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

	// This is the Kickstarter/Presale NFT contract of Chainmonsters.
// Based on the "current" NonFungibleToken standard on Flow.
// Does not include that much functionality as the only purpose it to mint and store the Presale NFTs.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract ChainmonstersRewards: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event RewardCreated(id: UInt32, metadata: String, season: UInt32)
	
	access(all)
	event NFTMinted(NFTID: UInt64, rewardID: UInt32, serialNumber: UInt32)
	
	access(all)
	event NewSeasonStarted(newCurrentSeason: UInt32)
	
	access(all)
	event ItemConsumed(itemID: UInt64, playerId: String)
	
	access(all)
	event ItemClaimed(itemID: UInt64, playerId: String, uid: String)
	
	access(all)
	event ItemMigrated(itemID: UInt64, rewardID: UInt32, serialNumber: UInt32, playerId: String, imxWallet: String)
	
	access(all)
	var nextRewardID: UInt32
	
	// Variable size dictionary of Reward structs
	access(self)
	var rewardDatas:{ UInt32: Reward}
	
	access(self)
	var rewardSupplies:{ UInt32: UInt32}
	
	access(self)
	var rewardSeasons:{ UInt32: UInt32}
	
	// a mapping of Reward IDs that indicates what serial/mint number
	// have been minted for this specific Reward yet
	access(all)
	var numberMintedPerReward:{ UInt32: UInt32}
	
	// the season a reward belongs to
	// A season is a concept where rewards are obtainable in-game for a limited time
	// After a season is over the rewards can no longer be minted and thus create
	// scarcity and drive the player-driven economy over time.
	access(all)
	var currentSeason: UInt32
	
	// A reward is a struct that keeps all the metadata information from an NFT in place.
	// There are 19 different rewards and all need an NFT-Interface.
	// Depending on the Reward-Type there are different ways to use and interact with future contracts.
	// E.g. the "Alpha Access" NFT needs to be claimed in order to gain game access with your account.
	// This process is destroying/moving the NFT to another contract.
	access(all)
	struct Reward{ 
		
		// The unique ID for the Reward
		access(all)
		let rewardID: UInt32
		
		// the game-season this reward belongs to
		// Kickstarter NFTs are Pre-Season and equal 0
		access(all)
		let season: UInt32
		
		// The metadata for the rewards is restricted to the name since
		// all other data is inside the token itself already
		// visual stuff and descriptions need to be retrieved via API
		access(all)
		let metadata: String
		
		init(metadata: String){ 
			pre{ 
				metadata.length != 0:
					"New Reward metadata cannot be empty"
			}
			self.rewardID = ChainmonstersRewards.nextRewardID
			self.metadata = metadata
			self.season = ChainmonstersRewards.currentSeason
			
			// Increment the ID so that it isn't used again
			ChainmonstersRewards.nextRewardID = ChainmonstersRewards.nextRewardID + UInt32(1)
			emit RewardCreated(id: self.rewardID, metadata: metadata, season: self.season)
		}
	}
	
	access(all)
	struct NFTData{ 
		
		// The ID of the Reward that the NFT references
		access(all)
		let rewardID: UInt32
		
		// The token mint number
		// Otherwise known as the serial number
		access(all)
		let serialNumber: UInt32
		
		init(rewardID: UInt32, serialNumber: UInt32){ 
			self.rewardID = rewardID
			self.serialNumber = serialNumber
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		
		// Global unique NFT ID
		access(all)
		let id: UInt64
		
		access(all)
		let data: NFTData
		
		init(serialNumber: UInt32, rewardID: UInt32){ 
			// Increment the global NFT IDs
			ChainmonstersRewards.totalSupply = ChainmonstersRewards.totalSupply + UInt64(1)
			self.id = ChainmonstersRewards.totalSupply
			self.data = NFTData(rewardID: rewardID, serialNumber: serialNumber)
			emit NFTMinted(NFTID: self.id, rewardID: rewardID, serialNumber: self.data.serialNumber)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Edition>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let externalRewardMetadata = ChainmonstersRewards.getExternalRewardMetadata(rewardID: self.data.rewardID)
			let name = externalRewardMetadata != nil ? (externalRewardMetadata!)["name"] ?? "Chainmonsters Reward #".concat(self.data.rewardID.toString()) : "Chainmonsters Reward #".concat(self.data.rewardID.toString())
			let description = externalRewardMetadata != nil ? (externalRewardMetadata!)["description"] ?? "A Chainmonsters Reward" : "A Chainmonsters Reward"
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: name, description: description, thumbnail: MetadataViews.HTTPFile(url: "https://chainmonsters.com/images/rewards/".concat(self.data.rewardID.toString()).concat(".png")))
				case Type<MetadataViews.Edition>():
					return MetadataViews.Edition(name: name, number: UInt64(self.data.serialNumber), max: UInt64(ChainmonstersRewards.getNumRewardsMinted(rewardID: self.data.rewardID)!))
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Chainmonsters Rewards", description: "Chainmonsters is a massive multiplayer online RPG where you catch, battle, trade, explore, and combine different types of monsters and abilities to create strong chain reactions! No game subscription required. Explore the vast lands of Ancora together with your friends on Steam, iOS and Android!", externalURL: MetadataViews.ExternalURL("https://chainmonsters.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://chainmonsters.com/images/chipleaf.png"), mediaType: "image/png"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://chainmonsters.com/images/bg.jpg"), mediaType: "image/jpeg"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/chainmonsters"), "discord": MetadataViews.ExternalURL("https://discord.gg/chainmonsters")})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://chainmonsters.com/rewards/".concat(self.data.rewardID.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: /storage/ChainmonstersRewardCollection, publicPath: /public/ChainmonstersRewardCollection, publicCollection: Type<&ChainmonstersRewards.Collection>(), publicLinkedType: Type<&ChainmonstersRewards.Collection>(), createEmptyCollectionFunction: fun (): @ChainmonstersRewards.Collection{ 
							return <-(ChainmonstersRewards.createEmptyCollection(nftType: Type<@ChainmonstersRewards.Collection>()) as! @ChainmonstersRewards.Collection)
						})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: ChainmonstersRewards.account.capabilities.get<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath())!, cut: 0.05, description: "Chainmonsters Platform Cut")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their Reward Collection as
	// to allow others to deposit Rewards into their Collection. It also allows for reading
	// the IDs of Rewards in the Collection.
	access(all)
	resource interface ChainmonstersRewardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowReward(id: UInt64): &ChainmonstersRewards.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Reward reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: ChainmonstersRewardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT-Reward from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			
			// Remove the nft from the Collection
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: Reward does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			
			// Return the withdrawn token
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		//
		// Parameters: ids: An array of IDs to withdraw
		//
		// Returns: @NonFungibleToken.Collection: A collection that contains
		//										the withdrawn rewards
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			// Create a new empty Collection
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			
			// Return the withdrawn tokens
			return <-batchCollection
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @ChainmonstersRewards.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// batchDeposit takes a Collection object as an argument
		// and deposits each contained NFT into this Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			
			// Get an array of the IDs to be deposited
			let keys = tokens.getIDs()
			
			// Iterate through the keys in the collection and deposit each one
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			
			// Destroy the empty Collection
			destroy tokens
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
		
		// borrowMReward returns a borrowed reference to a Reward
		// so that the caller can read data and call methods from it.
		//
		// Parameters: id: The ID of the NFT to get the reference for
		//
		// Returns: A reference to the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowReward(id: UInt64): &ChainmonstersRewards.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &ChainmonstersRewards.NFT?
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let rewardNFT = nft as! &ChainmonstersRewards.NFT
			return rewardNFT
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
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource Admin{ 
		
		// creates a new Reward struct and stores it in the Rewards dictionary
		// Parameters: metadata: the name of the reward
		access(TMP_ENTITLEMENT_OWNER)
		fun createReward(metadata: String, totalSupply: UInt32): UInt32{ 
			// Create the new Reward
			var newReward = Reward(metadata: metadata)
			let newID = newReward.rewardID
			
			// Kickstarter rewards are created with a fixed total supply.
			// Future season rewards are not technically limited by a total supply
			// but rather the time limitations in which a player can earn those.
			// Once a season is over the total supply for those rewards is fixed since
			// they can no longer be minted.
			ChainmonstersRewards.rewardSupplies[newID] = totalSupply
			ChainmonstersRewards.numberMintedPerReward[newID] = 0
			ChainmonstersRewards.rewardSeasons[newID] = newReward.season
			ChainmonstersRewards.rewardDatas[newID] = newReward
			return newID
		}
		
		// consuming an NFT (item) to be converted to in-game economy
		access(TMP_ENTITLEMENT_OWNER)
		fun consumeItem(token: @{NonFungibleToken.NFT}, playerId: String){ 
			let token <- token as! @ChainmonstersRewards.NFT
			let id: UInt64 = token.id
			emit ItemConsumed(itemID: id, playerId: playerId)
			destroy token
		}
		
		// removing an NFT (item) from the rewards collection to be migrated to the new IMX contracts
		access(TMP_ENTITLEMENT_OWNER)
		fun migrateItem(token: @{NonFungibleToken.NFT}, playerId: String, imxWallet: String){ 
			let token <- token as! @ChainmonstersRewards.NFT
			let id: UInt64 = token.id
			emit ItemMigrated(itemID: id, rewardID: token.data.rewardID, serialNumber: token.data.serialNumber, playerId: playerId, imxWallet: imxWallet)
			destroy token
		}
		
		// claiming an NFT item from e.g. Season Pass or Store
		// rewardID - reward to be claimed
		// uid - unique identifier from system
		access(TMP_ENTITLEMENT_OWNER)
		fun claimItem(rewardID: UInt32, playerId: String, uid: String): @NFT{ 
			let nft <- self.mintReward(rewardID: rewardID)
			emit ItemClaimed(itemID: nft.id, playerId: playerId, uid: uid)
			return <-nft
		}
		
		// mintReward mints a new NFT-Reward with a new ID
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mintReward(rewardID: UInt32): @NFT{ 
			pre{ 
				
				// check if the reward is still in "season"
				ChainmonstersRewards.rewardSeasons[rewardID] == ChainmonstersRewards.currentSeason
				// check if total supply allows additional NFTs || ignore if there is no hard cap specified == 0
				ChainmonstersRewards.numberMintedPerReward[rewardID] != ChainmonstersRewards.rewardSupplies[rewardID] || ChainmonstersRewards.rewardSupplies[rewardID] == UInt32(0)
			}
			
			// Gets the number of NFTs that have been minted for this Reward
			// to use as this NFT's serial number
			let numInReward = ChainmonstersRewards.numberMintedPerReward[rewardID]!
			
			// Mint the new NFT
			let newReward: @NFT <- create NFT(serialNumber: numInReward + UInt32(1), rewardID: rewardID)
			
			// Increment the count of NFTs minted for this Reward
			ChainmonstersRewards.numberMintedPerReward[rewardID] = numInReward + UInt32(1)
			return <-newReward
		}
		
		// batchMintReward mints an arbitrary quantity of Rewards
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintReward(rewardID: UInt32, quantity: UInt64): @Collection{ 
			let newCollection <- create Collection()
			var i: UInt64 = 0
			while i < quantity{ 
				newCollection.deposit(token: <-self.mintReward(rewardID: rewardID))
				i = i + UInt64(1)
			}
			return <-newCollection
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowReward(rewardID: UInt32): &Reward{ 
			pre{ 
				ChainmonstersRewards.rewardDatas[rewardID] != nil:
					"Cannot borrow Reward: The Reward doesn't exist"
			}
			
			// Get a reference to the Set and return it
			// use `&` to indicate the reference to the object and type
			return (&ChainmonstersRewards.rewardDatas[rewardID] as &Reward?)!
		}
		
		// ends the current season by incrementing the season number
		// Rewards minted after this will use the new season number.
		access(TMP_ENTITLEMENT_OWNER)
		fun startNewSeason(): UInt32{ 
			ChainmonstersRewards.currentSeason = ChainmonstersRewards.currentSeason + UInt32(1)
			emit NewSeasonStarted(newCurrentSeason: ChainmonstersRewards.currentSeason)
			return ChainmonstersRewards.currentSeason
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// -----------------------------------------------------------------------
	// ChainmonstersRewards contract-level function definitions
	// -----------------------------------------------------------------------
	// public function that anyone can call to create a new empty collection
	// This is required to receive Rewards in transactions.
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create ChainmonstersRewards.Collection()
	}
	
	// returns all the rewards setup in this contract
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllRewards(): [ChainmonstersRewards.Reward]{ 
		return ChainmonstersRewards.rewardDatas.values
	}
	
	// returns returns all the metadata associated with a specific Reward
	access(TMP_ENTITLEMENT_OWNER)
	fun getRewardMetaData(rewardID: UInt32): String?{ 
		return self.rewardDatas[rewardID]?.metadata
	}
	
	// returns the season this specified reward belongs to
	access(TMP_ENTITLEMENT_OWNER)
	fun getRewardSeason(rewardID: UInt32): UInt32?{ 
		return ChainmonstersRewards.rewardDatas[rewardID]?.season
	}
	
	// returns the maximum supply of a reward
	access(TMP_ENTITLEMENT_OWNER)
	fun getRewardMaxSupply(rewardID: UInt32): UInt32?{ 
		return ChainmonstersRewards.rewardSupplies[rewardID]
	}
	
	// isRewardLocked returns a boolean that indicates if a Reward
	//					  can no longer be minted.
	//
	// Parameters: rewardID: The id of the Set that is being searched
	//
	//
	// Returns: Boolean indicating if the reward is locked or not
	access(TMP_ENTITLEMENT_OWNER)
	fun isRewardLocked(rewardID: UInt32): Bool?{ 
		// Don't force a revert if the reward is invalid
		if ChainmonstersRewards.rewardSupplies[rewardID] == ChainmonstersRewards.numberMintedPerReward[rewardID]{ 
			return true
		} else{ 
			
			// If the Reward wasn't found , return nil
			return nil
		}
	}
	
	// returns the number of Rewards that have been minted already
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumRewardsMinted(rewardID: UInt32): UInt32?{ 
		let amount = ChainmonstersRewards.numberMintedPerReward[rewardID]
		return amount
	}
	
	// Get reward metadata from the contract owner storage, can be upgraded
	access(TMP_ENTITLEMENT_OWNER)
	fun getExternalSeasonMetadata(seasonID: UInt32):{ String: String}?{ 
		let data = self.account.capabilities.get<&[{String: String}]>(/public/ChainmonstersSeasonsMetadata).borrow()
		if data == nil{ 
			return nil
		}
		return (data!)[seasonID]
	}
	
	// Get reward metadata from the contract owner storage, can be upgraded
	access(TMP_ENTITLEMENT_OWNER)
	fun getExternalRewardMetadata(rewardID: UInt32):{ String: String}?{ 
		let data = self.account.capabilities.get<&[{String: String}]>(/public/ChainmonstersRewardsMetadata).borrow()
		if data == nil{ 
			return nil
		}
		return (data!)[rewardID]
	}
	
	init(){ 
		// Initialize contract fields
		self.rewardDatas ={} 
		self.nextRewardID = 1
		self.totalSupply = 0
		self.rewardSupplies ={} 
		self.numberMintedPerReward ={} 
		self.currentSeason = 0
		self.rewardSeasons ={} 
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: /storage/ChainmonstersRewardCollection)
		
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&{ChainmonstersRewardCollectionPublic}>(/storage/ChainmonstersRewardCollection)
		self.account.capabilities.publish(capability_1, at: /public/ChainmonstersRewardCollection)
		
		// Put the Minter in storage
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/ChainmonstersAdmin)
		emit ContractInitialized()
	}
}
