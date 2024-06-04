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
contract TFCSoulbounds{ 
	
	// Events
	access(all)
	event AddedItemToSoulbounds(itemName: String)
	
	access(all)
	event RemovedItemFromSoulbounds(itemName: String)
	
	access(all)
	event ContractInitialized()
	
	// Named Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(contract)
	var soulboundItems:{ String: Bool}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addNewItemToSoulboundList(itemName: String){ 
			TFCSoulbounds.soulboundItems.insert(key: itemName, true)
			emit AddedItemToSoulbounds(itemName: itemName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeItemFromSoulboundList(itemName: String){ 
			TFCSoulbounds.soulboundItems.remove(key: itemName)
			emit RemovedItemFromSoulbounds(itemName: itemName)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSoulboundItemsList(): [String]{ 
		return self.soulboundItems.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isItemSoulbound(itemName: String): Bool{ 
		return self.soulboundItems.containsKey(itemName)
	}
	
	init(){ 
		// Set our named paths
		self.AdminStoragePath = /storage/TFCSoulboundsAdmin
		self.AdminPrivatePath = /private/TFCSoulboundsAdminPrivate
		
		// Initialize Vars
		self.soulboundItems ={} 
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
