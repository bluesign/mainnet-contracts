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
contract StorefrontService{ 
	
	// basic data about the storefront
	access(all)
	let version: UInt32
	
	access(all)
	let name: String
	
	access(all)
	let description: String
	
	access(all)
	var closed: Bool
	
	// paths
	access(all)
	let ADMIN_OBJECT_PATH: StoragePath
	
	// storefront events
	access(all)
	event StorefrontClosed()
	
	access(all)
	event ContractInitialized()
	
	init(storefrontName: String, storefrontDescription: String){ 
		self.version = 1
		self.name = storefrontName
		self.description = storefrontDescription
		self.closed = false
		self.ADMIN_OBJECT_PATH = /storage/StorefrontAdmin
		
		// put the admin in storage
		self.account.storage.save<@StorefrontAdmin>(
			<-create StorefrontAdmin(),
			to: StorefrontService.ADMIN_OBJECT_PATH
		)
		emit ContractInitialized()
	}
	
	// Returns the version of this contract
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): UInt32{ 
		return self.version
	}
	
	// StorefrontAdmin is used for administering the Storefront
	//
	access(all)
	resource StorefrontAdmin{ 
		
		// Closes the Storefront, rendering any write access impossible
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun close(){ 
			if !StorefrontService.closed{ 
				StorefrontService.closed = true
				emit StorefrontClosed()
			}
		}
		
		// Creates a new StorefrontAdmin that allows for another account
		// to administer the Storefront
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewStorefrontAdmin(): @StorefrontAdmin{ 
			return <-create StorefrontAdmin()
		}
	}
}
