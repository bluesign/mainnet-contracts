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
contract TokenTransferEventContract{ 
	// Define an event that takes the amount of tokens transferred as an argument
	access(all)
	event TokensTransferred(amount: UFix64, address: Address)
	
	access(all)
	event BasicTourCompleted(address: Address)
	
	access(all)
	event BasicTourIncomplete(value: UInt64, address: Address)
	
	// Define a public function to emit the event, which can be called by a transaction
	// This event will trigger a backend command to send TIT Tokens based on the Flow value transferred
	access(TMP_ENTITLEMENT_OWNER)
	fun emitTokensTransferred(amount: UFix64, address: Address){ 
		emit TokensTransferred(amount: amount, address: address)
	}
	
	// When this event is triggered, someone has completed the basic Tour of TIT palace and needs to receive their winnings.
	access(TMP_ENTITLEMENT_OWNER)
	fun emitBasicTourCompleted(address: Address){ 
		emit BasicTourCompleted(address: address)
	}
	
	//If they don't complete the tour, let's see how far that got with the value variable and also capture their address
	access(TMP_ENTITLEMENT_OWNER)
	fun emitBasicTourIncomplete(value: UInt64, address: Address){ 
		emit BasicTourIncomplete(value: value, address: address)
	}
}
