import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FreshmintMetadataViews from "../0x0c82d33d4666f1f7/FreshmintMetadataViews.cdc"

pub contract BigMinter: NonFungibleToken {

    pub let version: String

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, hash: [UInt8])
    pub event Revealed(id: UInt64)
    pub event Burned(id: UInt64)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath

    /// The total number of BigMinter NFTs that have been minted.
    ///
    pub var totalSupply: UInt64

    /// A placeholder image used to display NFTs that have not yet been revealed.
    ///
    pub let placeholderImage: String

    /// A list of royalty recipients that is attached to all NFTs
    /// minted by this contract.
    ///
    access(contract) var royalties: [MetadataViews.Royalty]
    
    /// Return the royalty recipients for this contract.
    ///
    pub fun getRoyalties(): [MetadataViews.Royalty] {
        return BigMinter.royalties
    }

    pub struct Metadata {

        /// A salt that is published when the metadata is revealed.
        ///
        /// The salt is a byte array that is prepended to the 
        /// encoded metadata values before generating the metadata hash.
        ///
        pub let salt: [UInt8]

        pub let image: String
        pub let serialNumber: UInt64
        pub let name: String
        pub let description: String
        pub let shape: String
        pub let color: String
        pub let smile: String
        pub let emboss: String
        pub let outline: String
        pub let birthmark: String
        pub let redeemed: String

        init(
            salt: [UInt8],
            image: String,
            serialNumber: UInt64,
            name: String,
            description: String,
            shape: String,
            color: String,
            smile: String,
            emboss: String,
            outline: String,
            birthmark: String,
            redeemed: String,
        ) {
            self.salt = salt

            self.image = image
            self.serialNumber = serialNumber
            self.name = name
            self.description = description
            self.shape = shape
            self.color = color
            self.smile = smile
            self.emboss = emboss
            self.outline = outline
            self.birthmark = birthmark
            self.redeemed = redeemed
        }

        /// Encode this metadata object as a byte array.
        ///
        /// This can be used to hash the metadata and verify its integrity.
        ///
        pub fun encode(): [UInt8] {
            return self.salt
                .concat(self.image.utf8)
                .concat(self.serialNumber.toBigEndianBytes())
                .concat(self.name.utf8)
                .concat(self.description.utf8)
                .concat(self.shape.utf8)
                .concat(self.color.utf8)
                .concat(self.smile.utf8)
                .concat(self.emboss.utf8)
                .concat(self.outline.utf8)
                .concat(self.birthmark.utf8)
                .concat(self.redeemed.utf8)
        }

        pub fun hash(): [UInt8] {
            return HashAlgorithm.SHA3_256.hash(self.encode())
        }
    }

    /// This dictionary holds the metadata for all NFTs
    /// minted by this contract.
    ///
    /// When an NFT is revealed, its metadata is added to this 
    /// dictionary.
    ///
    access(contract) let metadata: {UInt64: Metadata}

    /// Return the metadata for an NFT.
    ///
    /// This function returns nil if the NFT has not yet been revealed.
    ///
    pub fun getMetadata(nftID: UInt64): Metadata? {
        return BigMinter.metadata[nftID]
    }

    /// This dictionary stores all NFT IDs minted by this contract,
    /// indexed by their metadata hash.
    ///
    /// It is populated at mint time and later used to validate
    /// metadata hashes at reveal time.
    ///
    /// This dictionary is indexed by hash rather than by ID so that
    /// the contract (and client software) can prevent duplicate mints.
    ///
    access(contract) let nftsByHash: {String: UInt64}

    pub fun getNFTIDByHash(hash: String): UInt64? {
        return BigMinter.nftsByHash[hash]
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        pub let id: UInt64

        /// A hash of the NFT's metadata.
        ///
        /// The metadata hash is known at mint time and 
        /// is generated by hashing the set of metadata fields
        /// for this NFT. The hash can later be used to verify
        /// that the correct metadata fields are revealed.
        ///
        pub let hash: [UInt8]

        init(hash: [UInt8]) {
            self.id = self.uuid
            self.hash = hash
        }

        /// Return the metadata for this NFT.
        ///
        /// This function returns nil if the NFT metadata has
        /// not yet been revealed.
        ///
        pub fun getMetadata(): Metadata? {
            return BigMinter.metadata[self.id]
        }

        pub fun getViews(): [Type] {
            if self.getMetadata() != nil {
                return [
                    Type<MetadataViews.Display>(),
                    Type<MetadataViews.ExternalURL>(),
                    Type<MetadataViews.NFTCollectionDisplay>(),
                    Type<MetadataViews.NFTCollectionData>(),
                    Type<MetadataViews.Royalties>(),
                    Type<MetadataViews.Serial>()
                ]
            }

            return [
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Display>(),
                Type<FreshmintMetadataViews.BlindNFT>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            if let metadata = self.getMetadata() {
                switch view {
                    case Type<MetadataViews.Display>():
                        return self.resolveDisplay(metadata)
                    case Type<MetadataViews.ExternalURL>():
                        return self.resolveExternalURL()
                    case Type<MetadataViews.NFTCollectionDisplay>():
                        return self.resolveNFTCollectionDisplay()
                    case Type<MetadataViews.NFTCollectionData>():
                        return self.resolveNFTCollectionData()
                    case Type<MetadataViews.Royalties>():
                        return self.resolveRoyalties()
                    case Type<MetadataViews.Serial>():
                        return self.resolveSerial(metadata)
                }

                return nil
            }

            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "BigMinter",
                        description: "This NFT is not yet revealed.",
                        thumbnail: MetadataViews.IPFSFile(
                            cid: BigMinter.placeholderImage, 
                            path: nil
                        )
                    )
                case Type<FreshmintMetadataViews.BlindNFT>():
                    return FreshmintMetadataViews.BlindNFT(hash: self.hash)
                case Type<MetadataViews.ExternalURL>():
                    return self.resolveExternalURL()
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return self.resolveNFTCollectionDisplay()
                case Type<MetadataViews.NFTCollectionData>():
                    return self.resolveNFTCollectionData()
                case Type<MetadataViews.Royalties>():
                    return self.resolveRoyalties()
            }

            return nil
        }

        pub fun resolveDisplay(_ metadata: Metadata): MetadataViews.Display {
            return MetadataViews.Display(
                name: metadata.name,
                description: metadata.description,
                thumbnail: MetadataViews.IPFSFile(cid: metadata.image, path: nil)
            )
        }
        
        pub fun resolveExternalURL(): MetadataViews.ExternalURL {
            return MetadataViews.ExternalURL("https://flute-app.vercel.app/".concat(self.id.toString()))
        }
        
        pub fun resolveNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay {
            let media = MetadataViews.Media(
                file: MetadataViews.IPFSFile(
                    cid: "bafkreicrfbblmaduqg2kmeqbymdifawex7rxqq2743mitmeia4zdybmmre", 
                    path: nil
                ),
                mediaType: "image/jpeg"
            )
        
            return MetadataViews.NFTCollectionDisplay(
                name: "BigMinter",
                description: "Seeds of Testing",
                externalURL: MetadataViews.ExternalURL("https://flute-app.vercel.app"),
                squareImage: media,
                bannerImage: media,
                socials: {}
            )
        }
        
        pub fun resolveNFTCollectionData(): MetadataViews.NFTCollectionData {
            return MetadataViews.NFTCollectionData(
                storagePath: BigMinter.CollectionStoragePath,
                publicPath: BigMinter.CollectionPublicPath,
                providerPath: BigMinter.CollectionPrivatePath,
                publicCollection: Type<&BigMinter.Collection{BigMinter.BigMinterCollectionPublic}>(),
                publicLinkedType: Type<&BigMinter.Collection{BigMinter.BigMinterCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&BigMinter.Collection{BigMinter.BigMinterCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                    return <-BigMinter.createEmptyCollection()
                })
            )
        }
        
        pub fun resolveRoyalties(): MetadataViews.Royalties {
            return MetadataViews.Royalties(BigMinter.royalties)
        }
        
        pub fun resolveSerial(_ metadata: Metadata): MetadataViews.Serial {
            return MetadataViews.Serial(metadata.serialNumber)
        }
        
        destroy() {
            BigMinter.totalSupply = BigMinter.totalSupply - (1 as UInt64)

            emit Burned(id: self.id)
        }
    }

    pub resource interface BigMinterCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBigMinter(id: UInt64): &BigMinter.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow BigMinter reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: BigMinterCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        
        /// A dictionary of all NFTs in this collection indexed by ID.
        ///
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        /// Remove an NFT from the collection and move it to the caller.
        ///
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) 
                ?? panic("Requested NFT to withdraw does not exist in this collection")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <- token
        }

        /// Deposit an NFT into this collection.
        ///
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @BigMinter.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Return an array of the NFT IDs in this collection.
        ///
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Return a reference to an NFT in this collection.
        ///
        /// This function panics if the NFT does not exist in this collection.
        ///
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        /// Return a reference to an NFT in this collection
        /// typed as BigMinter.NFT.
        ///
        /// This function returns nil if the NFT does not exist in this collection.
        ///
        pub fun borrowBigMinter(id: UInt64): &BigMinter.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &BigMinter.NFT
            }

            return nil
        }

        /// Return a reference to an NFT in this collection
        /// typed as MetadataViews.Resolver.
        ///
        /// This function panics if the NFT does not exist in this collection.
        ///
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let nftRef = nft as! &BigMinter.NFT
            return nftRef as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Return a new empty collection.
    ///
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    /// The administrator resource used to mint and reveal NFTs.
    ///
    pub resource Admin {

        /// Mint a new NFT.
        ///
        /// To mint a blind NFT, specify its metadata hash
        /// that can later be used to verify the revealed NFT.
        ///
        pub fun mintNFT(hash: [UInt8]): @BigMinter.NFT {
            let hexHash = String.encodeHex(hash)

            // Prevent multiple NFTs from being minted with the same metadata hash.
            assert(
                BigMinter.nftsByHash[hexHash] == nil,
                message: "an NFT has already been minted with hash=".concat(hexHash)
            )

            let nft <- create BigMinter.NFT(hash: hash)

            emit Minted(id: nft.id, hash: hash)

            // Save the metadata hash so that it can later be validated on reveal. 
            BigMinter.nftsByHash[hexHash] = nft.id

            BigMinter.totalSupply = BigMinter.totalSupply + (1 as UInt64)

            return <- nft
        }

        /// Reveal a minted NFT.
        ///
        /// To reveal an NFT, publish its complete metadata and unique salt value.
        ///
        pub fun revealNFT(id: UInt64, metadata: Metadata) {
            pre {
                BigMinter.metadata[id] == nil : "NFT has already been revealed"
            }

            // An NFT cannot be revealed unless the provided metadata values
            // match the hash the was specified at mint time.

            let hash = String.encodeHex(metadata.hash())

            if let mintedID = BigMinter.getNFTIDByHash(hash: hash) {
                assert(
                    id == mintedID,
                    message: "the provided metadata hash matches NFT with ID="
                        .concat(mintedID.toString())
                        .concat(", but expected ID=")
                        .concat(id.toString())
                )
            } else {
                panic("the provided metadata hash does not match any minted NFTs")
            }

            BigMinter.metadata[id] = metadata

            emit Revealed(id: id)
        }

        /// Set the royalty recipients for this contract.
        ///
        /// This function updates the royalty recipients for all NFTs
        /// minted by this contract.
        ///
        pub fun setRoyalties(_ royalties: [MetadataViews.Royalty]) {
            BigMinter.royalties = royalties
        }
    }

    /// Return a public path that is scoped to this contract.
    ///
    pub fun getPublicPath(suffix: String): PublicPath {
        return PublicPath(identifier: "BigMinter_".concat(suffix))!
    }

    /// Return a private path that is scoped to this contract.
    ///
    pub fun getPrivatePath(suffix: String): PrivatePath {
        return PrivatePath(identifier: "BigMinter_".concat(suffix))!
    }

    /// Return a storage path that is scoped to this contract.
    ///
    pub fun getStoragePath(suffix: String): StoragePath {
        return StoragePath(identifier: "BigMinter_".concat(suffix))!
    }

    priv fun initAdmin(admin: AuthAccount) {
        // Create an empty collection and save it to storage
        let collection <- BigMinter.createEmptyCollection()

        admin.save(<- collection, to: BigMinter.CollectionStoragePath)

        admin.link<&BigMinter.Collection>(BigMinter.CollectionPrivatePath, target: BigMinter.CollectionStoragePath)

        admin.link<&BigMinter.Collection{NonFungibleToken.CollectionPublic, BigMinter.BigMinterCollectionPublic, MetadataViews.ResolverCollection}>(BigMinter.CollectionPublicPath, target: BigMinter.CollectionStoragePath)
        
        // Create an admin resource and save it to storage
        let adminResource <- create Admin()

        admin.save(<- adminResource, to: self.AdminStoragePath)
    }

    init(placeholderImage: String) {

        self.version = "0.0.32"

        self.CollectionPublicPath = BigMinter.getPublicPath(suffix: "Collection")
        self.CollectionStoragePath = BigMinter.getStoragePath(suffix: "Collection")
        self.CollectionPrivatePath = BigMinter.getPrivatePath(suffix: "Collection")

        self.AdminStoragePath = BigMinter.getStoragePath(suffix: "Admin")

        self.placeholderImage = placeholderImage

        self.royalties = []

        self.totalSupply = 0

        self.metadata = {}
        self.nftsByHash = {}

        self.initAdmin(admin: self.account)

        emit ContractInitialized()
    }
}
