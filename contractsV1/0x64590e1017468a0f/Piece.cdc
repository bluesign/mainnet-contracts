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
	event Minted(id: UInt64, recipient: Address, creatorID: UInt64)
	
	access(all)
	event MetadataSuccess(creatorID: UInt64, textContent: String)
	
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
	
	// Maps metadataId of NFT to NFTMetadata
	access(all)
	let creatorIDs:{ UInt64: [NFTMetadata]}
	
	// You can get a list of purchased NFTs
	// by doing `buyersList.keys`
	access(account)
	let buyersList:{ Address:{ UInt64: [UInt64]}}
	
	access(account)
	let nftStorage: @{Address:{ UInt64: NFT}}
	
	access(all)
	struct NFTMetadata{ 
		access(all)
		let creatorID: UInt64
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let description: String
		
		access(all)
		let image: MetadataViews.HTTPFile
		
		access(all)
		let purchasers:{ UInt64: Address}
		
		access(all)
		let metadataId: UInt64
		
		access(all)
		var minted: UInt64
		
		access(all)
		var extra:{ String: AnyStruct}
		
		access(all)
		var timer: UInt64
		
		access(all)
		let creationTime: UFix64
		
		access(all)
		let embededHTML: String
		
		access(account)
		fun purchased(serial: UInt64, buyer: Address){ 
			self.purchasers[serial] = buyer
		}
		
		access(account)
		fun updateMinted(){ 
			self.minted = self.minted + 1
		}
		
		init(_creatorID: UInt64, _creatorAddress: Address, _description: String, _image: MetadataViews.HTTPFile, _extra:{ String: AnyStruct}, _currentTime: UFix64, _embededHTML: String){ 
			self.metadataId = _creatorID
			self.creatorID = _creatorID
			self.creatorAddress = _creatorAddress
			self.description = _description
			self.image = _image
			self.extra = _extra
			self.minted = 0
			self.purchasers ={} 
			self.timer = 0
			self.creationTime = _currentTime
			self.embededHTML = _embededHTML
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		// The 'metadataId' is what maps this NFT to its 'NFTMetadata'
		access(all)
		let creatorID: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let indexNumber: Int
		
		access(all)
		let originalMinter: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(): NFTMetadata{ 
			return Piece.getNFTMetadata(self.creatorID, self.indexNumber)!
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
					return MetadataViews.Display(name: metadata.creatorID.toString(), description: metadata.description, thumbnail: metadata.image)
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.getMetadata().extra, excludedNames: nil)
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
						return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.HTTPFile(url: metadata.embededHTML!), mediaType: "html")])
					}
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(metadata.creatorAddress).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.10, // 10% royalty on secondary sales																																																  
																																																  description: "The creator of the original content get's 10% of every secondary sale.")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_creatorID: UInt64, _indexNumber: Int, _recipient: Address){ 
			pre{ 
				Piece.creatorIDs[_creatorID] != nil:
					"This NFT does not exist in this collection."
			}
			// Assign serial number to the NFT based on the number of minted NFTs
			let _serial = (Piece.getNFTMetadata(_creatorID, _indexNumber)!).minted
			self.id = self.uuid
			self.creatorID = _creatorID
			self.serial = _serial
			self.indexNumber = _indexNumber
			self.originalMinter = _recipient
			
			// Update the buyers list so we keep track of who is purchasing
			if let buyersRef = &Piece.buyersList[_recipient] as auth(Mutate) &{UInt64: [UInt64]}?{ 
				if let metadataIdMap = buyersRef[_creatorID] as &[UInt64]?{ 
					metadataIdMap.append(_serial)
				} else{ 
					buyersRef[_creatorID] = [_serial]
				}
			} else{ 
				Piece.buyersList[_recipient] ={ _creatorID: [_serial]}
			}
			let metadataRef = &(Piece.creatorIDs[_creatorID]!)[_indexNumber] as &NFTMetadata
			// Update who bought this serial inside NFTMetadata
			metadataRef.purchased(serial: _serial, buyer: _recipient)
			// Update the total supply of this MetadataId by 1
			metadataRef.updateMinted()
			// Update Piece collection NFTs count
			Piece.totalSupply = Piece.totalSupply + 1
			emit Minted(id: self.id, recipient: _recipient, creatorID: _creatorID)
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface PieceCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
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
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
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
		access(TMP_ENTITLEMENT_OWNER)
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
			return nft as &{ViewResolver.Resolver}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(){ 
			if let storage = &Piece.nftStorage[(self.owner!).address] as auth(Mutate) &{UInt64: NFT}?{ 
				for id in storage.keys{ 
					self.deposit(token: <-storage.remove(key: id)!)
				}
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
	
	access(all)
	resource Administrator{ 
		
		// Function to upload the Metadata to the contract.
		access(TMP_ENTITLEMENT_OWNER)
		fun createNFTMetadata(channel: String, creatorID: UInt64, creatorAddress: Address, sourceURL: String, textContent: String, pieceCreationDate: String, contentCreationDate: String, imgUrl: String, embededHTML: String){ 
			// Check if a record for this ID Exist, if not
			// create am empty one for it
			if Piece.creatorIDs[creatorID] == nil{ 
				Piece.creatorIDs[creatorID] = []
			}
			
			// Check if that creatorID has uploaded any NFTs
			// If not, then stop and return error Event
			if let account_NFTs = &Piece.creatorIDs[creatorID] as &[Piece.NFTMetadata]?{ 
				if self.isMetadataUploaded(_metadatasArray: account_NFTs, _textContent: textContent){ 
					emit MetadataError(error: "A Metadata for this Event already exist")
				} else{ 
					Piece.creatorIDs[creatorID]?.append(NFTMetadata(_creatorID: creatorID, _creatorAddress: creatorAddress, _description: textContent, _image: MetadataViews.HTTPFile(url: imgUrl), _extra:{ "Channel": channel, "Creator": creatorID, "Source": sourceURL, "Text content": textContent, "Piece creation date": pieceCreationDate, "Content creation date": contentCreationDate}, _currentTime: getCurrentBlock().timestamp, _embededHTML: embededHTML))
					emit MetadataSuccess(creatorID: creatorID, textContent: textContent)
				}
			}
		}
		
		// mintNFT mints a new NFT and deposits
		// it in the recipients collection
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(creatorID: UInt64, indexNumber: Int, recipient: Address){ 
			pre{ 
				self.isMintingAvailable(_creatorID: creatorID, _indexNumber: indexNumber):
					"Minting for this NFT has ended."
			}
			let nft <- create NFT(_creatorID: creatorID, _indexNumber: indexNumber, _recipient: recipient)
			if let recipientCollection = getAccount(recipient).capabilities.get<&Piece.Collection>(Piece.CollectionPublicPath).borrow<&Piece.Collection>(){ 
				recipientCollection.deposit(token: <-nft)
			} else if let storage = &Piece.nftStorage[recipient] as auth(Mutate) &{UInt64: NFT}?{ 
				storage[nft.id] <-! nft
			} else{ 
				Piece.nftStorage[recipient] <-!{ nft.id: <-nft}
			}
		}
		
		// create a new Administrator resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Administrator{ 
			return <-create Administrator()
		}
		
		// change piece of collection info
		access(TMP_ENTITLEMENT_OWNER)
		fun changeField(key: String, value: AnyStruct){ 
			Piece.collectionInfo[key] = value
		}
		
		access(account)
		view fun isMintingAvailable(_creatorID: UInt64, _indexNumber: Int): Bool{ 
			let metadata = Piece.getNFTMetadata(_creatorID, _indexNumber)!
			let answer = getCurrentBlock().timestamp <= metadata.creationTime + 86400.0
			return answer
		}
		
		access(account)
		fun isMetadataUploaded(_metadatasArray: &[Piece.NFTMetadata], _textContent: String): Bool{ 
			var i = 0
			while i < _metadatasArray.length{ 
				if _metadatasArray[i].description == _textContent{ 
					return true
				}
				i = i + 1
			}
			return false
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
	access(TMP_ENTITLEMENT_OWNER)
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
	
	//Get all the recorded creatorIDs 
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllcreatorIDs(): [UInt64]{ 
		return self.creatorIDs.keys
	}
	
	// Get information about a NFTMetadata
	access(TMP_ENTITLEMENT_OWNER)
	view fun getNFTMetadata(_ creatorID: UInt64, _ indexNumber: Int): NFTMetadata?{ 
		return (self.creatorIDs[creatorID]!)[indexNumber]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getOnecreatorIdMetadatas(creatorID: UInt64): [NFTMetadata]?{ 
		return self.creatorIDs[creatorID]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTimeRemaining(_creatorID: UInt64, _indexNumber: Int): UFix64?{ 
		let metadata = Piece.getNFTMetadata(_creatorID, _indexNumber)!
		let answer = metadata.creationTime + 86400.0 - getCurrentBlock().timestamp
		return answer
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getbuyersList():{ Address:{ UInt64: [UInt64]}}{ 
		return self.buyersList
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionInfo():{ String: AnyStruct}{ 
		let collectionInfo = self.collectionInfo
		collectionInfo["creatorIDs"] = self.creatorIDs
		collectionInfo["buyersList"] = self.buyersList
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["version"] = 1
		return collectionInfo
	}
	
	access(TMP_ENTITLEMENT_OWNER)
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
		self.creatorIDs ={} 
		self.buyersList ={} 
		self.nftStorage <-{} 
		
		// Set the named paths
		self.CollectionStoragePath = /storage/PieceCollection
		self.CollectionPublicPath = /public/PieceCollection
		self.CollectionPrivatePath = /private/PieceCollection
		self.AdministratorStoragePath = /storage/PieceAdministrator
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// Create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Administrator resource and save it to storage
		let administrator <- create Administrator()
		self.account.storage.save(<-administrator, to: self.AdministratorStoragePath)
		emit ContractInitialized()
	}
}
