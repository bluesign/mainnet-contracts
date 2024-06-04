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

	// MADE BY: Emerald City, Jacob Tucker

// This is a very simple contract that lets users add addresses
// to an "Info" resource signifying they want them to share their account.  

// This is specifically used by the
// `pub fun borrowSharedRef(fromHost: Address): &FLOATEvents`
// function inside FLOAT.cdc to give users access to someone elses
// FLOATEvents if they are on this shared list.

// This contract is my way of saying I hate private capabilities, so I
// implemented an alternative solution to private access.
access(all)
contract GrantedAccountAccess{ 
	access(all)
	let InfoStoragePath: StoragePath
	
	access(all)
	let InfoPublicPath: PublicPath
	
	access(all)
	resource interface InfoPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllowed(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isAllowed(account: Address): Bool
	}
	
	// A list of people you allow to share your
	// account.
	access(all)
	resource Info: InfoPublic{ 
		access(account)
		var allowed:{ Address: Bool}
		
		// Allow someone to share your account
		access(TMP_ENTITLEMENT_OWNER)
		fun addAccount(account: Address){ 
			self.allowed[account] = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAccount(account: Address){ 
			self.allowed.remove(key: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllowed(): [Address]{ 
			return self.allowed.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isAllowed(account: Address): Bool{ 
			return self.allowed.containsKey(account)
		}
		
		init(){ 
			self.allowed ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createInfo(): @Info{ 
		return <-create Info()
	}
	
	init(){ 
		self.InfoStoragePath = /storage/GrantedAccountAccessInfo
		self.InfoPublicPath = /public/GrantedAccountAccessInfo
	}
}
