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

	import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

access(all)
contract ConcreteBlockPoetry{ 
	access(all)
	event NewPoem(poem: String)
	
	access(all)
	struct interface IPoetryLogic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun generatePoem(blockID: [UInt8; 32]): String
	}
	
	access(all)
	struct PoetryLogic: IPoetryLogic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun generatePoem(blockID: [UInt8; 32]): String{ 
			var poem = ""
			var i = 0
			while i < 32{ 
				poem = poem.concat(self.toAlphabet(blockID[i]!))
				i = i + 1
			}
			return poem
		}
		
		// Based on the frequency of typical English sentences
		access(self)
		fun toAlphabet(_ num: UInt8): String{ 
			if num < 27{ 
				return "E"
			}
			if num < 46{ 
				return "T"
			}
			if num < 63{ 
				return "A"
			}
			if num < 79{ 
				return "O"
			}
			if num < 94{ 
				return "I"
			}
			if num < 108{ 
				return "N"
			}
			if num < 121{ 
				return "S"
			}
			if num < 134{ 
				return "H"
			}
			if num < 147{ 
				return "R"
			}
			if num < 156{ 
				return "D"
			}
			if num < 164{ 
				return "L"
			}
			if num < 170{ 
				return "C"
			}
			if num < 175{ 
				return "U"
			}
			if num < 180{ 
				return "M"
			}
			if num < 185{ 
				return "W"
			}
			if num < 190{ 
				return "F"
			}
			if num < 195{ 
				return "G"
			}
			if num < 200{ 
				return "Y"
			}
			if num < 205{ 
				return "P"
			}
			if num < 208{ 
				return "B"
			}
			if num < 211{ 
				return "V"
			}
			if num < 213{ 
				return "K"
			}
			if num < 214{ 
				return "J"
			}
			if num < 215{ 
				return "X"
			}
			if num < 216{ 
				return "Q"
			}
			if num < 217{ 
				return "Z"
			}
			return " "
		}
	}
	
	access(all)
	resource interface PoetryCollectionPublic{ 
		access(all)
		var poems: @{UFix64: [AnyResource]}
	}
	
	access(all)
	resource PoetryCollection: PoetryCollectionPublic{ 
		access(all)
		var poems: @{UFix64: [AnyResource]}
		
		init(){ 
			self.poems <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun writePoem(poetryLogic:{ IPoetryLogic}){ 
			let poem = poetryLogic.generatePoem(blockID: getCurrentBlock().id)
			self.poems[getCurrentBlock().timestamp] <-! <-ConcreteAlphabets.newText(poem)
			emit NewPoem(poem: poem)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyPoetryCollection(): @PoetryCollection{ 
		return <-create PoetryCollection()
	}
}
