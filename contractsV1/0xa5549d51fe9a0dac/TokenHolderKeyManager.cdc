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

	import KeyManager from "../0x840b99b76051d886/KeyManager.cdc"

// The TokenHolderKeyManager contract is an implementation of
// the KeyManager interface intended for use by FLOW token holders.
//
// One instance is deployed to each token holder account.
// Deployment is executed a with signature from the administrator,
// allowing them to take possession of a KeyAdder resource
// upon initialization.
access(all)
contract TokenHolderKeyManager: KeyManager{ 
	access(contract)
	fun addPublicKey(_ publicKey: [UInt8]){ 
		self.account.addPublicKey(publicKey)
	}
	
	access(all)
	resource KeyAdder: KeyManager.KeyAdder{ 
		access(all)
		let address: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPublicKey(_ publicKey: [UInt8]){ 
			TokenHolderKeyManager.addPublicKey(publicKey)
		}
		
		init(address: Address){ 
			self.address = address
		}
	}
	
	init(admin: AuthAccount, path: Path){ 
		let keyAdder <- create KeyAdder(address: self.account.address)
		admin.save(<-keyAdder, to: path)
	}
}
