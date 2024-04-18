import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract ExpToken: FungibleToken{ 
    
    // Total supply of Flow tokens in existence
    pub var totalSupply: UFix64
    
    // Paths
    pub let tokenVaultPath: StoragePath
    
    pub let tokenBalancePath: PublicPath
    
    pub let tokenReceiverPath: PublicPath
    
    // This is a token model that combines the strengths of both Centralized Ledgers and Distributed Ledgers.
    // As for the claimable Exp Tokens, when users haven't set up a local Vault but have already earned Exp,
    // the associated tokens will be temporarily stored here.
    priv let unclaimedTokens:{ Address: UFix64}
    
    // Mint Exp token in Centralized Ledger model
    access(account) fun mintUnclaimedTokens(amount: UFix64, to: Address){ 
        if self.unclaimedTokens.containsKey(to){ 
            self.unclaimedTokens[to] = self.unclaimedTokens[to]! + amount
        } else{ 
            self.unclaimedTokens[to] = amount
        }
        emit UnclaimedTokensMinted(amount: amount)
    }
    
    // Due to the absence of msg.sender in Cadence, a certificate must be passed in for address verification
    pub fun claimTokens(amount: UFix64, userCertificateCap: Capability<&UserCertificate>): @ExpToken.Vault{ 
        let userAddr = ((userCertificateCap.borrow()!).owner!).address
        // UFix64 can automatically detect situations where the value is less than 0。
        self.unclaimedTokens[userAddr] = self.unclaimedTokens[userAddr]! - amount
        let expVault <- self.mintTokens(amount: amount)
        return <-expVault
    }
    
    pub fun getBalance(at: Address): UFix64{ 
        return self.unclaimedTokens[at] == nil ? self.unclaimedTokens[at]! : 0.0
    }
    
    // UserCertificate store in user's storage path for Pool function to verify user's address
    pub resource UserCertificate{} 
    
    pub fun setupUser(): @UserCertificate{ 
        let certificate <- create UserCertificate()
        return <-certificate
    }
    
    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)
    
    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    
    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)
    
    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)
    
    pub event UnclaimedTokensMinted(amount: UFix64)
    
    // Event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)
    
    // Event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)
    
    // Event that is emitted when a new burner resource is created
    pub event BurnerCreated()
    
    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance{ 
        
        // holds the balance of a users tokens
        pub var balance: UFix64
        
        // initialize the balance at resource creation time
        init(balance: UFix64){ 
            self.balance = balance
        }
        
        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault{ 
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }
        
        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault){ 
            let vault <- from as! @ExpToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }
        
        destroy(){ 
            if self.balance > 0.0{ 
                ExpToken.totalSupply = ExpToken.totalSupply - self.balance
            }
        }
    }
    
    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FungibleToken.Vault{ 
        return <-create Vault(balance: 0.0)
    }
    
    // Mint exp tokens
    //
    // $Exp token can only be minted when:
    //   - user takes online actions like: swap, mint, etc
    //
    access(account) fun mintTokens(amount: UFix64): @ExpToken.Vault{ 
        pre{ 
            amount > 0.0:
                "Amount minted must be greater than zero"
        }
        ExpToken.totalSupply = ExpToken.totalSupply + amount
        emit TokensMinted(amount: amount)
        return <-create Vault(balance: amount)
    }
    
    // Burn tokens
    //
    access(account) fun burnTokens(from: @FungibleToken.Vault){ 
        let vault <- from as! @ExpToken.Vault
        let amount = vault.balance
        destroy vault
        emit TokensBurned(amount: amount)
    }
    
    //
    access(account) fun gainExp(expAmount: UFix64, playerAddr: Address){ 
        // Mint Exp tokens
        let expVaultCap = getAccount(playerAddr).getCapability<&ExpToken.Vault{FungibleToken.Receiver}>(ExpToken.tokenReceiverPath)
        if expVaultCap.check() == true{ 
            let expVault <- ExpToken.mintTokens(amount: expAmount)
            (expVaultCap.borrow()!).deposit(from: <-expVault)
        } else{ 
            // If players do not claim the exp vault locally, it will be stored as a reward for future players to claim
            ExpToken.mintUnclaimedTokens(amount: expAmount, to: playerAddr)
        }
    }
    
    init(){ 
        self.totalSupply = 0.0
        self.unclaimedTokens ={} 
        self.tokenVaultPath = /storage/expTokenVault
        self.tokenReceiverPath = /public/expTokenReceiver
        self.tokenBalancePath = /public/expTokenBalance
        
        // Emit an event that shows that the contract was initialized
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
