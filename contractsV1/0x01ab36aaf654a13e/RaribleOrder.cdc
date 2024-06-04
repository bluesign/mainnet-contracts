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

	import RaribleFee from "../0x336405ad2f289b87/RaribleFee.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

// RaribleOrder
//
// Wraps the NFTStorefront.createListting
//
access(all)
contract RaribleOrder{ 
	access(all)
	let BUYER_FEE: String
	
	access(all)
	let SELLER_FEE: String
	
	access(all)
	let OTHER: String
	
	access(all)
	let ROYALTY: String
	
	access(all)
	let REWARD: String
	
	init(){ 
		// market buyer fee (on top of the price)
		self.BUYER_FEE = "BUYER_FEE"
		
		// market seller fee
		self.SELLER_FEE = "SELLER_FEE"
		
		// additional payments
		self.OTHER = "OTHER"
		
		// royalty
		self.ROYALTY = "ROYALTY"
		
		// seller reward
		self.REWARD = "REWARD"
	}
	
	// PaymentPart
	// 
	access(all)
	struct PaymentPart{ 
		// receiver address
		access(all)
		let address: Address
		
		// payment rate
		access(all)
		let rate: UFix64
		
		init(address: Address, rate: UFix64){ 
			self.address = address
			self.rate = rate
		}
	}
	
	// Payment
	// Describes payment in the event OrderAvailable
	// 
	access(all)
	struct Payment{ 
		// type of payment
		access(all)
		let type: String
		
		// receiver address
		access(all)
		let address: Address
		
		// payment rate
		access(all)
		let rate: UFix64
		
		// payment amount
		access(all)
		let amount: UFix64
		
		init(type: String, address: Address, rate: UFix64, amount: UFix64){ 
			self.type = type
			self.address = address
			self.rate = rate
			self.amount = amount
		}
	}
	
	// OrderAvailable
	// Order created and available for purchase
	// 
	access(all)
	event OrderAvailable(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64, // sum of payment parts
		
		offerPrice: UFix64, // base for calculate rates
		
		payments: [
			Payment
		]
	)
	
	access(all)
	event OrderClosed(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64,
		buyerAddress: Address,
		cuts: [
			PaymentPart
		]
	)
	
	access(all)
	event OrderCancelled(
		orderAddress: Address,
		orderId: UInt64,
		nftType: String,
		nftId: UInt64,
		vaultType: String,
		price: UFix64,
		cuts: [
			PaymentPart
		]
	)
	
	// addOrder
	// Wrapper for NFTStorefront.createListing
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun addOrder(
		storefront: &NFTStorefront.Storefront,
		nftProvider: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
		nftType: Type,
		nftId: UInt64,
		vaultPath: PublicPath,
		vaultType: Type,
		price: UFix64,
		extraCuts: [
			PaymentPart
		],
		royalties: [
			PaymentPart
		]
	): UInt64{ 
		let orderAddress = (storefront.owner!).address
		let payments: [Payment] = []
		let saleCuts: [NFTStorefront.SaleCut] = []
		var percentage = 1.0
		var offerPrice = 0.0
		let addPayment = fun (type: String, address: Address, rate: UFix64){ 
				assert(rate >= 0.0 && rate < 1.0, message: "Rate must be in range [0..1)")
				let amount = price * rate
				let receiver = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(vaultPath)
				assert(receiver.borrow() != nil, message: "Missing or mis-typed fungible token receiver")
				payments.append(Payment(type: type, address: address, rate: rate, amount: amount))
				saleCuts.append(NFTStorefront.SaleCut(receiver: receiver!, amount: amount))
				offerPrice = offerPrice + amount
				percentage = percentage - (type == RaribleOrder.BUYER_FEE ? 0.0 : rate)
				assert(rate >= 0.0 && rate < 1.0, message: "Sum of payouts must be in range [0..1)")
			}
		addPayment(RaribleOrder.BUYER_FEE, RaribleFee.feeAddress(), RaribleFee.buyerFee)
		addPayment(RaribleOrder.SELLER_FEE, RaribleFee.feeAddress(), RaribleFee.sellerFee)
		for cut in extraCuts{ 
			addPayment(RaribleOrder.OTHER, cut.address, cut.rate)
		}
		for royalty in royalties{ 
			addPayment(RaribleOrder.ROYALTY, royalty.address, royalty.rate)
		}
		addPayment(RaribleOrder.REWARD, orderAddress, percentage)
		let orderId =
			storefront.createListing(
				nftProviderCapability: nftProvider,
				nftType: nftType,
				nftID: nftId,
				salePaymentVaultType: vaultType,
				saleCuts: saleCuts
			)
		emit OrderAvailable(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: nftType.identifier,
			nftId: nftId,
			vaultType: vaultType.identifier,
			price: price,
			offerPrice: offerPrice,
			payments: payments
		)
		return orderId
	}
	
	// closeOrder
	// Purchase nft by o
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun closeOrder(
		storefront: &NFTStorefront.Storefront,
		orderId: UInt64,
		orderAddress: Address,
		listing: &NFTStorefront.Listing,
		paymentVault: @{FungibleToken.Vault},
		buyerAddress: Address
	): @{NonFungibleToken.NFT}{ 
		let details = listing.getDetails()
		let cuts: [PaymentPart] = []
		for saleCut in details.saleCuts{ 
			cuts.append(PaymentPart(address: saleCut.receiver.address, rate: saleCut.amount))
		}
		emit OrderClosed(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: details.nftType.identifier,
			nftId: details.nftID,
			vaultType: details.salePaymentVaultType.identifier,
			price: details.salePrice,
			buyerAddress: buyerAddress,
			cuts: cuts
		)
		let item <- listing.purchase(payment: <-paymentVault)
		storefront.cleanup(listingResourceID: orderId)
		return <-item
	}
	
	// removeOrder
	// Cancel sale, dismiss order
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun removeOrder(
		storefront: &NFTStorefront.Storefront,
		orderId: UInt64,
		orderAddress: Address,
		listing: &NFTStorefront.Listing
	){ 
		let details = listing.getDetails()
		let cuts: [PaymentPart] = []
		for saleCut in details.saleCuts{ 
			cuts.append(PaymentPart(address: saleCut.receiver.address, rate: saleCut.amount))
		}
		emit OrderCancelled(
			orderAddress: orderAddress,
			orderId: orderId,
			nftType: details.nftType.identifier,
			nftId: details.nftID,
			vaultType: details.salePaymentVaultType.identifier,
			price: details.salePrice,
			cuts: cuts
		)
		storefront.removeListing(listingResourceID: orderId)
	}
}
