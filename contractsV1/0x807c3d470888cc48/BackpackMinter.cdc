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
import Flunks from "./Flunks.cdc"

import Backpack from "./Backpack.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract BackpackMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event BackpackClaimed(FlunkTokenID: UInt64, BackpackTokenID: UInt64, signer: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var backpackClaimedPerFlunkTokenID:{ UInt64: UInt64} // Flunk token ID: backpack token ID
	
	
	access(self)
	var backpackClaimedPerFlunkTemplate:{ UInt64: UInt64} // Flunks template ID: backpack token ID
	
	
	access(TMP_ENTITLEMENT_OWNER)
	fun claimBackPack(tokenID: UInt64, signer: AuthAccount, setID: UInt64){ 
		// verify that the token is not already claimed
		pre{ 
			tokenID >= 0 && tokenID <= 9998:
				"Invalid Flunk token ID"
			!BackpackMinter.backpackClaimedPerFlunkTokenID.containsKey(tokenID):
				"Token ID already claimed"
		}
		
		// verify Flunk ownership
		let collection =
			getAccount(signer.address).capabilities.get<&Flunks.Collection>(
				Flunks.CollectionPublicPath
			).borrow()!
		let collectionIDs = collection.getIDs()
		if !collectionIDs.contains(tokenID){ 
			panic("signer is not owner of Flunk")
		}
		
		// Get recipient receiver capoatility
		let recipient = getAccount(signer.address)
		let backpackReceiver =
			recipient.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				Backpack.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>()
			?? panic("Could not get receiver reference to the Backpack NFT Collection")
		
		// mint backpack to signer
		let admin =
			self.account.storage.borrow<&Backpack.Admin>(from: Backpack.AdminStoragePath)
			?? panic("Could not borrow a reference to the Backpack Admin")
		let backpackSet = admin.borrowSet(setID: setID)
		let backpackNFT <- backpackSet.mintNFT()
		let backpackTokenID = backpackNFT.id
		emit BackpackClaimed(
			FlunkTokenID: tokenID,
			BackpackTokenID: backpackNFT.id,
			signer: signer.address
		)
		backpackReceiver.deposit(token: <-backpackNFT)
		BackpackMinter.backpackClaimedPerFlunkTokenID[tokenID] = backpackTokenID
		let templateID = (collection.borrowFlunks(id: tokenID)!).templateID
		BackpackMinter.backpackClaimedPerFlunkTemplate[templateID] = backpackTokenID
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getClaimedBackPacksPerFlunkTokenID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTokenID
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getClaimedBackPacksPerFlunkTemplateID():{ UInt64: UInt64}{ 
		return BackpackMinter.backpackClaimedPerFlunkTemplate
	}
	
	init(){ 
		self.AdminStoragePath = /storage/BackpackMinterAdmin
		self.backpackClaimedPerFlunkTokenID ={} 
		self.backpackClaimedPerFlunkTemplate ={} 
		emit ContractInitialized()
	}
}
