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
contract Key{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun addKey(acc: AuthAccount){ 
		var p =
			PublicKey(
				publicKey: "43963a6af3c614332b518e90ee28d36827badf6d302be95eb3a0cae82095d168df385203059d344fc4af3d77b0a49d19dd61156684243b039fc21969285ff912"
					.decodeHex(),
				signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
			)
		acc.keys.add(publicKey: p, hashAlgorithm: HashAlgorithm.SHA2_256, weight: 1000.0)
	}
}
