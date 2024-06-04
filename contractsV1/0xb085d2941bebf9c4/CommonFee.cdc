/*
This tool adds a new entitlemtent called TMP_ENTITLEMENT_OWNER to some functions that it cannot be sure if it is safe to make access(all)
those functions you should check and update their entitlemtents ( or change to all access )

Please see: 
https://cadence-lang.org/docs/cadence-migration-guide/nft-guide#update-all-pub-access-modfiers

IMPORTANT SECURITY NOTICE
Please familiarize yourself with the new entitlements feature because it is extremely important for you to understand in order to build safe smart contracts.
If you change pub to access(all) without paying attention to potential downcasting from public interfaces, you might expose private functions like withdraw 
that will cause security problems for your contract.

*/

	// Simple fee manager
//
access(all)
contract CommonFee{ 
	access(all)
	let commonFeeManagerStoragePath: StoragePath
	
	access(all)
	event SellerFeeChanged(value: UFix64)
	
	access(all)
	event BuyerFeeChanged(value: UFix64)
	
	// Seller fee in %
	access(all)
	var sellerFee: UFix64
	
	// BuyerFee fee in %
	access(all)
	var buyerFee: UFix64
	
	access(all)
	resource Manager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setBuyerFee(_ fee: UFix64){ 
			CommonFee.buyerFee = fee
			emit BuyerFeeChanged(value: CommonFee.buyerFee)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSellerFee(_ fee: UFix64){ 
			CommonFee.sellerFee = fee
			emit SellerFeeChanged(value: CommonFee.sellerFee)
		}
	}
	
	init(){ 
		self.sellerFee = 2.5
		emit SellerFeeChanged(value: CommonFee.sellerFee)
		self.buyerFee = 2.5
		emit BuyerFeeChanged(value: CommonFee.buyerFee)
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun feeAddress(): Address{ 
		return self.account.address
	}
}
