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

	// Fee manager
access(all)
contract LithokenFee{ 
	access(all)
	let commonFeeManagerStoragePath: StoragePath
	
	access(all)
	event SellerFeeChanged(value: UFix64)
	
	access(all)
	event BuyerFeeChanged(value: UFix64)
	
	access(all)
	event FeeAddressUpdated(label: String, address: Address)
	
	access(self)
	var feeAddresses:{ String: Address}
	
	access(all)
	var sellerFee: UFix64
	
	access(all)
	var buyerFee: UFix64
	
	access(all)
	resource Manager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setSellerFee(_ fee: UFix64){ 
			LithokenFee.sellerFee = fee
			emit SellerFeeChanged(value: LithokenFee.sellerFee)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setBuyerFee(_ fee: UFix64){ 
			LithokenFee.buyerFee = fee
			emit BuyerFeeChanged(value: LithokenFee.buyerFee)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFeeAddress(_ label: String, address: Address){ 
			LithokenFee.feeAddresses[label] = address
			emit FeeAddressUpdated(label: label, address: address)
		}
	}
	
	init(){ 
		self.sellerFee = 0.05
		emit SellerFeeChanged(value: LithokenFee.sellerFee)
		self.buyerFee = 0.05
		emit BuyerFeeChanged(value: LithokenFee.buyerFee)
		self.feeAddresses ={} 
		self.commonFeeManagerStoragePath = /storage/commonFeeManager
		self.account.storage.save(<-create Manager(), to: self.commonFeeManagerStoragePath)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun feeAddress(): Address{ 
		return self.feeAddresses["lithoken"] ?? self.account.address
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun feeAddressByName(_ label: String): Address{ 
		return self.feeAddresses[label] ?? self.account.address
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun addressMap():{ String: Address}{ 
		return LithokenFee.feeAddresses
	}
}
