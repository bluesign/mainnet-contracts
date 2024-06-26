import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract DriverzInsurance: NonFungibleToken {

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event DriverzInsuranceMinted(id: UInt64, name: String, description: String, image: String, traits: {String: String})

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let CollectionPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath

    pub var totalSupply: UInt64

    pub struct DriverzInsuranceMetadata {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub let image: String
        pub let traits: {String: String}

        init(id: UInt64 ,name: String, description: String, image: String, traits: {String: String}) {
            self.id = id
            self.name=name
            self.description = description
            self.image = image
            self.traits = traits
        }
    }

    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub let name: String
        pub let description: String
        pub var image: String
        pub let traits: {String: String}

        init(id: UInt64 ,name: String, description: String, image: String, traits: {String: String}) {
            self.id = id
            self.name=name
            self.description = description
            self.image = image
            self.traits = traits
        }

        pub fun revealThumbnail() {
            let urlBase = self.image.slice(from: 0, upTo: 47)
            let newImage = urlBase.concat(self.id.toString()).concat(".png")
            self.image = newImage
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTView>(),
                Type<MetadataViews.Display>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<DriverzInsurance.DriverzInsuranceMetadata>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.Traits>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.image,
                            path: nil
                        )
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://driverz.world")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: DriverzInsurance.CollectionStoragePath,
                        publicPath: DriverzInsurance.CollectionPublicPath,
                        providerPath: DriverzInsurance.CollectionPrivatePath,
                        publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic}>(),
                        publicLinkedType: Type<&Collection{DriverzInsurance.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Collection{DriverzInsurance.CollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <- DriverzInsurance.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let squareMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                           url: "https://driverzinc.io/DriverzNFT-logo.png"
                        ),
                        mediaType: "image"
                    )
                    let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://driverzinc.io/DriverzNFT-logo.png"
                        ),
                        mediaType: "image"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "DriverzInsurance",
                        description: "DriverzInsurance Collection",
                        externalURL: MetadataViews.ExternalURL("https://driverz.world"),
                        squareImage: squareMedia,
                        bannerImage: bannerMedia,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/DriverzWorld/"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/driverz"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/driverzworld/")
                        }
                    )
                case Type<DriverzInsurance.DriverzInsuranceMetadata>():
                    return DriverzInsurance.DriverzInsuranceMetadata(
                        id: self.id,
                        name: self.name,
                        description: self.description,
                        image: self.image,
                        traits: self.traits
                    )
                case Type<MetadataViews.NFTView>(): 
                let viewResolver = &self as &{MetadataViews.Resolver}
                return MetadataViews.NFTView(
                    id : self.id,
                    uuid: self.uuid,
                    display: MetadataViews.getDisplay(viewResolver),
                    externalURL : MetadataViews.getExternalURL(viewResolver),
                    collectionData : MetadataViews.getNFTCollectionData(viewResolver),
                    collectionDisplay : MetadataViews.getNFTCollectionDisplay(viewResolver),
                    royalties : MetadataViews.getRoyalties(viewResolver),
                    traits : MetadataViews.getTraits(viewResolver)
                )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties([])
                case Type<MetadataViews.Traits>():
                    let traits: [MetadataViews.Trait] = []
                    for trait in self.traits.keys {
                        traits.append(MetadataViews.Trait(
                            trait: trait,
                            value: self.traits[trait]!,
                            displayType: nil,
                            rarity: nil
                        ))
                    }
                    return MetadataViews.Traits(traits: traits)
            }
            return nil
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDriverzInsurance(id: UInt64): &DriverzInsurance.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow DriverzInsurance reference: The ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @DriverzInsurance.NFT

            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}{
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let mainNFT = nft as! &DriverzInsurance.NFT
            return mainNFT
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowDriverzInsurance(id: UInt64): &DriverzInsurance.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &DriverzInsurance.NFT
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.ownedNFTs
        }

        init () {
            self.ownedNFTs <- {}
        }
    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

	pub resource Admin {
		pub fun mintNFT(
		recipient: &{NonFungibleToken.CollectionPublic},
		name: String,
        description: String,
        image: String,
        traits: {String: String}
        ) {
            emit DriverzInsuranceMinted(id: DriverzInsurance.totalSupply, name: name, description: description, image: image, traits: traits)

            DriverzInsurance.totalSupply = DriverzInsurance.totalSupply + (1 as UInt64)
            
			recipient.deposit(token: <- create DriverzInsurance.NFT(
			    initID: DriverzInsurance.totalSupply,
                name: name,
                description: description,
			    image:image,
                traits: traits
                )
            )
		}

	}

    init() {
        self.CollectionStoragePath = /storage/DriverzInsuranceCollection
        self.CollectionPublicPath = /public/DriverzInsuranceCollection
        self.CollectionPrivatePath = /private/DriverzInsuranceCollection
        self.AdminStoragePath = /storage/DriverzInsuranceMinter

        self.totalSupply = 0

        let minter <- create Admin()
        self.account.save(<-minter, to: self.AdminStoragePath)

        let collection <- DriverzInsurance.createEmptyCollection()
        self.account.save(<-collection, to: DriverzInsurance.CollectionStoragePath)
        self.account.link<&DriverzInsurance.Collection{NonFungibleToken.CollectionPublic, DriverzInsurance.CollectionPublic}>(DriverzInsurance.CollectionPublicPath, target: DriverzInsurance.CollectionStoragePath)

        emit ContractInitialized()
    }
}