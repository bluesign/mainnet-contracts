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

	/**
  This contract contains the MFL Admin logic.The idea is that any account can create an adminProxy,
  but only an AdminRoot in possession of Claims can share them with that admin proxy (using private capabilities).
**/

access(all)
contract MFLAdmin{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event AdminRootCreated(by: Address?)
	
	// Named Paths
	access(all)
	let AdminRootStoragePath: StoragePath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	// MFL Royalty Address
	access(TMP_ENTITLEMENT_OWNER)
	fun royaltyAddress(): Address{ 
		return 0xa654669bd96b2014
	}
	
	// Interface that an AdminProxy will expose to be able to receive Claims capabilites from an AdminRoot
	access(all)
	resource interface AdminProxyPublic{ 
		access(contract)
		fun setClaimCapability(name: String, capability: Capability)
	}
	
	access(all)
	resource AdminProxy: AdminProxyPublic{ 
		
		// Dictionary of all Claims Capabilities stored in an AdminProxy
		access(contract)
		let claimsCapabilities:{ String: Capability}
		
		access(contract)
		fun setClaimCapability(name: String, capability: Capability){ 
			self.claimsCapabilities[name] = capability
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaimCapability(name: String): Capability?{ 
			return self.claimsCapabilities[name]
		}
		
		init(){ 
			self.claimsCapabilities ={} 
		}
	}
	
	// Anyone can create an AdminProxy, but can't do anything without Claims capabilities,
	// and only an AdminRoot can provide that.
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxy(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	// Resource that an admin owns to be able to create new AdminRoot or to set Claims
	access(all)
	resource AdminRoot{ 
		
		// Create a new AdminRoot resource and returns it
		// Only if really needed ! One AdminRoot should be enough for all the logic in MFL
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdminRoot(): @AdminRoot{ 
			emit AdminRootCreated(by: self.owner?.address)
			return <-create AdminRoot()
		}
		
		// Set a Claim capabability for a given AdminProxy
		access(TMP_ENTITLEMENT_OWNER)
		fun setAdminProxyClaimCapability(
			name: String,
			adminProxyRef: &{MFLAdmin.AdminProxyPublic},
			newCapability: Capability
		){ 
			adminProxyRef.setClaimCapability(name: name, capability: newCapability)
		}
	}
	
	init(){ 
		// Set our named paths
		self.AdminRootStoragePath = /storage/MFLAdminRoot
		self.AdminProxyStoragePath = /storage/MFLAdminProxy
		self.AdminProxyPublicPath = /public/MFLAdminProxy
		
		// Create an AdminRoot resource and save it to storage
		let adminRoot <- create AdminRoot()
		self.account.storage.save(<-adminRoot, to: self.AdminRootStoragePath)
		emit ContractInitialized()
	}
}
