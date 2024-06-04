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

access(all)
contract test{ 
	access(all)
	var array: [{String: UInt32}]
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getArray(): [{String: UInt32}]{ 
		return self.array
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun testGas2(){ 
		let tmp = self.array
		tmp.append({"tmp": 0})
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun add(_ item:{ String: UInt32}){ 
		self.array.append(item)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun remove(_ index: Int){ 
		self.array.remove(at: index)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun insert(_ index: Int, item:{ String: UInt32}){ 
		self.array.insert(at: index, item)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun testGas1(batch: Int){ 
		var i = 0
		while i < batch{ 
			self.array.append({"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa": 1})
			i = i + 1
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assign(){ 
		let tmp = self.array
	
	//self.array = tmp
	}
	
	init(){ 
		self.array = []
	}
}
