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
contract HelloWorld{ 
	access(all)
	var greeting: String
	
	// The init() function is required if the contract contains any fields.
	init(){ 
		self.greeting = "Hello, World NFTPL!"
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun changeGreeting(newGreeting: String){ 
		self.greeting = newGreeting
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun show(): String{ 
		return self.greeting
	}
}
