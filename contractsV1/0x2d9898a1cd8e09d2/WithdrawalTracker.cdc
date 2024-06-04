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
contract WithdrawalTracker{ 
	access(all)
	event WithdrawalTotalTrackerCreated(withdrawalLimit: UFix64, runningTotal: UFix64)
	
	access(all)
	event WithdrawalLimitSet(oldLimit: UFix64, newLimit: UFix64, runningTotal: UFix64)
	
	access(all)
	event RunningTotalUpdated(amount: UFix64, runningTotal: UFix64, withdrawalLimit: UFix64)
	
	// So the total can be checked publicly via a Capability
	access(all)
	resource interface WithdrawalTotalChecker{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentRunningTotal(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentWithdrawalLimit(): UFix64
	}
	
	// For admins, if needed
	access(all)
	resource interface SetWithdrawalLimit{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setWithdrawalLimit(withdrawalLimit: UFix64): Void
	}
	
	// Anyone can create one.
	// Place it in your storage, expose CheckRunningTotal in /public/,
	// and if you need to you can pass a Capability to SetWithdrawalLimit to an admin,
	// but really you should just update it yourself.
	access(all)
	resource WithdrawalTotalTracker: WithdrawalTotalChecker, SetWithdrawalLimit{ 
		access(self)
		var withdrawalLimit: UFix64
		
		access(self)
		var runningTotal: UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentRunningTotal(): UFix64{ 
			return self.runningTotal
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCurrentWithdrawalLimit(): UFix64{ 
			return self.withdrawalLimit
		}
		
		// The user can call this if they wish to avoid an exception from updateRunningTotal
		access(TMP_ENTITLEMENT_OWNER)
		view fun wouldExceedLimit(withdrawalAmount: UFix64): Bool{ 
			return self.runningTotal + withdrawalAmount > self.withdrawalLimit
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateRunningTotal(withdrawalAmount: UFix64){ 
			pre{ 
				!self.wouldExceedLimit(withdrawalAmount: withdrawalAmount):
					"Withdrawal would cause total to exceed withdrawalLimit"
			}
			self.runningTotal = self.runningTotal + withdrawalAmount
			emit RunningTotalUpdated(amount: withdrawalAmount, runningTotal: self.runningTotal, withdrawalLimit: self.withdrawalLimit)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setWithdrawalLimit(withdrawalLimit: UFix64){ 
			emit WithdrawalLimitSet(oldLimit: self.withdrawalLimit, newLimit: withdrawalLimit, runningTotal: self.runningTotal)
			self.withdrawalLimit = withdrawalLimit
		}
		
		init(initialLimit: UFix64, initialRunningTotal: UFix64){ 
			self.withdrawalLimit = initialLimit
			self.runningTotal = initialRunningTotal
			emit WithdrawalTotalTrackerCreated(withdrawalLimit: self.withdrawalLimit, runningTotal: self.runningTotal)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createWithdrawalTotalTracker(
		initialLimit: UFix64,
		initialRunningTotal: UFix64
	): @WithdrawalTotalTracker{ 
		return <-create WithdrawalTotalTracker(
			initialLimit: initialLimit,
			initialRunningTotal: initialRunningTotal
		)
	}
}
