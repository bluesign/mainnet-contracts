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

	import MotoGPAdmin from "./MotoGPAdmin.cdc"

import ContractVersion from "./ContractVersion.cdc"

access(all)
contract MotoGPCounter: ContractVersion{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "0.7.8"
	}
	
	access(self)
	let counterMap:{ String: UInt64}
	
	access(account)
	fun increment(_ key: String): UInt64{ 
		if self.counterMap.containsKey(key){ 
			self.counterMap[key] = self.counterMap[key]! + 1
		} else{ 
			self.counterMap[key] = 1
		}
		return self.counterMap[key]!
	}
	
	access(account)
	fun incrementBy(_ key: String, _ value: UInt64){ 
		if self.counterMap.containsKey(key){ 
			self.counterMap[key] = self.counterMap[key]! + value
		} else{ 
			self.counterMap[key] = value
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasCounter(_ key: String): Bool{ 
		return self.counterMap.containsKey(key)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCounter(_ key: String): UInt64{ 
		return self.counterMap[key]!
	}
	
	init(){ 
		self.counterMap ={} 
	}
}
