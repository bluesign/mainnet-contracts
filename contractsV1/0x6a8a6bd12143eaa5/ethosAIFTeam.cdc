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
	Description: Central Smart Contract for AIF Team
	
	This smart contract contains the core functionality for 
	AIF Team, created by Ethos Multiverse Inc.
	
	The contract manages the data associated with each NFT and 
	the distribution of each NFT to recipients.
	
	Admins throught their admin resource object have the power 
	to do all of the important actions in the smart contract such 
	as minting and batch minting.
	
	When NFTs are minted, they are initialized with metadata and stored in the
	admins Collection.
	
	The contract also defines a Collection resource. This is an object that 
	every AIF Team NFT owner will store in their account
	to manage their NFT collection.
	
	The main AIF Team account operated by Ethos Multiverse Inc. 
	will also have its own AIF Team collection it can use to hold its 
	own NFT's that have not yet been sent to a user.
	
	Note: All state changing functions will panic if an invalid argument is
	provided or one of its pre-conditions or post conditions aren't met.
	Functions that don't modify state will simply return 0 or nil 
	and those cases need to be handled by the caller.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ethosAIFTeam: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam contract Events
	// -----------------------------------------------------------------------
	
	// Emited when the ethosAIFTeam contract is created
	access(all)
	event ContractInitialized()
	
	// Emmited when a user transfers a ethosAIFTeam NFT out of their collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Emmited when a user recieves a ethosAIFTeam NFT into their collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Emmited when a ethosAIFTeam NFT is minted
	access(all)
	event Minted(id: UInt64)
	
	// Emmited when a ethosAIFTeam NFT is destroyed
	access(all)
	event NFTDestroyed(id: UInt64)
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	// The total number of ethosAIFTeam NFTs that have been created
	// Because NFTs can be destroyed, it doesn't necessarily mean that this
	// reflects the total number of NFTs in existence, just the number that
	// have been minted to date. Also used as NFT IDs for minting.
	access(all)
	var totalSupply: UInt64
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	// The resource that represents the ethosAIFTeam NFTs
	//
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: self.metadata["description"]!, thumbnail: MetadataViews.HTTPFile(url: self.metadata["external_url"]!))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_metadata:{ String: String}){ 
			self.id = ethosAIFTeam.totalSupply
			self.metadata = _metadata
			ethosAIFTeam.totalSupply = ethosAIFTeam.totalSupply + 1
			emit Minted(id: self.id)
		}
	}
	
	// The interface that users can cast their ethosAIFTeam Collection as
	// to allow others to deposit ethosAIFTeam into thier Collection. It also
	// allows for the reading of the details of ethosAIFTeam
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &ethosAIFTeam.NFT?
	}
	
	// Collection is a resource that every user who owns NFTs
	// will store in theit account to manage their NFTs
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let myToken <- token as! @ethosAIFTeam.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		// getIDs returns an arrat of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT Returns a borrowed reference to a ethosAIFTeam NFT in the Collection
		// so that the caller can read its ID
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowEntireNFT returns a borrowed reference to a ethosAIFTeam 
		// NFT so that the caller can read its data.
		// They can use this to read its id, description, and serial_number.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &ethosAIFTeam.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let reference = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return reference as! &ethosAIFTeam.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform important NFT
	// functions
	access(all)
	resource Admin{ 
		
		// mintethosAIFTeamNFT
		// Mints an new NFT
		// and deposits it in the Admins collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mintethosAIFTeamNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}){ 
			// create a new NFT 
			var newNFT <- create NFT(_metadata: metadata)
			
			// Deposit it in Admins account using their reference
			recipient.deposit(token: <-newNFT)
		}
		
		// batchMintNFT
		// Batch mints ethosAIFTeamNFTs
		// and deposits in the Admins collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintethosAIFTeamNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadataArray: [{String: String}]){ 
			var i: Int = 0
			while i < metadataArray.length{ 
				self.mintethosAIFTeamNFT(recipient: recipient, metadata: metadataArray[i])
				i = i + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam contract-level function definitions
	// -----------------------------------------------------------------------
	// createEmptyCollection
	// public function that anyone can call to create a new empty collection
	//
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// -----------------------------------------------------------------------
	// ethosAIFTeam initialization function
	// -----------------------------------------------------------------------
	//
	// initializer
	//
	init(){ 
		
		// Set named paths
		self.CollectionStoragePath = /storage/ethosAIFTeamCollection
		self.CollectionPublicPath = /public/ethosAIFTeamCollection
		self.AdminStoragePath = /storage/ethosAIFTeamAdmin
		self.AdminPrivatePath = /private/ethosAIFTeamAdminUpgrade
		
		// Initialize total supply count
		self.totalSupply = 1
		
		// Create an Admin resource and save it to storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&ethosAIFTeam.Admin>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath) ?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
