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

	import MoxyData from "./MoxyData.cdc"

access(all)
contract LinearRelease{ 
	access(all)
	struct LinearSchedule{ 
		access(all)
		var tgeDate: UFix64
		
		access(all)
		var totalAmount: UFix64
		
		access(all)
		var initialAmount: UFix64
		
		access(all)
		let unlockDate: UFix64
		
		access(all)
		var unlockAmount: UFix64
		
		access(all)
		let days: Int
		
		access(all)
		var dailyAmount: UFix64
		
		access(all)
		var lastReleaseDate: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setStartDate(timestamp: UFix64){ 
			self.tgeDate = timestamp
			self.lastReleaseDate = timestamp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateLastReleaseDate(){ 
			self.setLastReleaseDate(timestamp: getCurrentBlock().timestamp)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setLastReleaseDate(timestamp: UFix64){ 
			self.lastReleaseDate = timestamp
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun splitWith(amount: UFix64): LinearSchedule{ 
			pre{ 
				amount <= self.totalAmount:
					"Not enough amount to split linear release"
				self.totalAmount > 0.0:
					"Total amount should be greater than zero"
			}
			var initialAmount = self.getAmountAtTGEToPay()
			if initialAmount > 0.0{ 
				initialAmount = self.initialAmount / self.totalAmount * amount
			}
			var unlockAmount = self.getAmountAfterUnlockToPay()
			if unlockAmount > 0.0{ 
				unlockAmount = self.unlockAmount / self.totalAmount * amount
			}
			let totalToRelease = amount - (initialAmount + unlockAmount)
			let days = Int(self.getDaysRemainingToEnd())
			if days == 0{ 
				panic("Days is zero")
			}
			let dailyAmount = totalToRelease / UFix64(days)
			let newLinearRelease =
				LinearRelease.createLinearSchedule(
					tgeDate: self.tgeDate,
					totalAmount: amount,
					initialAmount: initialAmount,
					unlockDate: self.unlockDate,
					unlockAmount: unlockAmount,
					days: self.days,
					dailyAmount: dailyAmount
				)
			newLinearRelease.setLastReleaseDate(timestamp: self.lastReleaseDate)
			
			// Update current schedule
			self.initialAmount = self.initialAmount - initialAmount
			self.unlockAmount = self.unlockAmount - unlockAmount
			self.totalAmount = self.totalAmount - amount
			self.dailyAmount = self.dailyAmount - dailyAmount
			return newLinearRelease
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTotalToUnlock(): UFix64{ 
			var total = 0.0
			total = total + self.getAmountAtTGEToPay()
			total = total + self.getAmountAfterUnlockToPay()
			total = total + self.getDailyAmountToPay()
			return total
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDaysRemaining(): UFix64{ 
			/* 
							Returns the remaining days to pay depending the last release paid
						 */
			
			let today0000 = MoxyData.getTimestampTo0000(timestamp: getCurrentBlock().timestamp)
			var last0000 = 0.0
			if self.lastReleaseDate < self.unlockDate{ 
				last0000 = MoxyData.getTimestampTo0000(timestamp: self.unlockDate)
			} else{ 
				last0000 = MoxyData.getTimestampTo0000(timestamp: self.lastReleaseDate)
			}
			if Fix64(today0000) - Fix64(last0000) < 0.0{ 
				// Unlock date is not reached yet
				return 0.0
			}
			if last0000 >= MoxyData.getTimestampTo0000(timestamp: self.getEndDate()){ 
				// Finish date reached
				return 0.0
			}
			return (today0000 - last0000) / 86400.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDaysRemainingToEnd(): UFix64{ 
			/* 
							Returns the remaining days to pay depending the last release paid
						 */
			
			let end0000 = MoxyData.getTimestampTo0000(timestamp: self.getEndDate())
			var last0000 = 0.0
			if self.lastReleaseDate < self.unlockDate{ 
				last0000 = MoxyData.getTimestampTo0000(timestamp: self.unlockDate)
			} else{ 
				last0000 = MoxyData.getTimestampTo0000(timestamp: self.lastReleaseDate)
			}
			if last0000 >= end0000{ 
				// Finish date reached
				return 0.0
			}
			return (end0000 - last0000) / 86400.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEndDate(): UFix64{ 
			// Days starts from unlock date
			return self.unlockDate + UFix64(self.days * 86400)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountAtTGEToPay(): UFix64{ 
			if self.lastReleaseDate <= self.tgeDate{ 
				return self.initialAmount
			}
			// Returns zero if amount is already paid
			return 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountAtTGE(): UFix64{ 
			return self.initialAmount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountAfterUnlockToPay(): UFix64{ 
			if MoxyData.getTimestampTo0000(timestamp: self.lastReleaseDate)
			== MoxyData.getTimestampTo0000(timestamp: self.unlockDate){ 
				return self.unlockAmount
			}
			// Returns zero if amount is already paid
			return 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountAfterUnlock(): UFix64{ 
			return self.unlockAmount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDailyAmountToPay(): UFix64{ 
			// First is checked that the locked time has passed
			if getCurrentBlock().timestamp < self.unlockDate{ 
				return 0.0
			}
			let days = self.getDaysRemaining()
			return self.dailyAmount * days
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDailyAmount(): UFix64{ 
			return self.dailyAmount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTotalDailyAmount(): UFix64{ 
			return self.totalAmount - (self.initialAmount + self.unlockAmount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun printInfo(){ 
			log("************************************************")
			log("self.totalAmount")
			log(self.totalAmount)
			log("self.initialAmount")
			log(self.initialAmount)
			log("self.unlockDate")
			log(self.unlockDate)
			log("self.unlockAmount")
			log(self.unlockAmount)
			log("self.days")
			log(self.days)
			log("self.dailyAmount")
			log(self.dailyAmount)
			log("************************************************")
		}
		
		init(
			tgeDate: UFix64,
			totalAmount: UFix64,
			initialAmount: UFix64,
			unlockDate: UFix64,
			unlockAmount: UFix64,
			days: Int,
			dailyAmount: UFix64
		){ 
			self.tgeDate = tgeDate
			self.totalAmount = totalAmount
			self.initialAmount = initialAmount
			self.unlockDate = unlockDate
			self.unlockAmount = unlockAmount
			self.days = days
			self.dailyAmount = dailyAmount
			self.lastReleaseDate = tgeDate
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createLinearSchedule(
		tgeDate: UFix64,
		totalAmount: UFix64,
		initialAmount: UFix64,
		unlockDate: UFix64,
		unlockAmount: UFix64,
		days: Int,
		dailyAmount: UFix64
	): LinearSchedule{ 
		return LinearSchedule(
			tgeDate: tgeDate,
			totalAmount: totalAmount,
			initialAmount: initialAmount,
			unlockDate: unlockDate,
			unlockAmount: unlockAmount,
			days: days,
			dailyAmount: dailyAmount
		)
	}
}
