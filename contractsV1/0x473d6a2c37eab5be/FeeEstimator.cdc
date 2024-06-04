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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

/*
	FeeEstimator
	
	Small contract that allows other contracts to estimate how much storage cost a resource might take up.
	This is done by storing a resource in the FeeEstimator, recording the difference in available balance,
	then returning the difference and the original item being estimated.

	Consumers of this contract would then need to pop the resource out of the DepositEstimate resource to get it back
 */

access(all)
contract FeeEstimator{ 
	access(all)
	resource DepositEstimate{ 
		access(all)
		var item: @AnyResource?
		
		access(all)
		var storageFee: UFix64
		
		init(item: @AnyResource, storageFee: UFix64){ 
			self.item <- item
			self.storageFee = storageFee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(): @AnyResource{ 
			let _resource <- self.item <- nil
			return <-_resource!
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasStorageCapacity(_ addr: Address, _ storageFee: UFix64): Bool{ 
		return FlowStorageFees.defaultTokenAvailableBalance(addr) > storageFee
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun estimateDeposit(item: @AnyResource): @DepositEstimate{ 
		let storageUsedBefore = FeeEstimator.account.storage.used
		FeeEstimator.account.storage.save(<-item, to: /storage/temp)
		let storageUsedAfter = FeeEstimator.account.storage.used
		let storageDiff = storageUsedAfter - storageUsedBefore
		let storageFee = FeeEstimator.storageUsedToFlowAmount(storageDiff)
		let loadedItem <- FeeEstimator.account.storage.load<@AnyResource>(from: /storage/temp)!
		let estimate <- create DepositEstimate(item: <-loadedItem, storageFee: storageFee)
		return <-estimate
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun storageUsedToFlowAmount(_ storageUsed: UInt64): UFix64{ 
		let storageMB = FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storageUsed)
		return FlowStorageFees.storageCapacityToFlow(storageMB)
	}
	
	init(){} 
}
