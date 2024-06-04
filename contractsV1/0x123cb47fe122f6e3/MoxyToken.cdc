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

import MoxyVaultToken from "./MoxyVaultToken.cdc"

access(all)
contract MoxyToken: FungibleToken{ 
	
	/// Total supply of MoxyTokens in existence
	access(all)
	var totalSupply: UFix64
	
	/// TokensInitialized
	///
	/// The event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	/// TokensWithdrawn
	///
	/// The event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	/// TokensDeposited
	///
	/// The event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/// TokensMinted
	///
	/// The event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	/// TokensBurned
	///
	/// The event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	/// MinterCreated
	///
	/// The event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated(allowedAmount: UFix64)
	
	/// BurnerCreated
	///
	/// The event that is emitted when a new burner resource is created
	access(all)
	event BurnerCreated()
	
	access(all)
	event MOXtoMVConvertionRequested(address: Address, amount: UFix64)
	
	/// Vault
	///
	/// Each user stores an instance of only the Vault in their storage
	/// The functions in the Vault and governed by the pre and post conditions
	/// in FungibleToken when they are called.
	/// The checks happen at runtime whenever a function is called.
	///
	/// Resources can only be created in the context of the contract that they
	/// are defined in, so there is no way for a malicious user to create Vaults
	/// out of thin air. A special Minter resource needs to be defined to mint
	/// new tokens.
	///
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		
		/// The total balance of this vault
		access(all)
		var balance: UFix64
		
		// initialize the balance at resource creation time
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		/// withdraw
		///
		/// Function that takes an amount as an argument
		/// and withdraws that amount from the Vault.
		///
		/// It creates a new temporary Vault that is used to hold
		/// the money that is being transferred. It returns the newly
		/// created Vault to the context that called so it can be deposited
		/// elsewhere.
		///
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		/// deposit
		///
		/// Function that takes a Vault object as an argument and adds
		/// its balance to the balance of the owners Vault.
		///
		/// It is allowed to destroy the sent Vault because the Vault
		/// was a temporary holder of the tokens. The Vault's balance has
		/// been consumed and therefore can be destroyed.
		///
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			let vault <- from as! @MoxyToken.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault
		}
		
		access(account)
		fun depositLocked(from: @{FungibleToken.Vault}){ 
			return self.deposit(from: <-from)
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
	
	/// createEmptyVault
	///
	/// Function that creates a new Vault with a balance of zero
	/// and returns it to the calling context. A user must call this function
	/// and store the returned Vault in their storage in order to allow their
	/// account to be able to receive deposits of this token type.
	///
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(all)
	resource Administrator{ 
		
		/// createNewMinter
		///
		/// Function that creates and returns a new minter resource
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewMinter(allowedAmount: UFix64): @Minter{ 
			emit MinterCreated(allowedAmount: allowedAmount)
			return <-create Minter(allowedAmount: allowedAmount)
		}
		
		/// createNewBurner
		///
		/// Function that creates and returns a new burner resource
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	/// Minter
	///
	/// Resource object that token admin accounts can hold to mint new tokens.
	///
	access(all)
	resource Minter{ 
		
		/// The amount of tokens that the minter is allowed to mint
		access(all)
		var allowedAmount: UFix64
		
		/// mintTokens
		///
		/// Function that mints new tokens, adds them to the total supply,
		/// and returns them to the calling context.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(amount: UFix64): @MoxyToken.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount mined must be greater than zero ".concat(amount.toString())
				amount <= self.allowedAmount:
					"Amount minted must be less than the allowed amount"
			}
			MoxyToken.totalSupply = MoxyToken.totalSupply + amount
			self.allowedAmount = self.allowedAmount - amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
		
		init(allowedAmount: UFix64){ 
			self.allowedAmount = allowedAmount
		}
	}
	
	/// Burner
	///
	/// Resource object that token admin accounts can hold to burn tokens.
	///
	access(all)
	resource Burner{ 
		
		/// burnTokens
		///
		/// Function that destroys a Vault instance, effectively burning the tokens.
		///
		/// Note: the burned tokens are automatically subtracted from the
		/// total supply in the Vault destructor.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @MoxyToken.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	let moxyTokenVaultStorage: StoragePath
	
	access(all)
	let moxyTokenLockedVaultStorage: StoragePath
	
	access(all)
	let moxyTokenLockedVaultPrivate: PrivatePath
	
	access(all)
	let moxyTokenAdminStorage: StoragePath
	
	access(all)
	let moxyTokenReceiverPath: PublicPath
	
	access(all)
	let moxyTokenBalancePath: PublicPath
	
	access(all)
	let moxyTokenLockedBalancePath: PublicPath
	
	access(all)
	let moxyTokenLockedReceiverPath: PublicPath
	
	// Paths for Locked tonkens due MOX to MV conversion
	access(all)
	let moxyTokenLockedMVVaultStorage: StoragePath
	
	access(all)
	let moxyTokenLockedMVBalancePath: PublicPath
	
	access(all)
	let moxyTokenLockedMVReceiverPath: PublicPath
	
	// Play and Earn Paths
	access(all)
	let moxyTokenPlayAndEarnVaultStorage: StoragePath
	
	access(all)
	let moxyTokenPlayAndEarnVaultPrivate: PrivatePath
	
	access(all)
	let moxyTokenPlayAndEarnBalancePath: PublicPath
	
	init(){ 
		// The initial total supply corresponds with the total amount
		// to release in the different Token allocations rounds
		self.totalSupply = 0.0
		self.moxyTokenVaultStorage = /storage/moxyTokenVault
		self.moxyTokenLockedVaultStorage = /storage/moxyTokenLockedVault
		self.moxyTokenLockedVaultPrivate = /private/moxyTokenLockedVault
		self.moxyTokenAdminStorage = /storage/moxyTokenAdmin
		self.moxyTokenReceiverPath = /public/moxyTokenReceiver
		self.moxyTokenBalancePath = /public/moxyTokenBalance
		self.moxyTokenLockedBalancePath = /public/moxyTokenLockedBalance
		self.moxyTokenLockedReceiverPath = /public/moxyTokenLockedReceiver
		// Locked vaults due to MOX to MV conversion
		self.moxyTokenLockedMVVaultStorage = /storage/moxyTokenLockedMVVault
		self.moxyTokenLockedMVBalancePath = /public/moxyTokenLockedMVBalance
		self.moxyTokenLockedMVReceiverPath = /public/moxyTokenLockedMVReceiver
		//Play and Earn Storage
		self.moxyTokenPlayAndEarnVaultStorage = /storage/moxyTokenPlayAndEarnVault
		self.moxyTokenPlayAndEarnVaultPrivate = /private/moxyTokenPlayAndEarnVault
		self.moxyTokenPlayAndEarnBalancePath = /public/moxyTokenPlayAndEarnBalance
		
		// Create the Vault with the total supply of tokens and save it in storage
		//
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.moxyTokenVaultStorage)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		//
		var capability_1 = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(self.moxyTokenVaultStorage)
		self.account.capabilities.publish(capability_1, at: self.moxyTokenReceiverPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		//
		var capability_2 = self.account.capabilities.storage.issue<&MoxyToken.Vault>(self.moxyTokenVaultStorage)
		self.account.capabilities.publish(capability_2, at: self.moxyTokenBalancePath)
		
		// Create Play & Earn resource
		let playAndEarnvault <- self.createEmptyVault(vaultType: Type<@Vault>())
		self.account.storage.save(<-playAndEarnvault, to: self.moxyTokenPlayAndEarnVaultStorage)
		var capability_3 = self.account.capabilities.storage.issue<&{FungibleToken.Vault}>(self.moxyTokenPlayAndEarnVaultStorage)
		self.account.capabilities.publish(capability_3, at: self.moxyTokenPlayAndEarnVaultPrivate)
		var capability_4 = self.account.capabilities.storage.issue<&{FungibleToken.Vault}>(self.moxyTokenPlayAndEarnVaultStorage)
		self.account.capabilities.publish(capability_4, at: self.moxyTokenPlayAndEarnBalancePath)
		
		// Create admin resource
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.moxyTokenAdminStorage)
		
		// Emit an event that shows that the contract was initialized
		//
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
