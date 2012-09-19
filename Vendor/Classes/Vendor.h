//
//  Vendor.h
//  Vendor
//
//  Created by Wess Cope on 9/19/12.
//  Copyright (c) 2012 Wess Cope. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef void(^VendorProducts)(NSArray *products);
typedef void(^VendorTransactionPurchasing)(SKPaymentTransaction *transaction);
typedef void(^VendorTransactionPurchased)(SKPaymentTransaction *transaction);
typedef void(^VendorTransactionFailed)(SKPaymentTransaction *transaction);
typedef void(^VendorTransactionRestored)(SKPaymentTransaction *transaction);
typedef void(^VendorVerifyReceipt)(NSDictionary *response);
typedef void(^VendorErrorHandler)(NSError *error);

@interface Vendor : NSObject<SKRequestDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (assign, nonatomic)       BOOL isUsingSandbox;
@property (readonly, nonatomic)     BOOL canMakePurchases;
@property (copy, nonatomic)         NSArray *products;
@property (copy, nonatomic)         NSString *sharedSecret;

+ (Vendor *)instance;
- (void)setErrorHandler:(VendorErrorHandler)errorHandler;
- (void)requestProductsWithIdentifiers:(NSArray *)identifiers callback:(VendorProducts)callback;
- (void)addPaymentForProduct:(SKProduct *)product purchasing:(VendorTransactionPurchasing)purchasing purchased:(VendorTransactionPurchased)purchased failed:(VendorTransactionFailed)failed restored:(VendorTransactionRestored)restored;
- (void)verifyReceiptForTransaction:(SKPaymentTransaction *)transaction callback:(VendorVerifyReceipt)verifyReceipt;
@end
