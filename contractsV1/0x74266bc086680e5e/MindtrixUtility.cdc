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

	/* 
A hepler contract to deal with annoying but commonly used functionality.
All should be a pure function that has no dependency.
*/

access(all)
contract MindtrixUtility{ 
	//========================================================
	// Metadata
	//========================================================
	access(account)
	fun generateMetadataHash(strMetadata:{ String: String}): [UInt8]{ 
		var metadataString = "{"
		// The field order matters. It affects the hash result.
		var attributes: [String] =
			["Background", "Body", "Color", "Face", "Gloves", "Headgear", "Offhand", "Serial No"]
		metadataString = metadataString.concat("\"attributes\":[")
		let traitKeyPrefix = "trait_"
		// Serial No is an optional trait
		let serialNumberTraitKey = traitKeyPrefix.concat("Serial No".toLower())
		let isContainsSerialNoTrait = strMetadata.containsKey(serialNumberTraitKey)
		for i, t in attributes{ 
			let v = strMetadata[traitKeyPrefix.concat(t.toLower())] ?? nil
			if v == nil{ 
				continue
			}
			let isEnd = i == attributes.length - 1 || i == attributes.length - 2 && !isContainsSerialNoTrait
			metadataString = metadataString.concat("{").concat(MindtrixUtility.concatJsonKeyValue(k: "trait_type", v: t, isEnd: false))
			metadataString = metadataString.concat(MindtrixUtility.concatJsonKeyValue(k: "value", v: v!, isEnd: true)).concat("}").concat(isEnd ? "" : ",")
		}
		metadataString = metadataString.concat("]}")
		return HashAlgorithm.SHA3_256.hash(metadataString.utf8)
	}
	
	//========================================================
	// String 
	//========================================================
	access(TMP_ENTITLEMENT_OWNER)
	fun isAlphabet(_ singleUTF8: UInt8): Bool{ 
		let isLowerCase = singleUTF8 >= 97 && singleUTF8 <= 122
		let isUpperCase = singleUTF8 >= 65 && singleUTF8 <= 90
		return isLowerCase || isUpperCase
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun toUpperCase(_ lowerCase: String): String{ 
		var upperCase = ""
		for c in lowerCase{ 
			let uft8 = c.toString().utf8[0]
			let isLowerCase = uft8 >= 97 && uft8 <= 122
			upperCase = upperCase.concat(String.fromUTF8([isLowerCase ? uft8 - 32 : uft8]) ?? c.toString())
		}
		return upperCase
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun toLowerCase(_ upperCase: String): String{ 
		var lowerCase = ""
		for c in upperCase{ 
			let uft8 = c.toString().utf8[0]
			let isUpperCase = uft8 >= 65 && uft8 <= 90
			lowerCase = lowerCase.concat(String.fromUTF8([isUpperCase ? uft8 + 32 : uft8]) ?? c.toString())
		}
		return lowerCase
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun upperCaseFirstChar(_ str: String): String{ 
		return self.toUpperCase(str.slice(from: 0, upTo: 1)).concat(
			str.slice(from: 1, upTo: str.length)
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun concatJsonKeyValue(k: String, v: String, isEnd: Bool): String{ 
		return "\"".concat(k).concat("\":\"").concat(v).concat("\"").concat(isEnd ? "" : ",")
	}
}
