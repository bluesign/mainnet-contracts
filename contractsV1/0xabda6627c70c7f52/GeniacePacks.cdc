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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import GeniaceAuction from "../0xabda6627c70c7f52;/GeniaceAuction.cdc"

// This contract is to support the mystery packs functionality in Geniace platform
// In here, there are functions to do manage the payment for the mysterypack, as well as
// there is a resource that is to support the concept of collection capability transfer
// which is similar to the concept of allownce in erc721 Ethereum standerad 
access(all)
contract GeniacePacks{ 
	access(all)
	struct SaleCutEventData{ 
		
		// Address of the salecut receiver
		access(all)
		let receiver: Address
		
		// The amount of the payment FungibleToken that will be paid to the receiver.
		access(all)
		let percentage: UFix64
		
		// initializer
		//
		init(receiver: Address, percentage: UFix64){ 
			self.receiver = receiver
			self.percentage = percentage
		}
	}
	
	access(all)
	event Purchased(
		collectionName: String,
		tier: String,
		packIDs: [
			String
		],
		price: UFix64,
		currency: Type,
		buyerAddress: Address,
		saleCuts: [
			SaleCutEventData
		]
	)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun purchase(
		collectionName: String,
		tier: String,
		paymentVaultType: Type,
		packIDs: [
			String
		],
		price: UFix64,
		buyerAddress: Address,
		paymentVault: @{FungibleToken.Vault},
		saleCuts: [
			GeniaceAuction.SaleCut
		]
	){ 
		pre{ 
			paymentVault.balance == price:
				"payment does not equal offer price"
			paymentVault.isInstance(paymentVaultType):
				"payment vault is not requested fungible token"
		}
		
		// Rather than aborting the transaction if any receiver is absent when we try to pay it,
		// we send the cut to the first valid receiver.
		// The first receiver should therefore either be the seller, or an agreed recipient for
		// any unpaid cuts.
		var residualReceiver: &{FungibleToken.Receiver}? = nil
		
		// This struct is a helper to map the sale cut address and percentage
		// and pass it into the events
		var saleCutsEventMapping: [SaleCutEventData] = []
		
		// Pay each beneficiary their amount of the payment.
		for cut in saleCuts{ 
			if let receiver = cut.receiver.borrow(){ 
				
				//Withdraw cutPercentage to marketplace and put it in their vault
				let amount = price * cut.percentage
				let paymentCut <- paymentVault.withdraw(amount: amount)
				receiver.deposit(from: <-paymentCut)
				if residualReceiver == nil{ 
					residualReceiver = receiver
				}
				
				// 
				saleCutsEventMapping.append(SaleCutEventData(receiver: (receiver.owner!).address, percentage: cut.percentage))
			}
		}
		assert(residualReceiver != nil, message: "No valid payment receivers")
		(		 
		 // At this point, if all recievers were active and availabile, then the payment Vault will have
		 // zero tokens left, and this will functionally be a no-op that consumes the empty vault
		 residualReceiver!).deposit(from: <-paymentVault.withdraw(amount: paymentVault.balance))
		destroy paymentVault
		emit Purchased(
			collectionName: collectionName,
			tier: tier,
			packIDs: packIDs,
			price: price,
			currency: paymentVaultType,
			buyerAddress: buyerAddress,
			saleCuts: saleCutsEventMapping
		)
	}
	
	// publically assessible functions
	access(all)
	resource interface collectionCapabilityPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setCollectionCapability(
			collectionOwner: Address,
			capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isCapabilityExist(collectionOwner: Address): Bool
	}
	
	// Prviate functions
	access(all)
	resource interface collectionCapabilityManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionCapability(collectionOwner: Address): &{
			NonFungibleToken.Provider,
			NonFungibleToken.CollectionPublic
		}
	}
	
	// This resource is using to hold an NFT Collection Capabilty of multiple accounts,
	// In this way one account can transfer NFT's behalf of it's original owner
	// This is work similar to the concept of approval-allowance of the erc721 standerad 
	access(all)
	resource collectionCapabilityHolder: collectionCapabilityPublic, collectionCapabilityManager{ 
		
		// This dictionary variable will hold the address-capabilty pair
		access(self)
		var collectionCapabilityList:{ Address: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>}
		
		// The owner of the NFT collection will create a private capability of his collection
		// transer it to the collection holder using this publically assessible function
		access(TMP_ENTITLEMENT_OWNER)
		fun setCollectionCapability(collectionOwner: Address, capability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.collectionCapabilityList[collectionOwner] = capability
		}
		
		// This publically accessible function will be used to check weather a collection capability
		// of a specific account is available or not
		access(TMP_ENTITLEMENT_OWNER)
		fun isCapabilityExist(collectionOwner: Address): Bool{ 
			let ref = self.collectionCapabilityList[collectionOwner]?.borrow()
			if ref == nil{ 
				return false
			}
			return true
		}
		
		// This private function can be used to fetch the stored capability of a specific user
		// and can call the private functions such as 'withdraw'
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionCapability(collectionOwner: Address): &{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}{ 
			let ref = (self.collectionCapabilityList[collectionOwner]!).borrow()!
			return ref
		}
		
		init(){ 
			self.collectionCapabilityList ={} 
		}
	}
	
	// Public function to create and return collectionCapabilityHolder resource
	access(TMP_ENTITLEMENT_OWNER)
	fun createCapabilityHolder(): @collectionCapabilityHolder{ 
		return <-create collectionCapabilityHolder()
	}
}
