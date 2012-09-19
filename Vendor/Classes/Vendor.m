//
//  Vendor.m
//  Vendor
//
//  Created by Wess Cope on 9/19/12.
//  Copyright (c) 2012 Wess Cope. All rights reserved.
//

#import "Vendor.h"

static NSString *const kIAPSandBoxURLString                 = @"https://sandbox.itunes.apple.com/verifyReceipt";
static NSString *const kIAPLiveURLString                    = @"https://buy.itunes.apple.com/";
static NSString *const kVendorProductCallbackKey            = @"vendor_product_callback";
static NSString *const kVendorTransactionPurchasingCallback = @"vendor_product_purchasing";
static NSString *const kVendorTransactionPurchasedCallback  = @"vendor_product_purchased";
static NSString *const kVendorTransactionFailedCallback     = @"vendor_product_failed";
static NSString *const kVendorTransactionRestoredCallback   = @"vendor_product_restored";
static NSString *const kVendorVerifyReceiptCallback         = @"vendor_verify_receipt";
static NSString *const kVendorErrorCallback                 = @"vendor_error_handler";

/* Borrowed and tweaked from CargoBay */
static NSString *encodedStringFromData(NSData *data)
{
    NSUInteger length           = ((data.length + 2) / 3) * 4;
    NSMutableData *mutableData  = [NSMutableData dataWithLength:length];
    uint8_t *input              = (uint8_t *)data.bytes;
    uint8_t *output             = (uint8_t *)mutableData.mutableBytes;
    
    for (NSUInteger i = 0; i < length; i += 3)
    {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++)
        {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx  = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

@interface Vendor()
@property (strong, nonatomic) NSArray               *skProducts;
@property (strong, nonatomic) NSMutableSet          *productSet;
@property (strong, nonatomic) SKProductsRequest     *productRequest;
@property (strong, nonatomic) NSURL                 *requestURL;
@property (strong, nonatomic) NSMutableDictionary   *callbacks;
@end

@implementation Vendor

+ (Vendor *)instance
{
    static Vendor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[Vendor alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _isUsingSandbox = YES;
        _requestURL     = [NSURL URLWithString:kIAPSandBoxURLString];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)setErrorHandler:(VendorErrorHandler)errorHandler
{
    [_callbacks setObject:errorHandler forKey:kVendorErrorCallback];
}

- (void)setIsUsingSandbox:(BOOL)isUsingSandbox
{
    _isUsingSandbox = isUsingSandbox;
    _requestURL     = [NSURL URLWithString:((_isUsingSandbox)? kIAPSandBoxURLString : kIAPLiveURLString)];
}

- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

- (void)setProducts:(NSArray *)products
{
    [_productSet removeAllObjects];
    [_productSet addObjectsFromArray:products];

    _products = products;
    
    _productRequest             = nil;
    _productRequest             = [[SKProductsRequest alloc] initWithProductIdentifiers:_productSet];
    _productRequest.delegate    = self;
}

#pragma mark - Vendor Methods -
- (void)requestProductsWithIdentifiers:(NSArray *)identifiers callback:(VendorProducts)callback
{
    if(callback)
        [_callbacks setObject:callback forKey:kVendorProductCallbackKey];
    
    [_productRequest start];
}

- (void)addPaymentForProduct:(SKProduct *)product purchasing:(VendorTransactionPurchasing)purchasing purchased:(VendorTransactionPurchased)purchased failed:(VendorTransactionFailed)failed restored:(VendorTransactionRestored)restored
{
    if(purchasing)
        [_callbacks setObject:purchasing forKey:kVendorTransactionPurchasingCallback];
    
    if(purchased)
        [_callbacks setObject:purchased forKey:kVendorTransactionPurchasedCallback];
    
    if(failed)
        [_callbacks setObject:failed forKey:kVendorTransactionFailedCallback];
    
    if(restored)
        [_callbacks setObject:restored forKey:kVendorTransactionRestoredCallback];
    
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)verifyReceiptForTransaction:(SKPaymentTransaction *)transaction callback:(VendorVerifyReceipt)verifyReceipt
{
    if(verifyReceipt)
        [_callbacks setObject:verifyReceipt forKey:kVendorVerifyReceiptCallback];
    
    NSString *receipt = encodedStringFromData(transaction.transactionReceipt);

    if(receipt)
    {
        NSDictionary *params    = (_sharedSecret && ![_sharedSecret isEqualToString:@""])? @{@"receipt-data": receipt, @"password": _sharedSecret} : @{@"receipt-data": receipt};
        NSString *paramString   = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];

        NSURL *url = [NSURL URLWithString:kIAPSandBoxURLString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[paramString dataUsingEncoding:NSUTF8StringEncoding]];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if(error)
            {
                if([_callbacks objectForKey:kVendorErrorCallback])
                    ((VendorErrorHandler)[_callbacks objectForKey:kVendorErrorCallback])(error);
                else
                    NSLog(@"Vendor Error: %@", error);
                
                return;
            }
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

            if([_callbacks objectForKey:kVendorVerifyReceiptCallback])
                ((VendorVerifyReceipt)[_callbacks objectForKey:kVendorVerifyReceiptCallback])(result);
            
        }];
    }
}

#pragma mark - IAP Delegate Methods -
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSAssert(response.products.count > 0, @"No products available");
    
    _skProducts = [[NSArray alloc] initWithArray:response.products];
    if([_callbacks objectForKey:kVendorProductCallbackKey])
        ((VendorProducts)[_callbacks objectForKey:kVendorProductCallbackKey])(_skProducts);
}

-(void)requestDidFinish:(SKRequest *)request
{
//    SKPayment *payment  = [SKPayment paymentWithProduct:_product];
//    [[SKPaymentQueue defaultQueue] addPayment:payment];
//    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if([_callbacks objectForKey:kVendorErrorCallback])
        ((VendorErrorHandler)[_callbacks objectForKey:kVendorErrorCallback])(error);
    else
        NSLog(@"Vendor Request Error: %@", error);
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for(SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                if([_callbacks objectForKey:kVendorTransactionPurchasingCallback])
                    ((VendorTransactionPurchasing)[_callbacks objectForKey:kVendorTransactionPurchasingCallback])(transaction);
                break;

            case SKPaymentTransactionStatePurchased:
                if([_callbacks objectForKey:kVendorTransactionPurchasedCallback])
                    ((VendorTransactionPurchased)[_callbacks objectForKey:kVendorTransactionPurchasedCallback])(transaction);
                break;

            case SKPaymentTransactionStateFailed:
                if([_callbacks objectForKey:kVendorTransactionFailedCallback])
                    ((VendorTransactionFailed)[_callbacks objectForKey:kVendorTransactionFailedCallback])(transaction);
                break;

            case SKPaymentTransactionStateRestored:
                if([_callbacks objectForKey:kVendorTransactionRestoredCallback])
                    ((VendorTransactionRestored)[_callbacks objectForKey:kVendorTransactionRestoredCallback])(transaction);
                break;

            default:
                break;
        }
    }
}


@end




