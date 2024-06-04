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
contract KlktnNFTTimestamps{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event NFTTemplateTimestampCreated(typeID: UInt64, timestamps: KlktnNFTTemplateTimestamps)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var KlktnNFTTimestampsSet:{ UInt64: KlktnNFTTemplateTimestamps}
	
	access(all)
	struct KlktnNFTTemplateTimestamps{ 
		access(all)
		let typeID: UInt64
		
		access(self)
		var timestamps:{ String: UFix64}
		
		access(contract)
		fun updateTimestamps(newTimestamps:{ String: UFix64}){ 
			self.timestamps = newTimestamps
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTimestamps():{ String: UFix64}{ 
			return self.timestamps
		}
		
		init(initTypeID: UInt64, initTimestamps:{ String: UFix64}){ 
			self.typeID = initTypeID
			self.timestamps = initTimestamps
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createKlktnNFTTemplateTimestamps(typeID: UInt64, initTimestamps:{ String: UFix64}){ 
			pre{ 
				!KlktnNFTTimestamps.KlktnNFTTimestampsSet.containsKey(typeID):
					"NFT template timestamp with this typeID already exists."
			}
			let newNFTTimestamps =
				KlktnNFTTemplateTimestamps(initTypeID: typeID, initTimestamps: initTimestamps)
			KlktnNFTTimestamps.KlktnNFTTimestampsSet[typeID] = newNFTTimestamps
			emit NFTTemplateTimestampCreated(typeID: typeID, timestamps: newNFTTimestamps)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateKlktnNFTTemplateTimestamps(
			typeID: UInt64,
			newTimestamps:{ 
				String: UFix64
			}
		): KlktnNFTTimestamps.KlktnNFTTemplateTimestamps{ 
			pre{ 
				KlktnNFTTimestamps.KlktnNFTTimestampsSet.containsKey(typeID) != nil:
					"NFT KlktnNFTTemplateTimestamps with the typeID does not exist."
			}
			(KlktnNFTTimestamps.KlktnNFTTimestampsSet[typeID]!).updateTimestamps(
				newTimestamps: newTimestamps
			)
			return KlktnNFTTimestamps.KlktnNFTTimestampsSet[typeID]!
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTTemplateTimestamps(typeID: UInt64): KlktnNFTTemplateTimestamps{ 
		return self.KlktnNFTTimestampsSet[typeID]!
	}
	
	init(){ 
		self.KlktnNFTTimestampsSet ={} 
		self.AdminStoragePath = /storage/KlktnNFT2TimestampsAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
