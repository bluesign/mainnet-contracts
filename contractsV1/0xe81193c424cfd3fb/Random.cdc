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
contract Random{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun generateWithNumberSeed(seed: Number, amount: UInt8): [UFix64]{ 
		let hash: [UInt8] = HashAlgorithm.SHA3_256.hash(seed.toBigEndianBytes())
		return Random.generateWithBytesSeed(seed: hash, amount: amount)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun generateWithBytesSeed(seed: [UInt8], amount: UInt8): [UFix64]{ 
		let randoms: [UFix64] = []
		var i: UInt8 = 0
		while i < amount{ 
			randoms.append(Random.generate(seed: seed))
			seed[0] = seed[0] == 255 ? 0 : seed[0] + 1
			i = i + 1
		}
		return randoms
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun generate(seed: [UInt8]): UFix64{ 
		let hash: [UInt8] = HashAlgorithm.KECCAK_256.hash(seed)
		var value: UInt64 = 0
		var i: Int = 0
		while i < hash.length{ 
			value = value + UInt64(hash[i])
			value = value << 8
			i = i + 1
		}
		value = value + UInt64(hash[0])
		return UFix64(value % 100_000) / 100_000.0
	}
}
