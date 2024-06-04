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
contract AACommon{ 
	access(all)
	struct PaymentCut{ 
		// typicaly they are Storage, Insurance, Contractor
		access(all)
		let type: String
		
		access(all)
		let recipient: Address
		
		access(all)
		let rate: UFix64
		
		init(type: String, recipient: Address, rate: UFix64){ 
			assert(rate >= 0.0 && rate <= 1.0, message: "Rate should be other than 0")
			self.type = type
			self.recipient = recipient
			self.rate = rate
		}
	}
	
	access(all)
	struct Payment{ 
		// typicaly they are Storage, Insurance, Contractor
		access(all)
		let type: String
		
		access(all)
		let recipient: Address
		
		access(all)
		let rate: UFix64
		
		access(all)
		let amount: UFix64
		
		init(type: String, recipient: Address, rate: UFix64, amount: UFix64){ 
			self.type = type
			self.recipient = recipient
			self.rate = rate
			self.amount = amount
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun itemIdentifier(type: Type, id: UInt64): String{ 
		return type.identifier.concat("-").concat(id.toString())
	}
}
