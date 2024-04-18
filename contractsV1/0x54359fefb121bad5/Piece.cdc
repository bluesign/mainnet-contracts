import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract Piece: NonFungibleToken, ViewResolver{ 
	
	// Collection Information
	access(self)
	let collectionInfo:{ String: AnyStruct}
	
	// Contract Information
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, serial: UInt64, recipient: Address, creatorID: UInt64)
	
	access(all)
	event MetadataSuccess(creatorID: UInt64, description: String)
	
	access(all)
	event MetadataError(error: String)
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdministratorStoragePath: StoragePath
	
	access(all)
	let MetadataStoragePath: StoragePath
	
	access(all)
	let MetadataPublicPath: PublicPath
	
	access(account)
	let nftStorage: @{Address:{ UInt64: NFT}}
	
	access(all)
	resource MetadataStorage: MetadataStoragePublic{ 
		// List of Creator 
		access(all)
		var creatorsIds:{ UInt64: [NFTMetadata]}
		
		init(){ 
			self.creatorsIds ={} 
		}
		
		access(account)
		fun creatorExist(_ creatorId: UInt64){ 
			if self.creatorsIds[creatorId] == nil{ 
				self.creatorsIds[creatorId] = []
			}
		}
		
		access(account)
		fun metadataIsNew(_ creatorId: UInt64, _ description: String): Bool{ 
			self.creatorExist(creatorId)
			let metadata = self.findMetadata(creatorId, description)
			if metadata == nil{ 
				return true
			} else{ 
				return false
			}
		}
		
		access(account)
		fun addMetadata(_ creatorId: UInt64, _ metadata: NFTMetadata){ 
			if self.creatorsIds[creatorId] == nil{ 
				self.creatorsIds[creatorId] = []
			}
			self.creatorsIds[creatorId]?.append(metadata)
		}
		
		access(account)
		fun updateMinted(_ creatorId: UInt64, _ description: String){ 
			let metadataRef = self.findMetadataRef(creatorId, description)!
			metadataRef.updateMinted()
		}
		
		// Public Functions
		access(all)
		fun findMetadataRef(_ creatorId: UInt64, _ description: String): &Piece.NFTMetadata?{ 
			let metadatas = self.creatorsIds[creatorId]!
			var i = metadatas.length - 1
			while i >= 0{ 
				if metadatas[i].description == description{ 
					let metadataRef: &Piece.NFTMetadata = &(self.creatorsIds[creatorId]!)[i] as &NFTMetadata
					return metadataRef
				}
				i = i - 1
			}
			return nil
		}
		
		// Public Functions
		access(all)
		view fun findMetadata(_ creatorId: UInt64, _ description: String): Piece.NFTMetadata?{ 
			let metadatas = self.creatorsIds[creatorId]!
			var i = metadatas.length - 1
			while i >= 0{ 
				if metadatas[i].description == description{ 
					return metadatas[i]
				}
				i = i - 1
			}
			return nil
		}
		
		access(all)
		fun getTimeRemaining(_ creatorID: UInt64, _ description: String): UFix64?{ 
			let metadata = self.findMetadata(creatorID, description)!
			let answer = metadata.creationTime + 86400.0 - getCurrentBlock().timestamp
			return answer
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface MetadataStoragePublic{ 
		access(all)
		fun getTimeRemaining(_ creatorID: UInt64, _ description: String): UFix64?
		
		access(all)
		view fun findMetadata(_ creatorId: UInt64, _ description: String): Piece.NFTMetadata?
	}
	
	access(all)
	struct NFTMetadata{ 
		access(all)
		let creatorID: UInt64
		
		access(all)
		var creatorUsername: String
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let description: String
		
		access(all)
		let image: MetadataViews.HTTPFile
		
		access(all)
		let metadataId: UInt64
		
		access(all)
		var supply: UInt64
		
		access(all)
		var minted: UInt64
		
		access(all)
		let unlimited: Bool
		
		access(all)
		var extra:{ String: AnyStruct}
		
		access(all)
		var timer: UInt64
		
		access(all)
		let pieceCreationDate: String
		
		access(all)
		let contentCreationDate: String
		
		access(all)
		let creationTime: UFix64
		
		access(all)
		let lockdownTime: UFix64
		
		access(all)
		let embededHTML: String
		
		access(account)
		fun updateMinted(){ 
			self.minted = self.minted + 1
			if self.unlimited{ 
				self.supply = self.supply + 1
			}
		}
		
		init(_creatorID: UInt64, _creatorUsername: String, _creatorAddress: Address, _description: String, _image: MetadataViews.HTTPFile, _supply: UInt64, _extra:{ String: AnyStruct}, _pieceCreationDate: String, _contentCreationDate: String, _currentTime: UFix64, _lockdownTime: UFix64, _embededHTML: String){ 
			self.metadataId = _creatorID
			self.creatorID = _creatorID
			self.creatorUsername = _creatorUsername
			self.creatorAddress = _creatorAddress
			self.description = _description
			self.image = _image
			self.extra = _extra
			self.supply = _supply
			self.unlimited = _supply == 0
			self.minted = 0
			self.timer = 0
			self.pieceCreationDate = _pieceCreationDate
			self.contentCreationDate = _contentCreationDate
			self.creationTime = _currentTime
			self.lockdownTime = _lockdownTime
			self.embededHTML = _embededHTML
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// The 'metadataId' is what maps this NFT to its 'NFTMetadata'
		access(all)
		let creatorID: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let description: String
		
		access(all)
		let originalMinter: Address
		
		access(all)
		fun getMetadata(): NFTMetadata{ 
			return Piece.getNFTMetadata(self.creatorID, self.description)!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>(), Type<MetadataViews.NFTView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = self.getMetadata()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.creatorUsername.concat(" ").concat(metadata.contentCreationDate), description: metadata.description, thumbnail: metadata.image)
				case Type<MetadataViews.Traits>():
					let metaCopy = metadata.extra
					metaCopy["Serial"] = self.serial
					metaCopy["Supply"] = metadata.supply
					return MetadataViews.dictToTraits(dict: metaCopy, excludedNames: nil)
				case Type<MetadataViews.NFTView>():
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?, externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?, collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?, collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?, royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?, traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?)
				case Type<MetadataViews.NFTCollectionData>():
					return Piece.resolveView(view)
				case Type<MetadataViews.ExternalURL>():
					return Piece.getCollectionAttribute(key: "website") as! MetadataViews.ExternalURL
				case Type<MetadataViews.NFTCollectionDisplay>():
					return Piece.resolveView(view)
				case Type<MetadataViews.Medias>():
					if metadata.embededHTML != nil{ 
						return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: metadata.embededHTML), mediaType: "html")])
					}
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(metadata.creatorAddress).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!, cut: 0.10, // 10% royalty on secondary sales																																																   
																																																   description: "The creator of the original content gets 10% of every secondary sale.")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_creatorID: UInt64, _description: String, _recipient: Address){ 
			
			// Fetch the metadata blueprint
			let metadatas <- Piece.account.storage.load<@Piece.MetadataStorage>(from: Piece.MetadataStoragePath)!
			let metadataRef = metadatas.findMetadata(_creatorID, _description)!
			// Assign serial number to the NFT based on the number of minted NFTs
			self.id = self.uuid
			self.creatorID = _creatorID
			self.serial = metadataRef.minted
			self.description = _description
			self.originalMinter = _recipient
			
			// Update the total supply of this MetadataId by 1
			metadatas.updateMinted(_creatorID, _description)
			// Update Piece collection NFTs count 
			Piece.totalSupply = Piece.totalSupply + 1
			emit Minted(id: self.id, serial: self.serial, recipient: _recipient, creatorID: _creatorID)
			Piece.account.storage.save(<-metadatas, to: Piece.MetadataStoragePath)
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface PieceCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowPiece(id: UInt64): &Piece.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Piece NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PieceCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Withdraw removes an NFT from the collection and moves it to the caller(for Trading)
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		// GetIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// BorrowNFT gets a reference to an NFT in the collection
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Gets a reference to an NFT in the collection so that 
		/// the caller can read its metadata and call its methods
		///
		/// @param id: The ID of the wanted NFT
		/// @return A reference to the wanted NFT resource
		///		
		access(all)
		fun borrowPiece(id: UInt64): &Piece.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Piece.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = token as! &NFT
			return nft
		}
		
		access(all)
		fun claim(){ 
			if let storage = &Piece.nftStorage[(self.owner!).address] as auth(Mutate) &{UInt64: NFT}?{ 
				for id in storage.keys{ 
					self.deposit(token: <-storage.remove(key: id)!)
				}
			}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	resource Administrator{ 
		// Function to upload the Metadata to the contract.
		access(all)
		fun createNFTMetadata(channel: String, creatorID: UInt64, creatorUsername: String, creatorAddress: Address, sourceURL: String, description: String, pieceCreationDate: String, contentCreationDate: String, lockdownOption: Int, supplyOption: UInt64, imgUrl: String, embededHTML: String){ 
			// Load the metadata from the Piece account
			let metadatas <- Piece.account.storage.load<@Piece.MetadataStorage>(from: Piece.MetadataStoragePath)!
			// Check if Metadata already exist
			if metadatas.metadataIsNew(creatorID, description){ 
				metadatas.addMetadata(creatorID, NFTMetadata(_creatorID: creatorID, _creatorUsername: creatorUsername, _creatorAddress: creatorAddress, _description: description, _image: MetadataViews.HTTPFile(url: imgUrl), _supply: supplyOption, _extra:{ "Creator username": creatorUsername, "Creator ID": creatorID, "Channel": channel, "Text content": description, "Source": sourceURL, "Piece creation date": pieceCreationDate, "Content creation date": contentCreationDate}, _pieceCreationDate: pieceCreationDate, _contentCreationDate: contentCreationDate, _currentTime: getCurrentBlock().timestamp, _lockdownTime: self.getLockdownTime(lockdownOption), _embededHTML: embededHTML))
				emit MetadataSuccess(creatorID: creatorID, description: description)
			} else{ 
				emit MetadataError(error: "A Metadata for this Event already exist")
			}
			Piece.account.storage.save(<-metadatas, to: Piece.MetadataStoragePath)
		}
		
		// mintNFT mints a new NFT and deposits
		// it in the recipients collection
		access(all)
		fun mintNFT(creatorId: UInt64, description: String, recipient: Address){ 
			pre{ 
				self.isMintingAvailable(creatorId, description):
					"Minting for this NFT has ended or reached max supply."
			}
			let nft <- create NFT(_creatorID: creatorId, _description: description, _recipient: recipient)
			if let recipientCollection = (getAccount(recipient).capabilities.get<&Piece.Collection>(Piece.CollectionPublicPath)!).borrow(){ 
				recipientCollection.deposit(token: <-nft)
			} else if let storage = &Piece.nftStorage[recipient] as auth(Mutate) &{UInt64: NFT}?{ 
				storage[nft.id] <-! nft
			} else{ 
				Piece.nftStorage[recipient] <-!{ nft.id: <-nft}
			}
		}
		
		// create a new Administrator resource
		access(all)
		fun createAdmin(): @Administrator{ 
			return <-create Administrator()
		}
		
		// change piece of collection info
		access(all)
		fun changeField(key: String, value: AnyStruct){ 
			Piece.collectionInfo[key] = value
		}
		
		access(account)
		view fun isMintingAvailable(_ creatorId: UInt64, _ description: String): Bool{ 
			let metadata = Piece.getNFTMetadata(creatorId, description)!
			if metadata.unlimited{ 
				if metadata.lockdownTime != 0.0{ 
					let answer = getCurrentBlock().timestamp <= metadata.creationTime + metadata.lockdownTime
					return answer
				} else{ 
					return true
				}
			} else if metadata.minted < metadata.supply{ 
				if metadata.lockdownTime != 0.0{ 
					let answer = getCurrentBlock().timestamp <= metadata.creationTime + metadata.lockdownTime
					return answer
				} else{ 
					return true
				}
			} else{ 
				return false
			}
		}
		
		access(account)
		fun getLockdownTime(_ lockdownOption: Int): UFix64{ 
			switch lockdownOption{ 
				case 0:
					return 43200.0
				case 1:
					return 86400.0
				default:
					return 0.0
			}
		}
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// Function that resolves a metadata view for this contract.
	///
	/// @param view: The Type of the desired view.
	/// @return A structure representing the requested view.
	///
	access(all)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: Piece.CollectionStoragePath, publicPath: Piece.CollectionPublicPath, publicCollection: Type<&Piece.Collection>(), publicLinkedType: Type<&Piece.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-Piece.createEmptyCollection(nftType: Type<@Piece.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = Piece.getCollectionAttribute(key: "image") as! MetadataViews.Media
				return MetadataViews.NFTCollectionDisplay(name: "Piece", description: "Sell Pieces of any Tweet in seconds.", externalURL: MetadataViews.ExternalURL("https://piece.gg/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/CreateAPiece")})
		}
		return nil
	}
	
	// Get information about a NFTMetadata
	access(all)
	view fun getNFTMetadata(_ creatorId: UInt64, _ description: String): Piece.NFTMetadata?{ 
		let publicAccount = self.account
		let metadataCapability: Capability<&{Piece.MetadataStoragePublic}> = publicAccount.capabilities.get<&{MetadataStoragePublic}>(self.MetadataPublicPath)!
		let metadatasRef: &{Piece.MetadataStoragePublic} = metadataCapability.borrow()!
		let metadatas: Piece.NFTMetadata? = metadatasRef.findMetadata(creatorId, description)
		return metadatas
	}
	
	access(all)
	fun getCollectionInfo():{ String: AnyStruct}{ 
		let collectionInfo = self.collectionInfo
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["version"] = 1
		return collectionInfo
	}
	
	access(all)
	fun getCollectionAttribute(key: String): AnyStruct{ 
		return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
	}
	
	init(){ 
		// Collection Info
		self.collectionInfo ={} 
		self.collectionInfo["name"] = "Piece"
		self.collectionInfo["description"] = "Sell Pieces of any Tweet in seconds."
		self.collectionInfo["image"] = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://media.discordapp.net/attachments/1075564743152107530/1149417271597473913/Piece_collection_image.png?width=1422&height=1422"), mediaType: "image/jpeg")
		self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
		self.collectionInfo["website"] = MetadataViews.ExternalURL("https://www.piece.gg/")
		self.collectionInfo["socials"] ={ "Twitter": MetadataViews.ExternalURL("https://frontend-react-git-testing-piece.vercel.app/")}
		self.totalSupply = 0
		self.nftStorage <-{} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/PieceCollection
		self.CollectionPublicPath = /public/PieceCollection
		self.CollectionPrivatePath = /private/PieceCollection
		self.AdministratorStoragePath = /storage/PieceAdministrator
		self.MetadataStoragePath = /storage/PieceMetadata
		self.MetadataPublicPath = /public/PieceMetadata
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Administrator resource and save it to Piece account storage
		let administrator <- create Administrator()
		self.account.storage.save(<-administrator, to: self.AdministratorStoragePath)
		
		// Create a Metadata Storage resource and save it to Piece account storage
		let metadataStorage <- create MetadataStorage()
		self.account.storage.save(<-metadataStorage, to: self.MetadataStoragePath)
		
		// Create a public capability for the Metadata Storage
		var capability_2 = self.account.capabilities.storage.issue<&MetadataStorage>(self.MetadataStoragePath)
		self.account.capabilities.publish(capability_2, at: self.MetadataPublicPath)
		emit ContractInitialized()
	}
}
