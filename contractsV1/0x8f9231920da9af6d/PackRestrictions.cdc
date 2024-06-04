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

	access(all)
contract PackRestrictions{ 
	access(all)
	let restrictedIds: [UInt64]
	
	access(all)
	event PackIdAdded(id: UInt64)
	
	access(all)
	event PackIdRemoved(id: UInt64)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllRestrictedIds(): [UInt64]{ 
		return PackRestrictions.restrictedIds
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isRestricted(id: UInt64): Bool{ 
		return PackRestrictions.restrictedIds.contains(id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun accessCheck(id: UInt64){ 
		assert(!PackRestrictions.restrictedIds.contains(id), message: "Pack opening is restricted")
	}
	
	access(account)
	fun addPackId(id: UInt64){ 
		pre{ 
			!PackRestrictions.restrictedIds.contains(id):
				"Pack id already restricted"
		}
		PackRestrictions.restrictedIds.append(id)
		emit PackIdAdded(id: id)
	}
	
	access(account)
	fun removePackId(id: UInt64){ 
		pre{ 
			PackRestrictions.restrictedIds.contains(id):
				"Pack id not restricted"
		}
		let index = PackRestrictions.restrictedIds.firstIndex(of: id)
		if index != nil{ 
			PackRestrictions.restrictedIds.remove(at: index!)
			emit PackIdRemoved(id: id)
		}
	}
	
	init(){ 
		self.restrictedIds = []
	}
}
