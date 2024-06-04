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
import InceptionAvatar from "./InceptionAvatar.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import InceptionCrystal from "./InceptionCrystal.cdc"

import InceptionBlackBox from "./InceptionBlackBox.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract InceptionExchange{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let AdminStoragePath: StoragePath
	
	// Resets weekly
	access(self)
	var BlackBoxTokenIDToRedemptionTimeInSeconds:{ UInt64: UInt64}
	
	access(self)
	var InceptionAvatarTokenIDToRedemptionTimeInSeconds:{ UInt64: UInt64}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCurrentBlockTimeInSeconds(): UInt64{ 
		return UInt64(getCurrentBlock().timestamp)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun claimInceptionCrystalWithBlackBox(signerAuth: AuthAccount, tokenID: UInt64){ 
		// Check blackbox collection to ensure ownership
		let tokenIDs =
			getAccount(signerAuth.address).capabilities.get<&InceptionBlackBox.Collection>(
				InceptionBlackBox.CollectionPublicPath
			).borrow()?.getIDs()
		if !(tokenIDs!).contains(tokenID){ 
			panic("tokenID not found in signer's collection")
		}
		
		// Verify the time has passed the last claim time
		let nextClaimTime = self.getNextInceptionBlackBoxRedemptionTimeInSeconds(tokenID: tokenID)
		if UInt64(getCurrentBlock().timestamp) < nextClaimTime{ 
			panic("Cannot claim InceptionCrystal yet")
		}
		let InceptionCrystalAdmin =
			self.account.storage.borrow<&InceptionCrystal.Admin>(
				from: InceptionCrystal.AdminStoragePath
			)
			?? panic("Could not borrow a reference to the InceptionCrystal Admin")
		
		// Setup the recipient's collection if it doesn't exist
		if signerAuth.borrow<&InceptionCrystal.Collection>(
			from: InceptionCrystal.CollectionStoragePath
		)
		== nil{ 
			let collection <-
				InceptionCrystal.createEmptyCollection(
					nftType: Type<@InceptionCrystal.Collection>()
				)
			signerAuth.save(<-collection, to: InceptionCrystal.CollectionStoragePath)
			signerAuth.link<&InceptionCrystal.Collection>(
				InceptionCrystal.CollectionPublicPath,
				target: InceptionCrystal.CollectionStoragePath
			)
		}
		let recipient = getAccount(signerAuth.address)
		let InceptionCrystalReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				InceptionCrystal.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the InceptionCrystal Collection")
		
		// Mint 7 InceptionCrystal to the recipient
		for i in [0, 1, 2, 3, 4, 5, 6]{ 
			InceptionCrystalAdmin.mintInceptionCrystal(recipient: InceptionCrystalReceiver)
		}
		
		// Update the BlackBoxTokenIDToRedemptionTime
		InceptionExchange.BlackBoxTokenIDToRedemptionTimeInSeconds[tokenID] = UInt64(
				getCurrentBlock().timestamp
			)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun exchangeCrystalForFlowToken(signerAuth: AuthAccount, amount: UInt64){ 
		// Check InceptionCrystal balance
		let tokenIDs =
			getAccount(signerAuth.address).capabilities.get<&InceptionCrystal.Collection>(
				InceptionCrystal.CollectionPublicPath
			).borrow()?.getIDs()
		if UInt64((tokenIDs!).length) < amount{ 
			panic("Not enough InceptionCrystal to exchange")
		}
		
		// Burn crystals
		let signerCollectionRef =
			signerAuth.borrow<&InceptionCrystal.Collection>(
				from: InceptionCrystal.CollectionStoragePath
			)
			?? panic("Could not borrow a reference to the signer's InceptionCrystal collection")
		let payingCrystalCollection <-
			signerCollectionRef.batchWithdrawInceptionCrystals(amount: amount)
		destroy payingCrystalCollection
		
		// Transfer FlowToken to the user
		let recipient = getAccount(signerAuth.address)
		let recipientFlowTokenRef =
			recipient.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow()
			?? panic("Could not borrow a reference to the recipient's Vault")
		let selfFlowWithdrawVault <-
			(self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!)
				.withdraw(amount: 0.002 * UFix64(amount))
		recipientFlowTokenRef.deposit(from: <-selfFlowWithdrawVault)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNextInceptionBlackBoxRedemptionTimeInSeconds(tokenID: UInt64): UInt64{ 
		let lastClaimTime = InceptionExchange.BlackBoxTokenIDToRedemptionTimeInSeconds[tokenID] ?? 0
		return lastClaimTime + 86400 * 7
	}
	
	access(all)
	resource Admin{} 
	
	init(){ 
		self.AdminStoragePath = /storage/InceptionExchangeAdmin
		self.BlackBoxTokenIDToRedemptionTimeInSeconds ={} 
		self.InceptionAvatarTokenIDToRedemptionTimeInSeconds ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
