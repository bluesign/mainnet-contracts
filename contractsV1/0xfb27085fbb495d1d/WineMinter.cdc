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

	// SPDX-License-Identifier: UNLICENSED
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

import Wine from "./Wine.cdc"

access(all)
contract WineMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var saleMaxTokens:{ String:{ UInt64: UInt64}}
	
	access(all)
	var salePrices:{ String:{ UInt64: UFix64}}
	
	access(self)
	var saleAccounts:{ String:{ UInt64:{ Address: UInt64}}}
	
	access(all)
	var merchantAccounts:{ String: Address}
	
	access(self)
	fun initSaleAccounts(){ 
		if self.saleAccounts["PUBLIC"] == nil{ 
			self.saleAccounts["PUBLIC"] ={} 
		}
	}
	
	access(self)
	fun initPublicSaleAccountsForBuyer(templateID: UInt64, buyer: Address){ 
		if self.saleAccounts["PUBLIC"] == nil{ 
			self.saleAccounts["PUBLIC"] ={} 
		}
		if (self.saleAccounts["PUBLIC"]!)[templateID] == nil{ 
			let publicSaleAccounts = self.saleAccounts["PUBLIC"]!
			publicSaleAccounts[templateID] ={} 
			self.saleAccounts["PUBLIC"] = publicSaleAccounts
		}
		if ((self.saleAccounts["PUBLIC"]!)[templateID]!)[buyer] == nil{ 
			let publicSaleAccounts = self.saleAccounts["PUBLIC"]!
			let templateSaleAccounts = publicSaleAccounts[templateID]!
			templateSaleAccounts[buyer] = (self.saleMaxTokens["PUBLIC"]!)[templateID]
			publicSaleAccounts[templateID] = templateSaleAccounts
			self.saleAccounts["PUBLIC"] = publicSaleAccounts
		}
	}
	
	access(self)
	fun updateSaleAccountsForBuyer(templateID: UInt64, buyer: Address, newValue: UInt64){ 
		let publicSaleAccounts = self.saleAccounts["PUBLIC"]!
		let templateSaleAccounts = publicSaleAccounts[templateID]!
		templateSaleAccounts[buyer] = newValue
		publicSaleAccounts[templateID] = templateSaleAccounts
		self.saleAccounts["PUBLIC"] = publicSaleAccounts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		templateID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address
	){ 
		pre{ 
			paymentVault.balance >= (self.salePrices["DUC-PUBLIC"]!)[templateID]!:
				"Insufficient payment amount"
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"Payment type not DapperUtilityCoin"
			self.merchantAccounts["DUC"]! == merchantAccount:
				"Mismatching merchant account"
		}
		self.initPublicSaleAccountsForBuyer(templateID: templateID, buyer: buyer)
		
		// Check buyer hasn't exceeded their allowance
		if ((self.saleAccounts["PUBLIC"]!)[templateID]!)[buyer]! < 1{ 
			panic("Purchase amount exceeds maximum buyer allowance")
		}
		let admin =
			self.account.storage.borrow<&Wine.Admin>(from: Wine.AdminStoragePath)
			?? panic("Could not borrow a reference to the wine admin")
		let set = admin.borrowSet(id: setID)
		
		// Check set availability
		if set.getTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		
		// Check set eligibility
		if !set.isPublic{ 
			panic("Cannot mint private set with mintNFTWithDUC")
		}
		
		// Get DUC receiver reference of merchant account
		let merchantDUCReceiverRef =
			getAccount(self.merchantAccounts["DUC"]!).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 
		 // Deposit DUC to merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Wine NFT
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Wine.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Collector NFT
		admin.mintNFT(recipient: NFTReceiver, setID: setID, templateID: templateID)
		
		// Remove utilized spots
		self.updateSaleAccountsForBuyer(
			templateID: templateID,
			buyer: buyer,
			newValue: ((self.saleAccounts["PUBLIC"]!)[templateID]!)[buyer]! - 1
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintNFTWithFUT(
		buyer: Address,
		setID: UInt64,
		templateID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address
	){ 
		pre{ 
			paymentVault.balance >= (self.salePrices["FUT-PUBLIC"]!)[templateID]!:
				"Insufficient payment amount"
			paymentVault.getType() == Type<@FlowUtilityToken.Vault>():
				"Payment type not FlowUtilityToken"
			self.merchantAccounts["FUT"]! == merchantAccount:
				"Mismatching merchant account"
		}
		self.initPublicSaleAccountsForBuyer(templateID: templateID, buyer: buyer)
		
		// Check buyer hasn't exceeded their allowance
		if ((self.saleAccounts["PUBLIC"]!)[templateID]!)[buyer]! < 1{ 
			panic("Purchase amount exceeds maximum buyer allowance")
		}
		let admin =
			self.account.storage.borrow<&Wine.Admin>(from: Wine.AdminStoragePath)
			?? panic("Could not borrow a reference to the wine admin")
		let set = admin.borrowSet(id: setID)
		
		// Check set availability
		if set.getTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		
		// Check set eligibility
		if !set.isPublic{ 
			panic("Cannot mint private set with mintNFTWithFUT")
		}
		
		// Get FUT receiver reference of merchant account
		let merchantFUTReceiverRef =
			getAccount(self.merchantAccounts["FUT"]!).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowUtilityTokenReceiver
			)
		assert(
			merchantFUTReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant FUT receiver"
		)
		(		 
		 // Deposit FUT to merchant account FUT Vault (it's then forwarded to the main FUT contract afterwards)
		 merchantFUTReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Wine NFT
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Wine.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Collector NFT
		admin.mintNFT(recipient: NFTReceiver, setID: setID, templateID: templateID)
		
		// Remove utilized spots
		self.updateSaleAccountsForBuyer(
			templateID: templateID,
			buyer: buyer,
			newValue: ((self.saleAccounts["PUBLIC"]!)[templateID]!)[buyer]! - 1
		)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSaleMaxTokens(newSaleMaxTokens:{ String:{ UInt64: UInt64}}){ 
			WineMinter.saleMaxTokens = newSaleMaxTokens
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSalePrices(newSalePrices:{ String:{ UInt64: UFix64}}){ 
			WineMinter.salePrices = newSalePrices
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMerchantAccounts(newMerchantAccounts:{ String: Address}){ 
			WineMinter.merchantAccounts = newMerchantAccounts
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pruneSaleAccounts(){ 
			WineMinter.saleAccounts ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSaleAccounts():{ String:{ UInt64:{ Address: UInt64}}}{ 
		return self.saleAccounts
	}
	
	init(){ 
		self.AdminStoragePath = /storage/CollectorMinterAdmin
		self.saleMaxTokens ={} 
		self.salePrices ={} 
		self.saleAccounts ={} 
		
		// For DUC testnet this should be 0x03df89ac89a3d64a
		// For DUC mainnet this should be 0xfe15c4f52a58c75e
		self.merchantAccounts ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
