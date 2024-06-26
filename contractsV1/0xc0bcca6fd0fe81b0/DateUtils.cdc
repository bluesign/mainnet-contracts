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

	// Utils to get a date from a (block's) timestamp
access(all)
contract DateUtils{ 
	
	// only support dates after this one (to minimize computing time)
	access(all)
	let INITIAL_TIMESTAMP: UInt64
	
	access(all)
	let INITIAL_MONTH: Int
	
	access(all)
	let INITIAL_YEAR: Int
	
	// A simple Date object
	access(all)
	struct Date{ 
		access(all)
		let day: Int
		
		access(all)
		let month: Int
		
		access(all)
		let year: Int
		
		init(day: Int, month: Int, year: Int){ 
			self.day = day
			self.month = month
			self.year = year
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toTwoDigitString(_ num: Int): String{ 
			let raw = "0".concat(num.toString())
			let formattedNumber = raw.slice(from: raw.length - 2, upTo: raw.length)
			return formattedNumber
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toString(): String{ 
			return self.toTwoDigitString(self.day).concat("-").concat(
				self.toTwoDigitString(self.month).concat("-").concat(self.year.toString())
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun equals(_ other: Date): Bool{ 
			return self.day == other.day && self.month == other.month && self.year == other.year
		}
	}
	
	// Function to get today's date from the block's timestamp
	access(TMP_ENTITLEMENT_OWNER)
	fun getDate(): Date{ 
		let timestamp = UInt64(getCurrentBlock().timestamp)
		return self.getDateFromTimestamp(timestamp)
	}
	
	// Function to get a date a timestamp
	access(TMP_ENTITLEMENT_OWNER)
	fun getDateFromTimestamp(_ timestamp: UInt64): Date{ 
		let SECONDS_PER_DAY = 86400 as UInt64
		var days = Int((timestamp - self.INITIAL_TIMESTAMP) / SECONDS_PER_DAY)
		var year = self.INITIAL_YEAR
		while days >= self.daysForYear(year){ 
			days = days - self.daysForYear(year)
			year = year + 1
		}
		let daysPerMonth = self.daysPerMonth(year)
		var month = self.INITIAL_MONTH
		while days >= daysPerMonth[month]{ 
			days = days - daysPerMonth[month]
			month = month + 1
		}
		let day = days + 1
		return Date(day: day, month: month, year: year)
	}
	
	// Auxiliary functions
	access(self)
	fun isLeapYear(_ year: Int): Bool{ 
		return year % 400 == 0 || year % 4 == 0 && year % 100 != 0
	}
	
	access(self)
	fun daysForYear(_ year: Int): Int{ 
		return self.isLeapYear(year) ? 366 : 365
	}
	
	access(self)
	fun daysPerMonth(_ year: Int): [Int]{ 
		return [0, 31, self.isLeapYear(year) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	}
	
	init(){ 
		self.INITIAL_TIMESTAMP = 1609459200
		self.INITIAL_MONTH = 1
		self.INITIAL_YEAR = 2021
	}
}
