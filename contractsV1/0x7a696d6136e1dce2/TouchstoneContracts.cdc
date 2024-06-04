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

	// Created by Emerald City DAO for Touchstone (https://touchstone.city/)
access(all)
contract TouchstoneContracts{ 
	access(all)
	let ContractsBookStoragePath: StoragePath
	
	access(all)
	let ContractsBookPublicPath: PublicPath
	
	access(all)
	let GlobalContractsBookStoragePath: StoragePath
	
	access(all)
	let GlobalContractsBookPublicPath: PublicPath
	
	access(all)
	enum ReservationStatus: UInt8{ 
		access(all)
		case notFound // was never made
		
		
		access(all)
		case expired // this means someone made it but their Emerald Pass expired
		
		
		access(all)
		case active // is currently active
	
	}
	
	access(all)
	resource interface ContractsBookPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getContracts(): [String]
	}
	
	access(all)
	resource ContractsBook: ContractsBookPublic{ 
		access(all)
		let contractNames:{ String: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addContract(contractName: String){ 
			pre{ 
				self.contractNames[contractName] == nil:
					"You already have a contract with this name."
			}
			let me: Address = (self.owner!).address
			self.contractNames[contractName] = true
			let globalContractsBook = TouchstoneContracts.account.storage.borrow<&GlobalContractsBook>(from: TouchstoneContracts.GlobalContractsBookStoragePath)!
			globalContractsBook.addUser(address: me)
			globalContractsBook.reserve(contractName: contractName, user: me)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeContract(contractName: String){ 
			self.contractNames.remove(key: contractName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getContracts(): [String]{ 
			return self.contractNames.keys
		}
		
		init(){ 
			self.contractNames ={} 
		}
	}
	
	access(all)
	resource interface GlobalContractsBookPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllUsers(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllReservations():{ String: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressFromContractName(contractName: String): Address?
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getReservationStatus(contractName: String): ReservationStatus
	}
	
	access(all)
	resource GlobalContractsBook: GlobalContractsBookPublic{ 
		access(all)
		let allUsers:{ Address: Bool}
		
		access(all)
		let reservedContractNames:{ String: Address}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addUser(address: Address){ 
			self.allUsers[address] = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reserve(contractName: String, user: Address){ 
			pre{ 
				self.getReservationStatus(contractName: contractName) != ReservationStatus.active:
					contractName.concat(" is already taken!")
			}
			self.reservedContractNames[contractName] = user
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeReservation(contractName: String){ 
			self.reservedContractNames.remove(key: contractName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllUsers(): [Address]{ 
			return self.allUsers.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllReservations():{ String: Address}{ 
			return self.reservedContractNames
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getReservationStatus(contractName: String): ReservationStatus{ 
			if let reservedBy = self.reservedContractNames[contractName]{ 
				return ReservationStatus.active
			}
			return ReservationStatus.notFound
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressFromContractName(contractName: String): Address?{ 
			if self.getReservationStatus(contractName: contractName) == ReservationStatus.active{ 
				return self.reservedContractNames[contractName]
			}
			return nil
		}
		
		init(){ 
			self.allUsers ={} 
			self.reservedContractNames ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createContractsBook(): @ContractsBook{ 
		return <-create ContractsBook()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUserTouchstoneCollections(user: Address): [String]{ 
		let collections =
			getAccount(user).capabilities.get<&ContractsBook>(
				TouchstoneContracts.ContractsBookPublicPath
			).borrow<&ContractsBook>()
			?? panic("This user has not set up a Collections yet.")
		return collections.getContracts()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getGlobalContractsBook(): &GlobalContractsBook{ 
		return self.account.capabilities.get<&GlobalContractsBook>(
			TouchstoneContracts.GlobalContractsBookPublicPath
		).borrow<&GlobalContractsBook>()!
	}
	
	init(){ 
		self.ContractsBookStoragePath = /storage/TouchstoneContractsBook
		self.ContractsBookPublicPath = /public/TouchstoneContractsBook
		self.GlobalContractsBookStoragePath = /storage/TouchstoneGlobalContractsBook
		self.GlobalContractsBookPublicPath = /public/TouchstoneGlobalContractsBook
		self.account.storage.save(
			<-create GlobalContractsBook(),
			to: TouchstoneContracts.GlobalContractsBookStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&GlobalContractsBook>(
				TouchstoneContracts.GlobalContractsBookStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: TouchstoneContracts.GlobalContractsBookPublicPath
		)
	}
}
