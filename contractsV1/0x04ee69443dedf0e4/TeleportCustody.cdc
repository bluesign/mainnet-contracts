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

import REVV from "../0xd01e482eb680ec9f/REVV.cdc"

access(all)
contract TeleportCustody{ 
	
	// Event that is emitted when new tokens are teleported in from Ethereum (from: Ethereum Address, 20 bytes)
	access(all)
	event TokensTeleportedIn(amount: UFix64, from: [UInt8], hash: String)
	
	// Event that is emitted when tokens are destroyed and teleported to Ethereum (to: Ethereum Address, 20 bytes)
	access(all)
	event TokensTeleportedOut(amount: UFix64, to: [UInt8])
	
	// Event that is emitted when teleport fee is collected (type 0: out, 1: in)
	access(all)
	event FeeCollected(amount: UFix64, type: UInt8)
	
	// Event that is emitted when a new burner resource is created
	access(all)
	event TeleportAdminCreated(allowedAmount: UFix64)
	
	// The storage path for the admin resource (equivalent to root)
	access(all)
	let AdminStoragePath: StoragePath
	
	// The storage path for the teleport-admin resource (less priviledged than admin)  
	access(all)
	let TeleportAdminStoragePath: StoragePath
	
	// The private path for the teleport-admin resource
	access(all)
	let TeleportAdminPrivatePath: PrivatePath
	
	// The public path for the teleport user
	access(all)
	let TeleportUserPublicPath: PublicPath
	
	// Frozen flag controlled by Admin
	access(all)
	var isFrozen: Bool
	
	// Record teleported Ethereum hashes
	access(contract)
	var teleported:{ String: Bool}
	
	// Controls REVV vault
	access(contract)
	let revvVault: @REVV.Vault
	
	access(all)
	resource Allowance{ 
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
	}
	
	access(all)
	resource Administrator{ 
		
		// createNewTeleportAdmin
		//
		// Function that creates and returns a new teleport admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin{ 
			emit TeleportAdminCreated(allowedAmount: allowedAmount)
			return <-create TeleportAdmin(allowedAmount: allowedAmount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun freeze(){ 
			TeleportCustody.isFrozen = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unfreeze(){ 
			TeleportCustody.isFrozen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createAllowance(allowedAmount: UFix64): @Allowance{ 
			return <-create Allowance(balance: allowedAmount)
		}
		
		// deposit
		// 
		// Function that deposits REVV token into the contract controlled
		// vault.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun depositRevv(from: @REVV.Vault){ 
			let vaultRef =
				TeleportCustody.account.storage.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath)
				?? panic("Could not borrow reference to the owner's Vault!")
			vaultRef.deposit(from: <-from)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawRevv(amount: UFix64): @{FungibleToken.Vault}{ 
			let vaultRef =
				TeleportCustody.account.storage.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath)
				?? panic("Could not borrow reference to the owner's Vault!")
			return <-vaultRef.withdraw(amount: amount)
		}
	}
	
	access(all)
	resource interface TeleportUser{ 
		// fee collected when token is teleported from Ethereum to Flow
		access(all)
		var inwardFee: UFix64
		
		// fee collected when token is teleported from Flow to Ethereum
		access(all)
		var outwardFee: UFix64
		
		// the amount of tokens that the admin is allowed to teleport
		access(all)
		var allowedAmount: UFix64
		
		// corresponding controller account on Ethereum
		access(all)
		var ethereumAdminAccount: [UInt8]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportOut(from: @REVV.Vault, to: [UInt8]): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositAllowance(from: @Allowance)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFeeAmount(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEthereumAdminAccount(): [UInt8]
	}
	
	access(all)
	resource interface TeleportControl{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateInwardFee(fee: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOutwardFee(fee: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateEthereumAdminAccount(account: [UInt8])
	}
	
	// TeleportAdmin resource
	//
	//  Resource object that has the capability to teleport tokens
	//  upon receiving teleport request from Ethereum side
	//
	access(all)
	resource TeleportAdmin: TeleportUser, TeleportControl{ 
		
		// the amount of tokens that the admin is allowed to teleport
		access(all)
		var allowedAmount: UFix64
		
		// receiver reference to collect teleport fee
		access(all)
		let feeCollector: @REVV.Vault
		
		// fee collected when token is teleported from Ethereum to Flow
		access(all)
		var inwardFee: UFix64
		
		// fee collected when token is teleported from Flow to Ethereum
		access(all)
		var outwardFee: UFix64
		
		// corresponding controller account on Ethereum
		access(all)
		var ethereumAdminAccount: [UInt8]
		
		// teleportIn
		//
		// Function that release REVV tokens from custody,
		// and returns them to the calling context.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @{FungibleToken.Vault}{ 
			pre{ 
				!TeleportCustody.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount teleported must be less than the allowed amount"
				amount > self.inwardFee:
					"Amount teleported must be greater than inward teleport fee"
				from.length == 20:
					"Ethereum address should be 20 bytes"
				hash.length == 64:
					"Ethereum tx hash should be 32 bytes"
				!(TeleportCustody.teleported[hash] ?? false):
					"Same hash already teleported"
			}
			self.allowedAmount = self.allowedAmount - amount
			TeleportCustody.teleported[hash] = true
			emit TokensTeleportedIn(amount: amount, from: from, hash: hash)
			let vaultRef = TeleportCustody.account.storage.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath) ?? panic("Could not borrow reference to the owner's Vault!")
			let vault <- vaultRef.withdraw(amount: amount)
			let fee <- vault.withdraw(amount: self.inwardFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.inwardFee, type: 1)
			return <-vault
		}
		
		// teleportOut
		//
		// Function that destroys a Vault instance, effectively burning the tokens.
		//
		// Note: the burned tokens are automatically subtracted from the 
		// total supply in the Vault destructor.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportOut(from: @REVV.Vault, to: [UInt8]){ 
			pre{ 
				!TeleportCustody.isFrozen:
					"Teleport service is frozen"
				to.length == 20:
					"Ethereum address should be 20 bytes"
			}
			let vault <- from as! @REVV.Vault
			let fee <- vault.withdraw(amount: self.outwardFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.outwardFee, type: 0)
			let amount = vault.balance
			let vaultRef = TeleportCustody.account.storage.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath) ?? panic("Could not borrow reference to the owner's Vault!")
			vaultRef.deposit(from: <-vault)
			emit TokensTeleportedOut(amount: amount, to: to)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawFee(amount: UFix64): @{FungibleToken.Vault}{ 
			return <-self.feeCollector.withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateInwardFee(fee: UFix64){ 
			self.inwardFee = fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOutwardFee(fee: UFix64){ 
			self.outwardFee = fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateEthereumAdminAccount(account: [UInt8]){ 
			pre{ 
				account.length == 20:
					"Ethereum address should be 20 bytes"
			}
			self.ethereumAdminAccount = account
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
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEthereumAdminAccount(): [UInt8]{ 
			return self.ethereumAdminAccount
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
			self.feeCollector <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>()) as! @REVV.Vault
			self.inwardFee = 0.01
			self.outwardFee = 10.0
			self.ethereumAdminAccount = []
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLockedVaultBalance(): UFix64{ 
		let vaultRef =
			TeleportCustody.account.storage.borrow<&REVV.Vault>(from: REVV.RevvVaultStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")
		return vaultRef.balance
	}
	
	init(){ 
		
		// Initialize the path fields
		self.AdminStoragePath = /storage/revvTeleportCustodyAdmin
		self.TeleportAdminStoragePath = /storage/revvTeleportCustodyTeleportAdmin
		self.TeleportUserPublicPath = /public/revvTeleportCustodyTeleportUser
		self.TeleportAdminPrivatePath = /private/revvTeleportCustodyTeleportAdmin
		
		// Initialize contract variables
		self.isFrozen = false
		self.teleported ={} 
		
		// Setup internal REVV vault
		self.revvVault <- REVV.createEmptyVault(vaultType: Type<@REVV.Vault>()) as! @REVV.Vault
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
