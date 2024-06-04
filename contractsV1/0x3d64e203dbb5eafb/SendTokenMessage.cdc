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
contract SendTokenMessage{ 
	access(all)
	event Delivered(tokenType: Type, amount: UFix64, to: Address, message: String?)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun deliver(
		vault: @{FungibleToken.Vault},
		receiverPath: PublicPath,
		receiver: Address,
		message: String?
	){ 
		emit Delivered(
			tokenType: vault.getType(),
			amount: vault.balance,
			to: receiver,
			message: message
		)
		let receiverVault =
			getAccount(receiver).capabilities.get<&{FungibleToken.Receiver}>(receiverPath).borrow<
				&{FungibleToken.Receiver}
			>()
			?? panic("Receiver does not have a vault set up to accept this delivery.")
		receiverVault.deposit(from: <-vault)
	}
}
