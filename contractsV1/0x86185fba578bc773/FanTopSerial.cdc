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
contract FanTopSerial{ 
	access(all)
	struct Box{ 
		access(all)
		var offset: UInt32
		
		access(all)
		var size: UInt32
		
		access(self)
		let stock: [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStock(): [UInt64]{ 
			return self.stock
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isInStock(_ serialNumber: UInt32): Bool{ 
			pre{ 
				serialNumber >= 1:
					"Serial numbers less than 1 are not available"
				serialNumber <= self.size:
					"Serial numbers that exceed size are not available"
			}
			let chunk = (serialNumber - 1) / 64
			if chunk < self.offset{ 
				return false
			}
			return self.stock[chunk - self.offset] & 1 << UInt64((serialNumber - 1) % 64) != 0
		}
		
		access(account)
		fun pick(_ serialNumber: UInt32){ 
			pre{ 
				self.isInStock(serialNumber):
					"Only serial number that are in stock can be used"
			}
			let chunk = (serialNumber - 1) / 64 - self.offset
			let shift = (serialNumber - 1) % 64
			self.stock[chunk] = self.stock[chunk] ^ 1 << UInt64(shift)
		}
		
		access(account)
		fun truncate(limit: Int): Int{ 
			var count = 0
			while count < limit && self.stock.length > 0 && self.stock[0] == 0{ 
				self.stock.removeFirst()
				self.offset = self.offset + 1
				count = count + 1
			}
			return count
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		init(size: UInt32, pickTo: UInt32){ 
			pre{ 
				size >= pickTo:
					"size must be greater than or equal to pickTo"
			}
			self.size = size
			self.offset = pickTo / 64
			self.stock = []
			var chunk = Int(size / 64 - pickTo / 64) + (size % 64 > 0 ? 1 : 0)
			let length = Int(size)
			let remain = UInt64(size % 64)
			if chunk == 0{ 
				return
			}
			let seed = [UInt64.max]
			while seed.length <= chunk{ 
				if chunk / seed.length % 2 != 0{ 
					self.stock.appendAll(seed)
				}
				seed.appendAll(seed)
			}
			if remain > 0{ 
				self.stock[chunk - 1] = UInt64.max ^ UInt64.max << remain
			}
			self.stock[0] = self.stock[0] & UInt64.max << UInt64(pickTo % 64)
		}
	}
	
	access(self)
	let boxes:{ String: Box}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasBox(itemId: String): Bool{ 
		return self.boxes.containsKey(itemId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBoxRef(itemId: String): &Box?{ 
		if !self.boxes.containsKey(itemId){ 
			return nil
		}
		return &self.boxes[itemId] as &FanTopSerial.Box?
	}
	
	access(account)
	fun putBox(_ box: Box, itemId: String){ 
		pre{ 
			!self.boxes.containsKey(itemId):
				"Box cannot be overwritten"
		}
		self.boxes[itemId] = box
	}
	
	init(){ 
		self.boxes ={} 
	}
}
