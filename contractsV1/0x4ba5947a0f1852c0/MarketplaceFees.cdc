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

import MemeToken from "./MemeToken.cdc"

/// The MarketplaceFees contract is responsible for managing the fees for the marketplace.
/// This contract derived from the FlowTokenFees contract in the FlowToken contract.
access(all)
contract MarketplaceFees{ 
	
	// Event that is emitted when tokens are deposited to the fee vault
	access(all)
	event TokensDeposited(amount: UFix64)
	
	// Event that is emitted when tokens are withdrawn from the fee vault
	access(all)
	event TokensWithdrawn(amount: UFix64)
	
	// Event that is emitted when fees are deducted
	access(all)
	event FeesDeducted(amount: UFix64)
	
	// Event that is emitted when fee parameters change
	access(all)
	event FeeParametersChanged(rate: UFix64)
	
	// Private vault with public deposit function
	access(self)
	var vault: @MemeToken.Vault
	
	access(TMP_ENTITLEMENT_OWNER)
	fun deposit(from: @{FungibleToken.Vault}){ 
		let from <- from as! @MemeToken.Vault
		let balance = from.balance
		self.vault.deposit(from: <-from)
		emit TokensDeposited(amount: balance)
	}
	
	/// Get the balance of the Fees Vault
	access(TMP_ENTITLEMENT_OWNER)
	fun getFeeBalance(): UFix64{ 
		return self.vault.balance
	}
	
	access(all)
	resource Administrator{ 
		// withdraw
		//
		// Allows the administrator to withdraw tokens from the fee vault
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawTokensFromFeeVault(amount: UFix64): @{FungibleToken.Vault}{ 
			let vault <- MarketplaceFees.vault.withdraw(amount: amount)
			emit TokensWithdrawn(amount: amount)
			return <-vault
		}
		
		/// Allows the administrator to change all the fee parameters at once
		access(TMP_ENTITLEMENT_OWNER)
		fun setFeeParameters(
			rate: UFix64,
			receiverCapability: Capability<&{FungibleToken.Receiver}>
		){ 
			let newParameters = FeeParameters(rate: rate, receiverCapability: receiverCapability)
			MarketplaceFees.setFeeParameters(newParameters)
		}
	}
	
	/// A struct holding the fee parameters needed to calculate the fees
	access(all)
	struct FeeParameters{ 
		/// The surge factor is used to make transaction fees respond to high loads on the network
		access(all)
		var rate: UFix64
		
		/// The receiver capability is used to deposit the fees to the fee vault
		access(all)
		var receiverCapability: Capability<&{FungibleToken.Receiver}>
		
		init(rate: UFix64, receiverCapability: Capability<&{FungibleToken.Receiver}>){ 
			self.rate = rate
			self.receiverCapability = receiverCapability
		}
	}
	
	/// Called when a transaction is submitted to deduct the fee
	/// from the AuthAccount that submitted it
	access(TMP_ENTITLEMENT_OWNER)
	fun deductFee(_ account: AuthAccount, totalAmount: UFix64){ 
		var feeAmount = self.computeFees(amount: totalAmount, description: nil)
		if feeAmount == UFix64(0){ 
			// If there are no fees to deduct, do not continue, 
			// so that there are no unnecessarily emitted events
			return
		}
		let tokenVault =
			account.borrow<&MemeToken.Vault>(from: MemeToken.VaultStoragePath)
			?? panic("Unable to borrow reference to the default token vault")
		if feeAmount > tokenVault.balance{ 
			// In the future this code path will never be reached, 
			// as payers that are under account minimum balance will not have their transactions included in a collection
			//
			// Currently this is not used to fail the transaction (as that is the responsibility of the minimum account balance logic),
			// But is used to reduce the balance of the vault to 0.0, if the vault has less available balance than the transaction fees. 
			feeAmount = tokenVault.balance
		}
		let feeVault <- tokenVault.withdraw(amount: feeAmount)
		self.vault.deposit(from: <-feeVault)
		
		// The fee calculation can be reconstructed using the data from this event and the FeeParameters at the block when the event happened
		emit FeesDeducted(amount: feeAmount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFeeParameters(): FeeParameters{ 
		return self.account.storage.copy<FeeParameters>(from: /storage/MarketplaceFeeParameters)
		?? panic("Error getting marketplace fee parameters. They need to be initialized first!")
	}
	
	access(self)
	fun setFeeParameters(_ feeParameters: FeeParameters){ 
		// empty storage before writing new FeeParameters to it
		self.account.storage.load<FeeParameters>(from: /storage/MarketplaceFeeParameters)
		self.account.storage.save(feeParameters, to: /storage/MarketplaceFeeParameters)
		emit FeeParametersChanged(rate: feeParameters.rate)
	}
	
	// compute the transaction fees with the current fee parameters and the given inclusionEffort and executionEffort
	access(TMP_ENTITLEMENT_OWNER)
	fun computeFees(amount: UFix64, description: String?): UFix64{ 
		let params = self.getFeeParameters()
		return params.rate * amount
	}
	
	init(){ 
		// Create a new empty Vault for the fees if not already created
		self.vault <- MemeToken.createEmptyVault(vaultType: Type<@MemeToken.Vault>())
		let admin <- create Administrator()
		self.account.storage.save(<-admin, to: /storage/marketplaceFeesAdmin)
		
		// Create receiver capability for the fee vault
		let capability =
			getAccount(self.account.address).capabilities.get<&{FungibleToken.Receiver}>(
				MemeToken.ReceiverPublicPath
			)
		
		// Initialize the fee parameters if they are not already initialized
		if self.account.storage.borrow<&FeeParameters>(from: /storage/MarketplaceFeeParameters)
		== nil{ 
			let feeParameters = FeeParameters(rate: 0.05, receiverCapability: capability!)
			self.account.storage.save(feeParameters, to: /storage/MarketplaceFeeParameters)
		}
	}
}
