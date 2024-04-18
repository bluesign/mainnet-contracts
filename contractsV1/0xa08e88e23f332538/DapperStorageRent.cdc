import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import PrivateReceiverForwarder from "./../../standardsV1/PrivateReceiverForwarder.cdc"

/// DapperStorageRent
/// Provide a means for accounts storage TopUps. To be used during transaction execution.
access(all)
contract DapperStorageRent{ 
	access(all)
	let DapperStorageRentAdminStoragePath: StoragePath
	
	/// Threshold of storage required to trigger a refill
	access(contract)
	var StorageRentRefillThreshold: UInt64
	
	/// List of all refilledAccounts
	access(contract)
	var RefilledAccounts: [Address]
	
	/// Detailed account information of refilled accounts
	access(contract)
	var RefilledAccountInfos:{ Address: RefilledAccountInfo}
	
	/// List of all blockedAccounts
	access(contract)
	var BlockedAccounts: [Address]
	
	/// Blocks required between refill attempts
	access(contract)
	var RefillRequiredBlocks: UInt64
	
	/// Event emitted when an Admin blocks an address
	access(all)
	event BlockedAddress(_ address: [Address])
	
	/// Event emitted when a Refill is successful
	access(all)
	event Refuelled(_ address: Address)
	
	/// Event emitted when a Refill is not successful
	access(all)
	event RefilledFailed(address: Address, reason: String)
	
	/// getStorageRentRefillThreshold
	/// Get the current StorageRentRefillThreshold
	///
	/// @return UInt64 value of the current StorageRentRefillThreshold value
	access(all)
	fun getStorageRentRefillThreshold(): UInt64{ 
		return self.StorageRentRefillThreshold
	}
	
	/// getRefilledAccounts
	/// Get the current StorageRentRefillThreshold
	///
	/// @return List of refilled Accounts
	access(all)
	fun getRefilledAccounts(): [Address]{ 
		return self.RefilledAccounts
	}
	
	/// getBlockedAccounts
	/// Get the current StorageRentRefillThreshold
	///
	/// @return List of blocked accounts
	access(all)
	fun getBlockedAccounts(): [Address]{ 
		return self.BlockedAccounts
	}
	
	/// getRefilledAccountInfos
	/// Get the current StorageRentRefillThreshold
	///
	/// @return Address: RefilledAccountInfo mapping
	access(all)
	fun getRefilledAccountInfos():{ Address: RefilledAccountInfo}{ 
		return self.RefilledAccountInfos
	}
	
	/// getRefillRequiredBlocks
	/// Get the current StorageRentRefillThreshold
	///
	/// @return UInt64 value of the current RefillRequiredBlocks value
	access(all)
	fun getRefillRequiredBlocks(): UInt64{ 
		return self.RefillRequiredBlocks
	}
	
	access(all)
	fun fundedRefillV2(address: Address, tokens: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
		let privateForwardingSenderRef =
			self.account.storage.borrow<&PrivateReceiverForwarder.Sender>(
				from: PrivateReceiverForwarder.SenderStoragePath
			)!
		(privateForwardingSenderRef!).sendPrivateTokens(
			address,
			tokens: <-tokens.withdraw(amount: tokens.balance)
		)
		return <-tokens
	}
	
	/// tryRefill
	/// Attempt to refill an accounts storage capacity if it has dipped below threshold and passes other checks.
	///
	/// @param address: Address to attempt a storage refill on
	access(all)
	fun tryRefill(_ address: Address){ 
		let REFUEL_AMOUNT = 0.06
		self.cleanExpiredRefilledAccounts(10)
		
		// Get the Flow Token reciever of the address
		let recipient = getAccount(address)
		let receiverRef =
			(
				recipient.capabilities.get<&PrivateReceiverForwarder.Forwarder>(
					PrivateReceiverForwarder.PrivateReceiverPublicPath
				)!
			).borrow()
		
		// Silently fail if the `receiverRef` is `nill`
		if receiverRef == nil || (receiverRef!).owner == nil{ 
			emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts flowTokenVault")
			return
		}
		
		// Silently fail if the account has already be refueled within the block allowance
		if self.RefilledAccountInfos[address] != nil
		&& getCurrentBlock().height - (self.RefilledAccountInfos[address]!).atBlock
		< self.RefillRequiredBlocks{ 
			emit RefilledFailed(address: address, reason: "RefillRequiredBlocks")
			return
		}
		if recipient.storage.used < recipient.storage.capacity
		&& recipient.storage.capacity - recipient.storage.used > self.StorageRentRefillThreshold{ 
			emit RefilledFailed(
				address: address,
				reason: "Address is not below StorageRentRefillThreshold"
			)
			return
		}
		let vaultRef = self.account.storage.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
		if vaultRef == nil{ 
			emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts FlowToken.Vault")
			return
		}
		let privateForwardingSenderRef =
			self.account.storage.borrow<&PrivateReceiverForwarder.Sender>(
				from: PrivateReceiverForwarder.SenderStoragePath
			)
		if privateForwardingSenderRef == nil{ 
			emit RefilledFailed(address: address, reason: "Couldn't borrow the Accounts PrivateReceiverForwarder")
			return
		}
		
		// Check to make sure the payment vault has sufficient funds
		if let vaultBalanceRef =
			(self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance)!).borrow(){ 
			if vaultBalanceRef.balance <= REFUEL_AMOUNT{ 
				emit RefilledFailed(address: address, reason: "Insufficient balance to refuel")
				return
			}
		} else{ 
			emit RefilledFailed(address: address, reason: "Couldn't borrow flowToken balance")
			return
		}
		
		// 0.06 = 6MB of storage, or ~20k NBA TS moments
		self.addRefilledAccount(address)
		(privateForwardingSenderRef!).sendPrivateTokens(
			address,
			tokens: <-(vaultRef!).withdraw(amount: REFUEL_AMOUNT)
		)
		emit Refuelled(address)
	}
	
	/// checkEligibility
	///
	/// @param address: Address to check eligibility on
	/// @return Boolean valued based on if the provided address is below the storage threshold
	access(all)
	fun checkEligibility(_ address: Address): Bool{ 
		if self.RefilledAccountInfos[address] != nil
		&& getCurrentBlock().height - (self.RefilledAccountInfos[address]!).atBlock
		< self.RefillRequiredBlocks{ 
			return false
		}
		let acct = getAccount(address)
		if acct.storage.used < acct.storage.capacity
		&& acct.storage.capacity - acct.storage.used > self.StorageRentRefillThreshold{ 
			return false
		}
		return true
	}
	
	/// addRefilledAccount
	///
	/// @param address: Address to add to RefilledAccounts/RefilledAccountInfos
	access(contract)
	fun addRefilledAccount(_ address: Address){ 
		if self.RefilledAccountInfos[address] != nil{ 
			self.RefilledAccounts.remove(at: (self.RefilledAccountInfos[address]!).index)
		}
		self.RefilledAccounts.append(address)
		self.RefilledAccountInfos[address] = RefilledAccountInfo(
				self.RefilledAccounts.length - 1,
				getCurrentBlock().height
			)
	}
	
	/// cleanExpiredRefilledAccounts
	/// public method to clean up expired accounts based on current block height
	///
	/// @param batchSize: Int to set the batch size of the cleanup
	access(all)
	fun cleanExpiredRefilledAccounts(_ batchSize: Int){ 
		var index = 0
		while index < batchSize && self.RefilledAccounts.length > index{ 
			if self.RefilledAccountInfos[self.RefilledAccounts[index]] != nil && getCurrentBlock().height - (self.RefilledAccountInfos[self.RefilledAccounts[index]]!).atBlock < self.RefillRequiredBlocks{ 
				break
			}
			self.RefilledAccountInfos.remove(key: self.RefilledAccounts[index])
			self.RefilledAccounts.remove(at: index)
			index = index + 1
		}
	}
	
	/// RefilledAccountInfo struct
	/// Holds the block number it was refilled at
	access(all)
	struct RefilledAccountInfo{ 
		access(all)
		let atBlock: UInt64
		
		access(all)
		let index: Int
		
		init(_ index: Int, _ atBlock: UInt64){ 
			self.index = index
			self.atBlock = atBlock
		}
	}
	
	/// Admin resource
	/// Used to set different configuration levers such as StorageRentRefillThreshold, RefillRequiredBlocks, and BlockedAccounts
	access(all)
	resource Admin{ 
		access(all)
		fun setStorageRentRefillThreshold(_ threshold: UInt64){ 
			DapperStorageRent.StorageRentRefillThreshold = threshold
		}
		
		access(all)
		fun setRefillRequiredBlocks(_ blocks: UInt64){ 
			DapperStorageRent.RefillRequiredBlocks = blocks
		}
		
		access(all)
		fun blockAddress(_ address: Address){ 
			if !DapperStorageRent.getBlockedAccounts().contains(address){ 
				DapperStorageRent.BlockedAccounts.append(address)
				emit BlockedAddress(DapperStorageRent.getBlockedAccounts())
			}
		}
		
		access(all)
		fun unblockAddress(_ address: Address){ 
			if DapperStorageRent.getBlockedAccounts().contains(address){ 
				let position = DapperStorageRent.BlockedAccounts.firstIndex(of: address) ?? panic("Trying to unblock an address that is not blocked.")
				if position != nil{ 
					DapperStorageRent.BlockedAccounts.remove(at: position)
					emit BlockedAddress(DapperStorageRent.getBlockedAccounts())
				}
			}
		}
	}
	
	// DapperStorageRent init
	init(){ 
		self.DapperStorageRentAdminStoragePath = /storage/DapperStorageRentAdmin
		self.StorageRentRefillThreshold = 5000
		self.RefilledAccounts = []
		self.RefilledAccountInfos ={} 
		self.RefillRequiredBlocks = 86400
		self.BlockedAccounts = []
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.DapperStorageRentAdminStoragePath)
	}
}