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
contract DigiBuddies: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event DigiBuddiesMinted(id: UInt64, name: String, description: String, image: String, traits:{ String: String})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct DigiBuddiesMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let image: String
		
		access(all)
		let traits:{ String: String}
		
		init(id: UInt64, name: String, description: String, image: String, traits:{ String: String}){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.traits = traits
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		var image: String
		
		access(all)
		let traits:{ String: String}
		
		init(id: UInt64, name: String, description: String, image: String, traits:{ String: String}){ 
			self.id = id
			self.name = name
			self.description = description
			self.image = image
			self.traits = traits
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun revealThumbnail(){ 
			let urlBase = self.image.slice(from: 0, upTo: 47)
			let newImage = urlBase.concat(self.id.toString()).concat(".png")
			self.image = newImage
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<DigiBuddies.DigiBuddiesMetadata>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.image, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://digibuddies.xyz")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DigiBuddies.CollectionStoragePath, publicPath: DigiBuddies.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DigiBuddies.createEmptyCollection(nftType: Type<@DigiBuddies.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://digibuddies.xyz/logo.png"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://digibuddies.xyz/logo.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "DigiBuddies", description: "DigiBuddies Collection", externalURL: MetadataViews.ExternalURL("https://digibuddies.xyz"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/@digibuddiesxyz"), "instagram": MetadataViews.ExternalURL("https://instagram.com/@digibuddies.xyz")})
				case Type<DigiBuddies.DigiBuddiesMetadata>():
					return DigiBuddies.DigiBuddiesMetadata(id: self.id, name: self.name, description: self.description, image: self.image, traits: self.traits)
				case Type<MetadataViews.NFTView>():
					let viewResolver = &self as &{ViewResolver.Resolver}
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: MetadataViews.getDisplay(viewResolver), externalURL: MetadataViews.getExternalURL(viewResolver), collectionData: MetadataViews.getNFTCollectionData(viewResolver), collectionDisplay: MetadataViews.getNFTCollectionDisplay(viewResolver), royalties: MetadataViews.getRoyalties(viewResolver), traits: MetadataViews.getTraits(viewResolver))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					for trait in self.traits.keys{ 
						traits.append(MetadataViews.Trait(name: trait, value: self.traits[trait]!, displayType: nil, rarity: nil))
					}
					return MetadataViews.Traits(traits)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDigiBuddies(id: UInt64): &DigiBuddies.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DigiBuddies reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @DigiBuddies.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mainNFT = nft as! &DigiBuddies.NFT
			return mainNFT
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowDigiBuddies(id: UInt64): &DigiBuddies.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &DigiBuddies.NFT
			} else{ 
				return nil
			}
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteAllNFTs(){ 
			let ids = self.getIDs()
			for id in ids{ 
				let nftToBurn <- self.withdraw(withdrawID: id)
				destroy nftToBurn
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
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, image: String, traits:{ String: String}){ 
			emit DigiBuddiesMinted(id: DigiBuddies.totalSupply, name: name, description: description, image: image, traits: traits)
			DigiBuddies.totalSupply = DigiBuddies.totalSupply + 1 as UInt64
			recipient.deposit(token: <-create DigiBuddies.NFT(id: DigiBuddies.totalSupply, name: name, description: description, image: image, traits: traits))
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun reset(){ 
		self.totalSupply = 0
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DigiBuddiesCollection
		self.CollectionPublicPath = /public/DigiBuddiesCollection
		self.CollectionPrivatePath = /private/DigiBuddiesCollection
		self.AdminStoragePath = /storage/DigiBuddiesMinter
		self.totalSupply = 0
		let minter <- create Admin()
		self.account.storage.save(<-minter, to: self.AdminStoragePath)
		let collection <- DigiBuddies.createEmptyCollection(nftType: Type<@DigiBuddies.Collection>())
		self.account.storage.save(<-collection, to: DigiBuddies.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&DigiBuddies.Collection>(DigiBuddies.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: DigiBuddies.CollectionPublicPath)
		emit ContractInitialized()
	}
}
