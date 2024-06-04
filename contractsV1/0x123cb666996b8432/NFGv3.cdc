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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FindForge from "../0x097bafa4e0b48eef/FindForge.cdc"

access(all)
contract NFGv3: NonFungibleToken{ 
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
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	struct Info{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let externalURL: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let levels:{ String: UFix64}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let traits:{ String: String}
		
		access(all)
		let birthday: UFix64
		
		access(all)
		let medias:{ String: String}
		
		init(name: String, description: String, thumbnailHash: String, edition: UInt64, maxEdition: UInt64, externalURL: String, traits:{ String: String}, levels:{ String: UFix64}, scalars:{ String: UFix64}, birthday: UFix64, medias:{ String: String}){ 
			self.name = name
			self.description = description
			self.thumbnailHash = thumbnailHash
			self.edition = edition
			self.maxEdition = maxEdition
			self.traits = traits
			self.levels = levels
			self.scalars = scalars
			self.birthday = birthday
			self.externalURL = externalURL
			self.medias = medias
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let info: Info
		
		access(self)
		let royalties: MetadataViews.Royalties
		
		init(info: Info, royalties: MetadataViews.Royalties){ 
			self.id = self.uuid
			self.info = info
			self.royalties = royalties
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Traits>():
					let traits = MetadataViews.Traits([MetadataViews.Trait(name: "Birthday", value: self.info.birthday, displayType: "date", rarity: nil)])
					for value in self.info.traits.keys{ 
						traits.addTrait(MetadataViews.Trait(name: value, value: self.info.traits[value], displayType: "String", rarity: nil))
					}
					for value in self.info.scalars.keys{ 
						traits.addTrait(MetadataViews.Trait(name: value, value: self.info.scalars[value], displayType: "Number", rarity: nil))
					}
					for value in self.info.levels.keys{ 
						traits.addTrait(MetadataViews.Trait(name: value, value: self.info.levels[value], displayType: "Number", rarity: MetadataViews.Rarity(score: self.info.levels[value], max: 100.0, description: nil)))
					}
					return traits
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.info.name, description: self.info.description, thumbnail: MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "set", number: self.info.edition, max: self.info.maxEdition)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Royalties>():
					return self.royalties
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL(self.info.externalURL)
				case Type<MetadataViews.Medias>():
					let mediaList: [MetadataViews.Media] = []
					for hash in self.info.medias.keys{ 
						let mediaType = self.info.medias[hash]!
						let file = MetadataViews.IPFSFile(cid: hash, path: nil)
						let m: MetadataViews.Media = MetadataViews.Media(file: file, mediaType: mediaType)
						mediaList.append(m)
					}
					return MetadataViews.Medias(mediaList)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: NFGv3.CollectionStoragePath, publicPath: NFGv3.CollectionPublicPath, publicCollection: Type<&NFGv3.Collection>(), publicLinkedType: Type<&NFGv3.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-NFGv3.createEmptyCollection(nftType: Type<@NFGv3.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let square = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmeG1rPaLWmn4uUSjQ2Wbs7QnjxdQDyeadCGWyGwvHTB7c", path: nil), mediaType: "image/png")
					let banner = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmWmDRnSrv8HK5QsiHwUNR4akK95WC8veydq6dnnFbMja1", path: nil), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "NonFunGerbils", description: "The NonFunGerbils are a collaboration between the NonFunGerbils Podcast, their audience and sometimes fabolous artists. Harnessing the power of MEMEs with creative writing and collaboration they create the most dankest, cutest gerbils in the NFT space.", externalURL: MetadataViews.ExternalURL("https://nonfungerbils.com"), squareImage: square, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/NonFunGerbils")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
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
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @NFGv3.NFT
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
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nfgNFT = nft as! &NFGv3.NFT
			return nfgNFT as &{ViewResolver.Resolver}
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
	
	access(all)
	resource Forge: FindForge.Forge{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier): @{NonFungibleToken.NFT}{ 
			let info = data as? Info ?? panic("The data passed in is not in form of NFGv3Info.")
			let royalties: [MetadataViews.Royalty] = []
			royalties.append(MetadataViews.Royalty(receiver: platform.platform, cut: platform.platformPercentCut, description: "find forge"))
			if platform.minterCut != nil{ 
				royalties.append(MetadataViews.Royalty(receiver: platform.getMinterFTReceiver(), cut: platform.minterCut!, description: "creator"))
			}
			
			// create a new NFT
			var newNFT <- create NFT(info: info, royalties: MetadataViews.Royalties(royalties))
			NFGv3.totalSupply = NFGv3.totalSupply + UInt64(1)
			return <-newNFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier){ 
			// not used here 
			panic("Not supported for NFGv3 Contract")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getForgeType(): Type{ 
		return Type<@Forge>()
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/nfgNFTCollection
		self.CollectionPrivatePath = /private/nfgNFTCollection
		self.CollectionPublicPath = /public/nfgNFTCollection
		self.MinterStoragePath = /storage/nfgNFTMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&NFGv3.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		FindForge.addForgeType(<-create Forge())
		emit ContractInitialized()
	}
}
