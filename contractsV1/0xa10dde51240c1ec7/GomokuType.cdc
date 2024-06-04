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
contract GomokuType{ 
	access(all)
	enum VerifyDirection: UInt8{ 
		access(all)
		case vertical
		
		access(all)
		case horizontal
		
		access(all)
		case diagonal // "/"
		
		
		access(all)
		case reversedDiagonal // "\"
	
	}
	
	access(all)
	enum Role: UInt8{ 
		access(all)
		case host
		
		access(all)
		case challenger
	}
	
	access(all)
	enum StoneColor: UInt8{ 
		// block stone go first
		access(all)
		case black
		
		access(all)
		case white
	}
	
	access(all)
	enum Result: UInt8{ 
		access(all)
		case hostWins
		
		access(all)
		case challengerWins
		
		access(all)
		case draw
	}
	
	access(all)
	resource interface Stoning{ 
		access(all)
		let color: StoneColor
		
		access(all)
		let location: StoneLocation
		
		access(TMP_ENTITLEMENT_OWNER)
		fun key(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun convertToData():{ GomokuType.StoneDataing}
	}
	
	access(all)
	struct interface StoneDataing{ 
		access(all)
		let color: StoneColor
		
		access(all)
		let location: StoneLocation
		
		access(TMP_ENTITLEMENT_OWNER)
		init(color: StoneColor, location: StoneLocation)
	}
	
	access(all)
	struct StoneLocation{ 
		access(all)
		let x: Int8
		
		access(all)
		let y: Int8
		
		access(TMP_ENTITLEMENT_OWNER)
		init(x: Int8, y: Int8){ 
			self.x = x
			self.y = y
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun key(): String{ 
			return self.x.toString().concat(",").concat(self.y.toString())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun description(): String{ 
			return "x: ".concat(self.x.toString()).concat(", y: ").concat(self.y.toString())
		}
	}
}
