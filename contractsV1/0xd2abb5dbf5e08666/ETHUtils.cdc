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

	/**
> Reference: https://github.com/onflow/flow-cadence-eth-utils

# ETHUtils

*/

access(all)
contract ETHUtils{ 
	/// Verify a EVM signature from a message using a public key
	///
	access(all)
	fun verifySignature(hexPublicKey: String, hexSignature: String, message: String): Bool{ 
		let decodedHexPublicKey = hexPublicKey.decodeHex()
		let decodedHexSignature = hexSignature.decodeHex()
		let ethereumMessagePrefix: String =
			"\u{19}Ethereum Signed Message:\n".concat(message.length.toString())
		let fullMessage: String = ethereumMessagePrefix.concat(message)
		let publicKey =
			PublicKey(
				publicKey: decodedHexPublicKey,
				signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1
			)
		let isValid =
			publicKey.verify(
				signature: decodedHexSignature,
				signedData: fullMessage.utf8,
				domainSeparationTag: "",
				hashAlgorithm: HashAlgorithm.KECCAK_256
			)
		return isValid
	}
	
	/// Get the EVM address from a public key
	///
	access(all)
	fun getETHAddressFromPublicKey(hexPublicKey: String): String{ 
		let decodedHexPublicKey = hexPublicKey.decodeHex()
		let digest = HashAlgorithm.KECCAK_256.hash(decodedHexPublicKey)
		let hexDigest = String.encodeHex(digest)
		let ethAddress =
			"0x".concat(hexDigest.slice(from: hexDigest.length - 40, upTo: hexDigest.length))
		return ethAddress.toLower()
	}
}
