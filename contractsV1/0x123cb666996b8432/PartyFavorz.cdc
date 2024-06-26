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

import FindPack from "../0x097bafa4e0b48eef/FindPack.cdc"

import PartyFavorzExtraData from "./PartyFavorzExtraData.cdc"

access(all)
contract PartyFavorz: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, serial: UInt64, season: UInt64, name: String)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let royalties: [MetadataViews.Royalty]
	
	access(all)
	struct Info{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailHash: String
		
		access(all)
		let edition: UInt64
		
		access(all)
		let maxEdition: UInt64
		
		access(all)
		let fullsizeHash: String
		
		access(all)
		let artist: String
		
		init(name: String, description: String, thumbnailHash: String, edition: UInt64, maxEdition: UInt64, fullsizeHash: String, artist: String){ 
			self.name = name
			self.description = description
			self.thumbnailHash = thumbnailHash
			self.edition = edition
			self.maxEdition = maxEdition
			self.fullsizeHash = fullsizeHash
			self.artist = artist
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let info: Info
		
		init(info: Info, season: UInt64, royalties: [MetadataViews.Royalty], squareImage: String, bannerImage: String){ 
			self.id = self.uuid
			self.info = info
			PartyFavorzExtraData.setData(id: self.id, field: "season", value: season)
			PartyFavorzExtraData.setData(id: self.id, field: "royalties", value: royalties)
			PartyFavorzExtraData.setData(id: self.id, field: "nftCollectionDisplay", value:{ "squareImage": squareImage, "bannerImage": bannerImage})
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Medias>(), Type<FindPack.PackRevealData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let imageFile = MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil)
			switch view{ 
				case Type<FindPack.PackRevealData>():
					let data:{ String: String} ={ "nftImage": imageFile.uri(), "nftName": self.info.name, "packType": "PartyFavorz"}
					return FindPack.PackRevealData(data)
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.info.name, description: self.info.description, thumbnail: MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil))
				case Type<MetadataViews.Editions>():
					let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
					var season = 1 as UInt64
					if seasonData != nil{ 
						season = seasonData! as! UInt64
					}
					let editionInfo = MetadataViews.Edition(name: "season ".concat(season.toString()), number: self.info.edition, max: self.info.maxEdition)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Royalties>():
					let royaltiesData = PartyFavorzExtraData.getData(id: self.id, field: "royalties")
					if royaltiesData != nil{ 
						let r = royaltiesData! as! [MetadataViews.Royalty]
						return MetadataViews.Royalties(r)
					}
					return MetadataViews.Royalties(PartyFavorz.royalties)
				case Type<MetadataViews.ExternalURL>():
					if self.owner != nil{ 
						return MetadataViews.ExternalURL("https://find.xyz/".concat((self.owner!).address.toString()).concat("/collection/partyfavorz/").concat(self.id.toString()))
					}
					return MetadataViews.ExternalURL("https://find.xyz/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PartyFavorz.CollectionStoragePath, publicPath: PartyFavorz.CollectionPublicPath, publicCollection: Type<&PartyFavorz.Collection>(), publicLinkedType: Type<&PartyFavorz.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PartyFavorz.createEmptyCollection(nftType: Type<@PartyFavorz.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					var square = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmNkJGEzNYzXsKFqCMweFZBZ9cMQsfMUzV2ZDh2Nn8a1Xc", path: nil), mediaType: "image/png")
					var banner = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "QmVuMpDyJXHMCK9LnFboemWfPYabcwPNEmXgQMWbtxtGWD", path: nil), mediaType: "image/png")
					let nftCollectionDisplayData = PartyFavorzExtraData.getData(id: self.id, field: "nftCollectionDisplay")
					if nftCollectionDisplayData != nil{ 
						let nftCollectionDisplay = nftCollectionDisplayData! as!{ String: String}
						square = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: nftCollectionDisplay["squareImage"]!, path: nil), mediaType: "image/png")
						banner = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: nftCollectionDisplay["bannerImage"]!, path: nil), mediaType: "image/png")
					}
					return MetadataViews.NFTCollectionDisplay(name: "PartyFavorz", description: "By owning a Party Favorz NFT, you are granted access to the VIP sections of our virtual parties which include, but are not limited to major giveaways, 1 on 1s with artists/project leaders, and some IRL utility that involves partying, down the line. By owning Party Favorz, you are supporting the idea of community coming together for a few goals that include having fun, being positive, learning, and most importantly SUPPORTING ARTISTS.", externalURL: MetadataViews.ExternalURL("https://find.xyz/partyfavorz"), squareImage: square, bannerImage: banner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/FlowPartyFavorz"), "discord": MetadataViews.ExternalURL("https://discord.gg/bM76F34EnN")})
				case Type<MetadataViews.Traits>():
					let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
					var season = 1 as UInt64
					if seasonData != nil{ 
						season = seasonData! as! UInt64
					}
					return MetadataViews.Traits([MetadataViews.Trait(name: "Artist", value: self.info.artist, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Season", value: season, displayType: "Numeric", rarity: nil)])
				case Type<MetadataViews.Medias>():
					let seasonData = PartyFavorzExtraData.getData(id: self.id, field: "season")
					var season = 1 as UInt64
					if seasonData != nil{ 
						season = seasonData! as! UInt64
					}
					var thumbnailMediaType = "image/png"
					var fullImageMediaType = "image/png"
					switch season{ 
						case 2 as UInt64:
							fullImageMediaType = "image/gif"
					}
					return MetadataViews.Medias([MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.thumbnailHash, path: nil), mediaType: thumbnailMediaType), MetadataViews.Media(file: MetadataViews.IPFSFile(cid: self.info.fullsizeHash, path: nil), mediaType: fullImageMediaType)])
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
			let token <- token as! @PartyFavorz.NFT
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
			let PartyFavorz = nft as! &PartyFavorz.NFT
			return PartyFavorz as &{ViewResolver.Resolver}
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
			let info = data as?{ String: AnyStruct} ?? panic("The data passed in is not in form as needed.")
			assert(info.length == 5, message: "Please make sure to pass in `Info, season, royalties, squareImage, bannerImage`")
			
			// create a new NFT
			var newNFT <- create NFT(info: info["info"]! as! Info, season: info["season"]! as! UInt64, royalties: info["royalties"]! as! [MetadataViews.Royalty], squareImage: info["squareImage"]! as! String, bannerImage: info["bannerImage"]! as! String)
			PartyFavorz.totalSupply = PartyFavorz.totalSupply + UInt64(1)
			emit Minted(id: newNFT.id, serial: PartyFavorz.totalSupply, season: info["season"]! as! UInt64, name: newNFT.info.name)
			return <-newNFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addContractData(platform: FindForge.MinterPlatform, data: AnyStruct, verifier: &FindForge.Verifier){ 
			// not used here 
			panic("Not supported for PartyFavorz Contract")
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
		self.CollectionStoragePath = /storage/PartyFavorzCollection
		self.CollectionPrivatePath = /private/PartyFavorzCollection
		self.CollectionPublicPath = /public/PartyFavorzCollection
		self.MinterStoragePath = /storage/PartyFavorzMinter
		let partyFavorz = getAccount(0xded455fa967d350e).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		let artist = getAccount(0x34f2bf4a80bb0f69).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
		self.royalties = [MetadataViews.Royalty(receiver: partyFavorz!, cut: 0.03, description: "Party Favorz"), MetadataViews.Royalty(receiver: artist!, cut: 0.02, description: "Artist")]
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&PartyFavorz.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		FindForge.addForgeType(<-create Forge())
		emit ContractInitialized()
	}
}
