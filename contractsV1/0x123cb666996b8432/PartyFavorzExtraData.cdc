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
contract PartyFavorzExtraData{ 
	access(all)
	let extraData:{ UInt64:{ String: AnyStruct}}
	
	access(account)
	fun setData(id: UInt64, field: String, value: AnyStruct){ 
		let previousData = self.extraData[id] ??{} 
		previousData[field] = value
		self.extraData[id] = previousData
	}
	
	access(account)
	fun removeData(id: UInt64, field: String){ 
		pre{ 
			self.extraData.containsKey(id):
				"Extra data for ID : ".concat(id.toString()).concat(" does not exist")
			(self.extraData[id]!).containsKey(field):
				"Field does not exist : ".concat(field)
		}
		(self.extraData[id]!).remove(key: field)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getData(id: UInt64, field: String): AnyStruct?{ 
		let partyfavorz = self.extraData[id]
		if partyfavorz == nil{ 
			return nil
		}
		return (partyfavorz!)[field]
	}
	
	init(){ 
		self.extraData ={} 
	}
}
