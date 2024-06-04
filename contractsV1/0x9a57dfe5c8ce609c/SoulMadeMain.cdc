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

import SoulMadeComponent from "./SoulMadeComponent.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract SoulMadeMain: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event SoulMadeMainCollectionCreated()
	
	access(all)
	event SoulMadeMainCreated(id: UInt64, series: String)
	
	access(all)
	event NameSet(id: UInt64, name: String)
	
	access(all)
	event DescriptionSet(id: UInt64, description: String)
	
	access(all)
	event IpfsHashSet(id: UInt64, ipfsHash: String)
	
	access(all)
	event MainComponentUpdated(mainNftId: UInt64)
	
	access(all)
	struct MainDetail{ 
		access(all)
		let id: UInt64
		
		access(all)
		var name: String
		
		access(all)
		let series: String
		
		access(all)
		var description: String
		
		access(all)
		var ipfsHash: String
		
		access(all)
		var componentDetails: [SoulMadeComponent.ComponentDetail]
		
		init(id: UInt64, name: String, series: String, description: String, ipfsHash: String, componentDetails: [SoulMadeComponent.ComponentDetail]){ 
			self.id = id
			self.name = name
			self.series = series
			self.description = description
			self.ipfsHash = ipfsHash
			self.componentDetails = componentDetails
		}
	}
	
	access(all)
	resource interface MainPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mainDetail: MainDetail
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllComponentDetail():{ String: SoulMadeComponent.ComponentDetail}
	}
	
	access(all)
	resource interface MainPrivate{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setName(_ name: String): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ description: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIpfsHash(_ ipfsHash: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawComponent(category: String): @SoulMadeComponent.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositComponent(componentNft: @SoulMadeComponent.NFT): @SoulMadeComponent.NFT?
	}
	
	access(all)
	resource NFT: MainPublic, MainPrivate, NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let mainDetail: MainDetail
		
		access(self)
		var components: @{String: SoulMadeComponent.NFT}
		
		init(id: UInt64, series: String){ 
			self.id = id
			self.mainDetail = MainDetail(id: id, name: "", series: series, description: "", ipfsHash: "", componentDetails: [])
			self.components <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllComponentDetail():{ String: SoulMadeComponent.ComponentDetail}{ 
			var info:{ String: SoulMadeComponent.ComponentDetail} ={} 
			for categoryKey in self.components.keys{ 
				let componentRef = (&self.components[categoryKey] as &SoulMadeComponent.NFT?)!
				let detail = componentRef.componentDetail
				info[categoryKey] = detail
			}
			return info
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawComponent(category: String): @SoulMadeComponent.NFT{ 
			let componentNft <- self.components.remove(key: category)!
			self.mainDetail.componentDetails = self.getAllComponentDetail().values
			emit MainComponentUpdated(mainNftId: self.id)
			return <-componentNft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositComponent(componentNft: @SoulMadeComponent.NFT): @SoulMadeComponent.NFT?{ 
			let category: String = componentNft.componentDetail.category
			var old <- self.components[category] <- componentNft
			self.mainDetail.componentDetails = self.getAllComponentDetail().values
			emit MainComponentUpdated(mainNftId: self.id)
			return <-old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setName(_ name: String){ 
			pre{ 
				name.length > 2:
					"The name is too short"
				name.length < 100:
					"The name is too long"
			}
			self.mainDetail.name = name
			emit NameSet(id: self.id, name: name)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setDescription(_ description: String){ 
			pre{ 
				description.length > 2:
					"The descripton is too short"
				description.length < 500:
					"The description is too long"
			}
			self.mainDetail.description = description
			emit DescriptionSet(id: self.id, description: description)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIpfsHash(_ ipfsHash: String){ 
			self.mainDetail.ipfsHash = ipfsHash
			emit IpfsHashSet(id: self.id, ipfsHash: ipfsHash)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.mainDetail.name, description: self.mainDetail.description, thumbnail: MetadataViews.IPFSFile(cid: self.mainDetail.ipfsHash, path: nil))
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(0x9a57dfe5c8ce609c).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.00, description: "SoulMade Main Royalties")])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://soulmade.art")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: SoulMadeMain.CollectionStoragePath, publicPath: SoulMadeMain.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-SoulMadeMain.createEmptyCollection(nftType: Type<@SoulMadeMain.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/XgqDY3s.jpg"), mediaType: "image")
					let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://i.imgur.com/yBw3ktk.png"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "SoulMadeMain", description: "SoulMade Main Collection", externalURL: MetadataViews.ExternalURL("https://soulmade.art"), squareImage: squareMedia, bannerImage: bannerMedia, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/soulmade_nft"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/xtqqXCKW9B")})
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
		fun borrowMain(id: UInt64): &{SoulMadeMain.MainPublic}
	}
	
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Main NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @SoulMadeMain.NFT
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
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMain(id: UInt64): &{SoulMadeMain.MainPublic}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Main NFT doesn't exist"
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &SoulMadeMain.NFT
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMainPrivate(id: UInt64): &{SoulMadeMain.MainPrivate}{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Main NFT doesn't exist"
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &SoulMadeMain.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mainNFT = nft as! &SoulMadeMain.NFT
			return mainNFT as &{ViewResolver.Resolver}
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
		emit SoulMadeMainCollectionCreated()
		return <-create Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintMain(series: String): @NFT{ 
		var new <- create NFT(id: SoulMadeMain.totalSupply, series: series)
		emit SoulMadeMainCreated(id: SoulMadeMain.totalSupply, series: series)
		SoulMadeMain.totalSupply = SoulMadeMain.totalSupply + 1
		return <-new
	}
	
	init(){ 
		self.totalSupply = 0
		self.CollectionPublicPath = /public/SoulMadeMainCollection
		self.CollectionStoragePath = /storage/SoulMadeMainCollection
		self.CollectionPrivatePath = /private/SoulMadeMainCollection
		emit ContractInitialized()
	}
}
