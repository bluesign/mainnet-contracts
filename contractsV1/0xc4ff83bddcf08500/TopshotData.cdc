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
contract TopshotData{ 
	access(self)
	var nftMap:{ UInt64: NFTData}
	
	access(all)
	event NFTDataUpdated(id: UInt64, data:{ String: String})
	
	access(all)
	struct NFTData{ 
		access(all)
		let data:{ String: String}
		
		access(all)
		let id: UInt64
		
		init(id: UInt64, data:{ String: String}){ 
			self.id = id
			self.data = data
		}
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun upsertNFTData(data: NFTData){ 
			TopshotData.nftMap[data.id] = data
			emit NFTDataUpdated(id: data.id, data: data.data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTData(id: UInt64): NFTData?{ 
		return self.nftMap[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	init(){ 
		self.nftMap ={} 
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/TopshotDataAdmin)
	}
}
