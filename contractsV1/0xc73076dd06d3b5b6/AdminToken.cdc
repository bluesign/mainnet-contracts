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

	import Clock from "./Clock.cdc"

// we whitelist admins here
// utilizing an admin token resource gives us the opportunity to expire a given 
// whitelisted (in admin registry) account's resource automatically and in a single place instead of adding that logic to each resource
access(all)
contract AdminToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	var adminRegistry:{ Address: AdminDetails} // registry of authorized Admins
	
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event AdminAdded(address: Address)
	
	access(all)
	event AdminRemoved(address: Address)
	
	access(all)
	let TokenVaultStoragePath: StoragePath
	
	access(all)
	let TokenVaultPublicPath: PublicPath
	
	access(all)
	let TokenMinterStoragePath: StoragePath
	
	access(all)
	let SuperAdminManagerStoragePath: StoragePath
	
	access(all)
	struct AdminDetails{ 
		access(all)
		let created: UFix64
		
		access(all)
		let expires: UFix64
		
		init(expires: UFix64){ 
			self.created = Clock.getTime()
			self.expires = expires
		}
	}
	
	access(all)
	resource Token{ 
		access(all)
		let id: UInt64
		
		access(all)
		let address: Address
		
		init(id: UInt64, address: Address){ 
			self.id = id
			self.address = address
		}
	}
	
	access(all)
	resource interface AdminTokenVaultPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @AdminToken.Token): Void
	}
	
	access(all)
	resource TokenVault: AdminTokenVaultPublic{ 
		access(all)
		var adminToken: @AdminToken.Token?
		
		init(){ 
			self.adminToken <- nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @AdminToken.Token){ 
			let token <- token as! @AdminToken.Token
			let id: UInt64 = token.id
			let oldToken <- self.adminToken <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAdminToken(): &AdminToken.Token?{ 
			if self.adminToken != nil{ 
				let ref = (&self.adminToken as &AdminToken.Token?)!
				return ref
			}
			return nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyTokenVault(): @AdminToken.TokenVault{ 
		return <-create TokenVault()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun checkAuthorizedAdmin(_ adminTokenRef: &AdminToken.Token?){ 
		pre{ 
			adminTokenRef != nil:
				"A reference to an admin token is required"
			AdminToken.adminRegistry[((adminTokenRef!).owner!).address] != nil:
				"Admin was not found in the admin registry"
		}
		if AdminToken.adminRegistry[((adminTokenRef!).owner!).address] == nil{ 
			panic("The address on the Admin NFT is not for a registered admin")
		}
		if (AdminToken.adminRegistry[((adminTokenRef!).owner!).address]!).expires
		<= Clock.getTime(){ 
			panic("Admin token is expired!")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAdminDetails(address: Address): AdminToken.AdminDetails?{ 
		pre{ 
			AdminToken.adminRegistry[address] != nil:
				"Admin doesn't exists"
		}
		return AdminToken.adminRegistry[address]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAdminRegistryKeys(): [Address]{ 
		return AdminToken.adminRegistry.keys
	}
	
	access(all)
	resource TokenMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintToken(recipient: &{AdminToken.AdminTokenVaultPublic}){ 
			var newToken <-
				create Token(id: AdminToken.totalSupply, address: (recipient.owner!).address)
			recipient.deposit(token: <-newToken)
			AdminToken.totalSupply = AdminToken.totalSupply + 1
		}
	}
	
	access(all)
	resource SuperAdminManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addNAdmin(address: Address, expires: UFix64){ 
			pre{ 
				AdminToken.adminRegistry[address] == nil:
					"Admin already exists"
			}
			AdminToken.adminRegistry.insert(key: address, AdminToken.AdminDetails(expires: expires))
			emit AdminAdded(address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAdmin(address: Address){ 
			pre{ 
				AdminToken.adminRegistry[address] != nil:
					"Admin not found"
			}
			AdminToken.adminRegistry.remove(key: address)
			emit AdminRemoved(address: address)
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.adminRegistry ={} 
		self.TokenVaultStoragePath = /storage/kissoAdminTokenTokenVault
		self.TokenVaultPublicPath = /public/kissoAdminTokenTokenVault
		self.TokenMinterStoragePath = /storage/kissoAdminTokenMinter
		self.SuperAdminManagerStoragePath = /storage/kissoSuperAdminManager
		let superAdminManager <- create SuperAdminManager()
		self.account.storage.save(<-superAdminManager, to: self.SuperAdminManagerStoragePath)
		let tokenMinter <- create TokenMinter()
		self.account.storage.save(<-tokenMinter, to: self.TokenMinterStoragePath)
		emit ContractInitialized()
	}
}
