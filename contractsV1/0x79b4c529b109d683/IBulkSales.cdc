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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

/// IBulkSales
/// Contract interface for BulkListing and BulkPurchasing contracts that defines common values and interfaces
access(all)
contract interface IBulkSales{ 
	
	/// AdminStoragePath
	/// Storage path for contract admin object
	access(all)
	AdminStoragePath: StoragePath
	
	/// CommissionAdminPrivatePath
	/// Private path for commission admin capability
	access(all)
	CommissionAdminPrivatePath: PrivatePath
	
	/// CommissionReaderPublicPath
	/// Public path for commission reader capability
	access(all)
	CommissionReaderPublicPath: PublicPath
	
	/// CommissionReaderCapability
	/// Stored capability for commission reader
	access(all)
	CommissionReaderCapability: Capability<&{ICommissionReader}>
	
	/// Readable
	/// Interface that provides a human-readable output of the struct's data
	access(all)
	struct interface IReadable{ 
		access(all)
		view fun getReadable():{ String: AnyStruct}
	}
	
	access(all)
	struct interface IRoyalty{ 
		access(all)
		receiverAddress: Address
		
		access(all)
		rate: UFix64
	}
	
	/// Royalty
	/// An object representing a single royalty cut for a given listing
	access(all)
	struct interface Royalty: IRoyalty, IReadable{ 
		init(receiverAddress: Address, rate: UFix64){ 
			pre{ 
				rate > 0.0 && rate < 1.0:
					"rate must be between 0 and 1"
			}
		}
	}
	
	/// CommissionAdmin
	/// Private capability to manage commission receivers
	access(all)
	resource interface ICommissionAdmin{ 
		access(all)
		fun addCommissionReceiver(_ receiver: Capability<&{FungibleToken.Receiver}>)
		
		access(all)
		fun removeCommissionReceiver(receiverTypeIdentifier: String)
	}
	
	/// CommissionReader
	/// Public capability to get a commission receiver
	access(all)
	resource interface ICommissionReader{ 
		access(all)
		view fun getCommissionReceiver(_ identifier: String): Capability<&{FungibleToken.Receiver}>?
	}
}
