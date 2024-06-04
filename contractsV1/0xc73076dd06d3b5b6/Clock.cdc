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

	// forked from bjartek's Clock.cdc: https://github.com/findonflow/find/blob/main/contracts/Clock.cdc
access(all)
contract Clock{ 
	access(contract)
	var mockClock: UFix64
	
	access(contract)
	var enabled: Bool
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event MockTimeEnabled()
	
	access(all)
	event MockTimeDisabled()
	
	access(all)
	event MockTimeAdvanced(amount: UFix64)
	
	access(all)
	let ClockManagerStoragePath: StoragePath
	
	access(all)
	resource ClockManager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun turnMockTimeOn(){ 
			pre{ 
				Clock.enabled == false:
					"mock time is already ON"
			}
			Clock.enabled = true
			emit MockTimeEnabled()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun turnMockTimeOff(){ 
			pre{ 
				Clock.enabled == true:
					"mock time is already OFF"
			}
			Clock.enabled = false
			emit MockTimeDisabled()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun advanceClock(_ duration: UFix64){ 
			pre{ 
				Clock.enabled == true:
					"mock time keeping is not enabled"
			}
			Clock.mockClock = Clock.mockClock + duration
			emit MockTimeAdvanced(amount: duration)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getTime(): UFix64{ 
		if self.enabled{ 
			return self.mockClock
		}
		return getCurrentBlock().timestamp
	}
	
	init(){ 
		self.mockClock = 0.0
		self.enabled = false
		self.ClockManagerStoragePath = /storage/kissoClockManager
		let clockManager <- create ClockManager()
		self.account.storage.save(<-clockManager, to: self.ClockManagerStoragePath)
		emit ContractInitialized()
	}
}
