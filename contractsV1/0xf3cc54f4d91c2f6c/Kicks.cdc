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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NFTLX from "./NFTLX.cdc"

/**
	# Index of Contents
	NOTE: All index items below appear in the file, verbatim, once.
		  You can copy the name and search the file to find corresponding implementations.

	- Contract Events
	- Named Paths
	- Contract Fields
	- Core Composite Type Definitions
		- SneakerSet Resource
		- Blueprint Resource
		- NFT Resource
		- NFT Collection Resource
	- Priveleged Type Definitions
		- Minter Resource
		- Minting Functions
	- Universal Getters
	- Initializers and Setup Functions

	## Prioritization Structure
	Throughout the code's comments, there's deliberate formatting patterns to convey
	importance of items, to categorize the nature of a comment, and generally to 
	structure the contents in an interpretable and queryable fashion.

	1. High Importance items, typically types and functions of great importance, 
	are marked as:
	// ───────────────────────────────────────────────────────────────────────
	// {{ Name }}
	// ───────────────────────────────────────────────────────────────────────

	2. Medium Importance items, typically sections which implement a set of functionalities, 
	are marked as:
	// ───────────────  {{ Name + Purpose}}  ─────────────── \\
	A couple Purposes used in the project are:
	- Getters
	- Initializers and Destructor
	- Modifiers
	- {{ Interface }} Conformance
	- Transfering Functions
	NOTE: Always structure with 15 dashes (-), followed by 2 space, then name, 2 spaces, and 15 dashes
	EXAMPLE: // ───────────────  NFT Initializers and Destructor  ─────────────── \\

	3. Lesser importance items are marked as:
	// ─────  {{ Name }}  ─────

	## Other Tags Used
	All documentation for types and functions use:
	*/

/** {{ Declaration }}

		{{ Documentation }}
	*/

/*
	
	Additionally, we use the following tags throughout the file
	- QUESTION:
	- TODO:
	- NOTE:
	- LINK: 
	- EXAMPLE:

*/

/** Kicks

	The Kicks smart contract allows sneakerheads to buy limited edition custom sneakers
	as NFTs redeemable for the physical shoe. 
	Kicks is a collaboration between Want'd and Nifty Luxe 
*/

access(all)
contract Kicks: NonFungibleToken{ 
	
	// ───────────────────────────────────────────────────────────────────────
	// Contract Event
	// ───────────────────────────────────────────────────────────────────────
	access(all)
	event ContractInitialized()
	
	access(all)
	event SetCreated(id: UInt32)
	
	access(all)
	event BlueprintCreated(id: UInt32)
	
	access(all)
	event SneakerCreated(id: UInt64, setID: UInt32, blueprintID: UInt32, instanceID: UInt32)
	
	access(all)
	event SneakerBurned(id: UInt64, setID: UInt32, blueprintID: UInt32, instanceID: UInt32)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// ───────────────────────────────────────────────────────────────────────
	// Named Paths
	// ───────────────────────────────────────────────────────────────────────
	access(all)
	let SneakerSetsPrivatePath: PrivatePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// ───────────────────────────────────────────────────────────────────────
	// Contract Fields
	// ───────────────────────────────────────────────────────────────────────
	// ─────  Supply Fields  ─────
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var currentBlueprint: UInt32
	
	// ─────  Resource Collection Fields  ─────
	access(account)
	var setsCapability: Capability<&{UInt32:{ NFTLX.ISet}}>
	
	access(account)
	var setIDs: [UInt32]
	
	access(account)
	var blueprints: @{UInt32: Blueprint}
	
	// ───────────────────────────────────────────────────────────────────────
	// Core Composite Type Definitions
	// ───────────────────────────────────────────────────────────────────────
	// ───────────────  SneakerSet Resource  ─────────────── \\
	/** SneakerSet
	
			A SneakerSet is a curation of blueprints with a similar theme.
			A SneakerSet conforms to the NFTLX Set Interface (ISet) and is stored
			in the admin's storage area, which the central NFTLX set registry
			can reference via a shared capability.
			SneakerSets contain a unique ID in the NFTLX ecosystem, a display name,
			and a set of Blueprints within the Set.
		*/
	
	access(all)
	resource SneakerSet: NFTLX.ISet{ 
		
		// ─────  ISet Conformance  ─────
		access(all)
		let id: UInt32
		
		access(all)
		var name: String
		
		access(all)
		var URI: String // NOTE: URI are IPFS CID to a directory which will have a metadata.json, headerImage.jpg, 
		
		
		// Array of sneaker blueprint indexes in the Kicks project 
		access(account)
		var blueprintIDs: [UInt32]
		
		// ───────────────  SneakerSet Getters  ─────────────── \\
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt32]{ 
			return self.blueprintIDs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClasses(): [&Kicks.Blueprint]{ 
			var blueprints: [&Kicks.Blueprint] = []
			for id in self.blueprintIDs{ 
				if let blueprint = Kicks.blueprints[id]?.borrow(){ 
					blueprints.append(blueprint)
				}
			}
			return blueprints
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClass(atIndex index: Int): &Kicks.Blueprint?{ 
			pre{ 
				self.blueprintIDs.length > index:
					"Blueprint is not member of Sneaker Set."
			}
			return &Kicks.blueprints[self.blueprintIDs[index]] as &Kicks.Blueprint?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTotalSupply(): UInt32{ 
			var sum: UInt32 = 0
			for blueprint in self.getClasses(){ 
				sum = sum + blueprint.numberMinted
			}
			return sum
		}
		
		// ───────────────  SneakerSet Content Modifiers  ─────────────── \\
		access(contract)
		fun addBlueprint(blueprintID id: UInt32){ 
			pre{ 
				Kicks.blueprints.containsKey(id):
					"Blueprint does not exist"
				!self.blueprintIDs.contains(id):
					"Blueprint is already in set"
			}
			self.blueprintIDs.append(id)
		}
		
		access(contract)
		fun removeBlueprint(blueprintID id: UInt32){ 
			pre{ 
				self.blueprintIDs.contains(id):
					"Blueprint is not member of Sneaker Set."
			}
			var index: Int = 0
			for includedID in self.blueprintIDs{ 
				if id == includedID{ 
					self.blueprintIDs.remove(at: index)
					break
				}
				index = index + 1
			}
			self.blueprintIDs.remove(at: index)
		}
		
		access(contract)
		fun updateURI(_ newURI: String){ 
			self.URI = newURI
		}
		
		access(contract)
		fun updateName(_ newName: String){ 
			self.name = newName
		}
		
		// ─────  SneakerSet Initializers and Destructor  ─────
		init(id: UInt32, name: String, URI: String){ 
			self.id = id
			self.name = name
			self.URI = URI
			self.blueprintIDs = []
			emit SetCreated(id: id)
		}
	}
	
	// ───────────────  Blueprint Resource  ─────────────── \\
	/** Blueprint
		
			Represents the general characterstics for a class of shoe from which individual
			Sneaker NFTs are minted. This includes the name of a shoe, an IPFS URI where
			the shoe's media can be obtained, and supply information such as current number
			of copies minted, and a maximum supply where applicable.
		*/
	
	access(all)
	resource Blueprint: NFTLX.IClass{ 
		access(all)
		let id: UInt32
		
		access(all)
		var name: String
		
		access(all)
		var URI: String
		
		access(all)
		var numberMinted: UInt32
		
		access(all)
		let maxSupply: UInt32?
		
		access(contract)
		var metadata:{ String: AnyStruct}
		
		access(contract)
		var nftIDs: [UInt32]
		
		// ─────  Blueprint Getters  ─────
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt32]{ 
			return self.nftIDs
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(): &Blueprint{ 
			return &self as &Blueprint
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		// ─────  Blueprint Modifiers  ─────
		access(contract)
		fun nftAdded(nftID: UInt32){ 
			self.nftIDs.append(nftID)
			self.numberMinted = self.numberMinted + 1
		}
		
		/**  nftDestroyed
		
					Used internally to remove an NFT from a blueprint's record of nftIDs.
					NOTE: number minted does not decrement on an NFT's deletion. We deliberately
						  allow burned NFTs to increase scarcity of a blueprint.
				*/
		
		access(contract)
		fun nftDestroyed(nftID: UInt32){ 
			pre{ 
				self.nftIDs.contains(nftID):
					"NFT is not instance of this blueprint."
			}
			var index: Int = 0
			for id in self.nftIDs{ 
				if id == nftID{ 
					self.nftIDs.remove(at: index)
					break
				}
				index = index + 1
			}
		}
		
		access(contract)
		fun updateURI(_ newURI: String, media:{ String: AnyStruct}){ 
			self.URI = newURI
		}
		
		access(contract)
		fun updateName(_ newName: String){ 
			self.name = newName
		}
		
		// ─────  Blueprint Initializers and Destructor  ─────
		init(id: UInt32, name: String, URI: String, metadata:{ String: AnyStruct}, maxSupply: UInt32?){ 
			self.id = id
			self.URI = URI
			self.name = name
			self.numberMinted = 0
			self.maxSupply = maxSupply
			self.metadata = metadata
			self.nftIDs = []
			emit BlueprintCreated(id: id)
		}
	}
	
	// ───────────────  NFT Resource  ─────────────── \\
	/** SneakerAttributeKeys 
		
			The SneakerAttributeKeys struct statically stores the keys used by the NFT's metadata field.
			Its fields represent the individual attributes of a Sneaker.
			The purpose is to minimize typos and have a bridge from statically typed fields to the
			dynamically stored strings in the metadata so typos can be caught at build time not run time.
			SneakerAttributeKeys is instantiated once as SneakerAttribute and used throughout the file. 
			TODO: Once enumerations support functions, convert to enum with a .toString function, or
				  Once static fields are implemented, use a struct with static fields for attributes
		*/
	
	access(all)
	struct SneakerAttributeKeys{ 
		access(all)
		let redeemed: String
		
		access(all)
		let size: String
		
		access(all)
		let taggedTopShot: String
		
		init(){ 
			self.redeemed = "redeemed"
			self.size = "size"
			self.taggedTopShot = "taggedTopShot"
		}
	}
	
	access(all)
	let SneakerAttribute: SneakerAttributeKeys
	
	/** NFT
		
			To conform with the NFT interface, we have an NFT type which represents an individual and ownable
			Sneaker. Additionally, our Kick's NFT conforms to the NFTLX NFT Interface (ILXNFT) which requires
			a set, class and instance identifier, and the unique metadata of the NFT. The metadata included
			in an NFT is defined above in the SneakerAttributes enumeration; namely, whether it has been
			redeemed, and the size of the Sneaker
		*/
	
	access(all)
	resource NFT: NonFungibleToken.NFT, NFTLX.ILXNFT, ViewResolver.Resolver{ 
		// ─────  INFT Conformance  ─────
		access(all)
		let id: UInt64
		
		// ─────  ILXNFT Conformance  ─────
		access(all)
		let setID: UInt32
		
		access(all)
		let classID: UInt32 // aka, blueprintID
		
		
		access(all)
		let instanceID: UInt32
		
		access(all)
		let taggedNFT: @{NonFungibleToken.NFT}?
		
		access(contract)
		var metadata:{ String: AnyStruct}
		
		// ───────────────  NFT Modifiers  ─────────────── \\
		/** setSize
		
					Used to irriversibly set the size of the sneaker. Callable within the owner's NFT Collection and only
					accessible by the account - so references to the NFT may be freely passed around without fear of tampering.
					Once set, size is permanently stored as a String in the metadata under the "size" key.
		
					size: UFix64 -- Size of physical accompanying sneaker in US sizing and must be divisible by 0.5.
		
					Preconditions: Size must not be set already. Requested size must be between 3.5 - 15 and in half size increments.
					Postconditions: Size must be set afterwards.
				*/
		
		access(account)
		fun setSize(_ size: UFix64){ 
			pre{ 
				self.metadata[Kicks.SneakerAttribute.size] == nil:
					"Size has already been set"
				size % 0.5 == 0.0:
					"Size must be in half increments to be valid"
				size >= 3.5:
					"Size must be greater than 3.5"
				size <= 15.0:
					"Size cannot be greater than 15. If you do have size feet over size 15, well..."
			}
			post{ 
				self.metadata[Kicks.SneakerAttribute.size] as! String? != nil:
					"Sneaker's metadata did not update correctly"
			}
			let isHalfSize = size % 1.0 == 0.5
			var sizeString = UInt8(size).toString()
			if isHalfSize{ 
				sizeString = sizeString.concat(".5")
			}
			self.metadata.insert(key: Kicks.SneakerAttribute.size, sizeString)
		}
		
		/** redeemSneaker
		
					Used to irriversibly request the sneaker be delivered to the token holder. Callable within the owner's NFT
					Collection and only accessible by the account - so references to the NFT may be freely passed around
					without fear of tampering. Once set, redeemed status is permanently stored as a Boolean in the metadata 
					under the "redeemed" key.
		
					Preconditions: Metadata's value for "redeemed" key must be false.
					Postconditions: Metadata's value for "redeemed" key must be true.
				*/
		
		access(account)
		fun redeemSneaker(){ 
			pre{ 
				self.metadata[Kicks.SneakerAttribute.redeemed] as! Bool? != true:
					"Sneaker has already been redeemed"
			}
			post{ 
				self.metadata[Kicks.SneakerAttribute.redeemed] as! Bool? == true:
					"Sneaker's metadata did not update correctly"
			}
			self.metadata.insert(key: Kicks.SneakerAttribute.redeemed, true)
		}
		
		// ─────  NFT Getters  ─────
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			let blueprintMetadata = self.getBlueprint().getMetadata()
			var aggregateMetadata:{ String: AnyStruct} = self.metadata
			for key in blueprintMetadata.keys{ 
				if let value = blueprintMetadata[key]{ 
					aggregateMetadata.insert(key: key, value)
				}
			}
			return aggregateMetadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun getBlueprint(): &Blueprint{ 
			return Kicks.getBlueprint(withID: self.classID) ?? panic("Could not return parent blueprint")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(): &NFT{ 
			return &self as &NFT
		}
		
		// ─────  NFT Metadata Views  ─────
		access(TMP_ENTITLEMENT_OWNER)
		fun name(): String{ 
			let name = self.getBlueprint().name
			return name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String{ 
			let metadata = self.getBlueprint().getMetadata()
			var description: String = ""
			if metadata.containsKey("description"){ 
				if let classDescription = metadata["description"]! as? String{ 
					description = classDescription.concat(" #").concat(self.instanceID.toString())
				}
			} else{ 
				description = self.getBlueprint().name.concat(" #").concat(self.instanceID.toString()).concat(" (of ").concat(self.getBlueprint().numberMinted.toString()).concat(")")
				if let set = Kicks.getSneakerSet(withID: self.setID){ 
					description = description.concat(" in the ").concat(set.name).concat(" collection")
				}
			}
			return description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun defaultImage(): String?{ 
			let metadata = self.getMetadata()
			if let image = metadata["image"]{ 
				return image as? String
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<{String:{ MetadataViews.File}}>(), Type<String>(), Type<[String; 2]>(), Type<[UInt32; 3]>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					if !self.getMetadata().containsKey("image"){ 
						return nil
					}
					if let imageURL = self.getMetadata()["image"]! as? String{ 
						return MetadataViews.Display(name: self.name(), description: self.description(), thumbnail: MetadataViews.HTTPFile(url: imageURL))
					}
				case Type<String>():
					return self.name()
				case Type<[String; 2]>():
					let nameAndDescription: [String; 2] = [self.name(), self.description()]
					return nameAndDescription
				case Type<[UInt32; 3]>():
					let nftLocation: [UInt32; 3] = [self.setID, self.classID, self.instanceID]
					return nftLocation
				case Type<{String:{ MetadataViews.File}}>():
					let metadata = self.getMetadata()
					if !metadata.containsKey("mediaTypes"){ 
						return nil
					}
					if let supportedMedia = metadata["mediaTypes"]! as? [String]{ 
						var media:{ String:{ MetadataViews.File}} ={} 
						for mediaType in supportedMedia{ 
							if !metadata.containsKey(mediaType){ 
								return nil
							}
							if let mediaURI = metadata[mediaType]! as? String{ 
								media.insert(key: mediaType, MetadataViews.HTTPFile(url: mediaURI))
							}
						}
						return media
					}
			}
			return nil
		}
		
		// ─────  NFT Initializers and Destructor  ─────
		init(instanceID: UInt32, classID: UInt32, setID: UInt32, taggedNFT: @{NonFungibleToken.NFT}?){ 
			pre{ 
				Kicks.blueprints.containsKey(classID) == false:
					"Blueprint does not exist"
			}
			// Assign path id fields
			self.instanceID = instanceID
			self.classID = classID
			self.setID = setID
			
			// Assign unique id
			self.id = Kicks.totalSupply
			
			// Set the tagged NFT and create metadata. All fields set from hereon
			self.taggedNFT <- taggedNFT
			self.metadata ={ Kicks.SneakerAttribute.redeemed: false, Kicks.SneakerAttribute.size: nil}
			
			// Lastly, increase total supply and notify the flowverse of the freshest sneaker out there
			Kicks.totalSupply = Kicks.totalSupply + 1
			emit SneakerCreated(id: self.id, setID: setID, blueprintID: classID, instanceID: instanceID)
		}
		
		/** setMetadata
		
					Used solely by admin to set any metadata fields on an NFT. With great power, comes great responsibility.
				*/
		
		access(account)
		fun setMetadata(key: String, value: AnyStruct){ 
			self.metadata.insert(key: key, value)
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// ───────────────  NFT Collection Resource  ─────────────── \\
	/** KicksCollectionPublic
	
			A public interface extending the standard NFT Collection with type information specific
			to Kicks NFTs.
		*/
	
	access(all)
	resource interface KicksCollectionPublic{ 
		// ─────  NonFungibleToken CollectionPublic Conformance  ─────
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		// ─────  MetadataViews ResolverCollection Conformance  ─────
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		// ─────  KicksCollectionPublic  ─────
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetIDs(): [UInt32]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClassIDs(): [[UInt32; 2]]
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun borrowSneaker(id: UInt64): &Kicks.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Returned Sneaker's ID does not match expected ID"
			}
		}
	}
	
	/** Collection
	
			A collection is a user facing resource responsible for storing, sending, receiving, and interacting
			with NFTs a user owns. The name is required to be Collection as per the NFT standard interface, though
			NFT Collection is how we refer to it to be more specific.
		*/
	
	access(all)
	resource Collection: KicksCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// ───────────────  NFT Collection Transfering Functions  ─────────────── \\
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// batchWithdraw removes multiple Sneaker NFTs as a collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Kicks.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes another NFT Collection of Kicks and deposits
		// each item into current collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			for key in tokens.getIDs(){ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// ───────────────  NFT Collection Getters  ─────────────── \\
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// getSetIDs returns all unique NFTLX set IDs the collection holds
		access(TMP_ENTITLEMENT_OWNER)
		fun getSetIDs(): [UInt32]{ 
			var setIDs: [UInt32] = []
			for id in self.ownedNFTs.keys{ 
				if let sneaker = self.borrowSneaker(id: id){ 
					if !setIDs.contains(sneaker.setID){ 
						setIDs.append(sneaker.setID)
					}
				}
			}
			return setIDs
		}
		
		// getClassIDs returns all NFTLX set and class IDs the collection holds.
		access(TMP_ENTITLEMENT_OWNER)
		fun getClassIDs(): [[UInt32; 2]]{ 
			var classIDs: [[UInt32; 2]] = []
			for id in self.ownedNFTs.keys{ 
				if let sneaker = self.borrowSneaker(id: id){ 
					classIDs.append([sneaker.setID, sneaker.classID])
				}
			}
			return classIDs
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(TMP_ENTITLEMENT_OWNER)
		view fun borrowSneaker(id: UInt64): &Kicks.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as? &Kicks.NFT
		}
		
		// ─────  MetadataViews ResolverCollection Conformance  ─────
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			return self.borrowSneaker(id: id) ?? panic("Could not borrow sneaker")
		}
		
		// ───────────────  NFT Modifiers  ─────────────── \\
		access(TMP_ENTITLEMENT_OWNER)
		fun redeemSneaker(id: UInt64){ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"No sneaker with ID in collection"
			}
			let sneaker = self.borrowSneaker(id: id) ?? panic("Unable to get sneaker")
			sneaker.redeemSneaker()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSize(id: UInt64, size: UFix64){ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"No sneaker with ID in collection"
			}
			let sneaker = self.borrowSneaker(id: id) ?? panic("Unable to get sneaker")
			sneaker.setSize(size)
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
		
		// ─────  NFT Collection Initializers and Destructor  ─────
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// ───────────────────────────────────────────────────────────────────────
	// Priveleged Type Definitions
	// ───────────────────────────────────────────────────────────────────────
	// ───────────────  Minter Resource  ─────────────── \\
	/** Minter
	
			The minter is the most priveleged authority in the Kicks project. They can create
			and destroy new sets, blueprints, and NFTs.
		*/
	
	access(all)
	resource Minter{ 
		
		// ───────────────  Minting Functions  ─────────────── \\
		/** mintSneakerSet
		
					Creates a new NFTLX set for sneakers then save it into the central
					NFTLX sets storage and records the new ID in Kicks' setIDs.
		
					name: String -- Display name of the set. Will be displayed on website as
						 entered. Can be modified later via Minter's updateSetName function.
		
					URI: String -- IPFS Content ID to the media folder of the new set. It is 
						 expected that the set's content is already uploaded to IPFS before 
						 being minted on chain. Can be modified later via Minter's 
						 updateSetURI function.
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSneakerSet(name: String, URI: String){ 
			// 1. Create new set
			let newSetID = NFTLX.nextSetID
			let sneakerSet <- create SneakerSet(id: newSetID, name: name, URI: URI)
			
			// 2. Load NFTLX admin resource, add new set to universal registry
			let adminCap <- Kicks.account.storage.load<@NFTLX.Admin>(from: NFTLX.AdminStoragePath)!
			adminCap.addNewSet(set: <-sneakerSet)
			Kicks.account.storage.save(<-adminCap, to: NFTLX.AdminStoragePath)
			
			// 3. Add set id to list
			Kicks.setIDs.append(newSetID)
		}
		
		/** mintBlueprint
		
					Creates a new Kicks sneaker blueprint from which sneakers can be made.
		
					name: String -- Display name of the blueprint. Will be displayed on website
						 as entered. Can be modified later via Minter's updateBlueprintName function.
		
					URI: String -- IPFS Content ID to the media folder of the new blueprint, 
						 typically containing images, 3D rendering, and metadata.json. It is 
						 expected that the blueprint's content is already uploaded to IPFS before 
						 being minted on chain. Can be modified later via Minter's 
						 updateBlueprintURI function.
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintBlueprint(name: String, URI: String, metadata:{ String: AnyStruct}, maxSupply: UInt32?){ 
			let newBlueprint <- create Blueprint(id: Kicks.currentBlueprint, name: name, URI: URI, metadata: metadata, maxSupply: maxSupply)
			let old <- Kicks.blueprints.insert(key: Kicks.currentBlueprint, <-newBlueprint)
			assert(old == nil, message: "Unexpectedly found existing blueprint at newly minted ID. Forcibly assigning currentBlueprint may be required to resolve.")
			destroy old
			Kicks.currentBlueprint = UInt32(Kicks.blueprints.length)
		}
		
		/** mintNFT
		
					Creates a new Kicks sneaker from a blueprint. Has ability to deposit a tagged 
					NFT - typically, a TopShot moment - which the NFT will inseperably own.
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, blueprintID: UInt32, setID: UInt32, taggedNFT: @{NonFungibleToken.NFT}?){ 
			pre{ 
				Kicks.blueprints.containsKey(blueprintID):
					"Blueprint does not exist"
				(Kicks.getBlueprint(withID: blueprintID)!).numberMinted < (Kicks.getBlueprint(withID: blueprintID)!).maxSupply ?? UInt32.max:
					"Blueprint has reached max supply. Cannot mint further instances."
			}
			
			// Retrieve blueprint resource to modify its fields
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve parent blueprint")
			let newID = blueprint.numberMinted
			
			// create a new NFT
			var newNFT <- create NFT(instanceID: newID, classID: blueprintID, setID: setID, taggedNFT: <-taggedNFT)
			
			// Update blueprint's information
			blueprint.nftAdded(nftID: newID)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			
			// Place blueprint back into set
			let old <- Kicks.blueprints.insert(key: blueprintID, <-blueprint)
			assert(old == nil, message: "Unexpectedly found existing blueprint at newly minted ID. Forcibly assigning currentBlueprint may be required to resolve.")
			destroy old
		}
		
		/** mintBatchNFT
		
					Creates a new collection of Kicks sneaker from a blueprint and deposits to recipient.
		
					NOTE: Does not support taggedNFTs in minting.
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintBatchNFT(recipient: &{Kicks.KicksCollectionPublic}, blueprintID: UInt32, setID: UInt32, quantity: Int){ 
			pre{ 
				Kicks.blueprints.containsKey(blueprintID):
					"Blueprint does not exist"
				(Kicks.getBlueprint(withID: blueprintID)!).numberMinted < (Kicks.getBlueprint(withID: blueprintID)!).maxSupply ?? UInt32.max:
					"Blueprint has reached max supply. Cannot mint further instances."
			}
			
			// Retrieve blueprint resource to modify its fields
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve parent blueprint")
			
			// Create a collection to transfer NFTs afterwards
			var transitoryCollection <- Kicks.createEmptyCollection(nftType: Type<@Kicks.Collection>())
			
			// Repeat mint process
			var i = 0
			while i < quantity{ 
				let newID = blueprint.numberMinted
				
				// create a new NFT
				var newNFT <- create NFT(instanceID: newID, classID: blueprintID, setID: setID, taggedNFT: nil)
				
				// Update blueprint's information
				blueprint.nftAdded(nftID: newID)
				
				// Deposit to transitoryCollection
				transitoryCollection.deposit(token: <-newNFT)
				
				// Increment counter
				i = i + 1
			}
			
			// deposit it in the recipient's account using their reference
			recipient.batchDeposit(tokens: <-transitoryCollection)
			
			// Place blueprint back into set
			let old <- Kicks.blueprints.insert(key: blueprintID, <-blueprint)
			assert(old == nil, message: "Unexpectedly found existing blueprint at newly minted ID. Forcibly assigning currentBlueprint may be required to resolve.")
			destroy old
		}
		
		// ───────────────  Set Organizing Functions  ─────────────── \\
		access(TMP_ENTITLEMENT_OWNER)
		fun addBlueprintToSet(blueprintID: UInt32, setID: UInt32){ 
			var set = Kicks.getSneakerSet(withID: setID) ?? panic("Could not load set")
			set.addBlueprint(blueprintID: blueprintID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeBlueprintFromSet(blueprintID: UInt32, setID: UInt32){ 
			var set = Kicks.getSneakerSet(withID: setID) ?? panic("Could not load set")
			set.removeBlueprint(blueprintID: blueprintID)
		}
		
		// ───────────────  State Modifying Functions  ─────────────── \\
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSetURI(setID: UInt32, newURI: String){ 
			let set = Kicks.getSneakerSet(withID: setID) ?? panic("Unable to retrieve set with given ID")
			set.updateURI(newURI)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSetName(setID: UInt32, newName: String){ 
			let set = Kicks.getSneakerSet(withID: setID) ?? panic("Unable to retrieve set with given ID")
			set.updateName(newName)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBlueprintURI(blueprintID: UInt32, newURI: String, media:{ String: AnyStruct}){ 
			pre{ 
				Kicks.blueprints.containsKey(blueprintID):
					"Blueprint with given ID does not exist"
			}
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve blueprint with given ID")
			blueprint.updateURI(newURI, media: media)
			let old <- Kicks.blueprints[blueprintID] <- blueprint
			destroy old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBlueprintName(blueprintID: UInt32, newName: String){ 
			pre{ 
				Kicks.blueprints.containsKey(blueprintID):
					"Blueprint with given ID does not exist"
			}
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve blueprint with given ID")
			blueprint.updateName(newName)
			let old <- Kicks.blueprints[blueprintID] <- blueprint
			destroy old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addMetadataFieldsToBlueprint(withID blueprintID: UInt32, metadata:{ String: AnyStruct}){ 
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve blueprint with given ID")
			for key in metadata.keys{ 
				if let value = metadata[key]{ 
					blueprint.metadata.insert(key: key, value)
				}
			}
			let old <- Kicks.blueprints[blueprintID] <- blueprint
			destroy old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMetadataFieldsFromBlueprint(withID blueprintID: UInt32, fields: [String]){ 
			var blueprint <- Kicks.blueprints.remove(key: blueprintID) ?? panic("Unable to retrieve blueprint with given ID")
			for key in fields{ 
				blueprint.metadata.remove(key: key)
			}
			let old <- Kicks.blueprints[blueprintID] <- blueprint
			destroy old
		}
		
		/** forceSetNFTMetadata
		
					For use only if needed. Allows admin to forcibly set the metadata from an
					NFT reference. 
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun forceSetNFTMetadata(nft: &Kicks.NFT, key: String, value: AnyStruct){ 
			nft.setMetadata(key: key, value: value)
		}
	}
	
	// ───────────────────────────────────────────────────────────────────────
	// Universal Getters
	// ───────────────────────────────────────────────────────────────────────
	access(TMP_ENTITLEMENT_OWNER)
	fun getBlueprints(): [&Blueprint]{ 
		var blueprints: [&Blueprint] = []
		for blueprintID in self.blueprints.keys{ 
			blueprints.append(&self.blueprints[blueprintID] as &Kicks.Blueprint?)
		}
		return blueprints
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getBlueprint(withID id: UInt32): &Blueprint?{ 
		return &self.blueprints[id] as &Kicks.Blueprint?
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSupplyOfBlueprint(withID id: UInt32): UInt32?{ 
		return self.blueprints[id]?.numberMinted
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSneakerSet(withID id: UInt32): &SneakerSet?{ 
		pre{ 
			self.setIDs.contains(id):
				"Set with ID is not a Sneaker Set"
			self.setsCapability.check():
				"Sets Capability is not valid"
		}
		let sets = self.setsCapability.borrow() ?? panic("Unable to load sets from capability")
		let set = sets[id] as &{NFTLX.ISet}?
		return set as? &SneakerSet
	}
	
	// ───────────────────────────────────────────────────────────────────────
	// Initializers and Setup Functions
	// ───────────────────────────────────────────────────────────────────────
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		// Set Storage Locations
		self.SneakerSetsPrivatePath = /private/NFTLXKicksSneakerSets
		self.CollectionStoragePath = /storage/NFTLXKickCollection
		self.CollectionPublicPath = /public/NFTLXKickCollection
		self.MinterStoragePath = /storage/NFTLXKickMinter
		var capability_1 = self.account.capabilities.storage.issue<&{UInt32:{ NFTLX.ISet}}>(NFTLX.SetsStoragePath)
		self.account.capabilities.publish(capability_1, at: self.SneakerSetsPrivatePath)
		let setsCapability = capability_1
		
		// Initialize fields
		self.totalSupply = 0
		self.currentBlueprint = 0
		self.setIDs = []
		self.setsCapability = setsCapability
		self.blueprints <-{} 
		self.SneakerAttribute = SneakerAttributeKeys()
		
		// Load NFTLX Admin then create upload rights, create a Minter resource and save it to storage
		if let oldAdmin <- self.account.storage.load<@Minter>(from: self.MinterStoragePath){ 
			// NOTE: In event contract is deleted from network, the expected type @Minter will not exist, meaning this will fail.
			destroy oldAdmin
		}
		let minter <- create Minter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		
		// Notify creation🥳
		emit ContractInitialized()
	}
}
