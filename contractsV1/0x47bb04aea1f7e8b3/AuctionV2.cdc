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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import Collectible from "../0xf5b0eb433389ac3f/Collectible.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Edition from "../0xf5b0eb433389ac3f/Edition.cdc"

access(all)
contract AuctionV2{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
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
		
		access(all)
		let active: Bool
		
		access(all)
		let timeRemaining: Fix64
		
		access(all)
		let endTime: Fix64
		
		access(all)
		let startTime: Fix64
		
		access(all)
		let startBidTime: Fix64
		
		access(all)
		let metadata: Collectible.Metadata?
		
		access(all)
		let collectibleId: UInt64?
		
		access(all)
		let leader: Address?
		
		access(all)
		let minNextBid: UFix64
		
		access(all)
		let completed: Bool
		
		access(all)
		let expired: Bool
		
		access(all)
		let cancelled: Bool
		
		access(all)
		let currentLength: UFix64
		
		init(
			id: UInt64,
			currentPrice: UFix64,
			bids: UInt64,
			active: Bool,
			timeRemaining: Fix64,
			metadata: Collectible.Metadata?,
			collectibleId: UInt64?,
			leader: Address?,
			bidIncrement: UFix64,
			startTime: Fix64,
			startBidTime: Fix64,
			endTime: Fix64,
			minNextBid: UFix64,
			completed: Bool,
			expired: Bool,
			cancelled: Bool,
			currentLength: UFix64
		){ 
			self.id = id
			self.price = currentPrice
			self.bids = bids
			self.active = active
			self.timeRemaining = timeRemaining
			self.metadata = metadata
			self.collectibleId = collectibleId
			self.leader = leader
			self.bidIncrement = bidIncrement
			self.startTime = startTime
			self.startBidTime = startBidTime
			self.endTime = endTime
			self.minNextBid = minNextBid
			self.completed = completed
			self.expired = expired
			self.cancelled = cancelled
			self.currentLength = currentLength
		}
	}
	
	// The total amount of AuctionItems that have been created
	access(all)
	var totalAuctions: UInt64
	
	// Events
	access(all)
	event CollectionCreated()
	
	access(all)
	event Created(
		auctionID: UInt64,
		owner: Address,
		startPrice: UFix64,
		startTime: UFix64,
		auctionLength: UFix64,
		startBidTime: UFix64
	)
	
	access(all)
	event Bid(auctionID: UInt64, bidderAddress: Address, bidPrice: UFix64, placedAt: Fix64)
	
	access(all)
	event SetStartTime(auctionID: UInt64, startAuctionTime: UFix64)
	
	access(all)
	event Settled(auctionID: UInt64, price: UFix64)
	
	access(all)
	event Canceled(auctionID: UInt64)
	
	access(all)
	event Earned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	event FailEarned(nftID: UInt64, amount: UFix64, owner: Address, type: String)
	
	access(all)
	event Extend(auctionID: UInt64, auctionLengthFrom: UFix64, auctionLengthTo: UFix64)
	
	access(all)
	event AddNFT(auctionID: UInt64, nftID: UInt64)
	
	access(all)
	event BurnNFT(auctionID: UInt64, nftID: UInt64)
	
	access(all)
	event SendNFT(auctionID: UInt64, nftID: UInt64, to: Address)
	
	access(all)
	event FailSendNFT(auctionID: UInt64, nftID: UInt64, to: Address)
	
	access(all)
	event SendBidTokens(auctionID: UInt64, amount: UFix64, to: Address)
	
	access(all)
	event FailSendBidTokens(auctionID: UInt64, amount: UFix64, to: Address)
	
	// AuctionItem contains the Resources and metadata for a single auction
	access(all)
	resource AuctionItem{ 
		
		//Number of bids made, that is aggregated to the status struct
		access(self)
		var numberOfBids: UInt64
		
		//The Item that is sold at this auction
		access(self)
		var NFT: @Collectible.NFT?
		
		//This is the escrow vault that holds the tokens for the current largest bid
		access(self)
		let bidVault: @FUSD.Vault
		
		//The id of this individual auction
		access(all)
		let auctionID: UInt64
		
		//The minimum increment for a bid. This is an english auction style system where bids increase
		access(self)
		let minimumBidIncrement: UFix64
		
		//the time the auction should start at
		access(self)
		var auctionStartTime: UFix64
		
		//the start time for bids
		access(self)
		var auctionStartBidTime: UFix64
		
		//The length in seconds for this auction
		access(self)
		var auctionLength: UFix64
		
		//The period of time to extend auction
		access(self)
		var extendedLength: UFix64
		
		//The period of time of rest to extend
		access(self)
		var remainLengthToExtend: UFix64
		
		//Right now the dropitem is not moved from the collection when it ends, it is just marked here that it has ended 
		access(self)
		var auctionCompleted: Bool
		
		//Start price
		access(account)
		var startPrice: UFix64
		
		//Current price
		access(self)
		var currentPrice: UFix64
		
		//the capability that points to the resource where you want the NFT transfered to if you win this bid. 
		access(self)
		var recipientCollectionCap: Capability<&{Collectible.CollectionPublic}>?
		
		//the capablity to send the escrow bidVault to if you are outbid
		access(self)
		var recipientVaultCap: Capability<&FUSD.Vault>?
		
		//the vault receive FUSD in case of the recipient of commissiona or the previous bidder are unreachable
		access(self)
		let platformVaultCap: Capability<&FUSD.Vault>
		
		//This action was cancelled
		access(self)
		var auctionCancelled: Bool
		
		// Manage royalty for copies of the same items
		access(self)
		let editionCap: Capability<&{Edition.EditionCollectionPublic}>
		
		init(
			minimumBidIncrement: UFix64,
			auctionStartTime: UFix64,
			startPrice: UFix64,
			auctionStartBidTime: UFix64,
			auctionLength: UFix64,
			extendedLength: UFix64,
			remainLengthToExtend: UFix64,
			platformVaultCap: Capability<&FUSD.Vault>,
			editionCap: Capability<&{Edition.EditionCollectionPublic}>
		){ 
			AuctionV2.totalAuctions = AuctionV2.totalAuctions + 1 as UInt64
			self.NFT <- nil
			self.bidVault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
			self.auctionID = AuctionV2.totalAuctions
			self.minimumBidIncrement = minimumBidIncrement
			self.auctionLength = auctionLength
			self.extendedLength = extendedLength
			self.remainLengthToExtend = remainLengthToExtend
			self.startPrice = startPrice
			self.currentPrice = 0.0
			self.auctionStartTime = auctionStartTime
			self.auctionStartBidTime = auctionStartBidTime
			self.auctionCompleted = false
			self.recipientCollectionCap = nil
			self.recipientVaultCap = nil
			self.platformVaultCap = platformVaultCap
			self.numberOfBids = 0
			self.auctionCancelled = false
			self.editionCap = editionCap
		}
		
		// sendNFT sends the NFT to the Collection belonging to the provided Capability
		access(self)
		fun sendNFT(_ capability: Capability<&{Collectible.CollectionPublic}>){ 
			let nftId = self.NFT?.id!
			if let collectionRef = capability.borrow(){ 
				let NFT <- self.NFT <- nil
				collectionRef.deposit(token: <-NFT!)
				emit SendNFT(auctionID: self.auctionID, nftID: nftId, to: (collectionRef.owner!).address)
				return
			}
			emit FailSendNFT(
				auctionID: self.auctionID,
				nftID: nftId,
				to: (((self.recipientVaultCap!).borrow()!).owner!).address
			)
		}
		
		access(self)
		fun burnNFT(){ 
			if self.NFT == nil{ 
				return
			}
			let nftId = self.NFT?.id!
			let NFT <- self.NFT <- nil
			destroy NFT
			emit BurnNFT(auctionID: self.auctionID, nftID: nftId)
		}
		
		// sendBidTokens sends the bid tokens to the previous bidder
		access(self)
		fun sendBidTokens(_ capability: Capability<&FUSD.Vault>){ 
			// borrow a reference to the prevous bidder's vault
			if let vaultRef = capability.borrow(){ 
				let bidVaultRef = &self.bidVault as &FUSD.Vault
				let balance = bidVaultRef.balance
				if bidVaultRef.balance > 0.0{ 
					vaultRef.deposit(from: <-bidVaultRef.withdraw(amount: balance))
				}
				emit SendBidTokens(auctionID: self.auctionID, amount: balance, to: (vaultRef.owner!).address)
				return
			}
			
			//  platform vault get money in case the previous bidder vault is unreachable
			if let ownerRef = self.platformVaultCap.borrow(){ 
				let bidVaultRef = &self.bidVault as &FUSD.Vault
				let balance = bidVaultRef.balance
				if bidVaultRef.balance > 0.0{ 
					ownerRef.deposit(from: <-bidVaultRef.withdraw(amount: balance))
				}
				emit FailSendBidTokens(auctionID: self.auctionID, amount: balance, to: (ownerRef.owner!).address)
				return
			}
		}
		
		access(self)
		fun releasePreviousBid(){ 
			if let vaultCap = self.recipientVaultCap{ 
				self.sendBidTokens(self.recipientVaultCap!)
				return
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEditionNumber(id: UInt64): UInt64?{ 
			return self.NFT?.editionNumber
		}
		
		access(self)
		fun sendCommissionPayment(){ 
			let editionNumber = self.NFT?.editionNumber!
			let editionRef = self.editionCap.borrow()!
			let editionStatus = editionRef.getEdition(editionNumber)!
			for key in editionStatus.royalty.keys{ 
				if (editionStatus.royalty[key]!).firstSalePercent > 0.0{ 
					let commission = self.currentPrice * (editionStatus.royalty[key]!).firstSalePercent * 0.01
					let account = getAccount(key)
					let vaultCap = account.capabilities.get<&FUSD.Vault>(/public/fusdReceiver)
					if vaultCap.check(){ 
						let vault = vaultCap.borrow()!
						vault.deposit(from: <-self.bidVault.withdraw(amount: commission))
						emit Earned(nftID: self.NFT?.id!, amount: commission, owner: key, type: (editionStatus.royalty[key]!).description)
					} else{ 
						emit FailEarned(nftID: self.NFT?.id!, amount: commission, owner: key, type: (editionStatus.royalty[key]!).description)
					}
				}
			}
			
			// If commission was not paid, this money get platform
			if self.bidVault.balance > 0.0{ 
				let amount = self.bidVault.balance
				let platformVault = self.platformVaultCap.borrow()!
				platformVault.deposit(from: <-self.bidVault.withdraw(amount: amount))
				emit Earned(nftID: self.NFT?.id!, amount: amount, owner: (platformVault.owner!).address, type: "PLATFORM")
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun settleAuction(){ 
			pre{ 
				!self.auctionCancelled:
					"The auction was cancelled"
				!self.auctionCompleted:
					"The auction has been already settled"
				self.NFT != nil:
					"NFT in auction does not exist"
				self.isAuctionExpired():
					"Auction has not completed yet"
			}
			
			// burn token if there are no bids to settle
			if self.currentPrice == 0.0{ 
				self.burnNFT()
				self.auctionCompleted = true
				emit Settled(auctionID: self.auctionID, price: self.currentPrice)
				return
			}
			self.sendCommissionPayment()
			self.sendNFT(self.recipientCollectionCap!)
			self.auctionCompleted = true
			emit Settled(auctionID: self.auctionID, price: self.currentPrice)
		}
		
		//this can be negative if is expired
		access(TMP_ENTITLEMENT_OWNER)
		view fun timeRemaining(): Fix64{ 
			if self.auctionStartBidTime > 0.0 && self.numberOfBids == 0{ 
				return 0.0
			}
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
				return self.currentPrice + self.currentPrice * self.minimumBidIncrement * 0.01
			}
			
			//else start Collectible price
			return self.startPrice
		}
		
		access(self)
		fun extendAuction(){ 
			if			   //Auction time left is less than remainLengthToExtend
			   self.timeRemaining() < Fix64(self.remainLengthToExtend)
			//This is not the first bid in the reserve auction
			&& (
				self.auctionStartBidTime == 0.0
				|| self.auctionStartBidTime > 0.0 && self.numberOfBids > 1
			){ 
				self.auctionLength = self.auctionLength + self.extendedLength
				emit Extend(
					auctionID: self.auctionID,
					auctionLengthFrom: self.auctionLength - self.extendedLength,
					auctionLengthTo: self.auctionLength
				)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun bidder(): Address?{ 
			if let vaultCap = self.recipientVaultCap{ 
				// Check possible situation, where vault was unlinked after bid
				// Test this case in automated test
				if !vaultCap.check(){ 
					return nil
				}
				return ((vaultCap.borrow()!).owner!).address
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
			bidTokens: @FUSD.Vault,
			vaultCap: Capability<&FUSD.Vault>,
			collectionCap: Capability<&{Collectible.CollectionPublic}>
		){ 
			pre{ 
				vaultCap.check():
					"Fungible token storage is not initialized on account"
				collectionCap.check():
					"NFT storage is not initialized on account"
				!self.auctionCancelled:
					"Auction was cancelled"
				self.NFT != nil:
					"NFT in auction does not exist"
				self.auctionStartTime < getCurrentBlock().timestamp || self.auctionStartTime == 0.0:
					"The auction has not started yet"
				!self.isAuctionExpired():
					"Time expired"
				bidTokens.balance <= 999999.99:
					"Bid should be less than 1 000 000.00"
				self.auctionStartBidTime < getCurrentBlock().timestamp || self.auctionStartBidTime == 0.0:
					"The auction bid time has not started yet"
			}
			let bidderAddress = ((vaultCap.borrow()!).owner!).address
			let collectionAddress = ((collectionCap.borrow()!).owner!).address
			if bidderAddress != collectionAddress{ 
				panic("you cannot make a bid and send the Collectible to somebody else collection")
			}
			let amountYouAreBidding =
				bidTokens.balance + self.currentBidForUser(address: bidderAddress)
			let minNextBid = self.minNextBid()
			if amountYouAreBidding < minNextBid{ 
				panic("Bid is less than min acceptable")
			}
			
			// The first bid sets start auction time if auctionStartTime is not defined
			if self.bidVault.balance == 0.0 && self.auctionStartTime == 0.0{ 
				self.auctionStartTime = getCurrentBlock().timestamp
				emit SetStartTime(auctionID: self.auctionID, startAuctionTime: self.auctionStartTime)
			}
			if self.bidder() != bidderAddress{ 
				if self.bidVault.balance != 0.0{ 
					// Return the previous bid 
					self.sendBidTokens(self.recipientVaultCap!)
				}
			}
			
			// Update the bidVault to store the current bid
			self.bidVault.deposit(from: <-bidTokens)
			
			//update the capability of the wallet for the address with the current highest bid
			self.recipientVaultCap = vaultCap
			
			// Update the current price of the token
			self.currentPrice = self.bidVault.balance
			
			// Add the bidder's Vault and NFT receiver references
			self.recipientCollectionCap = collectionCap
			self.numberOfBids = self.numberOfBids + 1 as UInt64
			
			// Extend auction according to time left and extened length
			self.extendAuction()
			emit Bid(
				auctionID: self.auctionID,
				bidderAddress: bidderAddress,
				bidPrice: self.currentPrice,
				placedAt: Fix64(getCurrentBlock().timestamp)
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(): AuctionStatus{ 
			var leader: Address? = nil
			if let recipient = self.recipientVaultCap{ 
				leader = ((recipient.borrow()!).owner!).address
			}
			return AuctionStatus(
				id: self.auctionID,
				currentPrice: self.currentPrice,
				bids: self.numberOfBids,
				active: !self.auctionCompleted && !self.isAuctionExpired(),
				timeRemaining: self.timeRemaining(),
				metadata: self.NFT?.metadata,
				collectibleId: self.NFT?.id,
				leader: leader,
				bidIncrement: self.minimumBidIncrement,
				startTime: Fix64(self.auctionStartTime),
				startBidTime: Fix64(self.auctionStartBidTime),
				endTime: self.auctionStartTime > 0.0
					? Fix64(self.auctionStartTime + self.auctionLength)
					: Fix64(0.0),
				minNextBid: self.minNextBid(),
				completed: self.auctionCompleted,
				expired: self.isAuctionExpired(),
				cancelled: self.auctionCancelled,
				currentLength: self.auctionLength
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelAuction(){ 
			pre{ 
				!self.auctionCancelled:
					"The auction has been already cancelled"
				!self.auctionCompleted:
					"The auction was settled"
			}
			self.releasePreviousBid()
			self.burnNFT()
			self.auctionCancelled = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addNFT(NFT: @Collectible.NFT){ 
			pre{ 
				self.NFT == nil:
					"NFT in auction has already existed"
			}
			let nftID = NFT.id
			self.NFT <-! NFT
			emit AddNFT(auctionID: self.auctionID, nftID: nftID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reclaimSendNFT(collectionCap: Capability<&{Collectible.CollectionPublic}>){ 
			pre{ 
				self.auctionCompleted:
					"The auction has not been settled yet"
				self.NFT != nil:
					"NFT in auction does not exist"
			}
			self.sendNFT(collectionCap)
		}
	}
	
	// AuctionCollectionPublic is a resource interface that restricts users to
	// retreiving the auction price list and placing bids
	access(all)
	resource interface AuctionCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatuses():{ UInt64: AuctionV2.AuctionStatus}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(_ id: UInt64): AuctionStatus?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTimeLeft(_ id: UInt64): Fix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun placeBid(
			id: UInt64,
			bidTokens: @FUSD.Vault,
			vaultCap: Capability<&FUSD.Vault>,
			collectionCap: Capability<&{Collectible.CollectionPublic}>
		)
	}
	
	// AuctionCollection contains a dictionary of AuctionItems and provides
	// methods for manipulating the AuctionItems
	access(all)
	resource AuctionCollection: AuctionCollectionPublic{ 
		
		// Auction Items
		access(account)
		var auctionItems: @{UInt64: AuctionItem}
		
		init(){ 
			self.auctionItems <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun keys(): [UInt64]{ 
			return self.auctionItems.keys
		}
		
		// addTokenToAuctionItems adds an NFT to the auction items and sets the meta data
		// for the auction item
		access(TMP_ENTITLEMENT_OWNER)
		fun createAuction(minimumBidIncrement: UFix64, auctionLength: UFix64, extendedLength: UFix64, remainLengthToExtend: UFix64, auctionStartTime: UFix64, startPrice: UFix64, startBidTime: UFix64, platformVaultCap: Capability<&FUSD.Vault>, editionCap: Capability<&{Edition.EditionCollectionPublic}>): UInt64{ 
			pre{ 
				auctionLength > 0.00:
					"Auction lenght should be more than 0.00"
				auctionStartTime > getCurrentBlock().timestamp || auctionStartTime == 0.0:
					"Auction start time can't be in the past"
				startPrice > 0.00:
					"Start price should be more than 0.00"
				startPrice <= 999999.99:
					"Start bid should be less than 1 000 000.00"
				minimumBidIncrement > 0.00:
					"Minimum bid increment should be more than 0.00"
				platformVaultCap.check():
					"Platform vault should be reachable"
				startBidTime > getCurrentBlock().timestamp || startBidTime == 0.0:
					"Auction start bid time can't be in the past"
				(startBidTime == 0.0 && auctionStartTime == 0.0) == false:
					"Start bid time and auction start time can't equal 0.0 both"
				(startBidTime > 0.0 && auctionStartTime > 0.0) == false:
					"Start bid time and auction start time can't be more than 0.0 both"
			}
			
			// create a new auction items resource container
			let item <- create AuctionItem(minimumBidIncrement: minimumBidIncrement, auctionStartTime: auctionStartTime, startPrice: startPrice, auctionStartBidTime: startBidTime, auctionLength: auctionLength, extendedLength: extendedLength, remainLengthToExtend: remainLengthToExtend, platformVaultCap: platformVaultCap, editionCap: editionCap)
			let id = item.auctionID
			
			// update the auction items dictionary with the new resources
			let oldItem <- self.auctionItems[id] <- item
			destroy oldItem
			let owner = ((platformVaultCap.borrow()!).owner!).address
			emit Created(auctionID: id, owner: owner, startPrice: startPrice, startTime: auctionStartTime, auctionLength: auctionLength, startBidTime: startBidTime)
			return id
		}
		
		// getAuctionPrices returns a dictionary of available NFT IDs with their current price
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatuses():{ UInt64: AuctionStatus}{ 
			if self.auctionItems.keys.length == 0{ 
				return{} 
			}
			let priceList:{ UInt64: AuctionStatus} ={} 
			for id in self.auctionItems.keys{ 
				let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
				priceList[id] = itemRef.getAuctionStatus()
			}
			return priceList
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAuctionStatus(_ id: UInt64): AuctionStatus?{ 
			if self.auctionItems[id] == nil{ 
				return nil
			}
			
			// Get the auction item resources
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			return itemRef.getAuctionStatus()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTimeLeft(_ id: UInt64): Fix64?{ 
			if self.auctionItems[id] == nil{ 
				return nil
			}
			
			// Get the auction item resources
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			return itemRef.timeRemaining()
		}
		
		// settleAuction sends the auction item to the highest bidder
		// and deposits the FungibleTokens into the auction owner's account
		access(TMP_ENTITLEMENT_OWNER)
		fun settleAuction(_ id: UInt64){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist"
			}
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			itemRef.settleAuction()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelAuction(_ id: UInt64){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist"
			}
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			itemRef.cancelAuction()
			emit Canceled(auctionID: id)
		}
		
		// placeBid sends the bidder's tokens to the bid vault and updates the
		// currentPrice of the current auction item
		access(TMP_ENTITLEMENT_OWNER)
		fun placeBid(id: UInt64, bidTokens: @FUSD.Vault, vaultCap: Capability<&FUSD.Vault>, collectionCap: Capability<&{Collectible.CollectionPublic}>){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist in this drop"
			}
			
			// Get the auction item resources
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			itemRef.placeBid(bidTokens: <-bidTokens, vaultCap: vaultCap, collectionCap: collectionCap)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addNFT(id: UInt64, NFT: @Collectible.NFT){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist"
			}
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			itemRef.addNFT(NFT: <-NFT)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reclaimSendNFT(id: UInt64, collectionCap: Capability<&{Collectible.CollectionPublic}>){ 
			pre{ 
				self.auctionItems[id] != nil:
					"Auction does not exist"
			}
			let itemRef = &self.auctionItems[id] as &AuctionV2.AuctionItem?
			itemRef.reclaimSendNFT(collectionCap: collectionCap)
		}
	}
	
	// createAuctionCollection returns a new AuctionCollection resource to the caller
	access(self)
	fun createAuctionCollection(): @AuctionCollection{ 
		let auctionCollection <- create AuctionCollection()
		return <-auctionCollection
	}
	
	init(){ 
		self.totalAuctions = 10 as UInt64
		self.CollectionPublicPath = /public/NFTXtinglesBloctoAuctionV2
		self.CollectionStoragePath = /storage/NFTXtinglesBloctoAuctionV2
		let sale <- AuctionV2.createAuctionCollection()
		self.account.storage.save(<-sale, to: AuctionV2.CollectionStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{AuctionV2.AuctionCollectionPublic}>(
				AuctionV2.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: AuctionV2.CollectionPublicPath)
	}
}
