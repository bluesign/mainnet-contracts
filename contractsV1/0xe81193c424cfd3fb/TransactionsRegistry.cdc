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
Contract to register transactions that have been executed from admin accounts.

Old functionality is kept in this contract for backwards compatibility,
related to teleporter transactions from the Doodles Drop Ethereum contract.

New transactions should be registered using the generic methods.

A registry is composed from a name, arguments and a value.
The name identifies the type of transaction. For example "mint-doodle"
The arguments are unique identifiers for each transaction.
For example, the address of the receiver of the minted doodle.
The value is any variable that is related to the transaction.
For example, the name of the minted doodle.
*/

access(all)
contract TransactionsRegistry{ 
	access(all)
	event Register(name: String, args: [String], value: String)
	
	// Old event for backwards compatibility in teleporter
	access(all)
	event TransactionRegistered(key: String, transactionId: String)
	
	access(self)
	let registry:{ String: String}
	
	access(self)
	let extra:{ String: AnyStruct}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isRegistered(name: String, args: [String]): Bool{ 
		return self.getRegistryValue(name: name, args: args) != nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRegistryValue(name: String, args: [String]): String?{ 
		let key: String = self.getKey(name: name, args: args)
		return self.registry[key]
	}
	
	access(account)
	fun register(name: String, args: [String], value: String){ 
		let key: String = self.getKey(name: name, args: args)
		if self.registry[key] != nil{ 
			panic("Transaction already registered")
		}
		self.registry[key] = value
		emit Register(name: name, args: args, value: value)
	}
	
	access(self)
	fun getKey(name: String, args: [String]): String{ 
		var key: String = name
		for arg in args{ 
			key = key.concat("-").concat(arg)
		}
		return key
	}
	
	// Only for backwards compatibility. Use the generic methods for new transactions.
	// Teleporter from Ethereum Doodles Drops to Wearables Mint
	access(TMP_ENTITLEMENT_OWNER)
	fun getRegistryDoodlesDropsWearablesMint(packTypeId: UInt64, packId: UInt64): String?{ 
		return self.getRegistryValue(
			name: "doodles-drops-wearables-mint",
			args: [packTypeId.toString(), packId.toString()]
		)
	}
	
	access(account)
	fun registerDoodlesDropsWearablesMint(
		packTypeId: UInt64,
		packId: UInt64,
		transactionId: String
	){ 
		self.register(
			name: "doodles-drops-wearables-mint",
			args: [packTypeId.toString(), packId.toString()],
			value: transactionId
		)
	}
	
	// Teleporter from Ethereum Doodles Drops to Redeemables Mint
	access(TMP_ENTITLEMENT_OWNER)
	fun getRegistryDoodlesDropsRedeemablesMint(packTypeId: UInt64, packId: UInt64): String?{ 
		return self.getRegistryValue(
			name: "doodles-drops-redeemables-mint",
			args: [packTypeId.toString(), packId.toString()]
		)
	}
	
	access(account)
	fun registerDoodlesDropsRedeemablesMint(
		packTypeId: UInt64,
		packId: UInt64,
		transactionId: String
	){ 
		self.register(
			name: "doodles-drops-redeemables-mint",
			args: [packTypeId.toString(), packId.toString()],
			value: transactionId
		)
	}
	
	init(){ 
		self.registry ={} 
		self.extra ={} 
	}
}
