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

access(all)
contract RoyaltiesOverride{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	resource Ledger{ 
		access(account)
		let overrides:{ Type: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun set(_ type: Type, _ b: Bool){ 
			self.overrides[type] = b
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun get(_ type: Type): Bool{ 
			return self.overrides[type] ?? false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun remove(_ type: Type){ 
			self.overrides.remove(key: type)
		}
		
		init(){ 
			self.overrides ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun get(_ type: Type): Bool{ 
		return (self.account.storage.borrow<&Ledger>(from: RoyaltiesOverride.StoragePath)!).get(
			type
		)
	}
	
	init(){ 
		self.StoragePath = /storage/RoyaltiesOverride
		self.account.storage.save(<-create Ledger(), to: self.StoragePath)
	}
}
