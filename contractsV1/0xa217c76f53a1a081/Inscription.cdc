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
*
*  This is an example implementation of a Flow Non-Fungible Token
*  It is not part of the official standard but it assumed to be
*  similar to how many Inscriptions would implement the core functionality.
*
*  This contract does not implement any sophisticated classification
*  system for its Inscriptions. It defines a simple Inscription with minimal metadata.
*
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import InscriptionMetadata from "./InscriptionMetadata.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract Inscription: NonFungibleToken, ViewResolver{ 
	
	/// Total supply of Inscriptions in existence
	access(all)
	var totalSupply: UInt64
	
	/// Total supply of Inscriptions in existence
	access(all)
	var hardCap: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when an Inscription is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an Inscription is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// The core resource that represents a Non Fungible Token.
	/// New instances will be created using the InscriptionMinter resource
	/// and stored in the Collection resource
	///
	access(all)
	resource NFT: NonFungibleToken.NFT, InscriptionMetadata.Resolver{ 
		
		/// The unique ID that each Inscription has
		access(all)
		let id: UInt64
		
		/// Metadata fields
		access(all)
		let inscription: String
		
		init(id: UInt64, inscription: String){ 
			self.id = id
			self.inscription = inscription
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun getViews(): [Type]{ 
			return [Type<InscriptionMetadata.InscriptionView>()]
		}
		
		/// Function that resolves a metadata view for this token.
		///
		/// @param view: The Type of the desired view.
		/// @return A structure representing the requested view.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<InscriptionMetadata.InscriptionView>():
					return InscriptionMetadata.InscriptionView(id: self.id, uuid: self.uuid, inscription: self.inscription)
				default:
					panic("Run-time Type: ".concat(view.identifier).concat(" not supported."))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the methods that are particular to this Inscription contract collection
	///
	access(all)
	resource interface InscriptionCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowInscription(id: UInt64): &Inscription.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Inscription reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the Inscriptions inside any account.
	/// In order to be able to manage Inscriptions any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: InscriptionCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, InscriptionMetadata.ResolverCollection{ 
		// dictionary of Inscription conforming tokens
		// Inscription is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Removes an Inscription from the collection and moves it to the caller
		///
		/// @param withdrawID: The ID of the Inscription that wants to be withdrawn
		/// @return The Inscription resource that has been taken out of the collection
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Inscription")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Adds an Inscription to the collections dictionary and adds the ID to the id array
		///
		/// @param token: The Inscription resource to be included in the collection
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Inscription.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Helper method for getting the collection IDs
		///
		/// @return An array containing the IDs of the Inscriptions in the collection
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Gets a reference to an Inscription in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted Inscription
		/// @return A reference to the wanted Inscription resource
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Gets a reference to an Inscription in the collection so that
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted Inscription
		/// @return A reference to the wanted Inscription resource
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowInscription(id: UInt64): &Inscription.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Inscription.NFT
			}
			return nil
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
	}
	
	/// Allows anyone to create a new empty collection
	///
	/// @return The new Collection resource
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Mints a new Inscription with a new ID and deposit it in the
	/// recipients collection using their collection reference
	///
	/// @param recipient: A capability to the collection where the new Inscription will be deposited
	/// @param amount: The amount in the inscription
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun mintInscription(recipient: &{NonFungibleToken.CollectionPublic}, amount: UInt64){ 
		pre{ 
			amount == UInt64(1000):
				"The amount minted must be equal to 1000"
		}
		post{ 
			Inscription.totalSupply <= Inscription.hardCap:
				"Total supply must less than or equal to hard cap."
		}
		let inscription = "{\"p\":\"frc-20\",\"op\":\"mint\",\"tick\":\"ff\",\"amt\":\"".concat(amount.toString()).concat("\"}")
		
		// create a new Inscription
		var newInscription <- create NFT(id: Inscription.totalSupply, inscription: inscription)
		
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-newInscription)
		Inscription.totalSupply = Inscription.totalSupply + amount
	}
	
	/// Function that resolves a metadata view for this contract.
	///
	/// @param view: The Type of the desired view.
	/// @return A structure representing the requested view.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun resolveView(_ view: Type): AnyStruct?{ 
		return nil
	}
	
	/// Function that returns all the Metadata Views implemented by a Non Fungible Token
	///
	/// @return An array of Types defining the implemented views. This value will be used by
	///		 developers to know which parameter to pass to the resolveView() method.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun getViews(): [Type]{ 
		return []
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.hardCap = 2100000000
		
		// Set the named paths
		self.CollectionStoragePath = /storage/inscriptionCollection
		self.CollectionPublicPath = /public/inscriptionCollection
		self.MinterStoragePath = /storage/inscriptionMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Inscription.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		// let minter <- create InscriptionMinter()
		// self.account.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
