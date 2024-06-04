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

import FlowStorageFees from "../0xe467b9dd11fa00df/FlowStorageFees.cdc"

access(all)
contract BloctoStorageRent{ 
	access(all)
	let BloctoStorageRentAdminStoragePath: StoragePath
	
	access(contract)
	var StorageRentRefillThreshold: UInt64
	
	access(contract)
	var RefilledAccounts: [Address]
	
	access(contract)
	var RefilledAccountInfos:{ Address: RefilledAccountInfo}
	
	access(contract)
	var RefillRequiredBlocks: UInt64
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStorageRentRefillThreshold(): UInt64{ 
		return self.StorageRentRefillThreshold
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRefilledAccounts(): [Address]{ 
		return self.RefilledAccounts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRefilledAccountInfos():{ Address: RefilledAccountInfo}{ 
		return self.RefilledAccountInfos
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRefillRequiredBlocks(): UInt64{ 
		return self.RefillRequiredBlocks
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun tryRefill(_ address: Address){ 
		self.cleanExpiredRefilledAccounts(10)
		let recipient = getAccount(address)
		let receiverRef =
			recipient.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow<
				&{FungibleToken.Receiver}
			>()
		if receiverRef == nil || (receiverRef!).owner == nil{ 
			return
		}
		if self.RefilledAccountInfos[address] != nil
		&& getCurrentBlock().height - (self.RefilledAccountInfos[address]!).atBlock
		< self.RefillRequiredBlocks{ 
			return
		}
		var low: UInt64 = recipient.storage.used
		var high: UInt64 = recipient.storage.capacity
		if high < low{ 
			high <-> low
		}
		if high - low < self.StorageRentRefillThreshold{ 
			let vaultRef = self.account.storage.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)
			if vaultRef == nil{ 
				return
			}
			let requiredAmount = FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(self.StorageRentRefillThreshold * 2))
			self.addRefilledAccount(address)
			(receiverRef!).deposit(from: <-(vaultRef!).withdraw(amount: requiredAmount))
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkEligibility(_ address: Address): Bool{ 
		if self.RefilledAccountInfos[address] != nil
		&& getCurrentBlock().height - (self.RefilledAccountInfos[address]!).atBlock
		< self.RefillRequiredBlocks{ 
			return false
		}
		let acct = getAccount(address)
		var high: UInt64 = acct.storage.capacity
		var low: UInt64 = acct.storage.used
		if high < low{ 
			high <-> low
		}
		if high - low >= self.StorageRentRefillThreshold{ 
			return false
		}
		return true
	}
	
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
	
	access(TMP_ENTITLEMENT_OWNER)
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
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setStorageRentRefillThreshold(_ threshold: UInt64){ 
			BloctoStorageRent.StorageRentRefillThreshold = threshold
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRefillRequiredBlocks(_ blocks: UInt64){ 
			BloctoStorageRent.RefillRequiredBlocks = blocks
		}
	}
	
	init(){ 
		self.BloctoStorageRentAdminStoragePath = /storage/BloctoStorageRentAdmin
		self.StorageRentRefillThreshold = 5000
		self.RefilledAccounts = []
		self.RefilledAccountInfos ={} 
		self.RefillRequiredBlocks = 86400
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.BloctoStorageRentAdminStoragePath)
	}
}
