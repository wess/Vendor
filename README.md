# Vendor

> Vendor is a block based library for simplifying the In-App Purchase process from Apple.  A small and simple singleton that that doesn't stray to far from StoreKit itself, just wraps everything up in a nice Block based package. From getting products with identifiers, to validating receipts straight from your phone.  It also includes an optional Shared Secret param for the latest update, to help prevent bad people from doing bad things.

## Usage Example:
```objectivec

@property (assign, nonatomic)       BOOL isUsingSandbox;
@property (readonly, nonatomic)     BOOL canMakePurchases;
@property (copy, nonatomic)         NSArray *products;
@property (copy, nonatomic)         NSString *sharedSecret;

+ (Vendor *)instance;
- (void)setErrorHandler:(VendorErrorHandler)errorHandler;
- (void)requestProductsWithIdentifiers:(NSArray *)identifiers callback:(VendorProducts)callback;
- (void)addPaymentForProduct:(SKProduct *)product purchasing:(VendorTransactionPurchasing)purchasing purchased:(VendorTransactionPurchased)purchased failed:(VendorTransactionFailed)failed restored:(VendorTransactionRestored)restored;
- (void)verifyReceiptForTransaction:(SKPaymentTransaction *)transaction callback:(VendorVerifyReceipt)verifyReceipt;


NSArray *productIdentifiers = @[
	@"product_id_one",
	@"product_id_two",
	@"product_id_three"
];

[[Vendor instance] setIsUsingSandbox:YES];
if([[Vendor instance] canMakePurchases])
{

	[[Vendor instance] setErrorHandler:^(NSError *error) {
		NSLog(@"Vendor Error: %@", error.description);
	}];

	[[Vendor instance] requestProductsWithIdentifiers:productIdentifiers callback:^(NSArray *products) {
	    SKProduct *product = [products lastObject];
	
		[[Vendor instance] addPaymentForProduct:nil purchasing:^(SKPaymentTransaction *transaction) {
	        NSLog(@"Processing purchase");
	    } purchased:^(SKPaymentTransaction *transaction) {
        
			[[Vendor instance] verifyReceiptForTransaction:transaction callback:^(NSDictionary *response) {
				NSLog(@"RECEIPT RESPONSE: %@", response);
			}];

	    } failed:^(SKPaymentTransaction *transaction) {
	        NSLog(@"Transaction Failed");
	    } restored:^(SKPaymentTransaction *transaction) {
	        NSLog(@"Transaction Restored");
	    }];
	}];
}
```
## If you need me
[Github](http://www.github.com/wess)
[@WessCope](http://www.twitter.com/wess)

## License
Read LICENSE file for more info.