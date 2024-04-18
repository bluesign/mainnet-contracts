import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract MonoCat: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	//pub var CollectionPrivatePath: PrivatePath
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	// We use dict to store raw metadata
	access(all)
	resource interface RawMetadata{ 
		access(all)
		fun getRawMetadata():{ String: String}
	}
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver, RawMetadata{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, metadata:{ String: String}){ 
			self.id = id
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.ExternalURL>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				// Display view
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"]!, description: self.metadata["description"]!, thumbnail: MetadataViews.HTTPFile(url: "https://arweave.net/".concat(self.metadata["image"]!)))
				// royalties view
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0xc7246d622d0db9f1).capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenReceiver)!, cut: 0.075, description: "MonoCats Official")])
				
				// collection data view
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MonoCat.CollectionStoragePath, publicPath: MonoCat.CollectionPublicPath, publicCollection: Type<&MonoCat.Collection>(), publicLinkedType: Type<&MonoCat.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MonoCat.createEmptyCollection(nftType: Type<@MonoCat.Collection>())
						})
				
				// external url view
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://monocats.xyz/mainpage")
				
				// collection display view
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/nft/monocats/MonoCatSet_350x350.png"), mediaType: "image/png")
					let banner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://static.mono.fun/public/contents/projects/a73c1a41-be88-4c7c-a32e-929d453dbd39/carousels/mono%20cats%20PC.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "MonoCats", description: "Each NFT represent a MonoCats from the Meow Planets comes with unique design and utility.", externalURL: MetadataViews.ExternalURL("https://monocats.xyz/mainpage"), squareImage: media, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://monocats.xyz/twitter"), "discord": MetadataViews.ExternalURL("https://monocats.xyz/discord"), "instagram": MetadataViews.ExternalURL("https://monocats.xyz/instagram")})
			}
			return nil
		}
		
		access(all)
		fun getRawMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface MonoCatCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowMonoCat(id: UInt64): &MonoCat.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MonoCatCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @MonoCat.NFT
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
		fun borrowMonoCat(id: UInt64): &MonoCat.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MonoCat.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mlNFT = nft as! &MonoCat.NFT
			return mlNFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			assert(MonoCat.totalSupply + 1 <= 12500, message: "Mint would exceed max supply")
			
			// create a new NFT
			var newNFT <- create NFT(id: MonoCat.totalSupply, metadata: metadata)
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MonoCat.totalSupply = MonoCat.totalSupply + 1
			emit Mint(id: tokenRef.id, metadata: metadata)
			return tokenRef
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MonoCatCollection
		self.CollectionPublicPath = /public/MonoCatCollection
		self.MinterStoragePath = /storage/MonoCatMinter
		self.MinterPublicPath = /public/MonoCatMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&MonoCat.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
