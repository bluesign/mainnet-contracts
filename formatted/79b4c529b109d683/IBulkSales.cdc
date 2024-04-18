import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

/// IBulkSales
/// Contract interface for BulkListing and BulkPurchasing contracts that defines common values and interfaces
pub contract interface IBulkSales{ 
    pub        
        /// AdminStoragePath
        /// Storage path for contract admin object
        AdminStoragePath: StoragePath
    
    /// CommissionAdminPrivatePath
    /// Private path for commission admin capability
    pub CommissionAdminPrivatePath: PrivatePath
    
    /// CommissionReaderPublicPath
    /// Public path for commission reader capability
    pub CommissionReaderPublicPath: PublicPath
    
    /// CommissionReaderCapability
    /// Stored capability for commission reader
    pub CommissionReaderCapability: Capability<&{ICommissionReader}>
    
    /// Readable
    /// Interface that provides a human-readable output of the struct's data
    pub struct interface IReadable{ 
        pub fun getReadable():{ String: AnyStruct}{} 
    }
    
    pub struct interface IRoyalty{ 
        pub receiverAddress: Address
        
        pub rate: UFix64
    }
    
    /// Royalty
    /// An object representing a single royalty cut for a given listing
    pub struct Royalty: IRoyalty, IReadable{ 
        init(receiverAddress: Address, rate: UFix64){ 
            pre{ 
                rate > 0.0 && rate < 1.0:
                    "rate must be between 0 and 1"
            }
        }
    }
    
    /// CommissionAdmin
    /// Private capability to manage commission receivers
    pub resource interface ICommissionAdmin{ 
        pub fun addCommissionReceiver(
            _ receiver: Capability<&AnyResource{FungibleToken.Receiver}>
        ){} 
        
        pub fun removeCommissionReceiver(receiverTypeIdentifier: String){} 
    }
    
    /// CommissionReader
    /// Public capability to get a commission receiver
    pub resource interface ICommissionReader{ 
        pub fun getCommissionReceiver(_ identifier: String): Capability<
            &AnyResource{FungibleToken.Receiver}
        >?{} 
    }
}
