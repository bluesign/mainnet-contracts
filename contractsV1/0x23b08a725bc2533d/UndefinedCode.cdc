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

	// As of September 2023, Unicode 0x30000 to 0xDFFFF are undefined,
// but something might be discovered in the future.
access(all)
contract UndefinedCode{ 
	access(all)
	event Find(codePoint: UInt32)
	
	access(all)
	resource Code{ 
		access(all)
		let point: UInt32
		
		init(){ 
			self.point = self.random() % (0xDFFFF - 0x30000) + 0x30000
			emit Find(codePoint: self.point)
		}
		
		access(self)
		fun random(): UInt32{ 
			let id = getCurrentBlock().id
			return (UInt32(id[0]) << 16) + (UInt32(id[1]) << 8) + UInt32(id[2])
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun find(): @Code{ 
		return <-create Code()
	}
}
