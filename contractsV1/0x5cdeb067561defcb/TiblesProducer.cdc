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

	// TiblesProducer.cdc
import TiblesNFT from "./TiblesNFT.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface TiblesProducer{ 
	access(all)
	let ProducerStoragePath: StoragePath
	
	access(all)
	let ProducerPath: PrivatePath
	
	access(all)
	let ContentPath: PublicPath
	
	access(all)
	let contentCapability: Capability
	
	access(all)
	event MinterCreated(minterId: String)
	
	access(all)
	event TibleMinted(minterId: String, mintNumber: UInt32, id: UInt64)
	
	// Producers must provide a ContentLocation struct so that NFTs can access metadata.
	access(TMP_ENTITLEMENT_OWNER)
	struct interface ContentLocation{} 
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface IContentLocation{} 
	
	// This is a public resource that lets the individual tibles get their metadata.
	// Adding content is done through the Producer.
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IContent{ 
		// Content is stored in the set/item/variant structures. To retrieve it, we have a contentId that maps to the path.
		access(contract)
		let contentIdsToPaths:{ String:{ TiblesProducer.ContentLocation}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(contentId: String):{ String: AnyStruct}?
	}
	
	// Provides access to producer activities like content creation and NFT minting.
	// The resource is stored in the app account's storage with a link in /private.
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IProducer{ 
		// Minters create and store tibles before they are sold. One minter per set-item-variant combo.
		access(contract)
		let minters: @{String:{ TiblesProducer.Minter}}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Producer: IContent, IProducer{ 
		access(contract)
		let minters: @{String:{ TiblesProducer.Minter}}
	}
	
	// Mints new NFTs for a specific set/item/variant combination.
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IMinter{ 
		access(all)
		let id: String
		
		// Keeps track of the mint number for items.
		access(all)
		var lastMintNumber: UInt32
		
		// Stored with each minted NFT so that it can access metadata.
		access(all)
		let contentCapability: Capability
		
		// Used only on original purchase, when the NFT gets transferred from the producer to the user's collection.
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(mintNumber: UInt32): @{TiblesNFT.INFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNext()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Minter: IMinter{ 
		access(all)
		let id: String
		
		access(all)
		var lastMintNumber: UInt32
		
		access(all)
		let contentCapability: Capability
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(mintNumber: UInt32): @{TiblesNFT.INFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNext()
	}
}
