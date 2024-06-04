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

	// mainnet
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import ArleePartner from "./ArleePartner.cdc"

import ArleeScene from "./ArleeScene.cdc"

import ArleeSceneVoucher from "./ArleeSceneVoucher.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

// testnet
// import FungibleToken from "../0x9a0766d93b6608b7/FungibleToken.cdc"
// import NonFungibleToken from "../0x631e88ae7f1d7c20/NonFungibleToken.cdc"
// import MetadataViews from "../0x631e88ae7f1d7c20/MetadataViews.cdc"
// import FlowToken from "../0x7e60df042a9c0868/FlowToken.cdc"
// import ArleePartner from "../0xe7fd8b1148e021b2/ArleePartner.cdc"
// import ArleeScene from "../0xe7fd8b1148e021b2/ArleeScene.cdc"
// import ArleeSceneVoucher from "../0xe7fd8b1148e021b2/ArleeSceneVoucher.cdc"
// import FLOAT from "../0x0afe396ebc8eee65/FLOAT.cdc"
// local
// import FungibleToken from "../"./FungibleToken"/FungibleToken.cdc"
// import NonFungibleToken from "../"./NonFungibleToken"/NonFungibleToken.cdc"
// import MetadataViews from "../"./MetadataViews"/MetadataViews.cdc"
// import FlowToken from "../"./FlowToken"/FlowToken.cdc"
// import ArleePartner from "../"./ArleePartner"/ArleePartner.cdc"
// import ArleeScene from "../"./ArleeScene"/ArleeScene.cdc"
// import ArleeSceneVoucher from "../"./ArleeSceneVoucher"/ArleeSceneVoucher.cdc"
// import FLOAT from "../"./lib/FLOAT.cdc"/FLOAT.cdc"
access(all)
contract Arlequin{ 
	access(all)
	var arleepartnerNFTPrice: UFix64
	
	access(all)
	var sceneNFTPrice: UFix64
	
	access(all)
	var arleeSceneVoucherPrice: UFix64
	
	access(all)
	var arleeSceneUpgradePrice: UFix64
	
	// This is the ratio to partners in arleepartnerNFT sales, ratio to Arlequin will be (1 - partnerSplitRatio)
	access(all)
	var partnerSplitRatio: UFix64
	
	// Paths
	access(all)
	let ArleePartnerAdminStoragePath: StoragePath
	
	access(all)
	let ArleeSceneAdminStoragePath: StoragePath
	
	// Events
	access(all)
	event VoucherClaimed(address: Address, voucherID: UInt64)
	
	// Query Functions
	/* For ArleePartner */
	access(TMP_ENTITLEMENT_OWNER)
	fun checkArleePartnerNFT(addr: Address): Bool{ 
		return ArleePartner.checkArleePartnerNFT(addr: addr)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerNFTIDs(addr: Address): [UInt64]?{ 
		return ArleePartner.getArleePartnerNFTIDs(addr: addr)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerNFTName(id: UInt64): String?{ 
		return ArleePartner.getArleePartnerNFTName(id: id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerNFTNames(addr: Address): [String]?{ 
		return ArleePartner.getArleePartnerNFTNames(addr: addr)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerAllNFTNames():{ UInt64: String}{ 
		return ArleePartner.getAllArleePartnerNFTNames()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerRoyalties():{ String: ArleePartner.Royalty}{ 
		return ArleePartner.getRoyalties()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerRoyaltiesByPartner(partner: String): ArleePartner.Royalty?{ 
		return ArleePartner.getPartnerRoyalty(partner: partner)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerOwner(id: UInt64): Address?{ 
		return ArleePartner.getOwner(id: id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerMintable():{ String: Bool}{ 
		return ArleePartner.getMintable()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerTotalSupply(): UInt64{ 
		return ArleePartner.totalSupply
	}
	
	// For Minting 
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerMintPrice(): UFix64{ 
		return Arlequin.arleepartnerNFTPrice
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleePartnerSplitRatio(): UFix64{ 
		return Arlequin.partnerSplitRatio
	}
	
	/* For ArleeScene */
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneNFTIDs(addr: Address): [UInt64]?{ 
		return ArleeScene.getArleeSceneIDs(addr: addr)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneRoyalties(): [ArleeScene.Royalty]{ 
		return ArleeScene.getRoyalty()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneCID(id: UInt64): String?{ 
		return ArleeScene.getArleeSceneCID(id: id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllArleeSceneCID():{ UInt64: String}{ 
		return ArleeScene.getAllArleeSceneCID()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneFreeMintAcct():{ Address: UInt64}{ 
		return ArleeScene.getFreeMintAcct()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneFreeMintQuota(addr: Address): UInt64?{ 
		return ArleeScene.getFreeMintQuota(addr: addr)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneOwner(id: UInt64): Address?{ 
		return ArleeScene.getOwner(id: id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneMintable(): Bool{ 
		return ArleeScene.mintable
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneTotalSupply(): UInt64{ 
		return ArleeScene.totalSupply
	}
	
	// For Minting 
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneMintPrice(): UFix64{ 
		return Arlequin.sceneNFTPrice
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneVoucherMintPrice(): UFix64{ 
		return Arlequin.arleeSceneVoucherPrice
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArleeSceneUpgradePrice(): UFix64{ 
		return Arlequin.arleeSceneUpgradePrice
	}
	
	access(all)
	resource ArleePartnerAdmin{ 
		// ArleePartner NFT Admin Functinos
		access(TMP_ENTITLEMENT_OWNER)
		fun addPartner(creditor: String, addr: Address, cut: UFix64){ 
			ArleePartner.addPartner(creditor: creditor, addr: addr, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removePartner(creditor: String){ 
			ArleePartner.removePartner(creditor: creditor)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMarketplaceCut(cut: UFix64){ 
			ArleePartner.setMarketplaceCut(cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPartnerCut(partner: String, cut: UFix64){ 
			ArleePartner.setPartnerCut(partner: partner, cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMintable(mintable: Bool){ 
			ArleePartner.setMintable(mintable: mintable)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSpecificPartnerNFTMintable(partner: String, mintable: Bool){ 
			ArleePartner.setSpecificPartnerNFTMintable(partner: partner, mintable: mintable)
		}
		
		// for Minting
		access(TMP_ENTITLEMENT_OWNER)
		fun setArleePartnerMintPrice(price: UFix64){ 
			Arlequin.arleepartnerNFTPrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArleePartnerSplitRatio(ratio: UFix64){ 
			pre{ 
				ratio <= 1.0:
					"The spliting ratio cannot be greater than 1.0"
			}
			Arlequin.partnerSplitRatio = ratio
		}
		
		// Add flexibility to giveaway : an Admin mint function.
		access(TMP_ENTITLEMENT_OWNER)
		fun adminMintArleePartnerNFT(partner: String){ 
			// get all merchant receiving vault references 
			let recipientCap =
				getAccount(Arlequin.account.address).capabilities.get<&ArleePartner.Collection>(
					ArleePartner.CollectionPublicPath
				)
			let recipient =
				recipientCap.borrow() ?? panic("Cannot borrow Arlequin's Collection Public")
			// deposit
			ArleePartner.adminMintArleePartnerNFT(recipient: recipient, partner: partner)
		}
	}
	
	access(all)
	resource ArleeSceneAdmin{ 
		// Arlee Scene NFT Admin Functinos
		access(TMP_ENTITLEMENT_OWNER)
		fun setMarketplaceCut(cut: UFix64){ 
			ArleeScene.setMarketplaceCut(cut: cut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFreeMintAcct(addr: Address, mint: UInt64){ 
			ArleeScene.addFreeMintAcct(addr: addr, mint: mint)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchAddFreeMintAcct(list:{ Address: UInt64}){ 
			ArleeScene.batchAddFreeMintAcct(list: list)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFreeMintAcct(addr: Address){ 
			ArleeScene.removeFreeMintAcct(addr: addr)
		}
		
		// set an acct's free minting limit
		access(TMP_ENTITLEMENT_OWNER)
		fun setFreeMintAcctQuota(addr: Address, mint: UInt64){ 
			ArleeScene.setFreeMintAcctQuota(addr: addr, mint: mint)
		}
		
		// add to an acct's free minting limit
		access(TMP_ENTITLEMENT_OWNER)
		fun addFreeMintAcctQuota(addr: Address, additionalMint: UInt64){ 
			ArleeScene.addFreeMintAcctQuota(addr: addr, additionalMint: additionalMint)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMintable(mintable: Bool){ 
			ArleeScene.setMintable(mintable: mintable)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleVoucherIsMintable(){ 
			ArleeSceneVoucher.setMintable(mintable: !ArleeSceneVoucher.mintable)
		}
		
		// for minting
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSceneNFT(buyer: Address, cid: String, metadata:{ String: String}){ 
			let recipientCap =
				getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
					ArleeScene.CollectionPublicPath
				)
			let recipient =
				recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
			ArleeScene.mintSceneNFT(recipient: recipient, cid: cid, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArleeSceneMintPrice(price: UFix64){ 
			Arlequin.sceneNFTPrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArleeSceneVoucherMintPrice(price: UFix64){ 
			Arlequin.arleeSceneVoucherPrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setArleeSceneUpgradePrice(price: UFix64){ 
			Arlequin.arleeSceneUpgradePrice = price
		}
	}
	
	/* Public Minting for ArleePartnerNFT */
	access(TMP_ENTITLEMENT_OWNER)
	fun mintArleePartnerNFT(buyer: Address, partner: String, paymentVault: @{FungibleToken.Vault}){ 
		pre{ 
			paymentVault.balance >= Arlequin.arleepartnerNFTPrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"payment type not in FlowToken.Vault."
		}
		// get all merchant receiving vault references 
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receiving vault reference")
		let partnerRoyalty =
			self.getArleePartnerRoyaltiesByPartner(partner: partner)
			?? panic("Cannot find partner : ".concat(partner))
		let partnerAddr = partnerRoyalty.wallet
		let partnerVaultCap =
			getAccount(partnerAddr).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
		let partnerVault =
			partnerVaultCap.borrow() ?? panic("Cannot borrow partner's receiving vault reference")
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleePartner.Collection>(
				ArleePartner.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		// splitting vaults for partner and arlequin
		let toPartnerVault <-
			paymentVault.withdraw(amount: paymentVault.balance * Arlequin.partnerSplitRatio)
		// deposit
		arlequinVault.deposit(from: <-paymentVault)
		partnerVault.deposit(from: <-toPartnerVault)
		ArleePartner.mintArleePartnerNFT(recipient: recipient, partner: partner)
	}
	
	/* Public Minting for ArleeSceneNFT */
	access(TMP_ENTITLEMENT_OWNER)
	fun mintSceneNFT(
		buyer: Address,
		cid: String,
		metadata:{ 
			String: String
		},
		paymentVault: @{FungibleToken.Vault},
		adminRef: &ArleeSceneAdmin
	){ 
		pre{ 
			paymentVault.balance >= Arlequin.sceneNFTPrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"payment type not in FlowToken.Vault."
		}
		// get all merchant receiving vault references 
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receiving vault reference")
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
				ArleeScene.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		// deposit
		arlequinVault.deposit(from: <-paymentVault)
		ArleeScene.mintSceneNFT(recipient: recipient, cid: cid, metadata: metadata)
	}
	
	/* Free Minting for ArleeSceneNFT */
	access(TMP_ENTITLEMENT_OWNER)
	fun mintSceneFreeMintNFT(
		buyer: Address,
		cid: String,
		metadata:{ 
			String: String
		},
		adminRef: &ArleeSceneAdmin
	){ 
		let userQuota = Arlequin.getArleeSceneFreeMintQuota(addr: buyer)!
		assert(userQuota != nil, message: "You are not given free mint quotas")
		assert(userQuota > 0, message: "You ran out of free mint quotas")
		let recipientCap =
			getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
				ArleeScene.CollectionPublicPath
			)
		let recipient =
			recipientCap.borrow() ?? panic("Cannot borrow recipient's Collection Public")
		ArleeScene.setFreeMintAcctQuota(addr: buyer, mint: userQuota - 1)
		// deposit
		ArleeScene.mintSceneNFT(recipient: recipient, cid: cid, metadata: metadata)
	}
	
	/* Public Minting ArleeSceneVoucher NFT */
	access(TMP_ENTITLEMENT_OWNER)
	fun mintVoucherNFT(
		buyer: Address,
		species: String,
		paymentVault: @{FungibleToken.Vault},
		adminRef: &ArleeSceneAdmin
	){ 
		pre{ 
			paymentVault.balance >= Arlequin.arleeSceneVoucherPrice:
				"Insufficient funds provided to mint the voucher"
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"Funds provided are not Flow Tokens!"
		}
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receving vault reference")
		let recipientRef =
			getAccount(buyer).capabilities.get<&ArleeSceneVoucher.Collection>(
				ArleeSceneVoucher.CollectionPublicPath
			).borrow()
			?? panic("Cannot borrow recipient's collection")
		arlequinVault.deposit(from: <-paymentVault)
		ArleeSceneVoucher.mintVoucherNFT(recipient: recipientRef, species: species)
	}
	
	/* Minting from ArleeSceneNFT from ArleeSceneVoucher (doesn't allow possibility to change cid, metadata etc. only validate on backend */
	access(TMP_ENTITLEMENT_OWNER)
	fun mintSceneFromVoucher(
		buyer: Address,
		cid: String,
		metadata:{ 
			String: String
		},
		voucher: @{NonFungibleToken.NFT},
		adminRef: &ArleeSceneAdmin
	){ 
		pre{ 
			voucher.getType() == Type<@ArleeSceneVoucher.NFT>():
				"Voucher NFT is not of correct Type"
		}
		let recipientRef =
			getAccount(buyer).capabilities.get<&ArleeScene.Collection>(
				ArleeScene.CollectionPublicPath
			).borrow()
			?? panic("Cannot borrow recipient's ArleeScene CollectionPublic")
		ArleeScene.mintSceneNFT(recipient: recipientRef, cid: cid, metadata: metadata)
		destroy voucher
	}
	
	/* Redeem Voucher - general purpose voucher consumption function, backend can proceed to mint once voucher is redeemed */
	access(TMP_ENTITLEMENT_OWNER)
	fun redeemVoucher(
		address: Address,
		voucher: @{NonFungibleToken.NFT},
		adminRef: &ArleeSceneAdmin
	){ 
		pre{ 
			voucher.getType() == Type<@ArleeSceneVoucher.NFT>():
				"Provided NFT is not an ArleeSceneVoucher!"
		}
		emit VoucherClaimed(address: address, voucherID: voucher.id)
		destroy voucher
	}
	
	/* Upgrade Arlee */
	access(TMP_ENTITLEMENT_OWNER)
	fun updateArleeCID(
		arlee: @{NonFungibleToken.NFT},
		paymentVault: @{FungibleToken.Vault},
		cid: String,
		adminRef: &ArleeSceneAdmin
	): @{NonFungibleToken.NFT}{ 
		pre{ 
			arlee.getType() == Type<@ArleeScene.NFT>():
				"Incorrect NFT type provided!"
			paymentVault.balance >= Arlequin.arleeSceneUpgradePrice:
				"Insufficient funds provided to upgrade Arlee"
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"Funds provided are not Flow Tokens!"
		}
		let arlequinVault =
			self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Cannot borrow Arlequin's receving vault reference")
		arlequinVault.deposit(from: <-paymentVault)
		return <-ArleeScene.updateCID(arleeSceneNFT: <-arlee, newCID: cid)
	}
	
	// NOTE: Contract needs to be removed and redeployed (not upgraded) to re-run the initalization.
	init(){ 
		self.arleepartnerNFTPrice = 10.0
		self.sceneNFTPrice = 10.0
		self.arleeSceneVoucherPrice = 12.0
		self.arleeSceneUpgradePrice = 9.0
		self.partnerSplitRatio = 1.0
		self.ArleePartnerAdminStoragePath = /storage/ArleePartnerAdmin
		self.ArleeSceneAdminStoragePath = /storage/ArleeSceneAdmin
		destroy <-self.account.storage.load<@AnyResource>(
			from: Arlequin.ArleePartnerAdminStoragePath
		)
		destroy <-self.account.storage.load<@AnyResource>(from: Arlequin.ArleeSceneAdminStoragePath)
		self.account.storage.save(
			<-create ArleePartnerAdmin(),
			to: Arlequin.ArleePartnerAdminStoragePath
		)
		self.account.storage.save(
			<-create ArleeSceneAdmin(),
			to: Arlequin.ArleeSceneAdminStoragePath
		)
	}
}
