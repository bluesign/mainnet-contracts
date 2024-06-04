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

	import OverluError from "./OverluError.cdc"

access(all)
contract OverluConfig{ 
	/**	___  ____ ___ _  _ ____
		   *   |__] |__|  |  |__| [__
			*  |	|  |  |  |  | ___]
			 *************************/
	
	access(all)
	let UserCertificateStoragePath: StoragePath
	
	access(all)
	let UserCertificatePrivatePath: PrivatePath
	
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event WhitelistAdded(address: Address, operator: Address)
	
	access(all)
	event WhitelistRemoved(address: Address, operator: Address)
	
	access(all)
	event PauseStateChanged(pauseFlag: Bool, operator: Address)
	
	/**	____ ___ ____ ___ ____
		   *   [__   |  |__|  |  |___
			*  ___]  |  |  |  |  |___
			 ************************/
	
	/// Reserved parameter fields: {ParamName: Value}
	access(self)
	let _reservedFields:{ String: AnyStruct}
	
	// white list for creator when isPermissionless is false
	access(self)
	let whitelist: [Address]
	
	// global pause: true will stop pool creation
	access(all)
	var pause: Bool
	
	// record dna in upgrade model
	access(account)
	var upgradeRecords:{ UInt64: [{String: AnyStruct}]}
	
	// record dna on model
	access(account)
	var dnaNestRecords:{ UInt64: UInt64}
	
	// record dna in expand model
	access(account)
	var expandRecords:{ UInt64: [{String: AnyStruct}]}
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	resource interface IdentityCertificate{} 
	
	access(all)
	resource UserCertificate: IdentityCertificate{} 
	
	// resources
	// overlu admin resource for manage staking contract
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addWhitelist(address: Address){ 
			pre{ 
				!OverluConfig.whitelist.contains(address):
					OverluError.errorEncode(msg: "Whitelist address already exist", err: OverluError.ErrorCode.WHITE_LIST_EXIST)
			}
			OverluConfig.whitelist.append(address)
			emit WhitelistAdded(address: address, operator: (self.owner!).address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeWhitelist(_ idx: UInt8){ 
			pre{ 
				OverluConfig.whitelist[idx] != nil:
					OverluError.errorEncode(msg: "Address not exist", err: OverluError.ErrorCode.INVALID_PARAMETERS)
			}
			let address = OverluConfig.whitelist[idx]
			OverluConfig.whitelist.remove(at: idx)
			emit WhitelistRemoved(address: address, operator: (self.owner!).address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPause(_ flag: Bool){ 
			pre{ 
				OverluConfig.pause != flag:
					OverluError.errorEncode(msg: "Set pause state faild, the state is same", err: OverluError.ErrorCode.SAME_BOOL_STATE)
			}
			OverluConfig.pause = flag
			emit PauseStateChanged(pauseFlag: flag, operator: (self.owner!).address)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRandomId(_ range: Int): UInt64{ 
		return revertibleRandom<UInt64>() % UInt64(range)
	}
	
	access(account)
	fun setUpgradeRecords(_ id: UInt64, metadata:{ String: AnyStruct}){ 
		let records = OverluConfig.upgradeRecords[id] ?? []
		records.append(metadata)
		OverluConfig.upgradeRecords[id] = records
	}
	
	access(account)
	fun setExpandRecords(_ id: UInt64, metadata:{ String: AnyStruct}){ 
		let records = OverluConfig.expandRecords[id] ?? []
		records.append(metadata)
		OverluConfig.expandRecords[id] = records
	}
	
	access(account)
	fun setDNANestRecords(_ id: UInt64, dnaId: UInt64){ 
		OverluConfig.dnaNestRecords[dnaId] = id
	}
	
	// ---- contract methods ----
	access(TMP_ENTITLEMENT_OWNER)
	fun setupUser(): @UserCertificate{ 
		let certificate <- create UserCertificate()
		return <-certificate
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUpgradeRecords(_ id: UInt64): [{String: AnyStruct}]?{ 
		return OverluConfig.upgradeRecords[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getExpandRecords(_ id: UInt64): [{String: AnyStruct}]?{ 
		return OverluConfig.expandRecords[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getDNANestRecords(_ id: UInt64): UInt64?{ 
		return OverluConfig.dnaNestRecords[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllUpgradeRecords():{ UInt64: [{String: AnyStruct}]}{ 
		return OverluConfig.upgradeRecords
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllDNANestRecords():{ UInt64: UInt64}{ 
		return OverluConfig.dnaNestRecords
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllExpandRecords():{ UInt64: [{String: AnyStruct}]}{ 
		return OverluConfig.expandRecords
	}
	
	// ---- init func ----
	init(){ 
		self.UserCertificateStoragePath = /storage/overluUserCertificate
		self.UserCertificatePrivatePath = /private/overluUserCertificate
		self._reservedFields ={} 
		self.whitelist = []
		self.pause = false
		self.upgradeRecords ={} 
		self.expandRecords ={} 
		self.dnaNestRecords ={} 
	}
}
