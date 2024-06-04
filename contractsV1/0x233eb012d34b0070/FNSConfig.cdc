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
contract FNSConfig{ 
	access(self)
	var inboxFTWhitelist:{ String: Bool}
	
	access(self)
	var inboxNFTWhitelist:{ String: Bool}
	
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	access(self)
	let rootDomainConfig:{ String:{ String: AnyStruct}}
	
	access(self)
	let userConfig:{ Address:{ String: AnyStruct}}
	
	access(self)
	let domainConfig:{ String:{ String: AnyStruct}}
	
	access(account)
	fun updateFTWhitelist(key: String, flag: Bool){ 
		self.inboxFTWhitelist[key] = flag
	}
	
	access(account)
	fun updateNFTWhitelist(key: String, flag: Bool){ 
		self.inboxNFTWhitelist[key] = flag
	}
	
	access(account)
	fun setFTWhitelist(_ val:{ String: Bool}){ 
		self.inboxFTWhitelist = val
	}
	
	access(account)
	fun setNFTWhitelist(_ val:{ String: Bool}){ 
		self.inboxNFTWhitelist = val
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkFTWhitelist(_ typeIdentifier: String): Bool{ 
		return self.inboxFTWhitelist[typeIdentifier] ?? false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkNFTWhitelist(_ typeIdentifier: String): Bool{ 
		return self.inboxNFTWhitelist[typeIdentifier] ?? false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhitelist(_ type: String):{ String: Bool}{ 
		if type == "NFT"{ 
			return self.inboxNFTWhitelist
		}
		return self.inboxFTWhitelist
	}
	
	init(){ 
		self.inboxFTWhitelist ={} 
		self.inboxNFTWhitelist ={} 
		self._reservedFields ={} 
		self.rootDomainConfig ={} 
		self.userConfig ={} 
		self.domainConfig ={} 
	}
}
