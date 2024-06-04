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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFTCollections{ 
	access(all)
	let version: UInt32
	
	access(all)
	let NFT_COLLECTION_MANAGER_PATH: StoragePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(address: Address, id: UInt64)
	
	access(all)
	event Deposit(address: Address, id: UInt64)
	
	init(){ 
		self.version = 1
		self.NFT_COLLECTION_MANAGER_PATH = /storage/NFTCollectionManager
		emit ContractInitialized()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): UInt32{ 
		return self.version
	}
	
	access(all)
	resource interface WrappedNFT{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getContractName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(): Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionPath(): PublicPath
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(): &{NonFungibleToken.NFT}
	}
	
	access(all)
	resource interface Provider{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(address: Address, withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawWrapper(address: Address, withdrawID: UInt64): @NFTWrapper
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(address: Address, batch: [UInt64], into: &{NonFungibleToken.Collection})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdrawWrappers(address: Address, batch: [UInt64]): @Collection
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowWrapper(address: Address, id: UInt64): &NFTWrapper
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(address: Address, id: UInt64): &{NonFungibleToken.NFT}
	}
	
	access(all)
	resource interface Receiver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(
			contractName: String,
			address: Address,
			collectionPath: PublicPath,
			token: @{NonFungibleToken.NFT}
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositWrapper(wrapper: @NFTWrapper)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(
			contractName: String,
			address: Address,
			collectionPath: PublicPath,
			batch: @{NonFungibleToken.Collection}
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDepositWrapper(batch: @Collection)
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowWrapper(address: Address, id: UInt64): &NFTCollections.NFTWrapper
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(address: Address, id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(
			contractName: String,
			address: Address,
			collectionPath: PublicPath,
			token: @{NonFungibleToken.NFT}
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositWrapper(wrapper: @NFTWrapper)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(
			contractName: String,
			address: Address,
			collectionPath: PublicPath,
			batch: @{NonFungibleToken.Collection}
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDepositWrapper(batch: @Collection)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs():{ Address: [UInt64]}
	}
	
	// A resource for managing collections of NFTs
	//
	access(all)
	resource NFTCollectionManager{ 
		access(self)
		let collections: @{String: Collection}
		
		init(){ 
			self.collections <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionNames(): [String]{ 
			return self.collections.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createOrBorrowCollection(_ namespace: String): &Collection{ 
			if self.collections[namespace] == nil{ 
				return self.createCollection(namespace)
			} else{ 
				return self.borrowCollection(namespace)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createCollection(_ namespace: String): &Collection{ 
			pre{ 
				self.collections[namespace] == nil:
					"Collection with that namespace already exists"
			}
			let alwaysEmpty <- self.collections[namespace] <- create Collection()
			destroy alwaysEmpty
			return &self.collections[namespace] as &NFTCollections.Collection?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollection(_ namespace: String): &Collection{ 
			pre{ 
				self.collections[namespace] != nil:
					"Collection with that namespace not found"
			}
			return &self.collections[namespace] as &NFTCollections.Collection?
		}
	}
	
	// Creates and returns a new NFTCollectionManager resource for managing many
	// different Collections
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createNewNFTCollectionManager(): @NFTCollectionManager{ 
		return <-create NFTCollectionManager()
	}
	
	// An NFT wrapped with useful information
	//
	access(all)
	resource NFTWrapper: WrappedNFT{ 
		access(self)
		let contractName: String
		
		access(self)
		let address: Address
		
		access(self)
		let collectionPath: PublicPath
		
		access(self)
		var nft: @{NonFungibleToken.NFT}?
		
		init(contractName: String, address: Address, collectionPath: PublicPath, token: @{NonFungibleToken.NFT}){ 
			self.contractName = contractName
			self.address = address
			self.collectionPath = collectionPath
			self.nft <- token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getContractName(): String{ 
			return self.contractName
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(): Address{ 
			return self.address
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionPath(): PublicPath{ 
			return self.collectionPath
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(): &{NonFungibleToken.NFT}{ 
			pre{ 
				self.nft != nil:
					"Wrapped NFT is nil"
			}
			let optionalNft <- self.nft <- nil
			let nft <- optionalNft!!
			let ret = &nft as &{NonFungibleToken.NFT}
			self.nft <-! nft
			return ret!!
		}
		
		access(contract)
		fun unwrapNFT(): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.nft != nil:
					"Wrapped NFT is nil"
			}
			let optionalNft <- self.nft <- nil
			let nft <- optionalNft!!
			return <-nft
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, Provider, Receiver{ 
		access(self)
		var collections: @{Address: ShardedNFTWrapperCollection}
		
		init(){ 
			self.collections <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(contractName: String, address: Address, collectionPath: PublicPath, token: @{NonFungibleToken.NFT}){ 
			let wrapper <- create NFTWrapper(contractName: contractName, address: address, collectionPath: collectionPath, token: <-token)
			if self.collections[address] == nil{ 
				self.collections[address] <-! NFTCollections.createEmptyShardedNFTWrapperCollection()
			}
			let collection <- self.collections.remove(key: address)!
			collection.deposit(wrapper: <-wrapper)
			self.collections[address] <-! collection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositWrapper(wrapper: @NFTWrapper){ 
			let address = wrapper.getAddress()
			if self.collections[address] == nil{ 
				self.collections[address] <-! NFTCollections.createEmptyShardedNFTWrapperCollection()
			}
			let collection <- self.collections.remove(key: address)!
			collection.deposit(wrapper: <-wrapper)
			self.collections[address] <-! collection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(contractName: String, address: Address, collectionPath: PublicPath, batch: @{NonFungibleToken.Collection}){ 
			let keys = batch.getIDs()
			for key in keys{ 
				self.deposit(contractName: contractName, address: address, collectionPath: collectionPath, token: <-batch.withdraw(withdrawID: key))
			}
			destroy batch
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDepositWrapper(batch: @Collection){ 
			var addressMap = batch.getIDs()
			for address in addressMap.keys{ 
				let ids = addressMap[address] ?? []
				for id in ids{ 
					self.depositWrapper(wrapper: <-batch.withdrawWrapper(address: address, withdrawID: id))
				}
			}
			destroy batch
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(address: Address, withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			if self.collections[address] == nil{ 
				panic("No NFT with that Address exists")
			}
			let collection <- self.collections.remove(key: address)!
			let wrapper <- collection.withdraw(withdrawID: withdrawID)
			self.collections[address] <-! collection
			let nft <- wrapper.unwrapNFT()
			destroy wrapper
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawWrapper(address: Address, withdrawID: UInt64): @NFTWrapper{ 
			if self.collections[address] == nil{ 
				panic("No NFT with that Address exists")
			}
			let collection <- self.collections.remove(key: address)!
			let wrapper <- collection.withdraw(withdrawID: withdrawID)
			self.collections[address] <-! collection
			return <-wrapper
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(address: Address, batch: [UInt64], into: &{NonFungibleToken.Collection}){ 
			for id in batch{ 
				into.deposit(token: <-self.withdraw(address: address, withdrawID: id))
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdrawWrappers(address: Address, batch: [UInt64]): @Collection{ 
			var into <- NFTCollections.createEmptyCollection()
			for id in batch{ 
				into.depositWrapper(wrapper: <-self.withdrawWrapper(address: address, withdrawID: id))
			}
			return <-into
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs():{ Address: [UInt64]}{ 
			var ids:{ Address: [UInt64]} ={} 
			for key in self.collections.keys{ 
				ids[key] = []
				for id in self.collections[key]?.getIDs() ?? []{ 
					(ids[key]!).append(id)
				}
			}
			return ids
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(address: Address, id: UInt64): &{NonFungibleToken.NFT}{ 
			return (self.borrowWrapper(address: address, id: id)!).borrowNFT()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowWrapper(address: Address, id: UInt64): &NFTWrapper{ 
			if self.collections[address] == nil{ 
				panic("No NFT with that Address exists")
			}
			let collection = &self.collections[address] as &NFTCollections.ShardedNFTWrapperCollection?
			return collection.borrowWrapper(id: id)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create NFTCollections.Collection()
	}
	
	access(all)
	resource ShardedNFTWrapperCollection{ 
		access(self)
		var collections: @{UInt64: NFTWrapperCollection}
		
		access(self)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! NFTCollections.createEmptyNFTWrapperCollection() as! @NFTWrapperCollection
				i = i + UInt64(1)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(wrapper: @NFTWrapper){ 
			let bucket = wrapper.borrowNFT().id % self.numBuckets
			let collection <- self.collections.remove(key: bucket)!
			collection.deposit(wrapper: <-wrapper)
			self.collections[bucket] <-! collection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(batch: @ShardedNFTWrapperCollection){ 
			let keys = batch.getIDs()
			for key in keys{ 
				self.deposit(wrapper: <-batch.withdraw(withdrawID: key))
			}
			destroy batch
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @NFTWrapper{ 
			let bucket = withdrawID % self.numBuckets
			let wrapper <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-wrapper
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(batch: [UInt64]): @ShardedNFTWrapperCollection{ 
			var batchCollection <- NFTCollections.createEmptyShardedNFTWrapperCollection()
			for id in batch{ 
				batchCollection.deposit(wrapper: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			var ids: [UInt64] = []
			for key in self.collections.keys{ 
				for id in self.collections[key]?.getIDs() ?? []{ 
					ids.append(id)
				}
			}
			return ids
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowWrapper(id: UInt64): &NFTWrapper{ 
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowWrapper(id: id)!
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyShardedNFTWrapperCollection(): @ShardedNFTWrapperCollection{ 
		return <-create NFTCollections.ShardedNFTWrapperCollection(numBuckets: 32)
	}
	
	// A collection of NFTWrappers
	//
	access(all)
	resource NFTWrapperCollection{ 
		access(self)
		var wrappers: @{UInt64: NFTWrapper}
		
		init(){ 
			self.wrappers <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(wrapper: @NFTWrapper){ 
			let address = wrapper.getAddress()
			let id = wrapper.borrowNFT().id
			let oldWrapper <- self.wrappers[id] <- wrapper
			if oldWrapper != nil{ 
				panic("This Collection already has an NFTWrapper with that id")
			}
			emit Deposit(address: address, id: id)
			destroy oldWrapper
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(batch: @NFTWrapperCollection){ 
			let keys = batch.getIDs()
			for key in keys{ 
				self.deposit(wrapper: <-batch.withdraw(withdrawID: key))
			}
			destroy batch
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @NFTWrapper{ 
			let wrapper <-
				self.wrappers.remove(key: withdrawID)
				?? panic("Cannot withdraw: NFTWrapper does not exist in the collection")
			emit Withdraw(address: wrapper.getAddress(), id: withdrawID)
			return <-wrapper
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(batch: [UInt64]): @NFTWrapperCollection{ 
			var batchCollection <- create NFTWrapperCollection()
			for id in batch{ 
				batchCollection.deposit(wrapper: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.wrappers.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowWrapper(id: UInt64): &NFTWrapper{ 
			return &self.wrappers[id] as &NFTCollections.NFTWrapper?
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyNFTWrapperCollection(): @NFTWrapperCollection{ 
		return <-create NFTCollections.NFTWrapperCollection()
	}
}
