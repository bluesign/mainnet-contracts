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

	import Melos from "./Melos.cdc"

import MusicBlock from "./MusicBlock.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	This is a simple MusicBlock initial sale contract for the DApp to use
	in order to list and sell MusicBlock.

	Its structure is neither what it would be if it was the simplest possible
	market contract or if it was a complete general purpose market contract.
	Rather it's the simplest possible version of a more general purpose
	market contract that indicates how that contract might function in
	broad strokes. This has been done so that integrating with this contract
	is a useful preparatory exercise for code that will integrate with the
	later more general purpose market contract.

	It allows:
	- Anyone to create Sale Offers and place them in a collection, making it
	  publicly accessible.
	- Anyone to accept the offer and buy the item.

	It notably does not handle:
	- Multiple different sale NFT contracts.
	- Multiple different payment FT contracts.
	- Splitting sale payments to multiple recipients.

 */

access(all)
contract MusicBlockMarket{ 
	// SaleOffer events.
	//
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemID: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemID: UInt64)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(itemID: UInt64)
	
	// Collection events.
	//
	// A sale offer has been removed from the collection of Address.
	access(all)
	event CollectionRemovedSaleOffer(itemID: UInt64, owner: Address)
	
	// A sale offer has been inserted into the collection of Address.
	access(all)
	event CollectionInsertedSaleOffer(itemID: UInt64,													  //   typeID: UInt64, 
													  owner: Address, price: UFix64)
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// SaleOfferPublicView
	// An interface providing a read-only view of a SaleOffer
	//
	access(all)
	resource interface SaleOfferPublicView{ 
		access(all)
		let itemID: UInt64
		
		// pub let typeID: UInt64
		access(all)
		let price: UFix64
	}
	
	// SaleOffer
	// A MusicBlock NFT being offered to sale for a set fee paid in Melos.
	//
	access(all)
	resource SaleOffer: SaleOfferPublicView{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The MusicBlock NFT ID for sale.
		access(all)
		let itemID: UInt64
		
		// The 'type' of NFT
		// pub let typeID: UInt64
		// The sale payment price.
		access(all)
		let price: UFix64
		
		// The collection containing that ID.
		access(self)
		let sellerItemProvider: Capability<&MusicBlock.Collection>
		
		// The Melos vault that will receive that payment if teh sale completes successfully.
		access(self)
		let sellerPaymentReceiver: Capability<&Melos.Vault>
		
		// Called by a purchaser to accept the sale offer.
		// If they send the correct payment in Melos, and if the item is still available,
		// the MusicBlock NFT will be placed in their MusicBlock.Collection .
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(buyerCollection: &MusicBlock.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				buyerPayment.balance == self.price:
					"payment does not equal offer price"
				self.saleCompleted == false:
					"the sale offer has already been accepted"
			}
			self.saleCompleted = true
			(self.sellerPaymentReceiver.borrow()!).deposit(from: <-buyerPayment)
			let nft <- (self.sellerItemProvider.borrow()!).withdraw(withdrawID: self.itemID)
			buyerCollection.deposit(token: <-nft)
			emit SaleOfferAccepted(itemID: self.itemID)
		}
		
		// destructor
		//
		// initializer
		// Take the information required to create a sale offer, notably the capability
		// to transfer the MusicBlock NFT and the capability to receive Melos in payment.
		//
		// typeID: UInt64,
		init(sellerItemProvider: Capability<&MusicBlock.Collection>, itemID: UInt64, sellerPaymentReceiver: Capability<&Melos.Vault>, price: UFix64){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow seller"
				sellerPaymentReceiver.borrow() != nil:
					"Cannot borrow sellerPaymentReceiver"
			}
			self.saleCompleted = false
			let collectionRef = sellerItemProvider.borrow()!
			assert(collectionRef.borrowMusicBlock(id: itemID) != nil, message: "Specified NFT is not available in the owner's collection")
			self.sellerItemProvider = sellerItemProvider
			self.itemID = itemID
			self.sellerPaymentReceiver = sellerPaymentReceiver
			self.price = price
			// self.typeID = typeID
			emit SaleOfferCreated(itemID: self.itemID, price: self.price)
		}
	}
	
	// createSaleOffer
	// Make creating a SaleOffer publicly accessible.
	// typeID: UInt64,
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleOffer(
		sellerItemProvider: Capability<&MusicBlock.Collection>,
		itemID: UInt64,
		sellerPaymentReceiver: Capability<&Melos.Vault>,
		price: UFix64
	): @SaleOffer{ 
		return <-create SaleOffer(
			sellerItemProvider: sellerItemProvider,
			itemID: itemID,
			sellerPaymentReceiver: sellerPaymentReceiver,
			price: price
		)
	}
	
	// CollectionManager
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner.
	//
	access(all)
	resource interface CollectionManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun insert(offer: @MusicBlockMarket.SaleOffer): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun remove(itemID: UInt64): @SaleOffer
	}
	
	// CollectionPurchaser
	// An interface to allow purchasing items via SaleOffers in a collection.
	// This function is also provided by CollectionPublic, it is here to support
	// more fine-grained access to the collection for as yet unspecified future use cases.
	//
	access(all)
	resource interface CollectionPurchaser{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(
			itemID: UInt64,
			buyerCollection: &MusicBlock.Collection,
			buyerPayment: @{FungibleToken.Vault}
		): Void
	}
	
	// CollectionPublic
	// An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection.
	//
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleItem(itemID: UInt64): &SaleOffer?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(
			itemID: UInt64,
			buyerCollection: &MusicBlock.Collection,
			buyerPayment: @{FungibleToken.Vault}
		)
	}
	
	// Collection
	// A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them.
	//
	access(all)
	resource Collection: CollectionManager, CollectionPurchaser, CollectionPublic{ 
		access(all)
		var saleOffers: @{UInt64: SaleOffer}
		
		// insert
		// Insert a SaleOffer into the collection, replacing one with the same itemID if present.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun insert(offer: @MusicBlockMarket.SaleOffer){ 
			let itemID: UInt64 = offer.itemID
			// let typeID: UInt64 = offer.typeID
			let price: UFix64 = offer.price
			
			// add the new offer to the dictionary which removes the old one
			let oldOffer <- self.saleOffers[itemID] <- offer
			destroy oldOffer
			emit CollectionInsertedSaleOffer(itemID: itemID,															 //   typeID: typeID,
															 owner: self.owner?.address!, price: price)
		}
		
		// remove
		// Remove and return a SaleOffer from the collection.
		access(TMP_ENTITLEMENT_OWNER)
		fun remove(itemID: UInt64): @SaleOffer{ 
			emit CollectionRemovedSaleOffer(itemID: itemID, owner: self.owner?.address!)
			return <-(self.saleOffers.remove(key: itemID) ?? panic("missing SaleOffer"))
		}
		
		// purchase
		// If the caller passes a valid itemID and the item is still for sale, and passes a Melos vault
		// typed as a FungibleToken.Vault (Melos.deposit() handles the type safety of this)
		// containing the correct payment amount, this will transfer the MusicBlock to the caller's
		// MusicBlock collection.
		// It will then remove and destroy the offer.
		// Note that is means that events will be emitted in this order:
		//   1. Collection.CollectionRemovedSaleOffer
		//   2. MusicBlock.Withdraw
		//   3. MusicBlock.Deposit
		//   4. SaleOffer.SaleOfferFinished
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(itemID: UInt64, buyerCollection: &MusicBlock.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				self.saleOffers[itemID] != nil:
					"SaleOffer does not exist in the collection!"
			}
			let offer <- self.remove(itemID: itemID)
			offer.accept(buyerCollection: buyerCollection, buyerPayment: <-buyerPayment)
			//FIXME: Is this correct? Or should we return it to the caller to dispose of?
			destroy offer
		}
		
		// getSaleOfferIDs
		// Returns an array of the IDs that are in the collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIDs(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		// borrowSaleItem
		// Returns an Optional read-only view of the SaleItem for the given itemID if it is contained by this collection.
		// The optional will be nil if the provided itemID is not present in the collection.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleItem(itemID: UInt64): &SaleOffer?{ 
			if self.saleOffers[itemID] == nil{ 
				return nil
			} else{ 
				return &self.saleOffers[itemID] as &MusicBlockMarket.SaleOffer?
			}
		}
		
		// destructor
		//
		// constructor
		//
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	// createEmptyCollection
	// Make creating a Collection publicly accessible.
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	init(){ 
		//FIXME: REMOVE SUFFIX BEFORE RELEASE
		self.CollectionStoragePath = /storage/MusicBlockMarketCollection
		self.CollectionPublicPath = /public/MusicBlockMarketCollection
	}
}
