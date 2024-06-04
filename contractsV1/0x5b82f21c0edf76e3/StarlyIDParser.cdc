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
contract StarlyIDParser{ 
	access(self)
	let powersOf10: [UInt32; 8]
	
	init(){ 
		self.powersOf10 = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000]
	}
	
	access(all)
	struct StarlyID{ 
		access(all)
		let collectionID: String
		
		access(all)
		let cardID: UInt32
		
		access(all)
		let edition: UInt32
		
		init(collectionID: String, cardID: UInt32, edition: UInt32){ 
			self.collectionID = collectionID
			self.cardID = cardID
			self.edition = edition
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun parse(starlyID: String): StarlyID{ 
		let length = starlyID.length
		var x = length - 1
		var collectionEndIndex = 0
		var editionEndIndex = 0
		while x > 0{ 
			if starlyID[x] == "/"{ 
				if editionEndIndex == 0{ 
					editionEndIndex = x
				} else{ 
					collectionEndIndex = x
					break
				}
			}
			x = x - 1
		}
		let collectionID = starlyID.slice(from: 0, upTo: collectionEndIndex)
		let cardID = starlyID.slice(from: collectionEndIndex + 1, upTo: editionEndIndex)
		let edition = starlyID.slice(from: editionEndIndex + 1, upTo: length)
		return StarlyID(
			collectionID: collectionID,
			cardID: self.parseInt(cardID),
			edition: self.parseInt(edition)
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun parseInt(_ str: String): UInt32{ 
		var number: UInt32 = 0
		let chars = str.utf8
		assert(chars.length > 0, message: "Cannot parse ".concat(str))
		assert(chars.length < 9, message: "Number too big ".concat(str))
		var i = 0
		for c in chars{ 
			let multiplier = self.powersOf10[chars.length - 1 - i]
			let digit = UInt32(c) - 48
			if digit < 0 || digit > 9{ 
				panic("Cannot parse ".concat(str))
			}
			number = number + digit * multiplier
			i = i + 1
		}
		return number
	}
}
