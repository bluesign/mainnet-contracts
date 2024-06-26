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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FlowFees from "../0xf919ee77447b7497/FlowFees.cdc"

import FlowStorageFees from "./FlowStorageFees.cdc"

access(all)
contract FlowServiceAccount{ 
	access(all)
	event TransactionFeeUpdated(newFee: UFix64)
	
	access(all)
	event AccountCreationFeeUpdated(newFee: UFix64)
	
	access(all)
	event AccountCreatorAdded(accountCreator: Address)
	
	access(all)
	event AccountCreatorRemoved(accountCreator: Address)
	
	access(all)
	event IsAccountCreationRestrictedUpdated(isRestricted: Bool)
	
	/// A fixed-rate fee charged to execute a transaction
	access(all)
	var transactionFee: UFix64
	
	/// A fixed-rate fee charged to create a new account
	access(all)
	var accountCreationFee: UFix64
	
	/// The list of account addresses that have permission to create accounts
	access(contract)
	var accountCreators:{ Address: Bool}
	
	/// Initialize an account with a FlowToken Vault and publish capabilities.
	access(TMP_ENTITLEMENT_OWNER)
	fun initDefaultToken(_ acct: AuthAccount){ 
		// Create a new FlowToken Vault and save it in storage
		acct.save(
			<-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()),
			to: /storage/flowTokenVault
		)
		
		// Create a public capability to the Vault that only exposes
		// the deposit function through the Receiver interface
		acct.link<&FlowToken.Vault>(/public/flowTokenReceiver, target: /storage/flowTokenVault)
		
		// Create a public capability to the Vault that only exposes
		// the balance field through the Balance interface
		acct.link<&FlowToken.Vault>(/public/flowTokenBalance, target: /storage/flowTokenVault)
	}
	
	/// Get the default token balance on an account
	///
	/// Returns 0 if the account has no default balance
	access(TMP_ENTITLEMENT_OWNER)
	fun defaultTokenBalance(_ acct: &Account): UFix64{ 
		var balance = 0.0
		if let balanceRef =
			acct.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance).borrow<
				&FlowToken.Vault
			>(){ 
			balance = balanceRef.balance
		}
		return balance
	}
	
	/// Return a reference to the default token vault on an account
	access(TMP_ENTITLEMENT_OWNER)
	fun defaultTokenVault(_ acct: AuthAccount): &FlowToken.Vault{ 
		return acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
		?? panic("Unable to borrow reference to the default token vault")
	}
	
	/// Will be deprecated and can be deleted after the switchover to FlowFees.deductTransactionFee
	///
	/// Called when a transaction is submitted to deduct the fee
	/// from the AuthAccount that submitted it
	access(TMP_ENTITLEMENT_OWNER)
	fun deductTransactionFee(_ acct: AuthAccount){ 
		if self.transactionFee == UFix64(0){ 
			return
		}
		let tokenVault = self.defaultTokenVault(acct)
		var feeAmount = self.transactionFee
		if self.transactionFee > tokenVault.balance{ 
			feeAmount = tokenVault.balance
		}
		let feeVault <- tokenVault.withdraw(amount: feeAmount)
		FlowFees.deposit(from: <-feeVault)
	}
	
	/// - Deducts the account creation fee from a payer account.
	/// - Inits the default token.
	/// - Inits account storage capacity.
	access(TMP_ENTITLEMENT_OWNER)
	fun setupNewAccount(newAccount: AuthAccount, payer: AuthAccount){ 
		if !FlowServiceAccount.isAccountCreator(payer.address){ 
			panic("Account not authorized to create accounts")
		}
		if self.accountCreationFee < FlowStorageFees.minimumStorageReservation{ 
			panic("Account creation fees setup incorrectly")
		}
		let tokenVault = self.defaultTokenVault(payer)
		let feeVault <- tokenVault.withdraw(amount: self.accountCreationFee)
		let storageFeeVault <-
			feeVault.withdraw(amount: FlowStorageFees.minimumStorageReservation)
			as!
			@FlowToken.Vault
		FlowFees.deposit(from: <-feeVault)
		FlowServiceAccount.initDefaultToken(newAccount)
		let vaultRef = FlowServiceAccount.defaultTokenVault(newAccount)
		vaultRef.deposit(from: <-storageFeeVault)
	}
	
	/// Returns true if the given address is permitted to create accounts, false otherwise
	access(TMP_ENTITLEMENT_OWNER)
	fun isAccountCreator(_ address: Address): Bool{ 
		// If account creation is not restricted, then anyone can create an account
		if !self.isAccountCreationRestricted(){ 
			return true
		}
		return self.accountCreators[address] ?? false
	}
	
	/// Is true if new acconts can only be created by approved accounts `self.accountCreators`
	access(TMP_ENTITLEMENT_OWNER)
	fun isAccountCreationRestricted(): Bool{ 
		return self.account.storage.copy<Bool>(from: /storage/isAccountCreationRestricted) ?? false
	}
	
	// Authorization resource to change the fields of the contract
	/// Returns all addresses permitted to create accounts
	access(TMP_ENTITLEMENT_OWNER)
	fun getAccountCreators(): [Address]{ 
		return self.accountCreators.keys
	}
	
	// Gets Execution Effort Weights from the service account's storage 
	access(TMP_ENTITLEMENT_OWNER)
	fun getExecutionEffortWeights():{ UInt64: UInt64}{ 
		return self.account.storage.copy<{UInt64: UInt64}>(from: /storage/executionEffortWeights)
		?? panic("execution effort weights not set yet")
	}
	
	// Gets Execution Memory Weights from the service account's storage 
	access(TMP_ENTITLEMENT_OWNER)
	fun getExecutionMemoryWeights():{ UInt64: UInt64}{ 
		return self.account.storage.copy<{UInt64: UInt64}>(from: /storage/executionMemoryWeights)
		?? panic("execution memory weights not set yet")
	}
	
	// Gets Execution Memory Limit from the service account's storage
	access(TMP_ENTITLEMENT_OWNER)
	fun getExecutionMemoryLimit(): UInt64{ 
		return self.account.storage.copy<UInt64>(from: /storage/executionMemoryLimit)
		?? panic("execution memory limit not set yet")
	}
	
	/// Authorization resource to change the fields of the contract
	access(all)
	resource Administrator{ 
		
		/// Sets the transaction fee
		access(TMP_ENTITLEMENT_OWNER)
		fun setTransactionFee(_ newFee: UFix64){ 
			if newFee != FlowServiceAccount.transactionFee{ 
				emit TransactionFeeUpdated(newFee: newFee)
			}
			FlowServiceAccount.transactionFee = newFee
		}
		
		/// Sets the account creation fee
		access(TMP_ENTITLEMENT_OWNER)
		fun setAccountCreationFee(_ newFee: UFix64){ 
			if newFee != FlowServiceAccount.accountCreationFee{ 
				emit AccountCreationFeeUpdated(newFee: newFee)
			}
			FlowServiceAccount.accountCreationFee = newFee
		}
		
		/// Adds an account address as an authorized account creator
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccountCreator(_ accountCreator: Address){ 
			if FlowServiceAccount.accountCreators[accountCreator] == nil{ 
				emit AccountCreatorAdded(accountCreator: accountCreator)
			}
			FlowServiceAccount.accountCreators[accountCreator] = true
		}
		
		/// Removes an account address as an authorized account creator
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccountCreator(_ accountCreator: Address){ 
			if FlowServiceAccount.accountCreators[accountCreator] != nil{ 
				emit AccountCreatorRemoved(accountCreator: accountCreator)
			}
			FlowServiceAccount.accountCreators.remove(key: accountCreator)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIsAccountCreationRestricted(_ enabled: Bool){ 
			let path = /storage/isAccountCreationRestricted
			let oldValue = FlowServiceAccount.account.storage.load<Bool>(from: path)
			FlowServiceAccount.account.storage.save<Bool>(enabled, to: path)
			if enabled != oldValue{ 
				emit IsAccountCreationRestrictedUpdated(isRestricted: enabled)
			}
		}
	}
	
	init(){ 
		self.transactionFee = 0.0
		self.accountCreationFee = 0.0
		self.accountCreators ={} 
		let admin <- create Administrator()
		admin.addAccountCreator(self.account.address)
		self.account.storage.save(<-admin, to: /storage/flowServiceAdmin)
	}
}
