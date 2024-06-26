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

	// SPDX-License-Identifier: MIT
import JollyJokers from "./JollyJokers.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract JollyJokersMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var preSalePriceInDUC: UFix64
	
	access(all)
	var publicSalePriceInDUC: UFix64
	
	access(all)
	var preSaleMintLimitPerTx: UInt64
	
	access(all)
	var publicSaleMintLimitPerTx: UInt64
	
	access(self)
	var whitelistedAccounts:{ Address: UInt64}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintPreOrderNFTWithDUC(
		buyer: Address,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			JollyJokersMinter.whitelistedAccounts[buyer]! >= 1:
				"Requesting account is not whitelisted"
			numberOfTokens <= JollyJokersMinter.preSaleMintLimitPerTx:
				"purchaseAmount too large"
			JollyJokersMinter.whitelistedAccounts[buyer]! >= numberOfTokens:
				"purchaseAmount exeeds allowed whitelist spots"
			paymentVault.balance >= UFix64(numberOfTokens) * JollyJokersMinter.preSalePriceInDUC:
				"Insufficient payment amount."
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"payment type not DapperUtilityCoin.Vault."
		}
		let minter =
			self.account.storage.borrow<&JollyJokers.NFTMinter>(from: JollyJokers.MinterStoragePath)
			?? panic("Unable to borrow reference to the JJ NFTMinter")
		
		// Get DUC receiver reference of JollyJokers merchant account
		let merchantDUCReceiverRef =
			getAccount(merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 // Deposit DUC to JollyJokers merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive JollyJokers
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				JollyJokers.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint JollyJokers NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			minter.mintNFT(recipient: NFTReceiver)
			mintCounter = mintCounter - 1
		}
		
		// Empty whitelist spot
		if JollyJokersMinter.whitelistedAccounts[buyer]! - numberOfTokens == 0{ 
			JollyJokersMinter.whitelistedAccounts.remove(key: buyer)
		} else{ 
			JollyJokersMinter.whitelistedAccounts[buyer] = JollyJokersMinter.whitelistedAccounts[buyer]! - numberOfTokens
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintPublicNFTWithDUC(
		buyer: Address,
		paymentVault: @{FungibleToken.Vault},
		merchantAccount: Address,
		numberOfTokens: UInt64
	){ 
		pre{ 
			numberOfTokens <= JollyJokersMinter.publicSaleMintLimitPerTx:
				"purchaseAmount too large"
			paymentVault.getType() == Type<@DapperUtilityCoin.Vault>():
				"payment type not DapperUtilityCoin.Vault."
		}
		let price = JollyJokersMinter.getPriceForAddress(addr: buyer)
		assert(
			paymentVault.balance >= price * UFix64(numberOfTokens),
			message: "Insufficient payment amount."
		)
		let minter =
			self.account.storage.borrow<&JollyJokers.NFTMinter>(from: JollyJokers.MinterStoragePath)
			?? panic("Unable to borrow reference to the JJ NFTMinter")
		
		// Get DUC receiver reference of JollyJokers merchant account
		let merchantDUCReceiverRef =
			getAccount(merchantAccount).capabilities.get<&{FungibleToken.Receiver}>(
				/public/dapperUtilityCoinReceiver
			)
		assert(
			merchantDUCReceiverRef.borrow() != nil,
			message: "Missing or mis-typed merchant DUC receiver"
		)
		(		 // Deposit DUC to JollyJokers merchant account DUC Vault (it's then forwarded to the main DUC contract afterwards)
		 merchantDUCReceiverRef.borrow()!).deposit(from: <-paymentVault)
		
		// Get buyer collection public to receive JollyJokers
		let recipient = getAccount(buyer)
		let NFTReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				JollyJokers.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the NFT Collection")
		
		// Mint JollyJokers NFTs per purchaseAmount
		var mintCounter = numberOfTokens
		while mintCounter > 0{ 
			minter.mintNFT(recipient: NFTReceiver)
			mintCounter = mintCounter - 1
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addWhiteListAddress(address: Address, amount: UInt64){ 
			pre{ 
				amount <= 6:
					"Unable to allocate more than 6 whitelist spots"
			}
			JollyJokersMinter.whitelistedAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeWhiteListAddress(address: Address){ 
			pre{ 
				JollyJokersMinter.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			JollyJokersMinter.whitelistedAccounts.remove(key: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pruneWhitelist(){ 
			JollyJokersMinter.whitelistedAccounts ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateWhiteListAddressAmount(address: Address, amount: UInt64){ 
			pre{ 
				JollyJokersMinter.whitelistedAccounts[address] != nil:
					"Provided Address is not whitelisted"
			}
			JollyJokersMinter.whitelistedAccounts[address] = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePreSalePriceInDUC(price: UFix64){ 
			JollyJokersMinter.preSalePriceInDUC = price
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updatePublicSalePriceInDUC(price: UFix64){ 
			JollyJokersMinter.publicSalePriceInDUC = price
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhitelistedAccounts():{ Address: UInt64}{ 
		return JollyJokersMinter.whitelistedAccounts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWhitelistSpotsForAddress(address: Address): UInt64{ 
		return JollyJokersMinter.whitelistedAccounts[address] ?? 0
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPriceForAddress(addr: Address): UFix64{ 
		// if address has a joker, price is 99.0
		// does this address have any jokers?
		let cap =
			getAccount(addr).capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				JollyJokers.CollectionPublicPath
			)
		if !cap.check(){ 
			return JollyJokersMinter.publicSalePriceInDUC
		}
		let ids = (cap.borrow()!).getIDs()
		if ids.length > 0{ 
			return 99.0
		}
		
		// otherwise, price is JollyJokersMinter.publicSalePriceInDUC
		return JollyJokersMinter.publicSalePriceInDUC
	}
	
	init(){ 
		self.AdminStoragePath = /storage/JollyJokersWhitelistMinterAdmin
		self.preSalePriceInDUC = 299.00
		self.publicSalePriceInDUC = 299.00
		self.preSaleMintLimitPerTx = 6
		self.publicSaleMintLimitPerTx = 10
		self.whitelistedAccounts ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
