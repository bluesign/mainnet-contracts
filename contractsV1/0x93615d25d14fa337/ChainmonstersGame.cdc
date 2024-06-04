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
contract ChainmonstersGame{ 
	/**
	   * Contract events
	   */
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event GameEvent(eventID: UInt32, playerID: String?)
	
	// Event that fakes withdraw event for correct user aggregation
	access(all)
	event TokensWithdrawn(amount: UFix64, from: Address?)
	
	// Event that fakes deposited event for correct user aggregation
	access(all)
	event TokensDeposited(amount: UFix64, to: Address?)
	
	/**
	   * Contract-level fields
	   */
	
	/**
	   * Structs
	   */
	
	// Whoever owns an admin resource can emit game events and create new admin resources
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun emitGameEvent(eventID: UInt32, playerID: String?, playerAccount: Address){ 
			emit GameEvent(eventID: eventID, playerID: playerID)
			emit TokensWithdrawn(amount: 1.0, from: playerAccount)
			emit TokensDeposited(amount: 1.0, to: 0x93615d25d14fa337)
		}
		
		// createNewAdmin creates a new Admin resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	/**
	   * Contract-level functions
	   */
	
	init(){ 
		self.account.storage.save<@Admin>(<-create Admin(), to: /storage/chainmonstersGameAdmin)
		emit ContractInitialized()
	}
}
