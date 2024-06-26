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
contract FindUtils{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun deDupTypeArray(_ arr: [Type]): [Type]{ 
		let removeElement = fun (_ arr: [Type], _ element: Type): [Type]{ 
				var i = arr.firstIndex(of: element)
				let firstIndex = i
				while i != nil{ 
					arr.remove(at: i!)
					i = arr.firstIndex(of: element)
				}
				if firstIndex != nil{ 
					arr.insert(at: firstIndex!, element)
				}
				return arr
			}
		var arr = arr
		var c = 0
		while c < arr.length - 1{ 
			arr = removeElement(arr, arr[c])
			c = c + 1
		}
		return arr
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun joinString(_ arr: [String], sep: String): String{ 
		var message = ""
		for i, key in arr{ 
			if i > 0{ 
				message = message.concat(sep)
			}
			message = message.concat(key)
		}
		return message
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun joinMapToString(_ map:{ String: String}): String{ 
		var message = ""
		for i, key in map.keys{ 
			if i > 0{ 
				message = message.concat(" ")
			}
			message = message.concat(key.concat("=").concat(map[key]!))
		}
		return message
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun containsChar(_ string: String, char: Character): Bool{ 
		if var index = string.utf8.firstIndex(of: char.toString().utf8[0]){ 
			return true
		}
		return false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun contains(_ string: String, element: String): Bool{ 
		if element.length == 0{ 
			return true
		}
		if var index = string.utf8.firstIndex(of: element.utf8[0]){ 
			while index <= string.length - element.length{ 
				if string[index] == element[0] && string.slice(from: index, upTo: index + element.length) == element{ 
					return true
				}
				index = index + 1
			}
		}
		return false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun trimSuffix(_ name: String, suffix: String): String{ 
		if !self.hasSuffix(name, suffix: suffix){ 
			return name
		}
		let pos = name.length - suffix.length
		return name.slice(from: 0, upTo: pos)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasSuffix(_ string: String, suffix: String): Bool{ 
		if suffix.length > string.length{ 
			return false
		}
		return string.slice(from: string.length - suffix.length, upTo: string.length) == suffix
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasPrefix(_ string: String, prefix: String): Bool{ 
		if prefix.length > string.length{ 
			return false
		}
		return string.slice(from: 0, upTo: prefix.length) == prefix
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun splitString(_ string: String, sep: Character): [String]{ 
		if var index = string.utf8.firstIndex(of: sep.toString().utf8[0]){ 
			let first = string.slice(from: 0, upTo: index)
			let second = string.slice(from: index + 1, upTo: string.length)
			let res = [first]
			res.appendAll(self.splitString(second, sep: sep))
			return res
		}
		return [string]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun toUpper(_ string: String): String{ 
		let map = FindUtils.getLowerCaseToUpperCase()
		var res = ""
		var i = 0
		while i < string.length{ 
			let c = map[string[i].toString()] ?? string[i].toString()
			res = res.concat(c)
			i = i + 1
		}
		return res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun firstUpperLetter(_ string: String): String{ 
		if string.length < 1{ 
			return string
		}
		let map = FindUtils.getLowerCaseToUpperCase()
		if let first = map[string[0].toString()]{ 
			return first.concat(string.slice(from: 1, upTo: string.length))
		}
		return string
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun to_snake_case(_ string: String): String{ 
		var res = ""
		var i = 0
		let map = FindUtils.getUpperCaseToLowerCase()
		var spaced = false
		while i < string.length{ 
			if string[i] == " "{ 
				res = res.concat("_")
				spaced = true
				i = i + 1
				continue
			}
			if let lowerCase = map[string[i].toString()]{ 
				if i > 0 && !spaced{ 
					res = res.concat("_")
				}
				res = res.concat(lowerCase)
				i = i + 1
				spaced == false
				continue
			}
			res = res.concat(string[i].toString())
			i = i + 1
		}
		return res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun toCamelCase(_ string: String): String{ 
		var res = ""
		var i = 0
		let map = FindUtils.getLowerCaseToUpperCase()
		var upper = false
		let string = string.toLower()
		while i < string.length{ 
			if string[i] == " " || string[i] == "_"{ 
				upper = true
				i = i + 1
				continue
			}
			if upper{ 
				if let upperCase = map[string[i].toString()]{ 
					res = res.concat(upperCase)
					upper = false
					i = i + 1
					continue
				}
			}
			res = res.concat(string[i].toString())
			i = i + 1
		}
		return res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getLowerCaseToUpperCase():{ String: String}{ 
		return{ 
			"a": "A",
			"b": "B",
			"c": "C",
			"d": "D",
			"e": "E",
			"f": "F",
			"g": "G",
			"h": "H",
			"i": "I",
			"j": "J",
			"k": "K",
			"l": "L",
			"m": "M",
			"n": "N",
			"o": "O",
			"p": "P",
			"q": "Q",
			"r": "R",
			"s": "S",
			"t": "T",
			"u": "U",
			"v": "V",
			"w": "W",
			"x": "X",
			"y": "Y",
			"z": "Z"
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getUpperCaseToLowerCase():{ String: String}{ 
		return{ 
			"A": "a",
			"B": "b",
			"C": "c",
			"D": "d",
			"E": "e",
			"F": "f",
			"G": "g",
			"H": "h",
			"I": "i",
			"J": "j",
			"K": "k",
			"L": "l",
			"M": "m",
			"N": "n",
			"O": "o",
			"P": "p",
			"Q": "q",
			"R": "r",
			"S": "s",
			"T": "t",
			"U": "u",
			"V": "v",
			"W": "w",
			"X": "x",
			"Y": "y",
			"Z": "z"
		}
	}
}
