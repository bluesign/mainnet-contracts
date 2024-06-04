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

	// Created by ethos multiverse inc. for Jade(https://jade.ethosnft.com/)
access(all)
contract JadeContracts{ 
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
		case notFound
		
		access(all)
		case active
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
		
		init(){ 
			self.contractNames ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addContract(contractName: String){ 
			pre{ 
				self.contractNames[contractName] == nil:
					"Contract already exists."
			}
			let me: Address = (self.owner!).address
			self.contractNames[contractName] = true
			let globalContractsBook: &JadeContracts.GlobalContractsBook = JadeContracts.account.storage.borrow<&GlobalContractsBook>(from: JadeContracts.GlobalContractsBookStoragePath)!
			let users: [Address] = globalContractsBook.getAllUsers()
			let containsAddress: Bool = users.contains(me)
			if !containsAddress{ 
				globalContractsBook.addUser(address: me)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getContracts(): [String]{ 
			return self.contractNames.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeContract(contractName: String){ 
			self.contractNames.remove(key: contractName)
		}
	}
	
	access(all)
	resource interface GlobalContractsBookPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllUsers(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressFromContractName(contractName: String): Address?
	}
	
	access(all)
	resource GlobalContractsBook: GlobalContractsBookPublic{ 
		access(all)
		let allUsers:{ Address: Bool}
		
		access(all)
		let reservedContractNames:{ String: Address}
		
		init(){ 
			self.allUsers ={} 
			self.reservedContractNames ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addUser(address: Address){ 
			pre{ 
				self.allUsers[address] == nil:
					"User already exists."
			}
			self.allUsers[address] = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reserve(contractName: String, user: Address){ 
			pre{ 
				self.getReservationStatus(contractName: contractName) != ReservationStatus.active:
					contractName.concat(" is already reserved.")
			}
			self.reservedContractNames[contractName] = user
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeReservation(contractName: String){ 
			self.reservedContractNames.remove(key: contractName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllReservations():{ String: Address}{ 
			return self.reservedContractNames
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addContractName(contractName: String, address: Address){ 
			pre{ 
				self.reservedContractNames[contractName] == nil:
					"Contract name already exists."
			}
			self.reservedContractNames[contractName] = address
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllUsers(): [Address]{ 
			return self.allUsers.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getReservationStatus(contractName: String): ReservationStatus{ 
			if self.reservedContractNames[contractName] != nil{ 
				return ReservationStatus.active
			}
			return ReservationStatus.notFound
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressFromContractName(contractName: String): Address?{ 
			if self.getReservationStatus(contractName: contractName) == ReservationStatus.active{ 
				return self.reservedContractNames[contractName]!
			}
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createContractsBook(): @ContractsBook{ 
		return <-create ContractsBook()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUserJadeCollections(user: Address): [String]{ 
		let collections: &JadeContracts.ContractsBook =
			getAccount(user).capabilities.get<&JadeContracts.ContractsBook>(
				JadeContracts.ContractsBookPublicPath
			).borrow<&JadeContracts.ContractsBook>()
			?? panic("Could not borrow JadeContracts.ContractsBookPublic from user account")
		return collections.getContracts()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getGlobalContractsBook(): &GlobalContractsBook{ 
		return self.account.capabilities.get<&GlobalContractsBook>(
			JadeContracts.GlobalContractsBookPublicPath
		).borrow<&GlobalContractsBook>()!
	}
	
	init(){ 
		self.ContractsBookStoragePath = /storage/JadeContractsBook
		self.ContractsBookPublicPath = /public/JadeContractsBook
		self.GlobalContractsBookStoragePath = /storage/JadeGlobalContractsBook
		self.GlobalContractsBookPublicPath = /public/JadeGlobalContractsBook
		self.account.storage.save(
			<-create GlobalContractsBook(),
			to: JadeContracts.GlobalContractsBookStoragePath
		)
		var capability_1 =
			self.account.capabilities.storage.issue<&GlobalContractsBook>(
				JadeContracts.GlobalContractsBookStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: JadeContracts.GlobalContractsBookPublicPath
		)
	}
}
