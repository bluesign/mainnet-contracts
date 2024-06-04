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

	access(all)
contract KabuniCoin{ 
	access(all)
	var totalSupply: UFix64
	
	access(all)
	var name: String
	
	access(all)
	var symbol: String
	
	access(all)
	var decimals: UInt8
	
	access(all)
	resource interface Provider{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @KabuniCoin.Vault
	}
	
	access(all)
	resource interface Receiver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(from: @KabuniCoin.Vault): Void
	}
	
	access(all)
	resource Vault: Provider, Receiver{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @KabuniCoin.Vault{ 
			pre{ 
				self.balance >= amount:
					"Insufficient balance"
			}
			self.balance = self.balance - amount
			return <-create Vault(balance: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(from: @KabuniCoin.Vault){ 
			self.balance = self.balance + from.balance
			destroy from
		}
	}
	
	init(){ 
		self.totalSupply = 1000000000.0
		self.name = "Kabuni Coin"
		self.symbol = "KBC"
		self.decimals = 18
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: /storage/mainVault)
		var capability_1 =
			self.account.capabilities.storage.issue<&{KabuniCoin.Provider}>(/storage/mainVault)
		self.account.capabilities.publish(capability_1, at: /public/provider)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyVault(): @KabuniCoin.Vault{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintTokens(to: Address, amount: UFix64){ 
		pre{ 
			amount > 0.0:
				"Invalid amount"
		}
		let mainVaultRef =
			self.account.storage.borrow<&KabuniCoin.Vault>(from: /storage/mainVault)
			?? panic("Could not borrow main vault reference")
		let receiverRef =
			(getAccount(to).capabilities.get<&{KabuniCoin.Receiver}>(/public/receiver)!).borrow()
			?? panic("Could not borrow receiver reference")
		let tokens <- mainVaultRef.withdraw(amount: amount)
		receiverRef.deposit(from: <-tokens)
		self.totalSupply = self.totalSupply + amount
	}
}
