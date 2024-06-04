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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowNia from "./FlowNia.cdc"

access(all)
contract FlowNiaRareMintContract{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	var sale: Sale?
	
	access(all)
	struct Sale{ 
		access(all)
		var startTime: UFix64?
		
		access(all)
		var endTime: UFix64?
		
		access(all)
		var max: UInt64
		
		access(all)
		var current: UInt64
		
		access(all)
		var whitelist:{ Address: Bool}
		
		init(
			startTime: UFix64?,
			endTime: UFix64?,
			max: UInt64,
			current: UInt64,
			whitelist:{ 
				Address: Bool
			}
		){ 
			self.startTime = startTime
			self.endTime = endTime
			self.max = max
			self.current = current
			self.whitelist = whitelist
		}
		
		access(contract)
		fun useWhitelist(_ address: Address){ 
			self.whitelist[address] = true
		}
		
		access(contract)
		fun incCurrent(){ 
			self.current = self.current + UInt64(1)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun paymentMint(recipient: &{NonFungibleToken.CollectionPublic}){} 
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setSale(sale: Sale?){ 
			FlowNiaRareMintContract.sale = sale
		}
	}
	
	init(){ 
		self.sale = nil
		self.AdminStoragePath = /storage/FlowNiaRareMintContractAdmin
		self.account.storage.save(<-create Administrator(), to: self.AdminStoragePath)
	}
}
