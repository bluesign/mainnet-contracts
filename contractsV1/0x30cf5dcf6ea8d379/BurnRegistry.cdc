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

	//This is not in use because of complexity issues, we cannot access playEditions if it is too large
access(all)
contract BurnRegistry{ 
	access(self)
	let playEditions:{ UInt64: [UInt64]}
	
	access(account)
	fun burnEdition(playId: UInt64, edition: UInt64){ 
		if self.playEditions[edition] != nil{ 
			(self.playEditions[edition]!).append(edition)
			return
		}
		self.playEditions[edition] = [edition]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBurnRegistry():{ UInt64: [UInt64]}{ 
		return self.playEditions
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumbersBurned(_ playId: UInt64): Int{ 
		if let burned = self.playEditions[playId]{ 
			return burned.length
		}
		return 0
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBurnedEditions(_ playId: UInt64): [UInt64]{ 
		return self.playEditions[playId] ?? []
	}
	
	init(){ 
		self.playEditions ={} 
	}
}
