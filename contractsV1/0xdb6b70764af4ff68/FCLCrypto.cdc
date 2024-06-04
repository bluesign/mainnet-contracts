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
contract FCLCrypto{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun verifyUserSignatures(
		address: Address,
		message: String,
		keyIndices: [
			Int
		],
		signatures: [
			String
		]
	): Bool{ 
		return self.verifySignatures(
			address: address,
			message: message,
			keyIndices: keyIndices,
			signatures: signatures,
			domainSeparationTag: self.domainSeparationTagFlowUser
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun verifyAccountProofSignatures(
		address: Address,
		message: String,
		keyIndices: [
			Int
		],
		signatures: [
			String
		]
	): Bool{ 
		return self.verifySignatures(
			address: address,
			message: message,
			keyIndices: keyIndices,
			signatures: signatures,
			domainSeparationTag: self.domainSeparationTagAccountProof
		)
		|| self.verifySignatures(
			address: address,
			message: message,
			keyIndices: keyIndices,
			signatures: signatures,
			domainSeparationTag: self.domainSeparationTagFlowUser
		)
	}
	
	access(self)
	fun verifySignatures(
		address: Address,
		message: String,
		keyIndices: [
			Int
		],
		signatures: [
			String
		],
		domainSeparationTag: String
	): Bool{ 
		pre{ 
			keyIndices.length == signatures.length:
				"Key index list length does not match signature list length"
		}
		let account = getAccount(address)
		let messageBytes = message.decodeHex()
		var totalWeight: UFix64 = 0.0
		let seenKeyIndices:{ Int: Bool} ={} 
		var i = 0
		for keyIndex in keyIndices{ 
			let accountKey = account.keys.get(keyIndex: keyIndex) ?? panic("Key provided does not exist on account")
			let signature = signatures[i].decodeHex()
			
			// Ensure this key index has not already been seen
			if seenKeyIndices[accountKey.keyIndex] ?? false{ 
				return false
			}
			
			// Record the key index was seen
			seenKeyIndices[accountKey.keyIndex] = true
			
			// Ensure the key is not revoked
			if accountKey.isRevoked{ 
				return false
			}
			
			// Ensure the signature is valid
			if !accountKey.publicKey.verify(signature: signature, signedData: messageBytes, domainSeparationTag: domainSeparationTag, hashAlgorithm: accountKey.hashAlgorithm){ 
				return false
			}
			totalWeight = totalWeight + accountKey.weight
			i = i + 1
		}
		
		// Non-custodial users can only generate a weight of 999
		return totalWeight >= 999.0
	}
	
	access(self)
	let domainSeparationTagFlowUser: String
	
	access(self)
	let domainSeparationTagFCLUser: String
	
	access(self)
	let domainSeparationTagAccountProof: String
	
	init(){ 
		self.domainSeparationTagFlowUser = "FLOW-V0.0-user"
		self.domainSeparationTagFCLUser = "FCL-USER-V0.0"
		self.domainSeparationTagAccountProof = "FCL-ACCOUNT-PROOF-V0.0"
	}
}
