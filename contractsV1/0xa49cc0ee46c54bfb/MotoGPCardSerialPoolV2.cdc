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

	import ContractVersion from "./ContractVersion.cdc"

import MotoGPAdmin from "./MotoGPAdmin.cdc"

access(all)
contract MotoGPCardSerialPoolV2: ContractVersion{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.0.2"
	}
	
	// Should be used only to set a serial base not equal to 0
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun setSerialBase(adminRef: &MotoGPAdmin.Admin, cardID: UInt64, base: UInt64){ 
		if self.serialBaseByCardID[cardID] != nil{ 
			assert(base > self.serialBaseByCardID[cardID]!, message: "new base is less than current base")
		}
		self.serialBaseByCardID[cardID] = base
	}
	
	// Method to add sequential serials for a card id
	// Can be called multiple times
	// Will generate serial starting from the base for that cardID
	//
	access(TMP_ENTITLEMENT_OWNER)
	fun addSerials(adminRef: &MotoGPAdmin.Admin, cardID: UInt64, count: UInt64){ 
		if self.serialBaseByCardID[cardID] == nil{ 
			self.serialBaseByCardID[cardID] = 0
		}
		var index: UInt64 = 0
		if self.serialsByCardID[cardID] == nil{ 
			self.serialsByCardID[cardID] = []
		}
		while index < count{ 
			index = index + UInt64(1)
			(self.serialsByCardID[cardID]!).append(index + self.serialBaseByCardID[cardID]!)
		}
		self.serialBaseByCardID[cardID] = index + self.serialBaseByCardID[cardID]!
	}
	
	// Method to pick a serial for a cardID
	// Randomness for n should be generated before calling this method
	//
	access(account)
	fun pickSerial(n: UInt64, cardID: UInt64): UInt64{ 
		pre{ 
			(self.serialsByCardID[cardID]!).length != 0:
				"No serials for cardID ".concat(cardID.toString())
		}
		let r = n % UInt64((self.serialsByCardID[cardID]!).length)
		return (self.serialsByCardID[cardID]!).remove(at: r)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSerialBaseByCardID(cardID: UInt64): UInt64{ 
		return self.serialBaseByCardID[cardID] ?? 0
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllSerialsByCardID(cardID: UInt64): [UInt64]{ 
		return self.serialsByCardID[cardID] ?? []
	}
	
	access(contract)
	let serialsByCardID:{ UInt64: [UInt64]}
	
	access(contract)
	let serialBaseByCardID:{ UInt64: UInt64}
	
	init(){ 
		self.serialsByCardID ={} 
		self.serialBaseByCardID ={} 
	}
}
