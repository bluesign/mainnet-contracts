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

	// This contract allows users to put their NFTs up for sale. Other users
// can purchase these NFTs with fungible tokens.
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import Momentables from "./Momentables.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

//This contract was made during OWB so the code here is some of the first cadence code we (0xAlchemist and 0xBjartek wrote)
access(all)
contract MomentablesAuction{ 
	
	// This struct aggreates status for the auction and is exposed in order to create websites using auction information
	access(all)
	struct AuctionStatus{ 
		access(all)
		let id: UInt64
		
		access(all)
		let price: UFix64
		
		access(all)
		let bidIncrement: UFix64
		
		access(all)
		let bids: UInt64
		
		//Active is probably not needed when we have completed and expired above, consider removing it
		access(all)
		let active: Bool
		
		access(all)
		let timeRemaining: Fix64
		
		access(all)
		let endTime: Fix64
		
		access(all)
		let startTime: Fix64
		
		access(all)
		let metadata:{ String:{ String: String}}?
		
		access(all)
		let artId: UInt64?
		
		access(all)
		let owner: Address
		
		access(all)
		let leader: Address?
		
		access(all)
		let minNextBid: UFix64
		
		access(all)
		let completed: Bool
		
		access(all)
		let expired: Bool
		
		init(
			id: UInt64,
			currentPrice: UFix64,
			bids: UInt64,
			active: Bool,
			timeRemaining: Fix64,
			metadata:{ 
				String:{ 
					String: String
				}
			}?,
			artId: UInt64?,
			leader: Address?,
			bidIncrement: UFix64,
			owner: Address,
			startTime: Fix64,
			endTime: Fix64,
			minNextBid: UFix64,
			completed: Bool,
			expired: Bool
		){ 
			self.id = id
			self.price = currentPrice
			self.bids = bids
			self.active = active
			self.timeRemaining = timeRemaining
			self.metadata = metadata
			self.artId = artId
			self.leader = leader
			self.bidIncrement = bidIncrement
			self.owner = owner
			self.startTime = startTime
			self.endTime = endTime
			self.minNextBid = minNextBid
			self.completed = completed
			self.expired = expired
		}
	}
	
	access(all)
	struct momentableDetails{ 
		access(all)
		var momentableId: String
		
		access(all)
		var description: String
		
		init(momentableId: String, description: String){ 
			self.momentableId = momentableId
			self.description = description
		}
	}
	
	// The total amount of AuctionItems that have been created
	access(all)
	var totalAuctions: UInt64
	
	// Events
	access(all)
	event TokenPurchased(id: UInt64, artId: UInt64, price: UFix64, from: Address, to: Address?)
	
	access(all)
	event CollectionCreated(owner: Address, cutPercentage: UFix64)
	
	access(all)
	event Created(
		tokenID: UInt64,
		owner: Address,
		startPrice: UFix64,
		startTime: UFix64,
		endTime: Fix64,
		timeRemaining: Fix64,
		itemID: UInt64,
		momentableId: String
	)
	
	access(all)
	event Bid(tokenID: UInt64, bidderAddress: Address, bidPrice: UFix64)
	
	access(all)
	event Settled(tokenID: UInt64, price: UFix64)
	
	access(all)
	event Canceled(tokenID: UInt64)
	
	access(all)
	event MarketplaceEarned(amount: UFix64, owner: Address)
	
	// AuctionItem contains the Resources and metadata for a single auction
	access(all)
	resource AuctionItem{ 
		
		//Number of bids made, that is aggregated to the status struct
		access(self)
		var numberOfBids: UInt64
		
		//The Item that is sold at this auction
		//It would be really easy to extend this auction with using a NFTCollection here to be able to auction of several NFTs as a single
		//Lets say if you want to auction of a pack of TopShot moments
		access(all)
		var NFT: @Momentables.NFT?
		
		access(self)
		var momentableId: String
		
		access(self)
		var itemID: UInt64
		
		//This is the escrow vault that holds the tokens for the current largest bid
		access(self)
		let bidVault: @{FungibleToken.Vault}
		
		//The id of this individual auction
		access(all)
		let auctionID: UInt64
		
		//The minimum increment for a bid. This is an english auction style system where bids increase
		access(self)
		let minimumBidIncrement: UFix64
		
		//the time the acution should start at
		access(self)
		var auctionStartTime: UFix64
		
		//The length in seconds for this auction
		access(self)
		var auctionLength: UFix64
		
		//Right now the dropitem is not moved from the collection when it ends, it is just marked here that it has ended 
		access(self)
		var auctionCompleted: Bool
		
		// Auction State
		access(account)
		var startPrice: UFix64
		
		access(self)
		var currentPrice: UFix64
		
		//the capability that points to the resource where you want the NFT transfered to if you win this bid. 
		access(self)
		var recipientCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>?
		
		//the capablity to send the escrow bidVault to if you are outbid
		access(self)
		var recipientVaultCap: Capability<&{FungibleToken.Receiver}>?
		
		//the capability for the owner of the NFT to return the item to if the auction is cancelled
		access(self)
		let ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		
		//the capability to pay the owner of the item when the auction is done
		access(self)
		let ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		
		init(
			NFT: @Momentables.NFT,
			momentableId: String,
			itemID: UInt64,
			minimumBidIncrement: UFix64,
			auctionStartTime: UFix64,
			startPrice: UFix64,
			auctionLength: UFix64,
			ownerCollectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
			ownerVaultCap: Capability<&{FungibleToken.Receiver}>
		){ 
			MomentablesAuction.totalAuctions = MomentablesAuction.totalAuctions + 1 as UInt64
			self.NFT <- NFT
			self.momentableId = momentableId
			self.itemID = itemID
			self.bidVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
			self.auctionID = MomentablesAuction.totalAuctions
			self.minimumBidIncrement = minimumBidIncrement
			self.auctionLength = auctionLength
			self.startPrice = startPrice
			self.currentPrice = 0.0
			self.auctionStartTime = auctionStartTime
			self.auctionCompleted = false
			self.recipientCollectionCap = nil
			self.recipientVaultCap = nil
			self.ownerCollectionCap = ownerCollectionCap
			self.ownerVaultCap = ownerVaultCap
			self.numberOfBids = 0
		}
		
		// sendNFT sends the NFT to the Collection belonging to the provided Capability
		access(contract)
		fun sendNFT(_ capability: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			if let collectionRef = capability.borrow(){ 
				let NFT <- self.NFT <- nil
				collectionRef.deposit(token: <-NFT!)
				return
			}
			if let ownerCollection = self.ownerCollectionCap.borrow(){ 
				let NFT <- self.NFT <- nil
				ownerCollection.deposit(token: <-NFT!)
				return
			}
		}
		
		// sendBidTokens sends the bid tokens to the Vault Receiver belonging to the provided Capability
		access(contract)
		fun sendBidTokens(_ capability: Capability<&{FungibleToken.Receiver}>){ 
			// borrow a reference to the owner's NFT receiver
			if let vaultRef = capability.borrow(){ 
				let bidVaultRef = &self.bidVault as &{FungibleToken.Vault}
				if bidVaultRef.balance > 0.0{ 
					vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
				}
				return
			}
			if let ownerRef = self.ownerVaultCap.borrow(){ 
				let bidVaultRef = &self.bidVault as &{FungibleToken.Vault}
				if bidVaultRef.balance > 0.0{ 
					ownerRef.deposit(from: <-bidVaultRef.withdraw(amount: bidVaultRef.balance))
				}
				return
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun releasePreviousBid(){ 
			if let vaultCap = self.recipientVaultCap{ 
				self.sendBidTokens(self.recipientVaultCap!)
				return
			}
		}
		
		//This method should probably use preconditions more 
		access(TMP_ENTITLEMENT_OWNER)
		fun settleAuction(cutPercentage: UFix64, cutVault: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				!self.auctionCompleted:
					"The auction is already settled"
				self.NFT != nil:
					"NFT in auction does not exist"
				self.isAuctionExpired():
					"Auction has not completed yet"
			}
			
			// return if there are no bids to settle
			if self.currentPrice == 0.0{ 
				self.returnAuctionItemToOwner()
				return
			}
			if cutPercentage != 0.0{ 
				//Withdraw cutPercentage to marketplace and put it in their vault
				let amount = self.currentPrice * (cutPercentage / 100.0)
				let beneficiaryCut <- self.bidVault.withdraw(amount: amount)
				let cutVault = cutVault.borrow()!
				emit MarketplaceEarned(amount: amount, owner: (cutVault.owner!).address)
				cutVault.deposit(from: <-beneficiaryCut)
			}
			let artId = self.NFT?.id
			self.sendNFT(self.recipientCollectionCap!)
			self.sendBidTokens(self.ownerVaultCap)
			self.auctionCompleted = true
			emit Settled(tokenID: self.auctionID, price: self.currentPrice)
			emit TokenPurchased(
				id: self.auctionID,
				artId: artId!,
				price: self.currentPrice,
				from: self.ownerVaultCap.address,
				to: self.recipientCollectionCap?.address
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun returnAuctionItemToOwner(){ 
			
			// release the bidder's tokens
			self.releasePreviousBid()
			
			// deposit the NFT into the owner's collection
			self.sendNFT(self.ownerCollectionCap)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setAuctionCompleted(){ 
			self.auctionCompleted = true
		}
		
		//this can be negative if is expired
		access(TMP_ENTITLEMENT_OWNER)
		view fun timeRemaining(): Fix64{ 
			let auctionLength = self.auctionLength
			let startTime = self.auctionStartTime
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(startTime + auctionLength) - Fix64(currentTime)
			return remaining
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isAuctionExpired(): Bool{ 
			let timeRemaining = self.timeRemaining()
			return timeRemaining < Fix64(0.0)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun minNextBid(): UFix64{ 
			//If there are bids then the next min bid is the current price plus the increment
			if self.currentPrice != 0.0{ 
				return self.currentPrice + self.minimumBidIncrement
			}
			//else start price
			return self.startPrice
		}
		
		//Extend an auction with a given set of blocks
		access(TMP_ENTITLEMENT_OWNER)
		fun extendWith(_ amount: UFix64){ 
			self.auctionLength = self.auctionLength + amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun bidder(): Address?{ 
			if let vaultCap = self.recipientVaultCap{ 
				return vaultCap.address
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun currentBidForUser(address: Address): UFix64{ 
			if self.bidder() == address{ 
				return self.bidVault.balance
			}
			return 0.0
		}
		
		// This method should probably use preconditions more
		access(TMP_ENTITLEMENT_OWNER)
		fun placeBid(
			bidTokens: @{FungibleToken.Vault},
			vaultCap: Capability<&{FungibleToken.Receiver}>,
			collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		){ 
			pre{ 
				!self.auctionCompleted:
					"The auction is already settled"
				self.NFT != nil:
					"NFT in auction does not exist"
			}
			let bidderAddress = vaultCap.address
			let collectionAddress = collectionCap.address
			if bidderAddress != collectionAddress{ 
				panic("you cannot make a bid and send the art to sombody elses collection")
			}
			let amountYouAreBidding =
				bidTokens.balance + self.currentBidForUser(address: bidderAddress)
			let minNextBid = self.minNextBid()
			if amountYouAreBidding < minNextBid{ 
				panic("bid amount + (your current bid) must be larger or equal to the current price + minimum bid increment ".concat(amountYouAreBidding.toString()).concat(" < ").concat(minNextBid.toString()))
			}
			if self.bidder() != bidderAddress{ 
				if self.bidVault.balance != 0.0{ 
					self.sendBidTokens(self.recipientVaultCap!)
				}
			}
			
			// Update the auction item
			self.bidVault.deposit(from: <-bidTokens)
			
			//update the capability of the wallet for the address with the current highest bid
			self.recipientVaultCap = vaultCap
			
			// Update the current price of the token
			self.currentPrice = self.bidVault.balance
			
			// Add the bidder's Vault and NFT receiver references
			self.recipientCollectionCap = collectionCap
			self.numberOfBids = self.numberOfBids + 1 as UInt64
			emit Bid(
				tokenID: self.auctionID,
				bidderAddress: bidderAddress,
				bidPrice: self.currentPrice
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(): AuctionStatus{ 
			var leader: Address? = nil
			if let recipient = self.recipientVaultCap{ 
				leader = recipient.address
			}
			return AuctionStatus(
				id: self.auctionID,
				currentPrice: self.currentPrice,
				bids: self.numberOfBids,
				active: !self.auctionCompleted && !self.isAuctionExpired(),
				timeRemaining: self.timeRemaining(),
				metadata:{} ,
				artId: self.NFT?.id,
				leader: leader,
				bidIncrement: self.minimumBidIncrement,
				owner: self.ownerVaultCap.address,
				startTime: Fix64(self.auctionStartTime),
				endTime: Fix64(self.auctionStartTime + self.auctionLength),
				minNextBid: self.minNextBid(),
				completed: self.auctionCompleted,
				expired: self.isAuctionExpired()
			)
		}
	}
	
	// AuctionPublic is a resource interface that restricts users to
	// retreiving the auction price list and placing bids
	access(all)
	resource interface AuctionPublic{ 
		
		//It could be argued that this method should not be here in the public contract. I guss it could be an interface of its own
		//That way when you create an auction you chose if this is a curated auction or an auction where everybody can put their pieces up for sale
		access(TMP_ENTITLEMENT_OWNER)
		fun createAuction(
			token: @Momentables.NFT,
			momentableId: String,
			itemID: UInt64,
			minimumBidIncrement: UFix64,
			auctionLength: UFix64,
			auctionStartTime: UFix64,
			startPrice: UFix64,
			collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
			vaultCap: Capability<&{FungibleToken.Receiver}>
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatuses():{ UInt64: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(_ id: UInt64): AuctionStatus
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAuctionedMomentable(id: UInt64): &Momentables.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun placeBid(
			id: UInt64,
			bidTokens: @{FungibleToken.Vault},
			vaultCap: Capability<&{FungibleToken.Receiver}>,
			collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>
		)
	}
	
	// AuctionCollection contains a dictionary of AuctionItems and provides
	// methods for manipulating the AuctionItems
	access(all)
	resource AuctionCollection: AuctionPublic{ 
		
		// Auction Items
		access(account)
		var auctionItems: @{UInt64: AuctionItem}
		
		access(contract)
		var cutPercentage: UFix64
		
		access(contract)
		let marketplaceVault: Capability<&{FungibleToken.Receiver}>
		
		init(marketplaceVault: Capability<&{FungibleToken.Receiver}>, cutPercentage: UFix64){ 
			self.cutPercentage = cutPercentage
			self.marketplaceVault = marketplaceVault
			self.auctionItems <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun extendAllAuctionsWith(_ amount: UFix64){ 
			for id in self.auctionItems.keys{ 
				let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
				itemRef.extendWith(amount)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun keys(): [UInt64]{ 
			return self.auctionItems.keys
		}
		
		// addTokenToauctionItems adds an NFT to the auction items and sets the meta data
		// for the auction item
		access(TMP_ENTITLEMENT_OWNER)
		fun createAuction(token: @Momentables.NFT, momentableId: String, itemID: UInt64, minimumBidIncrement: UFix64, auctionLength: UFix64, auctionStartTime: UFix64, startPrice: UFix64, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>, vaultCap: Capability<&{FungibleToken.Receiver}>){ 
			
			// create a new auction items resource container
			let item <- MomentablesAuction.createStandaloneAuction(token: <-token, momentableId: momentableId, itemID: itemID, minimumBidIncrement: minimumBidIncrement, auctionLength: auctionLength, auctionStartTime: auctionStartTime, startPrice: startPrice, collectionCap: collectionCap, vaultCap: vaultCap)
			let id = item.auctionID
			
			// update the auction items dictionary with the new resources
			let oldItem <- self.auctionItems[id] <- item
			destroy oldItem
			let owner = vaultCap.address
			let endTime = Fix64(auctionStartTime + auctionLength)
			let currentTime = getCurrentBlock().timestamp
			let remaining = Fix64(auctionStartTime + auctionLength) - Fix64(currentTime)
			emit Created(tokenID: id, owner: owner, startPrice: startPrice, startTime: auctionStartTime, endTime: endTime, timeRemaining: remaining, itemID: itemID, momentableId: momentableId)
		}
		
		// getAuctionPrices returns a dictionary of available NFT IDs with their current price
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatuses():{ UInt64: AnyStruct}{ 
			var priceList:{ UInt64: AnyStruct} ={} 
			for id in self.auctionItems.keys{ 
				let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
				if itemRef == nil{ 
					return priceList
				}
				priceList.insert(key: id,{ "auctionDetails": itemRef.getAuctionStatus(), "momentableDetails":{ "momentableId": self.auctionItems[id]?.NFT?.momentableId, "name": self.auctionItems[id]?.NFT?.name, "description": self.auctionItems[id]?.NFT?.description, "itemID": self.auctionItems[id]?.NFT?.id}})
			}
			return priceList
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(_ id: UInt64): AuctionStatus{ 
			pre{ 
				self.auctionItems[id] != nil:
					"NFT doesn't exist"
			}
			
			// Get the auction item resources
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			return itemRef.getAuctionStatus()
		}
		
		// settleAuction sends the auction item to the highest bidder
		// and deposits the FungibleTokens into the auction owner's account
		access(TMP_ENTITLEMENT_OWNER)
		fun settleAuction(_ id: UInt64){ 
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			itemRef.settleAuction(cutPercentage: self.cutPercentage, cutVault: self.marketplaceVault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelAuction(_ id: UInt64){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist"
			}
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			itemRef.returnAuctionItemToOwner()
			itemRef.setAuctionCompleted()
			emit Canceled(tokenID: id)
		}
		
		// placeBid sends the bidder's tokens to the bid vault and updates the
		// currentPrice of the current auction item
		access(TMP_ENTITLEMENT_OWNER)
		fun placeBid(id: UInt64, bidTokens: @{FungibleToken.Vault}, vaultCap: Capability<&{FungibleToken.Receiver}>, collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist in this drop"
			}
			
			// Get the auction item resources
			let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
			itemRef.placeBid(bidTokens: <-bidTokens, vaultCap: vaultCap, collectionCap: collectionCap)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAuctionedMomentable(id: UInt64): &Momentables.NFT?{ 
			pre{ 
				self.auctionItems[id] != nil:
					"Momentable does not exist in this AuctionCollection"
			}
			if self.auctionItems[id] != nil{ 
				let itemRef = (&self.auctionItems[id] as &AuctionItem?)!
				let ref = (itemRef.NFT as &Momentables.NFT?)!
				return ref as! &Momentables.NFT
			} else{ 
				return nil
			}
		}
	}
	
	//this method is used to create a standalone auction that is not part of a collection
	//we use this to create the unique part of the Versus contract
	access(TMP_ENTITLEMENT_OWNER)
	fun createStandaloneAuction(
		token: @Momentables.NFT,
		momentableId: String,
		itemID: UInt64,
		minimumBidIncrement: UFix64,
		auctionLength: UFix64,
		auctionStartTime: UFix64,
		startPrice: UFix64,
		collectionCap: Capability<&{NonFungibleToken.CollectionPublic}>,
		vaultCap: Capability<&{FungibleToken.Receiver}>
	): @AuctionItem{ 
		
		// create a new auction items resource container
		return <-create AuctionItem(
			NFT: <-token,
			momentableId: momentableId,
			itemID: itemID,
			minimumBidIncrement: minimumBidIncrement,
			auctionStartTime: auctionStartTime,
			startPrice: startPrice,
			auctionLength: auctionLength,
			ownerCollectionCap: collectionCap,
			ownerVaultCap: vaultCap
		)
	}
	
	// createAuctionCollection returns a new AuctionCollection resource to the caller
	access(TMP_ENTITLEMENT_OWNER)
	fun createAuctionCollection(
		marketplaceVault: Capability<&{FungibleToken.Receiver}>,
		cutPercentage: UFix64
	): @AuctionCollection{ 
		let auctionCollection <-
			create AuctionCollection(
				marketplaceVault: marketplaceVault,
				cutPercentage: cutPercentage
			)
		emit CollectionCreated(owner: marketplaceVault.address, cutPercentage: cutPercentage)
		return <-auctionCollection
	}
	
	init(){ 
		self.totalAuctions = 0 as UInt64
	}
}
