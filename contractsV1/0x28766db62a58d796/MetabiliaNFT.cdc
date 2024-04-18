// SPDX-License-Identifier: UNLICENSED
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import Crypto

access(all)
contract MetabiliaNFT: NonFungibleToken{ 
	
	// Events
	//
	// This contract is initialized
	access(all)
	event ContractInitialized()
	
	// NFT is minted
	access(all)
	event NFTMinted(nftID: UInt64, setID: UInt64, templateID: UInt64, displayName: String, displayDescription: String, displayURI: String, creator: Address)
	
	// NFT is withdrawn from a collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// NFT is deposited from a collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// NFT is destroyed
	access(all)
	event NFTDestroyed(id: UInt64)
	
	// NFT template metadata is revealed
	access(all)
	event NFTRevealed(nftID: UInt64, setID: UInt64, templateID: UInt64, displayName: String, displayDescription: String, displayURI: String, metadata:{ String: String})
	
	// Set has been created
	access(all)
	event SetCreated(setID: UInt64, metadata: SetMetadata)
	
	// Template has been added
	access(all)
	event TemplateAdded(setID: UInt64, templateID: UInt64, displayName: String, displayDescription: String, displayURI: String)
	
	// Set has been marked Locked
	access(all)
	event SetLocked(setID: UInt64, numTemplates: UInt64)
	
	// Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Total NFT supply
	access(all)
	var totalSupply: UInt64
	
	access(all)
	fun externalURL(): MetadataViews.ExternalURL{ 
		return MetadataViews.ExternalURL("https://metabilia.io/")
	}
	
	access(all)
	fun squareImageCID(): String{ 
		return "QmSDXWBAERtuhb9h9UXE6kYioJgtr8FAwXE3Qdk2yiA32h"
	}
	
	access(all)
	fun bannerImageCID(): String{ 
		return "QmQ9RXqrsAF39bhSkmJsC8eTbXybH6JKJcuGNpxiRDKLse"
	}
	
	// Total number of sets
	access(self)
	var totalSets: UInt64
	
	// Dictionary mapping from set IDs to Set resources
	access(self)
	var sets: @{UInt64: Set}
	
	// Template metadata can have custom definitions but must have the
	// following implemented in order to power all the features of the
	// NFT contract.
	access(all)
	struct interface TemplateMetadata{ 
		
		// Hash representation of implementing structs.
		access(all)
		view fun hash(): [UInt8]
		
		// Representative Display
		access(all)
		fun display(): MetadataViews.Display
		
		// Representative {string: string} serialization
		access(all)
		fun repr():{ String: String}
		
		// MetadataViews compliant
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(all)
	struct DynamicTemplateMetadata: TemplateMetadata{ 
		access(self)
		let _display: MetadataViews.Display
		
		access(self)
		let _metadata:{ String: String}
		
		access(all)
		view fun hash(): [UInt8]{ 
			return []
		}
		
		access(all)
		fun display(): MetadataViews.Display{ 
			return self._display
		}
		
		access(all)
		fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.display()
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetabiliaNFT.externalURL()
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MetabiliaNFT.CollectionStoragePath, publicPath: MetabiliaNFT.CollectionPublicPath, publicCollection: Type<@MetabiliaNFT.Collection>(), publicLinkedType: Type<&MetabiliaNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MetabiliaNFT.createEmptyCollection(nftType: Type<@MetabiliaNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Metabilia", description: "Metabilia NFTs are tied to their specified physical memorabilia item which provides underlying value protection to the digital collectible.", externalURL: MetabiliaNFT.externalURL(), squareImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: MetabiliaNFT.squareImageCID(), path: nil), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.IPFSFile(cid: MetabiliaNFT.bannerImageCID(), path: nil), mediaType: "image/png"), socials:{} )
			}
			return nil
		}
		
		access(all)
		fun repr():{ String: String}{ 
			return self.metadata()
		}
		
		access(all)
		fun metadata():{ String: String}{ 
			return self._metadata
		}
		
		init(display: MetadataViews.Display, metadata:{ String: String}){ 
			self._display = display
			self._metadata = metadata
		}
	}
	
	// NFT
	//
	// "Standard" NFTs that implement MetadataViews and point
	// to a Template struct that give information about the NFTs metadata
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		
		// id is unique among all MetabiliaNFT NFTs on Flow, ordered sequentially from 0
		access(all)
		let id: UInt64
		
		// setID and templateID help us locate the specific template in the
		// specific set which stores this NFTs metadata
		access(all)
		let setID: UInt64
		
		access(all)
		let templateID: UInt64
		
		// The creator of the NFT
		access(all)
		let creator: Address
		
		// Fetch the metadata Template represented by this NFT
		access(all)
		view fun template():{ NFTTemplate}{ 
			return MetabiliaNFT.getTemplate(setID: self.setID, templateID: self.templateID)
		}
		
		// Proxy for MetadataViews.Resolver.getViews implemented by Template
		access(all)
		view fun getViews(): [Type]{ 
			let views = self.template().getViews()
			views.append(Type<MetadataViews.NFTView>())
			return views
		}
		
		// Proxy for MetadataViews.Resolver.resolveView implemented by Template
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			// Templates have no relationship to NFT id so the "NFTView" is only accessible through an NFT reference.
			// It should be noted that the NFTView was developed *after* the conception of this smart contract.
			if view == Type<MetadataViews.NFTView>(){ 
				let viewResolver = &self as &{ViewResolver.Resolver}
				return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
			}
			let template = self.template()
			return template.resolveView(view)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// NFT needs to be told which Template it follows
		init(setID: UInt64, templateID: UInt64, creator: Address){ 
			self.id = MetabiliaNFT.totalSupply
			MetabiliaNFT.totalSupply = MetabiliaNFT.totalSupply + 1
			self.setID = setID
			self.templateID = templateID
			self.creator = creator
			let defaultDisplay = self.template().defaultDisplay
			emit NFTMinted(nftID: self.id, setID: self.setID, templateID: self.templateID, displayName: defaultDisplay.name, displayDescription: defaultDisplay.description, displayURI: defaultDisplay.thumbnail.uri(), creator: self.creator)
		}
	
	// Emit NFTDestroyed when destroyed
	}
	
	// Collection
	//
	// Collections provide a way for collectors to store MetabiliaNFT NFTs in their
	// Flow account.
	// Exposing this interface allows external parties to inspect a Flow
	// account's MetabiliaNFT Collection and deposit NFTs
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMetabiliaNFT(id: UInt64): &NFT
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// NFTs are indexed by its globally assigned id
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Deposit a MetabiliaNFT into the collection. Safe to assume id's are unique.
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			// Required to ensure this is a MetabiliaNFT
			let token <- token as! @MetabiliaNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Withdraw an NFT from the collection.
		// Panics if NFT does not exist in the collection
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.ownedNFTs.containsKey(withdrawID):
					"NFT does not exist in collection."
			}
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Return all the IDs from the collection.
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Borrow a reference to the specified NFT
		// Panics if NFT does not exist in the collection
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"NFT does not exist in collection."
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// Borrow a reference to the specified NFT as a MetabiliaNFT.
		// Panics if NFT does not exist in the collection
		access(all)
		fun borrowMetabiliaNFT(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"NFT does not exist in collection."
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &NFT
		}
		
		// Return the MetadataViews.Resolver of the specified NFT
		// Panics if NFT does not exist in the collection
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"NFT does not exist in collection."
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let typedNFT = nft as! &NFT
			return typedNFT
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// If the collection is destroyed, destroy the NFTs it holds, as well
	// Anyone can make and store collections
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Set{ 
		
		// Globally assigned id based on number of created Sets.
		access(all)
		let id: UInt64
		
		access(all)
		var isLocked: Bool
		
		// Metadata for the Set
		access(all)
		var metadata: SetMetadata
		
		// Templates configured to be minted from this Set
		access(contract)
		var templates: [Template]
		
		// Number of NFTs that have minted from this Set
		access(all)
		var minted: UInt64
		
		// Add a new Template to the Set, only if the Set is Open
		access(all)
		fun addTemplate(template: Template){ 
			pre{ 
				!self.isLocked:
					"Set is locked. It cannot be modified"
			}
			let templateID = self.templates.length
			self.templates.append(template)
			let display = template.defaultDisplay
			emit TemplateAdded(setID: self.id, templateID: UInt64(templateID), displayName: display.name, displayDescription: display.description, displayURI: display.thumbnail.uri())
		}
		
		// Lock the Set if it is Open. This signals that this Set
		// will mint NFTs based only on the Templates configured in this Set.
		access(all)
		fun lock(){ 
			pre{ 
				!self.isLocked:
					"Only an Open set can be locked."
				self.templates.length > 0:
					"Set must be configured with at least one Template."
			}
			self.isLocked = true
			emit SetLocked(setID: self.id, numTemplates: UInt64(self.templates.length))
		}
		
		// Mint numToMint NFTs with the supplied creator attribute. The NFT will
		// be minted into the provided receiver
		access(all)
		fun mint(templateID: UInt64, creator: Address): @NFT{ 
			pre{ 
				templateID < UInt64(self.templates.length):
					"templateID does not exist in Set."
				self.templates[templateID].mintID == nil:
					"Template has already been marked as minted."
			}
			let nft <- create NFT(setID: self.id, templateID: templateID, creator: creator)
			self.templates[templateID].markMinted(nftID: nft.id)
			self.minted = self.minted + 1
			return <-nft
		}
		
		// Reveal a specified Template in a Set.
		access(all)
		fun revealTemplate(templateID: UInt64, metadata:{ TemplateMetadata}, salt: [UInt8]){ 
			pre{ 
				templateID < UInt64(self.templates.length):
					"templateId does not exist in Set."
				self.templates[templateID].mintID != nil:
					"Template has not been marked as minted."
			}
			let template = &self.templates[templateID] as &Template
			template.reveal(metadata: metadata, salt: salt)
			let display = metadata.display()
			emit NFTRevealed(nftID: template.mintID!, setID: self.id, templateID: templateID, displayName: display.name, displayDescription: display.description, displayURI: display.thumbnail.uri(), metadata: metadata.repr())
		}
		
		init(id: UInt64, metadata: SetMetadata){ 
			self.id = id
			self.metadata = metadata
			self.isLocked = false
			self.templates = []
			self.minted = 0
			emit SetCreated(setID: id, metadata: metadata)
		}
	}
	
	// Create and store a new Set. Return the id of the new Set.
	access(contract)
	fun createSet(metadata: SetMetadata): UInt64{ 
		let setID = MetabiliaNFT.totalSets
		let newSet <- create Set(id: setID, metadata: metadata)
		MetabiliaNFT.sets[setID] <-! newSet
		MetabiliaNFT.totalSets = MetabiliaNFT.totalSets + 1
		return setID
	}
	
	// Number of sets created by contract
	access(all)
	fun setsCount(): UInt64{ 
		return MetabiliaNFT.totalSets
	}
	
	// Metadata for the Set
	access(all)
	struct SetMetadata{ 
		access(all)
		var name: String
		
		access(all)
		var description: String
		
		access(all)
		var externalID: String
		
		init(name: String, description: String, externalID: String){ 
			self.name = name
			self.description = description
			self.externalID = externalID
		}
	}
	
	// A summary report of a Set
	access(all)
	struct SetReport{ 
		access(all)
		let id: UInt64
		
		access(all)
		let isLocked: Bool
		
		access(all)
		let metadata: SetMetadata
		
		access(all)
		let numTemplates: Int
		
		access(all)
		let numMinted: UInt64
		
		init(id: UInt64, isLocked: Bool, metadata: SetMetadata, numTemplates: Int, numMinted: UInt64){ 
			self.id = id
			self.isLocked = isLocked
			self.metadata = metadata
			self.numTemplates = numTemplates
			self.numMinted = numMinted
		}
	}
	
	// Generate a SetReport for informational purposes (to be used with scripts)
	access(all)
	fun generateSetReport(setID: UInt64): SetReport{ 
		let setRef = (&self.sets[setID] as &Set?)!
		return SetReport(id: setID, isLocked: setRef.isLocked, metadata: *setRef.metadata, numTemplates: setRef.templates.length, numMinted: setRef.minted)
	}
	
	// Template
	//
	// Templates are mechanisms for handling NFT metadata. These should ideally
	// have a one to one mapping with NFTs, with the assumption that NFTs are
	// designed to be unique. Template allows the creator to commit to an NFTs
	// metadata without having to reveal the metadata itself. The constructor
	// accepts a byte array checksum. After construction, anyone with access
	// to this struct will be able to reveal the metadata, which must be any
	// struct which implements TemplateMetadata and MetadataViews.Resolver such that
	// SHA3_256(salt || metadata.hash()) == checksum.
	//
	// Templates can be seen as metadata managers for NFTs. As such, Templates
	// also implement the MetadataResolver interface to conform with standards.
	// Safe Template interface for anyone inspecting NFTs
	access(all)
	struct interface NFTTemplate{ 
		access(all)
		let defaultDisplay: MetadataViews.Display
		
		access(all)
		var metadata:{ TemplateMetadata}?
		
		access(all)
		var mintID: UInt64?
		
		access(all)
		view fun checksum(): [UInt8]
		
		access(all)
		fun salt(): [UInt8]?
		
		access(all)
		view fun revealed(): Bool
		
		access(all)
		fun getViews(): [Type]
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(all)
	struct Template: NFTTemplate{ 
		
		// checksum as described above
		access(self)
		let _checksum: [UInt8]
		
		// Default Display in case the Template has not yet been revealed
		access(all)
		let defaultDisplay: MetadataViews.Display
		
		// salt and metadata are optional so they can be revealed later, such that
		// SHA3_256(salt || metadata.hash()) == checksum
		access(self)
		var _salt: [UInt8]?
		
		access(all)
		var metadata:{ TemplateMetadata}?
		
		// Convenience attribute to mark whether or not Template has minted NFT
		access(all)
		var mintID: UInt64?
		
		// Helper function to check if a proposed metadata and salt reveal would
		// produce the configured checksum in a Template
		access(all)
		view fun validate(metadata:{ TemplateMetadata}, salt: [UInt8]): Bool{ 
			let hash = String.encodeHex(HashAlgorithm.SHA3_256.hash(salt.concat(metadata.hash())))
			let checksum = String.encodeHex(self.checksum())
			return hash == checksum
		}
		
		// Reveal template metadata and salt. validate() is called as a precondition
		// so collector can be assured metadata was not changed
		access(all)
		fun reveal(metadata:{ TemplateMetadata}, salt: [UInt8]){ 
			pre{ 
				self.mintID != nil:
					"Template has not yet been minted."
				!self.revealed():
					"NFT Template has already been revealed"
				self.validate(metadata: metadata, salt: salt):
					"salt || metadata.hash() does not hash to checksum"
			}
			self.metadata = metadata
			self._salt = salt
		}
		
		access(all)
		view fun checksum(): [UInt8]{ 
			return self._checksum
		}
		
		access(all)
		fun salt(): [UInt8]?{ 
			return self._salt
		}
		
		// Check to see if metadata has been revealed
		access(all)
		view fun revealed(): Bool{ 
			return self.metadata != nil
		}
		
		// Mark the NFT as minted
		access(all)
		fun markMinted(nftID: UInt64){ 
			self.mintID = nftID
		}
		
		// Implements MetadataResolver.getViews
		access(all)
		fun getViews(): [Type]{ 
			if !self.revealed(){ 
				return [Type<MetadataViews.Display>()]
			}
			return (self.metadata!).getViews()
		}
		
		// Implements MetadataResolver.resolveView
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			if !self.revealed(){ 
				if view != Type<MetadataViews.Display>(){ 
					return nil
				}
				return self.defaultDisplay
			}
			return (self.metadata!).resolveView(view)
		}
		
		init(checksum: [UInt8], defaultDisplay: MetadataViews.Display){ 
			self._checksum = checksum
			self.defaultDisplay = defaultDisplay
			self._salt = nil
			self.metadata = nil
			self.mintID = nil
		}
	}
	
	// Public helper function to be able to inspect any Template
	access(all)
	view fun getTemplate(setID: UInt64, templateID: UInt64):{ NFTTemplate}{ 
		let setRef = (&self.sets[setID] as &Set?)!
		return setRef.templates[templateID]
	}
	
	access(all)
	resource SetMinter{ 
		access(all)
		let setID: UInt64
		
		init(setID: UInt64){ 
			self.setID = setID
		}
		
		access(all)
		fun mint(templateID: UInt64, creator: Address): @NFT{ 
			let set = (&MetabiliaNFT.sets[self.setID] as &Set?)!
			return <-set.mint(templateID: templateID, creator: creator)
		}
	}
	
	// Admin
	//
	// The Admin is meant to be a singleton superuser of the contract. The Admin
	// is responsible for creating Sets and SetManagers for managing the sets.
	access(all)
	resource Admin{ 
		
		// Create a set with the provided SetMetadata.
		access(all)
		fun createSet(metadata: SetMetadata): UInt64{ 
			return MetabiliaNFT.createSet(metadata: metadata)
		}
		
		access(all)
		fun borrowSet(setID: UInt64): &Set{ 
			return (&MetabiliaNFT.sets[setID] as &Set?)!
		}
		
		access(all)
		fun createSetMinter(setID: UInt64): @SetMinter{ 
			return <-create SetMinter(setID: setID)
		}
	}
	
	// Contract constructor
	init(){ 
		
		// Collection Paths
		self.CollectionStoragePath = /storage/MetabiliaNFTCollection
		self.CollectionPublicPath = /public/MetabiliaNFTCollection
		self.CollectionPrivatePath = /private/MetabiliaNFTCollection
		
		// Admin Storage Path. Save the singleton Admin resource to contract
		// storage.
		self.AdminStoragePath = /storage/MetabiliaNFTAdmin
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
		
		// Initializations
		self.totalSupply = 0
		self.totalSets = 0
		self.sets <-{} 
		emit ContractInitialized()
	}
}
