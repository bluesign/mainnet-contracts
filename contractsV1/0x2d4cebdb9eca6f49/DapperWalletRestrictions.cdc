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
contract DapperWalletRestrictions{ 
	//
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event TypeChanged(identifier: Type, newConfig: TypeConfig)
	
	access(all)
	event TypeRemoved(identifier: Type)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun GetConfigFlags():{ String: String}{ 
		return{ 
			"CAN_INIT": "Can initialize collection in Dapper Custodial Wallet",
			"CAN_WITHDRAW": "Can withdraw NFT out of Dapper Custodial space",
			"CAN_SELL": "Can sell collection in Dapper Custodial space",
			"CAN_TRADE": "Can trade collection with other Dapper Custodial Wallet",
			"CAN_TRADE_EXTERNAL": "Can trade collection with external wallets",
			"CAN_TRADE_DIFF_NFT": "Can trade collection with different NFT types"
		}
	}
	
	access(all)
	struct TypeConfig{ 
		access(all)
		let flags:{ String: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFlag(_ flag: String, _ value: Bool){ 
			if DapperWalletRestrictions.GetConfigFlags()[flag] == nil{ 
				panic("Invalid flag")
			}
			self.flags[flag] = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlag(_ flag: String): Bool{ 
			return self.flags[flag] ?? false
		}
		
		init(){ 
			self.flags ={} 
		}
	}
	
	access(self)
	let types:{ Type: TypeConfig}
	
	access(self)
	let ext:{ String: AnyStruct}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addType(_ t: Type, conf: TypeConfig){ 
			DapperWalletRestrictions.types.insert(key: t, conf)
			emit TypeChanged(identifier: t, newConfig: conf)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateType(_ t: Type, conf: TypeConfig){ 
			DapperWalletRestrictions.types[t] = conf
			emit TypeChanged(identifier: t, newConfig: conf)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeType(_ t: Type){ 
			DapperWalletRestrictions.types.remove(key: t)
			emit TypeRemoved(identifier: t)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTypes():{ Type: TypeConfig}{ 
		return self.types
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getConfig(_ t: Type): TypeConfig?{ 
		return self.types[t]
	}
	
	init(){ 
		self.types ={} 
		self.ext ={} 
		self.StoragePath = /storage/dapperWalletCollections
		self.account.storage.save(<-create Admin(), to: self.StoragePath)
	}
}
