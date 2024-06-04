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

access(all)
contract TFCPayouts{ 
	
	// Events
	access(all)
	event PayoutCompleted(to: Address, amount: UFix64, token: String)
	
	access(all)
	event ContractInitialized()
	
	// Named Paths
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun payout(
			to: Address,
			from: @{FungibleToken.Vault},
			paymentVaultType: Type,
			receiverPath: PublicPath
		){ 
			let amount = from.balance
			let receiver =
				getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(receiverPath).borrow<
					&{FungibleToken.Receiver}
				>()
				?? panic("Could not borrow receiver reference to the recipient's Vault")
			receiver.deposit(from: <-from)
			emit PayoutCompleted(to: to, amount: amount, token: paymentVaultType.identifier)
		}
	}
	
	init(){ 
		// Set our named paths
		self.AdminStoragePath = /storage/TFCPayoutsAdmin
		self.AdminPrivatePath = /private/TFCPayoutsPrivate
		
		// Create a Admin resource and save it to storage
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&Administrator>(self.AdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		emit ContractInitialized()
	}
}
