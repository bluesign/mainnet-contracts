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

import StarVaultFactory from "../0x5c6dad1decebccb4/StarVaultFactory.cdc"

import StarVaultConfig from "../0x5c6dad1decebccb4/StarVaultConfig.cdc"

import StarVaultInterfaces from "../0x5c6dad1decebccb4/StarVaultInterfaces.cdc"

access(all)
contract Migrator{ 
	access(all)
	let vaultAddress: Address
	
	access(all)
	let fromTokenKey: String
	
	access(TMP_ENTITLEMENT_OWNER)
	fun migrate(from: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
		pre{ 
			from.balance > 0.0:
				"from vault no balance"
			self.fromTokenKey == StarVaultConfig.SliceTokenTypeIdentifierFromVaultType(vaultTypeIdentifier: from.getType().identifier):
				"from vault type error"
		}
		let balance = from.balance
		destroy from
		let collectionRef =
			self.account.storage.borrow<&StarVaultFactory.VaultTokenCollection>(
				from: StarVaultConfig.VaultTokenCollectionStoragePath
			)!
		return <-collectionRef.withdraw(vault: self.vaultAddress, amount: balance)
	}
	
	init(fromTokenKey: String, vaultAddress: Address){ 
		self.fromTokenKey = fromTokenKey
		self.vaultAddress = vaultAddress
		let collection <- StarVaultFactory.createEmptyVaultTokenCollection()
		let storagePath = StarVaultConfig.VaultTokenCollectionStoragePath
		self.account.storage.save(<-collection, to: storagePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&StarVaultFactory.VaultTokenCollection>(
				storagePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: StarVaultConfig.VaultTokenCollectionPublicPath
		)
	}
}
