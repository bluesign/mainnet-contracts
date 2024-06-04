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
contract TeleportedTetherToken: FungibleToken{ 
	// Frozen flag controlled by Admin
	access(all)
	var isFrozen: Bool
	
	// Total supply of TeleportedTetherTokens in existence
	access(all)
	var totalSupply: UFix64
	
	// Record teleported Ethereum hashes
	access(all)
	var teleported:{ String: Bool}
	
	// Defines token vault storage path
	access(all)
	let TokenStoragePath: StoragePath
	
	// Defines token vault public balance path
	access(all)
	let TokenPublicBalancePath: PublicPath
	
	// Defines token vault public receiver path
	access(all)
	let TokenPublicReceiverPath: PublicPath
	
	// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
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
	
	// Vault
	//
	// Each user stores an instance of only the Vault in their storage
	// The functions in the Vault and governed by the pre and post conditions
	// in FungibleToken when they are called.
	// The checks happen at runtime whenever a function is called.
	//
	// Resources can only be created in the context of the contract that they
	// are defined in, so there is no way for a malicious user to create Vaults
	// out of thin air. A special Minter resource needs to be defined to mint
	// new tokens.
	//
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		// holds the balance of a users tokens
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		// withdraw
		//
		// Function that takes an integer amount as an argument
		// and withdraws that amount from the Vault.
		// It creates a new temporary Vault that is used to hold
		// the money that is being transferred. It returns the newly
		// created Vault to the context that called so it can be deposited
		// elsewhere.
		//
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		// deposit
		//
		// Function that takes a Vault object as an argument and adds
		// its balance to the balance of the owners Vault.
		// It is allowed to destroy the sent Vault because the Vault
		// was a temporary holder of the tokens. The Vault's balance has
		// been consumed and therefore can be destroyed.
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			let vault <- from as! @TeleportedTetherToken.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(all)
		fun createEmptyVault(): @{FungibleToken.Vault}{ 
			return <-create Vault(balance: 0.0)
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	// createEmptyVault
	//
	// Function that creates a new Vault with a balance of zero
	// and returns it to the calling context. A user must call this function
	// and store the returned Vault in their storage in order to allow their
	// account to be able to receive deposits of this token type.
	//
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
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
			TeleportedTetherToken.isFrozen = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unfreeze(){ 
			TeleportedTetherToken.isFrozen = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createAllowance(allowedAmount: UFix64): @Allowance{ 
			return <-create Allowance(balance: allowedAmount)
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
		
		// the amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		// corresponding controller account on Ethereum
		access(all)
		var ethereumAdminAccount: [UInt8]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportOut(from: @{FungibleToken.Vault}, to: [UInt8]): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun depositAllowance(from: @Allowance)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEthereumAdminAccount(): [UInt8]
	}
	
	access(all)
	resource interface TeleportControl{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @TeleportedTetherToken.Vault
		
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
	//  Resource object that has the capability to mint teleported tokens
	//  upon receiving teleport request from Ethereum side
	//
	access(all)
	resource TeleportAdmin: TeleportUser, TeleportControl{ 
		
		// the amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		// receiver reference to collect teleport fee
		access(all)
		let feeCollector: @TeleportedTetherToken.Vault
		
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
		// Function that mints new tokens, adds them to the total supply,
		// and returns them to the calling context.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun teleportIn(amount: UFix64, from: [UInt8], hash: String): @TeleportedTetherToken.Vault{ 
			pre{ 
				!TeleportedTetherToken.isFrozen:
					"Teleport service is frozen"
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
				amount > self.inwardFee:
					"Amount minted must be greater than inward teleport fee"
				from.length == 20:
					"Ethereum address should be 20 bytes"
				hash.length == 64:
					"Ethereum tx hash should be 32 bytes"
				!(TeleportedTetherToken.teleported[hash] ?? false):
					"Same hash already teleported"
			}
			TeleportedTetherToken.totalSupply = TeleportedTetherToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			TeleportedTetherToken.teleported[hash] = true
			emit TokensTeleportedIn(amount: amount, from: from, hash: hash)
			let vault <- create Vault(balance: amount)
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
		fun teleportOut(from: @{FungibleToken.Vault}, to: [UInt8]){ 
			pre{ 
				!TeleportedTetherToken.isFrozen:
					"Teleport service is frozen"
				to.length == 20:
					"Ethereum address should be 20 bytes"
			}
			let vault <- from as! @TeleportedTetherToken.Vault
			let fee <- vault.withdraw(amount: self.outwardFee)
			self.feeCollector.deposit(from: <-fee)
			emit FeeCollected(amount: self.outwardFee, type: 0)
			let amount = vault.balance
			destroy vault
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
			self.feeCollector <- TeleportedTetherToken.createEmptyVault(vaultType: Type<@TeleportedTetherToken.Vault>()) as! @TeleportedTetherToken.Vault
			self.inwardFee = 0.01
			self.outwardFee = 3.0
			self.ethereumAdminAccount = []
		}
	}
	
	init(){ 
		self.isFrozen = false
		self.totalSupply = 0.0
		self.teleported ={} 
		self.TokenStoragePath = /storage/teleportedTetherTokenVault
		self.TokenPublicBalancePath = /public/teleportedTetherTokenBalance
		self.TokenPublicReceiverPath = /public/teleportedTetherTokenReceiver
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: /storage/teleportedTetherTokenAdmin)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
