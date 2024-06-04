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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Minter{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	event MinterAdded(_ t: Type)
	
	access(all)
	resource interface FungibleTokenMinter{ 
		access(all)
		let type: Type
		
		access(all)
		let addr: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(acct: AuthAccount, amount: UFix64): @{FungibleToken.Vault}
	}
	
	access(all)
	resource interface AdminPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMinter(_ t: Type): &{Minter.FungibleTokenMinter}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTypes(): [Type]
	}
	
	access(all)
	resource Admin: AdminPublic{ 
		access(all)
		let minters: @{Type:{ FungibleTokenMinter}} // type to a minter interface
		
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerMinter(_ m: @{FungibleTokenMinter}){ 
			emit MinterAdded(m.getType())
			destroy <-self.minters.insert(key: m.type, <-m)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMinter(_ t: Type): &{FungibleTokenMinter}{ 
			return (&self.minters[t] as &{FungibleTokenMinter}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTypes(): [Type]{ 
			return self.minters.keys
		}
		
		init(){ 
			self.minters <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun borrowAdminPublic(): &Admin?{ 
		return self.account.storage.borrow<&Admin>(from: self.StoragePath)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdmin(): @Admin{ 
		return <-create Admin()
	}
	
	init(){ 
		self.StoragePath = /storage/MinterAdmin
		let a <- create Admin()
		self.account.storage.save(<-a, to: self.StoragePath)
	}
}
