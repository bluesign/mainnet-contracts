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

	// Made by Lanford33
//
// Cloud.cdc defines the FungibleToken DROP and the collections of it.
//
// There are 4 stages in a DROP.
// 1. You create a new DROP by setting the basic information, depositing funds, setting the criteria for eligible accounts and token distribution mode, then share the DROP link to your community;
// 2. Community members access the DROP page via the link, check their eligibility and claim the token if they are eligible.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Distributors from "./Distributors.cdc"

import EligibilityVerifiers from "./EligibilityVerifiers.cdc"

import DrizzleRecorder from "./DrizzleRecorder.cdc"

access(all)
contract Cloud{ 
	access(all)
	let CloudAdminStoragePath: StoragePath
	
	access(all)
	let CloudAdminPublicPath: PublicPath
	
	access(all)
	let CloudAdminPrivatePath: PrivatePath
	
	access(all)
	let DropCollectionStoragePath: StoragePath
	
	access(all)
	let DropCollectionPublicPath: PublicPath
	
	access(all)
	let DropCollectionPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event DropCreated(
		dropID: UInt64,
		name: String,
		host: Address,
		description: String,
		tokenIdentifier: String
	)
	
	access(all)
	event DropClaimed(
		dropID: UInt64,
		name: String,
		host: Address,
		claimer: Address,
		tokenIdentifier: String,
		amount: UFix64
	)
	
	access(all)
	event DropPaused(dropID: UInt64, name: String, host: Address)
	
	access(all)
	event DropUnpaused(dropID: UInt64, name: String, host: Address)
	
	access(all)
	event DropEnded(dropID: UInt64, name: String, host: Address)
	
	access(all)
	event DropDestroyed(dropID: UInt64, name: String, host: Address)
	
	access(all)
	enum EligibilityStatus: UInt8{ 
		access(all)
		case eligible
		
		access(all)
		case notEligible
		
		access(all)
		case hasClaimed
	}
	
	// Eligibility is a struct used to describe the eligibility of an account
	access(all)
	struct Eligibility{ 
		access(all)
		let status: EligibilityStatus
		
		access(all)
		let eligibleAmount: UFix64
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(status: EligibilityStatus, eligibleAmount: UFix64, extraData:{ String: AnyStruct}){ 
			self.status = status
			self.eligibleAmount = eligibleAmount
			self.extraData = extraData
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStatus(): String{ 
			switch self.status{ 
				case EligibilityStatus.eligible:
					return "eligible"
				case EligibilityStatus.notEligible:
					return "not eligible"
				case EligibilityStatus.hasClaimed:
					return "has claimed"
			}
			panic("invalid status")
		}
	}
	
	// TokenInfo stores the information of the FungibleToken in a DROP
	access(all)
	struct TokenInfo{ 
		access(all)
		let tokenIdentifier: String
		
		access(all)
		let providerIdentifier: String
		
		access(all)
		let balanceIdentifier: String
		
		access(all)
		let receiverIdentifier: String
		
		access(all)
		let account: Address
		
		access(all)
		let contractName: String
		
		access(all)
		let symbol: String
		
		access(all)
		let providerPath: StoragePath
		
		access(all)
		let balancePath: PublicPath
		
		access(all)
		let receiverPath: PublicPath
		
		init(
			account: Address,
			contractName: String,
			symbol: String,
			providerPath: String,
			balancePath: String,
			receiverPath: String
		){ 
			let address = account.toString()
			let addrTrimmed = address.slice(from: 2, upTo: address.length)
			self.tokenIdentifier = "A.".concat(addrTrimmed).concat(".").concat(contractName)
			self.providerIdentifier = self.tokenIdentifier.concat(".Vault")
			self.balanceIdentifier = self.tokenIdentifier.concat(".Balance")
			self.receiverIdentifier = self.tokenIdentifier.concat(".Receiver")
			self.account = account
			self.contractName = contractName
			self.symbol = symbol
			self.providerPath = StoragePath(identifier: providerPath)!
			self.balancePath = PublicPath(identifier: balancePath)!
			self.receiverPath = PublicPath(identifier: receiverPath)!
		}
	}
	
	// We will add a ClaimRecord to claimedRecords after an account claiming it's reward
	access(all)
	struct ClaimRecord{ 
		access(all)
		let address: Address
		
		access(all)
		let amount: UFix64
		
		access(all)
		let claimedAt: UFix64
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(address: Address, amount: UFix64, extraData:{ String: AnyStruct}){ 
			self.address = address
			self.amount = amount
			self.extraData = extraData
			self.claimedAt = getCurrentBlock().timestamp
		}
	}
	
	access(all)
	enum AvailabilityStatus: UInt8{ 
		access(all)
		case ok
		
		access(all)
		case ended
		
		access(all)
		case notStartYet
		
		access(all)
		case expired
		
		access(all)
		case noCapacity
		
		access(all)
		case paused
	}
	
	access(all)
	struct Availability{ 
		access(all)
		let status: AvailabilityStatus
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		init(status: AvailabilityStatus, extraData:{ String: AnyStruct}){ 
			self.status = status
			self.extraData = extraData
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStatus(): String{ 
			switch self.status{ 
				case AvailabilityStatus.ok:
					return "ok"
				case AvailabilityStatus.ended:
					return "ended"
				case AvailabilityStatus.notStartYet:
					return "not start yet"
				case AvailabilityStatus.expired:
					return "expired"
				case AvailabilityStatus.noCapacity:
					return "no capacity"
				case AvailabilityStatus.paused:
					return "paused"
			}
			panic("invalid status")
		}
	}
	
	// The airdrop created in Drizzle is called DROP.
	// IDropPublic defined the public fields and functions of a DROP
	access(all)
	resource interface IDropPublic{ 
		access(all)
		let dropID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let host: Address
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		let image: String?
		
		access(all)
		let url: String?
		
		access(all)
		let startAt: UFix64?
		
		access(all)
		let endAt: UFix64?
		
		access(all)
		let tokenInfo: TokenInfo
		
		access(all)
		let distributor:{ Distributors.IDistributor}
		
		access(all)
		let verifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		var isPaused: Bool
		
		access(all)
		var isEnded: Bool
		
		// Helper field for use to access the claimed amount of DROP easily
		access(all)
		var claimedAmount: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(receiver: &{FungibleToken.Receiver}, params:{ String: AnyStruct}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkAvailability(params:{ String: AnyStruct}): Availability
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkEligibility(account: Address, params:{ String: AnyStruct}): Eligibility
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimedRecord(account: Address): ClaimRecord?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimedRecords():{ Address: ClaimRecord}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDropBalance(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
	}
	
	access(all)
	resource interface IDropCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllDrops():{ UInt64: &{Cloud.IDropPublic}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicDropRef(dropID: UInt64): &{IDropPublic}?
	}
	
	access(all)
	resource Drop: IDropPublic{ 
		access(all)
		let dropID: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let host: Address
		
		access(all)
		let createdAt: UFix64
		
		access(all)
		let image: String?
		
		access(all)
		let url: String?
		
		access(all)
		let startAt: UFix64?
		
		access(all)
		let endAt: UFix64?
		
		access(all)
		let tokenInfo: TokenInfo
		
		access(all)
		let distributor:{ Distributors.IDistributor}
		
		access(all)
		let verifyMode: EligibilityVerifiers.VerifyMode
		
		access(all)
		var isPaused: Bool
		
		access(all)
		var isEnded: Bool
		
		access(all)
		let claimedRecords:{ Address: ClaimRecord}
		
		access(all)
		var claimedAmount: UFix64
		
		access(all)
		let extraData:{ String: AnyStruct}
		
		access(account)
		let verifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}
		
		access(self)
		let dropVault: @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(receiver: &{FungibleToken.Receiver}, params:{ String: AnyStruct}){ 
			params.insert(key: "recordUsedNFT", true)
			let availability = self.checkAvailability(params: params)
			assert(availability.status == AvailabilityStatus.ok, message: availability.getStatus())
			let claimer = (receiver.owner!).address
			let eligibility = self.checkEligibility(account: claimer, params: params)
			assert(eligibility.status == EligibilityStatus.eligible, message: eligibility.getStatus())
			let claimRecord = ClaimRecord(address: claimer, amount: eligibility.eligibleAmount, extraData:{} )
			self.claimedRecords.insert(key: claimRecord.address, claimRecord)
			self.claimedAmount = self.claimedAmount + claimRecord.amount
			emit DropClaimed(dropID: self.dropID, name: self.name, host: self.host, claimer: claimRecord.address, tokenIdentifier: self.tokenInfo.tokenIdentifier, amount: claimRecord.amount)
			if let recorderRef = params["recorderRef"]{ 
				let _recorderRef = recorderRef as! &DrizzleRecorder.Recorder
				_recorderRef.insertOrUpdateRecord(DrizzleRecorder.CloudDrop(dropID: self.dropID, host: self.host, name: self.name, tokenSymbol: self.tokenInfo.symbol, claimedAmount: claimRecord.amount, claimedAt: getCurrentBlock().timestamp, extraData:{} ))
			}
			let v <- self.dropVault.withdraw(amount: claimRecord.amount)
			receiver.deposit(from: <-v)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkAvailability(params:{ String: AnyStruct}): Availability{ 
			if self.isEnded{ 
				return Availability(status: AvailabilityStatus.ended, extraData:{} )
			}
			if let startAt = self.startAt{ 
				if getCurrentBlock().timestamp < startAt{ 
					return Availability(status: AvailabilityStatus.notStartYet, extraData:{} )
				}
			}
			if let endAt = self.endAt{ 
				if getCurrentBlock().timestamp > endAt{ 
					return Availability(status: AvailabilityStatus.expired, extraData:{} )
				}
			}
			let newParams:{ String: AnyStruct} = self.combinedParams(params: params)
			if !self.distributor.isAvailable(params: newParams){ 
				return Availability(status: AvailabilityStatus.noCapacity, extraData:{} )
			}
			if self.isPaused{ 
				return Availability(status: AvailabilityStatus.paused, extraData:{} )
			}
			return Availability(status: AvailabilityStatus.ok, extraData:{} )
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkEligibility(account: Address, params:{ String: AnyStruct}): Eligibility{ 
			if let record = self.claimedRecords[account]{ 
				return Eligibility(status: EligibilityStatus.hasClaimed, eligibleAmount: record.amount, extraData:{} )
			}
			params.insert(key: "claimer", account)
			var recordUsedNFT = false
			if let _recordUsedNFT = params["recordUsedNFT"]{ 
				recordUsedNFT = _recordUsedNFT as! Bool
			}
			let newParams:{ String: AnyStruct} = self.combinedParams(params: params)
			var isEligible = false
			if self.verifyMode == EligibilityVerifiers.VerifyMode.oneOf{ 
				for identifier in self.verifiers.keys{ 
					let _verifiers = &self.verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]
					var counter = 0
					while counter < _verifiers.length{ 
						let result = _verifiers[counter].verify(account: account, params: newParams)
						if result.isEligible{ 
							if recordUsedNFT{ 
								if let v = _verifiers[counter] as?{ EligibilityVerifiers.INFTRecorder}{ 
									(_verifiers[counter] as!{ EligibilityVerifiers.INFTRecorder}).addUsedNFTs(account: account, nftTokenIDs: result.usedNFTs)
								}
							}
							isEligible = true
							break
						}
						counter = counter + 1
					}
					if isEligible{ 
						break
					}
				}
			} else if self.verifyMode == EligibilityVerifiers.VerifyMode.all{ 
				isEligible = true
				let tempUsedNFTs:{ String:{ UInt64: [UInt64]}} ={} 
				for identifier in self.verifiers.keys{ 
					let _verifiers = &self.verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]
					var counter: UInt64 = 0
					while counter < UInt64(_verifiers.length){ 
						let result = _verifiers[counter].verify(account: account, params: params)
						if !result.isEligible{ 
							isEligible = false
							break
						}
						if recordUsedNFT && result.usedNFTs.length > 0{ 
							if tempUsedNFTs[identifier] == nil{ 
								let v:{ UInt64: [UInt64]} ={} 
								tempUsedNFTs[identifier] = v
							}
							(tempUsedNFTs[identifier]! as!{ UInt64: [UInt64]}).insert(key: counter, result.usedNFTs)
						}
						counter = counter + 1
					}
					if !isEligible{ 
						break
					}
				}
				if isEligible && recordUsedNFT{ 
					for identifier in tempUsedNFTs.keys{ 
						let usedNFTsInfo = tempUsedNFTs[identifier]!
						let _verifiers = &self.verifiers[identifier]! as &[{EligibilityVerifiers.IEligibilityVerifier}]
						for index in usedNFTsInfo.keys{ 
							(_verifiers[index] as!{ EligibilityVerifiers.INFTRecorder}).addUsedNFTs(account: account, nftTokenIDs: usedNFTsInfo[index]!)
						}
					}
				}
			}
			let eligibleAmount = self.distributor.getEligibleAmount(params: newParams)
			return Eligibility(status: isEligible ? EligibilityStatus.eligible : EligibilityStatus.notEligible, eligibleAmount: eligibleAmount, extraData:{} )
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimedRecord(account: Address): ClaimRecord?{ 
			return self.claimedRecords[account]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimedRecords():{ Address: ClaimRecord}{ 
			return self.claimedRecords
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDropBalance(): UFix64{ 
			return self.dropVault.balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVerifiers():{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}{ 
			return self.verifiers
		}
		
		// private methods
		access(TMP_ENTITLEMENT_OWNER)
		fun togglePause(): Bool{ 
			pre{ 
				!self.isEnded:
					"DROP has ended"
			}
			self.isPaused = !self.isPaused
			if self.isPaused{ 
				emit DropPaused(dropID: self.dropID, name: self.name, host: self.host)
			} else{ 
				emit DropUnpaused(dropID: self.dropID, name: self.name, host: self.host)
			}
			return self.isPaused
		}
		
		// deposit more token into the DROP.
		// If the whitelist of a DROP is allowed to extend, we need
		// this function to make sure the claimers can have enough funds to withdraw.
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(from: @{FungibleToken.Vault}){ 
			pre{ 
				!self.isEnded:
					"DROP has ended"
				from.balance > 0.0:
					"deposit empty vault"
			}
			self.dropVault.deposit(from: <-from)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun end(receiver: &{FungibleToken.Receiver}){ 
			self.isEnded = true
			self.isPaused = true
			emit DropEnded(dropID: self.dropID, name: self.name, host: self.host)
			if self.dropVault.balance > 0.0{ 
				let v <- self.dropVault.withdraw(amount: self.dropVault.balance)
				receiver.deposit(from: <-v)
			}
		}
		
		access(self)
		fun combinedParams(params:{ String: AnyStruct}):{ String: AnyStruct}{ 
			let combined:{ String: AnyStruct} ={ "claimedCount": UInt32(self.claimedRecords.keys.length), "claimedAmount": self.claimedAmount}
			for key in params.keys{ 
				if !combined.containsKey(key){ 
					combined[key] = params[key]
				}
			}
			return combined
		}
		
		init(name: String, description: String, host: Address, image: String?, url: String?, startAt: UFix64?, endAt: UFix64?, tokenInfo: TokenInfo, distributor:{ Distributors.IDistributor}, verifyMode: EligibilityVerifiers.VerifyMode, verifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]}, vault: @{FungibleToken.Vault}, extraData:{ String: AnyStruct}){ 
			pre{ 
				name.length > 0:
					"invalid name"
			}
			
			// `tokenInfo` should match with `vault`
			let tokenVaultType = CompositeType(tokenInfo.providerIdentifier)!
			if !vault.isInstance(tokenVaultType){ 
				panic("invalid token info: get ".concat(vault.getType().identifier).concat(", want ").concat(tokenVaultType.identifier))
			}
			if let _startAt = startAt{ 
				if let _endAt = endAt{ 
					assert(_startAt < _endAt, message: "endAt should greater than startAt")
				}
			}
			self.dropID = self.uuid
			self.name = name
			self.description = description
			self.host = host
			self.createdAt = getCurrentBlock().timestamp
			self.image = image
			self.url = url
			self.startAt = startAt
			self.endAt = endAt
			self.tokenInfo = tokenInfo
			self.distributor = distributor
			self.verifyMode = verifyMode
			self.verifiers = verifiers
			self.isPaused = false
			self.isEnded = false
			self.claimedRecords ={} 
			self.claimedAmount = 0.0
			self.dropVault <- vault
			self.extraData = extraData
			Cloud.totalDrops = Cloud.totalDrops + 1
			emit DropCreated(dropID: self.dropID, name: self.name, host: self.host, description: self.description, tokenIdentifier: self.tokenInfo.tokenIdentifier)
		}
	}
	
	access(all)
	resource interface ICloudPauser{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleContractPause(): Bool
	}
	
	access(all)
	resource Admin: ICloudPauser{ 
		// Use to pause the creation of new DROP
		// If we want to migrate the contracts, we can make sure no more DROP in old contracts be created.
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleContractPause(): Bool{ 
			Cloud.isPaused = !Cloud.isPaused
			return Cloud.isPaused
		}
	}
	
	access(all)
	resource DropCollection: IDropCollectionPublic{ 
		access(all)
		var drops: @{UInt64: Drop}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createDrop(name: String, description: String, host: Address, image: String?, url: String?, startAt: UFix64?, endAt: UFix64?, tokenInfo: TokenInfo, distributor:{ Distributors.IDistributor}, verifyMode: EligibilityVerifiers.VerifyMode, verifiers: [{EligibilityVerifiers.IEligibilityVerifier}], vault: @{FungibleToken.Vault}, extraData:{ String: AnyStruct}): UInt64{ 
			pre{ 
				verifiers.length == 1:
					"Currently only 1 verifier supported"
				!Cloud.isPaused:
					"Cloud contract is paused!"
			}
			let typedVerifiers:{ String: [{EligibilityVerifiers.IEligibilityVerifier}]} ={} 
			for verifier in verifiers{ 
				let identifier = verifier.getType().identifier
				if typedVerifiers[identifier] == nil{ 
					typedVerifiers[identifier] = [verifier]
				} else{ 
					(typedVerifiers[identifier]!).append(verifier)
				}
			}
			let drop <- create Drop(name: name, description: description, host: host, image: image, url: url, startAt: startAt, endAt: endAt, tokenInfo: tokenInfo, distributor: distributor, verifyMode: verifyMode, verifiers: typedVerifiers, vault: <-vault, extraData: extraData)
			let dropID = drop.dropID
			self.drops[dropID] <-! drop
			return dropID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllDrops():{ UInt64: &{IDropPublic}}{ 
			let dropRefs:{ UInt64: &{IDropPublic}} ={} 
			for dropID in self.drops.keys{ 
				let dropRef = (&self.drops[dropID] as &{IDropPublic}?)!
				dropRefs.insert(key: dropID, dropRef)
			}
			return dropRefs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPublicDropRef(dropID: UInt64): &{IDropPublic}?{ 
			return &self.drops[dropID] as &{IDropPublic}?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDropRef(dropID: UInt64): &Drop?{ 
			return &self.drops[dropID] as &Drop?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteDrop(dropID: UInt64, receiver: &{FungibleToken.Receiver}){ 
			// Clean the Drop before make it ownerless
			let dropRef = self.borrowDropRef(dropID: dropID) ?? panic("This drop does not exist")
			dropRef.end(receiver: receiver)
			let drop <- self.drops.remove(key: dropID) ?? panic("This drop does not exist")
			destroy drop
		}
		
		init(){ 
			self.drops <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyDropCollection(): @DropCollection{ 
		return <-create DropCollection()
	}
	
	access(all)
	var isPaused: Bool
	
	access(all)
	var totalDrops: UInt64
	
	init(){ 
		self.DropCollectionStoragePath = /storage/drizzleDropCollection
		self.DropCollectionPublicPath = /public/drizzleDropCollection
		self.DropCollectionPrivatePath = /private/drizzleDropCollection
		self.CloudAdminStoragePath = /storage/drizzleCloudAdmin
		self.CloudAdminPublicPath = /public/drizzleCloudAdmin
		self.CloudAdminPrivatePath = /private/drizzleCloudAdmin
		self.isPaused = false
		self.totalDrops = 0
		self.account.storage.save(<-create Admin(), to: self.CloudAdminStoragePath)
		emit ContractInitialized()
	}
}
