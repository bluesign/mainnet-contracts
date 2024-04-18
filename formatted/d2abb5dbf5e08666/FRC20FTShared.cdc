/**
> Author: FIXeS World <https://fixes.world/>

# FRC20FTShared

This contract is a shared library for FRC20 Fungible Token.

*/

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

// Fixes Imports
import FixesHeartbeat from "./FixesHeartbeat.cdc"

pub contract FRC20FTShared{ 
    pub        /* --- Events --- *//// The event that is emitted when the shared store is updated
        event SharedStoreKeyUpdated(key: String, valueType: Type)
    
    /// The event that is emitted when tokens are created
    pub event TokenChangeCreated(
        tick: String,
        amount: UFix64,
        from: Address,
        changeUuid: UInt64
    )
    
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokenChangeWithdrawn(
        tick: String,
        amount: UFix64,
        from: Address,
        changeUuid: UInt64
    )
    
    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokenChangeMerged(
        tick: String,
        amount: UFix64,
        from: Address,
        changeUuid: UInt64,
        fromChangeUuid: UInt64
    )
    
    /// The event that is emitted when tokens are extracted
    pub event TokenChangeExtracted(
        tick: String,
        amount: UFix64,
        from: Address,
        changeUuid: UInt64
    )
    
    /// The event that is emitted when a hook is added
    pub event VaildatedHookTypeAdded(type: Type)
    
    /// The event that is emitted when a hook is added
    pub event TransactionHookAdded(hooksOwner: Address, hookType: Type)
    
    /// The event that is emitted when a deal is updated
    pub event TransactionHooksOnDeal(
        hooksOwner: Address,
        executedHookType: Type,
        storefront: Address,
        listingId: UInt64
    )
    
    /// The event that is emitted when a heartbeat is occurred
    pub event TransactionHooksOnHeartbeat(
        hooksOwner: Address,
        executedHookType: Type,
        deltaTime: UFix64
    )
    
    /* --- Variable, Enums and Structs --- */    pub let SharedStoreStoragePath: StoragePath
    
    pub let SharedStorePublicPath: PublicPath
    
    pub let TransactionHookStoragePath: StoragePath
    
    pub let TransactionHookPublicPath: PublicPath
    
    /* --- Interfaces & Resources --- *//// Cut type for the sale
    ///
    pub enum SaleCutType: UInt8{ 
        pub case TokenTreasury
        
        pub case PlatformTreasury
        
        pub case PlatformStakers
        
        pub case SellMaker
        
        pub case BuyTaker
        
        pub case Commission
        
        pub case MarketplacePortion
    }
    
    /// Sale cut struct for the sale
    ///
    pub struct SaleCut{ 
        pub let type: SaleCutType
        
        pub let ratio: UFix64
        
        pub let receiver: Capability<&{FungibleToken.Receiver}>?
        
        init(
            type: SaleCutType,
            ratio: UFix64,
            receiver: Capability<&{FungibleToken.Receiver}>?
        ){ 
            if type == FRC20FTShared.SaleCutType.SellMaker{ 
                assert(receiver != nil, message: "Receiver should not be nil for consumer cut")
            } else{ 
                assert(receiver == nil, message: "Receiver should be nil for non-consumer cut")
            }
            self.type = type
            self.ratio = ratio
            self.receiver = receiver
        }
    }
    
    /// It a general interface for the Change of FRC20 Fungible Token
    ///
    pub resource interface Balance{ 
        pub            /// The ticker symbol of this change
            /// If the tick is "", it means the change is backed by FlowToken.Vault
            ///
            let tick: String
        
        /// The type of the FT Vault, Optional
        ///
        pub var ftVault: @FungibleToken.Vault?
        
        /// The balance of this change
        ///
        pub var balance: UFix64?
        
        // The conforming type must declare an initializer
        // that allows providing the initial balance of the Vault
        //
        init(
            tick: String,
            from: Address,
            balance: UFix64?,
            ftVault: @FungibleToken.Vault?
        ){} 
        
        /// Check if this Change is a staked tick's change
        ///
        pub fun isStakedTick(): Bool{ 
            return self.isBackedByVault() == false && self.tick[0] == "!"
        }
        
        pub fun getOriginalTick(): String{ 
            // if the tick is a staked tick, remove the first character
            if self.isStakedTick(){ 
                return self.tick.slice(from: 1, upTo: self.tick.length)
            }
            // otherwise, return the tick
            return self.tick
        }
        
        /// Get the balance of this Change
        ///
        pub fun getBalance(): UFix64{ 
            return self.ftVault?.balance ?? self.balance!
        }
        
        /// Check if this Change is empty
        ///
        pub fun isEmpty(): Bool{ 
            return self.getBalance() == 0.0
        }
        
        /// Check if this Change is backed by a Vault
        ///
        pub fun isBackedByVault(): Bool{ 
            return self.ftVault != nil
        }
        
        /// Check if this Change is backed by a FlowToken Vault
        ///
        pub fun isBackedByFlowTokenVault(): Bool{ 
            return self.tick == "" && self.isBackedByVault()
        }
        
        /// Get the type of the Vault
        ///
        pub fun getVaultType(): Type?{ 
            return self.ftVault?.getType()
        }
    }
    
    /// It a general interface for the Settler of FRC20 Fungible Token
    ///
    pub resource interface Settler{ 
        pub            /// Withdraw the given amount of tokens, as a FungibleToken Vault
            ///
            fun withdrawAsVault(amount: UFix64): @FungibleToken.Vault{ 
            post{ 
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
        
        /// Extract all balance of this Change
        ///
        pub fun extractAsVault(): @FungibleToken.Vault{} 
        
        /// Extract all balance of input Change and deposit to self, this method is only available for the contracts in the same account
        ///
        access(account) fun merge(from: @Change){} 
        
        /// Withdraw the given amount of tokens, as a FRC20 Fungible Token Change
        ///
        access(account) fun withdrawAsChange(amount: UFix64): @Change{ 
            post{ 
                // `result` refers to the return value
                result.getBalance() == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Change"
            }
        }
        
        /// Extract all balance of this Change
        ///
        access(account) fun extract(): UFix64{} 
    }
    
    /// It a general resource for the Change of FRC20 Fungible Token
    ///
    pub resource Change: Balance, Settler{ 
        /// The ticker symbol of this change
        pub let tick: String
        
        /// The address of the owner of this change
        pub let from: Address
        
        /// The type of the FT Vault, Optional
        pub var ftVault: @FungibleToken.Vault?
        
        // The token balance of this Change
        pub var balance: UFix64?
        
        init(tick: String, from: Address, balance: UFix64?, ftVault: @FungibleToken.Vault?){ 
            pre{ 
                balance != nil || ftVault != nil:
                    "The balance of the FT Vault or the initial balance must not be nil"
            }
            post{ 
                self.tick == tick:
                    "Tick must be equal to the provided tick"
                self.from == from:
                    "The owner of the Change must be the same as the owner of the Change"
                self.balance == balance:
                    "Balance must be equal to the initial balance"
                self.ftVault == nil || self.balance == nil:
                    "Either FT Vault or balance must be not nil"
            }
            
            // If the tick is "", it means the change is backed by FlowToken.Vault
            if tick == ""{ 
                assert(ftVault != nil && balance == nil, message: "FT Vault must not be nil for tick = ''")
                assert(ftVault.isInstance(OptionalType(Type<@FlowToken.Vault>())), message: "FT Vault must be an instance of FlowToken.Vault")
            }
            self.tick = tick
            self.from = from
            self.balance = balance
            self.ftVault <- ftVault
            emit TokenChangeCreated(tick: self.tick, amount: self.getBalance(), from: self.from, changeUuid: self.uuid)
        }
        
        /// @deprecated after Cadence 1.0
        destroy(){ 
            // You can not destroy a Change with a non-zero balance
            pre{ 
                self.getBalance() == UFix64(0):
                    "Balance must be zero for destroy"
            }
            // Destroy the FT Vault if it is not nil
            destroy self.ftVault
        }
        
        /// Subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        pub fun withdrawAsVault(amount: UFix64): @FungibleToken.Vault{ 
            pre{ 
                self.balance == nil:
                    "Balance must be nil for withdrawAsVault"
                self.isBackedByVault() == true:
                    "The Change must be backed by a Vault"
                self.ftVault?.balance! >= amount:
                    "Amount withdrawn must be less than or equal than the balance of the Vault"
            }
            post{ 
                // result's type must be the same as the type of the original Vault
                self.ftVault?.balance == before(self.ftVault?.balance)! - amount:
                    "New FT Vault balance must be the difference of the previous balance and the withdrawn Vault"
                // result's type must be the same as the type of the original Vault
                result.getType() == self.ftVault?.getType() ?? panic("The FT Vault must not be nil"):
                    "The type of the returned Vault must be the same as the type of the original Vault"
            }
            let vaultRef = self.borrowVault()
            let ret <- vaultRef.withdraw(amount: amount)
            emit TokenChangeWithdrawn(tick: self.tick, amount: amount, from: self.from, changeUuid: self.uuid)
            return <-ret
        }
        
        /// Extract all balance of this Change
        ///
        pub fun extractAsVault(): @FungibleToken.Vault{ 
            pre{ 
                self.isBackedByVault() == true:
                    "The Change must be backed by a Vault"
                self.getBalance() > UFix64(0):
                    "Balance must be greater than zero"
            }
            post{ 
                self.getBalance() == UFix64(0):
                    "Balance must be zero after extraction"
                result.balance == before(self.getBalance()):
                    "Extracted amount must be the same as the balance of the Change"
            }
            let vaultRef = self.borrowVault()
            let balanceToExtract = self.getBalance()
            let ret <- vaultRef.withdraw(amount: balanceToExtract)
            emit TokenChangeExtracted(tick: self.tick, amount: balanceToExtract, from: self.from, changeUuid: self.uuid)
            return <-ret
        }
        
        /// Extract all balance of input Change and deposit to self, this method is only available for the contracts in the same account
        ///
        access(account) fun merge(from: @Change){ 
            pre{ 
                self.isBackedByVault() == from.isBackedByVault():
                    "The Change must be backed by a Vault if and only if the input Change is backed by a Vault"
                from.tick == self.tick:
                    "Tick must be equal to the provided tick"
                from.from == self.from:
                    "The owner of the Change must be the same as the owner of the Change"
            }
            post{ 
                self.getBalance() == before(self.getBalance()) + before(from.getBalance()):
                    "New Vault balance must be the sum of the previous balance and the deposited Vault"
            }
            var extractAmount: UFix64 = 0.0
            if self.isBackedByVault(){ 
                assert(self.ftVault != nil && from.ftVault != nil, message: "FT Vault must not be nil for merge")
                let extracted <- from.extractAsVault()
                extractAmount = extracted.balance
                // Deposit the extracted Vault to self
                let vaultRef = self.borrowVault()
                vaultRef.deposit(from: <-extracted)
            } else{ 
                assert(self.balance != nil && from.balance != nil, message: "Balance must not be nil for merge")
                extractAmount = from.extract()
                self.balance = self.balance! + extractAmount
            }
            
            // emit TokenChangeMerged event
            emit TokenChangeMerged(tick: self.tick, amount: extractAmount, from: self.from, changeUuid: self.uuid, fromChangeUuid: from.uuid)
            // Destroy the Change that we extracted from
            destroy from
        }
        
        /// Withdraw the given amount of tokens, as a FRC20 Fungible Token Change
        ///
        access(account) fun withdrawAsChange(amount: UFix64): @Change{ 
            pre{ 
                self.getBalance() >= amount:
                    "Amount withdrawn must be less than or equal than the balance of the Vault"
            }
            post{ 
                // result's type must be the same as the type of the original Change
                result.tick == self.tick:
                    "Tick must be equal to the provided tick"
                // use the special function `before` to get the value of the `balance` field
                self.getBalance() == before(self.getBalance()) - amount:
                    "New Change balance must be the difference of the previous balance and the withdrawn Change"
            }
            var newChange: @Change? <- nil
            if self.isBackedByVault(){ 
                // withdraw from the input Change, the TokenChangeWithdrawn event will be emitted inside
                let extracted <- self.withdrawAsVault(amount: amount)
                // create a same source Change
                newChange <-! create Change(tick: self.tick, from: self.from, balance: nil, ftVault: <-extracted)
            } else{ 
                self.balance = self.balance! - amount
                newChange <-! create Change(tick: self.tick, from: self.from, balance: amount, ftVault: nil)
                // emit TokenChangeWithdrawn event
                emit TokenChangeWithdrawn(tick: self.tick, amount: amount, from: self.from, changeUuid: self.uuid)
            }
            return <-(newChange ?? panic("The new Change must not be nil"))
        }
        
        /// Extract all balance of this Change, this method is only available for the contracts in the same account
        ///
        access(account) fun extract(): UFix64{ 
            pre{ 
                !self.isBackedByVault():
                    "The Change must not be backed by a Vault"
                self.getBalance() > UFix64(0):
                    "Balance must be greater than zero"
            }
            post{ 
                self.getBalance() == UFix64(0):
                    "Balance must be zero after extraction"
                result == before(self.getBalance()):
                    "Extracted amount must be the same as the balance of the Change"
            }
            var balanceToExtract: UFix64 = self.balance ?? panic("The balance of the Change must be specified")
            self.balance = 0.0
            emit TokenChangeExtracted(tick: self.tick, amount: balanceToExtract, from: self.from, changeUuid: self.uuid)
            return balanceToExtract
        }
        
        /// Borrow the underlying Vault of this Change
        ///
        access(contract) fun borrowVault(): &FungibleToken.Vault{ 
            return &self.ftVault as &FungibleToken.Vault? ?? panic("The Change is not backed by a Vault")
        }
    }
    
    /// Create a new Change
    /// Only the owner of the account can call this method
    ///
    access(account) fun createChange(
        tick: String,
        from: Address,
        balance: UFix64?,
        ftVault: @FungibleToken.Vault?
    ): @Change{ 
        return <-create Change(
            tick: tick,
            from: from,
            balance: balance,
            ftVault: <-ftVault
        )
    }
    
    /// Create a new Change for staked tick
    ///
    access(account) fun createStakedChange(
        ref: &Change,
        issuer: Address
    ): @Change{ 
        pre{ 
            ref.isStakedTick() == false:
                "The input Change must not be a staked tick"
            ref.isBackedByVault() == false:
                "The input Change must not be backed by a Vault"
        }
        post{ 
            result.tick == "!".concat(ref.tick):
                "Tick must be equal to the provided tick"
            result.getBalance() == ref.getBalance():
                "Balance must be equal to the provided balance"
            result.from == issuer:
                "The owner of the Change must be the same as the issuer"
        }
        return <-create Change(
            tick: "!".concat(ref.tick), // staked tick is prefixed with "!"
            from: issuer, // all staked changes are from issuer
            balance: ref.getBalance(),
            ftVault: nil
        )
    }
    
    access(account) fun createEmptyChange(
        tick: String,
        from: Address
    ): @Change{ 
        if tick == ""{ 
            return <-self.createChange(tick: "", from: from, balance: nil, ftVault: <-FlowToken.createEmptyVault())
        } else{ 
            return <-self.createChange(tick: tick, from: from, balance: 0.0, ftVault: nil)
        }
    }
    
    /// Create a new Change for FlowToken
    /// Only the owner of the account can call this method
    ///
    access(account) fun createEmptyFlowChange(from: Address): @Change{ 
        return <-self.createEmptyChange(tick: "", from: from)
    }
    
    /// Create a new Change by some FungibleToken
    ///
    access(account) fun wrapFungibleVaultChange(
        ftVault: @FungibleToken.Vault,
        from: Address
    ): @Change{ 
        let tick =
            ftVault.isInstance(Type<@FlowToken.Vault>())
                ? ""
                : ftVault.getType().identifier
        return <-self.createChange(
            tick: tick,
            from: from,
            balance: nil,
            ftVault: <-ftVault
        )
    }
    
    /// Deposit one Change to another Change
    /// Only the owner of the account can call this method
    ///
    access(account) fun depositToChange(receiver: &Change, change: @Change){ 
        pre{ 
            change.isBackedByVault() == receiver.isBackedByVault():
                "The Change must be backed by a Vault if and only if the input Change is backed by a Vault"
            change.tick == receiver.tick:
                "Tick must be equal to the provided tick"
        }
        if change.from == receiver.from{ 
            receiver.merge(from: <-change)
        } else{ 
            if change.isBackedByVault(){ 
                // withdraw from the input Change
                let extracted <- change.extractAsVault()
                // deposit to the receiver
                let vaultRef = receiver.borrowVault()
                vaultRef.deposit(from: <-extracted)
            } else{ 
                // withdraw from the input Change
                let extracted = change.extract()
                // create a same source Change and deposit to the receiver
                receiver.merge(from: <-self.createChange(tick: receiver.tick, from: receiver.from, balance: extracted, ftVault: nil))
            }
            // destroy the input Change
            destroy change
        }
    }
    
    /** --- Temporary order resources --- *//// It a temporary resource combining change and cuts
    ///
    pub resource ValidFrozenOrder{ 
        pub let tick: String
        
        pub let amount: UFix64
        
        pub let totalPrice: UFix64
        
        pub let cuts: [SaleCut]
        
        pub var change: @Change?
        
        init(
            tick: String,
            amount: UFix64,
            totalPrice: UFix64,
            cuts: [
                SaleCut
            ],
            _ change: @Change
        ){ 
            pre{ 
                amount > UFix64(0):
                    "Amount must be greater than zero"
                cuts.length > 0:
                    "Cuts must not be empty"
                change.getBalance() > UFix64(0):
                    "Balance must be greater than zero"
            }
            self.tick = tick
            self.amount = amount
            self.totalPrice = totalPrice
            self.change <- change
            self.cuts = cuts
        }
        
        /// @deprecated after Cadence 1.0
        destroy(){ 
            pre{ 
                self.change == nil:
                    "Change must be nil for destroy"
            }
            destroy self.change
        }
        
        /// Extract all balance of this Change, this method is only available for the contracts in the same account
        ///
        access(account) fun extract(): @Change{ 
            pre{ 
                self.change != nil:
                    "Change must not be nil for extract"
            }
            post{ 
                self.change == nil:
                    "Change must be nil after extraction"
                result.getBalance() == before(self.change?.getBalance()):
                    "Extracted amount must be the same as the balance of the Change"
            }
            var out: @Change? <- nil
            self.change <-> out
            return <-out!
        }
    }
    
    /// Only the contracts in this account can call this method
    ///
    access(account) fun createValidFrozenOrder(
        tick: String,
        amount: UFix64,
        totalPrice: UFix64,
        cuts: [
            SaleCut
        ],
        change: @Change
    ): @ValidFrozenOrder{ 
        return <-create ValidFrozenOrder(
            tick: tick,
            amount: amount,
            totalPrice: totalPrice,
            cuts: cuts,
            <-change
        )
    }
    
    /** Shared store resource *//// The Market config type
    ///
    pub enum ConfigType: UInt8{ 
        // Platform config type
        pub case PlatformSalesFee
        
        pub case PlatformSalesCutTreasuryPoolRatio
        
        pub case PlatformSalesCutPlatformPoolRatio
        
        pub case PlatformSalesCutPlatformStakersRatio
        
        pub case PlatformSalesCutMarketRatio
        
        pub case PlatofrmMarketplaceStakingToken
        
        pub case MarketFeeSharedRatio
        
        pub case MarketFeeTokenSpecificRatio
        
        // Market config type
        pub case MarketFeeDeployerRatio
        
        pub case MarketAccessibleAfter
        
        pub case MarketWhitelistClaimingToken
        
        pub case MarketWhitelistClaimingAmount
        
        pub case GameLotteryTicketPrice
        
        pub case GameLotteryEpochInterval
        
        pub case GameLotteryAutoStart
        
        pub case GameLotteryServiceFee
    // FGameLottery config type
    }
    
    /* --- Public Methods --- */    pub resource interface SharedStorePublic{ 
        pub            /// Get the key by type
            ///
            fun getKeyByEnum(_ type: ConfigType): String?{ 
            var key: String? = nil
            // get the key by type
            switch type{ 
                case ConfigType.PlatformSalesFee:
                    key = "platform:SalesFee"
                    break
                case ConfigType.PlatformSalesCutTreasuryPoolRatio:
                    key = "platform:SalesCutTreasuryPoolRatio"
                    break
                case ConfigType.PlatformSalesCutPlatformPoolRatio:
                    key = "platform:SalesCutPlatformPoolRatio"
                    break
                case ConfigType.PlatformSalesCutPlatformStakersRatio:
                    key = "platform:SalesCutPlatformStakersRatio"
                    break
                case ConfigType.PlatformSalesCutMarketRatio:
                    key = "platform:SalesCutMarketRatio"
                    break
                case ConfigType.PlatofrmMarketplaceStakingToken:
                    key = "platform:MarketplaceStakingToken"
                    break
                case ConfigType.MarketFeeSharedRatio:
                    key = "market:FeeSharedRatio"
                    break
                case ConfigType.MarketFeeTokenSpecificRatio:
                    key = "market:FeeTokenSpecificRatio"
                    break
                case ConfigType.MarketFeeDeployerRatio:
                    key = "market:FeeDeployerRatio"
                    break
                case ConfigType.MarketAccessibleAfter:
                    key = "market:AccessibleAfter"
                    break
                case ConfigType.MarketWhitelistClaimingToken:
                    key = "market:WhitelistClaimingToken"
                    break
                case ConfigType.MarketWhitelistClaimingAmount:
                    key = "market:WhitelistClaimingAmount"
                    break
                case ConfigType.GameLotteryTicketPrice:
                    key = "gameLottery:TicketPrice"
                    break
                case ConfigType.GameLotteryEpochInterval:
                    key = "gameLottery:EpochInterval"
                    break
                case ConfigType.GameLotteryAutoStart:
                    key = "gameLottery:AutoStart"
                    break
                case ConfigType.GameLotteryServiceFee:
                    key = "gameLottery:ServiceFee"
                    break
            }
            return key
        }
        
        // getter for the shared store
        pub fun get(_ key: String): AnyStruct?{} 
        
        // getter for the shared store
        pub fun getByEnum(_ type: ConfigType): AnyStruct?{ 
            if let key = self.getKeyByEnum(type){ 
                return self.get(key)
            }
            return nil
        }
        
        // --- Account Methods ---
        
        /// Set the value
        access(account) fun set(_ key: String, value: AnyStruct){} 
        
        /// Set the value by type
        access(account) fun setByEnum(_ type: ConfigType, value: AnyStruct){} 
    }
    
    pub resource SharedStore: SharedStorePublic{ 
        priv var data:{ String: AnyStruct}
        
        init(){ 
            self.data ={} 
        }
        
        /// getter for the shared store
        ///
        pub fun get(_ key: String): AnyStruct?{ 
            return self.data[key]
        }
        
        /// Set the value
        ///
        access(account) fun set(_ key: String, value: AnyStruct){ 
            self.data[key] = value
            emit SharedStoreKeyUpdated(key: key, valueType: value.getType())
        }
        
        /// Set the value by type
        ///
        access(account) fun setByEnum(_ type: ConfigType, value: AnyStruct){ 
            if let key = self.getKeyByEnum(type){ 
                self.set(key, value: value)
            }
        }
    }
    
    /* --- Public Methods --- *//// Get the shared store
    ///
    pub fun borrowGlobalStoreRef(): &SharedStore{SharedStorePublic}{ 
        let addr = self.account.address
        return self.borrowStoreRef(addr)
        ?? panic("Could not borrow capability from public store")
    }
    
    /// Borrow the shared store
    ///
    pub fun borrowStoreRef(_ address: Address): &SharedStore{
        SharedStorePublic
    }?{ 
        return getAccount(address).getCapability<
            &SharedStore{SharedStorePublic}
        >(self.SharedStorePublicPath).borrow()
    }
    
    /* --- Account Methods --- *//// Create the instance of the shared store
    ///
    access(account) fun createSharedStore(): @SharedStore{ 
        return <-create SharedStore()
    }
    
    /** Transaction hooks */    access(contract) let validatedHookTypes:{ Type: Bool}
    
    /// It a general interface for the Transaction Hook
    ///
    pub resource interface TransactionHook{ 
        access(               /// The method that is invoked when the transaction is executed
               /// Before try-catch is deployed, please ensure that there will be no panic inside the method.
               ///
               account) fun onDeal(
            storefront: Address,
            listingId: UInt64,
            seller: Address,
            buyer: Address,
            tick: String,
            dealAmount: UFix64,
            dealPrice: UFix64,
            totalAmountInListing: UFix64
        ){ 
            log("Default Empty Transaction Hook")
        }
        
        /// The methods that is invoked when the heartbeat is executed
        /// Before try-catch is deployed, please ensure that there will be no panic inside the method.
        ///
        access(account) fun onHeartbeat(_ deltaTime: UFix64){ 
            log("Default Empty Transaction Hook")
        }
    }
    
    access(account) fun registerHookType(_ type: Type){ 
        if type.isSubtype(of: Type<@AnyResource{TransactionHook}>()){ 
            self.validatedHookTypes[type] = true
            emit VaildatedHookTypeAdded(type: type)
        }
    }
    
    pub fun getAllValidatedHookTypes(): [Type]{ 
        return self.validatedHookTypes.keys
    }
    
    pub fun isHookTypeValidated(_ type: Type): Bool{ 
        return self.validatedHookTypes[type] == true
    }
    
    /// It a general resource for the Transaction Hook
    ///
    pub resource Hooks: TransactionHook, FixesHeartbeat.IHeartbeatHook{ 
        priv let hooks:{ Type: Capability<&AnyResource{TransactionHook}>}
        
        init(){ 
            self.hooks ={} 
        }
        
        // --- Public Methods ---
        
        /// Check if the hook exists
        ///
        pub fun hasHook(_ type: Type): Bool{ 
            return self.hooks[type] != nil
        }
        
        // --- Account Methods ---
        
        pub fun addHook(_ hook: Capability<&AnyResource{TransactionHook}>){ 
            pre{ 
                hook.check():
                    "The hook must be valid"
            }
            let hookRef = hook.borrow() ?? panic("Could not borrow reference from hook capability.")
            let type = hookRef.getType()
            assert(self.hooks[type] == nil, message: "Hook of type ".concat(type.identifier).concat("already exists."))
            self.hooks[type] = hook
            emit TransactionHookAdded(hooksOwner: self.owner?.address ?? panic("Hooks owner must not be nil"), hookType: type)
        }
        
        /// The method that is invoked when the transaction is executed
        ///
        access(account) fun onDeal(storefront: Address, listingId: UInt64, seller: Address, buyer: Address, tick: String, dealAmount: UFix64, dealPrice: UFix64, totalAmountInListing: UFix64){ 
            let hooksOwnerAddr = self.owner?.address
            if hooksOwnerAddr == nil{ 
                return
            }
            // iterate all hooks
            self._iterateHooks(fun (type: Type, ref: &AnyResource{FRC20FTShared.TransactionHook}){ 
                    // call hook
                    ref.onDeal(storefront: storefront, listingId: listingId, seller: seller, buyer: buyer, tick: tick, dealAmount: dealAmount, dealPrice: dealPrice, totalAmountInListing: totalAmountInListing)
                    
                    // emit event
                    emit TransactionHooksOnDeal(hooksOwner: hooksOwnerAddr!, executedHookType: type, storefront: storefront, listingId: listingId)
                })
        }
        
        /// The methods that is invoked when the heartbeat is executed
        ///
        access(account) fun onHeartbeat(_ deltaTime: UFix64){ 
            let hooksOwnerAddr = self.owner?.address
            if hooksOwnerAddr == nil{ 
                return
            }
            // iterate all hooks
            self._iterateHooks(fun (type: Type, ref: &AnyResource{FRC20FTShared.TransactionHook}){ 
                    // call hook
                    ref.onHeartbeat(deltaTime)
                    
                    // emit event
                    emit TransactionHooksOnHeartbeat(hooksOwner: hooksOwnerAddr!, executedHookType: type, deltaTime: deltaTime)
                })
        }
        
        /// Iterate all hooks
        ///
        priv fun _iterateHooks(_ func: ((Type, &AnyResource{FRC20FTShared.TransactionHook}): Void)){ 
            // call all hooks
            for type in self.hooks.keys{ 
                // check if the hook type is validated
                if !FRC20FTShared.isHookTypeValidated(type){ 
                    continue
                }
                // get the hook capability
                if let hookCap = self.hooks[type]{ 
                    let valid = hookCap.check()
                    if !valid{ 
                        continue
                    }
                    if let ref: &AnyResource{FRC20FTShared.TransactionHook} = hookCap.borrow(){ 
                        func(type, ref)
                    }
                }
            } // end for
        }
    }
    
    /// Create the instance of the hooks resource
    ///
    pub fun createHooks(): @Hooks{ 
        return <-create Hooks()
    }
    
    /// Get the hooks resource reference
    /// Only the owner of the account can call this method
    ///
    access(account) fun borrowTransactionHook(_ address: Address): &AnyResource{
        TransactionHook
    }?{ 
        return getAccount(address).getCapability<&AnyResource{TransactionHook}>(
            self.TransactionHookPublicPath
        ).borrow()
    }
    
    /// Get the hooks resource reference
    /// Only the owner of the account can call this method
    ///
    access(account) fun borrowTransactionHookWithHeartbeat(
        _ address: Address
    ): &AnyResource{TransactionHook, FixesHeartbeat.IHeartbeatHook}?{ 
        return getAccount(address).getCapability<
            &AnyResource{
                FRC20FTShared.TransactionHook,
                FixesHeartbeat.IHeartbeatHook
            }
        >(self.TransactionHookPublicPath).borrow()
    }
    
    init(){ 
        // Transaction Hook
        let hookIdentifier =
            "FRC20FTShared_".concat(self.account.address.toString()).concat(
                "_transactionHook"
            )
        self.TransactionHookStoragePath = StoragePath(
                identifier: hookIdentifier
            )!
        self.TransactionHookPublicPath = PublicPath(identifier: hookIdentifier)!
        self.validatedHookTypes ={} 
        
        // Shared Store
        let identifier =
            "FRC20SharedStore_".concat(self.account.address.toString())
        self.SharedStoreStoragePath = StoragePath(identifier: identifier)!
        self.SharedStorePublicPath = PublicPath(identifier: identifier)!
        
        // create the indexer
        self.account.save(
            <-self.createSharedStore(),
            to: self.SharedStoreStoragePath
        )
        self.account.link<&SharedStore{SharedStorePublic}>(
            self.SharedStorePublicPath,
            target: self.SharedStoreStoragePath
        )
    }
}
