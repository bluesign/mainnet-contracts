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

	import Crypto

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FantastecNFT from "./FantastecNFT.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface IFantastecPackNFT{ 
	/// StoragePath for Collection Resource
	access(all)
	let CollectionStoragePath: StoragePath
	
	/// PublicPath expected for deposit
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// PublicPath for receiving NFT
	access(all)
	let CollectionIFantastecPackNFTPublicPath: PublicPath
	
	/// StoragePath for the NFT Operator Resource (issuer owns this)
	access(all)
	let OperatorStoragePath: StoragePath
	
	/// PrivatePath to share IOperator interfaces with Operator (typically with PDS account)
	access(all)
	let OperatorPrivPath: PrivatePath
	
	/// Burned
	/// Emitted when a NFT has been burned
	access(all)
	event Burned(id: UInt64)
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IOperator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(packId: UInt64, productId: UInt64): @{IFantastecPackNFT.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(id: UInt64, recipient: Address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface FantastecPackNFTOperator: IOperator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(packId: UInt64, productId: UInt64): @{IFantastecPackNFT.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFantastecNFT(id: UInt64, nft: @FantastecNFT.NFT)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(id: UInt64, recipient: Address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IFantastecPack{ 
		access(all)
		var ownedNFTs: @{UInt64: FantastecNFT.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFantastecNFT(nft: @FantastecNFT.NFT)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(recipient: Address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IFantastecPackNFTCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
	}
}
