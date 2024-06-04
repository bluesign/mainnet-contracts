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
contract MikoseaUserInformation{ 
	access(all)
	let storagePath: StoragePath
	
	access(all)
	let publicPath: PublicPath
	
	access(all)
	let adminPath: StoragePath
	
	access(contract)
	let userData:{ Address: UserInfo}
	
	access(all)
	struct UserInfo{ 
		access(all)
		var metadata:{ String: String}
		
		init(metadata:{ String: String}){ 
			self.metadata = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun byKey(key: String): String?{ 
			return self.metadata[key]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setKeyValue(key: String, value: String){ 
			self.metadata[key] = value
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun update(metadata:{ String: String}){ 
			self.metadata = metadata
		}
	}
	
	access(all)
	resource Admin{ 
		init(){} 
		
		access(TMP_ENTITLEMENT_OWNER)
		fun upsert(address: Address, metadata:{ String: String}){ 
			MikoseaUserInformation.userData[address] = UserInfo(metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun upsertKeyValue(address: Address, key: String, value: String){ 
			if let user = MikoseaUserInformation.userData[address]{ 
				user.setKeyValue(key: key, value: value)
				self.upsert(address: address, metadata: user.metadata)
			} else{ 
				self.upsert(address: address, metadata:{ key: value})
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun findByAddress(address: Address): UserInfo?{ 
		return MikoseaUserInformation.userData[address]
	}
	
	init(){ 
		// Initialize contract paths
		self.storagePath = /storage/MikoseaUserInformation
		self.publicPath = /public/MikoseaUserInformation
		self.adminPath = /storage/MikoseaUserInformationAdmin
		self.userData ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.adminPath)
	}
}
