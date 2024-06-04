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
contract DapperWalletCollections{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event TypeChanged(identifier: String, added: Bool)
	
	access(self)
	let types:{ Type: Bool}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addType(_ t: Type){ 
			DapperWalletCollections.types.insert(key: t, true)
			emit TypeChanged(identifier: t.identifier, added: true)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeType(_ t: Type){ 
			DapperWalletCollections.types.remove(key: t)
			emit TypeChanged(identifier: t.identifier, added: false)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun containsType(_ t: Type): Bool{ 
		return self.types.containsKey(t)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTypes():{ Type: Bool}{ 
		return self.types
	}
	
	init(){ 
		self.types ={} 
		self.StoragePath = /storage/dapperWalletCollections
		self.account.storage.save(<-create Admin(), to: self.StoragePath)
	}
}
