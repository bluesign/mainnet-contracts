/**

    TrmRentV2_2.cdc

    Description: Contract definitions for initializing Rent Collections, Rent NFT Resource and Rent Minter

    Rent contract is used for defining the Rent NFT, Rent Collection,
    Rent Collection Public Interface and Rent Minter

    ## `NFT` resource

    The core resource type that represents an Rent NFT in the smart contract.

    ## `Collection` Resource

    The resource that stores a user's Rent NFT collection.
    It includes a few functions to allow the owner to easily
    move tokens in and out of the collection.

    ## `Receiver` resource interfaces

    This interface is used for depositing Rent NFTs to the Rent Collectio.
    It also exposes few functions to fetch data about Rent token

    To send an NFT to another user, a user would simply withdraw the NFT
    from their Collection, then call the deposit function on another user's
    Collection to complete the transfer.

    ## `Minter` Resource

    Minter resource is used for minting Rent NFTs

*/
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"

pub contract TrmRentV2_2: NonFungibleToken {
    // -----------------------------------------------------------------------
    // Rent contract Event definitions
    // -----------------------------------------------------------------------

    // The total number of tokens of this type in existence
    pub var totalSupply: UInt64
    // Event that emitted when the NFT contract is initialized
    pub event ContractInitialized()
    // Event that emitted when the rent collection is initialized
    pub event RentCollectionInitialized(userAccountAddress: Address)
    // Emitted when a Rent is minted
    pub event RentMinted(id: UInt64, assetTokenID: UInt64, kID: String, assetURL: String, expiryTimestamp: UFix64)
    // Emitted when a Rent is destroyed
    pub event RentDestroyed(id: UInt64)
    // Event that is emitted when a token is withdrawn, indicating the owner of the collection that it was withdrawn from.
    pub event Withdraw(id: UInt64, from: Address?)
    // Event that emitted when a token is deposited to a collection. It indicates the owner of the collection that it was deposited to.
    pub event Deposit(id: UInt64, to: Address?)

    /// Paths where Storage and capabilities are stored
    pub let collectionStoragePath: StoragePath
    pub let collectionPublicPath: PublicPath
    pub let minterStoragePath: StoragePath
    pub let minterPrivatePath: PrivatePath

    // RentData
    //
    // Struct for storing metadata for Rent
    pub struct RentData {
        pub let assetTokenID: UInt64
        pub let kID: String
        pub var assetName: String
        pub var assetDescription: String
        pub let assetURL: String
        pub var assetThumbnailURL: String
        pub var assetMetadata: {String: String}
        pub var rentMetadata: {String: String}
        pub let expiryTimestamp: UFix64

        init(assetTokenID: UInt64, kID: String, assetName: String, assetDescription: String, assetURL: String, assetThumbnailURL: String, assetMetadata: {String: String}, expiryTimestamp: UFix64) {
            // pre {
            //     expiryTimestamp > getCurrentBlock().timestamp:
            //         "Expiry timestamp should be greater than current timestamp"
            // }
            self.assetTokenID = assetTokenID
            self.kID = kID
            self.assetName = assetName
            self.assetDescription = assetDescription
            self.assetURL = assetURL
            self.assetThumbnailURL = assetThumbnailURL
            self.assetMetadata = assetMetadata
            self.assetMetadata = {}
            self.rentMetadata = {}
            self.expiryTimestamp = expiryTimestamp
        }
    }

    //  NFT
    //
    // The main Rent NFT resource that signifies that an asset is rented by a user
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let data: RentData

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.data.assetName.concat("(Rented)"),
                        description: self.data.assetDescription,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.data.assetThumbnailURL
                        )
                    )
            }

            return nil
        }

        init(id: UInt64, assetTokenID: UInt64, kID: String, assetName: String, assetDescription: String, assetURL: String, assetThumbnailURL: String, assetMetadata: {String: String}, expiryTimestamp: UFix64) {
            self.id = id
            self.data = RentData(assetTokenID: assetTokenID, kID: kID, assetName: assetName, assetDescription: assetDescription, assetURL: assetURL, assetThumbnailURL: assetThumbnailURL, assetMetadata: assetMetadata, expiryTimestamp: expiryTimestamp)

            emit RentMinted(id: self.id, assetTokenID: assetTokenID, kID: kID, assetURL: assetURL, expiryTimestamp: expiryTimestamp)
        }

        // If the Rent NFT is destroyed, emit an event to indicate to outside ovbservers that it has been destroyed
        destroy() {
            emit RentDestroyed(id: self.id)
        }
    }

    // CollectionPublic
    //
    // Public interface for Rent Collection
    // This exposes functions for depositing NFTs
    // and also for returning some info for a specific
    // Rent NFT id and Asset NFT id
    pub resource interface CollectionPublic {
        access(contract) fun depositRent(token: @NonFungibleToken.NFT)

        pub fun getIDs(): [UInt64]
        pub fun getAssetTokenIDs(): [UInt64]
        pub fun getID(assetTokenID: UInt64): UInt64
        pub fun getAssetTokenID(id: UInt64): UInt64
        pub fun idExists(id: UInt64): Bool
        pub fun assetTokenIDExists(assetTokenID: UInt64): Bool
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowNFTUsingAssetTokenID(assetTokenID: UInt64): &NonFungibleToken.NFT?
        pub fun borrowRent(id: UInt64): &NFT
        pub fun borrowRentUsingAssetTokenID(assetTokenID: UInt64): &NFT
        pub fun getExpiryTimestamp(id: UInt64): UFix64
        pub fun getExpiryTimestampUsingAssetTokenID(assetTokenID: UInt64): UFix64
        pub fun isExpired(id: UInt64): Bool
        pub fun isExpiredUsingAssetTokenID(assetTokenID: UInt64): Bool
        pub fun isRentValid(id: UInt64): Bool
        pub fun isRentValidUsingAssetTokenID(assetTokenID: UInt64): Bool
    }

    // Collection
    //
    // The resource that stores a user's Rent NFT collection.
    // It includes a few functions to allow the owner to easily
    // moveto deposit or withdraw the tokens.
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
        
        // Dictionary to hold the Rent NFTs in the Collection
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        // Dictionary mapping Asset Token IDs to Rent Token IDs
        pub var rentedNFTs: {UInt64: UInt64}

        init() {
            self.ownedNFTs <- {}
            self.rentedNFTs = {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            pre {
                false: "Withdrawing Rent directly from Rent contract is not allowed"
            }
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Rent Token ID does not exist")
            let rentToken <- token as! @NFT
            self.rentedNFTs.remove(key: rentToken.data.assetTokenID)
            emit Withdraw(id: withdrawID, from: self.owner!.address)
            return <- rentToken
        }

        // deposit takes an NFT as an argument and adds it to the Collection
        pub fun deposit(token: @NonFungibleToken.NFT) {
            pre {
                false: "Depositing Rent directly to Rent contract is not allowed"
            }

            let rentToken <- token as! @NFT

            if self.isRentValidUsingAssetTokenID(assetTokenID: rentToken.data.assetTokenID) {
                destroy rentToken
                panic("Valid Rent token for this asset already exists")
            } else {
                if let existingRentTokenID = self.rentedNFTs[rentToken.data.assetTokenID] {
                    let existingRentToken <- self.withdrawRent(id: existingRentTokenID)
                    destroy existingRentToken
                }
                let newRentTokenId = rentToken.id
                self.rentedNFTs[rentToken.data.assetTokenID] = newRentTokenId
                let oldToken <- self.ownedNFTs[newRentTokenId] <- rentToken
                destroy oldToken
                emit Deposit(id: newRentTokenId, to: self.owner!.address)
            }
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowViewResolver is to conform with MetadataViews
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT

            return refRentNFT as &AnyResource{MetadataViews.Resolver}
        }

        // getAssetTokenIDs returns an array of the asset token IDs that are in the collection
        pub fun getAssetTokenIDs(): [UInt64] {
            return self.rentedNFTs.keys
        }

        // Returns the rent token ID for an NFT from assetTokenID in the collection
        pub fun getID(assetTokenID: UInt64): UInt64 {
            return self.rentedNFTs[assetTokenID] ?? panic("Asset Token ID does not exist")
        }

        // Returns the asset token ID for an NFT in the collection
        pub fun getAssetTokenID(id: UInt64): UInt64 {
            pre {
                self.ownedNFTs[id] != nil: "Rent Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT
            
            return refRentNFT.data.assetTokenID
        }

        // Checks if id of NFT exists in collection
        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        // Checks if id of NFT exists in collection
        pub fun assetTokenIDExists(assetTokenID: UInt64): Bool {
            if (self.rentedNFTs[assetTokenID] == nil) {
                return false
            }
            let rentTokenID = self.rentedNFTs[assetTokenID] ?? panic("Rent Token ID does not exist")
            return self.ownedNFTs[rentTokenID] != nil
        }

        // Returns a borrowed reference to an NFT in the collection so that the caller can read data and call methods from it
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // Returns a borrowed reference to an NFT in the collection using asset token id so that the caller can read data and call methods from it
        pub fun borrowNFTUsingAssetTokenID(assetTokenID: UInt64): &NonFungibleToken.NFT? {
            let rentTokenID = self.rentedNFTs[assetTokenID] ?? panic("Rent Token ID does not exist")
            return &self.ownedNFTs[rentTokenID] as &NonFungibleToken.NFT?
        }

        // Returns a borrowed reference to the Rent NFT in the collection so that the caller can read data and call methods from it
        pub fun borrowRent(id: UInt64): &NFT {
            pre {
                self.ownedNFTs[id] != nil: "Rent Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            return refNFT as! &NFT
        }

        // Returns a borrowed reference to the RENT NFT in the collection using asset token id so that the caller can read data and call methods from it
        pub fun borrowRentUsingAssetTokenID(assetTokenID: UInt64): &NFT {
            pre {
                self.rentedNFTs[assetTokenID] != nil: "Asset Token ID does not exist"
                self.ownedNFTs[self.rentedNFTs[assetTokenID]!] != nil: "Rent Token ID does not exist"
            }
            let rentTokenID = self.rentedNFTs[assetTokenID]!
            let refNFT = (&self.ownedNFTs[rentTokenID] as auth &NonFungibleToken.NFT?)!
            return refNFT as! &NFT
            
        }

        // Returns the expiry for an NFT in the collection
        pub fun getExpiryTimestamp(id: UInt64): UFix64 {
            pre {
                self.ownedNFTs[id] != nil: "Rent Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT
            return refRentNFT.data.expiryTimestamp
        }

        // Returns the expiry for an NFT in the collection using asset token id
        pub fun getExpiryTimestampUsingAssetTokenID(assetTokenID: UInt64): UFix64 {
            pre {
                self.rentedNFTs[assetTokenID] != nil: "Asset Token ID does not exist"
                self.ownedNFTs[self.rentedNFTs[assetTokenID]!] != nil: "Rent Token ID does not exist"
            }
            let rentTokenID = self.rentedNFTs[assetTokenID]!

            let refNFT = (&self.ownedNFTs[rentTokenID] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT
            return refRentNFT.data.expiryTimestamp
        }

        // Returns if token is expired
        pub fun isExpired(id: UInt64): Bool {
            pre {
                self.ownedNFTs[id] != nil: "Rent Token ID does not exist"
            }
            let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT
            return refRentNFT.data.expiryTimestamp < getCurrentBlock().timestamp
        }

        // Returns if token is expired using asset token id
        pub fun isExpiredUsingAssetTokenID(assetTokenID: UInt64): Bool {
            pre {
                self.rentedNFTs[assetTokenID] != nil: "Asset Token ID does not exist"
                self.ownedNFTs[self.rentedNFTs[assetTokenID]!] != nil: "Rent Token ID does not exist"
            }
            let rentTokenID = self.rentedNFTs[assetTokenID]!

            let refNFT = (&self.ownedNFTs[rentTokenID] as auth &NonFungibleToken.NFT?)!
            let refRentNFT = refNFT as! &NFT
            return refRentNFT.data.expiryTimestamp < getCurrentBlock().timestamp
        }

        // Returns if rent is valid for rent id
        pub fun isRentValid(id: UInt64): Bool {
            if self.ownedNFTs[id] != nil {

                let refNFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                let refRentNFT = refNFT as! &NFT
                return refRentNFT.data.expiryTimestamp > getCurrentBlock().timestamp

            } else {
                return false
            }
        }

        // Returns if rent is valid for asset token id
        pub fun isRentValidUsingAssetTokenID(assetTokenID: UInt64): Bool {
            if let rentTokenID = self.rentedNFTs[assetTokenID] {

                if self.ownedNFTs[rentTokenID] != nil {

                    let refNFT = (&self.ownedNFTs[rentTokenID] as auth &NonFungibleToken.NFT?)!
                    let refRentNFT = refNFT as! &NFT
                    return refRentNFT.data.expiryTimestamp > getCurrentBlock().timestamp
                    
                } else {
                    return false
                }
            }
            return false
        }

        // Destroys specified token in the collection
        access(contract) fun destroyToken(id: UInt64) {
            pre {
                self.ownedNFTs[id] != nil: "Rent Token ID does not exist"
            }
            self.rentedNFTs.remove(key: self.getAssetTokenID(id: id))
            let oldToken <- self.ownedNFTs.remove(key: id) 
            destroy oldToken
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        access(contract) fun withdrawRent(id: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: id) ?? panic("Rent Token ID does not exist")
            let rentToken <- token as! @NFT
            self.rentedNFTs.remove(key: rentToken.data.assetTokenID)
            emit Withdraw(id: id, from: self.owner!.address)
            return <- rentToken
        }

        // deposit takes an NFT as an argument and adds it to the Collection
        access(contract) fun depositRent(token: @NonFungibleToken.NFT) {
            let rentToken <- token as! @NFT

            if self.isRentValidUsingAssetTokenID(assetTokenID: rentToken.data.assetTokenID) {
                destroy rentToken
                panic("Valid Rent token for this asset already exists")
            } else {
                if let existingRentTokenID = self.rentedNFTs[rentToken.data.assetTokenID] {
                    let existingRentToken <- self.withdrawRent(id: existingRentTokenID)
                    destroy existingRentToken
                }
                let newRentTokenId = rentToken.id
                self.rentedNFTs[rentToken.data.assetTokenID] = newRentTokenId
                let oldToken <- self.ownedNFTs[newRentTokenId] <- rentToken
                destroy oldToken
                emit Deposit(id: newRentTokenId, to: self.owner!.address)
            }
        }

        // If a transaction destroys the Collection object, all the NFTs contained within are also destroyed!
        destroy() {
            destroy self.ownedNFTs
        }
    }

    // createEmptyCollection creates an empty Collection and returns it to the caller so that they can own NFTs
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // emitCreateEmptyRentCollectionEvent emits events for asset collection initialization
    pub fun emitCreateEmptyRentCollectionEvent(userAccountAddress: Address) {
        emit RentCollectionInitialized(userAccountAddress: userAccountAddress)
    }

    // Minter
    //
    // Minter is a special resource that is used for minting Rent Tokens
    pub resource Minter {

        // mintNFT mints the rent NFT and stores it in the collection of recipient
        pub fun mintNFT(assetTokenID: UInt64, kID: String, assetName: String, assetDescription: String, assetURL: String, assetThumbnailURL: String, assetMetadata: {String: String}, expiryTimestamp: UFix64, recipient: &AnyResource{CollectionPublic}): UInt64 {
            // pre {
            //     expiryTimestamp > getCurrentBlock().timestamp:
            //         "Expiry timestamp should be greater than current timestamp"
            // }
            
            let id = TrmRentV2_2.totalSupply
            TrmRentV2_2.totalSupply = id + 1

            recipient.depositRent(token: <- create NFT(id: id, assetTokenID: assetTokenID, kID: kID, assetName: assetName, assetDescription: assetDescription, assetURL: assetURL, assetThumbnailURL: assetThumbnailURL, assetMetadata: assetMetadata, expiryTimestamp: expiryTimestamp))
            
            return id
        }
    }

    init() {
        self.totalSupply = 0

        // Settings paths
        self.collectionStoragePath = /storage/TrmRentV2_2Collection
        self.collectionPublicPath = /public/TrmRentV2_2Collection
        self.minterStoragePath = /storage/TrmRentV2_2Minter
        self.minterPrivatePath = /private/TrmRentV2_2Minter

        // First, check to see if a minter resource already exists
        if self.account.type(at: self.minterStoragePath) == nil {

            // Put the minter in storage with access only to admin
            self.account.save(<-create Minter(), to: self.minterStoragePath)
        }

        self.account.link<&TrmRentV2_2.Minter>(self.minterPrivatePath, target: TrmRentV2_2.minterStoragePath)

        emit ContractInitialized()
    }
}