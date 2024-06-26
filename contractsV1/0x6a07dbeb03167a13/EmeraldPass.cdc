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

import FUSD from "./../../standardsV1/FUSD.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

// This contract is now deprecated and should no longer be used.
access(all)
contract EmeraldPass{ 
	access(self)
	var treasury: ECTreasury
	
	// Maps the type of a token to its pricing
	access(self)
	var pricing:{ Type: Pricing}
	
	access(all)
	var purchased: UInt64
	
	access(all)
	let VaultPublicPath: PublicPath
	
	access(all)
	let VaultStoragePath: StoragePath
	
	access(all)
	event ChangedPricing(newPricing:{ UFix64: UFix64})
	
	access(all)
	event Purchased(subscriber: Address, time: UFix64, vaultType: Type)
	
	access(all)
	event Donation(by: Address, to: Address, vaultType: Type)
	
	access(all)
	struct ECTreasury{ 
		access(all)
		let tokenTypeToVault:{ Type: Capability<&{FungibleToken.Receiver}>}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSupportedTokens(): [Type]{ 
			return self.tokenTypeToVault.keys
		}
		
		view init(){ 
			let ecAccount: &Account = getAccount(0x5643fd47a29770e7)
			self.tokenTypeToVault ={ 
					Type<@FUSD.Vault>():
					ecAccount.capabilities.get<&FUSD.Vault>(/public/fusdReceiver),
					Type<@FlowToken.Vault>():
					ecAccount.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver)
				}
		}
	}
	
	access(all)
	struct Pricing{ 
		// examples in $FUSD
		// 100.0 -> 2629743.0 (1 month)
		// 1000.0 -> 31556926.0 (1 year)
		access(all)
		let costToTime:{ UFix64: UFix64}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTime(cost: UFix64): UFix64?{ 
			return self.costToTime[cost]
		}
		
		init(_ costToTime:{ UFix64: UFix64}){ 
			self.costToTime = costToTime
		}
	}
	
	access(all)
	resource interface VaultPublic{ 
		access(all)
		var endDate: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(payment: @{FungibleToken.Vault}): Void
		
		access(account)
		fun addTime(time: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isActive(): Bool
	}
	
	access(all)
	resource Vault: VaultPublic{ 
		access(all)
		var endDate: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun purchase(payment: @{FungibleToken.Vault}){ 
			pre{ 
				false:
					"Disabled."
			}
			let paymentType: Type = payment.getType()
			let pricing: Pricing = EmeraldPass.getPricing(vaultType: paymentType) ?? panic("This is not a supported form of payment.")
			let time: UFix64 = pricing.getTime(cost: payment.balance) ?? panic("The balance of the Vault you sent in does not correlate to any supported amounts of time.")
			EmeraldPass.depositToECTreasury(vault: <-payment)
			self.addTime(time: time)
			EmeraldPass.purchased = EmeraldPass.purchased + 1
			emit Purchased(subscriber: (self.owner!).address, time: time, vaultType: paymentType)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isActive(): Bool{ 
			return true
		}
		
		access(account)
		fun addTime(time: UFix64){ 
			// If you're already active, just add more time to the end date.
			// Otherwise, start the subscription now and set the end date.
			if self.isActive(){ 
				self.endDate = self.endDate + time
			} else{ 
				self.endDate = getCurrentBlock().timestamp + time
			}
		}
		
		init(){ 
			self.endDate = 0.0
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createVault(): @Vault{ 
		return <-create Vault()
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun changePricing(newPricing:{ Type: Pricing}){ 
			EmeraldPass.pricing = newPricing
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun giveUserTime(user: Address, time: UFix64){ 
			let userVault =
				getAccount(user).capabilities.get<&Vault>(EmeraldPass.VaultPublicPath).borrow<
					&Vault
				>()
				?? panic("This receiver has not set up a Vault for Emerald Pass yet.")
			userVault.addTime(time: time)
		}
	}
	
	// A public function because, well, ... um ... you can
	// always call this if you want! :D ;) <3
	access(TMP_ENTITLEMENT_OWNER)
	fun depositToECTreasury(vault: @{FungibleToken.Vault}){ 
		pre{ 
			self.getTreasury()[vault.getType()] != nil:
				"We have not set up this payment yet."
		}
		((self.getTreasury()[vault.getType()]!).borrow()!).deposit(from: <-vault)
	}
	
	// A function you can call to donate subscription time to someone else
	access(TMP_ENTITLEMENT_OWNER)
	fun donate(nicePerson: Address, to: Address, payment: @{FungibleToken.Vault}){ 
		pre{ 
			false:
				"Disabled."
		}
		let userVault =
			getAccount(to).capabilities.get<&Vault>(EmeraldPass.VaultPublicPath).borrow<&Vault>()
			?? panic("This receiver has not set up a Vault for Emerald Pass yet.")
		let paymentType: Type = payment.getType()
		userVault.purchase(payment: <-payment)
		emit Donation(by: nicePerson, to: to, vaultType: paymentType)
	}
	
	// Checks to see if a user is currently subscribed to Emerald Pass
	access(TMP_ENTITLEMENT_OWNER)
	fun isActive(user: Address): Bool{ 
		return true
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllPricing():{ Type: Pricing}{ 
		return self.pricing
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPricing(vaultType: Type): Pricing?{ 
		return self.getAllPricing()[vaultType]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getTreasury():{ Type: Capability<&{FungibleToken.Receiver}>}{ 
		return ECTreasury().tokenTypeToVault
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUserVault(user: Address): &Vault?{ 
		return getAccount(user).capabilities.get<&Vault>(EmeraldPass.VaultPublicPath).borrow<
			&Vault
		>()
	}
	
	init(){ 
		self.treasury = ECTreasury()
		self.pricing ={ Type<@FUSD.Vault>(): Pricing({100.0: 2629743.0, // 1 month																		
																		1000.0: 31556926.0 // 1 year																						  
																						  })}
		self.purchased = 0
		self.VaultPublicPath = /public/EmeraldPass
		self.VaultStoragePath = /storage/EmeraldPass
		self.account.storage.save(<-create Admin(), to: /storage/EmeraldPassAdmin)
	}
}
