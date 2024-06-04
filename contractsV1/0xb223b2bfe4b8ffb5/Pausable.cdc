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

	import ContractVersion from "./ContractVersion.cdc"

access(all)
contract Pausable: ContractVersion{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun getVersion(): String{ 
		return "1.1.5"
	}
	
	access(all)
	event Paused(account: Address)
	
	access(all)
	event Unpaused(account: Address)
	
	access(all)
	resource interface PausableExternal{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun isPaused(): Bool
	}
	
	access(all)
	resource interface PausableInternal{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun pause(): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unPause()
	}
	
	access(all)
	resource PausableResource: PausableInternal, PausableExternal{ 
		access(self)
		var paused: Bool
		
		init(paused: Bool){ 
			self.paused = paused
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isPaused(): Bool{ 
			return self.paused
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun pause(){ 
			pre{ 
				self.paused == false:
					"Invalid: The resource is paused already"
			}
			self.paused = true
			emit Paused(account: (self.owner!).address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unPause(){ 
			pre{ 
				self.paused == true:
					"Invalid: The resource is not paused"
			}
			self.paused = false
			emit Unpaused(account: (self.owner!).address)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createResource(paused: Bool): @PausableResource{ 
		return <-create PausableResource(paused: paused)
	}
	
	init(){} 
}
