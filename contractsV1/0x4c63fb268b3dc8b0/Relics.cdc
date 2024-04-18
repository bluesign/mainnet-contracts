/*******************************************
Modern Musician Relic Contract v.0.1.4
description: This smart contract functions as the main Modern Musician NFT ('Relics') production contract.
It follows Flow's NonFungibleToken standards as well as uses a MetadataViews implementation.
developed by info@spaceleaf.io
*******************************************/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Relics: NonFungibleToken{ 
	
	// define events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, rarity: String, relicId: String, creatorId: String)
	
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address?)
	
	// define storage paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	// track total supply of Relics
	access(all)
	var totalSupply: UInt64
	
	// maps all relicIds to creatorId->  creatorId : [relicId]
	access(all)
	var creatorRelicMap:{ String: [String]}
	
	// maps all editions by relicId-> relicId : [editions]
	access(all)
	var relicEditionMap:{ String: [UInt64]}
	
	// maps all editions by creatorId-> creatorId : [editions]
	access(all)
	var creatorEditionMap:{ String: [UInt64]}
	
	// Dictionary of serial numbers mapped to creatorId
	access(all)
	var creatorSerialMap:{ String: [Int]}
	
	// Dictionary to query owner address by Edition ID (id)
	access(all)
	var idToOwnerMap:{ UInt64: Address}
	
	access(all)
	fun updateIdToOwnerMap(id: UInt64, address: Address): Address?{ 
		Relics.idToOwnerMap[id] = address
		return Relics.idToOwnerMap[id]
	}
	
	// Relic NFT resource definition
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creatorId: String
		
		access(all)
		let relicId: String
		
		access(all)
		let rarity: String
		
		access(all)
		let category: String
		
		access(all)
		let type: String
		
		access(all)
		let creatorName: String
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let editionSize: UInt64
		
		access(all)
		let mintDate: String
		
		access(all)
		var assetVideoURL: String
		
		access(all)
		var assetImageURL: String
		
		access(all)
		var musicURL: String
		
		access(all)
		var artworkURL: String
		
		access(all)
		var marketDisplay: String
		
		access(all)
		let serial: Int
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(_initID: UInt64, _creatorId: String, _relicId: String, _rarity: String, _category: String, _type: String, _creatorName: String, _title: String, _description: String, _edition: UInt64, _editionSize: UInt64, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _serial: Int, _royalties: [MetadataViews.Royalty]){ 
			self.id = _initID
			self.creatorId = _creatorId
			self.relicId = _relicId
			self.rarity = _rarity
			self.category = _category
			self.type = _type
			self.creatorName = _creatorName
			self.title = _title
			self.description = _description
			self.edition = _edition
			self.editionSize = _editionSize
			self.mintDate = _mintDate
			self.assetVideoURL = _assetVideoURL
			self.assetImageURL = _assetImageURL
			self.musicURL = _musicURL
			self.artworkURL = _artworkURL
			self.marketDisplay = _assetImageURL
			self.serial = _serial
			self.royalties = _royalties
		}
		
		access(contract)
		fun updateAssetVideoURL(_newAssetVideoURL: String){ 
			self.assetVideoURL = _newAssetVideoURL
		}
		
		access(contract)
		fun updateAssetImageURL(_newAssetImageURL: String){ 
			self.assetImageURL = _newAssetImageURL
		}
		
		access(contract)
		fun updateMusicURL(_newMusicURL: String){ 
			self.musicURL = _newMusicURL
		}
		
		access(contract)
		fun updateArtworkURL(_newArtworkURL: String){ 
			self.artworkURL = _newArtworkURL
		}
		
		access(contract)
		fun updateMarketDisplay(_newURL: String){ 
			self.marketDisplay = _newURL
		}
		
		access(contract)
		fun updateMediaURLs(_newAssetVideoURL: String, _newAssetImageURL: String, _newMusicURL: String, _newArtworkURL: String, _newMarketDisplay: String){ 
			self.assetVideoURL = _newAssetVideoURL
			self.assetImageURL = _newAssetImageURL
			self.musicURL = _newMusicURL
			self.artworkURL = _newArtworkURL
			self.marketDisplay = _newMarketDisplay
		}
		
		access(all)
		fun name(): String{ 
			return self.creatorName.concat(" - ").concat(self.title)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Identity>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name(), description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.assetImageURL), id: self.id, category: self.category, rarity: self.rarity, type: self.type, creatorName: self.creatorName, title: self.title, mintDate: self.mintDate, assetVideoURL: self.assetVideoURL, assetImageURL: self.assetImageURL, musicURL: self.musicURL, artworkURL: self.artworkURL)
				case Type<MetadataViews.Identity>():
					return MetadataViews.Identity(uuid: self.uuid)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(": https://www.musicRelics.com/".concat(self.id.toString()))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: self.rarity, number: self.edition, max: self.editionSize)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(UInt64(self.serial))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Relics.CollectionStoragePath, publicPath: Relics.CollectionPublicPath, publicCollection: Type<&Relics.Collection>(), publicLinkedType: Type<&Relics.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Relics.createEmptyCollection(nftType: Type<@Relics.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.marketDisplay), mediaType: "image")
					let image = MetadataViews.Media(file: MetadataViews.HTTPFile(url: self.artworkURL), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: self.name(), description: self.description, externalURL: MetadataViews.ExternalURL("https://www.musicRelics.com/"), squareImage: media, bannerImage: image, socials:{} )
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// defines the public Relic Collection resource interface
	access(all)
	resource interface RelicCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowRelic(id: UInt64): &Relics.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Relic reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// defines the public Relic Collection resource
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, RelicCollectionPublic{ 
		// Dictionary of Relic conforming tokens
		// NFT is a resource type with a UInt64 ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Relic not found.")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let relic <- token as! @Relics.NFT
			emit Deposit(id: relic.id, to: self.owner?.address)
			self.ownedNFTs[relic.id] <-! relic
		}
		
		access(all)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("Relic not found.")
			recipient.deposit(token: <-token)
			emit Transfer(id: id, from: self.owner?.address, to: recipient.owner?.address)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowRelic(id: UInt64): &Relics.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Relics.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let relic = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let getRelic = relic as! &Relics.NFT
			return getRelic
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
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Relics.Collection()
	}
	
	// the RelicMinter is stored on the deployment account and used to mint all Relics / Editions as well as store functions for updating media urls (if needed).
	access(all)
	resource RelicMinter{ 
		access(all)
		fun mintRelic(recipient: &{NonFungibleToken.CollectionPublic}, _receiverAddress: Address, _creatorId: String, _relicId: String, _rarity: String, _category: String, _type: String, _creatorName: String, _title: String, _description: String, _edition: UInt64, _editionSize: UInt64, _mintDate: String, _assetVideoURL: String, _assetImageURL: String, _musicURL: String, _artworkURL: String, _royalties: [MetadataViews.Royalty]){ 
			
			//Check if any serial numbers exist for this creator yet, if not set the first at 1 so it can be used for the mint. Otherwise, add the next value so it can be used.
			if Relics.creatorSerialMap[_creatorId] == nil{ 
				Relics.creatorSerialMap.insert(key: _creatorId, [1])
			} else{ 
				(Relics.creatorSerialMap[_creatorId]!).append((Relics.creatorSerialMap[_creatorId]!).length + 1)
			}
			
			// mint Relic NFT
			recipient.deposit(token: <-create NFT(_initID: Relics.totalSupply, _creatorId: _creatorId, _relicId: _relicId, _rarity: _rarity, _category: _category, _type: _type, _creatorName: _creatorName, _title: _title, _description: _description, _edition: _edition, _editionSize: _editionSize, _mintDate: _mintDate, _assetVideoURL: _assetVideoURL, _assetImageURL: _assetImageURL, _musicURL: _musicURL, _artworkURL: _artworkURL, _serial: (Relics.creatorSerialMap[_creatorId]!).length, _royalties: _royalties))
			emit Minted(id: Relics.totalSupply, rarity: _rarity, relicId: _relicId, creatorId: _creatorId)
			
			// update the creatorRelicMap
			if Relics.creatorRelicMap[_creatorId] == nil{ 
				Relics.creatorRelicMap.insert(key: _creatorId, [_relicId])
			} else if (Relics.creatorRelicMap[_creatorId]!).contains(_relicId){ 
				log("relicId already present in creatorRelicMap")
			} else{ 
				(Relics.creatorRelicMap[_creatorId]!).append(_relicId)
			}
			
			// update the relicEditionMap
			if Relics.relicEditionMap[_relicId] == nil{ 
				Relics.relicEditionMap.insert(key: _relicId, [Relics.totalSupply])
			} else{ 
				(Relics.relicEditionMap[_relicId]!).append(Relics.totalSupply)
			}
			
			// update the creatorEditionMap
			if Relics.creatorEditionMap[_creatorId] == nil{ 
				Relics.creatorEditionMap.insert(key: _creatorId, [Relics.totalSupply])
			} else{ 
				(Relics.creatorEditionMap[_creatorId]!).append(Relics.totalSupply)
			}
			
			// update the idToOwnerMap to map owner Address to the Edition id
			Relics.idToOwnerMap.insert(key: Relics.totalSupply, _receiverAddress)
			
			// increment total supply by 1 after mint is complete
			Relics.totalSupply = Relics.totalSupply + 1
		}
		
		// update a single media URL on a single edition
		access(all)
		fun updateMediaURL(_from: Address, _id: UInt64, _whichURL: String, _newURL: String){ 
			let collection = (getAccount(_from).capabilities.get<&Relics.Collection>(Relics.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
			let edition = collection.borrowRelic(id: _id)
			switch _whichURL{ 
				case "assetVideoURL":
					edition?.updateAssetVideoURL(_newAssetVideoURL: _newURL)
				case "assetImageURL":
					edition?.updateAssetImageURL(_newAssetImageURL: _newURL)
				case "artworkURL":
					edition?.updateArtworkURL(_newArtworkURL: _newURL)
				case "musicURL":
					edition?.updateMusicURL(_newMusicURL: _newURL)
				case "marketDisplay":
					edition?.updateMarketDisplay(_newURL: _newURL)
			}
		}
		
		// update all media URLs on a single edition
		access(all)
		fun updateMediaURLs(from: Address, id: UInt64, _newAssetVideoURL: String, _newAssetImageURL: String, _newMusicURL: String, _newArtworkURL: String, _newMarketDisplay: String){ 
			let collection = (getAccount(from).capabilities.get<&Relics.Collection>(Relics.CollectionPublicPath)!).borrow() ?? panic("Couldn't get collection")
			let edition = collection.borrowRelic(id: id)
			edition?.updateMediaURLs(_newAssetVideoURL: _newAssetVideoURL, _newAssetImageURL: _newAssetImageURL, _newMusicURL: _newMusicURL, _newArtworkURL: _newArtworkURL, _newMarketDisplay: _newMarketDisplay)
		}
	}
	
	// initialize contract states
	init(){ 
		self.CollectionStoragePath = /storage/RelicCollection
		self.CollectionPublicPath = /public/RelicCollection
		self.MinterStoragePath = /storage/RelicMinter
		self.totalSupply = 0
		self.creatorRelicMap ={} 
		self.creatorEditionMap ={} 
		self.relicEditionMap ={} 
		self.idToOwnerMap ={} 
		self.creatorSerialMap ={} 
		let minter <- create RelicMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let collection <- Relics.createEmptyCollection(nftType: Type<@Relics.Collection>())
		self.account.storage.save(<-collection, to: Relics.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Relics.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
