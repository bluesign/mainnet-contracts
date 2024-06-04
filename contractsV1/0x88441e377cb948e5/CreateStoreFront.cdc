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

	// SPDX-License-Identifier: Unlicense
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract CreateStoreFront{ 
	access(all)
	event CreateStoreFrontSubmit(storefrontAddress: Address)
	
	access(account)
	var beneficiaryCapability: Capability<&{FungibleToken.Receiver}>?
	
	access(account)
	var amount: UFix64
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createStorefront(storefrontAddress: Address, vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance == self.amount:
				"Amount does not match the amount"
			self.amount >= UFix64(0):
				"Configure the amount field"
		}
		((self.beneficiaryCapability!).borrow()!).deposit(from: <-vault)
		emit CreateStoreFrontSubmit(storefrontAddress: storefrontAddress)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBeneficiary(
			beneficiaryCapabilityReceiver: Capability<&{FungibleToken.Receiver}>
		){ 
			CreateStoreFront.beneficiaryCapability = beneficiaryCapabilityReceiver
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateAmount(amountReceiver: UFix64){ 
			CreateStoreFront.amount = amountReceiver
		}
	}
	
	init(){ 
		self.amount = UFix64(0)
		self.beneficiaryCapability = nil
		self.account.storage.save<@CreateStoreFront.Admin>(
			<-create Admin(),
			to: /storage/createStoreFrontAdmin
		)
	}
}
