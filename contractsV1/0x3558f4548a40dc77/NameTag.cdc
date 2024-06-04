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

	
// Simplified version from https://flow-view-source.com/testnet/account/0xba1132bc08f82fe2/contract/Profile
// It allows to somone to update a stauts on the blockchain
access(all)
contract NameTag{ 
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let storagePath: StoragePath
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun readTag(): String
	}
	
	access(all)
	resource interface Owner{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun readTag(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeTag(_ tag: String){ 
			pre{ 
				tag.length <= 15:
					"Tags must be under 15 characters long."
			}
		}
	}
	
	access(all)
	resource Base: Owner, Public{ 
		access(self)
		var tag: String
		
		init(){ 
			self.tag = ""
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun readTag(): String{ 
			return self.tag
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeTag(_ tag: String){ 
			self.tag = tag
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun new(): @NameTag.Base{ 
		return <-create Base()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasTag(_ address: Address): Bool{ 
		return getAccount(address).capabilities.get<&{NameTag.Public}>(NameTag.publicPath).check()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun fetch(_ address: Address): &{NameTag.Public}{ 
		return getAccount(address).capabilities.get<&{NameTag.Public}>(NameTag.publicPath).borrow()!
	}
	
	init(){ 
		self.publicPath = /public/boulangeriev1PublicNameTag
		self.storagePath = /storage/boulangeriev1StorageNameTag
		self.account.storage.save(<-self.new(), to: self.storagePath)
		var capability_1 = self.account.capabilities.storage.issue<&Base>(self.storagePath)
		self.account.capabilities.publish(capability_1, at: self.publicPath)
	}
}
