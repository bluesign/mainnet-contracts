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

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import AACommon from "./AACommon.cdc"

import AACollectionManager from "./AACollectionManager.cdc"

import AACurrencyManager from "./AACurrencyManager.cdc"

import AAFeeManager from "./AAFeeManager.cdc"

import AAReferralManager from "./AAReferralManager.cdc"

access(all)
contract AAOpenBid{ 
	access(all)
	event AAOpenBidInitialized()
	
	access(all)
	event OpenBidInitialized(openBidResourceID: UInt64)
	
	access(all)
	event OpenBidDestroyed(openBidResourceID: UInt64)
	
	access(all)
	event BidAvailable(
		openBidAddress: Address,
		bidResourceID: UInt64,
		nftType: Type,
		nftID: UInt64,
		ftVaultType: Type,
		price: UFix64
	)
	
	access(all)
	event BidCompleted(
		bidResourceID: UInt64,
		openBidResourceID: UInt64,
		purchased: Bool,
		nftType: Type,
		nftID: UInt64,
		payments: [
			AACommon.Payment
		]?
	)
	
	// OpenBidStoragePath
	// The location in storage that a OpenBid resource should be located.
	access(all)
	let OpenBidStoragePath: StoragePath
	
	// OpenBidPublicPath
	// The public location for a OpenBid link.
	access(all)
	let OpenBidPublicPath: PublicPath
	
	// SaleCut
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a token is sold.
	//
	access(all)
	struct SaleCut{ 
		// The receiver for the payment.
		// Note that we do not store an address to find the Vault that this represents,
		// as the link or resource that we fetch in this way may be manipulated,
		// so to find the address that a cut goes to you must get this struct and then
		// call receiver.borrow()!.owner.address on it.
		// This can be done efficiently in a script.
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		// The amount of the payment FungibleToken that will be paid to the receiver.
		access(all)
		let amount: UFix64
		
		// initializer
		//
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	// BidDetails
	// A struct containing a Bid's data.
	//
	access(all)
	struct BidDetails{ 
		// The OpenBid that the Bid is stored in.
		// Note that this resource cannot be moved to a different OpenBid,
		// so this is OK. If we ever make it so that it *can* be moved,
		// this should be revisited.
		access(all)
		var openBidID: UInt64
		
		// Whether this listing has been purchased or not.
		access(all)
		var purchased: Bool
		
		// The Type of the NonFungibleToken.NFT that is being listed.
		access(all)
		let nftType: Type
		
		// The ID of the NFT within that type.
		access(all)
		let nftID: UInt64
		
		// The Type of the FungibleToken that payments must be made in.
		access(all)
		let salePaymentVaultType: Type
		
		// The amount that must be paid in the specified FungibleToken.
		access(all)
		let bidPrice: UFix64
		
		// The address of referral user
		access(all)
		let affiliate: Address?
		
		// setToPurchased
		// Irreversibly set this listing as purchased.
		//
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
		}
		
		// initializer
		//
		init(
			openBidID: UInt64,
			nftType: Type,
			nftID: UInt64,
			salePaymentVaultType: Type,
			bidPrice: UFix64,
			affiliate: Address?
		){ 
			self.openBidID = openBidID
			self.purchased = false
			self.nftType = nftType
			self.nftID = nftID
			self.salePaymentVaultType = salePaymentVaultType
			self.affiliate = affiliate
			assert(bidPrice > 0.0, message: "Bid must have non-zero price")
			self.bidPrice = bidPrice
		}
	}
	
	// BidPublic
	// An interface providing a useful public interface to a Bid.
	//
	access(all)
	resource interface BidPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): AAOpenBid.BidDetails
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(nftProviderCapability: Capability<&{NonFungibleToken.Provider}>)
	}
	
	access(all)
	resource Bid: BidPublic{ 
		// The simple (non-Capability, non-complex) details of the sale
		access(self)
		let details: BidDetails
		
		access(self)
		let vaultProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance}>
		
		access(self)
		let recipientCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		// getDetails
		// Get the details of the current state of the Bid as a struct.
		// This avoids having more public variables and getter methods for them, and plays
		// nicely with scripts (which cannot return resources). 
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): BidDetails{ 
			return self.details
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(nftProviderCapability: Capability<&{NonFungibleToken.Provider}>){ 
			pre{ 
				self.details.purchased == false:
					"listing has already been purchased"
			}
			let nft <- (nftProviderCapability.borrow()!).withdraw(withdrawID: self.details.nftID)
			assert(nft.isInstance(self.details.nftType), message: "NFT is not of specified type")
			assert(nft.id == self.details.nftID, message: "NFT does not have specified ID")
			let seller = nftProviderCapability.address
			
			// Make sure the listing cannot be purchased again.
			self.details.setToPurchased()
			(			 
			 // Send item to bidder
			 self.recipientCapability.borrow()!).deposit(token: <-nft)
			
			// Pay each beneficiary their amount of the payment.
			let path = AACurrencyManager.getPath(type: self.details.salePaymentVaultType)
			assert(path != nil, message: "Currency Path not setting")
			let cap = fun (_ addr: Address): Capability<&{FungibleToken.Receiver}>{ 
					return getAccount(addr).capabilities.get<&{FungibleToken.Receiver}>((path!).publicPath)!
				}
			let payment <- (self.vaultProviderCapability.borrow()!).withdraw(amount: self.details.bidPrice)
			let cuts = AAOpenBid.getSaleCuts(seller: seller, nftType: self.details.nftType, nftID: self.details.nftID, affiliate: self.details.affiliate)
			let payments: [AACommon.Payment] = []
			var rate = 1.0
			for cut in cuts{ 
				if let receiver = cap(cut.recipient).borrow(){ 
					rate = rate - cut.rate
					let amount = cut.rate * self.details.bidPrice
					let paymentCut <- payment.withdraw(amount: amount)
					receiver.deposit(from: <-paymentCut)
					payments.append(AACommon.Payment(type: cut.type, recipient: cut.recipient, rate: cut.rate, amount: amount))
				}
			}
			payments.append(AACommon.Payment(type: "Seller Earn", recipient: seller, rate: rate, amount: payment.balance))
			let sellerRecipient = cap(seller).borrow() ?? panic("Seller vault broken")
			sellerRecipient.deposit(from: <-payment)
			AAFeeManager.markAsPurchased(type: self.details.nftType, nftID: self.details.nftID)
			
			// If the bid is purchased, we regard it as completed here.
			// Otherwise we regard it as completed in the destructor.		
			emit BidCompleted(bidResourceID: self.uuid, openBidResourceID: self.details.openBidID, purchased: self.details.purchased, nftType: self.details.nftType, nftID: self.details.nftID, payments: payments)
		}
		
		// initializer
		//
		init(vaultProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance}>, nftType: Type, nftID: UInt64, bidPrice: UFix64, recipientCapability: Capability<&{NonFungibleToken.CollectionPublic}>, affiliate: Address?){ 
			let vaultRef = vaultProviderCapability.borrow() ?? panic("vault ref broken")
			assert(AACurrencyManager.isCurrencyAccepted(type: vaultRef.getType()), message: "Currency not accepted")
			
			// Store the sale information
			self.details = BidDetails(openBidID: self.uuid, nftType: nftType, nftID: nftID, salePaymentVaultType: vaultRef.getType(), bidPrice: bidPrice, affiliate: affiliate)
			self.vaultProviderCapability = vaultProviderCapability
			self.recipientCapability = recipientCapability
			let collection = self.recipientCapability.borrow()
			assert(collection != nil, message: "cannot borrow collection recipient")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSaleCuts(seller: Address, nftType: Type, nftID: UInt64, affiliate: Address?): [
		AACommon.PaymentCut
	]{ 
		let referrer = AAReferralManager.referrerOf(owner: seller)
		let cuts =
			AAFeeManager.getPlatformCuts(referralReceiver: referrer, affiliate: affiliate) ?? []
		let itemCuts = AAFeeManager.getPaymentCuts(type: nftType, nftID: nftID)
		cuts.appendAll(itemCuts)
		if let collectionCuts = AACollectionManager.getCollectionCuts(type: nftType, nftID: nftID){ 
			cuts.appendAll(collectionCuts)
		}
		return cuts
	}
	
	// OpenBidManager
	// An interface for adding and removing Bids within a OpenBid,
	// intended for use by the OpenBid's own
	//
	access(all)
	resource interface OpenBidManager{ 
		// createBid
		// Allows the OpenBid owner to create and insert Bid.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createBid(
			vaultProviderCapability: Capability<
				&{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance}
			>,
			nftType: Type,
			nftID: UInt64,
			bidPrice: UFix64,
			recipientCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
			affiliate: Address?
		): UInt64
		
		// Allows the OpenBid owner to remove any bid, purchased or not.
		access(TMP_ENTITLEMENT_OWNER)
		fun removeBid(bidResourceID: UInt64)
	}
	
	access(all)
	resource interface OpenBidPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getBidIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBid(bidResourceID: UInt64): &Bid?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanup(bidResourceID: UInt64)
	}
	
	// OpenBid
	// A resource that allows its owner to manage a list of Bids, and anyone to interact with them
	// in order to query their details and purchase the NFTs that they represent.
	//
	access(all)
	resource OpenBid: OpenBidManager, OpenBidPublic{ 
		// The dictionary of Bid uuids to Bid resources.
		access(self)
		var bids: @{UInt64: Bid}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createBid(vaultProviderCapability: Capability<&{FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance}>, nftType: Type, nftID: UInt64, bidPrice: UFix64, recipientCapability: Capability<&{NonFungibleToken.CollectionPublic}>, affiliate: Address?): UInt64{ 
			let bid <- create Bid(vaultProviderCapability: vaultProviderCapability, nftType: nftType, nftID: nftID, bidPrice: bidPrice, recipientCapability: recipientCapability, affiliate: affiliate)
			let bidResourceID = bid.uuid
			let vaultType = bid.getDetails().salePaymentVaultType
			
			// Add the new listing to the dictionary.
			let oldBid <- self.bids[bidResourceID] <- bid
			// Note that oldBid will always be nil, but we have to handle it.
			destroy oldBid
			emit BidAvailable(openBidAddress: self.owner?.address!, bidResourceID: bidResourceID, nftType: nftType, nftID: nftID, ftVaultType: vaultType, price: bidPrice)
			return bidResourceID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeBid(bidResourceID: UInt64){ 
			let bid <- self.bids.remove(key: bidResourceID) ?? panic("missing Bid")
			
			// This will emit a BidCompleted event.
			destroy bid
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBidIDs(): [UInt64]{ 
			return self.bids.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBid(bidResourceID: UInt64): &Bid?{ 
			if self.bids[bidResourceID] != nil{ 
				return (&self.bids[bidResourceID] as &Bid?)!
			} else{ 
				return nil
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanup(bidResourceID: UInt64){ 
			pre{ 
				self.bids[bidResourceID] != nil:
					"could not find listing with given id"
			}
			let bid <- self.bids.remove(key: bidResourceID)!
			assert(bid.getDetails().purchased == true, message: "listing is not purchased, only admin can remove")
			destroy bid
		}
		
		init(){ 
			self.bids <-{} 
			
			// Let event consumers know that this openBid exists
			emit OpenBidInitialized(openBidResourceID: self.uuid)
		}
	}
	
	// createOpenBid
	// Make creating a OpenBid publicly accessible.
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createOpenBid(): @OpenBid{ 
		return <-create OpenBid()
	}
	
	init(){ 
		self.OpenBidStoragePath = /storage/AAOpenBid
		self.OpenBidPublicPath = /public/AAOpenBid
		emit AAOpenBidInitialized()
	}
}
