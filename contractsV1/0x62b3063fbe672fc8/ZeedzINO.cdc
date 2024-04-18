import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

/*
	Description: Central Smart Contract for the first generation of Zeedle NFTs

	Zeedles are cute little nature-inspired monsters that grow with the real world weather.
	They are the main characters of Zeedz, the first play-for-purpose game where players 
	reduce global carbon emissions by growing Zeedles. 
	
	This smart contract encompasses the main functionality for the first generation
	of Zeedle NFTs. 

	Oriented much on the standard NFT contract, each Zeedle NFT has a certain typeID,
	which is the type of Zeedle - e.g. "Baby Aloe Vera" or "Ginger Biggy". A contract-level
	dictionary takes account of the different quentities that have been minted per Zeedle type.

	Different types also imply different rarities, and these are also hardcoded inside 
	the given Zeedle NFT in order to allow the direct querying of the Zeedle's rarity 
	in external applications and wallets.

	Each batch-minting of Zeedles is resembled by an edition number, with the community pre-sale 
	being the first-ever edition (0). This way, each Zeedle can be traced back to the edition it
	was created in, and the number of minted Zeedles of that type in the specific edition.

	Many of the in-game purchases lead to real-world donations to NGOs focused on climate action. 
	The carbonOffset attribute of a Zeedle proves the impact the in-game purchases related to this Zeedle
	have already made with regards to reducing greenhouse gases. This value is computed by taking the 
	current dollar-value of each purchase at the time of the purchase, and applying the dollar-to-CO2-offset
	formular of the current climate action partner. 
*/

access(all)
contract ZeedzINO: NonFungibleToken{ 
	
	//  Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, name: String, description: String, typeID: UInt32, serialNumber: String, edition: UInt32, rarity: String)
	
	access(all)
	event Evolved(oldID: UInt64, newID: UInt64, name: String, description: String, typeID: UInt32, serialNumber: String, edition: UInt32, rarity: String, carbonOffset: UInt64)
	
	access(all)
	event Burned(id: UInt64, from: Address?)
	
	access(all)
	event Offset(id: UInt64, amount: UInt64)
	
	access(all)
	event Redeemed(id: UInt64, message: String, from: Address?)
	
	//  Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	var numberMintedPerType:{ UInt32: UInt64}
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		//  The token's ID
		access(all)
		let id: UInt64
		
		//  The memorable short name for the Zeedle, e.g. “Baby Aloe"
		access(all)
		let name: String
		
		//  A short description of the Zeedle's type
		access(all)
		let description: String
		
		//  Number id of the Zeedle type -> e.g "1 = Ginger Biggy, 2 = Baby Aloe, etc”
		access(all)
		let typeID: UInt32
		
		//  A Zeedle's unique serial number from the Zeedle's edition 
		access(all)
		let serialNumber: String
		
		//  Number id of the Zeedle's edition -> e.g "1 = first edition, 2 = second edition, etc"  
		access(all)
		let edition: UInt32
		
		//  The total number of Zeedle's minted in this edition
		access(all)
		let editionCap: UInt32
		
		//  The Zeedle's evolutionary stage 
		access(all)
		let evolutionStage: UInt32
		
		//  The Zeedle's rarity -> e.g "RARE, COMMON, LEGENDARY, etc" 
		access(all)
		let rarity: String
		
		//  URI to the image of the Zeedle 
		access(all)
		let imageURI: String
		
		//  The total amount this Zeedle has contributed to offsetting CO2 emissions
		access(all)
		var carbonOffset: UInt64
		
		init(initID: UInt64, initName: String, initDescription: String, initTypeID: UInt32, initSerialNumber: String, initEdition: UInt32, initEditionCap: UInt32, initEvolutionStage: UInt32, initRarity: String, initImageURI: String, initCarbonOffset: UInt64){ 
			self.id = initID
			self.name = initName
			self.description = initDescription
			self.typeID = initTypeID
			self.serialNumber = initSerialNumber
			self.edition = initEdition
			self.editionCap = initEditionCap
			self.evolutionStage = initEvolutionStage
			self.rarity = initRarity
			self.imageURI = initImageURI
			self.carbonOffset = initCarbonOffset
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Rarity>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.IPFSFile(cid: self.imageURI, path: nil))
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://play.zeedz.io/")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: ZeedzINO.CollectionStoragePath, publicPath: ZeedzINO.CollectionPublicPath, publicCollection: Type<&ZeedzINO.Collection>(), publicLinkedType: Type<&ZeedzINO.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-ZeedzINO.createEmptyCollection(nftType: Type<@ZeedzINO.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://play.zeedz.io/logo-zeedz.svg"), mediaType: "image/svg+xml")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://play.zeedz.io/background-zeedz.jpg"), mediaType: "image/png")
					let socials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/zeedz_official"), "discord": MetadataViews.ExternalURL("http://discord.com/invite/zeedz"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/zeedz"), "medium": MetadataViews.ExternalURL("https://blog.zeedz.io/"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/zeedz_official/"), "youtube": MetadataViews.ExternalURL("https://www.youtube.com/c/zeedz_official")}
					return MetadataViews.NFTCollectionDisplay(name: "Zeedz", description: "Zeedz is the first play-for-purpose game where players reduce global carbon emissions by collecting plant-inspired creatures: Zeedles. They live as NFTs on an eco-friendly blockchain (Flow) and grow with the real-world weather.", externalURL: MetadataViews.ExternalURL("https://play.zeedz.io"), squareImage: mediaSquare, bannerImage: mediaBanner, socials: socials)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.Traits>():
					let editionTrait = MetadataViews.Trait(name: "edition number", value: self.edition, displayType: nil, rarity: nil)
					let editionCapTrait = MetadataViews.Trait(name: "total minted in edition", value: self.editionCap, displayType: nil, rarity: nil)
					let serialNumberTrait = MetadataViews.Trait(name: "serial number", value: self.serialNumber, displayType: nil, rarity: nil)
					let evolutionStageTrait = MetadataViews.Trait(name: "evolution stage", value: self.evolutionStage, displayType: nil, rarity: nil)
					let carbonOffsetTrait = MetadataViews.Trait(name: "carbon offset", value: self.carbonOffset, displayType: nil, rarity: nil)
					return MetadataViews.Traits([editionTrait, editionCapTrait, serialNumberTrait, evolutionStageTrait, carbonOffsetTrait])
				case Type<MetadataViews.Rarity>():
					var rarityScore = 0.0
					let maxRarityScore = 5.0
					switch self.rarity{ 
						case "COMMON":
							rarityScore = 1.0
						case "RARE":
							rarityScore = 2.0
						case "EPIC":
							rarityScore = 3.0
						case "LEGENDARY":
							rarityScore = 4.0
						case "CUSTOM":
							rarityScore = 5.0
						default:
							rarityScore = 0.0
					}
					return MetadataViews.Rarity(score: rarityScore, max: maxRarityScore, description: self.rarity)
			}
			return nil
		}
		
		access(all)
		fun getMetadata():{ String: AnyStruct}{ 
			return{ "id": self.id, "name": self.name, "description": self.description, "typeID": self.typeID, "serialNumber": self.serialNumber, "edition": self.edition, "editionCap": self.editionCap, "evolutionStage": self.evolutionStage, "rarity": self.rarity, "imageURI": self.imageURI, "carbonOffset": self.carbonOffset}
		}
		
		access(contract)
		fun increaseOffset(amount: UInt64){ 
			self.carbonOffset = self.carbonOffset + amount
		}
		
		access(contract)
		fun changeOffset(offset: UInt64){ 
			self.carbonOffset = offset
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// 
	//  This is the interface that users can cast their Zeedz Collection as
	//  to allow others to deposit Zeedles into their Collection. It also allows for reading
	//  the details of Zeedles in the Collection.
	// 
	access(all)
	resource interface ZeedzCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowZeedle(id: UInt64): &ZeedzINO.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Zeedle reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(contract)
		fun retrieve(id: UInt64): @{NonFungibleToken.NFT}
	}
	
	// 
	//  This is the interface that users can cast their Zeedz Collection as
	//  to allow themselves to call the burn function on their own collection.
	// 
	access(all)
	resource interface ZeedzCollectionPrivate{ 
		access(all)
		fun burn(burnID: UInt64)
		
		access(all)
		fun redeem(redeemID: UInt64, message: String)
	}
	
	//
	//  A collection of Zeedz NFTs owned by an account.
	//   
	access(all)
	resource Collection: ZeedzCollectionPublic, ZeedzCollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Not able to find specified NFT within the owner's collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun burn(burnID: UInt64){ 
			let token <- self.ownedNFTs.remove(key: burnID) ?? panic("Not able to find specified NFT within the owner's collection")
			let zeedle <- token as! @ZeedzINO.NFT
			
			//  reduce numberOfMinterPerType
			ZeedzINO.numberMintedPerType[zeedle.typeID] = ZeedzINO.numberMintedPerType[zeedle.typeID]! - 1 as UInt64
			destroy zeedle
			emit Burned(id: burnID, from: self.owner?.address)
		}
		
		access(all)
		fun redeem(redeemID: UInt64, message: String){ 
			let token <- self.ownedNFTs.remove(key: redeemID) ?? panic("Not able to find specified NFT within the owner's collection")
			let zeedle <- token as! @ZeedzINO.NFT
			
			//  reduce numberOfMinterPerType
			ZeedzINO.numberMintedPerType[zeedle.typeID] = ZeedzINO.numberMintedPerType[zeedle.typeID]! - 1 as UInt64
			destroy zeedle
			emit Redeemed(id: redeemID, message: message, from: self.owner?.address)
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @ZeedzINO.NFT
			let id: UInt64 = token.id
			//  add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		//
		//  Returns an array of the IDs that are in the collection.
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		//
		//  Gets a reference to an NFT in the collection
		//  so that the caller can read its metadata and call its methods.
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		//
		//  Gets a reference to an NFT in the collection as a Zeed,
		//  exposing all of its fields
		//  this is safe as there are no functions that can be called on the Zeed.
		//
		access(all)
		fun borrowZeedle(id: UInt64): &ZeedzINO.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &ZeedzINO.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let zeedzINO = nft as! &ZeedzINO.NFT
			return zeedzINO as &{ViewResolver.Resolver}
		}
		
		access(contract)
		fun retrieve(id: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("Not able to find specified NFT within the owner's collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	//
	//  Public function that anyone can call to create a new empty collection.
	// 
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//
	//  The Administrator resource that an Administrator or something similar 
	//  would own to be able to mint & level-up NFT's.
	//
	access(all)
	resource Administrator{ 
		
		//
		//  Mints a new NFT with a new ID
		//  and deposit it in the recipients collection using their collection reference.
		//
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, typeID: UInt32, serialNumber: String, edition: UInt32, editionCap: UInt32, evolutionStage: UInt32, rarity: String, imageURI: String){ 
			recipient.deposit(token: <-create ZeedzINO.NFT(initID: ZeedzINO.totalSupply, initName: name, initDescription: description, initTypeID: typeID, initSerialNumber: serialNumber, initEdition: edition, initEditionCap: editionCap, initEvolutionStage: evolutionStage, initRarity: rarity, initImageURI: imageURI, initCarbonOffset: 0))
			emit Minted(id: ZeedzINO.totalSupply, name: name, description: description, typeID: typeID, serialNumber: serialNumber, edition: edition, rarity: rarity)
			
			// increase numberOfMinterPerType and totalSupply
			ZeedzINO.totalSupply = ZeedzINO.totalSupply + 1 as UInt64
			if ZeedzINO.numberMintedPerType[typeID] == nil{ 
				ZeedzINO.numberMintedPerType[typeID] = 1
			} else{ 
				ZeedzINO.numberMintedPerType[typeID] = ZeedzINO.numberMintedPerType[typeID]! + 1 as UInt64
			}
		}
		
		//
		//  Increase the Zeedle's total carbon offset by the given amount
		//
		access(all)
		fun increaseOffset(zeedleRef: &ZeedzINO.NFT, amount: UInt64){ 
			zeedleRef.increaseOffset(amount: amount)
			emit Offset(id: zeedleRef.id, amount: zeedleRef.carbonOffset)
		}
		
		//
		//  Retrieve an NFT from an account's collection
		//
		access(all)
		fun retrieveNFT(from: &{ZeedzINO.ZeedzCollectionPublic}, id: UInt64): @{NonFungibleToken.NFT}{ 
			return <-from.retrieve(id: id)
		}
		
		//
		//  Change the Zeedle's total carbon offset to the given amount
		//
		access(all)
		fun changeOffset(zeedleRef: &ZeedzINO.NFT, offset: UInt64){ 
			zeedleRef.changeOffset(offset: offset)
			emit Offset(id: zeedleRef.id, amount: offset)
		}
		
		access(all)
		fun evolve(zeedle: @ZeedzINO.NFT?, nextEvolutionMetadata:{ String: String}): @ZeedzINO.NFT{ 
			let evolvedZeedle <- create ZeedzINO.NFT(initID: ZeedzINO.totalSupply, initName: nextEvolutionMetadata["name"]!, initDescription: nextEvolutionMetadata["description"]!, initTypeID: UInt32.fromString(nextEvolutionMetadata["typeID"]!)!, initSerialNumber: zeedle?.serialNumber != nil ? zeedle?.serialNumber! : nextEvolutionMetadata["serialNumber"]!, initEdition: zeedle?.edition != nil ? zeedle?.edition! : 99, initEditionCap: zeedle?.editionCap != nil ? zeedle?.editionCap! : 0, initEvolutionStage: UInt32.fromString(nextEvolutionMetadata["evolutionStage"]!)!, initRarity: nextEvolutionMetadata["rarity"]!, initImageURI: nextEvolutionMetadata["imageURI"]!, initCarbonOffset: zeedle?.carbonOffset != nil ? zeedle?.carbonOffset! : 0)
			
			// increase numberOfMinterPerType and totalSupply
			ZeedzINO.totalSupply = ZeedzINO.totalSupply + 1 as UInt64
			if ZeedzINO.numberMintedPerType[evolvedZeedle.typeID] == nil{ 
				ZeedzINO.numberMintedPerType[evolvedZeedle.typeID] = 1
			} else{ 
				ZeedzINO.numberMintedPerType[evolvedZeedle.typeID] = ZeedzINO.numberMintedPerType[evolvedZeedle.typeID]! + 1 as UInt64
			}
			emit Evolved(oldID: zeedle?.id != nil ? zeedle?.id! : 0, newID: evolvedZeedle.id, name: evolvedZeedle.name, description: evolvedZeedle.description, typeID: evolvedZeedle.typeID, serialNumber: evolvedZeedle.serialNumber, edition: evolvedZeedle.edition, rarity: evolvedZeedle.rarity, carbonOffset: evolvedZeedle.carbonOffset)
			destroy zeedle
			return <-evolvedZeedle
		}
	}
	
	//
	//  Get a reference to a Zeedle from an account's Collection, if available.
	//  If an account does not have a Zeedz.Collection, panic.
	//  If it has a collection but does not contain the zeedleId, return nil.
	//  If it has a collection and that collection contains the zeedleId, return a reference to that.
	//
	access(all)
	fun fetch(_ from: Address, zeedleID: UInt64): &ZeedzINO.NFT?{ 
		let capability = getAccount(from).capabilities.get<&ZeedzINO.Collection>(ZeedzINO.CollectionPublicPath)!
		if capability.check(){ 
			let collection = capability.borrow()
			return (collection!).borrowZeedle(id: zeedleID)
		} else{ 
			return nil
		}
	}
	
	// 
	//  Returns the number of minted Zeedles for each Zeedle type.
	//
	access(all)
	fun getMintedPerType():{ UInt32: UInt64}{ 
		return self.numberMintedPerType
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/ZeedzINOCollection
		self.CollectionPublicPath = /public/ZeedzINOCollection
		self.AdminStoragePath = /storage/ZeedzINOMinter
		self.AdminPrivatePath = /private/ZeedzINOAdminPrivate
		self.totalSupply = 0
		self.numberMintedPerType ={} 
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
