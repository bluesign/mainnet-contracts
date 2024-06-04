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

	// SPDX-License-Identifier: Apache License 2.0
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FUSD from "./../../standardsV1/FUSD.cdc"

import Elvn from "../0x3084a96e617d3b0a/Elvn.cdc"

// ElvnFUSDTreasury
// 
// Elvn <-> Custody contract that allows FUSD to be swapped 1:1
access(all)
contract ElvnFUSDTreasury{ 
	access(contract)
	let elvnVault: @Elvn.Vault
	
	access(contract)
	let fusdVault: @FUSD.Vault
	
	access(all)
	event Initialize()
	
	access(all)
	event WithdrawnElvn(amount: UFix64)
	
	access(all)
	event DepositedElvn(amount: UFix64)
	
	access(all)
	event WithdrawnFUSD(amount: UFix64)
	
	access(all)
	event DepositedFUSD(amount: UFix64)
	
	access(all)
	event SwapElvnToFUSD(amount: UFix64)
	
	access(all)
	event SwapFUSDToElvn(amount: UFix64)
	
	access(all)
	resource ElvnAdministrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"amount is not positive"
			}
			let vaultAmount = ElvnFUSDTreasury.elvnVault.balance
			if vaultAmount < amount{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnElvn(amount: amount)
			return <-ElvnFUSDTreasury.elvnVault.withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawAllAmount(): @{FungibleToken.Vault}{ 
			let vaultAmount = ElvnFUSDTreasury.elvnVault.balance
			if vaultAmount <= 0.0{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnElvn(amount: vaultAmount)
			return <-ElvnFUSDTreasury.elvnVault.withdraw(amount: vaultAmount)
		}
	}
	
	access(all)
	resource FUSDAdministrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"amount is not positive"
			}
			let vaultAmount = ElvnFUSDTreasury.fusdVault.balance
			if vaultAmount < amount{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnFUSD(amount: amount)
			return <-ElvnFUSDTreasury.fusdVault.withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawAllAmount(): @{FungibleToken.Vault}{ 
			let vaultAmount = ElvnFUSDTreasury.fusdVault.balance
			if vaultAmount <= 0.0{ 
				panic("not enough balance in vault")
			}
			emit WithdrawnFUSD(amount: vaultAmount)
			return <-ElvnFUSDTreasury.fusdVault.withdraw(amount: vaultAmount)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun depositElvn(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"amount is not positive"
		}
		let amount = vault.balance
		self.elvnVault.deposit(from: <-vault)
		emit DepositedElvn(amount: amount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun depositFUSD(vault: @{FungibleToken.Vault}){ 
		pre{ 
			vault.balance > 0.0:
				"amount is not positive"
		}
		let amount = vault.balance
		self.fusdVault.deposit(from: <-vault)
		emit DepositedFUSD(amount: amount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun swapElvnToFUSD(vault: @Elvn.Vault): @{FungibleToken.Vault}{ 
		let vaultAmount = vault.balance
		if vaultAmount <= 0.0{ 
			panic("vault balance is not positive")
		}
		if ElvnFUSDTreasury.fusdVault.balance < vaultAmount{ 
			panic("not enough balance in Treasury.fusdVault")
		}
		self.elvnVault.deposit(from: <-vault)
		emit SwapElvnToFUSD(amount: vaultAmount)
		return <-self.fusdVault.withdraw(amount: vaultAmount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun swapFUSDToElvn(vault: @FUSD.Vault): @{FungibleToken.Vault}{ 
		let vaultAmount = vault.balance
		if vaultAmount <= 0.0{ 
			panic("vault balance is not positive")
		}
		if ElvnFUSDTreasury.elvnVault.balance < vaultAmount{ 
			panic("not enough balance in Treasury.elvnVault")
		}
		self.fusdVault.deposit(from: <-vault)
		emit SwapFUSDToElvn(amount: vaultAmount)
		return <-self.elvnVault.withdraw(amount: vaultAmount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBalance(): [UFix64]{ 
		return [self.elvnVault.balance, self.fusdVault.balance]
	}
	
	init(){ 
		self.elvnVault <- Elvn.createEmptyVault(vaultType: Type<@Elvn.Vault>()) as! @Elvn.Vault
		self.fusdVault <- FUSD.createEmptyVault(vaultType: Type<@FUSD.Vault>())
		let elvnAdmin <- create ElvnAdministrator()
		self.account.storage.save(<-elvnAdmin, to: /storage/treasuryElvnAdmin)
		let fusdAdmin <- create FUSDAdministrator()
		self.account.storage.save(<-fusdAdmin, to: /storage/treasuryFUSDAdmin)
		emit Initialize()
	}
}
