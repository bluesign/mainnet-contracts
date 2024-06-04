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
contract DataObject{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let privatePath: StoragePath
	
	access(all)
	resource interface ObjectPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getObjectData(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setObjectData(_ data: String){ 
			pre{ 
				data.length >= 2:
					"Data not of sufficient length"
			}
		}
	}
	
	access(all)
	resource Object: ObjectPublic{ 
		access(self)
		var data: String
		
		init(metadata: String){ 
			self.data = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getObjectData(): String{ 
			return self.data
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setObjectData(_ data: String){ 
			self.data = data
		}
	}
	
	access(all)
	resource Collection{ 
		//Dictionary of the Object with string
		access(all)
		var objects: @{String: Object}
		
		//Initilize the Objects filed to an empty collection
		init(){ 
			self.objects <-{} 
		}
		
		//remove 
		access(TMP_ENTITLEMENT_OWNER)
		fun removeObject(objectId: String){ 
			let item <- self.objects.remove(key: objectId) ?? panic("Cannot remove")
			destroy item
		}
		
		//update 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateObject(objectId: String, data: String){ 
			self.objects[objectId]?.setObjectData(data)
		}
		
		//add
		access(TMP_ENTITLEMENT_OWNER)
		fun addObject(objectId: String, data: String){ 
			var object <- create Object(metadata: data)
			self.objects[objectId] <-! object
		}
		
		//read keys
		access(TMP_ENTITLEMENT_OWNER)
		fun getObjectKeys(): [String]{ 
			return self.objects.keys
		}
	}
	
	// creates a new empty Collection resource and returns it 
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyObjectCollection(): @Collection{ 
		return <-create Collection()
	}
	
	// check if the collection exists or not 
	access(TMP_ENTITLEMENT_OWNER)
	fun check(objectID: String, address: Address): Bool{ 
		return getAccount(address).capabilities.get<&Collection>(self.publicPath).check()
	}
	
	init(){ 
		self.publicPath = /public/object
		self.privatePath = /storage/object
		self.account.storage.save(<-self.createEmptyObjectCollection(), to: self.privatePath)
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.privatePath)
		self.account.capabilities.publish(capability_1, at: self.publicPath)
	}
}
