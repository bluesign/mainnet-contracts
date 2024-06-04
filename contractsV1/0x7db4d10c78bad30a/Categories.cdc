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
contract Categories{ 
	// events
	access(all)
	event CategoryAdded(name: String, id: UInt64)
	
	access(all)
	event CategoryRemoved(name: String, id: UInt64)
	
	// struct
	access(all)
	struct Category{ 
		access(all)
		let name: String
		
		access(all)
		let id: UInt64
		
		init(name: String){ 
			pre{ 
				Categories.categories.containsKey(name)
			}
			self.name = name
			self.id = Categories.categories[name]!
		}
	}
	
	// Variables
	access(self)
	var counter: UInt64 // A counter used as an incremental Category ID
	
	
	access(contract)
	var categories:{ String: UInt64} // category list { category name : categoty counter (acts as ID)}
	
	
	// Functions
	// Get Catagories by a list of names or as {name: category id}
	access(TMP_ENTITLEMENT_OWNER)
	fun getCategories(): [String]{ 
		return self.categories.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCategoriesFull():{ String: UInt64}{ 
		return self.categories
	}
	
	// Get category name by using Category ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getCategoryName(id: UInt64): String?{ 
		pre{ 
			id < self.counter:
				"Invalid Category #"
		}
		for cat in self.categories.keys{ 
			if self.categories[cat] == id{ 
				return cat
			}
		}
		return nil
	}
	
	// Get category name by using Category ID
	access(TMP_ENTITLEMENT_OWNER)
	fun getCategoryID(name: String): UInt64{ 
		pre{ 
			self.categories.containsKey(name):
				"Invalid Category"
		}
		return self.categories[name]!
	}
	
	// management functions
	access(account)
	fun addCategory(name: String){ 
		pre{ 
			!self.categories.containsKey(name):
				"Category: ".concat(name).concat(" already exists.")
		}
		post{ 
			self.categories.containsKey(name):
				"Internal Error: Add Category"
		}
		self.categories.insert(key: name, self.counter)
		log("Category Added: ".concat(name))
		emit CategoryAdded(name: name, id: self.counter)
		self.counter = self.counter + 1
	}
	
	access(account)
	fun removeCategory(name: String){ 
		pre{ 
			self.categories.containsKey(name):
				"Category: ".concat(name).concat(" does not exists.")
		}
		post{ 
			!self.categories.containsKey(name):
				"Internal Error: Remove Category"
		}
		self.categories.remove(key: name)
		log("Category Removed: ".concat(name))
		emit CategoryRemoved(name: name, id: self.counter)
	}
	
	init(){ 
		self.counter = 0
		self.categories ={} 
		
		// initial categories
		
		// category types
		self.addCategory(name: "Digital")
		self.addCategory(name: "Physical")
		// detailed types
		self.addCategory(name: "Image")
		self.addCategory(name: "Audio")
		self.addCategory(name: "Video")
		self.addCategory(name: "Text")
		self.addCategory(name: "Photography")
		self.addCategory(name: "Virtual Reality")
		self.addCategory(name: "Augmented Reality")
		// typically physical in nature
		self.addCategory(name: "Sculpture")
		self.addCategory(name: "Fashion")
	}
}
