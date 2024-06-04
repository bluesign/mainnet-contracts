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
contract DrizzleRecorder{ 
	access(all)
	let RecorderStoragePath: StoragePath
	
	access(all)
	let RecorderPublicPath: PublicPath
	
	access(all)
	let RecorderPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event RecordInserted(recorder: Address, type: String, uuid: UInt64, host: Address)
	
	access(all)
	event RecordUpdated(recorder: Address, type: String, uuid: UInt64, host: Address)
	
	access(all)
	event RecordRemoved(recorder: Address, type: String, uuid: UInt64, host: Address)
	
	access(all)
	struct CloudDrop{ 
		access(all)
		let dropID: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let name: String
		
		access(all)
		let tokenSymbol: String
		
		access(all)
		let claimedAmount: UFix64
		
		access(all)
		let claimedAt: UFix64
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(
			dropID: UInt64,
			host: Address,
			name: String,
			tokenSymbol: String,
			claimedAmount: UFix64,
			claimedAt: UFix64,
			extraData:{ 
				String: AnyStruct
			}
		){ 
			self.dropID = dropID
			self.host = host
			self.name = name
			self.tokenSymbol = tokenSymbol
			self.claimedAmount = claimedAmount
			self.claimedAt = claimedAt
			self.extraData = extraData
		}
	}
	
	access(all)
	struct MistRaffle{ 
		access(all)
		let raffleID: UInt64
		
		access(all)
		let host: Address
		
		access(all)
		let name: String
		
		access(all)
		let nftName: String
		
		access(all)
		let registeredAt: UFix64
		
		access(all)
		let rewardTokenIDs: [UInt64]
		
		access(all)
		var claimedAt: UFix64?
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(
			raffleID: UInt64,
			host: Address,
			name: String,
			nftName: String,
			registeredAt: UFix64,
			extraData:{ 
				String: AnyStruct
			}
		){ 
			self.raffleID = raffleID
			self.host = host
			self.name = name
			self.nftName = nftName
			self.registeredAt = registeredAt
			self.rewardTokenIDs = []
			self.claimedAt = nil
			self.extraData = extraData
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markAsClaimed(rewardTokenIDs: [UInt64], extraData:{ String: AnyStruct}){ 
			assert(self.claimedAt == nil, message: "Already marked as Claimed")
			self.rewardTokenIDs.appendAll(rewardTokenIDs)
			self.claimedAt = getCurrentBlock().timestamp
			for key in extraData.keys{ 
				if !self.extraData.containsKey(key){ 
					self.extraData[key] = extraData[key]
				}
			}
		}
	}
	
	access(all)
	resource interface IRecorderPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecords():{ String:{ UInt64: AnyStruct}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecordsByType(_ type: Type):{ UInt64: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecord(type: Type, uuid: UInt64): AnyStruct?
	}
	
	access(all)
	resource Recorder: IRecorderPublic{ 
		access(all)
		let records:{ String:{ UInt64: AnyStruct}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecords():{ String:{ UInt64: AnyStruct}}{ 
			return self.records
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecordsByType(_ type: Type):{ UInt64: AnyStruct}{ 
			self.initTypeRecords(type: type)
			return self.records[type.identifier]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRecord(type: Type, uuid: UInt64): AnyStruct?{ 
			self.initTypeRecords(type: type)
			return (self.records[type.identifier]!)[uuid]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun insertOrUpdateRecord(_ record: AnyStruct){ 
			let type = record.getType()
			self.initTypeRecords(type: type)
			if record.isInstance(Type<CloudDrop>()){ 
				let dropInfo = record as! CloudDrop
				let oldValue = (self.records[type.identifier]!).insert(key: dropInfo.dropID, dropInfo)
				if oldValue == nil{ 
					emit RecordInserted(recorder: (self.owner!).address, type: type.identifier, uuid: dropInfo.dropID, host: dropInfo.host)
				} else{ 
					emit RecordUpdated(recorder: (self.owner!).address, type: type.identifier, uuid: dropInfo.dropID, host: dropInfo.host)
				}
			} else if record.isInstance(Type<MistRaffle>()){ 
				let raffleInfo = record as! MistRaffle
				let oldValue = (self.records[type.identifier]!).insert(key: raffleInfo.raffleID, raffleInfo)
				if oldValue == nil{ 
					emit RecordInserted(recorder: (self.owner!).address, type: type.identifier, uuid: raffleInfo.raffleID, host: raffleInfo.host)
				} else{ 
					emit RecordUpdated(recorder: (self.owner!).address, type: type.identifier, uuid: raffleInfo.raffleID, host: raffleInfo.host)
				}
			} else{ 
				panic("Invalid record type")
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRecord(_ record: AnyStruct){ 
			let type = record.getType()
			self.initTypeRecords(type: type)
			if record.isInstance(Type<CloudDrop>()){ 
				let dropInfo = record as! CloudDrop
				(self.records[type.identifier]!).remove(key: dropInfo.dropID)
				emit RecordRemoved(recorder: (self.owner!).address, type: type.identifier, uuid: dropInfo.dropID, host: dropInfo.host)
			} else if record.isInstance(Type<MistRaffle>()){ 
				let raffleInfo = record as! MistRaffle
				(self.records[type.identifier]!).remove(key: raffleInfo.raffleID)
				emit RecordRemoved(recorder: (self.owner!).address, type: type.identifier, uuid: raffleInfo.raffleID, host: raffleInfo.host)
			} else{ 
				panic("Invalid record type")
			}
		}
		
		access(self)
		fun initTypeRecords(type: Type){ 
			assert(type == Type<CloudDrop>() || type == Type<MistRaffle>(), message: "Invalid Type")
			if self.records[type.identifier] == nil{ 
				self.records[type.identifier] ={} 
			}
		}
		
		init(){ 
			self.records ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyRecorder(): @Recorder{ 
		return <-create Recorder()
	}
	
	init(){ 
		self.RecorderStoragePath = /storage/drizzleRecorder
		self.RecorderPublicPath = /public/drizzleRecorder
		self.RecorderPrivatePath = /private/drizzleRecorder
		emit ContractInitialized()
	}
}
