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
contract CarClubTracker{ 
	access(all)
	struct PurchaseRecord{ 
		access(all)
		let id: UInt64
		
		access(all)
		let userAddress: Address
		
		access(all)
		let itemType: String // "Single" or "Pack"
		
		
		access(all)
		let rollout: String
		
		init(_ id: UInt64, userAddress: Address, itemType: String, rollout: String){ 
			self.id = id
			self.userAddress = userAddress
			self.itemType = itemType
			self.rollout = rollout
		}
	}
	
	// Store for the purchase records
	access(all)
	var purchaseRecords:{ UInt64: PurchaseRecord}
	
	// Global ID counter for purchase records
	access(all)
	var nextId: UInt64
	
	// Function to add a new purchase record
	access(TMP_ENTITLEMENT_OWNER)
	fun addPurchase(userAddress: Address, itemType: String, rollout: String){ 
		let newPurchase =
			PurchaseRecord(
				self.nextId,
				userAddress: userAddress,
				itemType: itemType,
				rollout: rollout
			)
		self.purchaseRecords[self.nextId] = newPurchase
		self.nextId = self.nextId + 1
	}
	
	init(){ 
		self.purchaseRecords ={} 
		self.nextId = 0
	}
}
