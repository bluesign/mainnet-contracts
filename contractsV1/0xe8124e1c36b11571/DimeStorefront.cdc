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

	/* SPDX-License-Identifier: UNLICENSED */
import DimeCollectible from "../0xf5cdaace879e5a79/DimeCollectible.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	This contract allows:
	- Anyone to create Sale Offers and place them in their storefront, making it
	  publicly accessible.
	- Anyone to accept the offer and buy the item.
	- The Dime admin account to accept offers without transferring tokens
 */

access(all)
contract DimeStorefront{ 
	
	// SaleOffer events
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemId: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemId: UInt64)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(itemId: UInt64)
	
	// A sale offer has been removed from the collection of Address.
	access(all)
	event SaleOfferRemoved(itemId: UInt64, owner: Address)
	
	// A sale offer has been inserted into the collection of Address.
	access(all)
	event SaleOfferAdded(
		itemId: UInt64,
		creator: Address,
		content: String,
		owner: Address,
		price: UFix64
	)
	
	// Named paths
	access(all)
	let StorefrontStoragePath: StoragePath
	
	access(all)
	let StorefrontPublicPath: PublicPath
	
	// An interface providing a read-only view of a SaleOffer
	access(all)
	resource interface SaleOfferPublic{ 
		access(all)
		let itemId: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let content: String
		
		access(all)
		var price: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getHistory(): [[AnyStruct]]
	}
	
	// A DimeCollectible NFT being offered to sale for a set fee
	access(all)
	resource SaleOffer: SaleOfferPublic{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The NFT for sale.
		access(all)
		let itemId: UInt64
		
		access(all)
		let creator: Address
		
		access(all)
		let content: String
		
		access(all)
		var price: UFix64
		
		access(self)
		let history: [[AnyStruct]]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getHistory(): [[AnyStruct]]{ 
			return self.history
		}
		
		// The vault that will be paid when the item is purchased.
		// This isn't used right now since FUSD payments are not enabled,
		// but keeping for future compatibility
		access(self)
		let receiver: Capability<&FUSD.Vault>
		
		// The fraction of the price that goes to Dime
		access(all)
		let dimeRoyalty: UFix64
		
		// The fraction of the price that goes to the original creator
		access(all)
		let creatorRoyalty: UFix64
		
		// The collection containing that ID.
		access(self)
		let sellerItemProvider: Capability<&DimeCollectible.Collection>
		
		// Take the information required to create a sale offer
		init(sellerItemProvider: Capability<&DimeCollectible.Collection>, itemId: UInt64, creator: Address, content: String, price: UFix64, history: [[AnyStruct]], receiver: Capability<&FUSD.Vault>){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow collection from seller"
			}
			self.saleCompleted = false
			let collectionRef = sellerItemProvider.borrow()!
			self.sellerItemProvider = sellerItemProvider
			self.itemId = itemId
			self.price = price
			self.creator = creator
			self.content = content
			self.history = history
			self.receiver = receiver
			self.creatorRoyalty = 0.01
			self.dimeRoyalty = 0.01
			emit SaleOfferCreated(itemId: self.itemId, price: self.price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPrice(newPrice: UFix64){ 
			self.price = newPrice
		}
	}
	
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner
	access(all)
	resource interface StorefrontManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createSaleOffer(
			sellerItemProvider: Capability<&DimeCollectible.Collection>,
			itemId: UInt64,
			creator: Address,
			content: String,
			price: UFix64,
			history: [
				[
					AnyStruct
				]
			],
			receiver: Capability<&FUSD.Vault>
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleOffer(itemId: UInt64, beingPurchased: Bool)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(itemId: UInt64, newPrice: UFix64)
	}
	
	// An interface to allow listing and borrowing SaleOffers, and purchasing items via SaleOffers in a collection
	access(all)
	resource interface StorefrontPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIds(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleOffer(itemId: UInt64): &SaleOffer?
	}
	
	// A resource that allows its owner to manage a list of SaleOffers, and purchasers to interact with them
	access(all)
	resource Storefront: StorefrontManager, StorefrontPublic{ 
		access(self)
		var saleOffers: @{UInt64: SaleOffer}
		
		// Returns an array of the Ids that are in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIds(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		// Returns an Optional read-only view of the SaleItem for the given itemId if it is contained by this collection.
		// The optional will be nil if the provided itemId is not present in the collection.
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleOffer(itemId: UInt64): &SaleOffer?{ 
			if self.saleOffers[itemId] == nil{ 
				return nil
			}
			return &self.saleOffers[itemId] as &DimeStorefront.SaleOffer?
		}
		
		// Insert a SaleOffer into the collection, replacing one with the same itemId if present
		access(TMP_ENTITLEMENT_OWNER)
		fun createSaleOffer(sellerItemProvider: Capability<&DimeCollectible.Collection>, itemId: UInt64, creator: Address, content: String, price: UFix64, history: [[AnyStruct]], receiver: Capability<&FUSD.Vault>){ 
			let nft = (sellerItemProvider.borrow()!).borrowCollectible(id: itemId) ?? panic("Couldn't borrow nft from seller")
			if !nft.tradeable{ 
				panic("Tried to put an untradeable token on sale")
			}
			let newOffer <- create SaleOffer(sellerItemProvider: sellerItemProvider, itemId: itemId, creator: creator, content: content, price: price, history: history, receiver: receiver)
			
			// Add the new offer to the dictionary, overwriting an old one if it exists
			let oldOffer <- self.saleOffers[itemId] <- newOffer
			destroy oldOffer
			emit SaleOfferAdded(itemId: itemId, creator: creator, content: content, owner: self.owner?.address!, price: price)
		}
		
		// Remove and return a SaleOffer from the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleOffer(itemId: UInt64, beingPurchased: Bool){ 
			let offer <- self.saleOffers.remove(key: itemId) ?? panic("missing SaleOffer")
			if beingPurchased{ 
				emit SaleOfferAccepted(itemId: itemId)
			} else{ 
				emit SaleOfferRemoved(itemId: itemId, owner: self.owner?.address!)
			}
			destroy offer
		}
		
		access(contract)
		fun push(offer: @SaleOffer){ 
			let oldOffer <- self.saleOffers[offer.itemId] <- offer
			destroy oldOffer
		}
		
		access(contract)
		fun pop(itemId: UInt64): @SaleOffer?{ 
			let offer <- self.saleOffers.remove(key: itemId)
			return <-offer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changePrice(itemId: UInt64, newPrice: UFix64){ 
			pre{ 
				self.saleOffers[itemId] != nil:
					"Tried to change price of an item that's not on sale"
			}
			let offer <- self.pop(itemId: itemId)!
			offer.setPrice(newPrice: newPrice)
			self.push(offer: <-offer)
		}
		
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	// Make creating a Storefront publicly accessible.
	access(TMP_ENTITLEMENT_OWNER)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	init(){ 
		self.StorefrontStoragePath = /storage/DimeStorefrontCollection
		self.StorefrontPublicPath = /public/DimeStorefrontCollection
	}
}
