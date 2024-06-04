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

// Token contract of Sushi (SUSHI)
access(all)
contract Sushi: FungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Sushi contract Events
	// -----------------------------------------------------------------------
	
	// Event that is emitted when the contract is created
	access(all)
	event TokensInitialized(initialSupply: UFix64)
	
	// Event that is emitted when tokens are withdrawn from a Vault
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that is emitted when tokens are deposited to a Vault
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	// Event that is emitted when new tokens are minted
	access(all)
	event TokensMinted(amount: UFix64)
	
	// Event that is emitted when tokens are destroyed
	access(all)
	event TokensBurned(amount: UFix64)
	
	// Event that is emitted when a new minter resource is created
	access(all)
	event MinterCreated()
	
	// Event that is emitted when a new burner resource is created
	access(all)
	event BurnerCreated()
	
	// Event that is emitted when a new MinterProxy resource is created
	access(all)
	event MinterProxyCreated()
	
	// -----------------------------------------------------------------------
	// Sushi contract Named Paths
	// -----------------------------------------------------------------------
	// Defines Sushi vault storage path
	access(all)
	let VaultStoragePath: StoragePath
	
	// Defines Sushi vault public balance path
	access(all)
	let BalancePublicPath: PublicPath
	
	// Defines Sushi vault public receiver path
	access(all)
	let ReceiverPublicPath: PublicPath
	
	// Defines Sushi admin storage path
	access(all)
	let AdminStoragePath: StoragePath
	
	// Defines Sushi minter storage path
	access(all)
	let MinterStoragePath: StoragePath
	
	// Defines Sushi minters' MinterProxy storage path
	access(all)
	let MinterProxyStoragePath: StoragePath
	
	// Defines Sushi minters' MinterProxy capability public path
	access(all)
	let MinterProxyPublicPath: PublicPath
	
	// -----------------------------------------------------------------------
	// Sushi contract fields
	// These contain actual values that are stored in the smart contract
	// -----------------------------------------------------------------------
	// Total supply of Sushi in existence
	access(all)
	var totalSupply: UFix64
	
	// Vault
	//
	// Each user stores an instance of only the Vault in their storage
	// The functions in the Vault are governed by the pre and post conditions
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
			let vault <- from as! @Sushi.Vault
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
	
	// Administrator
	//
	// Resource object that token admin accounts can hold to create new minters and burners.
	//
	access(all)
	resource Administrator{ 
		// createNewMinter
		//
		// Function that creates and returns a new minter resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewMinter(): @Minter{ 
			emit MinterCreated()
			return <-create Minter()
		}
		
		// createNewBurner
		//
		// Function that creates and returns a new burner resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewBurner(): @Burner{ 
			emit BurnerCreated()
			return <-create Burner()
		}
	}
	
	// Minter
	//
	// Resource object that token admin accounts can hold to mint new tokens.
	//
	access(all)
	resource Minter{ 
		
		// mintTokens
		//
		// Function that mints new tokens, adds them to the total supply,
		// and returns them to the calling context.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(amount: UFix64): @Sushi.Vault{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
			}
			Sushi.totalSupply = Sushi.totalSupply + amount
			emit TokensMinted(amount: amount)
			return <-create Vault(balance: amount)
		}
	}
	
	// Burner
	//
	// Resource object that token admin accounts can hold to burn tokens.
	//
	access(all)
	resource Burner{ 
		
		// burnTokens
		//
		// Function that destroys a Vault instance, effectively burning the tokens.
		//
		// Note: the burned tokens are automatically subtracted from the 
		// total supply in the Vault destructor.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun burnTokens(from: @{FungibleToken.Vault}){ 
			let vault <- from as! @Sushi.Vault
			let amount = vault.balance
			destroy vault
			emit TokensBurned(amount: amount)
		}
	}
	
	access(all)
	resource interface MinterProxyPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCapability(cap: Capability<&Sushi.Minter>): Void
	}
	
	// MinterProxy
	//
	// Resource object holding a capability that can be used to mint new tokens.
	// The resource that this capability represents can be deleted by the admin
	// in order to unilaterally revoke minting capability if needed.
	access(all)
	resource MinterProxy: MinterProxyPublic{ 
		
		// access(self) so nobody else can copy the capability and use it.
		access(self)
		var minterCapability: Capability<&Minter>?
		
		// Anyone can call this, but only the admin can create Minter capabilities,
		// so the type system constrains this to being called by the admin.
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCapability(cap: Capability<&Minter>){ 
			self.minterCapability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(amount: UFix64): @Sushi.Vault{ 
			return <-((self.minterCapability!).borrow()!).mintTokens(amount: amount)
		}
		
		init(){ 
			self.minterCapability = nil
		}
	}
	
	// createMinterProxy
	//
	// Function that creates a MinterProxy.
	// Anyone can call this, but the MinterProxy cannot mint without a Minter capability,
	// and only the admin can provide that.
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinterProxy(): @MinterProxy{ 
		emit MinterProxyCreated()
		return <-create MinterProxy()
	}
	
	init(){ 
		self.VaultStoragePath = /storage/basicBeastsSushiVault
		self.ReceiverPublicPath = /public/basicBeastsSushiReceiver
		self.BalancePublicPath = /public/basicBeastsSushiBalance
		self.AdminStoragePath = /storage/basicBeastsSushiAdmin
		self.MinterStoragePath = /storage/basicBeastsSushiMinter
		self.MinterProxyPublicPath = /public/basicBeastsSushiMinterProxy
		self.MinterProxyStoragePath = /storage/basicBeastsSushiMinterProxy
		self.totalSupply = 0.0
		
		// Create the Vault with the total supply of tokens and save it in storage
		let vault <- create Vault(balance: self.totalSupply)
		self.account.storage.save(<-vault, to: self.VaultStoragePath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `deposit` method through the `Receiver` interface
		var capability_1 = self.account.capabilities.storage.issue<&Sushi.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_1, at: self.ReceiverPublicPath)
		
		// Create a public capability to the stored Vault that only exposes
		// the `balance` field through the `Balance` interface
		var capability_2 = self.account.capabilities.storage.issue<&Sushi.Vault>(self.VaultStoragePath)
		self.account.capabilities.publish(capability_2, at: self.BalancePublicPath)
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		
		// Emit an event that shows that the contract was initialized
		emit TokensInitialized(initialSupply: self.totalSupply)
	}
}
