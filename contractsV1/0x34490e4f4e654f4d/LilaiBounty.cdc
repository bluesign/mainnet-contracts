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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import LilaiQuest from "./LilaiQuest.cdc"

import LilaiMarket from "./LilaiMarket.cdc"

access(all)
contract LilaiBounty{ 
	access(all)
	var questFulfillments:{ UInt64: Fulfillment}
	
	access(all)
	struct Fulfillment{ 
		access(all)
		let questId: UInt64
		
		access(all)
		let fulfiller: Address
		
		access(all)
		var submissionMetadata:{ String: String}
		
		access(all)
		var status: String
		
		access(all)
		let bounty: UFix64
		
		init(
			questId: UInt64,
			fulfiller: Address,
			submissionMetadata:{ 
				String: String
			},
			bounty: UFix64
		){ 
			self.questId = questId
			self.fulfiller = fulfiller
			self.submissionMetadata = submissionMetadata
			self.status = "Pending"
			self.bounty = bounty
		}
	}
	
	// Function to submit fulfillment details
	access(TMP_ENTITLEMENT_OWNER)
	fun submitFulfillment(
		questId: UInt64,
		fulfiller: Address,
		submissionMetadata:{ 
			String: String
		},
		bounty: UFix64
	){ 
		let newFulfillment =
			Fulfillment(
				questId: questId,
				fulfiller: fulfiller,
				submissionMetadata: submissionMetadata,
				bounty: bounty
			)
		self.questFulfillments[questId] = newFulfillment
	}
	
	// Function for the requester to approve fulfillment and release bounty
	access(TMP_ENTITLEMENT_OWNER)
	fun approveFulfillment(questId: UInt64, buyer: Address, buyerVaultRef: &{FungibleToken.Vault}){ 
		let fulfillment = self.questFulfillments[questId]!
		assert(fulfillment.status == "Pending", message: "Fulfillment already processed")
		// Withdraw the bounty amount from the buyer's vault
		let bountyVault <- buyerVaultRef.withdraw(amount: fulfillment.bounty)
		// Get the fulfiller's public Vault capability
		let fulfillerVaultCap =
			getAccount(fulfillment.fulfiller).capabilities.get<&{FungibleToken.Vault}>(
				/public/FungibleTokenReceiver
			)
		// Deposit the bounty into the fulfiller's vault
		let fulfillerVaultRef =
			fulfillerVaultCap.borrow()
			?? panic("Could not borrow a reference to the fulfiller's vault")
		fulfillerVaultRef.deposit(from: <-bountyVault)
		fulfillment.status = "Approved"
		emit FulfillmentApproved(questId: questId, fulfiller: fulfillment.fulfiller)
	}
	
	// Function for the requester to reject fulfillment
	access(TMP_ENTITLEMENT_OWNER)
	fun rejectFulfillment(questId: UInt64, buyer: Address){ 
		let fulfillment = self.questFulfillments[questId]!
		assert(fulfillment.status == "Pending", message: "Fulfillment already processed")
		fulfillment.status = "Rejected"
		emit FulfillmentRejected(questId: questId, fulfiller: fulfillment.fulfiller)
	}
	
	// Events
	access(all)
	event FulfillmentApproved(questId: UInt64, fulfiller: Address)
	
	access(all)
	event FulfillmentRejected(questId: UInt64, fulfiller: Address)
	
	init(){ 
		self.questFulfillments ={} 
	}
}
