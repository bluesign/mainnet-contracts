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

	/*
	Description: Central Collection for a large number of TopShot
				 NFTs

	authors: Joshua Hannan joshua.hannan@dapperlabs.com
			 Bastian Muller bastian@dapperlabs.com

	This resource object looks and acts exactly like a TopShot MomentCollection
	and (in a sense) shouldn’t have to exist! 

	The problem is that Cadence currently has a limitation where 
	storing more than ~100k objects in a single dictionary or array can fail.

	Most MomentCollections are likely to be much, much smaller than this, 
	and that limitation will be removed in a future iteration of Cadence, 
	so most people will never need to worry about it.

	However! The main TopShot administration account DOES need to worry about it
	because it frequently needs to mint >10k Moments for sale, 
	and could easily end up needing to hold more than 100k Moments at one time.
	
	Until Cadence gets an update, that leaves us in a bit of a pickle!

	This contract bundles together a bunch of MomentCollection objects 
	in a dictionary, and then distributes the individual Moments between them 
	while implementing the same public interface 
	as the default MomentCollection implementation. 

	If we assume that Moment IDs are uniformly distributed, 
	a ShardedCollection with 10 inner Collections should be able 
	to store 10x as many Moments (or ~1M).

	When Cadence is updated to allow larger dictionaries, 
	then this contract can be retired.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

access(all)
contract TopShotShardedCollection{ 
	
	// ShardedCollection stores a dictionary of TopShot Collections
	// A Moment is stored in the field that corresponds to its id % numBuckets
	access(all)
	resource ShardedCollection:
		TopShot.MomentCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		// Dictionary of topshot collections
		access(all)
		var collections: @{UInt64: TopShot.Collection}
		
		// The number of buckets to split Moments into
		// This makes storage more efficient and performant
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			
			// Create a new empty collection for each bucket
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! TopShot.createEmptyCollection(nftType: Type<@TopShot.Collection>()) as! @TopShot.Collection
				i = i + UInt64(1)
			}
		}
		
		// withdraw removes a Moment from one of the Collections 
		// and moves it to the caller
		access(NonFungibleToken.Withdraw)
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
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: an array of the IDs to be withdrawn from the Collection
		//
		// Returns: @NonFungibleToken.Collection a Collection containing the moments
		//		  that were withdrawn
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <-
				TopShot.createEmptyCollection(nftType: Type<@TopShot.Collection>())
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes a Moment and adds it to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			
			// Find the bucket this corresponds to
			let bucket = token.id % self.numBuckets
			let collectionRef = (&self.collections[bucket] as &TopShot.Collection?)!
			
			// Deposit the nft into the bucket
			collectionRef.deposit(token: <-token)
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the Collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// getIDs returns an array of the IDs that are in the Collection
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
		
		// Safe way to borrow a reference to an NFT that does not panic
		// Also now part of the NonFungibleToken.CollectionPublic interface
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: An optional reference to the desired NFT, will be nil if the passed ID does not exist
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}?{ 
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			
			// Find NFT in the collections and borrow a reference
			return self.collections[bucket]?.borrowNFTSafe(id: id) ?? nil
		}
		
		// borrowNFT Returns a borrowed reference to a Moment in the Collection
		// so that the caller can read data and call methods from it
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			post{ 
				result.id == id:
					"The ID of the reference is incorrect"
			}
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			
			// Find NFT in the collections and borrow a reference
			return self.collections[bucket]?.borrowNFT(id)!!
		}
		
		// borrowMoment Returns a borrowed reference to a Moment in the Collection
		// so that the caller can read data and call methods from it
		// They can use this to read its setID, playID, serialNumber,
		// or any of the setData or Play Data associated with it by
		// getting the setID or playID and reading those fields from
		// the smart contract
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMoment(id: UInt64): &TopShot.NFT?{ 
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowMoment(id: id) ?? nil
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	
	// If a transaction destroys the Collection object,
	// All the NFTs contained within are also destroyed
	}
	
	// Creates an empty ShardedCollection and returns it to the caller
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(numBuckets: UInt64): @ShardedCollection{ 
		return <-create ShardedCollection(numBuckets: numBuckets)
	}
}
