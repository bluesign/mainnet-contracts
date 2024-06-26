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

import StarlyToken from "../0x142fa6570b62fd97/StarlyToken.cdc"

access(all)
contract TeleportCustodyBSC{ 
	access(all)
	event TeleportAdminCreated(allowedAmount: UFix64)
	
	access(all)
	event Locked(amount: UFix64, to: [UInt8])
	
	access(all)
	event Unlocked(amount: UFix64, from: [UInt8], txHash: String)
	
	access(all)
	event FeeCollected(amount: UFix64, type: UInt8)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let TeleportAdminStoragePath: StoragePath
	
	access(all)
	let TeleportAdminTeleportUserPath: PublicPath
	
	access(all)
	let TeleportAdminTeleportControlPath: PrivatePath
	
	access(all)
	let teleportAddressLength: Int
	
	access(all)
	let teleportTxHashLength: Int
	
	access(all)
	var isFrozen: Bool
	
	access(contract)
	var unlocked:{ String: Bool}
	
	access(contract)
	let lockVault: @StarlyToken.Vault
	
	access(all)
	resource Allowance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin{ 
			emit TeleportAdminCreated(allowedAmount: allowedAmount)
			return <-create TeleportAdmin(allowedAmount: allowedAmount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun freeze(){ 
			TeleportCustodyBSC.isFrozen = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unfreeze(){ 
			TeleportCustodyBSC.isFrozen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createAllowance(allowedAmount: UFix64): @Allowance{ 
			return <-create Allowance(balance: allowedAmount)
		}
	}
	
	access(all)
	resource interface TeleportUser{ 
		access(all)
		var lockFee: UFix64
		
		access(all)
		var unlockFee: UFix64
		
		access(all)
		var allowedAmount: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8]): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositAllowance(from: @Allowance)
	}
	
	access(all)
	resource interface TeleportControl{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateLockFee(fee: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateUnlockFee(fee: UFix64)
	}
	
	access(all)
	resource TeleportAdmin: TeleportUser, TeleportControl{ 
		access(all)
		var lockFee: UFix64
		
		access(all)
		var unlockFee: UFix64
		
		access(all)
		var allowedAmount: UFix64
		
		access(all)
		let feeCollector: @StarlyToken.Vault
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lock(from: @{FungibleToken.Vault}, to: [UInt8]){ 
			pre{ 
				!TeleportCustodyBSC.isFrozen:
					"Teleport service is frozen"
				to.length == TeleportCustodyBSC.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
			}
			let vault <- from as! @StarlyToken.Vault
			let fee <- vault.withdraw(amount: self.lockFee)
			self.feeCollector.deposit(from: <-fee)
			let amount = vault.balance
			TeleportCustodyBSC.lockVault.deposit(from: <-vault)
			emit Locked(amount: amount, to: to)
			emit FeeCollected(amount: self.lockFee, type: 0)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unlock(amount: UFix64, from: [UInt8], txHash: String): @{FungibleToken.Vault}{ 
			pre{ 
				!TeleportCustodyBSC.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount unlocked must be less than the allowed amount"
				amount > self.unlockFee:
					"Amount unlocked must be greater than unlock fee"
				from.length == TeleportCustodyBSC.teleportAddressLength:
					"Teleport address should be teleportAddressLength bytes"
				txHash.length == TeleportCustodyBSC.teleportTxHashLength:
					"Teleport tx hash should be teleportTxHashLength bytes"
				!(TeleportCustodyBSC.unlocked[txHash] ?? false):
					"Same unlock txHash has been executed"
			}
			self.allowedAmount = self.allowedAmount - amount
			TeleportCustodyBSC.unlocked[txHash] = true
			emit Unlocked(amount: amount, from: from, txHash: txHash)
			let vault <- TeleportCustodyBSC.lockVault.withdraw(amount: amount)
			let fee <- vault.withdraw(amount: self.unlockFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.unlockFee, type: 1)
			return <-vault
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.feeCollector.withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateLockFee(fee: UFix64){ 
			self.lockFee = fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateUnlockFee(fee: UFix64){ 
			self.unlockFee = fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFeeAmount(): UFix64{ 
			return self.feeCollector.balance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositAllowance(from: @Allowance){ 
			self.allowedAmount = self.allowedAmount + from.balance
			destroy from
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
			self.feeCollector <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>()) as! @StarlyToken.Vault
			self.lockFee = 3.0
			self.unlockFee = 0.01
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLockVaultBalance(): UFix64{ 
		return TeleportCustodyBSC.lockVault.balance
	}
	
	init(){ 
		self.teleportAddressLength = 20
		self.teleportTxHashLength = 64
		self.AdminStoragePath = /storage/teleportCustodyBSCAdmin
		self.TeleportAdminStoragePath = /storage/teleportCustodyBSCTeleportAdmin
		self.TeleportAdminTeleportUserPath = /public/teleportCustodyBSCTeleportUser
		self.TeleportAdminTeleportControlPath = /private/teleportCustodyBSCTeleportControl
		self.isFrozen = false
		self.unlocked ={} 
		self.lockVault <- StarlyToken.createEmptyVault(vaultType: Type<@StarlyToken.Vault>())
			as!
			@StarlyToken.Vault
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
