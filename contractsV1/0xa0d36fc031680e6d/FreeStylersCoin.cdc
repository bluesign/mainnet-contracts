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
contract FreeStylersCoin{ 
	access(self)
	var totalSupply: UFix64
	
	access(all)
	var name: String
	
	access(all)
	var symbol: String
	
	access(all)
	resource Token{ 
		access(all)
		let value: UFix64
		
		init(value: UFix64){ 
			self.value = value
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createInitialTokens(amount: UFix64): @Token{ 
		let newToken <- create Token(value: amount)
		self.totalSupply = self.totalSupply + amount
		return <-newToken
	}
	
	init(){ 
		self.totalSupply = 0.0
		self.name = "FreeStylers Coin"
		self.symbol = "FSC"
		// Creating initial tokens
		self.totalSupply = 50000000.0
	// Consider decimal places for the token if necessary
	}
}
