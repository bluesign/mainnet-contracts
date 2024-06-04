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

	import Rumble from "./Rumble.cdc"

access(all)
contract TokenManager{ 
	access(all)
	var cooldown: UFix64
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(from: @Rumble.Vault): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun canWithdraw(): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): UFix64
		
		access(account)
		fun distribute(to: Address, amount: UFix64)
	}
	
	access(all)
	resource LockedVault: Public{ 
		access(self)
		let tokens: @Rumble.Vault
		
		access(all)
		var withdrawTimestamp: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(from: @Rumble.Vault){ 
			self.tokens.deposit(from: <-from)
			self.withdrawTimestamp = getCurrentBlock().timestamp + TokenManager.cooldown
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @Rumble.Vault{ 
			pre{ 
				self.canWithdraw():
					"User cannot withdraw yet."
			}
			let tokens <- self.tokens.withdraw(amount: amount) as! @Rumble.Vault
			return <-tokens
		}
		
		access(account)
		fun distribute(to: Address, amount: UFix64){ 
			let recipientVault = getAccount(to).capabilities.get<&LockedVault>(TokenManager.VaultPublicPath).borrow<&LockedVault>() ?? panic("This user does not have a vault set up.")
			let tokens <- self.tokens.withdraw(amount: amount) as! @Rumble.Vault
			recipientVault.deposit(from: <-tokens)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun canWithdraw(): Bool{ 
			return getCurrentBlock().timestamp >= self.withdrawTimestamp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): UFix64{ 
			return self.tokens.balance
		}
		
		init(){ 
			self.tokens <- Rumble.createEmptyVault(vaultType: Type<@Rumble.Vault>())
			self.withdrawTimestamp = getCurrentBlock().timestamp
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyVault(): @LockedVault{ 
		return <-create LockedVault()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkUserDepositStatusIsValid(user: Address, amount: UFix64): Bool{ 
		let userVault =
			getAccount(user).capabilities.get<&LockedVault>(TokenManager.VaultPublicPath).borrow<
				&LockedVault
			>()
			?? panic("This user does not have a vault set up.")
		return userVault.getBalance() >= amount
	}
	
	access(account)
	fun changeCooldown(newCooldown: UFix64){ 
		self.cooldown = newCooldown
	}
	
	init(){ 
		self.cooldown = 0.0
		self.VaultPublicPath = /public/BloxsmithLockedVault
		self.VaultStoragePath = /storage/BloxsmithLockedVault
	}
}
