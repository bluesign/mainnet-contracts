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

	import Crypto

access(all)
contract Signature{ 
	access(account)
	fun verify(signature: [UInt8], signedData: [UInt8], account: &Account, keyIndex: Int): Bool{ 
		let key =
			account.keys.get(keyIndex: keyIndex)
			?? panic("Keys that cannot be referenced cannot be used")
		assert(!key.isRevoked, message: "Revoked keys cannot be used")
		let keyList = Crypto.KeyList()
		keyList.add(key.publicKey, hashAlgorithm: key.hashAlgorithm, weight: key.weight)
		let signatureSet: [Crypto.KeyListSignature] =
			[Crypto.KeyListSignature(keyIndex: 0, signature: signature)]
		return keyList.verify(signatureSet: signatureSet, signedData: signedData)
	}
}
