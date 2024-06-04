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
contract CounterContract{ 
	access(all)
	let CounterStoragePath: StoragePath
	
	access(all)
	let CounterPublicPath: PublicPath
	
	access(all)
	event AddedCount(currentCount: UInt64)
	
	access(all)
	resource interface HasCount{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun currentCount(): UInt64
	}
	
	access(all)
	resource Counter: HasCount{ 
		access(contract)
		var count: UInt64
		
		init(){ 
			self.count = 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun plusOne(hash: String){ 
			self.count = self.count + 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun currentCount(): UInt64{ 
			return self.count
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun currentCount(): UInt64{ 
		let counter = self.account.capabilities.get<&{HasCount}>(self.CounterPublicPath)
		let counterRef = counter.borrow()!
		return counterRef.currentCount()
	}
	
	// initializer
	//
	init(){ 
		self.CounterStoragePath = /storage/testCounterPrivatePath
		self.CounterPublicPath = /public/testCounterPublicPath
		let counter <- create Counter()
		self.account.storage.save(<-counter, to: self.CounterStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{HasCount}>(self.CounterStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CounterPublicPath)
	}
}
