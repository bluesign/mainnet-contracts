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

	import Analogs from "./Analogs.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

access(all)
contract AnalogMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var mintableSets:{ UInt64: MintableSet}
	
	access(all)
	struct MintableSet{ 
		access(all)
		var privateSalePrice: UFix64
		
		access(all)
		var publicSalePrice: UFix64
		
		access(all)
		var whitelistedAccounts:{ Address: UInt64}
		
		access(self)
		var metadata:{ String: String}
		
		access(account)
		fun addWhiteListAddress(address: Address, amount: UInt64){ 
			pre{ 
				self.whitelistedAccounts[address] == nil:
					"Provided Address is already whitelisted"
			}
			self.whitelistedAccounts[address] = amount
		}
		
		access(account)
		fun removeWhiteListAddress(address: Address){ 
			pre{ 
				self.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			self.whitelistedAccounts.remove(key: address)
		}
		
		access(account)
		fun pruneWhitelist(){ 
			self.whitelistedAccounts ={} 
		}
		
		access(account)
		fun updateWhiteListAddressAmount(address: Address, amount: UInt64){ 
			pre{ 
				self.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			self.whitelistedAccounts[address] = amount
		}
		
		access(account)
		fun updatePrivateSalePrice(price: UFix64){ 
			self.privateSalePrice = price
		}
		
		access(account)
		fun updatePublicSalePrice(price: UFix64){ 
			self.publicSalePrice = price
		}
		
		init(privateSalePrice: UFix64, publicSalePrice: UFix64){ 
			self.privateSalePrice = privateSalePrice
			self.publicSalePrice = publicSalePrice
			self.whitelistedAccounts ={} 
			self.metadata ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintPrivateNFTWithFUT(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			(AnalogMinter.mintableSets[setID]!).whitelistedAccounts[buyer]! >= 1:
				"Requesting account is not whitelisted"
			// This code is commented for future use case. In case addresses needs a buy amount limit for private sales, this should be discommented.
			// AnalogMinter.mintableSets[setID]!.whitelistedAccounts[buyer]! >= numberOfTokens: "purchaseAmount exceeds allowed whitelist spots"
			paymentVault.balance >= UFix64(numberOfTokens) * (AnalogMinter.mintableSets[setID]!).privateSalePrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowUtilityToken.Vault>():
				"payment type not FlowUtilityToken.Vault."
		}
		let admin =
			self.account.storage.borrow<&Analogs.Admin>(from: Analogs.AdminStoragePath)
			?? panic("Could not borrow a reference to the Analogs Admin")
		let set = admin.borrowSet(setID: setID)
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		// Check set eligibility
		if set.locked{ 
			panic("Set is locked")
		}
		if set.isPublic{ 
			panic("Cannot mint public set with mintPrivateNFTWithFUT")
		}
		
		// Get FUT receiver reference of Analogs merchant account
		let merchantFUTReceiverRef =
			getAccount(set.analogRoyaltyAddress).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowUtilityTokenReceiver
			)
		assert(
			merchantFUTReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant FUT receiver"
		)
		(		 // Deposit FUT to Analogs merchant account FUT Vault (it's then forwarded to the main FUT contract afterwards)
		 merchantFUTReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Analogs
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Analogs.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Analogs NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
		
		// Empty whitelist spot
		if (AnalogMinter.mintableSets[setID]!).whitelistedAccounts[buyer]! - numberOfTokens == 0{ 
			(AnalogMinter.mintableSets[setID]!).removeWhiteListAddress(address: buyer)
		} else{ 
			let newAmount = (AnalogMinter.mintableSets[setID]!).whitelistedAccounts[buyer]! - numberOfTokens
			(AnalogMinter.mintableSets[setID]!).updateWhiteListAddressAmount(address: buyer, amount: newAmount)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintPublicNFTWithFUT(
		buyer: Address,
		setID: UInt64,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			numberOfTokens <= 4:
				"purchaseAmount too large"
			paymentVault.balance >= UFix64(numberOfTokens) * (AnalogMinter.mintableSets[setID]!).publicSalePrice:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@FlowUtilityToken.Vault>():
				"payment type not FlowUtilityToken.Vault."
		}
		let admin =
			self.account.storage.borrow<&Analogs.Admin>(from: Analogs.AdminStoragePath)
			?? panic("Could not borrow a reference to the Analogs Admin")
		let set = admin.borrowSet(setID: setID)
		// Check set availability
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		// Check set eligibility
		if set.locked{ 
			panic("Set is locked")
		}
		if !set.isPublic{ 
			panic("Cannot mint private set with mintPublicNFTWithFUT")
		}
		
		// Get FUT receiver reference of Analogs merchant account
		let merchantFUTReceiverRef =
			getAccount(set.analogRoyaltyAddress).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowUtilityTokenReceiver
			)
		assert(
			merchantFUTReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant FUT receiver"
		)
		(		 // Deposit FUT to Analogs merchant account FUT Vault (it's then forwarded to the main FUT contract afterwards)
		 merchantFUTReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive Analogs
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Analogs.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint Analogs NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintFreeNFT(buyer: Address, numberOfTokens: UInt64){ 
		pre{ 
			numberOfTokens > 0:
				"numberOfTokens must be greater than 0"
		}
		let setID: UInt64 = 1
		var mintedCount: UInt64? = (AnalogMinter.mintableSets[setID]!).whitelistedAccounts[buyer]
		if mintedCount == nil{ 
			mintedCount = 0
			(AnalogMinter.mintableSets[setID]!).addWhiteListAddress(address: buyer, amount: numberOfTokens)
		} else{ 
			(AnalogMinter.mintableSets[setID]!).updateWhiteListAddressAmount(address: buyer, amount: mintedCount! + numberOfTokens)
		}
		assert(mintedCount! + numberOfTokens <= 5, message: "You exceed the minting limit")
		let admin =
			self.account.storage.borrow<&Analogs.Admin>(from: Analogs.AdminStoragePath)
			?? panic("Could not borrow a reference to the Analogs Admin")
		let set = admin.borrowSet(setID: setID)
		if set.getAvailableTemplateIDs().length == 0{ 
			panic("Set is empty")
		}
		if set.locked{ 
			panic("Set is locked")
		}
		let buyerFUTReceiverRef =
			getAccount(buyer).capabilities.get<&{FungibleToken.Receiver}>(
				/public/flowUtilityTokenReceiver
			)
		assert(
			buyerFUTReceiverRef.borrow() != nil,
			message: "Missing or mis-typed buyer FUT receiver"
		)
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Analogs.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			admin.mintNFT(recipient: NFTReceiver, setID: setID)
			mintCounter = mintCounter - 1
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createMintableSet(setID: UInt64, privateSalePrice: UFix64, publicSalePrice: UFix64){ 
			pre{ 
				AnalogMinter.mintableSets[setID] == nil:
					"Set already exists"
			}
			AnalogMinter.mintableSets[setID] = MintableSet(
					privateSalePrice: privateSalePrice,
					publicSalePrice: publicSalePrice
				)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addWhiteListAddress(setID: UInt64, address: Address, amount: UInt64){ 
			(AnalogMinter.mintableSets[setID]!).addWhiteListAddress(
				address: address,
				amount: amount
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeWhiteListAddress(setID: UInt64, address: Address){ 
			(AnalogMinter.mintableSets[setID]!).removeWhiteListAddress(address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pruneWhitelist(setID: UInt64){ 
			(AnalogMinter.mintableSets[setID]!).pruneWhitelist()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateWhiteListAddressAmount(setID: UInt64, address: Address, amount: UInt64){ 
			(AnalogMinter.mintableSets[setID]!).updateWhiteListAddressAmount(
				address: address,
				amount: amount
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePrivateSalePrice(setID: UInt64, price: UFix64){ 
			(AnalogMinter.mintableSets[setID]!).updatePrivateSalePrice(price: price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePublicSalePrice(setID: UInt64, price: UFix64){ 
			(AnalogMinter.mintableSets[setID]!).updatePublicSalePrice(price: price)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhitelistedAccounts(setID: UInt64):{ Address: UInt64}{ 
		return (AnalogMinter.mintableSets[setID]!).whitelistedAccounts
	}
	
	init(){ 
		self.AdminStoragePath = /storage/AnalogMinterAdmin
		self.mintableSets ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
