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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AACurrencyManager{ 
	access(self)
	var acceptCurrencies: [Type]
	
	access(self)
	let paths:{ String: CurPath}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	struct CurPath{ 
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let storagePath: StoragePath
		
		init(publicPath: PublicPath, storagePath: StoragePath){ 
			self.publicPath = publicPath
			self.storagePath = storagePath
		}
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setAcceptCurrencies(types: [Type]){ 
			for type in types{ 
				assert(type.isSubtype(of: Type<@{FungibleToken.Vault}>()), message: "Should be a sub type of FungibleToken.Vault")
			}
			AACurrencyManager.acceptCurrencies = types
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPath(type: Type, path: CurPath){ 
			AACurrencyManager.paths[type.identifier] = path
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAcceptCurrentcies(): [Type]{ 
		return self.acceptCurrencies
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isCurrencyAccepted(type: Type): Bool{ 
		return self.acceptCurrencies.contains(type)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPath(type: Type): CurPath?{ 
		return self.paths[type.identifier]
	}
	
	init(){ 
		self.acceptCurrencies = []
		self.paths ={} 
		self.AdminStoragePath = /storage/AACurrencyManagerAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
