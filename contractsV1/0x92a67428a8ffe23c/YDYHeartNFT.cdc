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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract YDYHeartNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var price: UFix64
	
	access(all)
	var isMintingEnabled: Bool
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Bought(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	enum Rarity: UInt8{ 
		access(all)
		case common
		
		access(all)
		case rare
		
		access(all)
		case legendary
		
		access(all)
		case epic
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun rarityToString(_ rarity: Rarity): String{ 
		switch rarity{ 
			case Rarity.common:
				return "Common"
			case Rarity.rare:
				return "Rare"
			case Rarity.legendary:
				return "Legendary"
			case Rarity.epic:
				return "Epic"
		}
		return ""
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun calculateAttribute(_ rarity: Rarity): UInt64{ 
		let commonRange = revertibleRandom<UInt64>() % 5 + 1 // 1-5
		
		let rareRange = revertibleRandom<UInt64>() % 6 + 4 // 4-9
		
		let legendaryRange = revertibleRandom<UInt64>() % 11 + 8 //8-18
		
		let epicRange = revertibleRandom<UInt64>() % 18 + 14 //14-31
		
		switch rarity{ 
			case Rarity.common:
				return commonRange
			case Rarity.rare:
				return rareRange
			case Rarity.legendary:
				return legendaryRange
			case Rarity.epic:
				return epicRange
		}
		return 0
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
		let thumbnailCID: String
		
		access(all)
		let background: String
		
		access(all)
		let body: String
		
		access(all)
		let mouth: String
		
		access(all)
		let eyes: String
		
		access(all)
		let pants: String
		
		access(all)
		let zone: String
		
		access(all)
		var level: UInt64
		
		access(all)
		var lastLeveledUp: UFix64
		
		access(all)
		var stamina: UFix64
		
		access(all)
		var lastStaminaUpdate: UFix64
		
		access(all)
		var endurance: UFix64
		
		access(all)
		var lastEnduranceBoost: UFix64
		
		access(all)
		var efficiency: UFix64
		
		access(all)
		var lastEfficiencyBoost: UFix64
		
		access(all)
		var luck: UFix64
		
		access(all)
		var lastLuckBoost: UFix64
		
		access(all)
		let rarity: String
		
		access(all)
		var version: String
		
		access(all)
		var versionLaunchDate: String
		
		init(thumbnailCID: String, background: String, body: String, mouth: String, eyes: String, pants: String, rarity: Rarity, version: String, versionLaunchDate: String){ 
			YDYHeartNFT.totalSupply = YDYHeartNFT.totalSupply + 1
			self.id = YDYHeartNFT.totalSupply
			self.name = "Heart #".concat(self.id.toString())
			self.description = "YDY Heart NFT #".concat(self.id.toString())
			self.thumbnailCID = thumbnailCID
			self.background = background
			self.body = body
			self.mouth = mouth
			self.eyes = eyes
			self.pants = pants
			self.zone = background
			self.level = 1
			self.lastLeveledUp = getCurrentBlock().timestamp
			self.stamina = 100.0
			self.lastStaminaUpdate = getCurrentBlock().timestamp
			self.endurance = UFix64(YDYHeartNFT.calculateAttribute(rarity))
			self.lastEnduranceBoost = getCurrentBlock().timestamp
			self.efficiency = UFix64(YDYHeartNFT.calculateAttribute(rarity))
			self.lastEfficiencyBoost = getCurrentBlock().timestamp
			self.luck = UFix64(YDYHeartNFT.calculateAttribute(rarity))
			self.lastLuckBoost = getCurrentBlock().timestamp
			self.rarity = YDYHeartNFT.rarityToString(rarity)
			self.version = version
			self.versionLaunchDate = versionLaunchDate
		}
		
		access(contract)
		fun levelUp(){ 
			self.level = self.level + 1
			self.lastLeveledUp = getCurrentBlock().timestamp
		}
		
		access(contract)
		fun repair(_ points: UFix64){ 
			if self.stamina + points > 100.0{ 
				self.stamina = 100.0
			} else{ 
				self.stamina = self.stamina + points
			}
			self.lastStaminaUpdate = getCurrentBlock().timestamp
		}
		
		access(contract)
		fun reduceStamina(_ points: UFix64){ 
			pre{ 
				self.stamina > points:
					"Not enough stamina to reduce by"
			}
			self.stamina = self.stamina - points
			self.lastStaminaUpdate = getCurrentBlock().timestamp
		}
		
		access(contract)
		fun boostEndurance(_ points: UFix64){ 
			self.endurance = self.endurance + points
			self.lastEnduranceBoost = getCurrentBlock().timestamp
		}
		
		access(contract)
		fun boostEfficiency(_ points: UFix64){ 
			self.efficiency = self.efficiency + points
			self.lastEfficiencyBoost = getCurrentBlock().timestamp
		}
		
		access(contract)
		fun boostLuck(_ points: UFix64){ 
			self.luck = self.luck + points
			self.lastLuckBoost = getCurrentBlock().timestamp
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.thumbnailCID, path: "/".concat(self.id.toString()).concat(".png")))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: YDYHeartNFT.CollectionStoragePath, publicPath: YDYHeartNFT.CollectionPublicPath, publicCollection: Type<&YDYHeartNFT.Collection>(), publicLinkedType: Type<&YDYHeartNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-YDYHeartNFT.createEmptyCollection(nftType: Type<@YDYHeartNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "YDY NFT", description: "Collection of YDY NFTs.", externalURL: MetadataViews.ExternalURL("https://www.ydylife.com/"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/ydylife")})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://www.ydylife.com/")
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: getAccount(YDYHeartNFT.account.address).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.075, description: "This is the royalty receiver for YDY NFTs")])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface YDYNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowYDYNFT(id: UInt64): &YDYHeartNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow YDYNFT reference: the ID of the returned reference is incorrect"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}
	}
	
	access(all)
	resource interface YDYNFTCollectionPrivate{ 
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
	}
	
	access(all)
	resource Collection: YDYNFTCollectionPublic, YDYNFTCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @YDYHeartNFT.NFT
			let id: UInt64 = token.id
			emit Deposit(id: id, to: self.owner?.address)
			self.ownedNFTs[id] <-! token
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
		fun borrowYDYNFT(id: UInt64): &YDYHeartNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &YDYHeartNFT.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let ydyNFT = nft as! &YDYHeartNFT.NFT
			return ydyNFT as &{ViewResolver.Resolver}
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
	
	access(TMP_ENTITLEMENT_OWNER)
	fun buy(collectionCapability: Capability<&Collection>, payment: @FlowToken.Vault, quantity: UInt64){ 
		pre{ 
			YDYHeartNFT.isMintingEnabled == true:
				"Minting is not enabled."
			payment.balance == YDYHeartNFT.price * UFix64(quantity):
				"Payment does not match the price."
		}
		let ydyWallet = self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!
		ydyWallet.deposit(from: <-payment)
		let ydyCollection = self.account.capabilities.get<&Collection>(YDYHeartNFT.CollectionPublicPath).borrow<&Collection>() ?? panic("Can't get YDY's collection.")
		let availableNFTs = ydyCollection.getIDs()
		if availableNFTs.length > 0{ 
			let receiver = collectionCapability.borrow() ?? panic("Cannot borrow")
			let randomInt = revertibleRandom<UInt64>() % UInt64(availableNFTs.length)
			let id = availableNFTs[randomInt]
			let token <- ydyCollection.withdraw(withdrawID: id) as! @YDYHeartNFT.NFT
			emit Bought(id: id, to: receiver.owner?.address)
			receiver.deposit(token: <-token)
		} else{ 
			panic("No NFTs available.")
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(thumbnailCID: String, background: String, body: String, mouth: String, eyes: String, pants: String, rarity: Rarity, version: String, versionLaunchDate: String){ 
			let accountOwnerCollection = YDYHeartNFT.account.storage.borrow<&Collection>(from: YDYHeartNFT.CollectionStoragePath)!
			accountOwnerCollection.deposit(token: <-create YDYHeartNFT.NFT(thumbnailCID: thumbnailCID, background: background, body: body, mouth: mouth, eyes: eyes, pants: pants, rarity: rarity, version: version, versionLaunchDate: versionLaunchDate))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun transferNFT(collectionCapability: Capability<&Collection>): UInt64{ 
			let ydyCollection = YDYHeartNFT.account.capabilities.get<&Collection>(YDYHeartNFT.CollectionPublicPath).borrow<&Collection>() ?? panic("Can't get YDY's collection.")
			let availableNFTs = ydyCollection.getIDs()
			if availableNFTs.length > 0{ 
				let receiver = collectionCapability.borrow() ?? panic("Cannot borrow")
				let randomInt = revertibleRandom<UInt64>() % UInt64(availableNFTs.length)
				let id = availableNFTs[randomInt]
				let token <- ydyCollection.withdraw(withdrawID: id) as! @YDYHeartNFT.NFT
				receiver.deposit(token: <-token)
				return id
			} else{ 
				panic("No NFTs available.")
			}
			return 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun levelUp(id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			post{ 
				nft.level == beforeLevel + 1:
					"The level must be increased by 1"
			}
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			let beforeLevel = nft.level
			nft.levelUp()
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun repair(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			let beforeStamina = nft.stamina
			nft.repair(points)
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reduceStamina(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			post{ 
				nft.stamina == beforeStamina - points:
					"The stamina must be reduced by the points"
			}
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			let beforeStamina = nft.stamina
			nft.reduceStamina(points)
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun boostEndurance(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			nft.boostEndurance(points)
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun boostEfficiency(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			nft.boostEfficiency(points)
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun boostLuck(points: UFix64, id: UInt64, recipientCollectionCapability: Capability<&Collection>): &YDYHeartNFT.NFT?{ 
			let receiver = recipientCollectionCapability.borrow() ?? panic("Cannot borrow")
			let nft = receiver.borrowYDYNFT(id: id) ?? panic("No NFT with this ID exists for user")
			nft.boostLuck(points)
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(price: UFix64){ 
			YDYHeartNFT.price = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeIsMintingEnabled(isMinting: Bool){ 
			YDYHeartNFT.isMintingEnabled = isMinting
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.price = 100.0
		self.isMintingEnabled = false
		self.CollectionStoragePath = /storage/YDYHeartNFTCollection
		self.CollectionPublicPath = /public/YDYHeartNFTCollection
		self.AdminStoragePath = /storage/YDYHeartNFTAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
