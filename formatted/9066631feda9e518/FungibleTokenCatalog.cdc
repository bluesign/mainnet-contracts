import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

import FUSD from "../0x3c5959b568896393/FUSD.cdc"

pub contract FungibleTokenCatalog{ 
    pub        
        /// VaultSchema
        /// Data about a fungible token vault path and type information
        struct VaultSchema{ 
        pub let type: Type
        
        pub let contractName: String
        
        pub let storagePath: StoragePath
        
        pub let publicPath: PublicPath
        
        pub let publicLinkedType: Type
        
        pub let privatePath: PrivatePath?
        
        pub let privateLinkedType: Type?
        
        init(
            type: Type,
            contractName: String,
            storagePath: StoragePath,
            publicPath: PublicPath,
            publicLinkedType: Type,
            privatePath: PrivatePath?,
            privateLinkedType: Type?
        ){ 
            self.type = type
            self.contractName = contractName
            self.storagePath = storagePath
            self.publicPath = publicPath
            self.publicLinkedType = publicLinkedType
            self.privatePath = privatePath
            self.privateLinkedType = privateLinkedType
        }
    }
    
    /// getVaultForType
    /// Function to return vault information for a given fungible token vault type.
    pub fun getVaultForType(vaultType: Type): VaultSchema?{ 
        switch vaultType{ 
            case Type<@FlowToken.Vault>():
                return VaultSchema(
                    type: Type<@FlowToken.Vault>(),
                    contractName: "FlowToken",
                    storagePath: StoragePath(identifier: "flowTokenVault")!,
                    publicPath: PublicPath(identifier: "flow")!,
                    publicLinkedType: Type<
                        @FlowToken.Vault{
                            FungibleToken.Receiver,
                            FungibleToken.Balance
                        }
                    >(),
                    privatePath: PrivatePath(identifier: "flow")!,
                    privateLinkedType: Type<
                        @FlowToken.Vault{FungibleToken.Provider}
                    >()
                )
            case Type<@DapperUtilityCoin.Vault>():
                return VaultSchema(
                    type: Type<@DapperUtilityCoin.Vault>(),
                    contractName: "DapperUtilityCoin",
                    storagePath: StoragePath(
                        identifier: "dapperUtilityCoinVault"
                    )!,
                    publicPath: PublicPath(
                        identifier: "dapperUtilityCoinReceiver"
                    )!,
                    publicLinkedType: Type<
                        @DapperUtilityCoin.Vault{FungibleToken.Receiver}
                    >(),
                    privatePath: PrivatePath(
                        identifier: "dapperUtilityCoinVault"
                    )!,
                    privateLinkedType: Type<
                        @DapperUtilityCoin.Vault{
                            FungibleToken.Provider,
                            FungibleToken.Balance
                        }
                    >()
                )
            case Type<@FlowUtilityToken.Vault>():
                return VaultSchema(
                    type: Type<@FlowUtilityToken.Vault>(),
                    contractName: "FlowUtilityToken",
                    storagePath: StoragePath(
                        identifier: "flowUtilityTokenVault"
                    )!,
                    publicPath: PublicPath(
                        identifier: "flowUtilityTokenReceiver"
                    )!,
                    publicLinkedType: Type<
                        @FlowUtilityToken.Vault{FungibleToken.Receiver}
                    >(),
                    privatePath: nil,
                    privateLinkedType: nil
                )
            case Type<@FUSD.Vault>():
                return VaultSchema(
                    type: Type<@FUSD.Vault>(),
                    contractName: "FUSD",
                    storagePath: StoragePath(identifier: "fusdVault")!,
                    publicPath: PublicPath(identifier: "fusdReceiver")!,
                    publicLinkedType: Type<
                        @FUSD.Vault{FungibleToken.Receiver}
                    >(),
                    privatePath: nil,
                    privateLinkedType: nil
                )
            default:
                return nil
        }
    }
}
