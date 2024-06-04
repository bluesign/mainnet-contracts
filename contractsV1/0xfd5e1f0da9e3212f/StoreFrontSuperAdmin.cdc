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

	// SPDX-License-Identifier: Unlicense
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import StoreFront from "./StoreFront.cdc"

// TOKEN RUNNERS: Contract responsable for Admin and Super admin permissions
access(all)
contract StoreFrontSuperAdmin{ 
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level fields.
	// These contain actual values that are stored in the smart contract.
	// -----------------------------------------------------------------------
	/// Path where the public capability for the `Collection` is available
	access(all)
	let storeFrontAdminReceiverPublicPath: PublicPath
	
	/// Path where the private capability for the `Collection` is available
	access(all)
	let storeFrontAdminReceiverStoragePath: StoragePath
	
	/// Event used on contract initiation
	access(all)
	event ContractInitialized()
	
	/// Event used on create super admin
	access(all)
	event StoreFrontCreated(databaseID: String)
	
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level Composite Type definitions
	// -----------------------------------------------------------------------
	// These are just *definitions* for Types that this contract
	// and other accounts can use. These definitions do not contain
	// actual stored values, but an instance (or object) of one of these Types
	// can be created by this contract that contains stored values.
	// -----------------------------------------------------------------------
	access(all)
	resource interface ISuperAdminStoreFrontPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getStoreFrontPublic(): &NFTStorefront.Storefront
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSecondaryMarketplaceFee(): UFix64
	}
	
	access(all)
	resource SuperAdmin: ISuperAdminStoreFrontPublic{ 
		access(all)
		var storeFront: @NFTStorefront.Storefront
		
		access(all)
		var adminRef: @{UInt64: StoreFront.Admin}
		
		access(all)
		var fee: UFix64
		
		init(databaseID: String){ 
			self.storeFront <- NFTStorefront.createStorefront()
			self.adminRef <-{} 
			self.adminRef[0] <-! StoreFront.createStoreFrontAdmin()
			self.fee = 0.0
			emit StoreFrontCreated(databaseID: databaseID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStoreFront(): &NFTStorefront.Storefront{ 
			return &self.storeFront as &NFTStorefront.Storefront
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStoreFrontPublic(): &NFTStorefront.Storefront{ 
			return &self.storeFront as &NFTStorefront.Storefront
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSecondaryMarketplaceFee(): UFix64{ 
			return self.fee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun changeFee(_newFee: UFix64){ 
			self.fee = _newFee
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawAdmin(): @StoreFront.Admin{ 
			let token <- self.adminRef.remove(key: 0) ?? panic("Cannot withdraw admin resource")
			return <-token
		}
	}
	
	access(all)
	resource interface AdminTokenReceiverPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun receiveAdmin(adminRef: Capability<&StoreFront.Admin>): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun receiveSuperAdmin(superAdminRef: Capability<&SuperAdmin>)
	}
	
	access(all)
	resource AdminTokenReceiver: AdminTokenReceiverPublic{ 
		access(self)
		var adminRef: Capability<&StoreFront.Admin>?
		
		access(self)
		var superAdminRef: Capability<&SuperAdmin>?
		
		init(){ 
			self.adminRef = nil
			self.superAdminRef = nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun receiveAdmin(adminRef: Capability<&StoreFront.Admin>){ 
			self.adminRef = adminRef
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun receiveSuperAdmin(superAdminRef: Capability<&SuperAdmin>){ 
			self.superAdminRef = superAdminRef
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAdminRef(): &StoreFront.Admin?{ 
			return (self.adminRef!).borrow()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSuperAdminRef(): &SuperAdmin?{ 
			return (self.superAdminRef!).borrow()
		}
	}
	
	// -----------------------------------------------------------------------
	// StoreFrontSuperAdmin contract-level function definitions
	// -----------------------------------------------------------------------
	// createAdminTokenReceiver create a admin token receiver. Must be public
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminTokenReceiver(): @AdminTokenReceiver{ 
		return <-create AdminTokenReceiver()
	}
	
	// createSuperAdmin create a super admin. Must be public
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun createSuperAdmin(databaseID: String): @SuperAdmin{ 
		return <-create SuperAdmin(databaseID: databaseID)
	}
	
	init(){ 
		// Paths
		self.storeFrontAdminReceiverPublicPath = /public/AdminTokenReceiver0xfd5e1f0da9e3212f
		self.storeFrontAdminReceiverStoragePath = /storage/AdminTokenReceiver0xfd5e1f0da9e3212f
		emit ContractInitialized()
	}
}
