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
contract ChainlinkFlowToken2: FungibleToken{ 
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
	
	access(all)
	let TokenVaultStoragePath: StoragePath
	
	access(all)
	let TokenVaultPublicPath: PublicPath
	
	access(all)
	let TokenMinterStoragePath: StoragePath
	
	access(all)
	resource Vault: FungibleToken.Vault, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
		access(all)
		var balance: UFix64
		
		init(balance: UFix64){ 
			self.balance = balance
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			self.balance = self.balance - amount
			emit TokensWithdrawn(amount: amount, from: self.owner?.address)
			return <-create Vault(balance: amount)
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			let vault <- from as! @ChainlinkFlowToken2.Vault
			self.balance = self.balance + vault.balance
			emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
			vault.balance = 0.0
			destroy vault // Make sure we get rid of the vault
		
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
	
	access(all)
	fun createEmptyVault(vaultType: Type): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: 0.0)
	}
	
	access(contract)
	fun initialMint(initialMintValue: UFix64): @{FungibleToken.Vault}{ 
		return <-create Vault(balance: initialMintValue)
	}
	
	access(all)
	resource Minter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				amount > 0.0:
					"Amount minted must be greater than zero"
			}
			ChainlinkFlowToken2.totalSupply = ChainlinkFlowToken2.totalSupply + amount
			return <-create Vault(balance: amount)
		}
	}
	
	init(){ 
		self.totalSupply = 100.00
		self.TokenVaultStoragePath = /storage/ChainlinkFlowToken2Vault
		self.TokenVaultPublicPath = /public/ChainlinkFlowToken2Vault
		self.TokenMinterStoragePath = /storage/ChainlinkFlowToken2Minter
		self.account.storage.save(<-create Minter(), to: ChainlinkFlowToken2.TokenMinterStoragePath)
		
		//
		// Create an Empty Vault for the Minter
		//
		self.account.storage.save(<-ChainlinkFlowToken2.initialMint(initialMintValue: self.totalSupply), to: ChainlinkFlowToken2.TokenVaultStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&ChainlinkFlowToken2.Vault>(ChainlinkFlowToken2.TokenVaultStoragePath)
		self.account.capabilities.publish(capability_1, at: ChainlinkFlowToken2.TokenVaultPublicPath)
	}
}
