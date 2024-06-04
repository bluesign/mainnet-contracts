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

	//  SPDX-License-Identifier: UNLICENSED
//
//  Description: Smart Contract for Anique central.
//  All NFT contracts of Anique will inherit this.
//
//  authors: Atsushi Otani atsushi.ootani@anique.jp
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface Anique{ 
	
	// Event that emitted when the NFT contract is initialized
	//
	access(all)
	event ContractInitialized()
	
	// Interface that Anique NFTs have to conform to
	//
	access(TMP_ENTITLEMENT_OWNER)
	resource interface INFT{} 
	
	// Requirement that all conforming NFT smart contracts have
	// to define a resource called NFT that conforms to INFT
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFT: INFT{ 
		access(all)
		let id: UInt64
	}
	
	// The interface that Anique NFT contract's admin
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Admin{} 
	
	// Requirement for the the concrete resource type
	// to be declared in the implementing Anique contracts
	// mainly used by AniqueMarket.
	// Cooporative with NonFungibleToken.Collection because each
	// Anique NFT contract's Collection should implement both
	// NonFungibleToken.Collection and Anique.Collection
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Collection{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		// getIDs returns an array of the IDs that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		// Returns a borrowed reference to an NFT in the collection
		// so that the caller can read data and call methods from it
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"NFT does not exist in the collection!"
			}
		}
		
		// Returns a borrowed reference to an Anique.NFT in the collection
		// so that the caller can read data and call methods from it
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAniqueNFT(id: UInt64): &{Anique.NFT}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Anique NFT does not exist in the collection!"
			}
		}
	}
}
