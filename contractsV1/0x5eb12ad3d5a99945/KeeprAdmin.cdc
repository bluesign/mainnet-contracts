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

	import KeeprNFTStorefront from "./KeeprNFTStorefront.cdc"

access(all)
contract KeeprAdmin{ 
	access(all)
	let KeeprAdminStoragePath: StoragePath
	
	access(all)
	let KeeprAdminPublicPath: PublicPath
	
	access(all)
	event InitAdmin()
	
	access(all)
	event AddedCapability(owner: Address)
	
	access(all)
	resource interface AdminStorefrontManagerPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&KeeprNFTStorefront.Storefront>, owner: Address): Void
	}
	
	access(all)
	resource AdminStorefront{ 
		access(all)
		let account: Address
		
		access(all)
		let storefrontCapability: Capability<&KeeprNFTStorefront.Storefront>
		
		init(account: Address, storefrontCapability: Capability<&KeeprNFTStorefront.Storefront>){ 
			self.account = account
			self.storefrontCapability = storefrontCapability
		}
	}
	
	access(all)
	resource AdminStorefrontManager: AdminStorefrontManagerPublic{ 
		access(self)
		var storefronts: @{Address: AdminStorefront}
		
		init(){ 
			self.storefronts <-{} 
			emit InitAdmin()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&KeeprNFTStorefront.Storefront>, owner: Address){ 
			let storefront <- create AdminStorefront(account: owner, storefrontCapability: cap)
			let oldStorefront <- self.storefronts[owner] <- storefront
			destroy oldStorefront
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCapability(owner: Address): &AdminStorefront?{ 
			return &self.storefronts[owner] as &AdminStorefront?
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createStorefrontManager(): @AdminStorefrontManager{ 
		return <-create AdminStorefrontManager()
	}
	
	init(){ 
		self.KeeprAdminStoragePath = /storage/keepradmin002
		self.KeeprAdminPublicPath = /public/keepradmin002
	}
}
