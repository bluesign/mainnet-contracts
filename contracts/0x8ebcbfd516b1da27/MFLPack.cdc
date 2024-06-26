import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import MFLViews from "./MFLViews.cdc"
import MFLAdmin from "./MFLAdmin.cdc"
import MFLPackTemplate from "./MFLPackTemplate.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows to mint packs (NFTs), which can then be opened. A pack
  is always linked to a packTemplate (see MFLPackTemplate contract for more info).
**/

pub contract MFLPack: NonFungibleToken {

    // Events
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Opened(id: UInt64, from: Address?)
    pub event Minted(id: UInt64, packTemplateID: UInt64, from: Address?)
    pub event Destroyed(id: UInt64)

    // Named Paths
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let PackAdminStoragePath: StoragePath

    // Counter for all the Packs ever minted
    pub var totalSupply: UInt64

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        // Unique ID across all packs
        pub let id: UInt64

        // ID used to identify the kind of pack it is
        pub let packTemplateID: UInt64

        init(packTemplateID: UInt64) {
            MFLPack.totalSupply = MFLPack.totalSupply + (1 as UInt64)
            self.id = MFLPack.totalSupply
            self.packTemplateID = packTemplateID
            emit Minted(id: self.id, packTemplateID: packTemplateID, from: self.owner?.address)
        }

        // Get all supported views for this NFT
        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MFLViews.PackDataViewV1>()
            ]
        }

        // Resolve a specific view
        pub fun resolveView(_ view: Type): AnyStruct? {
            let packTemplateData = MFLPackTemplate.getPackTemplate(id: self.packTemplateID)!
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: packTemplateData.name,
                        description: "MFL Pack #".concat(self.id.toString()),
                        thumbnail: MetadataViews.HTTPFile(url: packTemplateData.imageUrl)
                    )
                case Type<MetadataViews.Royalties>():
                     let royalties: [MetadataViews.Royalty] = []
                     let royaltyReceiverCap = getAccount(MFLAdmin.royaltyAddress()).getCapability<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
                     royalties.append(
                         MetadataViews.Royalty(
                             receiver: royaltyReceiverCap,
                             cut:  0.05,
                             description: "Creator Royalty"
                         )
                     )
                     return MetadataViews.Royalties(royalties)
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let socials = {
                        "twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"),
                        "discord":  MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"),
                        "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"),
                        "medium": MetadataViews.ExternalURL("https://medium.com/playmfl")
                    }
                    return MetadataViews.NFTCollectionDisplay(
                        name: "MFL Pack Collection",
                        description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you’ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you’ll be able to : Be a recruiter (Scout, find, and trade players…), be an agent (Find the best clubs for your players, negotiate contracts with club owners…), be a club owner (Develop your club, recruit players, compete in leagues and tournaments…) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Packs.",
                        externalURL: MetadataViews.ExternalURL("https://playmfl.com"),
                        squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"),
                        bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"),
                        socials: socials
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: MFLPack.CollectionStoragePath,
                        publicPath: MFLPack.CollectionPublicPath,
                        providerPath: /private/MFLPackCollection,
                        publicCollection: Type<&MFLPack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        publicLinked: Type<&MFLPack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&MFLPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-MFLPack.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://playmfl.com")
                case Type<MFLViews.PackDataViewV1>():
                    return MFLViews.PackDataViewV1(
                       id: self.id,
                       packTemplate: packTemplateData
                    )
            }
            return nil
        }

        destroy() {
            emit Destroyed(id: self.id)
        }
    }

    // Main Collection to manage all the Packs NFT
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        // withdraw removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
            // Create a new empty Collection
            var batchCollection <- create Collection()

            // Iterate through the ids and withdraw them from the Collection
            for id in ids {
                batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
            }

            // Return the withdrawn tokens
            return <-batchCollection
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @MFLPack.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let packNFT = nft as! &MFLPack.NFT
            return packNFT as &AnyResource{MetadataViews.Resolver}
        }

        // Called by any account that want to open a specific pack
        pub fun openPack(id: UInt64) {
            let pack <- self.withdraw(withdrawID: id) as! @MFLPack.NFT
            let packTemplate = MFLPackTemplate.getPackTemplate(id: pack.packTemplateID)!

            // Check if packTemplate is openable or if the owner must wait before opening the pack
            assert(packTemplate.isOpenable, message: "PackTemplate is not openable")

            // Emit an event which will be processed by the backend to distribute the content of the pack
            emit Opened(
                id: pack.id,
                from: self.owner!.address,
            )
            destroy pack
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // Public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // This interface allows any account that has a private capability to a PackAdminClaim to call the methods below
    pub resource interface PackAdminClaim {
        pub let name: String
        pub fun batchMintPack(packTemplateID: UInt64, nbToMint: UInt32): @Collection
    }

    pub resource PackAdmin: PackAdminClaim {
        pub let name: String

        init() {
            self.name = "PackAdminClaim"
        }

        pub fun batchMintPack(packTemplateID: UInt64, nbToMint: UInt32): @Collection {
            MFLPackTemplate.increasePackTemplateCurrentSupply(id: packTemplateID, nbToMint: nbToMint)
            let newCollection <- create Collection()
            var i: UInt32 = 0
            while i < nbToMint {
                let pack <- create NFT(packTemplateID: packTemplateID)
                newCollection.deposit(token: <- pack)
                i = i + (1 as UInt32)
            }
            return <- newCollection
        }

        pub fun createPackAdmin(): @PackAdmin {
            return <- create PackAdmin()
        }
    }

    init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/MFLPackCollection
        self.CollectionPublicPath = /public/MFLPackCollection
        self.PackAdminStoragePath = /storage/MFLPackAdmin

        // Initialize contract fields
        self.totalSupply = 0

        // Create a Collection and save it to storage
        self.account.save<@MFLPack.Collection>(<- MFLPack.createEmptyCollection(), to: MFLPack.CollectionStoragePath)
        // Create a public capability for the Collection
        self.account.link<&MFLPack.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(MFLPack.CollectionPublicPath, target: MFLPack.CollectionStoragePath)

        // Create PackAdmin resource and save it to storage
        self.account.save(<- create PackAdmin() , to: self.PackAdminStoragePath)

        emit ContractInitialized()
    }
}
