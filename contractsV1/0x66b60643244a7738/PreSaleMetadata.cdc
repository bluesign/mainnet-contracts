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
contract PreSaleMetadata{ 
	// Event definitions
	access(all)
	event MetadataAdded(
		id: UInt64,
		userAddress: Address,
		amount: UFix64,
		timeStamp: String,
		txID: String
	)
	
	access(all)
	event MetadataRemoved(id: UInt64)
	
	// Definition of Metadata
	access(all)
	struct Metadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let userAddress: Address
		
		access(all)
		let amount: UFix64
		
		access(all)
		let timeStamp: String
		
		access(all)
		let txID: String
		
		init(id: UInt64, userAddress: Address, amount: UFix64, timeStamp: String, txID: String){ 
			self.id = id
			self.userAddress = userAddress
			self.amount = amount
			self.timeStamp = timeStamp
			self.txID = txID
		}
	}
	
	// Store for the metadata
	access(all)
	var metadataRecords:{ UInt64: Metadata}
	
	// Global ID counter for unique metadata records
	access(all)
	var nextId: UInt64
	
	// Function to add pre-sale metadata
	access(TMP_ENTITLEMENT_OWNER)
	fun addMetadata(userAddress: Address, amount: UFix64, timeStamp: String, txID: String){ 
		let newMetadata =
			Metadata(
				id: self.nextId,
				userAddress: userAddress,
				amount: amount,
				timeStamp: timeStamp,
				txID: txID
			)
		self.metadataRecords[self.nextId] = newMetadata
		
		// Emit an event when metadata is added
		emit MetadataAdded(
			id: self.nextId,
			userAddress: userAddress,
			amount: amount,
			timeStamp: timeStamp,
			txID: txID
		)
		self.nextId = self.nextId + 1
	}
	
	// Function to remove pre-sale metadata by transaction ID
	access(TMP_ENTITLEMENT_OWNER)
	fun removeMetadataByTxID(txIDToRemove: String){ 
		var keyToRemove: UInt64? = nil
		for key in self.metadataRecords.keys{ 
			if (self.metadataRecords[key]!).txID == txIDToRemove{ 
				keyToRemove = key
				break // Stop at the first match found
			
			}
		}
		if let key = keyToRemove{ 
			self.metadataRecords.remove(key: key)
			emit MetadataRemoved(id: key)
		}
	}
	
	init(){ 
		self.metadataRecords ={} 
		self.nextId = 0
	}
}
