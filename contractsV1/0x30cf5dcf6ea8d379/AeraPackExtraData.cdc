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
contract AeraPackExtraData{ 
	access(contract)
	let data:{ UInt64:{ String: AnyStruct}}
	
	access(account)
	fun registerItemsForPackType(typeId: UInt64, items: Int){ 
		let item = self.data[typeId] ??{} 
		item["items"] = items
		self.data[typeId] = item
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getItemsPerPackType(_ typeId: UInt64): Int?{ 
		if let item = self.data[typeId]{ 
			if let value = item["items"]{ 
				return value as! Int
			}
		}
		return nil
	}
	
	access(account)
	fun registerTierForPackType(typeId: UInt64, tier: String){ 
		let item = self.data[typeId] ??{} 
		item["packTier"] = tier
		self.data[typeId] = item
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTierPerPackType(_ typeId: UInt64): String?{ 
		if let item = self.data[typeId]{ 
			if let value = item["packTier"]{ 
				return value as! String
			}
		}
		return nil
	}
	
	access(account)
	fun registerItemTypeForPackType(typeId: UInt64, itemType: Type){ 
		let item = self.data[typeId] ??{} 
		item["itemType"] = itemType
		self.data[typeId] = item
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getItemTypePerPackType(_ typeId: UInt64): Type?{ 
		if let item = self.data[typeId]{ 
			if let value = item["itemType"]{ 
				return value as! Type
			}
		}
		return nil
	}
	
	access(account)
	fun registerReceiverPathForPackType(typeId: UInt64, receiverPath: String){ 
		let item = self.data[typeId] ??{} 
		item["receiverPath"] = receiverPath
		self.data[typeId] = item
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getReceiverPathPerPackType(_ typeId: UInt64): String?{ 
		if let item = self.data[typeId]{ 
			if let value = item["receiverPath"]{ 
				return value as! String
			}
		}
		return "aeraNFTs"
	}
	
	init(){ 
		self.data ={} 
	}
}
