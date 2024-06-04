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

	import FLOAT from "./FLOAT.cdc"

access(all)
contract FLOATIncinerator{ 
	access(all)
	let IncineratorStoragePath: StoragePath
	
	access(all)
	let IncineratorPublicPath: PublicPath
	
	access(all)
	var flameStrength: UInt64
	
	access(all)
	var totalIncinerated: UInt64
	
	access(all)
	resource interface IncineratorPublic{ 
		access(all)
		var individualIncinerated: UInt64
		
		access(all)
		var contributedStrength: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtraMetadata():{ String: String}
	}
	
	access(all)
	resource Incinerator: IncineratorPublic{ 
		access(all)
		var individualIncinerated: UInt64
		
		access(all)
		var contributedStrength: UInt64
		
		access(self)
		var extraMetadata:{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun burn(collection: &FLOAT.Collection, ids: [UInt64]){ 
			let length = ids.length
			for id in ids{ 
				let float: &FLOAT.NFT = collection.borrowFLOAT(id: id) ?? panic("This FLOAT does not exist.")
				let score = FLOATIncinerator.calculateScore(dateReceived: float.dateReceived, serial: float.serial)
				self.contributedStrength = self.contributedStrength + score
				FLOATIncinerator.flameStrength = FLOATIncinerator.flameStrength + score
				collection.delete(id: id)
			}
			self.individualIncinerated = self.individualIncinerated + UInt64(length)
			FLOATIncinerator.totalIncinerated = FLOATIncinerator.totalIncinerated + UInt64(length)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtraMetadata():{ String: String}{ 
			return self.extraMetadata
		}
		
		init(){ 
			self.individualIncinerated = 0
			self.contributedStrength = 0
			self.extraMetadata ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createIncinerator(): @Incinerator{ 
		return <-create Incinerator()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun calculateScore(dateReceived: UFix64, serial: UInt64): UInt64{ 
		// Serial
		var serialScore: UInt64 = 0
		if serial < 10{ 
			serialScore = 5
		} else if serial < 100{ 
			serialScore = 4
		} else if serial < 1000{ 
			serialScore = 3
		} else if serial < 10000{ 
			serialScore = 2
		} else if serial < 100000{ 
			serialScore = 1
		}
		
		// Time
		var timeScore: UInt64 = 0
		var difference = getCurrentBlock().timestamp - dateReceived
		if difference > 31556926.0{ // a year 
			
			timeScore = 5
		} else if difference > 2629743.0{ // a month 
			
			timeScore = 4
		} else if difference > 604800.0{ // a week 
			
			timeScore = 3
		} else if difference > 86400.0{ // a day 
			
			timeScore = 2
		} else if difference > 3600.0{ // an hour 
			
			timeScore = 1
		}
		return serialScore + timeScore
	}
	
	init(){ 
		self.IncineratorStoragePath = /storage/FLOATIncineratorStoragePath
		self.IncineratorPublicPath = /public/FLOATIncineratorPublicPath
		self.totalIncinerated = 0
		self.flameStrength = 0
	}
}
