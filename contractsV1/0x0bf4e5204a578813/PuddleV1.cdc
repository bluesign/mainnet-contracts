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

access(all)
contract PuddleV1: NonFungibleToken{ 
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
					let editionInfo = MetadataViews.Edition(name: "PuddleV1 Edition", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.getpuddle.co")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PuddleV1.CollectionStoragePath, publicPath: PuddleV1.CollectionPublicPath, publicCollection: Type<&PuddleV1.Collection>(), publicLinkedType: Type<&PuddleV1.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PuddleV1.createEmptyCollection(nftType: Type<@PuddleV1.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://puddle-admin-bucket.s3.ap-southeast-1.amazonaws.com/Puddle+white+w+text.png"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "PuddleV1", description: "Puddle is the fastest and easiest way to mint your NFTs on Flow.", externalURL: MetadataViews.ExternalURL("https://www.getpuddle.co"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/getpuddle")})
				case Type<MetadataViews.Traits>():
					// exclude mintedTime to show more data using MetadataViews.Trait
					let excludedTraits = ["mintedTime"]
					// this removes mintedTime from the list of metadata 
					// mintedTime will be repackaged as MetadataViews.Trait below to display more information
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
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
	resource interface PuddleV1CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPuddleV1(id: UInt64): &PuddleV1.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PuddleV1 reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: PuddleV1CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an UInt64 ID field
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
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @PuddleV1.NFT
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
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPuddleV1(id: UInt64): &PuddleV1.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PuddleV1.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let PuddleV1 = nft as! &PuddleV1.NFT
			return PuddleV1 as &{ViewResolver.Resolver}
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
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty]){ 
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			
			// create a new NFT
			var newNFT <- create NFT(id: PuddleV1.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			PuddleV1.totalSupply = PuddleV1.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/PuddleV1Collection
		self.CollectionPublicPath = /public/PuddleV1Collection
		self.MinterStoragePath = /storage/PuddleV1Minter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&PuddleV1.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
