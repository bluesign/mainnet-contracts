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

	import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract StarlyTokenReward{ 
	access(all)
	event RewardPaid(rewardId: String, to: Address)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun transfer(rewardId: String, to: Address, amount: UFix64){ 
			let rewardsVaultRef =
				StarlyTokenReward.account.storage.borrow<&StarlyToken.Vault>(
					from: StarlyToken.TokenStoragePath
				)!
			let receiverRef =
				getAccount(to).capabilities.get<&{FungibleToken.Receiver}>(
					StarlyToken.TokenPublicReceiverPath
				).borrow<&{FungibleToken.Receiver}>()
				?? panic(
					"Could not borrow StarlyToken receiver reference to the recipient's vault!"
				)
			receiverRef.deposit(from: <-rewardsVaultRef.withdraw(amount: amount))
			emit RewardPaid(rewardId: rewardId, to: to)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/starlyTokenRewardAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		// for payouts we will use account's default Starly token vault
		if self.account.storage.borrow<&StarlyToken.Vault>(from: StarlyToken.TokenStoragePath)
		== nil{ 
			self.account.storage.save(
				<-StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()),
				to: StarlyToken.TokenStoragePath
			)
			var capability_1 =
				self.account.capabilities.storage.issue<&StarlyToken.Vault>(
					StarlyToken.TokenStoragePath
				)
			self.account.capabilities.publish(capability_1, at: StarlyToken.TokenPublicReceiverPath)
			var capability_2 =
				self.account.capabilities.storage.issue<&StarlyToken.Vault>(
					StarlyToken.TokenStoragePath
				)
			self.account.capabilities.publish(capability_2, at: StarlyToken.TokenPublicBalancePath)
		}
	}
}
