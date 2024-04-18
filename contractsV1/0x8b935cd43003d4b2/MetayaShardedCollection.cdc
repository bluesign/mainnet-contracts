/**
	Description: Central Collection for a large number of Metaya NFTs
	This contract bundles together a bunch of MomentCollection objects
	in a dictionary, and then distributes the individual Moments between them
	while implementing the same public interface
	as the default MomentCollection implementation.

	Copyright 2021 Metaya.io
	SPDX-License-Identifier: Apache-2.0
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Metaya from "./Metaya.cdc"

access(all)
contract MetayaShardedCollection{ 
	
	/// Named Paths
	access(all)
	let ShardedCollectionStoragePath: StoragePath
	
	access(all)
	let ShardedCollectionPublicPath: PublicPath
	
	/// ShardedCollection stores a dictionary of Metaya Collections
	/// A Moment is stored in the field that corresponds to its id % numBuckets
	access(all)
	resource ShardedCollection:
		Metaya.MomentCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		/// Dictionary of Metaya collections
		access(all)
		var collections: @{UInt64: Metaya.Collection}
		
		/// The number of buckets to split Moments into
		/// This makes storage more efficient and performant
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			
			// Create a new empty collection for each bucket
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! Metaya.createEmptyCollection(nftType: Type<@Metaya.Collection>()) as! @Metaya.Collection
				i = i + 1 as UInt64
			}
		}
		
		/// withdraw removes a Moment from one of the Collections 
		/// and moves it to the caller
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			// Find the bucket it should be withdrawn from
			let bucket = withdrawID % self.numBuckets
			
			// Withdraw the moment
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		/// batchWithdraw withdraws multiple tokens and returns them as a Collection
		///
		/// Parameters: ids: an array of the IDs to be withdrawn from the Collection
		///
		/// Returns: @NonFungibleToken.Collection a Collection containing the moments
		///		  that were withdrawn
		access(all)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- Metaya.createEmptyCollection(nftType: Type<@Metaya.Collection>())
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		/// deposit takes a Moment and adds it to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			
			// Find the bucket this corresponds to
			let bucket = token.id % self.numBuckets
			
			// Get the bucket reference
			let collectionRef = &self.collections[bucket] as &Metaya.Collection?
			
			// Deposit the NFT into the bucket
			collectionRef.deposit(token: <-token)
		}
		
		/// batchDeposit takes a Collection object as an argument
		/// and deposits each contained NFT into this Collection
		access(all)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the Collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		/// getIDs returns an array of the IDs that are in the Collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			var ids: [UInt64] = []
			// Concatenate IDs in all the Collections
			for key in self.collections.keys{ 
				for id in self.collections[key]?.getIDs() ?? []{ 
					ids.append(id)
				}
			}
			return ids
		}
		
		/// borrowNFT Returns a borrowed reference to a Moment in the Collection
		/// so that the caller can read data and call methods from it
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			post{ 
				result.id == id:
					"The ID of the reference is incorrect"
			}
			
			// Get the bucket of the NFT to be borrowed
			let bucket = id % self.numBuckets
			
			// Find NFT in the collections and borrow a reference
			return self.collections[bucket]?.borrowNFT(id)!!
		}
		
		/// borrowMoment Returns a borrowed reference to a Moment in the Collection
		/// so that the caller can read data and call methods from it
		/// They can use this to read its setID, playID, serialNumber,
		/// or any of the setData or Play Data associated with it by
		/// getting the setID or playID and reading those fields from
		/// the smart contract
		///
		/// Parameters: id: The ID of the NFT to get the reference for
		///
		/// Returns: A reference to the NFT
		access(all)
		fun borrowMoment(id: UInt64): &Metaya.NFT?{ 
			
			// Get the bucket of the NFT to be borrowed
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowMoment(id: id) ?? nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create ShardedCollection()
		}
	
	/// If a transaction destroys the Collection object,
	/// All the NFTs contained within are also destroyed
	}
	
	/// Creates an empty ShardedCollection and returns it to the caller
	access(all)
	fun createEmptyCollection(numBuckets: UInt64): @ShardedCollection{ 
		return <-create ShardedCollection(numBuckets: numBuckets)
	}
	
	init(){ 
		// Set named paths
		self.ShardedCollectionStoragePath = /storage/MetayaShardedMomentCollection
		self.ShardedCollectionPublicPath = /public/MetayaShardedMomentCollection
	}
}
