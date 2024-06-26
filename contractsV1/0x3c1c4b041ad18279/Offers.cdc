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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import LostAndFound from "../0x473d6a2c37eab5be/LostAndFound.cdc"

import ScopedFTProviders from "./ScopedFTProviders.cdc"

import NFTStorefrontV2 from "./../../standardsV1/NFTStorefrontV2.cdc"

import Filter from "./Filter.cdc"

import FlowtyUtils from "../0x3cdbb3d569211ff3/FlowtyUtils.cdc"

import FlowtyListingCallback from "../0x3cdbb3d569211ff3/FlowtyListingCallback.cdc"

import DNAHandler from "../0x3cdbb3d569211ff3/DNAHandler.cdc"

access(all)
contract Offers{ 
	access(all)
	let OffersStoragePath: StoragePath
	
	access(all)
	let OffersPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	// Events
	access(all)
	event StorefrontInitialized(storefrontResourceID: UInt64)
	
	access(all)
	event OfferCancelled(storefrontAddress: Address?, offerResourceID: UInt64)
	
	access(all)
	event OfferCompleted(storefrontAddress: Address?, offerResourceID: UInt64)
	
	access(all)
	event OfferCreated(
		storefrontAddress: Address,
		offerResourceID: UInt64,
		offeredAmount: UFix64,
		paymentTokenType: String,
		numAcceptable: Int,
		expiry: UInt64,
		taker: Address?,
		payer: Address
	)
	
	access(all)
	event OfferAccepted(
		storefrontAddress: Address,
		offerResourceID: UInt64,
		offeredAmount: UFix64,
		paymentTokenType: String,
		numAcceptable: Int,
		remaining: Int,
		taker: Address,
		nftID: UInt64,
		nftType: String
	)
	
	access(all)
	event FilterTypeAdded(type: Type)
	
	access(all)
	event FilterTypeRemoved(type: Type)
	
	access(all)
	event MissingReceiver(receiver: Address, amount: UFix64)
	
	access(all)
	resource interface StorefrontPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOffer(offerResourceID: UInt64): &Offers.Offer?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun acceptOffer(
			offerResourceID: UInt64,
			nft: @{NonFungibleToken.NFT},
			receiver: Capability<&{FungibleToken.Receiver}>
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanupOffer(_ id: UInt64)
		
		access(contract)
		fun adminRemoveListing(offerResourceID: UInt64)
	}
	
	access(all)
	resource Storefront: StorefrontPublic{ 
		access(self)
		let offers: @{UInt64: Offer}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createOffer(offeredAmount: UFix64, paymentTokenType: Type, filterGroup: Filter.FilterGroup, expiry: UInt64, numAcceptable: Int, taker: Address?, paymentProvider: Capability<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>, nftReceiver: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			pre{ 
				paymentProvider.check():
					"payment provider is invalid"
				nftReceiver.check():
					"nftReceiver is invalid"
				Offers.validateFilterGroup(filterGroup):
					"invalid filter provided"
				filterGroup.filters.length == 1:
					"filter group must be a length of one filter"
			}
			
			// wrap out FT provider to keep it safe!
			// the provider should expire after when the offer expires, and it should only be
			// permitted to withdraw (offeredAmount * numAcceptable) tokens
			let allowance = ScopedFTProviders.AllowanceFilter(offeredAmount * UFix64(numAcceptable))
			let scopedProvider <- ScopedFTProviders.createScopedFTProvider(provider: paymentProvider, filters: [allowance], expiration: UFix64(expiry))
			let paymentTokenType = scopedProvider.getProviderType()
			let commission = NFTStorefrontV2.getFee(p: offeredAmount, t: paymentTokenType)
			let offer <- create Offer(offeredAmount: offeredAmount, paymentTokenType: paymentTokenType, commission: commission, filterGroup: filterGroup, expiry: expiry, numAcceptable: numAcceptable, taker: taker, paymentProvider: <-scopedProvider, nftReceiver: nftReceiver)
			emit OfferCreated(storefrontAddress: (self.owner!).address, offerResourceID: offer.uuid, offeredAmount: offeredAmount, paymentTokenType: paymentTokenType.identifier, numAcceptable: numAcceptable, expiry: expiry, taker: taker, payer: paymentProvider.address)
			if let callback = Offers.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Created, listing: &offer as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			self.offers[offer.uuid] <-! offer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun acceptOffer(offerResourceID: UInt64, nft: @{NonFungibleToken.NFT}, receiver: Capability<&{FungibleToken.Receiver}>){ 
			let offer = &self.offers[offerResourceID] as &Offer? ?? panic("offer not found")
			let nftType = nft.getType()
			let nftID = nft.id
			emit OfferAccepted(storefrontAddress: (self.owner!).address, offerResourceID: offer.uuid, offeredAmount: offer.details.offeredAmount, paymentTokenType: offer.details.paymentTokenType.identifier, numAcceptable: offer.details.numAcceptable, remaining: offer.details.remaining - 1, taker: receiver.address, nftID: nft.id, nftType: nftType.identifier)
			offer.acceptOffer(nft: <-nft, receiver: receiver)
			if offer.details.remaining < 1{ 
				emit OfferCompleted(storefrontAddress: (self.owner!).address, offerResourceID: offer.uuid)
				let o <- self.offers.remove(key: offerResourceID)!
				if let callback = Offers.borrowCallbackContainer(){ 
					callback.handle(stage: FlowtyListingCallback.Stage.Completed, listing: &o as &{FlowtyListingCallback.Listing}, nft: nil)
					callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &o as &{FlowtyListingCallback.Listing}, nft: nil)
				}
				destroy o
			}
			
			// clean up any listings that belong to this NFT on the NFTStorefront as well
			let cap = getAccount(receiver.address).capabilities.get<&NFTStorefrontV2.Storefront>(NFTStorefrontV2.StorefrontPublicPath)
			if cap.check(){ 
				let s = cap.borrow()!
				var existingListingIDs = s.getExistingListingIDs(nftType: nftType, nftID: nftID)
				for listingID in existingListingIDs{ 
					s.cleanupInvalidListing(listingResourceID: listingID)
				}
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cancelOffer(offerResourceID: UInt64){ 
			let offer <- self.offers.remove(key: offerResourceID) ?? panic("no offer with that resource ID")
			emit OfferCancelled(storefrontAddress: self.owner?.address, offerResourceID: offer.uuid)
			if let callback = Offers.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Destroyed, listing: &offer as &{FlowtyListingCallback.Listing}, nft: nil)
			}
			destroy offer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun cleanupOffer(_ id: UInt64){ 
			pre{ 
				self.offers.containsKey(id):
					"offer does not exist"
			}
			let offer <- self.offers.remove(key: id) ?? panic("offer not found")
			assert(!offer.isValid(), message: "cannot cleanup offers that are still valid")
			emit OfferCancelled(storefrontAddress: (self.owner!).address, offerResourceID: offer.uuid)
			destroy offer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowOffer(offerResourceID: UInt64): &Offer?{ 
			return &self.offers[offerResourceID] as &Offer?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.offers.keys
		}
		
		access(contract)
		fun adminRemoveListing(offerResourceID: UInt64){ 
			pre{ 
				self.offers[offerResourceID] != nil:
					"could not find listing with given id"
			}
			let offer <- self.offers.remove(key: offerResourceID) ?? panic("missing offer")
			emit OfferCancelled(storefrontAddress: (self.owner!).address, offerResourceID: offer.uuid)
			let offerDetails = offer.getDetails()
			destroy offer
		}
		
		init(){ 
			self.offers <-{} 
			emit StorefrontInitialized(storefrontResourceID: self.uuid)
		}
	}
	
	access(all)
	struct OfferCut{} 
	
	access(all)
	struct Details{ 
		access(all)
		let offerResourceID: UInt64
		
		access(all)
		let offeredAmount: UFix64
		
		access(all)
		let paymentTokenType: Type
		
		access(all)
		let filterGroup: Filter.FilterGroup
		
		access(all)
		let expiry: UInt64
		
		// Only provide for private offers
		access(all)
		let taker: Address?
		
		// how many times can this offer be accepted
		access(all)
		let numAcceptable: Int
		
		access(all)
		var remaining: Int
		
		// generated by offer creation
		access(all)
		let commission: UFix64
		
		init(
			offerResourceID: UInt64,
			offeredAmount: UFix64,
			paymentTokenType: Type,
			commission: UFix64,
			filterGroup: Filter.FilterGroup,
			expiry: UInt64,
			numAcceptable: Int,
			taker: Address?
		){ 
			pre{ 
				numAcceptable > 0:
					"must be acceptable at least once"
			}
			self.offerResourceID = offerResourceID
			self.offeredAmount = offeredAmount
			self.paymentTokenType = paymentTokenType
			self.filterGroup = filterGroup
			self.expiry = expiry
			self.commission = commission
			self.taker = taker
			self.numAcceptable = numAcceptable
			self.remaining = numAcceptable
		}
		
		access(contract)
		fun decrementRemaining(){ 
			pre{ 
				self.remaining > 0:
					"cannot decrement below 0"
			}
			self.remaining = self.remaining - 1
		}
	}
	
	access(all)
	resource interface OfferPublic{ 
		access(contract)
		fun acceptOffer(
			nft: @{NonFungibleToken.NFT},
			receiver: Capability<&{FungibleToken.Receiver}>
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): Offers.Details
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isValid(): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isMatch(_ nft: &{NonFungibleToken.NFT}): Bool
	}
	
	access(all)
	resource Offer: OfferPublic, FlowtyListingCallback.Listing{ 
		access(contract)
		let details: Details
		
		access(contract)
		let provider: @ScopedFTProviders.ScopedFTProvider
		
		access(contract)
		let receiver: Capability<&{NonFungibleToken.CollectionPublic}>
		
		access(contract)
		fun acceptOffer(nft: @{NonFungibleToken.NFT}, receiver: Capability<&{FungibleToken.Receiver}>){ 
			pre{ 
				self.details.filterGroup.match(nft: &nft as &{NonFungibleToken.NFT}):
					"nft does not pass filter check"
				self.details.taker == nil || receiver.address == self.details.taker:
					"this offer is meant for a private taker"
				self.isValid():
					"offer is not valid"
			}
			let fees = NFTStorefrontV2.getPaymentCuts(r: receiver, n: &nft as &{NonFungibleToken.NFT}, p: self.details.offeredAmount, tokenType: self.details.paymentTokenType)
			let mpFee = NFTStorefrontV2.getFee(p: self.details.offeredAmount, t: self.details.paymentTokenType)
			let payment <- self.provider.withdraw(amount: self.details.offeredAmount)
			assert(payment.getType() == self.details.paymentTokenType, message: "mismatched payment token type")
			assert(payment.balance == self.details.offeredAmount, message: "mismatched payment amount")
			let depositor = Offers.account.storage.borrow<&LostAndFound.Depositor>(from: LostAndFound.DepositorStoragePath)!
			let mpPayment <- payment.withdraw(amount: mpFee)
			let mpReceiver = NFTStorefrontV2.getCommissionReceiver(t: self.details.paymentTokenType)
			(mpReceiver.borrow()!).deposit(from: <-mpPayment)
			for f in fees{ 
				let paymentCut <- payment.withdraw(amount: f.amount)
				FlowtyUtils.trySendFungibleTokenVault(vault: <-paymentCut, receiver: f.receiver, depositor: depositor)
			}
			if payment.balance > 0.0{ 
				// send whatever is left to the maker who is the last receiver
				FlowtyUtils.trySendFungibleTokenVault(vault: <-payment, receiver: fees[fees.length - 1].receiver, depositor: depositor)
			} else{ 
				destroy payment
			}
			if let callback = Offers.borrowCallbackContainer(){ 
				callback.handle(stage: FlowtyListingCallback.Stage.Filled, listing: &self as &{FlowtyListingCallback.Listing}, nft: &nft as &{NonFungibleToken.NFT})
			}
			self.details.decrementRemaining()
			(self.receiver.borrow()!).deposit(token: <-nft)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isMatch(_ nft: &{NonFungibleToken.NFT}): Bool{ 
			return self.details.filterGroup.match(nft: nft)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): Details{ 
			return self.details
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isValid(): Bool{ 
			if !self.provider.check(){ 
				return false
			}
			if !self.provider.canWithdraw(self.details.offeredAmount){ 
				return false
			}
			if self.details.remaining < 1{ 
				return false
			}
			if UInt64(getCurrentBlock().timestamp) > self.details.expiry{ 
				return false
			}
			return true
		}
		
		init(offeredAmount: UFix64, paymentTokenType: Type, commission: UFix64, filterGroup: Filter.FilterGroup, expiry: UInt64, numAcceptable: Int, taker: Address?, paymentProvider: @ScopedFTProviders.ScopedFTProvider, nftReceiver: Capability<&{NonFungibleToken.CollectionPublic}>){ 
			self.details = Details(offerResourceID: self.uuid, offeredAmount: offeredAmount, paymentTokenType: paymentTokenType, commission: commission, filterGroup: filterGroup, expiry: expiry, numAcceptable: numAcceptable, taker: taker)
			self.provider <- paymentProvider
			self.receiver = nftReceiver
		}
	}
	
	access(all)
	resource interface AdminPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		view fun isValidFilter(_ t: Type): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFilters():{ Type: Bool}
	}
	
	access(all)
	resource interface AdminCleaner{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun removeOffer(storefrontAddress: Address, offerResourceID: UInt64): Void
	}
	
	access(all)
	resource Admin: AdminPublic, AdminCleaner{ 
		access(all)
		let permittedFilters:{ Type: Bool}
		
		init(){ 
			self.permittedFilters ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPermittedFilter(_ t: Type){ 
			pre{ 
				t.isSubtype(of: Type<{Filter.NFTFilter}>())
			}
			self.permittedFilters[t] = true
			emit FilterTypeAdded(type: t)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFilter(_ t: Type){ 
			if let removedType = self.permittedFilters.remove(key: t){ 
				emit FilterTypeRemoved(type: t)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isValidFilter(_ t: Type): Bool{ 
			return self.permittedFilters[t] != nil && self.permittedFilters[t]!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFilters():{ Type: Bool}{ 
			return self.permittedFilters
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeOffer(storefrontAddress: Address, offerResourceID: UInt64){ 
			let acct = getAccount(storefrontAddress)
			let storefront = acct.capabilities.get<&Storefront>(Offers.OffersPublicPath)
			(storefront.borrow()!).adminRemoveListing(offerResourceID: offerResourceID)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getValidFilters():{ Type: Bool}{ 
		return Offers.borrowPublicAdmin().getFilters()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createStorefront(): @Storefront{ 
		return <-create Storefront()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun borrowPublicAdmin(): &Admin{ 
		return self.account.storage.borrow<&Admin>(from: Offers.AdminStoragePath)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun validateFilterGroup(_ fg: Filter.FilterGroup): Bool{ 
		let a = Offers.borrowPublicAdmin()
		for f in fg.filters{ 
			if !a.isValidFilter(f.getType()){ 
				return false
			}
		}
		return true
	}
	
	access(contract)
	fun borrowCallbackContainer(): &FlowtyListingCallback.Container?{ 
		return self.account.storage.borrow<&FlowtyListingCallback.Container>(
			from: FlowtyListingCallback.ContainerStoragePath
		)
	}
	
	init(){ 
		self.OffersStoragePath = StoragePath(
				identifier: "Offers".concat(self.account.address.toString())
			)!
		self.OffersPublicPath = PublicPath(
				identifier: "Offers".concat(self.account.address.toString())
			)!
		self.AdminPublicPath = /public/offersAdmin
		self.AdminStoragePath = /storage/offersAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		if self.account.storage.borrow<&AnyResource>(
			from: FlowtyListingCallback.ContainerStoragePath
		)
		== nil{ 
			let dnaHandler <- DNAHandler.createHandler()
			let listingHandler <-
				FlowtyListingCallback.createContainer(defaultHandler: <-dnaHandler)
			self.account.storage.save(
				<-listingHandler,
				to: FlowtyListingCallback.ContainerStoragePath
			)
		}
	}
}
