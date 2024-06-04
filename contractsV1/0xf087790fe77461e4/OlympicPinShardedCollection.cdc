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
	Description: Central Collection for a large number of OlympicPin
				 NFTs

	This resource object looks and acts exactly like a OlympicPin PieceCollection
	and (in a sense) shouldn’t have to exist! 

	The problem is that Cadence currently has a limitation where 
	storing more than ~100k objects in a single dictionary or array can fail.

	Most PieceCollections are likely to be much, much smaller than this, 
	and that limitation will be removed in a future iteration of Cadence, 
	so most people will never need to worry about it.

	However! The main OlympicPin administration account DOES need to worry about it
	because it frequently needs to mint >10k Pieces for sale,
	and could easily end up needing to hold more than 100k Piece at one time.
	
	Until Cadence gets an update, that leaves us in a bit of a pickle!

	This contract bundles together a bunch of PieceCollection objects 
	in a dictionary, and then distributes the individual Pieces between them 
	while implementing the same public interface 
	as the default PieceCollection implementation. 

	If we assume that piece IDs are uniformly distributed,
	a ShardedCollection with 10 inner Collections should be able 
	to store 10x as many pieces (or ~1M).

	When Cadence is updated to allow larger dictionaries, 
	then this contract can be retired.

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import OlympicPin from 0x1d007eed492fdbbe

access(all)
contract OlympicPinShardedCollection{ 
	access(all)
	let ShardedPieceCollectionPath: StoragePath
	
	// ShardedCollection stores a dictionary of OlympicPin Collections
	// A Piece is stored in the field that corresponds to its id % numBuckets
	access(all)
	resource ShardedCollection:
		OlympicPin.PieceCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		// Dictionary of OlympicPin collections
		access(all)
		var collections: @{UInt64: OlympicPin.Collection}
		
		// The number of buckets to split pieces into
		// This makes storage more efficient and performant
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			
			// Create a new empty collection for each bucket
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! OlympicPin.createEmptyCollection() as! @OlympicPin.Collection
				i = i + UInt64(1)
			}
		}
		
		// withdraw removes a Piece from one of the Collections 
		// and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			// Find the bucket it should be withdrawn from
			let bucket = withdrawID % self.numBuckets
			
			// Withdraw the piece
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: an array of the IDs to be withdrawn from the Collection
		//
		// Returns: @NonFungibleToken.Collection a Collection containing the pieces
		//		  that were withdrawn
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- OlympicPin.createEmptyCollection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes a piece and adds it to the Collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			// Find the bucket this corresponds to
			let bucket = token.id % self.numBuckets
			let collectionRef = (&self.collections[bucket] as &OlympicPin.Collection?)!
			
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
		
		// borrowNFT Returns a borrowed reference to a Piece in the Collection
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
			return self.collections[bucket]?.borrowNFT(id: id)!
		}
		
		// borrowPiece Returns a borrowed reference to a Piece in the Collection
		// so that the caller can read data and call methods from it
		// They can use this to read its setID, pinID, serialNumber,
		// or any of the setData or Pin Data associated with it by
		// getting the setID or pinID and reading those fields from
		// the smart contract
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPiece(id: UInt64): &OlympicPin.NFT?{ 
			
			// Get the bucket of the nft to be borrowed
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowPiece(id: id) ?? nil
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
	
	init(){ 
		self.ShardedPieceCollectionPath = /storage/ShardedPieceCollection
	}
}
