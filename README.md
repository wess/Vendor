# Vendor

> Vendor is a block based library for simplifying the In-App Purchase process from Apple.  A small and simple singleton that doesn't stray too far from StoreKit itself, just wraps everything up in a nice Block based package. From getting products with identifiers, to validating receipts straight from your phone.  It also includes an optional Shared Secret param for the latest update, to help prevent bad people from doing bad things.

## Usage Example:
```objectivec

NSArray *productIdentifiers = @[
	@"product_id_one",
	@"product_id_two",
	@"product_id_three"
];

if([[Vendor instance] canMakePurchases])
{
	[[Vendor instance] setIsUsingSandbox:YES];
	[[Vendor instance] setSharedSecret:@"111111111111"];

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
* [Github](http://www.github.com/wess)
* [@WessCope](http://www.twitter.com/wess)

## License
Read LICENSE file for more info.