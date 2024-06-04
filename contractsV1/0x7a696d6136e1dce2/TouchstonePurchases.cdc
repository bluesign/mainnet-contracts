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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

// Created by Emerald City DAO for Touchstone (https://touchstone.city/)
access(all)
contract TouchstonePurchases{ 
	access(all)
	let PurchasesStoragePath: StoragePath
	
	access(all)
	let PurchasesPublicPath: PublicPath
	
	access(all)
	struct Purchase{ 
		access(all)
		let metadataId: UInt64
		
		access(all)
		let display: MetadataViews.Display
		
		access(all)
		let contractAddress: Address
		
		access(all)
		let contractName: String
		
		init(
			_metadataId: UInt64,
			_display: MetadataViews.Display,
			_contractAddress: Address,
			_contractName: String
		){ 
			self.metadataId = _metadataId
			self.display = _display
			self.contractAddress = _contractAddress
			self.contractName = _contractName
		}
	}
	
	access(all)
	resource interface PurchasesPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getPurchases():{ UInt64: TouchstonePurchases.Purchase}
	}
	
	access(all)
	resource Purchases: PurchasesPublic{ 
		access(all)
		let list:{ UInt64: Purchase}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPurchase(uuid: UInt64, metadataId: UInt64, display: MetadataViews.Display, contractAddress: Address, contractName: String){ 
			self.list[uuid] = Purchase(_metadataId: metadataId, _display: display, _contractAddress: contractAddress, _contractName: contractName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPurchases():{ UInt64: Purchase}{ 
			return self.list
		}
		
		init(){ 
			self.list ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createPurchases(): @Purchases{ 
		return <-create Purchases()
	}
	
	init(){ 
		self.PurchasesStoragePath = /storage/TouchstonePurchases
		self.PurchasesPublicPath = /public/TouchstonePurchases
	}
}
