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

	import Crypto

access(all)
contract MatchContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let waitingIndices: [UInt32]
	
	access(all)
	let matchedIndices: [UInt32]
	
	access(all)
	let finalizeIndices: [UInt32]
	
	access(self)
	var registerActive: Bool
	
	access(self)
	var matchActive: Bool
	
	// latest not used yet index
	access(self)
	var nextIndex: UInt32
	
	// if using pub let other can still modify by such transaction
	// execute {
	//   MatchContract.indexAddressMap[0]?.remove(key: MatchContract.MatchRole.host)
	// }
	access(account)
	let addressGroupMap:{ String:{ MatchStatus: [UInt32]}}
	
	access(account)
	let indexAddressMap:{ UInt32:{ MatchRole: Address}}
	
	// Events
	access(all)
	event registered(host: Address, index: UInt32)
	
	access(all)
	event matched(host: Address, challenger: Address, index: UInt32)
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setActivateRegistration(_ active: Bool){ 
			MatchContract.registerActive = active
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setActivateMatching(_ active: Bool){ 
			MatchContract.matchActive = active
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	init(){ 
		self.registerActive = false
		self.matchActive = false
		self.nextIndex = 0
		self.addressGroupMap ={} 
		self.indexAddressMap ={} 
		self.waitingIndices = []
		self.matchedIndices = []
		self.finalizeIndices = []
		self.AdminStoragePath = /storage/matchAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
	
	// Script
	// Return oldest waiting index as well as first index of waiting group of specific address.
	access(TMP_ENTITLEMENT_OWNER)
	fun getFirstWaitingIndex(hostAddress: Address): UInt32?{ 
		let key = hostAddress.toString().toLower()
		let matchGroups = self.addressGroupMap[key] ??{} 
		let waitingGroup = matchGroups[MatchStatus.waiting] ?? []
		if waitingGroup.length > 0{ 
			return waitingGroup[0]
		} else{ 
			return nil
		}
	}
	
	// Return oldest waiting index as well as first index of waitingIndices.
	access(TMP_ENTITLEMENT_OWNER)
	fun getRandomWaitingIndex(): UInt32?{ 
		if self.waitingIndices.length > 0{ 
			var iterationIndex = 0
			for waitingIndex in self.waitingIndices{ 
				assert(self.indexAddressMap.keys.contains(waitingIndex), message: "IndexAddressMap should contain index ".concat(waitingIndex.toString()))
				if let addressGroups = self.indexAddressMap[waitingIndex]{ 
					if addressGroups[MatchRole.challenger] == nil{ 
						return waitingIndex
					} else{ 
						continue
					}
				}
			}
			return nil
		} else{ 
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNextIndex(): UInt32{ 
		return self.nextIndex
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWaiting(by address: Address): [UInt32]{ 
		let key = address.toString().toLower()
		let addressGroup = self.addressGroupMap[key] ??{} 
		return addressGroup[MatchStatus.waiting] ?? []
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMatched(by address: Address): [UInt32]{ 
		let key = address.toString().toLower()
		let addressGroup = self.addressGroupMap[key] ??{} 
		return addressGroup[MatchStatus.matched] ?? []
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFinished(by address: Address): [UInt32]{ 
		let key = address.toString().toLower()
		let addressGroup = self.addressGroupMap[key] ??{} 
		return addressGroup[MatchStatus.finished] ?? []
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getHostAddress(by index: UInt32): Address?{ 
		let roleAddressMap = self.indexAddressMap[index] ??{} 
		return roleAddressMap[MatchRole.host]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getChallengerAddress(by index: UInt32): Address?{ 
		let roleAddressMap = self.indexAddressMap[index] ??{} 
		return roleAddressMap[MatchRole.challenger]
	}
	
	// Transaction
	// Register a waiting match.
	access(TMP_ENTITLEMENT_OWNER)
	fun register(host: Address): UInt32{ 
		pre{ 
			self.registerActive:
				"Registration is not active."
		}
		var currentIndex = self.nextIndex
		let key = host.toString().toLower()
		let matchGroups = self.addressGroupMap[key] ??{} 
		let waitingGroup: [UInt32] = matchGroups[MatchStatus.waiting] ?? []
		waitingGroup.append(currentIndex)
		matchGroups[MatchStatus.waiting] = waitingGroup
		self.addressGroupMap[key] = matchGroups
		self.indexAddressMap[currentIndex] ={ MatchRole.host: host}
		self.waitingIndices.append(currentIndex)
		if currentIndex == UInt32.max{ 
			// Indices is using out.
			self.registerActive = false
		} else{ 
			self.nextIndex = currentIndex + 1
		}
		emit registered(host: host, index: currentIndex)
		return currentIndex
	}
	
	// Must match with specific index in case host register slightly before.
	access(account)
	fun match(index: UInt32, challengerAddress: Address): Address?{ 
		pre{ 
			self.matchActive:
				"Matching is not active."
			self.indexAddressMap.keys.contains(index):
				"Index not found in indexAddressMap"
		}
		let roleAddressMap = self.indexAddressMap[index] ??{} 
		assert(roleAddressMap[MatchRole.host] != nil, message: "Host not found for this index.")
		assert(roleAddressMap[MatchRole.challenger] == nil, message: "Challenger already exist.")
		roleAddressMap[MatchRole.challenger] = challengerAddress
		self.indexAddressMap[index] = roleAddressMap
		let hostAddress = roleAddressMap[MatchRole.host]!
		let hostKey = hostAddress.toString().toLower()
		let addressGroup = self.addressGroupMap[hostKey] ??{} 
		let waitingGroup: [UInt32] = addressGroup[MatchStatus.waiting] ?? []
		assert(
			waitingGroup.length > 0,
			message: hostAddress.toString().concat("'s waiting group length should over 0")
		)
		if let firstIndex: Int = waitingGroup.firstIndex(of: index){ 
			let matchIndex = waitingGroup.remove(at: firstIndex)
			addressGroup[MatchStatus.waiting] = waitingGroup
			assert(matchIndex == index, message: "Match index not equal.")
			let matchedGroup: [UInt32] = addressGroup[MatchStatus.matched] ?? []
			matchedGroup.append(matchIndex)
			addressGroup[MatchStatus.matched] = matchedGroup
			self.addressGroupMap[hostKey] = addressGroup
			let challengerAddress = challengerAddress
			let challengerKey = challengerAddress.toString().toLower()
			let challengerAddressGroup = self.addressGroupMap[challengerKey] ??{} 
			let indices = challengerAddressGroup[MatchStatus.matched] ?? []
			indices.append(index)
			challengerAddressGroup[MatchStatus.matched] = indices
			self.addressGroupMap[challengerKey] = challengerAddressGroup
			assert(self.waitingIndices.contains(matchIndex), message: "WaitingIndices should include ".concat(matchIndex.toString()).concat(" before matched."))
			assert(self.matchedIndices.contains(matchIndex) == false, message: "MatchedIndices should not include ".concat(matchIndex.toString()).concat(" before matched."))
			if let waitingIndex = self.waitingIndices.firstIndex(of: matchIndex){ 
				let matchedIndex = self.waitingIndices.remove(at: waitingIndex)
				self.matchedIndices.append(matchedIndex)
				assert(self.waitingIndices.contains(matchIndex) == false, message: "WaitingIndices should not include ".concat(matchIndex.toString()).concat(" after matched."))
				assert(self.matchedIndices.contains(matchIndex), message: "MatchedIndices should include ".concat(matchIndex.toString()).concat(" after matched."))
				emit matched(host: hostAddress, challenger: challengerAddress, index: index)
				return hostAddress
			} else{ 
				panic("MatchIndex ".concat(matchIndex.toString()).concat(" should be found in waitingIndices"))
			}
		} else{ 
			panic(hostAddress.toString().concat(" not contain index: ").concat(index.toString()))
		}
		return nil
	}
	
	access(account)
	fun finish(index: UInt32){ 
		pre{ 
			self.finalizeIndices.contains(index) == false:
				"Index already finished."
			self.matchedIndices.firstIndex(of: index) != nil:
				"Index not exist in matchedIndices."
		}
		post{ 
			self.finalizeIndices.contains(index):
				"Finish failed."
		}
		let indexOfMatched = self.matchedIndices.firstIndex(of: index)!
		let finishedIndex = self.matchedIndices.remove(at: indexOfMatched)
		assert(finishedIndex == index, message: "Finish failed.")
		self.finalizeIndices.append(index)
		let roleAddressMap = self.indexAddressMap[index] ??{} 
		assert(roleAddressMap[MatchRole.host] != nil, message: "Host not found for this index.")
		assert(roleAddressMap[MatchRole.challenger] != nil, message: "Challenger already exist.")
		let hostAddress = roleAddressMap[MatchRole.host]!
		let challengerAddress = roleAddressMap[MatchRole.challenger]!
		let hostKey = hostAddress.toString().toLower()
		let challengerKey = challengerAddress.toString().toLower()
		self.moveMatchedToFinished(_for: index, key: hostKey)
		self.moveMatchedToFinished(_for: index, key: challengerKey)
	}
	
	access(self)
	fun moveMatchedToFinished(_for index: UInt32, key: String){ 
		assert(
			self.addressGroupMap.keys.contains(key),
			message: "Address key not found for this index."
		)
		let addressGroup = self.addressGroupMap[key] ??{} 
		let matchedGroup: [UInt32] = addressGroup[MatchStatus.matched] ?? []
		assert(matchedGroup.contains(index), message: "Index not found in matchedGroup.")
		let indexOfMatchedGroup = matchedGroup.firstIndex(of: index)!
		let removedIndex = matchedGroup.remove(at: indexOfMatchedGroup)
		assert(removedIndex == index, message: "Finish failed.")
		addressGroup[MatchStatus.matched] = matchedGroup
		let finishedGroup: [UInt32] = addressGroup[MatchStatus.finished] ?? []
		finishedGroup.append(index)
		addressGroup[MatchStatus.finished] = finishedGroup
		self.addressGroupMap[key] = addressGroup
	}
	
	access(all)
	enum MatchStatus: UInt8{ 
		access(all)
		case waiting
		
		access(all)
		case matched
		
		access(all)
		case finished
	}
	
	access(all)
	enum MatchRole: UInt8{ 
		access(all)
		case host
		
		access(all)
		case challenger
	}
}
