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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import TicalUniverse from "../0xfef48806337aabf1/TicalUniverse.cdc"

import TuneGO from "../0x0d9bc5af3fc0c2e3/TuneGO.cdc"

// Contract
//
access(all)
contract TuneGOMarket{ 
	
	// Events
	//
	access(all)
	event ContractInitialized()
	
	access(all)
	event SaleOfferCreated(
		saleOfferId: UInt64,
		collectibleId: UInt64,
		collectibleType: String,
		tunegoFee: MarketFee,
		royalties: [
			Royalty
		],
		price: UFix64
	)
	
	access(all)
	event SaleOfferAccepted(saleOfferId: UInt64, buyer: Address)
	
	access(all)
	event SaleOfferRemoved(saleOfferId: UInt64)
	
	access(all)
	event TuneGOMarketFeeSet(receiver: Address, percentage: UFix64)
	
	// Paths
	//
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Royalty
	//
	access(all)
	struct Royalty{ 
		access(all)
		let receiver: Address
		
		access(all)
		let percentage: UFix64
		
		init(receiver: Address, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	// MarketFee
	//
	access(all)
	struct MarketFee{ 
		access(all)
		let receiver: Address
		
		access(all)
		let percentage: UFix64
		
		init(receiver: Address, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	// Market config
	//
	access(contract)
	var TuneGOFee: MarketFee
	
	access(contract)
	let SupportedNFTTypes: [Type]
	
	// SaleOfferPublic
	//
	access(all)
	resource interface SaleOfferPublic{ 
		access(all)
		let collectibleId: UInt64
		
		access(all)
		let collectibleType: Type
		
		access(all)
		let price: UFix64
		
		access(all)
		var isCompleted: Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(
			payment: @{FungibleToken.Vault},
			buyerCollection: Capability<&{NonFungibleToken.Receiver}>
		): @{NonFungibleToken.NFT}
	}
	
	// SaleOffer
	//
	access(all)
	resource SaleOffer: SaleOfferPublic{ 
		access(all)
		var isCompleted: Bool
		
		access(all)
		let collectibleId: UInt64
		
		access(all)
		let collectibleType: Type
		
		access(all)
		let price: UFix64
		
		access(self)
		let paymentReceiver: Capability<&FlowToken.Vault>
		
		access(self)
		let royalties: [Royalty]
		
		access(self)
		let saleItemProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		access(self)
		let tunegoPaymentFeeReceiver: Capability<&{FungibleToken.Receiver}>
		
		access(self)
		let tunegoPaymentFeePercentage: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(payment: @{FungibleToken.Vault}, buyerCollection: Capability<&{NonFungibleToken.Receiver}>): @{NonFungibleToken.NFT}{ 
			pre{ 
				payment.balance == self.price:
					"Payment does not equal offer price"
				self.isCompleted == false:
					"The sale offer has already been accepted"
			}
			self.isCompleted = true
			let tunegoFee = self.price * self.tunegoPaymentFeePercentage / 100.0
			let tunegoFeePayment <- payment.withdraw(amount: tunegoFee)
			(self.tunegoPaymentFeeReceiver.borrow()!).deposit(from: <-tunegoFeePayment)
			for royalty in self.royalties{ 
				let royaltyAccount = getAccount(royalty.receiver)
				let royaltyVault = royaltyAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
				if royaltyVault.check(){ 
					let royaltyAmount = self.price * royalty.percentage / 100.0
					let royaltyPayment <- payment.withdraw(amount: royaltyAmount)
					(royaltyVault.borrow()!).deposit(from: <-royaltyPayment)
				}
			}
			(self.paymentReceiver.borrow()!).deposit(from: <-payment)
			let nft <- (self.saleItemProviderCapability.borrow()!).withdraw(withdrawID: self.collectibleId)
			emit SaleOfferAccepted(saleOfferId: self.uuid, buyer: buyerCollection.address)
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCollectible(): &{NonFungibleToken.NFT}{ 
			let saleItemProvider = (self.saleItemProviderCapability.borrow()!).borrowNFT(self.collectibleId)
			assert(saleItemProvider.isInstance(self.collectibleType), message: "Collectible has wrong type")
			assert(saleItemProvider.id == self.collectibleId, message: "Collectible has wrong ID")
			return saleItemProvider as &{NonFungibleToken.NFT}
		}
		
		init(saleItemProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, collectibleType: Type, collectibleId: UInt64, royalties: [Royalty], price: UFix64, paymentReceiver: Capability<&FlowToken.Vault>){ 
			assert(price > 0.0, message: "Sale price amount must be greater than 0")
			let saleItemProvider = saleItemProviderCapability.borrow()
			assert(saleItemProvider != nil, message: "Cannot access sale item from provider")
			let collectible = (saleItemProvider!).borrowNFT(collectibleId)
			assert(collectible.isInstance(collectibleType), message: "Collectible is not of specified type")
			assert(collectible.id == collectibleId, message: "Collectible does not have specified ID")
			assert(TuneGOMarket.SupportedNFTTypes.contains(collectible.getType()), message: "Collectible is not of supported type")
			assert(paymentReceiver.borrow() != nil, message: "Missing payment receiver vault")
			var totalRoyaltiesPercentage: UFix64 = 0.0
			for royalty in royalties{ 
				let account = getAccount(royalty.receiver)
				let vault = account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
				assert(vault.borrow() != nil, message: "Missing royalty receiver vault")
				totalRoyaltiesPercentage = totalRoyaltiesPercentage + royalty.percentage
			}
			let totalFeesPercentage = totalRoyaltiesPercentage + TuneGOMarket.TuneGOFee.percentage
			assert(totalFeesPercentage < 100.0, message: "Total fees percentage is too high")
			self.isCompleted = false
			self.saleItemProviderCapability = saleItemProviderCapability
			self.collectibleType = collectibleType
			self.collectibleId = collectibleId
			self.royalties = royalties
			self.price = price
			self.paymentReceiver = paymentReceiver
			let tunegoAccount = getAccount(TuneGOMarket.TuneGOFee.receiver)
			self.tunegoPaymentFeeReceiver = tunegoAccount.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
			self.tunegoPaymentFeePercentage = TuneGOMarket.TuneGOFee.percentage
		}
	}
	
	// CollectionManager
	//
	access(all)
	resource interface CollectionManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createSaleOffer(
			saleItemProviderCapability: Capability<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>,
			collectibleType: Type,
			collectibleId: UInt64,
			royalties: [
				TuneGOMarket.Royalty
			],
			price: UFix64,
			paymentReceiver: Capability<&FlowToken.Vault>
		): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleOffer(saleOfferId: UInt64)
	}
	
	// CollectionPublic
	//
	access(all)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleOffer(saleOfferId: UInt64): &SaleOffer?
	}
	
	// Collection
	//
	access(all)
	resource Collection: CollectionManager, CollectionPublic{ 
		access(self)
		var saleOffers: @{UInt64: SaleOffer}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createSaleOffer(saleItemProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, collectibleType: Type, collectibleId: UInt64, royalties: [Royalty], price: UFix64, paymentReceiver: Capability<&FlowToken.Vault>): UInt64{ 
			let saleOffer <- create SaleOffer(saleItemProviderCapability: saleItemProviderCapability, collectibleType: collectibleType, collectibleId: collectibleId, royalties: royalties, price: price, paymentReceiver: paymentReceiver)
			let saleOfferId = saleOffer.uuid
			let oldOffer <- self.saleOffers[saleOfferId] <- saleOffer
			destroy oldOffer
			emit SaleOfferCreated(saleOfferId: saleOfferId, collectibleId: collectibleId, collectibleType: collectibleType.identifier, tunegoFee: TuneGOMarket.TuneGOFee, royalties: royalties, price: price)
			return saleOfferId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleOffer(saleOfferId: UInt64){ 
			emit SaleOfferRemoved(saleOfferId: saleOfferId)
			let saleOffer <- self.saleOffers.remove(key: saleOfferId) ?? panic("missing SaleOffer")
			destroy saleOffer
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSaleOfferIDs(): [UInt64]{ 
			return self.saleOffers.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSaleOffer(saleOfferId: UInt64): &SaleOffer?{ 
			if self.saleOffers[saleOfferId] == nil{ 
				return nil
			} else{ 
				return &self.saleOffers[saleOfferId] as &TuneGOMarket.SaleOffer?
			}
		}
		
		init(){ 
			self.saleOffers <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMarketFee(): MarketFee{ 
		return MarketFee(receiver: self.TuneGOFee.receiver, percentage: self.TuneGOFee.percentage)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setTuneGOFee(tunegoFee: MarketFee){ 
			TuneGOMarket.TuneGOFee = tunegoFee
			emit TuneGOMarketFeeSet(receiver: tunegoFee.receiver, percentage: tunegoFee.percentage)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSupportedNFTType(nftType: Type){ 
			TuneGOMarket.SupportedNFTTypes.append(nftType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.CollectionPublicPath = /public/tunegoMarketCollection
		self.CollectionStoragePath = /storage/tunegoMarketCollection
		self.AdminPublicPath = /public/tunegoMarketAdmin
		self.AdminStoragePath = /storage/tunegoMarketAdmin
		self.account.storage.save<@Admin>(<-create Admin(), to: TuneGOMarket.AdminStoragePath)
		self.SupportedNFTTypes = [Type<@TuneGO.NFT>(), Type<@TicalUniverse.NFT>()]
		let initialMarketFee = MarketFee(receiver: self.account.address, percentage: UFix64(2.5))
		self.TuneGOFee = initialMarketFee
		emit TuneGOMarketFeeSet(
			receiver: initialMarketFee.receiver,
			percentage: initialMarketFee.percentage
		)
		emit ContractInitialized()
	}
}
