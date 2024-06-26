/*
 * Copyright (c) 2021 24Karat. All rights reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * This file is part of Project: 24karat flow contract (https://github.com/24karat-gld/flow-24karat-contract)
 *
 * This source code is licensed under the MIT License found in the
 * LICENSE file in the root directory of this source tree or at
 * https://opensource.org/licenses/MIT.
 */

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

// KaratNFT
// NFT items
//
pub contract KaratNFT: NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, metadata: Metadata)

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let metadata: Metadata

        init(initID: UInt64, initMetadata: Metadata) {
            self.id = initID
            self.metadata = initMetadata
        }

        pub fun getMetadata(): Metadata {
            return self.metadata
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata.name,
                        description: self.metadata.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: "https://market.24karat.io/api/items/".concat(self.id.toString()).concat("/thumbnail")
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // There is no max number of NFTs that can be minted from this contract
                    // so the max edition field value is set to nil
                    let editionInfo = MetadataViews.Edition(name: "24Karat NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        [MetadataViews.Royalty(
                            receiver: getAccount(self.metadata.artistAddress).getCapability<&{FungibleToken.Receiver}>(MetadataViews.getRoyaltyReceiverPublicPath()),
                            cut: self.metadata.royalty,
                            description: "The Royalty of 24Karat NFT"
                        )]
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://market.24karat.io/nfts/".concat(self.id.toString()))
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: KaratNFT.CollectionStoragePath,
                        publicPath: KaratNFT.CollectionPublicPath,
                        providerPath: /private/KaratNFTCollection,
                        publicCollection: Type<&KaratNFT.Collection{KaratNFT.KaratNFTCollectionPublic}>(),
                        publicLinkedType: Type<&KaratNFT.Collection{KaratNFT.KaratNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&KaratNFT.Collection{KaratNFT.KaratNFTCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-KaratNFT.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://static.wixstatic.com/media/568614_5676993b65c64da29cecf24d323fd664~mv2.png/v1/fill/w_140,h_160,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/568614_5676993b65c64da29cecf24d323fd664~mv2.png"
                        ),
                        mediaType: "image/png"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "The 24Karat Collection",
                        description: "This collection is used for 24Karat market.",
                        externalURL: MetadataViews.ExternalURL("https://market.24karat.io"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/24karat_io")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // traits is not yet ready
                    let excludedTraits: [String] = []
                    let traitsView = MetadataViews.dictToTraits(dict: {}, excludedNames: excludedTraits)
                    return traitsView

            }
            return nil
        }
    }

    // This is the interface that users can cast their KaratNFT Collection as
    // to allow others to deposit KaratNFT into their Collection. It also allows for reading
    // the details of KaratNFT in the Collection.
    pub resource interface KaratNFTCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowKaratNFT(id: UInt64): &KaratNFT.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow KaratNFT reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub struct Metadata {
        pub let name: String
        pub let artist: String
        pub let artistAddress:Address
        pub let description: String
        pub let type: String
        pub let serialId: UInt64
        pub let royalty: UFix64

		init(
            name: String, 
            artist: String,
            artistAddress:Address, 
            description: String, 
            type: String, 
            serialId: UInt64,
            royalty: UFix64
        ) {
            self.name=name
            self.artist=artist
            self.artistAddress=artistAddress
            self.description=description
            self.type=type
            self.serialId=serialId
            self.royalty=royalty
        }

    }

    // Collection
    // A collection of KaratNFT NFTs owned by an account
    //
    pub resource Collection: KaratNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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

            return <-token
        }

        // deposit takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KaratNFT.NFT

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

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let karatNFT = nft as! &KaratNFT.NFT
            return karatNFT as &AnyResource{MetadataViews.Resolver}
        }

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowKaratNFT
        // Gets a reference to an NFT in the collection as a KaratNFT,
        // exposing all of its fields (including the metadata).
        // This is safe as there are no functions that can be called on the KaratNFT.
        //
        pub fun borrowKaratNFT(id: UInt64): &KaratNFT.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &KaratNFT.NFT
            }

            return nil
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: KaratNFT.Metadata) {

            pre {
                metadata.royalty <= 0.1: "royalty must lower than 0.1"
            }

            // create a new NFT
            var newNFT <- create NFT(initID: KaratNFT.totalSupply, initMetadata: metadata)

            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newNFT)
            emit Minted(id: KaratNFT.totalSupply, metadata: metadata)
            KaratNFT.totalSupply = KaratNFT.totalSupply + (1 as UInt64)
        }
    }

    init() {

        // Set our named paths
        self.CollectionStoragePath = /storage/KaratNFTCollection
        self.CollectionPublicPath = /public/KaratNFTCollection
        self.AdminStoragePath = /storage/KaratNFTAdmin

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.AdminStoragePath)

        emit ContractInitialized()
    }
}
 