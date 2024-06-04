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
contract Heartbeat{ 
	access(all)
	event heartbeat(pulseUUID: UInt64, message: String, ts_begin: Int64)
	
	access(all)
	let greeting: String
	
	access(all)
	resource Pulse{ 
		access(all)
		var ts_begin: Int64
		
		access(all)
		var message: String
		
		init(ts_begin: Int64, message: String){ 
			self.ts_begin = ts_begin
			self.message = message
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun generatePulse(ts_begin: Int64, message: String){ 
		let newPulse <- create Pulse(ts_begin: ts_begin, message: message)
		emit heartbeat(
			pulseUUID: newPulse.uuid,
			message: newPulse.message,
			ts_begin: newPulse.ts_begin
		)
		destroy newPulse
	}
	
	init(){ 
		self
			.greeting = "\u{1f44b}Greetings from Graffle.io!\u{1f469}\u{200d}\u{1f680}\u{1f680}\u{1f468}\u{200d}\u{1f680}"
	}
}
