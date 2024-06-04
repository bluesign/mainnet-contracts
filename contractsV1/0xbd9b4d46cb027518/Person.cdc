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

	
// A simple Person contract 
// 
// reference: https://developers.flow.com/cadence/language/contracts
access(all)
contract Person{ 
	// declaration of a public variable
	access(all)
	var name: String
	
	// initialization method for our contracts, this gets run on deployment
	init(){ 
		self.name = "Bob"
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun sayHello(): String{ 
		return "Hello, my name is ".concat(self.name)
	}
	
	// create a new friendship resource 
	access(TMP_ENTITLEMENT_OWNER)
	fun makeFriends(): @Friendship{ 
		return <-create Friendship()
	}
	
	// Friendship resource are types of values that can only exist in one place 
	// 
	// read more about this unique and powerful Cadence feature here https://developers.flow.com/cadence/language/resources
	access(all)
	resource Friendship{ 
		init(){} 
		
		access(TMP_ENTITLEMENT_OWNER)
		fun yaay(){ 
			log("such a nice friend") // we can log to output, useful on emualtor for debugging
		
		}
	}
}
