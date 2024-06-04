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

import Collector from "./Collector.cdc"

access(all)
contract CollectorMinter{ 
	access(all)
	event ContractInitialized(merchantAccount: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var privateSaleMaxTokens: UInt64
	
	access(all)
	var privateSalePrice: UFix64
	
	access(all)
	var presaleMaxTokens: UInt64
	
	access(all)
	var presalePrice: UFix64
	
	access(all)
	var publicSaleMaxTokens: UInt64
	
	access(all)
	var publicSalePrice: UFix64
	
	access(all)
	var privateSaleRegistrationOpen: Bool
	
	access(all)
	var presaleRegistrationOpen: Bool
	
	access(self)
	var privateSaleAccounts:{ Address: UInt64}
	
	access(self)
	var presaleAccounts:{ Address: UInt64}
	
	access(self)
	var publicSaleAccounts:{ Address: UInt64}
	
	access(all)
	var merchantAccount: Address
	
	access(TMP_ENTITLEMENT_OWNER)
	fun registerForPrivateSale(buyer: Address){ 
		pre{ 
			self.privateSaleRegistrationOpen == true:
				"Private sale registration is closed"
			self.privateSaleAccounts[buyer] == nil:
				"Address already registered for the private sale"
		}
		self.privateSaleAccounts[buyer] = self.privateSaleMaxTokens
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun privateSaleMintNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		numberOfTokens: UInt64,
		merchantAccount: Address
	){ 
		pre{ 
			self.privateSaleAccounts[buyer]! >= 0:
				"Requesting account is not whitelisted"
			numberOfTokens <= self.privateSaleMaxTokens:
				"Purchase amount exceeds maximum allowed"
			self.privateSaleAccounts[buyer]! >= numberOfTokens:
				"Purchase amount exceeds maximum buyer allowance"
			paymentVault.balance >= UFix64(numberOfTokens) * self.privateSalePrice:
				"Insufficient payment amount"
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"Payment type not DapperUtilityCoin"
			self.merchantAccount == merchantAccount:
				"Mismatching merchant account"
		}
		let admin =
			self.account.storage.borrow<&Collector.Admin>(from: Collector.AdminStoragePath)
			?? panic("Could not borrow a reference to the collector admin")
		let set = admin.borrowSet(id: setID)
		
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		
		// Check set eligibility
		if set.isPublic{ 
			panic("Cannot mint public set with privateSaleMintNFTWithDUC")
		}
		
		// Get DUC receiver reference of Collector merchant account
		let merchantDUCReceiverRef =
			getAccount(self.merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 
		 // Deposit DUC to Collector merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Collector
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Collector.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT collection")
		
		// Mint Collector NFTs
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
		
		// Remove utilized spots
		self.privateSaleAccounts[buyer] = self.privateSaleAccounts[buyer]! - numberOfTokens
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun registerForPresale(buyer: Address){ 
		pre{ 
			self.presaleRegistrationOpen == true:
				"Presale registration is closed"
			self.presaleAccounts[buyer] == nil:
				"Address already registered for the presale"
		}
		self.presaleAccounts[buyer] = self.presaleMaxTokens
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun presaleMintNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		numberOfTokens: UInt64,
		merchantAccount: Address
	){ 
		pre{ 
			self.presaleAccounts[buyer]! >= 0:
				"Requesting account is not whitelisted"
			numberOfTokens <= self.presaleMaxTokens:
				"Purchase amount exceeds maximum allowed"
			self.presaleAccounts[buyer]! >= numberOfTokens:
				"Purchase amount exceeds maximum buyer allowance"
			paymentVault.balance >= UFix64(numberOfTokens) * self.presalePrice:
				"Insufficient payment amount"
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"Payment type not DapperUtilityCoin"
			self.merchantAccount == merchantAccount:
				"Mismatching merchant account"
			Collector.totalSupply < 3506:
				"Reached max capacity"
		}
		let admin =
			self.account.storage.borrow<&Collector.Admin>(from: Collector.AdminStoragePath)
			?? panic("Could not borrow a reference to the collector admin")
		let set = admin.borrowSet(id: setID)
		
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		
		// Check set eligibility
		if set.isPublic{ 
			panic("Cannot mint public set with presaleMintNFTWithDUC")
		}
		
		// Get DUC receiver reference of Collector merchant account
		let merchantDUCReceiverRef =
			getAccount(self.merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 
		 // Deposit DUC to Collector merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Collector
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Collector.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT collection")
		
		// Mint Collector NFTs
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
		
		// Remove utilized spots
		self.presaleAccounts[buyer] = self.presaleAccounts[buyer]! - numberOfTokens
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun publicSaleMintNFTWithDUC(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		numberOfTokens: UInt64,
		merchantAccount: Address
	){ 
		pre{ 
			numberOfTokens <= self.publicSaleMaxTokens:
				"Purchase amount exeeds maximum allowed"
			paymentVault.balance >= UFix64(numberOfTokens) * self.publicSalePrice:
				"Insufficient payment amount"
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"Payment type not DapperUtilityCoin"
			self.merchantAccount == merchantAccount:
				"Mismatching merchant account"
			Collector.totalSupply < 3506:
				"Reached max capacity"
		}
		
		// Add address to public sale accounts list
		if self.publicSaleAccounts[buyer] == nil{ 
			self.publicSaleAccounts[buyer] = self.publicSaleMaxTokens
		}
		
		// Check buyer hasn't exceeded their allowance
		if self.publicSaleAccounts[buyer]! < numberOfTokens{ 
			panic("Purchase amount exceeds maximum buyer allowance")
		}
		let admin =
			self.account.storage.borrow<&Collector.Admin>(from: Collector.AdminStoragePath)
			?? panic("Could not borrow a reference to the collector admin")
		let set = admin.borrowSet(id: setID)
		
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		
		// Check set eligibility
		if !set.isPublic{ 
			panic("Cannot mint private set with publicSaleMintNFTWithDUC")
		}
		
		// Get DUC receiver reference of Collector merchant account
		let merchantDUCReceiverRef =
			getAccount(self.merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 
		 // Deposit DUC to Collector merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Collector
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Collector.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Collector NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
		
		// Remove utilized spots
		self.publicSaleAccounts[buyer] = self.publicSaleAccounts[buyer]! - numberOfTokens
	}
	
	access(all)
	resource Admin{ 
		//
		// PRIVATE SALE FUNCTIONS
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccountToPrivateSale(address: Address, amount: UInt64){ 
			pre{ 
				amount <= CollectorMinter.privateSaleMaxTokens:
					"Unable to allocate more private sale spots"
				CollectorMinter.privateSaleAccounts[address] == nil:
					"Provided address already added to the private sale"
			}
			CollectorMinter.privateSaleAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccountFromPrivateSale(address: Address){ 
			pre{ 
				CollectorMinter.privateSaleAccounts[address] != nil:
					"Provided address is not in the private sale list"
			}
			CollectorMinter.privateSaleAccounts.remove(key: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePrivateSaleAccountAmount(address: Address, amount: UInt64){ 
			pre{ 
				CollectorMinter.privateSaleAccounts[address] != nil:
					"Provided address is not in the private sale list"
			}
			CollectorMinter.privateSaleAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePrivateSaleMaxTokens(amount: UInt64){ 
			CollectorMinter.privateSaleMaxTokens = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePrivateSalePrice(price: UFix64){ 
			CollectorMinter.privateSalePrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun prunePrivateSaleAccounts(){ 
			CollectorMinter.privateSaleAccounts ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun closePrivateSaleRegistration(){ 
			CollectorMinter.privateSaleRegistrationOpen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPrivateSaleRegistration(){ 
			CollectorMinter.privateSaleRegistrationOpen = true
		}
		
		//
		// PRESALE FUNCTIONS
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccountToPresale(address: Address, amount: UInt64){ 
			pre{ 
				amount <= CollectorMinter.presaleMaxTokens:
					"Unable to allocate more presale spots"
				CollectorMinter.presaleAccounts[address] == nil:
					"Provided address already added to the presale"
			}
			CollectorMinter.presaleAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccountFromPresale(address: Address){ 
			pre{ 
				CollectorMinter.presaleAccounts[address] != nil:
					"Provided address is not in the presale list"
			}
			CollectorMinter.presaleAccounts.remove(key: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePresaleAccountAmount(address: Address, amount: UInt64){ 
			pre{ 
				CollectorMinter.presaleAccounts[address] != nil:
					"Provided address is not in the presale list"
			}
			CollectorMinter.presaleAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePresaleMaxTokens(amount: UInt64){ 
			CollectorMinter.presaleMaxTokens = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePresalePrice(price: UFix64){ 
			CollectorMinter.presalePrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun prunePresaleAccounts(){ 
			CollectorMinter.presaleAccounts ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun closePresaleRegistration(){ 
			CollectorMinter.presaleRegistrationOpen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPresaleRegistration(){ 
			CollectorMinter.presaleRegistrationOpen = true
		}
		
		//
		// PUBLIC SALE FUNCTIONS
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePublicSaleMaxTokens(amount: UInt64){ 
			CollectorMinter.publicSaleMaxTokens = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePublicSalePrice(price: UFix64){ 
			CollectorMinter.publicSalePrice = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun prunePublicSaleAccounts(){ 
			CollectorMinter.publicSaleAccounts ={} 
		}
		
		//
		// COMMON
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMerchantAccount(newAddr: Address){ 
			CollectorMinter.merchantAccount = newAddr
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPrivateSaleAccounts():{ Address: UInt64}{ 
		return self.privateSaleAccounts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPresaleAccounts():{ Address: UInt64}{ 
		return self.presaleAccounts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPublicSaleAccounts():{ Address: UInt64}{ 
		return self.publicSaleAccounts
	}
	
	init(merchantAccount: Address){ 
		self.AdminStoragePath = /storage/CollectorMinterAdmin
		self.privateSaleRegistrationOpen = true
		self.presaleRegistrationOpen = true
		self.privateSaleMaxTokens = 1
		self.privateSalePrice = 10.00
		self.privateSaleAccounts ={} 
		self.presaleMaxTokens = 3
		self.presalePrice = 129.00
		self.presaleAccounts ={} 
		self.publicSaleMaxTokens = 3
		self.publicSalePrice = 179.00
		self.publicSaleAccounts ={} 
		
		// For testnet this should be 0x03df89ac89a3d64a
		// For mainnet this should be 0xfe15c4f52a58c75e
		self.merchantAccount = merchantAccount
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized(merchantAccount: merchantAccount)
	}
}
