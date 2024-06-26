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

	// Used for managing access lists on the BC. It does not manage the 
// minting process, only the access lists.
access(all)
contract TheFabricantAccessList{ 
	
	// -----------------------------------------------------------------------
	// Paths
	// -----------------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AccessListStoragePath: StoragePath
	
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event AccessListDetailsCreated(
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListDetailUpdated(
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListDetailDeleted(
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListDetailsIsActiveUpdated(
		isActive: Bool,
		onlyUseTestingList: Bool,
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListDetailsOnlyUseTestingListUpdated(
		isActive: Bool,
		onlyUseTestingList: Bool,
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListAddressesAdded(
		accessListDetailsId: UInt64,
		addresses:{ 
			Address: Bool
		},
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AddressRemovedFromAccessList(
		accessListDetailsId: UInt64,
		address: Address,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AddressRemovedFromTestingList(
		accessListDetailsId: UInt64,
		address: Address,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event AccessListEmptied(
		isActive: Bool,
		onlyUseTestingList: Bool,
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	access(all)
	event TestingListEmptied(
		isActive: Bool,
		onlyUseTestingList: Bool,
		id: UInt64,
		collection: String,
		description: String?,
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	// TODO:
	access(all)
	event IsAccessListClosedChanged()
	
	access(all)
	event TestingListAddressesAdded(
		accessListDetailsId: UInt64,
		addresses:{ 
			Address: Bool
		},
		accessListStoragePath: String,
		testingListStoragePath: String
	)
	
	// -----------------------------------------------------------------------
	// Contract State
	// -----------------------------------------------------------------------
	access(self)
	var accessListDetails:{ UInt64: AccessListDetails}
	
	access(self)
	var testingLists:{ UInt64:{ Address: Bool}}
	
	access(contract)
	var nextAccessListId: UInt64
	
	// -----------------------------------------------------------------------
	// Address List Struct
	// -----------------------------------------------------------------------
	// * The AL struct can represent an internal testing list or an extenral access list.
	// * It is saved to the Admin's account storage under a constructed storage path.
	// * It is linked to a public path, exposing the AddressListPublic interface.
	// * The AL struct is distinct from the AccessListDetails struct to minimise the
	// size of the AL struct in storage (and therefore to maximise the number of
	// addresses that can be stored).
	// * The AL struct is stored in account storage to ensure that the size of other AL 
	// structs don't impact the computational cost of accessing individual AL structs.
	// 
	access(all)
	struct interface AddressListPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressList():{ Address: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressListLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun containsAddress(address: Address): Bool
	}
	
	// An AddressList can be an AccessList or a TestingList
	access(all)
	struct AddressList: AddressListPublic{ 
		access(self)
		var addressList:{ Address: Bool}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressList():{ Address: Bool}{ 
			return self.addressList
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddressListLength(): Int{ 
			return self.addressList.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun containsAddress(address: Address): Bool{ 
			return self.addressList.containsKey(address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAddressesToAddressList(addressDict:{ Address: Bool}){ 
			var i = 0
			while i < addressDict.length{ 
				self.addressList.insert(key: addressDict.keys[i], addressDict.values[i])
				i = i + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAddressFromAddressList(address: Address): Bool{ 
			if !self.addressList.containsKey(address){ 
				return false
			} else{ 
				self.addressList.remove(key: address)
				return true
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun emptyAddressList(){ 
			self.addressList ={} 
		}
		
		init(){ 
			self.addressList ={} 
		}
	}
	
	// -----------------------------------------------------------------------
	// Access List Details
	// -----------------------------------------------------------------------
	// * Contains the details for a related Address List struct and maintains
	// the open/closed state.
	// * Used to determine if an address has access via the checkAccessFor(address:)
	// function.
	access(all)
	struct AccessListDetails{ 
		
		// Identifier for ALD, but also the corresponding AL and TL
		access(contract)
		var id: UInt64
		
		access(contract)
		var collection: String
		
		access(contract)
		var description: String?
		
		access(contract)
		var dateCreated: UFix64
		
		access(contract)
		var accessListStoragePath: StoragePath
		
		access(contract)
		var testingListStoragePath: StoragePath
		
		access(contract)
		var accessListPublicPath: PublicPath
		
		access(contract)
		var testingListPublicPath: PublicPath
		
		access(contract)
		var isActive: Bool
		
		access(contract)
		var onlyUseTestingList: Bool
		
		access(self)
		fun isOpenExternally(): Bool{ 
			if self.isOpen() && !self.onlyUseTestingList{ 
				return true
			}
			return false
		}
		
		access(self)
		fun isOpenInternally(): Bool{ 
			if self.isOpen() && self.onlyUseTestingList{ 
				return true
			}
			return false
		}
		
		access(self)
		fun isOpen(): Bool{ 
			if self.isActive{ 
				return true
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccessListOpenState():{ String: Bool}{ 
			var state:{ String: Bool} ={} 
			state["isOpen"] = self.isOpen()
			state["isOpenExternally"] = self.isOpenExternally()
			state["isOpenInternally"] = self.isOpenInternally()
			return state
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccessListDetails():{ String: AnyStruct}{ 
			var ret:{ String: AnyStruct} ={} 
			ret["id"] = self.id
			ret["collection"] = self.collection
			ret["description"] = self.description
			ret["dateCreated"] = self.dateCreated
			ret["onlyUseTestingList"] = self.onlyUseTestingList
			ret["isOpenExternally"] = self.isOpenExternally()
			ret["isOpenInternally"] = self.isOpenInternally()
			ret["isOpen"] = self.isOpen()
			ret["accessListLength"] = self.borrowAccessList().getAddressListLength()
			ret["testingListLength"] = self.borrowTestingList().getAddressListLength()
			return ret
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIsActive(isActive: Bool){ 
			self.isActive = isActive
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setOnlyUseInternalTestingList(useTestingList: Bool){ 
			self.onlyUseTestingList = useTestingList
		}
		
		// NOTE: This is the function that should be used for determining
		// access via the contract level doesAddressHaveAccess()!
		access(TMP_ENTITLEMENT_OWNER)
		fun checkAccessFor(address: Address): Bool{ 
			if self.isOpenInternally(){ 
				// In testing mode
				let testingList = self.borrowTestingList()
				return testingList.containsAddress(address: address)
			}
			if self.isOpenExternally(){ 
				// NOT in testing mode
				let accessList = self.borrowAccessList()
				return accessList.containsAddress(address: address)
			}
			return false
		}
		
		// NOTE: WARNING! This function should not be used for determining access.
		// Use doesAddressHaveAccess for access rights.
		// This function tells you what lists the address is in and what the state of the
		// ALD currently is.
		access(TMP_ENTITLEMENT_OWNER)
		fun addressIsInList(address: Address):{ String: AnyStruct}{ 
			var ret:{ String: AnyStruct} ={} 
			ret["AccessListDetailsId"] = self.id
			ret["isInAccessList"] = self.borrowAccessList().containsAddress(address: address)
			ret["isInTestingList"] = self.borrowTestingList().containsAddress(address: address)
			ret["isOpenExternally"] = self.isOpenExternally()
			ret["isOpenInternally"] = self.isOpenInternally()
			ret["isOpen"] = self.isOpen()
			return ret
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateAccessListDetails(collection: String?, description: String?){ 
			if let collection = collection{ 
				self.collection = collection
			}
			if let description = description{ 
				self.description = description
			}
		}
		
		access(self)
		fun borrowAccessList(): &AddressList{ 
			return TheFabricantAccessList.account.capabilities.get<&AddressList>(
				self.accessListPublicPath
			).borrow()
			?? panic("No access list exists in storage for this AccessListDetails")
		}
		
		access(self)
		fun borrowTestingList(): &AddressList{ 
			return TheFabricantAccessList.account.capabilities.get<&AddressList>(
				self.testingListPublicPath
			).borrow()
			?? panic("No access list exists in storage for this AccessListDetails")
		}
		
		init(collection: String, description: String?){ 
			pre{ 
				!TheFabricantAccessList.accessListDetails.containsKey(TheFabricantAccessList.nextAccessListId)
			}
			self.collection = collection
			self.description = description
			self.dateCreated = getCurrentBlock().timestamp
			self.id = TheFabricantAccessList.nextAccessListId
			let masterPathString = TheFabricantAccessList.AccessListStoragePath.toString()
			let accessListString = "_accessLists_".concat(self.id.toString())
			let accessListStoragePathString = masterPathString.concat(accessListString)
			// Remove /storage/ by slicing
			let accessListPathString =
				accessListStoragePathString.slice(from: 9, upTo: accessListStoragePathString.length)
			let testingListString = "_testingLists_".concat(self.id.toString())
			let testingListStoragePathString = masterPathString.concat(testingListString)
			// Remove /storage/ by slicing
			let testingListPathString =
				testingListStoragePathString.slice(
					from: 9,
					upTo: testingListStoragePathString.length
				)
			self.accessListStoragePath = StoragePath(identifier: accessListPathString)!
			self.testingListStoragePath = StoragePath(identifier: testingListPathString)!
			self.accessListPublicPath = PublicPath(identifier: accessListPathString)!
			self.testingListPublicPath = PublicPath(identifier: testingListPathString)!
			self.isActive = false
			self.onlyUseTestingList = true
		}
	}
	
	// -----------------------------------------------------------------------
	// Admin Resource
	// -----------------------------------------------------------------------
	// * Used to control CRUD ALDs + ALs. 
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setIsActive(accessListDetailsId: UInt64, isActive: Bool){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("Can't setIsActive as no AccessListDetail exists with this id!")
			accessListDetails.setIsActive(isActive: isActive)
			TheFabricantAccessList.accessListDetails[accessListDetailsId] = accessListDetails
			emit AccessListDetailsIsActiveUpdated(
				isActive: accessListDetails.isActive,
				onlyUseTestingList: accessListDetails.onlyUseTestingList,
				id: accessListDetails.id,
				collection: accessListDetails.collection,
				description: accessListDetails.description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		// NOTE: WARNING! Setting this to false will open up the external (public) access list!
		access(TMP_ENTITLEMENT_OWNER)
		fun setOnlyUseInternalTestingList(accessListDetailsId: UInt64, useTestingList: Bool){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic(
					"Can't set onlyUseTestingList as no AccessListDetails with this id exists!"
				)
			accessListDetails.setOnlyUseInternalTestingList(useTestingList: useTestingList)
			TheFabricantAccessList.accessListDetails[accessListDetailsId] = accessListDetails
			emit AccessListDetailsOnlyUseTestingListUpdated(
				isActive: accessListDetails.isActive,
				onlyUseTestingList: accessListDetails.onlyUseTestingList,
				id: accessListDetails.id,
				collection: accessListDetails.collection,
				description: accessListDetails.description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		// The user must create an ALD before creating an AL
		access(TMP_ENTITLEMENT_OWNER)
		fun createAccessListDetails(collection: String, description: String?){ 
			let accessListDetails: AccessListDetails =
				TheFabricantAccessList.AccessListDetails(
					collection: collection,
					description: description
				)
			TheFabricantAccessList.accessListDetails[accessListDetails.id] = accessListDetails
			TheFabricantAccessList.nextAccessListId = TheFabricantAccessList.nextAccessListId + 1
			var accessList: TheFabricantAccessList.AddressList =
				TheFabricantAccessList.AddressList()
			var testingList: TheFabricantAccessList.AddressList =
				TheFabricantAccessList.AddressList()
			TheFabricantAccessList.account.storage.save(
				accessList,
				to: TheFabricantAccessList.constructAccessListStoragePath(
					accessListDetailsId: accessListDetails.id
				)
			)
			TheFabricantAccessList.account.storage.save(
				testingList,
				to: TheFabricantAccessList.constructTestingListStoragePath(
					accessListDetailsId: accessListDetails.id
				)
			)
			TheFabricantAccessList.account.link<&AddressList>(
				TheFabricantAccessList.constructAccessListPublicPath(
					accessListDetailsId: accessListDetails.id
				),
				target: TheFabricantAccessList.constructAccessListStoragePath(
					accessListDetailsId: accessListDetails.id
				)
			)
			TheFabricantAccessList.account.link<&AddressList>(
				TheFabricantAccessList.constructTestingListPublicPath(
					accessListDetailsId: accessListDetails.id
				),
				target: TheFabricantAccessList.constructTestingListStoragePath(
					accessListDetailsId: accessListDetails.id
				)
			)
			emit AccessListDetailsCreated(
				id: accessListDetails.id,
				collection: collection,
				description: description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateAccessListDetails(
			accessListDetailsId: UInt64,
			collection: String?,
			description: String?
		){ 
			let accessListDetails: AccessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("Can't update details of AccessListDetails as no ALD with this id exists!")
			accessListDetails.updateAccessListDetails(
				collection: collection,
				description: description
			)
			TheFabricantAccessList.accessListDetails[accessListDetailsId] = accessListDetails
			emit AccessListDetailUpdated(
				id: accessListDetails.id,
				collection: accessListDetails.collection,
				description: accessListDetails.description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteAccessListDetails(accessListDetailsId: UInt64){ 
			// Delete entire details and list from top level dictionary
			pre{ 
				TheFabricantAccessList.accessListDetails[accessListDetailsId] != nil:
					"No accessListDetails exists with this Id"
			}
			let accessListDetails = TheFabricantAccessList.accessListDetails[accessListDetailsId]
			TheFabricantAccessList.accessListDetails.remove(key: accessListDetailsId)
			
			// Unlink and delete access list and testing list
			TheFabricantAccessList.account.unlink(
				TheFabricantAccessList.constructAccessListPublicPath(
					accessListDetailsId: accessListDetailsId
				)
			)
			TheFabricantAccessList.account.unlink(
				TheFabricantAccessList.constructTestingListPublicPath(
					accessListDetailsId: accessListDetailsId
				)
			)
			// Loading a struct and doing nothing with it is equivalent to destroying a resource
			let accessList =
				TheFabricantAccessList.account.storage.load<AddressList>(
					from: TheFabricantAccessList.constructAccessListStoragePath(
						accessListDetailsId: accessListDetailsId
					)
				)
			let testingList =
				TheFabricantAccessList.account.storage.load<AddressList>(
					from: TheFabricantAccessList.constructTestingListStoragePath(
						accessListDetailsId: accessListDetailsId
					)
				)
			emit AccessListDetailDeleted(
				id: (accessListDetails!).id,
				collection: (accessListDetails!).collection,
				description: (accessListDetails!).description,
				accessListStoragePath: (accessListDetails!).accessListStoragePath.toString(),
				testingListStoragePath: (accessListDetails!).testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAddressesToAccessList(accessListDetailsId: UInt64, addresses:{ Address: Bool}){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("No AccessListDetails exists with this id")
			let addressList = self.borrowAccessList(accessListDetailsId: accessListDetailsId)
			addressList.addAddressesToAddressList(addressDict: addresses)
			emit AccessListAddressesAdded(
				accessListDetailsId: accessListDetailsId,
				addresses: addresses,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAddressFromAccessList(accessListDetailsId: UInt64, address: Address): Bool{ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic(
					"Can't remove address from AL as no AccessListDetails exists with this id!"
				)
			let addressRemoved: Bool =
				self.borrowAccessList(accessListDetailsId: accessListDetailsId)
					.removeAddressFromAddressList(address: address)
			if addressRemoved{ 
				emit AddressRemovedFromAccessList(accessListDetailsId: accessListDetailsId, address: address, accessListStoragePath: accessListDetails.accessListStoragePath.toString(), testingListStoragePath: accessListDetails.testingListStoragePath.toString())
			}
			return addressRemoved
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun emptyAccessList(accessListDetailsId: UInt64){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("No AccessListDetails exists with this id")
			self.borrowAccessList(accessListDetailsId: accessListDetailsId).emptyAddressList()
			emit AccessListEmptied(
				isActive: accessListDetails.isActive,
				onlyUseTestingList: accessListDetails.onlyUseTestingList,
				id: accessListDetails.id,
				collection: accessListDetails.collection,
				description: accessListDetails.description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAddressesToTestingList(accessListDetailsId: UInt64, addresses:{ Address: Bool}){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("No AccessListDetails exists with this id")
			let addressList = self.borrowTestingList(accessListDetailsId: accessListDetailsId)
			addressList.addAddressesToAddressList(addressDict: addresses)
			emit TestingListAddressesAdded(
				accessListDetailsId: accessListDetailsId,
				addresses: addresses,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAddressFromTestingList(accessListDetailsId: UInt64, address: Address): Bool{ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("No AccessListDetail exists with this id")
			let addressRemoved: Bool =
				self.borrowTestingList(accessListDetailsId: accessListDetailsId)
					.removeAddressFromAddressList(address: address)
			if addressRemoved{ 
				emit AddressRemovedFromTestingList(accessListDetailsId: accessListDetailsId, address: address, accessListStoragePath: accessListDetails.accessListStoragePath.toString(), testingListStoragePath: accessListDetails.testingListStoragePath.toString())
			}
			return addressRemoved
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun emptyTestingList(accessListDetailsId: UInt64){ 
			let accessListDetails =
				TheFabricantAccessList.accessListDetails[accessListDetailsId]
				?? panic("No AccessListDetails exists with this id")
			self.borrowTestingList(accessListDetailsId: accessListDetailsId).emptyAddressList()
			emit TestingListEmptied(
				isActive: accessListDetails.isActive,
				onlyUseTestingList: accessListDetails.onlyUseTestingList,
				id: accessListDetails.id,
				collection: accessListDetails.collection,
				description: accessListDetails.description,
				accessListStoragePath: accessListDetails.accessListStoragePath.toString(),
				testingListStoragePath: accessListDetails.testingListStoragePath.toString()
			)
		}
		
		access(self)
		fun borrowAccessList(accessListDetailsId: UInt64): &AddressList{ 
			return TheFabricantAccessList.account.storage.borrow<&AddressList>(
				from: TheFabricantAccessList.constructAccessListStoragePath(
					accessListDetailsId: accessListDetailsId
				)
			)
			?? panic("No access list exists in storage for this AccessListDetails")
		}
		
		access(self)
		fun borrowTestingList(accessListDetailsId: UInt64): &AddressList{ 
			return TheFabricantAccessList.account.storage.borrow<&AddressList>(
				from: TheFabricantAccessList.constructTestingListStoragePath(
					accessListDetailsId: accessListDetailsId
				)
			)
			?? panic("No access list exists in storage for this AccessListDetails")
		}
	}
	
	// -----------------------------------------------------------------------
	// Public Query Functions
	// -----------------------------------------------------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun getAccessList(accessListDetailsId: UInt64):{ Address: Bool}?{ 
		if let accessListDetails = TheFabricantAccessList.accessListDetails[accessListDetailsId]{ 
			if let addressListRef = TheFabricantAccessList.account.capabilities.get<&AddressList>(accessListDetails.accessListPublicPath).borrow(){ 
				return addressListRef.getAddressList()
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllAccessLists():{ UInt64:{ Address: Bool}}{ 
		let keys: [UInt64] = TheFabricantAccessList.accessListDetails.keys
		var ret:{ UInt64:{ Address: Bool}} ={} 
		var i: UInt64 = 1
		while i <= UInt64(keys.length){ 
			let accessListDetails = TheFabricantAccessList.accessListDetails[i as! UInt64] ?? nil
			let publicPath = (accessListDetails!).accessListPublicPath
			if let addressListRef = TheFabricantAccessList.account.capabilities.get<&AddressList>((accessListDetails!).accessListPublicPath).borrow(){ 
				let addressList = addressListRef.getAddressList()
				ret[i] = addressList
			}
			i = i + 1
		}
		return ret
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTestingList(accessListDetailsId: UInt64):{ Address: Bool}?{ 
		if let accessListDetails = TheFabricantAccessList.accessListDetails[accessListDetailsId]{ 
			if let addressListRef = TheFabricantAccessList.account.capabilities.get<&AddressList>(accessListDetails.testingListPublicPath).borrow(){ 
				return addressListRef.getAddressList()
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllTestingLists():{ UInt64:{ Address: Bool}}{ 
		let keys: [UInt64] = TheFabricantAccessList.accessListDetails.keys
		var ret:{ UInt64:{ Address: Bool}} ={} 
		var i: Int = 1
		while i < keys.length{ 
			let accessListDetails = TheFabricantAccessList.accessListDetails[i as! UInt64] ?? nil
			if accessListDetails == nil{ 
				return ret
			}
			let publicPath = (accessListDetails!).testingListPublicPath
			if let addressListRef = TheFabricantAccessList.account.capabilities.get<&AddressList>((accessListDetails!).testingListPublicPath).borrow(){ 
				let addressList = addressListRef.getAddressList()
				ret[i as! UInt64] = addressList
			}
		}
		return ret
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAccessListDetails(accessListDetailsId: UInt64):{ String: AnyStruct}?{ 
		if let accessListDetails = self.accessListDetails[accessListDetailsId]{ 
			return accessListDetails.getAccessListDetails()
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllAccessListDetails():{ UInt64: TheFabricantAccessList.AccessListDetails}{ 
		return TheFabricantAccessList.accessListDetails
	}
	
	// NOTE: WARNING This should not be used to grant access to addresses.
	// Use checkAccessForAddress() for granting access.
	// This should only be used to check if an address is on a list or not,
	// remember that an AL may not be active (hence why you should not use 
	// this to grant access)
	// This function returns a dict containing
	// a Bool that determines if the address has access and details on the
	// state of the ALD.
	access(TMP_ENTITLEMENT_OWNER)
	fun isAddressInList(accessListDetailsId: UInt64, address: Address):{ String: AnyStruct}?{ 
		if let accessListDetail = TheFabricantAccessList.accessListDetails[accessListDetailsId]{ 
			return accessListDetail.addressIsInList(address: address)
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkAccessForAddress(accessListDetailsId: UInt64, address: Address): Bool{ 
		if let accessListDetail = TheFabricantAccessList.accessListDetails[accessListDetailsId]{ 
			return accessListDetail.checkAccessFor(address: address)
		}
		return false
	}
	
	// -----------------------------------------------------------------------
	// Public Utility Functions
	// -----------------------------------------------------------------------
	access(TMP_ENTITLEMENT_OWNER)
	fun constructAccessListStoragePath(accessListDetailsId: UInt64): StoragePath{ 
		let masterPathString = TheFabricantAccessList.AccessListStoragePath.toString()
		let accessListString = "_accessLists_".concat(accessListDetailsId.toString())
		let accessListStoragePathString = masterPathString.concat(accessListString)
		// Remove /storage/ by slicing
		let accessListPathString =
			accessListStoragePathString.slice(from: 9, upTo: accessListStoragePathString.length)
		return StoragePath(identifier: accessListPathString)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun constructAccessListPublicPath(accessListDetailsId: UInt64): PublicPath{ 
		let masterPathString = TheFabricantAccessList.AccessListStoragePath.toString()
		let accessListString = "_accessLists_".concat(accessListDetailsId.toString())
		let accessListStoragePathString = masterPathString.concat(accessListString)
		// Remove /storage/ by slicing
		let accessListPathString =
			accessListStoragePathString.slice(from: 9, upTo: accessListStoragePathString.length)
		return PublicPath(identifier: accessListPathString)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun constructTestingListStoragePath(accessListDetailsId: UInt64): StoragePath{ 
		let masterPathString = TheFabricantAccessList.AccessListStoragePath.toString()
		let testingListString = "_testingLists_".concat(accessListDetailsId.toString())
		let testingListStoragePathString = masterPathString.concat(testingListString)
		// Remove /storage/ by slicing
		let testingListPathString =
			testingListStoragePathString.slice(from: 9, upTo: testingListStoragePathString.length)
		return StoragePath(identifier: testingListPathString)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun constructTestingListPublicPath(accessListDetailsId: UInt64): PublicPath{ 
		let masterPathString = TheFabricantAccessList.AccessListStoragePath.toString()
		let testingListString = "_testingLists_".concat(accessListDetailsId.toString())
		let testingListStoragePathString = masterPathString.concat(testingListString)
		// Remove /storage/ by slicing
		let testingListPathString =
			testingListStoragePathString.slice(from: 9, upTo: testingListStoragePathString.length)
		return PublicPath(identifier: testingListPathString)!
	}
	
	init(){ 
		self.AdminStoragePath = /storage/TheFabricantAccessListAdminStoragePath001
		self.AccessListStoragePath = /storage/TheFabricantAccessListStoragePath001
		self.accessListDetails ={} 
		self.nextAccessListId = 1
		self.testingLists ={} 
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
