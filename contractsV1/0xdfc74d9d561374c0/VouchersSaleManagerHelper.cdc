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

	access(all)
contract VouchersSaleManagerHelper{ 
	access(all)
	var goatVoucherMaxQuantityPerMint: UInt64
	
	access(all)
	var goatVoucherSaleStartTime: UFix64
	
	access(all)
	var goatVoucherSalePrice: UFix64
	
	access(all)
	var curSequentialGoatEditionNumber: UInt64
	
	access(account)
	let mintedGoatVoucherEditions:{ UInt64: Bool}
	
	access(all)
	var packVoucherMaxQuantityPerMint: UInt64
	
	access(all)
	var packVoucherSaleStartTime: UFix64
	
	access(all)
	var packVoucherSalePrice: UFix64
	
	access(all)
	var curSequentialPackEditionNumber: UInt64
	
	access(account)
	let mintedPackVoucherEditions:{ UInt64: Bool}
	
	access(account)
	fun setMintedGoatVoucherEditionToMinted(_ edition: UInt64){ 
		self.mintedGoatVoucherEditions[edition] = true
	}
	
	access(account)
	fun hasGoatVoucherEdition(_ edition: UInt64): Bool{ 
		return self.mintedGoatVoucherEditions.containsKey(edition)
	}
	
	access(account)
	fun hasGoatPackEdition(_ edition: UInt64): Bool{ 
		return self.mintedPackVoucherEditions.containsKey(edition)
	}
	
	access(account)
	fun setMintedPackVoucherEditionToMinted(_ edition: UInt64){ 
		self.mintedPackVoucherEditions[edition] = true
	}
	
	access(account)
	fun updateGoatVoucherSale(quantityPerMint: UInt64, price: UFix64, startTime: UFix64){ 
		self.goatVoucherMaxQuantityPerMint = quantityPerMint
		self.goatVoucherSaleStartTime = startTime
		self.goatVoucherSalePrice = price
	}
	
	access(account)
	fun setSequentialGoatEditionNumber(_ edition: UInt64){ 
		self.curSequentialGoatEditionNumber = edition
	}
	
	access(account)
	fun updatePackVoucherSale(quantityPerMint: UInt64, price: UFix64, startTime: UFix64){ 
		self.packVoucherMaxQuantityPerMint = quantityPerMint
		self.packVoucherSaleStartTime = startTime
		self.packVoucherSalePrice = price
	}
	
	access(account)
	fun setSequentialPackEditionNumber(_ edition: UInt64){ 
		self.curSequentialPackEditionNumber = edition
	}
	
	init(){ 
		self.goatVoucherMaxQuantityPerMint = 0
		self.goatVoucherSaleStartTime = 14268375033.0
		self.goatVoucherSalePrice = 100000000.0
		self.mintedGoatVoucherEditions ={} 
		self.packVoucherMaxQuantityPerMint = 0
		self.packVoucherSaleStartTime = 14268375033.0
		self.packVoucherSalePrice = 100000000.0
		self.mintedPackVoucherEditions ={} 
		
		// Why 1250? Minting was turned off prior to the
		// deployment of this updated helper. Starting at 1250
		// matches mainnet's current status in minting at the
		// time of this deployment.
		self.curSequentialGoatEditionNumber = 1250
		self.curSequentialPackEditionNumber = 1250
	}
}
