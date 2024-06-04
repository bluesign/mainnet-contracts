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

	import KlktnNFT2 from "./KlktnNFT2.cdc"

import KlktnNFTTimestamps from "./KlktnNFTTimestamps.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract KlktnNFTProxy{ 
	
	// Emitted when KlktnNFT contract is created
	access(all)
	event ContractInitialized()
	
	// mintNFTWithFlow deposits FLOW & mints the next available serialNumber for NFT of typeID
	access(TMP_ENTITLEMENT_OWNER)
	fun mintNFTWithFlow(
		recipient: &{NonFungibleToken.CollectionPublic},
		typeID: UInt64,
		paymentVault: @{FungibleToken.Vault}
	){ 
		pre{ 
			!KlktnNFT2.isNFTTemplateExpired(typeID: typeID):
				"NFT of this typeID does not exist or is no longer being offered."
			paymentVault.balance >= KlktnNFT2.getNFTTemplateInfo(typeID: typeID).priceFlow:
				"Insufficient payment."
			paymentVault.getType() == Type<@FlowToken.Vault>():
				"payment type not FlowToken.Vault."
			KlktnNFTTimestamps.getNFTTemplateTimestamps(typeID: typeID).getTimestamps()["availableAt"]! <= getCurrentBlock().timestamp:
				"sale has not started"
			KlktnNFTTimestamps.getNFTTemplateTimestamps(typeID: typeID).getTimestamps()["expiresAt"]! >= getCurrentBlock().timestamp:
				"sale has ended"
		}
		let adminFlowReceiverRef =
			self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
				.borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the admin's Vault")
		adminFlowReceiverRef.deposit(from: <-paymentVault)
		let admin =
			self.account.storage.borrow<&KlktnNFT2.Admin>(from: KlktnNFT2.AdminStoragePath)
			?? panic("Could not borrow a reference to the KlktnNFT2 Admin")
		admin.mintNextAvailableNFT(recipient: recipient, typeID: typeID, metadata:{} )
	}
	
	init(){ 
		emit ContractInitialized()
	}
}
