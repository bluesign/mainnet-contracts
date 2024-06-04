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
contract Traceability{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event ProductCodeCreate(code: String)
	
	access(all)
	event ProductCodeRemove(code: String)
	
	access(all)
	resource interface ProductCodePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun ProductCodeExist(code: String): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun GetAllProductCodes(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ProductCodesLength(): Integer
	}
	
	access(all)
	resource ProductCodeList: ProductCodePublic{ 
		access(all)
		var CodeMap:{ String: Bool}
		
		init(){ 
			self.CodeMap ={} 
		}
		
		// public interface contains function that everyone can call
		access(TMP_ENTITLEMENT_OWNER)
		fun ProductCodesLength(): Integer{ 
			return self.CodeMap.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun ProductCodeExist(code: String): Bool{ 
			return self.CodeMap.containsKey(code)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun GetAllProductCodes(): [String]{ 
			return self.CodeMap.keys
		}
		
		// only account owner can call the rest of functions
		access(TMP_ENTITLEMENT_OWNER)
		fun AddProductCode(code: String){ 
			self.CodeMap[code] = true
			emit ProductCodeCreate(code: code)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun RemoveProductCode(code: String){ 
			if self.CodeMap.containsKey(code){ 
				self.CodeMap.remove(key: code)
				emit ProductCodeRemove(code: code)
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createCodeList(): @ProductCodeList{ 
		return <-create ProductCodeList()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/CodeCollection
		self.CollectionPublicPath = /public/CodeCollection
		
		// store an empty ProductCode Collection in account storage
		self.account.storage.save(<-self.createCodeList(), to: self.CollectionStoragePath)
		
		// publish a reference to the Collection in storage
		// create a public capability for the collection
		var capability_1 =
			self.account.capabilities.storage.issue<&Traceability.ProductCodeList>(
				self.CollectionStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
