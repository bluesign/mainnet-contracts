//SPDX-License-Identifier : CC-BY-NC-4.0

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

// Metaverse
// NFT for Metaverse
//
pub contract Metaverse: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, typeID: UInt64, metadata: {String:String})
    pub event BatchMinted(ids: [UInt64], typeID: [UInt64], metadata: {String:String})
    pub event NFTBurned(id: UInt64)
    pub event NFTsBurned(ids: [UInt64])

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of Metaverses that have been minted
    //
    pub var totalSupply: UInt64

    // NFT
    // Metaverse as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // The token's ID
        pub let id: UInt64
        // The token's type, e.g. 3 == Hat
        pub let typeID: UInt64
        // Token's metadata as a string dictionary
        access(self) let metadata:  {String: String}

        // initializer
        //
        init(initID: UInt64, initTypeID: UInt64, initMetadata: {String: String}) {
            self.id = initID
            self.typeID = initTypeID
            self.metadata = initMetadata
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Traits>()
            ]
        }

         pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"]!,
                        description: self.metadata["description"]!,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata["imageUrl"]!
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://ozonemetaverse.io/")
                case Type<MetadataViews.Royalties>(): 
                    let royalties : [MetadataViews.Royalty] = []
                    royalties.append(MetadataViews.Royalty(recipient: getAccount(Metaverse.account.address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), cut: 0.1, description: "Ozone Metaverse Secondary Sale Royalty"))
                    return MetadataViews.Royalties(cutInfos: royalties)
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Metaverse.CollectionStoragePath,
                        publicPath: Metaverse.CollectionPublicPath,
                        providerPath: /private/ProvenancedCollectionsV9,
                        publicCollection: Type<&Metaverse.Collection{Metaverse.MetaverseCollectionPublic, NonFungibleToken.CollectionPublic}>(),
                        publicLinkedType: Type<&Metaverse.Collection{Metaverse.MetaverseCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Metaverse.Collection{Metaverse.MetaverseCollectionPublic,NonFungibleToken.Provider,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Metaverse.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                           url: "https://d19wottuqbmkwr.cloudfront.net/nft/banners1.jpg"
                        ),
                        mediaType: "image"
                    )
                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://d19wottuqbmkwr.cloudfront.net/nft/banners2.jpg"
                        ),
                        mediaType: "image"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Ozone Metaverse",
                        description: "Ozone is the enterprise grade platform for virtual worlds building. Simple to use - Powerful - 100% browser based.",
                        externalURL: MetadataViews.ExternalURL("https://ozonemetaverse.io"),
                        squareImage: squareMedia,
                        bannerImage: bannerMedia,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/ozonemetaverse"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/ozonemetaverse")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let districtNameTrait = MetadataViews.Trait(
                        name: "District Name", 
                        value: self.metadata["districtName"], 
                        displayType: nil,
                        rarity: nil
                    )
                    let landRarityTrait = MetadataViews.Trait(
                        name: "Land Rarity", 
                        value: self.metadata["landRarity"], 
                        displayType: nil,
                        rarity: nil
                    )
                    return MetadataViews.Traits([
                        districtNameTrait,
                        landRarityTrait
                    ])
            }

            return nil
        }

        // get complete metadata
        pub fun getMetadata() : {String:String} {
            return self.metadata;
        }

        // get metadata field by key
        pub fun getMetadataField(key:String) : String? {
            if let value = self.metadata[key] {
                return value
            }
            return nil;
        }

        // If the NFT is burned, emit an event to indicate 
        // to outside observers that it has been destroyed
        destroy() {
            emit NFTBurned(id: self.id)
        }
    }

    // This is the interface that users can cast their Metaverse Collection as
    // to allow others to deposit Metaverse into their Collection. It also allows for reading
    // the details of Metaverse in the Collection.
    pub resource interface MetaverseCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun getNFTs(): &{UInt64: NonFungibleToken.NFT}
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowMetaverse(id: UInt64): &Metaverse.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Metaverse reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Metaverse NFTs owned by an account
    //
    pub resource Collection: MetaverseCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Metaverse.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun getNFTs(): &{UInt64: NonFungibleToken.NFT} {
            return (&self.ownedNFTs as &{UInt64: NonFungibleToken.NFT})
            
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // borrowMetaverse
        // Gets a reference to an NFT in the collection as a Metaverse,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the Metaverse.
        //
        pub fun borrowMetaverse(id: UInt64): &Metaverse.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Metaverse.NFT
            } else {
                return nil
            }
        }

        pub fun borrowNFTSafe(id: UInt64): &NFT? {
            post {
                result == nil || result!.id == id: "The returned reference's ID does not match the requested ID"
            }

            return self.ownedNFTs[id] != nil 
                ? (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)! as! &Metaverse.NFT 
                : nil
        }

          pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let metaverseNft = nft as! &Metaverse.NFT
            return metaverseNft as &AnyResource{MetadataViews.Resolver}
        }

        // destructor
        destroy() {
            emit NFTsBurned(ids: self.ownedNFTs.keys)
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource NFTMinter {

		// mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, metadata: {String:String}) {
            emit Minted(id: Metaverse.totalSupply, typeID: typeID, metadata: metadata)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create Metaverse.NFT(initID: Metaverse.totalSupply, initTypeID: typeID, initMetadata: metadata))

            Metaverse.totalSupply = Metaverse.totalSupply + (1 as UInt64)
		}

        // bachtMintNFT
        // Mints a batch of NFTs
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun batchMintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: [UInt64], metadata: {String:String}) {
            let idsTab: [UInt64] = []
            let quantity = UInt64(typeID.length)
            var i: UInt64 = 0
            while i < quantity {
              
                // deposit it in the recipient's account using their reference
			    recipient.deposit(token: <-create Metaverse.NFT(initID: Metaverse.totalSupply, initTypeID: typeID[i], initMetadata: metadata))

                idsTab.append(Metaverse.totalSupply)

                Metaverse.totalSupply = Metaverse.totalSupply + (1 as UInt64)

                i = i + UInt64(1)
            }

            emit BatchMinted(ids: idsTab, typeID: typeID, metadata: metadata)
		}
	}

    // fetch
    // Get a reference to a Metaverse from an account's Collection, if available.
    // If an account does not have a Metaverse.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &Metaverse.NFT? {
        let collection = getAccount(from)
            .getCapability(Metaverse.CollectionPublicPath)!
            .borrow<&Metaverse.Collection{Metaverse.MetaverseCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust Metaverse.Collection.borowMetaverse to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowMetaverse(id: itemID)
    }

     pub fun getAllNftsFromAccount(_ from: Address): &{UInt64: NonFungibleToken.NFT}? {
        let collection = getAccount(from)
            .getCapability(Metaverse.CollectionPublicPath)!
            .borrow<&Metaverse.Collection{Metaverse.MetaverseCollectionPublic}>()
            ?? panic("Couldn't get collection")
        return collection.getNFTs()
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/metaverseCollection
        self.CollectionPublicPath = /public/metaverseCollection
        self.MinterStoragePath = /storage/metaverseMinter

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        // Create and link collection to this account   
        self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
        self.account.link<&Metaverse.Collection{NonFungibleToken.CollectionPublic, Metaverse.MetaverseCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)
        
        emit ContractInitialized()
	}
}