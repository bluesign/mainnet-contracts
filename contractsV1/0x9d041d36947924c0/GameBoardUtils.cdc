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

	import StringUtils from "./../../standardsV1/StringUtils.cdc"

access(all)
contract GameBoardUtils{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun convertRelativePositionsToString(_ positions: [[Int]]): String{ 
		var res: [String] = []
		for p in positions{ 
			res.append(StringUtils.joinInts(p, ","))
		}
		return StringUtils.join(res, "|")
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun convertStringToRelativePositions(_ str: String): [[Int]]{ 
		var relativePositions: [[Int]] = []
		let positionsArr: [String] = StringUtils.split(str, "|")
		var index = 0
		for p in positionsArr{ 
			relativePositions.append([])
			let positions: [String] = StringUtils.split(p, ",")
			for pos in positions{ 
				relativePositions[index].append(Int.fromString(pos)!)
			}
			index = index + 1
		}
		return relativePositions
	}
}
