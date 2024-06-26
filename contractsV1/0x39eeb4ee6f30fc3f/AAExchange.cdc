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

	import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import AACollectionManager from "./AACollectionManager.cdc"

import AACurrencyManager from "./AACurrencyManager.cdc"

import AAFeeManager from "./AAFeeManager.cdc"

import AAReferralManager from "./AAReferralManager.cdc"

import AACommon from "./AACommon.cdc"

// A wrapper of NFTStorefront
access(all)
contract AAExchange{ 
	access(contract)
	let affiliateAmounts:{ UInt64: UFix64}
	
	access(all)
	event ListingAvailable(
		storefrontAddress: Address,
		listingResourceID: UInt64,
		nftType: Type,
		nftID: UInt64,
		ftVaultType: Type,
		price: UFix64,
		payments: [
			AACommon.Payment
		]
	)
	
	access(all)
	event ListingCancelled(
		storefrontAddress: Address,
		listingResourceID: UInt64,
		nftType: Type,
		nftID: UInt64
	)
	
	access(all)
	event ListingPurchased(
		storefrontAddress: Address,
		listingResourceID: UInt64,
		nftType: Type,
		nftID: UInt64,
		paymentType: Type,
		price: UFix64,
		buyer: Address,
		cuts: [
			CutPaid
		]
	)
	
	access(all)
	struct CutPaid{ 
		access(all)
		let to: Address
		
		access(all)
		let amount: UFix64
		
		init(to: Address, amount: UFix64){ 
			self.to = to
			self.amount = amount
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun listForSale(
		store: &NFTStorefront.Storefront,
		nftProviderCapability: Capability<
			&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
		>,
		nftType: Type,
		nftID: UInt64,
		salePaymentVaultType: Type,
		listingPrice: UFix64,
		minimumRequire: UFix64
	){ 
		pre{ 
			listingPrice > 0.0:
				"Cannot list a NFT for 0.0"
			AACurrencyManager.isCurrencyAccepted(type: salePaymentVaultType):
				"Payment type is not allow"
		}
		let storeAddress = (store.owner!).address
		let saleCuts: [NFTStorefront.SaleCut] = []
		let payments: [AACommon.Payment] = []
		var ownerAmount = listingPrice
		var percentage = 1.0
		let path = AACurrencyManager.getPath(type: salePaymentVaultType)
		assert(path != nil, message: "Currency path not setting")
		let id = getCurrentBlock().id
		let salePaymentPath = (path!).publicPath
		let addPayment = fun (type: String, recipient: Address, rate: UFix64, amount: UFix64?){ 
				var cutAmount = amount
				if amount == nil{ 
					cutAmount = rate * listingPrice
				}
				percentage = percentage - rate
				ownerAmount = ownerAmount - cutAmount!
				let recipientCap = getAccount(recipient).capabilities.get<&{FungibleToken.Receiver}>(salePaymentPath)
				assert(recipientCap.borrow() != nil, message: "Missing or mis-typed fungible token receiver")
				let payment = AACommon.Payment(type: type, recipient: recipient, rate: rate, amount: cutAmount!)
				let saleCut = NFTStorefront.SaleCut(receiver: recipientCap!, amount: cutAmount!)
				if amount != nil && payments.length > 0{ 
					payments.insert(at: 0, payment)
					saleCuts.insert(at: 0, saleCut)
					return
				}
				payments.append(payment)
				saleCuts.append(saleCut)
			}
		let referrer = AAReferralManager.referrerOf(owner: storeAddress)
		let cuts =
			AAFeeManager.getPlatformCuts(
				referralReceiver: referrer,
				affiliate: self.account.address
			)
			?? []
		let itemCuts = AAFeeManager.getPaymentCuts(type: nftType, nftID: nftID)
		cuts.appendAll(itemCuts)
		if let collectionCuts = AACollectionManager.getCollectionCuts(type: nftType, nftID: nftID){ 
			cuts.appendAll(collectionCuts)
		}
		for cut in cuts{ 
			addPayment(type: cut.type, recipient: cut.recipient, rate: cut.rate, amount: nil)
		}
		assert(ownerAmount >= minimumRequire, message: "Minimum require not pass")
		addPayment(type: "Reward", recipient: storeAddress, rate: percentage, ownerAmount)
		let listingResourceID =
			store.createListing(
				nftProviderCapability: nftProviderCapability,
				nftType: nftType,
				nftID: nftID,
				salePaymentVaultType: salePaymentVaultType,
				saleCuts: saleCuts
			)
		self.affiliateAmounts[listingResourceID] = AAFeeManager.affiliateRate * listingPrice
		emit ListingAvailable(
			storefrontAddress: storeAddress,
			listingResourceID: listingResourceID,
			nftType: nftType,
			nftID: nftID,
			ftVaultType: salePaymentVaultType,
			price: listingPrice,
			payments: payments
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun acceptListing(
		store: &NFTStorefront.Storefront,
		listingResourceID: UInt64,
		payment: @{FungibleToken.Vault},
		receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>,
		affiliate: Address?
	){ 
		let listing =
			store.borrowListing(listingResourceID: listingResourceID)
			?? panic("No Listing with that ID in the store")
		let nft <- listing.purchase(payment: <-payment)
		let details = listing.getDetails()
		AAFeeManager.markAsPurchased(type: details.nftType, nftID: details.nftID)
		let cuts: [CutPaid] = []
		for saleCut in details.saleCuts{ 
			cuts.append(CutPaid(to: saleCut.receiver.address, amount: saleCut.amount))
		}
		let recipient =
			receiverCap.borrow() ?? panic("Collection to receive NFT not setup correctly")
		recipient.deposit(token: <-nft)
		let affiliateAmount = self.affiliateAmounts[listingResourceID]!
		AAFeeManager.paidAffiliateFee(
			paymentType: details.salePaymentVaultType,
			affiliate: affiliate,
			amount: affiliateAmount
		)
		store.cleanup(listingResourceID: listingResourceID)
		self.affiliateAmounts.remove(key: listingResourceID)
		emit ListingPurchased(
			storefrontAddress: (store.owner!).address,
			listingResourceID: listingResourceID,
			nftType: details.nftType,
			nftID: details.nftID,
			paymentType: details.salePaymentVaultType,
			price: details.salePrice,
			buyer: receiverCap.address,
			cuts: cuts
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun cancelListing(store: &NFTStorefront.Storefront, listingResourceID: UInt64){ 
		let listing =
			store.borrowListing(listingResourceID: listingResourceID)
			?? panic("No Listing with that ID in the store")
		let details = listing.getDetails()
		assert(!details.purchased, message: "Listing already purchased")
		store.removeListing(listingResourceID: listingResourceID)
		self.affiliateAmounts.remove(key: listingResourceID)
		emit ListingCancelled(
			storefrontAddress: (store.owner!).address,
			listingResourceID: listingResourceID,
			nftType: details.nftType,
			nftID: details.nftID
		)
	}
	
	init(){ 
		self.affiliateAmounts ={} 
	}
}
