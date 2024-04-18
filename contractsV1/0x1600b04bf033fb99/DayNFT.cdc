// Implementation of the DayNFT contract
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import DateUtils from "../0xc0bcca6fd0fe81b0/DateUtils.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract DayNFT: NonFungibleToken{ 
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	// Total number of NFTs in circulation
	access(all)
	var totalSupply: UInt64
	
	// Resource containing data and logic around bids, minting and distribution
	access(contract)
	let manager: @ContractManager
	
	// Event emitted when the contract is initialized
	access(all)
	event ContractInitialized()
	
	// Event emitted when users withdraw from their NFT collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event emitted when users deposit into their NFT collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Event emitted when a new NFT is minted
	access(all)
	event Minted(id: UInt64, date: String, title: String)
	
	// Event emitted when a user makes a bid
	access(all)
	event BidReceived(user: Address, date: DateUtils.Date, title: String)
	
	// Event emitted when a user claims Flow tokens
	access(all)
	event TokensClaimed(user: Address, amount: UFix64)
	
	// Resource containing data and logic around bids, minting and distribution
	access(all)
	resource ContractManager{ 
		// NFTs that can be claimed by users that won previous days' auction(s)
		access(self)
		var NFTsDue: @{Address: [NFT]}
		
		// Amounts of Flow available to be redistributed to each NFT holder
		access(self)
		var amountsDue:{ UInt64: UFix64}
		
		// Percentage of any amount of Flow deposited to this contract that gets 
		// redistributed to NFT holders
		access(self)
		let percentageDistributed: UFix64
		
		// Vault to be used for flow redistribution
		access(self)
		let distributeVault: @FlowToken.Vault
		
		// Best bid of the day for minting today's NFT
		access(self)
		var bestBid: @Bid
		
		// NFT minter
		access(self)
		let minter: @NFTMinter
		
		// Contract address used for receiving tokens
		access(self)
		let contractAddress: Address
		
		init(contractAddress: Address){ 
			self.amountsDue ={} 
			self.NFTsDue <-{} 
			self.percentageDistributed = 0.5
			self.distributeVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
			
			// Initialize dummy best bid
			let vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
			let date = DateUtils.Date(day: 1, month: 1, year: 2021)
			self.bestBid <- create Bid(vault: <-vault, recipient: Address(0x0), title: "", date: date)
			
			// Create a Minter resource and keep it in the resource (not accessible from outside the contract)
			self.minter <- create NFTMinter()
			self.contractAddress = contractAddress
		}
		
		// Get the best bid for today's auction
		access(all)
		fun getBestBidWithToday(today: DateUtils.Date): PublicBid{ 
			if today.equals(self.bestBid.date){ 
				return PublicBid(amount: self.bestBid.vault.balance, user: self.bestBid.recipient, date: today)
			} else{ 
				return PublicBid(amount: 0.0, user: Address(0x0), date: today)
			}
		}
		
		// Get the best bid title for today's auction
		access(all)
		fun getBestBidTitleWithToday(today: DateUtils.Date): String?{ 
			if today.equals(self.bestBid.date){ 
				return self.bestBid.title
			} else{ 
				return nil
			}
		}
		
		// Verify if a user has any NFTs to claim after winning one or more auctions
		access(all)
		fun nbNFTsToClaimWithToday(address: Address, today: DateUtils.Date): Int{ 
			var res = 0
			if self.NFTsDue[address] != nil{ 
				res = self.NFTsDue[address]?.length!
			}
			if !self.bestBid.date.equals(today) && self.bestBid.recipient == address{ 
				res = res + 1
			}
			return res
		}
		
		// Handle new incoming bid
		access(all)
		fun handleBid(newBid: @Bid, today: DateUtils.Date){ 
			var bid <- newBid
			if self.bestBid.date.equals(today) || self.bestBid.vault.balance == 0.0{ 
				if bid.vault.balance > self.bestBid.vault.balance{ 
					if self.bestBid.vault.balance > 0.0{ 
						// Refund current best bid and replace it with the new one
						let rec = (getAccount(self.bestBid.recipient).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!).borrow() ?? panic("Could not borrow a reference to the receiver")
						var tempVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
						tempVault <-> self.bestBid.vault
						rec.deposit(from: <-tempVault)
					}
					bid <-> self.bestBid
				} else{ 
					// Refund the new bid
					let rec = (getAccount(bid.recipient).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!).borrow() ?? panic("Could not borrow a reference to the receiver")
					var tempVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
					tempVault <-> bid.vault
					rec.deposit(from: <-tempVault)
				}
			} else{ 
				// This is the first bid of the day
				// Assign NFT to best yesterday's bidder and replace today's bestBid with new bid
				// Deposit flow into contract account for redistribution
				var tempVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
				tempVault <-> self.bestBid.vault
				self.deposit(vault: <-tempVault)
				
				// Mint the NFT
				self.amountsDue[DayNFT.totalSupply] = 0.0
				let newNFT <- self.minter.mintNFT(date: self.bestBid.date, title: self.bestBid.title)
				// Record into due NFTs
				if self.NFTsDue[self.bestBid.recipient] == nil{ 
					let newArray <- [<-newNFT]
					self.NFTsDue[self.bestBid.recipient] <-! newArray
				} else{ 
					var newArray: @[NFT] <- []
					var a = 0
					var len = self.NFTsDue[self.bestBid.recipient]?.length!
					while a < len{ 
						let nft <- self.NFTsDue[self.bestBid.recipient]?.removeFirst()!
						newArray.append(<-nft)
						a = a + 1
					}
					newArray.append(<-newNFT)
					let old <- self.NFTsDue.remove(key: self.bestBid.recipient)
					destroy old
					self.NFTsDue[self.bestBid.recipient] <-! newArray
				}
				
				// Replace bid
				self.bestBid <-> bid
			}
			destroy bid
		}
		
		// Claim NFTs due to the user, and deposit them into their collection
		access(all)
		fun claimNFTsWithToday(address: Address, today: DateUtils.Date): Int{ 
			var res = 0
			let receiver = (getAccount(address).capabilities.get<&{DayNFT.CollectionPublic}>(DayNFT.CollectionPublicPath)!).borrow() ?? panic("Could not get receiver reference to the NFT Collection")
			if self.NFTsDue[address] != nil{ 
				var a = 0
				let len = self.NFTsDue[address]?.length!
				while a < len{ 
					let nft <- self.NFTsDue[address]?.removeFirst()!
					receiver.deposit(token: <-nft)
					a = a + 1
				}
				res = len
			}
			if !self.bestBid.date.equals(today) && self.bestBid.recipient == address{ 
				// Deposit flow to contract account
				var tempVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
				tempVault <-> self.bestBid.vault
				self.deposit(vault: <-tempVault)
				
				// Mint the NFT and send it
				self.amountsDue[DayNFT.totalSupply] = 0.0
				let newNFT <- self.minter.mintNFT(date: self.bestBid.date, title: self.bestBid.title)
				receiver.deposit(token: <-newNFT)
				
				// Replace old best bid with a dummy one with zero balance for today
				let vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()) as! @FlowToken.Vault
				var bid <- create Bid(vault: <-vault, recipient: Address(0x0), title: "", date: today)
				self.bestBid <-> bid
				destroy bid
				res = res + 1
			}
			return res
		}
		
		// Get amount of Flow due to the user
		access(all)
		fun tokensToClaim(address: Address): UFix64{ 
			// Borrow the recipient's public NFT collection reference
			let holder = (getAccount(address).capabilities.get<&DayNFT.Collection>(DayNFT.CollectionPublicPath)!).borrow() ?? panic("Could not get receiver reference to the NFT Collection")
			
			// Compute amount due based on number of NFTs detained
			var amountDue = 0.0
			for id in holder.getIDs(){ 
				amountDue = amountDue + self.amountsDue[id]!
			}
			return amountDue
		}
		
		// Claim Flow due to the user
		access(all)
		fun claimTokens(address: Address): UFix64{ 
			// Borrow the recipient's public NFT collection reference
			let holder = (getAccount(address).capabilities.get<&DayNFT.Collection>(DayNFT.CollectionPublicPath)!).borrow() ?? panic("Could not get receiver reference to the NFT Collection")
			
			// Borrow the recipient's flow token receiver
			let receiver = (getAccount(address).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!).borrow() ?? panic("Could not borrow a reference to the receiver")
			
			// Compute amount due based on number of NFTs detained
			var amountDue = 0.0
			for id in holder.getIDs(){ 
				amountDue = amountDue + self.amountsDue[id]!
				self.amountsDue[id] = 0.0
			}
			
			// Pay amount
			let vault <- self.distributeVault.withdraw(amount: amountDue)
			receiver.deposit(from: <-vault)
			emit TokensClaimed(user: address, amount: amountDue)
			return amountDue
		}
		
		access(all)
		fun max(_ a: UFix64, _ b: UFix64): UFix64{ 
			var res = a
			if b > a{ 
				res = b
			}
			return res
		}
		
		// Deposit Flow into the contract, to be redistributed among NFT holders
		access(all)
		fun deposit(vault: @{FungibleToken.Vault}){ 
			let amount = vault.balance
			var distribute = amount * self.percentageDistributed
			if DayNFT.totalSupply == 0{ 
				distribute = 0.0
			}
			let distrVault <- vault.withdraw(amount: distribute)
			self.distributeVault.deposit(from: <-distrVault)
			// Deposit to the account
			let rec = (getAccount(self.contractAddress).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)!).borrow() ?? panic("Could not borrow a reference to the Flow receiver")
			rec.deposit(from: <-vault)
			
			// Assign part of the value to the current holders
			let id = DayNFT.totalSupply
			let distributeEach = distribute / self.max(UFix64(id), 1.0)
			var a = 0 as UInt64
			while a < id{ 
				self.amountsDue[a] = self.amountsDue[a]! + distributeEach
				a = a + 1
			}
		}
	}
	
	// Standard NFT resource
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let title: String
		
		access(all)
		let date: DateUtils.Date
		
		access(all)
		let dateStr: String
		
		init(initID: UInt64, date: DateUtils.Date, title: String){ 
			self.dateStr = date.toString()
			self.id = initID
			self.name = "DAY-NFT #".concat(self.dateStr)
			self.description = "Minted on day-nft.io on ".concat(self.dateStr)
			self.thumbnail = "https://day-nft.io/imgs/".concat(initID.toString()).concat(".png")
			self.title = title
			self.date = date
			emit Minted(id: initID, date: date.toString(), title: title)
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
					let editionInfo = MetadataViews.Edition(name: "DayNFT", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					let royalty = MetadataViews.Royalty(receiver: DayNFT.account.capabilities.get<&{FungibleToken.Receiver}>(DayNFT.AdminPublicPath)!, cut: 0.1, description: "Default royalty")
					return MetadataViews.Royalties([royalty])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://day-nft.io")
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: DayNFT.CollectionStoragePath, publicPath: DayNFT.CollectionPublicPath, publicCollection: Type<&DayNFT.Collection>(), publicLinkedType: Type<&DayNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-DayNFT.createEmptyCollection(nftType: Type<@DayNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let header = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://day-nft.io/header.png"), mediaType: "image/png")
					let logo = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://day-nft.io/thumbnail.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "DayNFT", description: "One NFT per day, storing memories on Flow. Half of daily auction proceeds gets distributed back to holders.", externalURL: MetadataViews.ExternalURL("https://day-nft.io"), squareImage: logo, bannerImage: header, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/day_nft_io")})
				case Type<MetadataViews.Traits>():
					let rarityScore = (1.0 - UFix64(self.id + 1) / UFix64(DayNFT.totalSupply)) * 100.0
					var rarityDesc = "Common"
					if rarityScore > 80.0{ 
						rarityDesc = "Historic"
					} else if rarityScore > 50.0{ 
						rarityDesc = "Vintage"
					} else if rarityScore > 30.0{ 
						rarityDesc = "Classical"
					}
					if self.id < 20{ 
						rarityDesc = "OG"
					}
					let ageRarity = MetadataViews.Rarity(score: rarityScore, max: 100.0, description: rarityDesc)
					let mintedDayTrait = MetadataViews.Trait(name: "Mint Day", value: self.dateStr, displayType: "String", rarity: ageRarity)
					let mintedMonthTrait = MetadataViews.Trait(name: "Mint Month", value: self.dateStr.slice(from: 3, upTo: 10), displayType: "String", rarity: nil)
					let traits = MetadataViews.Traits([mintedDayTrait, mintedMonthTrait])
					return traits
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// This is the interface that users can cast their DayNFT Collection as
	// to allow others to deposit DayNFT into their Collection. It also allows for reading
	// the details of a DayNFT in the Collection.
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrowDayNFT(id: UInt64): &DayNFT.NFT?{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow DayNFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	// Collection of NFTs implementing standard interfaces
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// Dictionary of NFT conforming tokens
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
			let token <- token as! @DayNFT.NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary which removes the old one
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
		
		// Gets a reference to an NFT in the collection as a DayNFT,
		// exposing all of its fields.
		access(all)
		fun borrowDayNFT(id: UInt64): &DayNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &DayNFT.NFT?
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let dayNFT = nft as! &DayNFT.NFT
			return dayNFT as &{ViewResolver.Resolver}
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Resource that the contract owns to create new NFTs
	access(all)
	resource NFTMinter{ 
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(date: DateUtils.Date, title: String): @NFT{ 
			
			// create a new NFT
			let id = DayNFT.totalSupply
			var newNFT <- create NFT(initID: id, date: date, title: title)
			DayNFT.totalSupply = DayNFT.totalSupply + 1
			return <-newNFT
		}
	}
	
	// Resource containing a user's bid in the auction for today's NFT
	access(all)
	resource Bid{ 
		access(all)
		var vault: @FlowToken.Vault
		
		access(all)
		let recipient: Address
		
		access(all)
		let title: String
		
		access(all)
		let date: DateUtils.Date
		
		init(vault: @FlowToken.Vault, recipient: Address, title: String, date: DateUtils.Date){ 
			self.vault <- vault
			self.recipient = recipient
			self.title = title
			self.date = date
		}
	}
	
	// PUBLIC APIs //
	// Create an empty NFT collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Make a bid on today's NFT
	access(all)
	fun makeBid(vault: @FlowToken.Vault, recipient: Address, title: String, date: DateUtils.Date){ 
		let today = DateUtils.getDate()
		self.makeBidWithToday(vault: <-vault, recipient: recipient, title: title, date: date, today: today)
	}
	
	// Make this public when testing
	access(contract)
	fun makeBidWithToday(vault: @FlowToken.Vault, recipient: Address, title: String, date: DateUtils.Date, today: DateUtils.Date){ 
		if !date.equals(today){ 
			panic("You can only bid on today's NFT")
		}
		if vault.balance == 0.0{ 
			panic("You can only bid a positive amount")
		}
		if title.length > 70{ 
			panic("The title can only be 70 characters long at most")
		}
		var bid <- create Bid(vault: <-vault, recipient: recipient, title: title, date: date)
		self.manager.handleBid(newBid: <-bid, today: today)
		emit BidReceived(user: recipient, date: date, title: title)
	}
	
	access(all)
	struct PublicBid{ 
		access(all)
		let amount: UFix64
		
		access(all)
		let user: Address
		
		access(all)
		let date: DateUtils.Date
		
		init(amount: UFix64, user: Address, date: DateUtils.Date){ 
			self.amount = amount
			self.user = user
			self.date = date
		}
	}
	
	// Get the best bid for today's auction
	access(all)
	fun getBestBid(): PublicBid{ 
		var today = DateUtils.getDate()
		return self.getBestBidWithToday(today: today)
	}
	
	// Make this public when testing
	access(contract)
	fun getBestBidWithToday(today: DateUtils.Date): PublicBid{ 
		return self.manager.getBestBidWithToday(today: today)
	}
	
	// Get the best bid title for today's auction
	access(all)
	fun getBestBidTitle(): String?{ 
		var today = DateUtils.getDate()
		return self.getBestBidTitleWithToday(today: today)
	}
	
	// Make this public when testing
	access(contract)
	fun getBestBidTitleWithToday(today: DateUtils.Date): String?{ 
		return self.manager.getBestBidTitleWithToday(today: today)
	}
	
	// Verify if a user has any NFTs to claim after winning one or more auctions
	access(all)
	fun nbNFTsToClaim(address: Address): Int{ 
		let today = DateUtils.getDate()
		return self.nbNFTsToClaimWithToday(address: address, today: today)
	}
	
	// Make this public when testing
	access(contract)
	fun nbNFTsToClaimWithToday(address: Address, today: DateUtils.Date): Int{ 
		return self.manager.nbNFTsToClaimWithToday(address: address, today: today)
	}
	
	// Claim NFTs due to the user, and deposit them into their collection
	access(all)
	fun claimNFTs(address: Address): Int{ 
		var today = DateUtils.getDate()
		return self.claimNFTsWithToday(address: address, today: today)
	}
	
	// Make this public when testing
	access(contract)
	fun claimNFTsWithToday(address: Address, today: DateUtils.Date): Int{ 
		return self.manager.claimNFTsWithToday(address: address, today: today)
	}
	
	// Get amount of Flow due to the user
	access(all)
	fun tokensToClaim(address: Address): UFix64{ 
		return self.manager.tokensToClaim(address: address)
	}
	
	// Claim Flow due to the user
	access(all)
	fun claimTokens(address: Address): UFix64{ 
		return self.manager.claimTokens(address: address)
	}
	
	// Resource to receive Flow tokens to be distributed
	access(all)
	resource Admin: FungibleToken.Receiver{ 
		access(all)
		fun deposit(from: @{FungibleToken.Vault}){ 
			DayNFT.manager.deposit(vault: <-from)
		}
		
		access(all)
		view fun getSupportedVaultTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedVaultType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	init(){ 
		// Set named paths
		// Add version suffix to the paths when deploying to testnet
		self.CollectionStoragePath = /storage/DayNFTCollection
		self.CollectionPublicPath = /public/DayNFTCollection
		self.AdminPublicPath = /public/DayNFTAdmin
		let adminStoragePath = /storage/DayNFTAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: adminStoragePath)
		// Create a public capability allowing external users (like marketplaces)
		// to deposit flow to the contract so that it can be redistributed
		var capability_1 = self.account.capabilities.storage.issue<&DayNFT.Admin>(adminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPublicPath)
		self.totalSupply = 0
		self.manager <- create ContractManager(contractAddress: self.account.address)
		emit ContractInitialized()
	}
}