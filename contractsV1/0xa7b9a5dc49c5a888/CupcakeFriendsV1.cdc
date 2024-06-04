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
contract CupcakeFriendsV1{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource Cupcake: FriendlyCupcake, NotYetKnownCupcake, MyCupcake{ 
		access(self)
		let id: Int
		
		access(self)
		var accessoryId: Int?
		
		access(self)
		let friendships: @{Int: CupcakeFriendShip}
		
		access(self)
		let openFriendshipRequests: @{Int: CupcakeFriendshipRequestHolder}
		
		access(self)
		let requestedFriendships: [Int]
		
		init(id: Int){ 
			self.id = id
			self.accessoryId = nil
			self.friendships <-{} 
			self.openFriendshipRequests <-{} 
			self.requestedFriendships = []
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): Int{ 
			return self.id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			if self.id != request.getRequestedAcceptorId(){ 
				panic("Cannot accept friendships for another Cupcake")
			}
			if self.friendships[request.getRequestorId()] != nil{ 
				panic("I am already friends with this Cupcake")
			}
			self.friendships[request.getRequestorId()] <-! create CupcakeFriendShip(requestorId: request.getRequestorId(), acceptorId: self.id, creationTime: time, requestorCupcake: request.getRequestorCupcake())
			destroy request
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRequestedFriendship(otherCupcakeId: Int){ 
			let index = self.requestedFriendships.firstIndex(of: otherCupcakeId)
			if index != nil{ 
				self.requestedFriendships.remove(at: index!)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun storeRequestedFriendship(otherCupcakeId: Int){ 
			self.requestedFriendships.append(otherCupcakeId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createFriendshipRequest(myCupcake: Capability<&{NotYetKnownCupcake}>, otherCupcakeId: Int, time: UInt64): @CupcakeFriendshipRequest{ 
			return <-create CupcakeFriendshipRequest(requestorId: self.id, requestedAcceptorId: otherCupcakeId, creationTime: time, requestorCupcake: myCupcake)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun acceptBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
			let request <- holder.getRequest()
			let acceptor <- holder.getAcceptor()
			acceptor.accept(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(), time: time), time: time)
			self.accept(request: <-request, time: time)
			destroy acceptor
			destroy holder
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun denyBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			let holder <- self.openFriendshipRequests.remove(key: friendCupcake) ?? panic("No friend request from this Cupcake")
			let request <- holder.getRequest()
			let acceptor <- holder.getAcceptor()
			acceptor.deny(request: <-self.createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: request.getRequestorId(), time: time))
			destroy acceptor
			destroy request
			destroy holder
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOpenRequests(): &{Int: CupcakeFriendshipRequestHolder}{ 
			return &self.openFriendshipRequests as &{Int: CupcakeFriendshipRequestHolder}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder){ 
			self.openFriendshipRequests[request.getId()] <-! request
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriendRequests(): [CupcakeState]{ 
			let requestStates: [CupcakeState] = []
			for key in self.openFriendshipRequests.keys{ 
				let requestRef = &self.openFriendshipRequests[key] as &CupcakeFriendshipRequestHolder?
				let otherRequest = (requestRef!).getRequestRef().getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake")
				let request = (requestRef!).getRequestRef()
				requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: request.getCreationTime()))
			}
			return requestStates
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestedFriendships(): [Int]{ 
			return self.requestedFriendships
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriends(): [CupcakeState]{ 
			let requestStates: [CupcakeState] = []
			for key in self.friendships.keys{ 
				let requestRef = &self.friendships[key] as &CupcakeFriendShip?
				let otherRequest = (requestRef!).getRequestorCupcake().borrow() ?? panic("Could not borrow other cupcake")
				let creationTime = (requestRef!).getCreationTime()
				requestStates.append(CupcakeState(id: otherRequest.getId(), accessoryId: otherRequest.getAccessory(), time: creationTime))
			}
			return requestStates
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasFriendOrRequest(id: Int): Bool{ 
			if self.friendships[id] != nil{ 
				return true
			}
			if self.openFriendshipRequests[id] != nil{ 
				return true
			}
			if self.requestedFriendships.firstIndex(of: id) != nil{ 
				return true
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAccessory(id: Int){ 
			self.accessoryId = id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccessory(): Int?{ 
			return self.accessoryId
		}
	}
	
	access(all)
	struct CupcakeState{ 
		access(all)
		let id: Int
		
		access(all)
		let accessoryId: Int?
		
		access(all)
		let time: UInt64?
		
		init(id: Int, accessoryId: Int?, time: UInt64?){ 
			self.id = id
			self.accessoryId = accessoryId
			self.time = time
		}
	}
	
	access(all)
	resource interface FriendlyCupcake{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(request: @CupcakeFriendsV1.CupcakeFriendshipRequest, time: UInt64): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRequestedFriendship(otherCupcakeId: Int)
	}
	
	access(all)
	resource interface MyCupcake{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createFriendshipRequest(
			myCupcake: Capability<&{CupcakeFriendsV1.NotYetKnownCupcake}>,
			otherCupcakeId: Int,
			time: UInt64
		): @CupcakeFriendsV1.CupcakeFriendshipRequest
		
		access(TMP_ENTITLEMENT_OWNER)
		fun acceptBothSides(
			myCupcake: Capability<&{NotYetKnownCupcake}>,
			friendCupcake: Int,
			time: UInt64
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun denyBothSides(
			myCupcake: Capability<&{NotYetKnownCupcake}>,
			friendCupcake: Int,
			time: UInt64
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun storeRequestedFriendship(otherCupcakeId: Int)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAccessory(id: Int)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasFriendOrRequest(id: Int): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): Int
	}
	
	access(all)
	resource interface NotYetKnownCupcake{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun depositFriendshipRequest(
			request: @CupcakeFriendsV1.CupcakeFriendshipRequestHolder
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriendRequests(): [CupcakeState]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriends(): [CupcakeState]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestedFriendships(): [Int]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccessory(): Int?
	}
	
	access(all)
	resource CupcakeFriendshipRequestHolder{ 
		access(self)
		let request: @{Int: CupcakeFriendshipRequest}
		
		access(self)
		let acceptor: @{Int: CupcakeFriendshipAcceptor}
		
		init(request: @CupcakeFriendshipRequest, acceptor: @CupcakeFriendshipAcceptor){ 
			self.request <-{ 0: <-request}
			self.acceptor <-{ 0: <-acceptor}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequest(): @CupcakeFriendshipRequest{ 
			return <-self.request.remove(key: 0)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestRef(): &CupcakeFriendshipRequest{ 
			let requestRef = &self.request[0] as &CupcakeFriendshipRequest?
			return requestRef!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAcceptor(): @CupcakeFriendshipAcceptor{ 
			return <-self.acceptor.remove(key: 0)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): Int{ 
			let ref = &self.request[0] as &CupcakeFriendshipRequest?
			return (ref!).getRequestorId()
		}
	}
	
	access(all)
	resource CupcakeMinter{ 
		access(self)
		let usedIds: [Int]
		
		init(){ 
			self.usedIds = []
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(id: Int): @Cupcake{ 
			if self.usedIds.contains(id){ 
				panic("ID has already been minted")
			}
			self.usedIds.append(id)
			return <-create Cupcake(id: id)
		}
	}
	
	access(all)
	resource CupcakeFriendShip{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let acceptorId: Int
		
		access(self)
		let creationTime: UInt64
		
		access(self)
		let requestorCupcake: Capability<&{NotYetKnownCupcake}>
		
		init(
			requestorId: Int,
			acceptorId: Int,
			creationTime: UInt64,
			requestorCupcake: Capability<&{NotYetKnownCupcake}>
		){ 
			self.requestorId = requestorId
			self.acceptorId = acceptorId
			self.requestorCupcake = requestorCupcake
			self.creationTime = creationTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestorId(): Int{ 
			return self.requestorId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAcceptorId(): Int{ 
			return self.acceptorId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCreationTime(): UInt64{ 
			return self.creationTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestorCupcake(): Capability<&{NotYetKnownCupcake}>{ 
			return self.requestorCupcake
		}
	}
	
	access(all)
	resource CupcakeFriendshipRequest{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let requestedAcceptorId: Int
		
		access(self)
		let creationTime: UInt64
		
		access(self)
		let requestorCupcake: Capability<&{NotYetKnownCupcake}>
		
		init(
			requestorId: Int,
			requestedAcceptorId: Int,
			creationTime: UInt64,
			requestorCupcake: Capability<&{NotYetKnownCupcake}>
		){ 
			self.requestorId = requestorId
			self.requestedAcceptorId = requestedAcceptorId
			self.requestorCupcake = requestorCupcake
			self.creationTime = creationTime
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestorId(): Int{ 
			return self.requestorId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestedAcceptorId(): Int{ 
			return self.requestedAcceptorId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestorCupcake(): Capability<&{NotYetKnownCupcake}>{ 
			return self.requestorCupcake
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCreationTime(): UInt64{ 
			return self.creationTime
		}
	}
	
	access(all)
	resource CupcakeFriendshipAcceptor{ 
		access(self)
		let requestorId: Int
		
		access(self)
		let cupcake: Capability<&{FriendlyCupcake}>
		
		init(requestorId: Int, cupcake: Capability<&{FriendlyCupcake}>){ 
			self.requestorId = requestorId
			self.cupcake = cupcake
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			if request.getRequestorId() != self.requestorId{ 
				panic("I cannot accept friendship requests from you")
			}
			let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake")
			cupcake.accept(request: <-request, time: time)
			cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deny(request: @CupcakeFriendshipRequest){ 
			if request.getRequestorId() != self.requestorId{ 
				panic("I cannot deny friendship requests from you")
			}
			let cupcake = self.cupcake.borrow() ?? panic("Cannot borrow Cupcake")
			cupcake.removeRequestedFriendship(otherCupcakeId: self.requestorId)
			destroy request
		}
	}
	
	access(all)
	resource CupcakeCollection: CupcakeReceiver, FriendlyCupcake, NotYetKnownCupcake, MyCupcake{ 
		access(self)
		let ownedCupcakes: @{UInt64: Cupcake}
		
		init(){ 
			self.ownedCupcakes <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositCupcake(cupcake: @Cupcake){ 
			if self.hasCupcake(){ 
				panic("Cannot own more than one Cupcake")
			}
			self.ownedCupcakes[0] <-! cupcake
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCupcake(): &Cupcake{ 
			if !self.hasCupcake(){ 
				panic("Do not have a Cupcake yet")
			}
			return (&self.ownedCupcakes[0] as &Cupcake?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasCupcake(): Bool{ 
			return self.ownedCupcakes.length != 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(request: @CupcakeFriendshipRequest, time: UInt64){ 
			self.getCupcake().accept(request: <-request, time: time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRequestedFriendship(otherCupcakeId: Int){ 
			self.getCupcake().removeRequestedFriendship(otherCupcakeId: otherCupcakeId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun storeRequestedFriendship(otherCupcakeId: Int){ 
			self.getCupcake().storeRequestedFriendship(otherCupcakeId: otherCupcakeId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createFriendshipRequest(myCupcake: Capability<&{NotYetKnownCupcake}>, otherCupcakeId: Int, time: UInt64): @CupcakeFriendshipRequest{ 
			return <-self.getCupcake().createFriendshipRequest(myCupcake: myCupcake, otherCupcakeId: otherCupcakeId, time: time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositFriendshipRequest(request: @CupcakeFriendshipRequestHolder){ 
			self.getCupcake().depositFriendshipRequest(request: <-request)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): Int{ 
			return self.getCupcake().getId()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriendRequests(): [CupcakeState]{ 
			return self.getCupcake().getFriendRequests()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFriends(): [CupcakeState]{ 
			return self.getCupcake().getFriends()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun acceptBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			self.getCupcake().acceptBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun denyBothSides(myCupcake: Capability<&{NotYetKnownCupcake}>, friendCupcake: Int, time: UInt64){ 
			self.getCupcake().denyBothSides(myCupcake: myCupcake, friendCupcake: friendCupcake, time: time)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequestedFriendships(): [Int]{ 
			return self.getCupcake().getRequestedFriendships()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccessory(): Int?{ 
			return self.getCupcake().getAccessory()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAccessory(id: Int){ 
			self.getCupcake().setAccessory(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasFriendOrRequest(id: Int): Bool{ 
			return self.getCupcake().hasFriendOrRequest(id: id)
		}
	}
	
	access(all)
	resource interface CupcakeReceiver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun depositCupcake(cupcake: @CupcakeFriendsV1.Cupcake): Void
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @CupcakeCollection{ 
		return <-create CupcakeCollection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun requestFriendship(
		myCupcakeRef: Capability<&{MyCupcake}>,
		notYetKnownMyCupcakeRef: Capability<&{NotYetKnownCupcake}>,
		friendlyCupcakeRef: Capability<&{FriendlyCupcake}>,
		otherCupcakeRef: Capability<&{NotYetKnownCupcake}>,
		time: UInt64
	){ 
		let myCupcake = myCupcakeRef.borrow() ?? panic("Cannot borrow my Cupcake")
		let otherCupcake = otherCupcakeRef.borrow() ?? panic("Cannot borrow other Cupcake")
		if myCupcake.hasFriendOrRequest(id: otherCupcake.getId()){ 
			panic("I am already friends with this cupcake, it has requested to be friends with me, or i requested to be friends with it")
		}
		if myCupcake.getId() == otherCupcake.getId(){ 
			panic("I cannot be friends with myself")
		}
		let request <-
			myCupcake.createFriendshipRequest(
				myCupcake: notYetKnownMyCupcakeRef,
				otherCupcakeId: otherCupcake.getId(),
				time: time
			)
		let acceptor <-
			create CupcakeFriendshipAcceptor(
				requestorId: otherCupcake.getId(),
				cupcake: friendlyCupcakeRef
			)
		let holder <-
			create CupcakeFriendshipRequestHolder(request: <-request, acceptor: <-acceptor)
		myCupcake.storeRequestedFriendship(otherCupcakeId: otherCupcake.getId())
		otherCupcake.depositFriendshipRequest(request: <-holder)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun setupCollection(account: AuthAccount){ 
		account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
		account.link<&{CupcakeReceiver, NotYetKnownCupcake}>(
			self.CollectionPublicPath,
			target: self.CollectionStoragePath
		)
		account.link<&{FriendlyCupcake, MyCupcake}>(
			self.CollectionPrivatePath,
			target: self.CollectionStoragePath
		)
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/barcampCupcakeCollectionV1
		self.CollectionPrivatePath = /private/barcampCupcakeCollectionV1
		self.CollectionPublicPath = /public/barcampCupcakeCollectionV1
		self.MinterStoragePath = /storage/barcampCupcakeMinterV1
		self.setupCollection(account: self.account)
		self.account.storage.save(<-create CupcakeMinter(), to: self.MinterStoragePath)
	}
}
