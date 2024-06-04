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
	var shardedNFTMap:{ UInt64:{ UInt64: NFTData}}
	
	access(all)
	let numBuckets: UInt64
	
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
			let bucket = data.id % TopshotData.numBuckets
			let newNFTMap = TopshotData.shardedNFTMap[bucket]!
			newNFTMap[data.id] = data
			TopshotData.shardedNFTMap[bucket] = newNFTMap
			emit NFTDataUpdated(id: data.id, data: data.data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		init(){} 
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTData(id: UInt64): NFTData?{ 
		let bucket = id % TopshotData.numBuckets
		return (self.shardedNFTMap[bucket]!)[id]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	init(){ 
		self.numBuckets = UInt64(100)
		self.shardedNFTMap ={} 
		var i: UInt64 = 0
		while i < self.numBuckets{ 
			self.shardedNFTMap[i] ={} 
			i = i + UInt64(1)
		}
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/TopshotDataAdminV3)
	}
}
