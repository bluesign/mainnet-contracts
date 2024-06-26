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

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

// Offers
//
// Contract holds the Offer resource and a public method to create them.
//
// Each Offer can have one or more royalties of the sale price that
// goes to one or more addresses.
//
// Owners of NFT can watch for OfferAvailable events and check
// the Offer amount to see if they wish to accept the offer.
//
// Marketplaces and other aggregators can watch for OfferAvailable events
// and list offers of interest to logged in users.
//
access(all)
contract Offers{ 
	// OfferAvailable
	// An Offer has been created and added to the users DapperOffer resource.
	//
	access(all)
	event OfferAvailable(
		offerAddress: Address,
		offerId: UInt64,
		nftType: Type,
		nftId: UInt64,
		offerAmount: UFix64,
		royalties:{ 
			Address: UFix64
		}
	)
	
	// OfferCompleted
	// The Offer has been resolved. The offer has either been accepted
	//  by the NFT owner, or the offer has been removed and destroyed.
	//
	access(all)
	event OfferCompleted(
		offerId: UInt64,
		nftType: Type,
		nftId: UInt64,
		purchased: Bool,
		acceptingAddress: Address?
	)
	
	// Royalty
	// A struct representing a recipient that must be sent a certain amount
	// of the payment when a NFT is sold.
	//
	access(all)
	struct Royalty{ 
		access(all)
		let receiver: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let amount: UFix64
		
		init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64){ 
			self.receiver = receiver
			self.amount = amount
		}
	}
	
	// OfferDetails
	// A struct containing Offers' data.
	//
	access(all)
	struct OfferDetails{ 
		// The ID of the offer
		access(all)
		let offerId: UInt64
		
		// The Type of the NFT
		access(all)
		let nftType: Type
		
		// The ID of the NFT
		access(all)
		let nftId: UInt64
		
		// The Offer amount for the NFT
		access(all)
		let offerAmount: UFix64
		
		// Flag to tracked the purchase state
		access(all)
		var purchased: Bool
		
		// This specifies the division of payment between recipients.
		access(all)
		let royalties: [Royalty]
		
		// setToPurchased
		// Irreversibly set this offer as purchased.
		//
		access(contract)
		fun setToPurchased(){ 
			self.purchased = true
		}
		
		// initializer
		//
		init(
			offerId: UInt64,
			nftType: Type,
			nftId: UInt64,
			offerAmount: UFix64,
			royalties: [
				Royalty
			]
		){ 
			self.offerId = offerId
			self.nftType = nftType
			self.nftId = nftId
			self.offerAmount = offerAmount
			self.purchased = false
			self.royalties = royalties
		}
	}
	
	// OfferPublic
	// An interface providing a useful public interface to an Offer resource.
	//
	access(all)
	resource interface OfferPublic{ 
		// accept
		// This will accept the offer if provided with the NFT id that matches the Offer
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(
			item: @{NonFungibleToken.NFT},
			receiverCapability: Capability<&{FungibleToken.Receiver}>
		): Void
		
		// getDetails
		// Return Offer details
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): OfferDetails
	}
	
	access(all)
	resource Offer: OfferPublic{ 
		// The OfferDetails struct of the Offer
		access(self)
		let details: OfferDetails
		
		// The vault which will handle the payment if the Offer is accepted.
		access(contract)
		let vaultRefCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>
		
		// Receiver address for the NFT when/if the Offer is accepted.
		access(contract)
		let nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>
		
		init(vaultRefCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>, nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>, nftType: Type, nftId: UInt64, amount: UFix64, royalties: [Royalty]){ 
			pre{ 
				nftReceiverCapability.check():
					"reward capability not valid"
			}
			self.vaultRefCapability = vaultRefCapability
			self.nftReceiverCapability = nftReceiverCapability
			var price: UFix64 = amount
			let royaltyInfo:{ Address: UFix64} ={} 
			for royalty in royalties{ 
				assert(royalty.receiver.check(), message: "invalid royalty receiver")
				price = price - royalty.amount
				royaltyInfo[royalty.receiver.address] = royalty.amount
			}
			assert(price > 0.0, message: "price must be > 0")
			self.details = OfferDetails(offerId: self.uuid, nftType: nftType, nftId: nftId, offerAmount: amount, royalties: royalties)
			emit OfferAvailable(offerAddress: nftReceiverCapability.address, offerId: self.details.offerId, nftType: self.details.nftType, nftId: self.details.nftId, offerAmount: self.details.offerAmount, royalties: royaltyInfo)
		}
		
		// accept
		// Accept the offer if...
		// - Calling from an Offer that hasn't been purchased/desetoryed.
		// - Provided with a NFT matching the NFT id within the Offer details.
		// - Provided with a NFT matching the NFT Type within the Offer details.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(item: @{NonFungibleToken.NFT}, receiverCapability: Capability<&{FungibleToken.Receiver}>): Void{ 
			pre{ 
				!self.details.purchased:
					"Offer has already been purchased"
				item.id == self.details.nftId:
					"item NFT does not have specified ID"
				item.isInstance(self.details.nftType):
					"item NFT is not of specified type"
			}
			self.details.setToPurchased()
			(self.nftReceiverCapability.borrow()!).deposit(token: <-item)
			let initalDucSupply = (self.vaultRefCapability.borrow()!).balance
			let payment <- (self.vaultRefCapability.borrow()!).withdraw(amount: self.details.offerAmount)
			
			// Payout royalties
			for royalty in self.details.royalties{ 
				if let receiver = royalty.receiver.borrow(){ 
					let amount = royalty.amount
					let part <- payment.withdraw(amount: amount)
					receiver.deposit(from: <-part)
				}
			}
			(receiverCapability.borrow()!).deposit(from: <-payment)
			
			// If a DUC vault is being used for payment we must assert that no DUC is leaking from the transactions.
			let isDucVault = self.vaultRefCapability.isInstance(Type<Capability<&DapperUtilityCoin.Vault>>())
			if isDucVault{ 
				assert((self.vaultRefCapability.borrow()!).balance == initalDucSupply, message: "DUC is leaking")
			}
			emit OfferCompleted(offerId: self.details.offerId, nftType: self.details.nftType, nftId: self.details.nftId, purchased: self.details.purchased, acceptingAddress: receiverCapability.address)
		}
		
		// getDetails
		// Return Offer details
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): OfferDetails{ 
			return self.details
		}
	}
	
	// makeOffer
	access(TMP_ENTITLEMENT_OWNER)
	fun makeOffer(
		vaultRefCapability: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>,
		nftReceiverCapability: Capability<&{NonFungibleToken.CollectionPublic}>,
		nftType: Type,
		nftId: UInt64,
		amount: UFix64,
		royalties: [
			Royalty
		]
	): @Offer{ 
		let newOfferResource <-
			create Offer(
				vaultRefCapability: vaultRefCapability,
				nftReceiverCapability: nftReceiverCapability,
				nftType: nftType,
				nftId: nftId,
				amount: amount,
				royalties: royalties
			)
		return <-newOfferResource
	}
}
