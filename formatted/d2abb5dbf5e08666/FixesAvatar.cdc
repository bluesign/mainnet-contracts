/**
> Author: FIXeS World <https://fixes.world/>

# FixesAvatar

TODO: Add description

*/


// Thirdparty Imports
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// Fixes Imports
import FixesTraits from "./FixesTraits.cdc"

import FRC20FTShared from "./FRC20FTShared.cdc"

/// The `FixesAvatar` contract
///
pub contract FixesAvatar{ 
    pub        /* --- Events --- *//// Event emitted when the contract is initialized
        event ContractInitialized()
    
    pub event              
              /// Event emitted when a new trait entry is added
              TraitEntryAdd(
        owner: Address?,
        traitId: UInt64,
        series: String,
        value: UInt8,
        rarity: UInt8,
        offset: Int8
    )
    
    /* --- Variable, Enums and Structs --- */    pub let AvatarStoragePath: StoragePath
    
    pub let AvatarPublicPath: PublicPath
    
    /* --- Interfaces & Resources --- */    pub resource interface ProfilePublic{ 
        pub fun getProperty(_ name: String): String?{} 
        
        pub fun getEnabledTraits(): [MetadataViews.Trait]{} 
        
        pub fun getOwnedTraitIDs(): [UInt64]{} 
        
        pub fun getOwnedTrait(_ id: UInt64): FixesTraits.TraitWithOffset?{} 
        
        pub fun getOwnedTraitView(_ id: UInt64): MetadataViews.Trait?{} 
    }
    
    /// The resource that stores the metadata for this contract
    ///
    pub resource Profile:
        ProfilePublic,
        FRC20FTShared.TransactionHook,
        MetadataViews.Resolver{
    
        // Holds the properties for this profile, key is the property name, value is the property value
        priv let properties:{ String: String}
        
        // Holds NFTs for this profile, key is the NFT type, value is a map of NFT ID to NFT
        priv let nfts: @{Type:{ UInt64: NonFungibleToken.NFT}}
        
        // Holds the owned entities for this profile
        priv let ownedEntities: @{UInt64: FixesTraits.Entry}
        
        // Holds the enabled entities for this profile
        priv let enabledEntities: [UInt64]
        
        init(){ 
            self.properties ={} 
            self.nfts <-{} 
            self.ownedEntities <-{} 
            self.enabledEntities = []
        }
        
        /// @deprecated after Cadence 1.0
        destroy(){ 
            destroy self.nfts
            destroy self.ownedEntities
        }
        
        // ---- implement TransactionHook ----
        
        /// The method that is invoked when the transaction is executed
        ///
        access(account) fun onDeal(
            storefront: Address,
            listingId: UInt64,
            seller: Address,
            buyer: Address,
            tick: String,
            dealAmount: UFix64,
            dealPrice: UFix64,
            totalAmountInListing: UFix64
        ){ 
            // For season 0, we only support the following tick
            // "flows", the default tick
            // "fixes", the tick for the FIXeS platform
            if tick == "flows" || tick == "fixes"{ 
                if let entry <- FixesTraits.attemptToGenerateRandomEntryForSeason0(){ 
                    log("Generated a random entry for season 0".concat(entry.uuid.toString()))
                    self.addTraitEntry(<-entry)
                }
            }
        }
        
        // ---- implement Resolver ----
        
        /// Function that returns all the Metadata Views available for this profile
        ///
        pub fun getViews(): [Type]{ 
            return [Type<MetadataViews.Traits>()]
        }
        
        /// Function that resolves a metadata view for this profile
        ///
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<MetadataViews.Traits>():
                    return MetadataViews.Traits(self.getEnabledTraits())
            }
            return nil
        }
        
        // ---- Public methods ----
        
        /// Get the property with the given name
        ///
        pub fun getProperty(_ name: String): String?{ 
            return self.properties[name]
        }
        
        pub fun getEnabledTraits(): [MetadataViews.Trait]{ 
            let traits: [MetadataViews.Trait] = []
            for traitId in self.enabledEntities{ 
                if let entry = self.borrowEntry(traitId){ 
                    if let view = entry.resolveView(Type<MetadataViews.Trait>()){ 
                        traits.append(view as! MetadataViews.Trait)
                    }
                }
            }
            return traits
        }
        
        pub fun getOwnedTraitIDs(): [UInt64]{ 
            return self.ownedEntities.keys
        }
        
        pub fun getOwnedTrait(_ id: UInt64): FixesTraits.TraitWithOffset?{ 
            if let entry = self.borrowEntry(id){ 
                return entry.getTrait()
            }
            return nil
        }
        
        pub fun getOwnedTraitView(_ id: UInt64): MetadataViews.Trait?{ 
            if let entry = self.borrowEntry(id){ 
                return entry.resolveView(Type<MetadataViews.Trait>()) as! MetadataViews.Trait?
            }
            return nil
        }
        
        // ---- Account Access methods ----
        
        access(account) fun addTraitEntry(_ entry: @FixesTraits.Entry){ 
            let uuid = entry.uuid
            if self.ownedEntities[uuid] != nil{ 
                destroy entry
                return
            }
            let ref = &entry as &FixesTraits.Entry
            // Add the entry to the owned entities
            self.ownedEntities[uuid] <-! entry
            
            // emit the event
            let trait = ref.getTrait()
            emit TraitEntryAdd(
                owner: self.owner?.address,
                traitId: uuid,
                series: trait.series.identifier,
                value: trait.value,
                rarity: trait.rarity,
                offset: trait.offset
            )
        }
        
        // ---- Private methods ----
        
        /// Set the property with the given name to the given value
        ///
        pub fun setProperty(_ name: String, _ value: String){ 
            self.properties[name] = value
        }
        
        // ---- Internal methods ----
        
        priv fun borrowEntry(_ id: UInt64): &FixesTraits.Entry?{ 
            return &self.ownedEntities[id] as &FixesTraits.Entry?
        }
    }
    
    /* --- Public Functions --- *//// Creates a new `Profile` resource
    ///
    pub fun create(): @Profile{ 
        return <-create Profile()
    }
    
    /// Returns the `Profile` public capability for the given address
    ///
    pub fun getProfileCap(_ addr: Address): Capability<
        &Profile{
            ProfilePublic,
            FRC20FTShared.TransactionHook,
            MetadataViews.Resolver
        }
    >{ 
        return getAccount(addr).getCapability<
            &Profile{
                ProfilePublic,
                FRC20FTShared.TransactionHook,
                MetadataViews.Resolver
            }
        >(self.AvatarPublicPath)
    }
    
    init(){ 
        let identifier = "FixesAvatar_".concat(self.account.address.toString())
        self.AvatarStoragePath = StoragePath(identifier: identifier)!
        self.AvatarPublicPath = PublicPath(identifier: identifier)!
        
        // Register the hooks
        FRC20FTShared.registerHookType(Type<@FixesAvatar.Profile>())
        emit ContractInitialized()
    }
}
