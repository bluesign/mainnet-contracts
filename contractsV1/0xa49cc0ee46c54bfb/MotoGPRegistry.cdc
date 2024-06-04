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

	import ContractVersion from 0xa49cc0ee46c54bfb

access(all)
contract MotoGPRegistry: ContractVersion{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.0.0"
	}
	
	access(all)
	resource Admin{} 
	
	access(contract)
	let map:{ String: AnyStruct}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun set(adminRef: &Admin, key: String, value: AnyStruct){ 
		self.map[key] = value
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun get(key: String): AnyStruct?{ 
		return self.map[key] ?? nil
	}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	init(){ 
		self.map ={} 
		self.AdminStoragePath = /storage/registryAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
