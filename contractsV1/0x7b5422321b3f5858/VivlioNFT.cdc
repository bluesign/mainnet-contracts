import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract VivlioNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					let editionInfo = MetadataViews.Edition(name: "Genoma23", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://genoma23.com/en/gallery/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: VivlioNFT.CollectionStoragePath, publicPath: VivlioNFT.CollectionPublicPath, publicCollection: Type<&VivlioNFT.Collection>(), publicLinkedType: Type<&VivlioNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-VivlioNFT.createEmptyCollection(nftType: Type<@VivlioNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let square = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/sWYJMBu.jpg"), mediaType: "image/jpeg")
					let banner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/4nQg7xY.jpeg"), mediaType: "image/jpeg")
					return MetadataViews.NFTCollectionDisplay(name: "G23ANDME", description: "Life is Art, turn your DNA into art through Genome 23 / La vida es Arte, convierte tu ADN en Arte a trav\u{e9}s del Genoma 23", externalURL: MetadataViews.ExternalURL("https://genoma23.com/en/about-us/"), squareImage: square, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/artegenoma23"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/artegenoma23/"), "facebook": MetadataViews.ExternalURL("https://www.facebook.com/Genoma23-101738548973485"), "pinterest": MetadataViews.ExternalURL("https://www.pinterest.es/artegenoma23/"), "youtube": MetadataViews.ExternalURL("https://www.youtube.com/channel/UC_KLJBjwHVOPZV6hLhR9G6g")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime and foo to show other uses of Traits
					let excludedTraits = ["dna"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					
					// foo is a trait with its own rarity
					let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
					
					// We add the DNA Art
					let dnaTrait = MetadataViews.Trait(name: "dnaArt", value: self.metadata["dna"]!, displayType: "IPFSFile", rarity: fooTraitRarity)
					traitsView.addTrait(dnaTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface VivlioNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowVivlioNFT(id: UInt64): &VivlioNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow VivlioNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: VivlioNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @VivlioNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowVivlioNFT(id: UInt64): &VivlioNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &VivlioNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let vivlioNFT = nft as! &VivlioNFT.NFT
			return vivlioNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], ipfsCid: String){ 
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			
			// this piece of metadata will be used to show embedding dna into a trait
			metadata["dna"] = MetadataViews.IPFSFile(cid: ipfsCid, path: nil)
			
			// create a new NFT
			var newNFT <- create NFT(id: VivlioNFT.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			VivlioNFT.totalSupply = VivlioNFT.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/vivlioNFTCollection
		self.CollectionPublicPath = /public/vivlioNFTCollection
		self.MinterStoragePath = /storage/vivlioNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&VivlioNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
