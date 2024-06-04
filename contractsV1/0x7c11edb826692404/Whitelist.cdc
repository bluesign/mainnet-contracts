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
contract Whitelist{ 
	access(self)
	let whitelist:{ Address: Bool}
	
	access(self)
	let bought:{ Address: Bool}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	event WhitelistUpdate(addresses: [Address], whitelisted: Bool)
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addWhitelist(addresses: [Address]){ 
			for address in addresses{ 
				Whitelist.whitelist[address] = true
			}
			emit WhitelistUpdate(addresses: addresses, whitelisted: true)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unWhitelist(addresses: [Address]){ 
			for address in addresses{ 
				Whitelist.whitelist[address] = false
			}
			emit WhitelistUpdate(addresses: addresses, whitelisted: false)
		}
	}
	
	access(account)
	fun markAsBought(address: Address){ 
		self.bought[address] = true
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun whitelisted(address: Address): Bool{ 
		return self.whitelist[address] ?? false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasBought(address: Address): Bool{ 
		return self.bought[address] ?? false
	}
	
	init(){ 
		self.whitelist ={} 
		self.bought ={} 
		self.AdminStoragePath = /storage/BNMUWhitelistAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
