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
contract MarketplaceBlacklist{ 
	
	// listingId : nftId
	access(all)
	let blacklist:{ UInt64: UInt64}
	
	access(all)
	event MarketplaceBlacklistAdd(listingId: UInt64, nftId: UInt64)
	
	access(all)
	event MarketplaceBlacklistRemove(listingId: UInt64, nftId: UInt64)
	
	init(){ 
		self.blacklist ={} 
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun exist(listingId: UInt64): Bool{ 
		return self.blacklist.containsKey(listingId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun add(listingId: UInt64, nftId: UInt64){ 
		self.blacklist[listingId] = nftId
		emit MarketplaceBlacklistAdd(listingId: listingId, nftId: nftId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun remove(listingId: UInt64){ 
		pre{ 
			self.blacklist[listingId] != nil:
				"listingId not exist"
		}
		let nftId = self.blacklist.remove(key: listingId)
		if let unwrappedNftId = nftId{ 
			emit MarketplaceBlacklistRemove(listingId: listingId, nftId: unwrappedNftId)
		}
		assert(nftId != nil, message: "Not been removed successfully!")
	}
}
