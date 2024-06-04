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

	import DigitalNativeArt from "../0xa19cf4dba5941530/DigitalNativeArt.cdc"

access(all)
contract Atelier{ 
	access(all)
	enum Event: UInt8{ 
		access(all)
		case creation
		
		access(all)
		case destruction
	}
	
	access(all)
	struct Record{ 
		access(all)
		let blockHeight: UInt64
		
		access(all)
		let timestamp: UFix64
		
		access(all)
		let event: Event
		
		access(all)
		let creations: UInt64
		
		access(all)
		let destructions: UInt64
		
		init(
			blockHeight: UInt64,
			timestamp: UFix64,
			_event: Event,
			creations: UInt64,
			destructions: UInt64
		){ 
			self.blockHeight = blockHeight
			self.timestamp = timestamp
			self.event = _event
			self.creations = creations
			self.destructions = destructions
		}
	}
	
	access(all)
	var arts: @{UInt64: DigitalNativeArt.Art}
	
	access(all)
	var creations: UInt64
	
	access(all)
	var destructions: UInt64
	
	access(account)
	var records: [Record]
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createArt(): UInt64{ 
		let art <- DigitalNativeArt.create()
		let uuid = art.uuid
		Atelier.arts[uuid] <-! art
		Atelier.creations = Atelier.creations + 1
		let block = getCurrentBlock()
		let record =
			Record(
				blockHeight: block.height,
				timestamp: block.timestamp,
				_event: Event.creation,
				creations: self.creations,
				destructions: self.destructions
			)
		Atelier.records.insert(at: 0, record)
		return uuid
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun destroyArt(uuid: UInt64){ 
		let art <- Atelier.arts.remove(key: uuid)!
		destroy art
		Atelier.destructions = Atelier.destructions + 1
		let block = getCurrentBlock()
		let record =
			Record(
				blockHeight: block.height,
				timestamp: block.timestamp,
				_event: Event.destruction,
				creations: self.creations,
				destructions: self.destructions
			)
		Atelier.records.insert(at: 0, record)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun withdrawArt(uuid: UInt64): @DigitalNativeArt.Art{ 
		return <-Atelier.arts.remove(key: uuid)!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUUIDs(): [UInt64]{ 
		return Atelier.arts.keys
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRecords(from: Int, upTo: Int): [Record]{ 
		if from >= Atelier.records.length{ 
			return []
		}
		if upTo > Atelier.records.length{ 
			return Atelier.records.slice(from: from, upTo: Atelier.records.length)
		}
		return Atelier.records.slice(from: from, upTo: upTo)
	}
	
	init(){ 
		self.arts <-{} 
		self.creations = 1
		self.destructions = 1
		self.records = []
	}
}
