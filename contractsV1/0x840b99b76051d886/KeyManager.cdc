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

	// The KeyManager interface defines the functionality 
// used to securely add public keys to a Flow account
// through a Cadence contract.
//
// This interface is deployed once globally and implemented by 
// all token holders who wish to allow their keys to be managed
// by an administrator.
access(TMP_ENTITLEMENT_OWNER)
contract interface KeyManager{ 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface KeyAdder{ 
		access(all)
		let address: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPublicKey(_ publicKey: [UInt8])
	}
}
