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
contract ConstantUpdate{ 
	access(all)
	event HardMaximum(value: UFix64)
	
	access(all)
	let hardMaximum: UFix64
	
	access(TMP_ENTITLEMENT_OWNER)
	fun doSomethingUnrelated(): Bool{ 
		return true
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun broadcastHardMaximum(){ 
		emit HardMaximum(value: self.hardMaximum)
	}
	
	init(){ 
		self.hardMaximum = 100.0
	}
}
