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

	/**

## The Flow Non-Fungible Token standard

Adapted for Capsule needs.

## `NonFungibleToken` contract interface

The interface that all non-fungible token contracts could conform to.
If a user wants to deploy a new nft contract, their contract would need
to implement this NonFungibleToken interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `NFT` resource

The core resource type that represents an NFT in the smart contract.

## `Collection` Resource

The resource that stores a user's NFT collection.
It includes a few functions to allow the owner to easily
move tokens in and out of the collection.

## `Provider` and `Receiver` resource interfaces

These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the tokens.

By using resources and interfaces, users of NFT smart contracts can send
and receive tokens peer-to-peer, without having to interact with a central ledger
smart contract.

To send an NFT to another user, a user would simply withdraw the NFT
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

*/


// The main NFT contract interface. Other NFT contracts will
// import and implement this interface
//
access(TMP_ENTITLEMENT_OWNER)
contract interface CapsuleNFT{ 
	
	// The total number of tokens of this type in existence
	access(all)
	var totalMinted: UInt64
	
	// Event that emitted when the NFT contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	// Event that is emitted when a token is withdrawn,
	// indicating the:
	// - the ID of the NFT being withdrawn
	// - the size (bytes) of the NFT
	// - the owner of the collection that it was withdrawn from
	//
	// If the collection is not in an account's storage, `from` will be `nil`.
	//
	access(all)
	event Withdraw(id: String, size: UInt64, from: Address?)
	
	// Event that emitted when a token is deposited to a collection,
	// indicating the:
	// - the ID of the NFT being withdrawn
	// - the size (bytes) of the NFT
	// - the owner of the collection that it was deposited to
	//
	//
	access(all)
	event Deposit(id: String, size: UInt64, to: Address?)
	
	// Event that emits when a token is minted.
	//
	access(all)
	event Minted(id: String)
	
	// Interface that the NFTs have to conform to
	//
	access(TMP_ENTITLEMENT_OWNER)
	resource interface INFT{ 
		// The Capsule UniqueID given to the NFT
		access(all)
		let id: String
	}
	
	// Requirement that all conforming NFT smart contracts have
	// to define a resource called NFT that conforms to INFT
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFT: INFT{ 
		access(all)
		let id: String
	}
	
	// Interface to mediate withdraws from the Collection
	//
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Provider{ 
		// withdraw removes an NFT from the collection and moves it to the caller
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: String): @{CapsuleNFT.NFT}{ 
			post{ 
				result.id == id:
					"The ID of the withdrawn token must be the same as the requested ID"
			}
		}
	}
	
	// Interface to mediate deposits to the Collection
	//
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Receiver{ 
		// deposit takes an NFT as an argument and adds it to the Collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{CapsuleNFT.NFT})
	}
	
	// Interface that an account would commonly 
	// publish for their collection
	access(TMP_ENTITLEMENT_OWNER)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{CapsuleNFT.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getIDs(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}
	}
	
	// Requirement for the the concrete resource type
	// to be declared in the implementing contract
	//
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Collection: Provider, Receiver, CollectionPublic{ 
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{String:{ CapsuleNFT.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: String): @{CapsuleNFT.NFT}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{CapsuleNFT.NFT})
		
		// getIDs returns an array of the IDs that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		view fun getIDs(): [String]
		
		// Returns a borrowed reference to an NFT in the collection
		// so that the caller can read data and call methods from it
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: String): &{CapsuleNFT.NFT}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
		}
	}
	
	// createEmptyCollection creates an empty Collection
	// and returns it to the caller so that they can own NFTs
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @{CapsuleNFT.Collection}{ 
		post{ 
			result.getIDs().length == 0:
				"The created collection must be empty!"
		}
	}
}
