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
contract BarterYardStats{ 
	access(self)
	var minted: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintedTokens(): UInt64{ 
		return BarterYardStats.minted
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun setLastMintedToken(lastID: UInt64){ 
		self.minted = lastID
	}
	
	access(account)
	fun getNextTokenId(): UInt64{ 
		self.minted = self.minted + 1
		return self.minted
	}
	
	access(all)
	resource Admin{} 
	
	init(){ 
		self.minted = 5500
		emit ContractInitialized()
	}
}
