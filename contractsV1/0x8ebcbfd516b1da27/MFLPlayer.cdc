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

import MFLViews from "./MFLViews.cdc"

import MFLAdmin from "./MFLAdmin.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint players (NFTs). A player has metadata
  that can be updated by an admin.
**/

access(all)
contract MFLPlayer: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Updated(id: UInt64)
	
	access(all)
	event Destroyed(id: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let PlayerAdminStoragePath: StoragePath
	
	// The total number of Players that have been minted
	access(all)
	var totalSupply: UInt64
	
	// All players datas are stored in this dictionary
	access(self)
	let playersDatas:{ UInt64: PlayerData}
	
	// Data stored in playersdatas. Updatable by an admin
	access(all)
	struct PlayerData{ 
		access(all)
		let id: UInt64
		
		access(contract)
		let metadata:{ String: AnyStruct}
		
		access(all)
		let season: UInt32
		
		access(all)
		let image:{ MetadataViews.File}
		
		init(id: UInt64, metadata:{ String: AnyStruct}, season: UInt32, image:{ MetadataViews.File}){ 
			self.id = id
			self.metadata = metadata
			self.season = season
			self.image = image
		}
	}
	
	// The resource that represents the Player NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// The unique ID for the Player
		access(all)
		let id: UInt64
		
		access(all)
		let season: UInt32
		
		access(all)
		let image:{ MetadataViews.File}
		
		init(id: UInt64, season: UInt32, image:{ MetadataViews.File}){ 
			self.id = id
			// Increment the totalSupply so that id it isn't used again
			MFLPlayer.totalSupply = MFLPlayer.totalSupply + 1 as UInt64
			self.season = season
			self.image = image
			emit Minted(id: self.id)
		}
		
		// Get all supported views for this NFT
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Serial>(), Type<MFLViews.PlayerDataViewV1>()]
		}
		
		// Resolve a specific view
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let playerData = MFLPlayer.getPlayerData(id: self.id)!
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: playerData.metadata["name"] as! String? ?? "", description: "MFL Player #".concat(playerData.id.toString()), thumbnail: playerData.image)
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					let royaltyReceiverCap = getAccount(MFLAdmin.royaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
					royalties.append(MetadataViews.Royalty(receiver: royaltyReceiverCap!, cut: 0.05, description: "Creator Royalty"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let socials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"), "discord": MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"), "medium": MetadataViews.ExternalURL("https://medium.com/playmfl")}
					return MetadataViews.NFTCollectionDisplay(name: "MFL Player Collection", description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you\u{2019}ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you\u{2019}ll be able to : Be a recruiter (Scout, find, and trade players\u{2026}), be an agent (Find the best clubs for your players, negotiate contracts with club owners\u{2026}), be a club owner (Develop your club, recruit players, compete in leagues and tournaments\u{2026}) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Players.", externalURL: MetadataViews.ExternalURL("https://playmfl.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"), socials: socials)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MFLPlayer.CollectionStoragePath, publicPath: MFLPlayer.CollectionPublicPath, publicCollection: Type<&MFLPlayer.Collection>(), publicLinkedType: Type<&MFLPlayer.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MFLPlayer.createEmptyCollection(nftType: Type<@MFLPlayer.Collection>())
						})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://playmfl.com")
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					traits.append(MetadataViews.Trait(name: "name", value: playerData.metadata["name"] as! String?, displayType: "String", rarity: nil))
					let nationalitiesOptional = playerData.metadata["nationalities"] as! [String]?
					var nationalitiesString: String = ""
					if let nationalities = nationalitiesOptional{ 
						for nationality in nationalities{ 
							if nationalitiesString.length > 0{ 
								nationalitiesString = nationalitiesString.concat(", ")
							}
							nationalitiesString = nationalitiesString.concat(nationality)
						}
					}
					traits.append(MetadataViews.Trait(name: "nationalities", value: nationalitiesString, displayType: "String", rarity: nil))
					var positionsString: String = ""
					if let positions = playerData.metadata["positions"] as! [String]?{ 
						for position in positions{ 
							if positionsString.length > 0{ 
								positionsString = positionsString.concat(", ")
							}
							positionsString = positionsString.concat(position)
						}
					}
					traits.append(MetadataViews.Trait(name: "positions", value: positionsString, displayType: "String", rarity: nil))
					traits.append(MetadataViews.Trait(name: "preferredFoot", value: playerData.metadata["preferredFoot"] as! String?, displayType: "String", rarity: nil))
					traits.append(MetadataViews.Trait(name: "ageAtMint", value: playerData.metadata["ageAtMint"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "height", value: playerData.metadata["height"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "overall", value: playerData.metadata["overall"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "pace", value: playerData.metadata["pace"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "shooting", value: playerData.metadata["shooting"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "passing", value: playerData.metadata["passing"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "dribbling", value: playerData.metadata["dribbling"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "defense", value: playerData.metadata["defense"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "physical", value: playerData.metadata["physical"] as! UInt32?, displayType: "Number", rarity: nil))
					traits.append(MetadataViews.Trait(name: "goalkeeping", value: playerData.metadata["goalkeeping"] as! UInt32?, displayType: "Number", rarity: nil))
					return MetadataViews.Traits(traits)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(playerData.id)
				case Type<MFLViews.PlayerDataViewV1>():
					return MFLViews.PlayerDataViewV1(id: playerData.id, metadata: playerData.metadata, season: playerData.season, thumbnail: playerData.image)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// A collection of Player NFTs owned by an account
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary of NFT conforming tokens
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Withdraws multiple Players and returns them as a Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @MFLPlayer.NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let playerNFT = nft as! &MFLPlayer.NFT
			return playerNFT as &{ViewResolver.Resolver}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Get data for a specific player ID
	access(TMP_ENTITLEMENT_OWNER)
	view fun getPlayerData(id: UInt64): PlayerData?{ 
		return self.playersDatas[id]
	}
	
	// This interface allows any account that has a private capability to a PlayerAdminClaim to call the methods below
	access(all)
	resource interface PlayerAdminClaim{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPlayer(id: UInt64, metadata:{ String: AnyStruct}, season: UInt32, image:{ MetadataViews.File}): @MFLPlayer.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePlayerMetadata(id: UInt64, metadata:{ String: AnyStruct})
	}
	
	access(all)
	resource PlayerAdmin: PlayerAdminClaim{ 
		access(all)
		let name: String
		
		init(){ 
			self.name = "PlayerAdminClaim"
		}
		
		// Mint a new Player and returns it
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPlayer(id: UInt64, metadata:{ String: AnyStruct}, season: UInt32, image:{ MetadataViews.File}): @MFLPlayer.NFT{ 
			pre{ 
				MFLPlayer.getPlayerData(id: id) == nil:
					"Player already exists"
			}
			let newPlayerNFT <- create MFLPlayer.NFT(id: id, season: season, image: image)
			MFLPlayer.playersDatas[newPlayerNFT.id] = MFLPlayer.PlayerData(id: newPlayerNFT.id, metadata: metadata, season: season, image: image)
			return <-newPlayerNFT
		}
		
		// Update Player Metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePlayerMetadata(id: UInt64, metadata:{ String: AnyStruct}){ 
			let playerData = MFLPlayer.playersDatas[id] ?? panic("Data not found")
			let updatedPlayerData = MFLPlayer.PlayerData(id: playerData.id, metadata: metadata, season: playerData.season, image: playerData.image)
			MFLPlayer.playersDatas[id] = updatedPlayerData
			emit Updated(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createPlayerAdmin(): @PlayerAdmin{ 
			return <-create PlayerAdmin()
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/MFLPlayerCollection
		self.CollectionPublicPath = /public/MFLPlayerCollection
		self.PlayerAdminStoragePath = /storage/MFLPlayerAdmin
		
		// Initialize contract fields
		self.totalSupply = 0
		self.playersDatas ={} 
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&MFLPlayer.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a PlayerAdmin resource and save it to storage
		self.account.storage.save(<-create PlayerAdmin(), to: self.PlayerAdminStoragePath)
		emit ContractInitialized()
	}
}
