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

access(TMP_ENTITLEMENT_OWNER)
contract interface IPackNFT{ 
	/// StoragePath for Collection Resource
	///
	access(all)
	let CollectionStoragePath: StoragePath
	
	/// PublicPath expected for deposit
	///
	access(all)
	let CollectionPublicPath: PublicPath
	
	/// PublicPath for receiving PackNFT
	///
	access(all)
	let CollectionIPackNFTPublicPath: PublicPath
	
	/// StoragePath for the PackNFT Operator Resource (issuer owns this)
	///
	access(all)
	let OperatorStoragePath: StoragePath
	
	/// PrivatePath to share IOperator interfaces with Operator (typically with PDS account)
	///
	access(all)
	let OperatorPrivPath: PrivatePath
	
	/// Request for Reveal
	///
	access(all)
	event RevealRequest(id: UInt64, openRequest: Bool)
	
	/// Request for Open
	///
	/// This is emitted when owner of a PackNFT request for the entitled NFT to be
	/// deposited to its account
	access(all)
	event OpenRequest(id: UInt64)
	
	/// Burned
	///
	/// Emitted when a PackNFT has been burned
	access(all)
	event Burned(id: UInt64)
	
	/// Opened
	///
	/// Emitted when a packNFT has been opened
	access(all)
	event Opened(id: UInt64)
	
	access(all)
	enum Status: UInt8{ 
		access(TMP_ENTITLEMENT_OWNER)
		case Sealed
		
		access(TMP_ENTITLEMENT_OWNER)
		case Revealed
		
		access(TMP_ENTITLEMENT_OWNER)
		case Opened
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface Collectible{ 
		access(all)
		let address: Address
		
		access(all)
		let contractName: String
		
		access(all)
		let id: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hashString(): String
		
		init(address: Address, contractName: String, id: UInt64)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IPack{ 
		access(all)
		let issuer: Address
		
		access(all)
		var status: Status
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(nftString: String): Bool
		
		access(contract)
		fun reveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String)
		
		access(contract)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
		
		init(commitHash: String, issuer: Address)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IOperator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(distId: UInt64, commitHash: String, issuer: Address): @{IPackNFT.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reveal(id: UInt64, nfts: [{Collectible}], salt: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface PackNFTOperator: IOperator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(distId: UInt64, commitHash: String, issuer: Address): @{IPackNFT.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reveal(id: UInt64, nfts: [{Collectible}], salt: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(id: UInt64, nfts: [{IPackNFT.Collectible}])
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IPackNFTToken{ 
		access(all)
		let id: UInt64
		
		access(all)
		let issuer: Address
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFT: NonFungibleToken.NFT, IPackNFTToken, IPackNFTOwnerOperator{ 
		access(all)
		let id: UInt64
		
		access(all)
		let issuer: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reveal(openRequest: Bool)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IPackNFTOwnerOperator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun reveal(openRequest: Bool)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IPackNFTCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPackNFT(id: UInt64): &{IPackNFT.NFT}?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || (result!).id == id:
					"Cannot borrow PackNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(contract)
	fun revealRequest(id: UInt64, openRequest: Bool)
	
	access(contract)
	fun openRequest(id: UInt64)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun publicReveal(id: UInt64, nfts: [{IPackNFT.Collectible}], salt: String)
}
