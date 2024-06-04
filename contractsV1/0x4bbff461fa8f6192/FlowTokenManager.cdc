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

import FlowStorageFees from "../0xe467b9dd11fa00df/FlowStorageFees.cdc"

access(all)
contract FlowTokenManager{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun TopUpFlowTokens(account: &Account, flowTokenProvider: &{FungibleToken.Provider}){ 
		if account.storage.used > account.storage.capacity{ 
			var extraStorageRequiredBytes = account.storage.used - account.storage.capacity
			var extraStorageRequiredMb = FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(extraStorageRequiredBytes)
			var flowRequired = FlowStorageFees.storageCapacityToFlow(extraStorageRequiredMb)
			let vault: @{FungibleToken.Vault} <- flowTokenProvider.withdraw(amount: flowRequired)
			((account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!).borrow()!).deposit(from: <-vault)
		}
	}
}
