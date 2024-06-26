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

	import FIND from 0x97bafa4e0b48eef

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import NFTStorefrontV2 from "./../../standardsV1/NFTStorefrontV2.cdc"

import Flowty from "../0x5c57f79c6694797f/Flowty.cdc"

import FlowtyRentals from "../0x5c57f79c6694797f/FlowtyRentals.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlovatarMarketplace from "../0x921ea449dffec68a/FlovatarMarketplace.cdc"

import Flovatar from "../0x921ea449dffec68a/Flovatar.cdc"

import FlovatarComponent from "../0x921ea449dffec68a/FlovatarComponent.cdc"

access(all)
contract FindUserStatus{ 
	access(all)
	struct StoreFrontCut{ 
		access(all)
		let amount: UFix64
		
		access(all)
		let address: Address
		
		access(all)
		let findName: String?
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(amount: UFix64, address: Address){ 
			self.amount = amount
			self.address = address
			self.findName = FIND.reverseLookup(address)
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(all)
	struct StorefrontListing{ 
		access(all)
		var listingId: UInt64
		
		// if purchased is true -> don't show it
		//pub var purchased: Bool
		access(all)
		let nftIdentifier: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let ftTypeIdentifier: String
		
		access(all)
		let amount: UFix64
		
		access(all)
		let cuts: [StoreFrontCut]
		
		access(all)
		var customID: String?
		
		access(all)
		let commissionAmount: UFix64?
		
		access(all)
		let listingValidUntil: UInt64?
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			storefrontID: UInt64,
			nftType: String,
			nftID: UInt64,
			salePaymentVaultType: String,
			salePrice: UFix64,
			saleCuts: [
				StoreFrontCut
			],
			customID: String?,
			commissionAmount: UFix64?,
			expiry: UInt64?
		){ 
			self.listingId = storefrontID
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.ftTypeIdentifier = salePaymentVaultType
			self.amount = salePrice
			self.cuts = saleCuts
			self.customID = customID
			self.commissionAmount = commissionAmount
			self.listingValidUntil = expiry
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(all)
	struct FlowtyListing{ 
		access(all)
		var listingId: UInt64
		
		access(all)
		var funded: Bool
		
		access(all)
		let nftIdentifier: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let amount: UFix64
		
		access(all)
		let interestRate: UFix64
		
		access(all)
		var term: UFix64
		
		access(all)
		let paymentVaultType: String
		
		access(all)
		let paymentCuts: [StoreFrontCut]
		
		access(all)
		var listedTime: UFix64
		
		access(all)
		var royaltyRate: UFix64
		
		access(all)
		var listingValidUntil: UFix64
		
		access(all)
		var repaymentAmount: UFix64
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			flowtyStorefrontID: UInt64,
			funded: Bool,
			nftType: String,
			nftID: UInt64,
			amount: UFix64,
			interestRate: UFix64,
			term: UFix64,
			paymentVaultType: String,
			paymentCuts: [
				StoreFrontCut
			],
			listedTime: UFix64,
			royaltyRate: UFix64,
			expiresAfter: UFix64,
			repaymentAmount: UFix64
		){ 
			self.listingId = flowtyStorefrontID
			self.funded = funded
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.amount = amount
			self.interestRate = interestRate
			self.term = term
			self.paymentVaultType = paymentVaultType
			self.paymentCuts = paymentCuts
			self.listedTime = listedTime
			self.royaltyRate = royaltyRate
			self.listingValidUntil = expiresAfter + listedTime
			self.repaymentAmount = repaymentAmount
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(all)
	struct FlowtyRental{ 
		access(all)
		var listingId: UInt64
		
		access(all)
		var rented: Bool
		
		access(all)
		let nftIdentifier: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let amount: UFix64
		
		access(all)
		let deposit: UFix64
		
		access(all)
		var term: UFix64
		
		access(all)
		let paymentVaultType: String
		
		access(all)
		let reenableOnReturn: Bool
		
		access(all)
		let paymentCuts: [StoreFrontCut]
		
		access(all)
		var listedTime: UFix64
		
		access(all)
		var royaltyRate: UFix64
		
		access(all)
		var listingValidUntil: UFix64
		
		access(all)
		var repaymentAmount: UFix64
		
		access(all)
		var renter: Address?
		
		access(all)
		var renterName: String?
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			flowtyStorefrontID: UInt64,
			rented: Bool,
			nftType: String,
			nftID: UInt64,
			amount: UFix64,
			deposit: UFix64,
			term: UFix64,
			paymentVaultType: String,
			reenableOnReturn: Bool,
			paymentCuts: [
				StoreFrontCut
			],
			listedTime: UFix64,
			royaltyRate: UFix64,
			expiresAfter: UFix64,
			repaymentAmount: UFix64,
			renter: Address?
		){ 
			self.listingId = flowtyStorefrontID
			self.rented = rented
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.deposit = deposit
			self.amount = amount
			self.term = term
			self.paymentVaultType = paymentVaultType
			self.reenableOnReturn = reenableOnReturn
			self.paymentCuts = paymentCuts
			self.listedTime = listedTime
			self.royaltyRate = royaltyRate
			self.listingValidUntil = expiresAfter + listedTime
			self.repaymentAmount = repaymentAmount
			self.renter = renter
			self.renterName = nil
			if renter != nil{ 
				self.renterName = FIND.reverseLookup(renter!)
			}
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(all)
	struct FlovatarListing{ 
		access(all)
		var listingId: UInt64
		
		access(all)
		let nftIdentifier: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let ftTypeIdentifier: String
		
		access(all)
		let amount: UFix64
		
		access(all)
		let cuts: [StoreFrontCut]
		
		access(all)
		let accessoryId: UInt64?
		
		access(all)
		let hatId: UInt64?
		
		access(all)
		let eyeglassesId: UInt64?
		
		access(all)
		let backgroundId: UInt64?
		
		access(all)
		let mint: UInt64
		
		access(all)
		let series: UInt32
		
		access(all)
		let creatorAddress: Address
		
		access(all)
		let components:{ String: UInt64}
		
		access(all)
		let rareCount: UInt8
		
		access(all)
		let epicCount: UInt8
		
		access(all)
		let legendaryCount: UInt8
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			storefrontID: UInt64,
			nftType: String,
			nftID: UInt64,
			salePaymentVaultType: String,
			salePrice: UFix64,
			saleCuts: [
				StoreFrontCut
			],
			flovatarMetadata: FlovatarMarketplace.FlovatarSaleData
		){ 
			self.listingId = storefrontID
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.ftTypeIdentifier = salePaymentVaultType
			self.amount = salePrice
			self.cuts = saleCuts
			let f = flovatarMetadata
			self.accessoryId = f.accessoryId
			self.hatId = f.hatId
			self.eyeglassesId = f.eyeglassesId
			self.backgroundId = f.backgroundId
			let d = f.metadata
			self.mint = d.mint
			self.series = d.series
			self.creatorAddress = d.creatorAddress
			self.components = d.getComponents()
			self.rareCount = d.rareCount
			self.epicCount = d.epicCount
			self.legendaryCount = d.legendaryCount
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(all)
	struct FlovatarComponentListing{ 
		access(all)
		var listingId: UInt64
		
		access(all)
		let nftIdentifier: String
		
		access(all)
		let nftId: UInt64
		
		access(all)
		let ftTypeIdentifier: String
		
		access(all)
		let amount: UFix64
		
		access(all)
		let cuts: [StoreFrontCut]
		
		access(all)
		let mint: UInt64
		
		access(all)
		let templateId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let category: String
		
		access(all)
		let rarity: String
		
		access(all)
		let color: String
		
		access(all)
		let tags:{ String: String}
		
		access(all)
		let scalars:{ String: UFix64}
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(
			storefrontID: UInt64,
			nftType: String,
			nftID: UInt64,
			salePaymentVaultType: String,
			salePrice: UFix64,
			saleCuts: [
				StoreFrontCut
			],
			flovatarComponentMetadata: FlovatarMarketplace.FlovatarComponentSaleData
		){ 
			self.listingId = storefrontID
			self.nftIdentifier = nftType
			self.nftId = nftID
			self.ftTypeIdentifier = salePaymentVaultType
			self.amount = salePrice
			self.cuts = saleCuts
			let f = flovatarComponentMetadata.metadata
			self.mint = f.mint
			self.templateId = f.templateId
			self.name = f.name
			self.description = f.description
			self.category = f.category
			self.rarity = f.rarity
			self.color = f.color
			self.tags ={} 
			self.scalars ={} 
			self.extra ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStorefrontListing(user: Address, id: UInt64, type: Type): StorefrontListing?{ 
		var listingsV1: StorefrontListing? = nil
		let account = getAccount(user)
		let storefrontCap =
			account.capabilities.get<&NFTStorefront.Storefront>(NFTStorefront.StorefrontPublicPath)
		if storefrontCap.check(){ 
			let storefrontRef = storefrontCap.borrow()!
			for listingId in storefrontRef.getListingIDs(){ 
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID != id || d.nftType != type{ 
					continue
				}
				if d.purchased{ 
					continue
				}
				let saleCuts: [StoreFrontCut] = []
				for cut in d.saleCuts{ 
					saleCuts.append(StoreFrontCut(amount: cut.amount, address: cut.receiver.address))
				}
				listingsV1 = StorefrontListing(storefrontID: d.storefrontID, nftType: d.nftType.identifier, nftID: d.nftID, salePaymentVaultType: d.salePaymentVaultType.identifier, salePrice: d.salePrice, saleCuts: saleCuts, customID: nil, commissionAmount: nil, expiry: nil)
				return listingsV1
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStorefrontV2Listing(user: Address, id: UInt64, type: Type): StorefrontListing?{ 
		var listingsV2: StorefrontListing? = nil
		let account = getAccount(user)
		let storefrontV2Cap =
			account.capabilities.get<&NFTStorefrontV2.Storefront>(
				NFTStorefrontV2.StorefrontPublicPath
			)
		if storefrontV2Cap.check(){ 
			let storefrontRef = storefrontV2Cap.borrow()!
			for listingId in storefrontRef.getListingIDs(){ 
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID != id || d.nftType != type{ 
					continue
				}
				if d.purchased{ 
					continue
				}
				let saleCuts: [StoreFrontCut] = []
				for cut in d.saleCuts{ 
					saleCuts.append(StoreFrontCut(amount: cut.amount, address: cut.receiver.address))
				}
				listingsV2 = StorefrontListing(storefrontID: d.storefrontID, nftType: d.nftType.identifier, nftID: d.nftID, salePaymentVaultType: d.salePaymentVaultType.identifier, salePrice: d.salePrice, saleCuts: saleCuts, customID: d.customID, commissionAmount: d.commissionAmount, expiry: d.expiry)
				return listingsV2
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFlowtyListing(user: Address, id: UInt64, type: Type): FlowtyListing?{ 
		var flowty: FlowtyListing? = nil
		let account = getAccount(user)
		let flowtyCap =
			account.capabilities.get<&Flowty.FlowtyStorefront>(Flowty.FlowtyStorefrontPublicPath)
		if flowtyCap.check(){ 
			let storefrontRef = flowtyCap.borrow()!
			for listingId in storefrontRef.getListingIDs(){ 
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID != id || d.nftType != type{ 
					continue
				}
				if d.funded{ 
					continue
				}
				let saleCuts: [StoreFrontCut] = []
				for cut in d.getPaymentCuts(){ 
					saleCuts.append(StoreFrontCut(amount: cut.amount, address: cut.receiver.address))
				}
				flowty = FlowtyListing(flowtyStorefrontID: d.flowtyStorefrontID, funded: d.funded, nftType: d.nftType.identifier, nftID: d.nftID, amount: d.amount, interestRate: d.interestRate, term: d.term, paymentVaultType: d.paymentVaultType.identifier, paymentCuts: saleCuts, listedTime: d.listedTime, royaltyRate: d.royaltyRate, expiresAfter: d.expiresAfter, repaymentAmount: d.getTotalPayment())
				return flowty
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFlowtyRentals(user: Address, id: UInt64, type: Type): FlowtyRental?{ 
		var flowtyRental: FlowtyRental? = nil
		let account = getAccount(user)
		let flowtyRentalCap =
			account.capabilities.get<&FlowtyRentals.FlowtyRentalsStorefront>(
				FlowtyRentals.FlowtyRentalsStorefrontPublicPath
			)
		if flowtyRentalCap.check(){ 
			let storefrontRef = flowtyRentalCap.borrow()!
			for listingId in storefrontRef.getListingIDs(){ 
				let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
				let d = listing.getDetails()
				if d.nftID != id || d.nftType != type{ 
					continue
				}
				if d.rented{ 
					continue
				}
				let saleCuts: [StoreFrontCut] = []
				let cut = d.getPaymentCut()
				saleCuts.append(StoreFrontCut(amount: cut.amount, address: cut.receiver.address))
				flowtyRental = FlowtyRental(flowtyStorefrontID: d.flowtyStorefrontID, rented: d.rented, nftType: d.nftType.identifier, nftID: d.nftID, amount: d.amount, deposit: d.deposit, term: d.term, paymentVaultType: d.paymentVaultType.identifier, reenableOnReturn: d.reenableOnReturn, paymentCuts: saleCuts, listedTime: d.listedTime, royaltyRate: d.royaltyRate, expiresAfter: d.expiresAfter, repaymentAmount: d.getTotalPayment(), renter: d.renter)
				return flowtyRental
			}
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFlovatarListing(user: Address, id: UInt64, type: Type): FlovatarListing?{ 
		let nftType = Type<@Flovatar.NFT>()
		if type != nftType{ 
			return nil
		}
		let flovatar = FlovatarMarketplace.getFlovatarSale(address: user, id: id)
		if flovatar == nil{ 
			return nil
		}
		let f = flovatar!
		let saleCuts: [StoreFrontCut] = []
		let creatorCut = Flovatar.getRoyaltyCut()
		let marketCut = Flovatar.getMarketplaceCut()
		saleCuts.appendAll(
			[
				StoreFrontCut(amount: creatorCut, address: f.metadata.creatorAddress),
				StoreFrontCut(
					amount: marketCut,
					address: FlovatarMarketplace.marketplaceWallet.address
				)
			]
		)
		return FlovatarListing(
			storefrontID: f.id,
			nftType: nftType.identifier,
			nftID: f.id,
			salePaymentVaultType: Type<@FlowToken.Vault>().identifier,
			salePrice: f.price,
			saleCuts: saleCuts,
			flovatarMetadata: f
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFlovatarComponentListing(
		user: Address,
		id: UInt64,
		type: Type
	): FlovatarComponentListing?{ 
		let nftType = Type<@FlovatarComponent.NFT>()
		if type != nftType{ 
			return nil
		}
		let flovatar = FlovatarMarketplace.getFlovatarComponentSale(address: user, id: id)
		if flovatar == nil{ 
			return nil
		}
		let f = flovatar!
		let saleCuts: [StoreFrontCut] = []
		let creatorCut = Flovatar.getRoyaltyCut()
		let marketCut = Flovatar.getMarketplaceCut()
		saleCuts.appendAll(
			[
				StoreFrontCut(
					amount: marketCut,
					address: FlovatarMarketplace.marketplaceWallet.address
				)
			]
		)
		return FlovatarComponentListing(
			storefrontID: f.id,
			nftType: nftType.identifier,
			nftID: f.id,
			salePaymentVaultType: Type<@FlowToken.Vault>().identifier,
			salePrice: f.price,
			saleCuts: saleCuts,
			flovatarComponentMetadata: f
		)
	}
}
