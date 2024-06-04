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

	// BasicNFT.cdc
//
// The NonFungibleToken contract is a sample implementation of a non-fungible token (NFT) on Flow.
//
// This contract defines one of the simplest forms of NFTs using an
// integer ID and metadata field.
// 
// Learn more about non-fungible tokens in this tutorial: https://developers.flow.com/cadence/tutorial/05-non-fungible-tokens-1
access(all)
contract BasicNFT{ 
	// Declare the NFT resource type
	access(all)
	resource NFT{ 
		// The unique ID that differentiates each NFT
		access(all)
		let id: UInt64
		
		// String mapping to hold metadata
		access(all)
		var metadata:{ String: String}
		
		// Initialize both fields in the init function
		init(initID: UInt64){ 
			self.id = initID
			self.metadata ={} 
		}
	}
	
	// Function to create a new NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun createNFT(id: UInt64): @NFT{ 
		return <-create NFT(initID: id)
	}
	
	// Create a single new NFT and save it to account storage
	init(){ 
		self.account.storage.save<@NFT>(<-create NFT(initID: 1), to: /storage/BasicNFTPath)
	}
}
