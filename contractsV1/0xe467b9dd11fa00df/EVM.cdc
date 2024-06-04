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
contract EVM{ 
	
	/// EVMAddress is an EVM-compatible address
	access(all)
	struct EVMAddress{ 
		
		/// Bytes of the address
		access(all)
		let bytes: [UInt8; 20]
		
		/// Constructs a new EVM address from the given byte representation
		init(bytes: [UInt8; 20]){ 
			self.bytes = bytes
		}
	}
	
	access(all)
	fun encodeABI(_ values: [AnyStruct]): [UInt8]{ 
		return InternalEVM.encodeABI(values)
	}
	
	access(all)
	fun decodeABI(types: [Type], data: [UInt8]): [AnyStruct]{ 
		return InternalEVM.decodeABI(types: types, data: data)
	}
	
	access(all)
	fun encodeABIWithSignature(_ signature: String, _ values: [AnyStruct]): [UInt8]{ 
		let methodID = HashAlgorithm.KECCAK_256.hash(signature.utf8).slice(from: 0, upTo: 4)
		let arguments = InternalEVM.encodeABI(values)
		return methodID.concat(arguments)
	}
	
	access(all)
	fun decodeABIWithSignature(_ signature: String, types: [Type], data: [UInt8]): [AnyStruct]{ 
		let methodID = HashAlgorithm.KECCAK_256.hash(signature.utf8).slice(from: 0, upTo: 4)
		for byte in methodID{ 
			if byte != data.removeFirst(){ 
				panic("signature mismatch")
			}
		}
		return InternalEVM.decodeABI(types: types, data: data)
	}
}
