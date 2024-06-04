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
contract SportsIconCounter{ 
	access(all)
	var nextNFTID: UInt64
	
	access(all)
	var nextSetID: UInt64
	
	access(all)
	var nextAuctionID: UInt64
	
	access(all)
	var nextBuyNowID: UInt64
	
	access(account)
	fun incrementNFTCounter(): UInt64{ 
		self.nextNFTID = self.nextNFTID + 1
		return self.nextNFTID
	}
	
	access(account)
	fun incrementSetCounter(): UInt64{ 
		self.nextSetID = self.nextSetID + 1
		return self.nextSetID
	}
	
	access(account)
	fun incrementAuctionCounter(): UInt64{ 
		self.nextAuctionID = self.nextAuctionID + 1
		return self.nextAuctionID
	}
	
	access(account)
	fun incrementBuyNowCounter(): UInt64{ 
		self.nextBuyNowID = self.nextBuyNowID + 1
		return self.nextBuyNowID
	}
	
	init(){ 
		self.nextNFTID = 1
		self.nextSetID = 1
		self.nextAuctionID = 1
		self.nextBuyNowID = 1
	}
}
