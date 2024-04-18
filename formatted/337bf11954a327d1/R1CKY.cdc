import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import
    FungibleTokenMetadataViews
    from "../0xf233dcee88fe0abe/FungibleTokenMetadataViews.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

import Toucans from "../0x577a3c409c5dcb5e/Toucans.cdc"

import ToucansTokens from "../0x577a3c409c5dcb5e/ToucansTokens.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract R1CKY: FungibleToken, ViewResolver{ 
    
    // The amount of tokens in existance
    pub var totalSupply: UFix64
    
    // nil if there is none
    pub let maxSupply: UFix64?
    
    // Paths
    pub let VaultStoragePath: StoragePath
    
    pub let ReceiverPublicPath: PublicPath
    
    pub let VaultPublicPath: PublicPath
    
    pub let MinterStoragePath: StoragePath
    
    pub let AdministratorStoragePath: StoragePath
    
    // Events
    pub event TokensInitialized(initialSupply: UFix64)
    
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    
    pub event TokensDeposited(amount: UFix64, to: Address?)
    
    pub event TokensTransferred(amount: UFix64, from: Address, to: Address)
    
    pub event TokensMinted(amount: UFix64)
    
    pub event TokensBurned(amount: UFix64)
    
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, MetadataViews.Resolver{ 
        pub var balance: UFix64
        
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault{ 
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            if let owner: Address = self.owner?.address{ 
                R1CKY.setBalance(address: owner, balance: self.balance)
            }
            return <-create Vault(balance: amount)
        }
        
        pub fun deposit(from: @FungibleToken.Vault){ 
            let vault: @Vault <- from as! @Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            
            // We set the balance to 0.0 here so that it doesn't
            // decrease the totalSupply in the `destroy` function.
            vault.balance = 0.0
            destroy vault
            if let owner: Address = self.owner?.address{ 
                R1CKY.setBalance(address: owner, balance: self.balance)
            }
        }
        
        pub fun getViews(): [Type]{ 
            return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>()]
        }
        
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<FungibleTokenMetadataViews.FTView>():
                    return R1CKY.resolveView(view)
                case Type<FungibleTokenMetadataViews.FTDisplay>():
                    return R1CKY.resolveView(view)
                case Type<FungibleTokenMetadataViews.FTVaultData>():
                    return R1CKY.resolveView(view)
            }
            return nil
        }
        
        init(balance: UFix64){ 
            self.balance = balance
        }
        
        destroy(){ 
            if self.balance > 0.0{ 
                emit TokensBurned(amount: self.balance)
                R1CKY.totalSupply = R1CKY.totalSupply - self.balance
            }
        }
    }
    
    pub fun createEmptyVault(): @Vault{ 
        return <-create Vault(balance: 0.0)
    }
    
    pub resource Minter: Toucans.Minter{ 
        pub fun mint(amount: UFix64): @Vault{ 
            post{ 
                R1CKY.maxSupply == nil || R1CKY.totalSupply <= R1CKY.maxSupply!:
                    "Exceeded the max supply of tokens allowd."
            }
            R1CKY.totalSupply = R1CKY.totalSupply + amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }
    }
    
    // We follow this pattern of storage
    // so the (potentially) huge dictionary 
    // isn't loaded when the contract is imported
    pub resource Administrator{ 
        // This is an experimental index and should
        // not be used for anything official
        // or monetary related
        priv let balances:{ Address: UFix64}
        
        access(contract) fun setBalance(address: Address, balance: UFix64){ 
            self.balances[address] = balance
        }
        
        pub fun getBalance(address: Address): UFix64{ 
            return self.balances[address] ?? 0.0
        }
        
        pub fun getBalances():{ Address: UFix64}{ 
            return self.balances
        }
        
        init(){ 
            self.balances ={} 
        }
    }
    
    access(contract) fun setBalance(address: Address, balance: UFix64){ 
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        admin.setBalance(address: address, balance: balance)
    }
    
    pub fun getBalance(address: Address): UFix64{ 
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        return admin.getBalance(address: address)
    }
    
    pub fun getBalances():{ Address: UFix64}{ 
        let admin: &Administrator = self.account.borrow<&Administrator>(from: self.AdministratorStoragePath)!
        return admin.getBalances()
    }
    
    pub fun getViews(): [Type]{ 
        return [Type<FungibleTokenMetadataViews.FTView>(), Type<FungibleTokenMetadataViews.FTDisplay>(), Type<FungibleTokenMetadataViews.FTVaultData>()]
    }
    
    pub fun resolveView(_ view: Type): AnyStruct?{ 
        switch view{ 
            case Type<FungibleTokenMetadataViews.FTView>():
                return FungibleTokenMetadataViews.FTView(ftDisplay: self.resolveView(Type<FungibleTokenMetadataViews.FTDisplay>()) as! FungibleTokenMetadataViews.FTDisplay?, ftVaultData: self.resolveView(Type<FungibleTokenMetadataViews.FTVaultData>()) as! FungibleTokenMetadataViews.FTVaultData?)
            case Type<FungibleTokenMetadataViews.FTDisplay>():
                let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "undefined"), mediaType: "image")
                let bannerMedia = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "undefined"), mediaType: "image")
                let medias = MetadataViews.Medias([media, bannerMedia])
                return FungibleTokenMetadataViews.FTDisplay(name: "R1CKY", symbol: "RISP", description: "Each of the participants will have the right to a drawing of tokens or NFTs of my digital account on the flow", externalURL: MetadataViews.ExternalURL(""), logos: medias, socials:{ "twitter": MetadataViews.ExternalURL(""), "discord": MetadataViews.ExternalURL("FpP46nM8")})
            case Type<FungibleTokenMetadataViews.FTVaultData>():
                return FungibleTokenMetadataViews.FTVaultData(storagePath: R1CKY.VaultStoragePath, receiverPath: R1CKY.ReceiverPublicPath, metadataPath: R1CKY.VaultPublicPath, providerPath: /private/R1CKYVault, receiverLinkedType: Type<&Vault{FungibleToken.Receiver}>(), metadataLinkedType: Type<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(), providerLinkedType: Type<&Vault{FungibleToken.Provider}>(), createEmptyVaultFunction: fun (): @Vault{ 
                        return <-R1CKY.createEmptyVault()
                    })
        }
        return nil
    }
    
    init(_paymentTokenInfo: ToucansTokens.TokenInfo, _editDelay: UFix64, _minting: Bool, _initialTreasurySupply: UFix64, _maxSupply: UFix64?, _extra:{ String: AnyStruct}){ 
        
        // Contract Variables
        self.totalSupply = 0.0
        self.maxSupply = _maxSupply
        
        // Paths
        self.VaultStoragePath = /storage/R1CKYVault
        self.ReceiverPublicPath = /public/R1CKYReceiver
        self.VaultPublicPath = /public/R1CKYMetadata
        self.MinterStoragePath = /storage/R1CKYMinter
        self.AdministratorStoragePath = /storage/R1CKYAdmin
        
        // Admin Setup
        let vault <- create Vault(balance: self.totalSupply)
        self.account.save(<-vault, to: self.VaultStoragePath)
        self.account.link<&Vault{FungibleToken.Receiver}>(self.ReceiverPublicPath, target: self.VaultStoragePath)
        self.account.link<&Vault{FungibleToken.Balance, MetadataViews.Resolver}>(self.VaultPublicPath, target: self.VaultStoragePath)
        if self.account.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath) == nil{ 
            self.account.save(<-Toucans.createCollection(), to: Toucans.CollectionStoragePath)
            self.account.link<&Toucans.Collection{Toucans.CollectionPublic}>(Toucans.CollectionPublicPath, target: Toucans.CollectionStoragePath)
        }
        let toucansProjectCollection = self.account.borrow<&Toucans.Collection>(from: Toucans.CollectionStoragePath)!
        toucansProjectCollection.createProject(projectTokenInfo: ToucansTokens.TokenInfo("R1CKY", self.account.address, "RISP", self.ReceiverPublicPath, self.VaultPublicPath, self.VaultStoragePath), paymentTokenInfo: _paymentTokenInfo, minter: <-create Minter(), editDelay: _editDelay, minting: _minting, initialTreasurySupply: _initialTreasurySupply, extra: _extra)
        self.account.save(<-create Administrator(), to: self.AdministratorStoragePath)
        
        // Events
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
