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

	/*
	DarkCountryMarket.cdc

	Description: Contract definitions for users to sell and buy their DarkCountry NFTs

	authors: Ivan Kravets evan@dapplica.io

	Marketplace is where users can create a sale collection that they
	store in their account storage. In the sale collection,
	they can put their NFTs up for sale with a price and publish a
	reference so that others can see the sale.

	If another user sees an NFT that they want to buy,
	they can send fungible tokens that equal or exceed the buy price
	to buy the NFT. The NFT is transferred to them when
	they make the purchase.

	Each user who wants to sell NFTs will have a sale collection
	instance in their account that holds the NFTs that they are putting up for sale

	They can give a reference to this collection to a central contract
	so that it can list the sales in a central place

	When a user creates a sale, they will supply four arguments:
	- A DarkCountry.Collection capability that allows their sale to withdraw
	  a NFT when it is purchased.
	- A FungibleToken.Receiver capability as the place where the payment for the token goes.
	- Item ID as the identifier of the item for sale
	- Price of the item for sale

	DarkCountry Market has smart contract level setting that are managed by an account with Admin resource.
	Such setting are as follows:
	- beneficiaryCapability: A FungibleToken.Receiver capability specifying a beneficiary,
		where a cut of the purchase gets sent.
	- cutPercentage: A cut percentage, specifying how much the beneficiary will recieve.
	- preOrders: A dictionary of Adress to {ItemTemplate : number of preordered items} mapping that indicates
		how many items of a specific Item Template are resevred for the Address


	Only Admins can create sale offers wich can be used in pre-sales only. Such offers can not be accepted by users
	that do not have records in the preOrders. Once such sale is accepted, the preOrders value is adjusted accordingly.

*/

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import DarkCountry from "./DarkCountry.cdc"

import DarkCountryStaking from "./DarkCountryStaking.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DarkCountryMarket{ 
	// SaleOffer events.
	//
	// A sale offer has been created.
	access(all)
	event SaleOfferCreated(itemID: UInt64, price: UFix64)
	
	// Someone has purchased an item that was offered for sale.
	access(all)
	event SaleOfferAccepted(itemID: UInt64, buyerAddress: Address)
	
	// A sale offer has been destroyed, with or without being accepted.
	access(all)
	event SaleOfferFinished(itemID: UInt64)
	
	// A sale offer has been removed from the collection of Address.
	access(all)
	event CollectionRemovedSaleOffer(itemID: UInt64, owner: Address)
	
	// A sale offer has been inserted into the collection of Address.
	access(all)
	event CollectionInsertedSaleOffer(
		itemID: UInt64,
		itemTemplateID: UInt64,
		owner: Address,
		price: UFix64
	)
	
	// emitted when the cut percentage has been changed by the DarkCountry Market admin
	// the same cut percentage value is used for the all sales within the market
	access(all)
	event CutPercentageChanged(newPercent: UFix64)
	
	// emitted when a user's pre orders have been changed by the DarkCountry Market admin
	access(all)
	event PreOrderChanged(userAddress: Address, newPreOrders:{ UInt64: UInt64})
	
	// Named paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// The capability that is used for depositing
	// the beneficiary's cut of every sale
	// The beneficiary is set at the Dark Country Market level by the Market's admin and be the same
	// for all the DarkCountry NFTs
	access(account)
	var beneficiaryCapability: Capability
	
	// The percentage that is taken from every purchase for the beneficiary
	// For example, if the percentage is 15%, cutPercentage = 0.15
	// The percentage cut is set at the Dark Country Market level by the Market's admin and be the same
	// for all the DarkCountry NFTs
	access(all)
	var cutPercentage: UFix64
	
	// Pre Orders for a drop. Optional.
	// Indicates how many NFTs of a certain Item Template booked for a user.
	// The Admin resource manages the data.
	// Note: We do not make it as a resource that can be stored in user's storage
	// since the pre-order might be requested off chain
	access(account)
	var preOrders:{ Address:{ UInt64: UInt64}}
	
	// SaleOfferPublicView
	// An interface providing a read-only view of a SaleOffer
	//
	access(all)
	resource interface SaleOfferPublicView{ 
		access(all)
		let itemID: UInt64
		
		access(all)
		let itemTemplateID: UInt64
		
		access(all)
		let price: UFix64
	}
	
	// SaleOffer
	// A DarkCountry NFT being offered to sale for a set fee paid in FlowToken.
	//
	access(all)
	resource SaleOffer: SaleOfferPublicView{ 
		// Whether the sale has completed with someone purchasing the item.
		access(all)
		var saleCompleted: Bool
		
		// The DarkCountry NFT ID for sale.
		access(all)
		let itemID: UInt64
		
		// The Item Template of NFT
		access(all)
		let itemTemplateID: UInt64
		
		// The sale payment price.
		access(all)
		let price: UFix64
		
		// Indicates if the Sale for pre-ordered items only
		// That means only buyers that pre-ordered corresponding item can accept the offer
		// Only account with the Admin resource can create such sales
		access(all)
		let isPreOrdersOnly: Bool
		
		// The collection containing that ID.
		access(self)
		let sellerItemProvider: Capability<&DarkCountry.Collection>
		
		// The FlowToken vault that will receive that payment if the sale completes successfully.
		access(self)
		let sellerPaymentReceiver: Capability<&FlowToken.Vault>
		
		// Called by a purchaser to accept the sale offer.
		// If they send the correct payment in FlowToken, and if the item is still available,
		// the DarkCountry NFT will be placed in their DarkCountry.Collection
		// If the sale offer is for pre ordered items only,
		// the preOrders dictionary is checked for a corresponding record
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun accept(buyerCollection: &DarkCountry.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				buyerPayment.balance == self.price:
					"payment does not equal offer price"
				self.saleCompleted == false:
					"the sale offer has already been accepted"
			}
			let buyerAccount = buyerCollection.owner ?? panic("Could not get buyer address during accepting the pre sale")
			
			// Check if the sale is for pre-ordered items only
			if self.isPreOrdersOnly == true{ 
				let buyerPreOrders = DarkCountryMarket.preOrders[buyerAccount.address] ??{} 
				let preOrderedCount = buyerPreOrders[self.itemTemplateID] ?? 0 as UInt64
				if preOrderedCount < 1 as UInt64{ 
					panic("Could not find pre ordered items")
				}
				buyerPreOrders[self.itemTemplateID] = preOrderedCount - 1 as UInt64
				DarkCountryMarket.preOrders[buyerAccount.address] = buyerPreOrders
			}
			self.saleCompleted = true
			
			// Take the cut of the tokens that the beneficiary gets from the sent tokens
			let beneficiaryCut <- buyerPayment.withdraw(amount: self.price * DarkCountryMarket.cutPercentage)
			(			 
			 // Deposit it into the beneficiary's Vault
			 DarkCountryMarket.beneficiaryCapability.borrow<&{FungibleToken.Receiver}>()!).deposit(from: <-beneficiaryCut)
			(			 
			 // Deposit the remaining tokens into the seller's vault
			 self.sellerPaymentReceiver.borrow()!).deposit(from: <-buyerPayment)
			let nft <- (self.sellerItemProvider.borrow()!).withdraw(withdrawID: self.itemID)
			buyerCollection.deposit(token: <-nft)
			emit SaleOfferAccepted(itemID: self.itemID, buyerAddress: buyerAccount.address)
		}
		
		// destructor
		//
		// initializer
		// Take the information required to create a sale offer, notably the capability
		// to transfer the DarkCountry NFT and the capability to receive FlowToken in payment.
		//
		init(sellerItemProvider: Capability<&DarkCountry.Collection>, itemID: UInt64, sellerPaymentReceiver: Capability<&FlowToken.Vault>, price: UFix64, isPreOrdersOnly: Bool){ 
			pre{ 
				sellerItemProvider.borrow() != nil:
					"Cannot borrow seller"
				sellerPaymentReceiver.borrow() != nil:
					"Cannot borrow sellerPaymentReceiver"
			}
			let saleOwner = (sellerItemProvider.borrow()!).owner!
			let collectionBorrow = (saleOwner.capabilities.get<&{DarkCountry.DarkCountryCollectionPublic}>(DarkCountry.CollectionPublicPath)!).borrow() ?? panic("Could not borrow DarkCountryCollectionPublic")
			
			// borrow a reference to a specific NFT in the collection
			let nft = collectionBorrow.borrowDarkCountryNFT(id: itemID) ?? panic("No such itemID in that collection")
			
			// make sure the NFT is not staked
			if DarkCountryStaking.stakedItems.containsKey(nft.owner?.address!) && (DarkCountryStaking.stakedItems[nft.owner?.address!]!).contains(itemID){ 
				panic("Cannot withdraw: the NFT is staked.")
			}
			self.itemTemplateID = nft.itemTemplateID
			self.saleCompleted = false
			self.sellerItemProvider = sellerItemProvider
			self.itemID = itemID
			self.sellerPaymentReceiver = sellerPaymentReceiver
			self.price = price
			self.isPreOrdersOnly = isPreOrdersOnly
			emit SaleOfferCreated(itemID: self.itemID, price: self.price)
		}
	}
	
	// createSaleOffer
	// Make creating a SaleOffer publicly accessible.
	//
	// NOTE: the function will be private in the initial release of the market smart contract
	// 
	access(TMP_ENTITLEMENT_OWNER)
	fun createSaleOffer(
		sellerItemProvider: Capability<&DarkCountry.Collection>,
		itemID: UInt64,
		sellerPaymentReceiver: Capability<&FlowToken.Vault>,
		price: UFix64
	): @SaleOffer{ 
		return <-create SaleOffer(
			sellerItemProvider: sellerItemProvider,
			itemID: itemID,
			sellerPaymentReceiver: sellerPaymentReceiver,
			price: price,
			isPreOrdersOnly: false
		)
	}
	
	// CollectionManager
	// An interface for adding and removing SaleOffers to a collection, intended for
	// use by the collection's owner.
	//
	access(all)
	resource interface CollectionManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun insert(offer: @DarkCountryMarket.SaleOffer): Void
		
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
			buyerCollection: &DarkCountry.Collection,
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
			buyerCollection: &DarkCountry.Collection,
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
		fun insert(offer: @DarkCountryMarket.SaleOffer){ 
			let itemID: UInt64 = offer.itemID
			let itemTemplateID: UInt64 = offer.itemTemplateID
			let price: UFix64 = offer.price
			
			// add the new offer to the dictionary which removes the old one
			let oldOffer <- self.saleOffers[itemID] <- offer
			destroy oldOffer
			emit CollectionInsertedSaleOffer(itemID: itemID, itemTemplateID: itemTemplateID, owner: self.owner?.address!, price: price)
		}
		
		// remove
		// Remove and return a SaleOffer from the collection.
		access(TMP_ENTITLEMENT_OWNER)
		fun remove(itemID: UInt64): @SaleOffer{ 
			emit CollectionRemovedSaleOffer(itemID: itemID, owner: self.owner?.address!)
			return <-(self.saleOffers.remove(key: itemID) ?? panic("missing SaleOffer"))
		}
		
		// purchase
		// If the caller passes a valid itemID and the item is still for sale, and passes a FlowToken vault
		// typed as a FungibleToken.Vault (FlowToken.deposit() handles the type safety of this)
		// containing the correct payment amount, this will transfer the KittyItem to the caller's
		// DarkCountry collection.
		// It will then remove and destroy the offer.
		// Note that is means that events will be emitted in this order:
		//   1. Collection.CollectionRemovedSaleOffer
		//   2. DarkCountry.Withdraw
		//   3. DarkCountry.Deposit
		//   4. SaleOffer.SaleOfferFinished
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(itemID: UInt64, buyerCollection: &DarkCountry.Collection, buyerPayment: @{FungibleToken.Vault}){ 
			pre{ 
				self.saleOffers[itemID] != nil:
					"SaleOffer does not exist in the collection!"
			}
			let offer <- self.remove(itemID: itemID)
			offer.accept(buyerCollection: buyerCollection, buyerPayment: <-buyerPayment)
			// We destroy the offer. The purchase history should be tracked off chain
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
				return &self.saleOffers[itemID] as &SaleOffer?
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
	
	// Admin is a special authorization resource that
	// allows the owner to perform functions to modify the following:
	//  1. Beneficiary
	//  2. Beneficiary cut percentage
	//  3. Pre-orders
	access(all)
	resource Admin{ 
		
		// setPercentage changes the cut percentage of the tokens that are for sale
		//
		// Parameters: newPercent: The new cut percentage for the sale
		access(TMP_ENTITLEMENT_OWNER)
		fun setPercentage(_ newPercent: UFix64){ 
			DarkCountryMarket.cutPercentage = newPercent
			emit CutPercentageChanged(newPercent: newPercent)
		}
		
		// setBeneficiaryReceiver updates the capability for the beneficiary of the cut of the sale
		//
		// Parameters: newBeneficiary the new capability for the beneficiary of the cut of the sale
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun setBeneficiaryReceiver(_ newBeneficiaryCapability: Capability){ 
			pre{ 
				newBeneficiaryCapability.borrow<&{FungibleToken.Receiver}>() != nil:
					"Beneficiary's Receiver Capability is invalid!"
			}
			DarkCountryMarket.beneficiaryCapability = newBeneficiaryCapability
		}
		
		// sets pre orders for a user by theirs addresss
		//
		// Parameters: userAddress: The address of the user's account
		// newPreOrders: dictionaty of Item Template and corresponding amount of items that are booked
		access(TMP_ENTITLEMENT_OWNER)
		fun setPreOrdersForAddress(userAddress: Address, newPreOrders:{ UInt64: UInt64}){ 
			DarkCountryMarket.preOrders[userAddress] = newPreOrders
			emit PreOrderChanged(userAddress: userAddress, newPreOrders: newPreOrders)
		}
		
		// createSaleOffer
		// Make creating a SaleOffer publicly accessible.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createPreOrderSaleOffer(
			sellerItemProvider: Capability<&DarkCountry.Collection>,
			itemID: UInt64,
			sellerPaymentReceiver: Capability<&FlowToken.Vault>,
			price: UFix64
		): @SaleOffer{ 
			return <-create SaleOffer(
				sellerItemProvider: sellerItemProvider,
				itemID: itemID,
				sellerPaymentReceiver: sellerPaymentReceiver,
				price: price,
				isPreOrdersOnly: true
			)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/DarkCountryMarketCollection
		self.CollectionPublicPath = /public/DarkCountryMarketCollection
		self.AdminStoragePath = /storage/DarkCountryAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// The default cut percentage value can be changed by Admin
		self.cutPercentage = 0.15 as UFix64
		
		// The default beneficiary capability value can be changed by Admin
		self.beneficiaryCapability = self.account.capabilities.get_<YOUR_TYPE>(
				/public/flowTokenReceiver
			)
		self.preOrders ={} 
	}
}
