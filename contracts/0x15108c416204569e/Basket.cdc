// Basket Contract
//
// NonFungibleToken that holds any number of NonFungibleTokens and FungibleTokens

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import ViewResolver from "../0x1d7e57aa55817448/ViewResolver.cdc"

pub contract Basket: NonFungibleToken, ViewResolver {

    // Total number of Basket's in existance
    pub var totalSupply: UInt64 

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    
    // Thought these could be added as useful way to retrieve correct paths that is backwards compatible across all contracts
    pub fun getDefaultCollectionStoragePath(): StoragePath { return self.CollectionStoragePath }
    pub fun getDefaultCollectionPublicPath(): PublicPath { return self.CollectionPublicPath }

    pub event DepositFungibleTokens(identifier: String, amount: UFix64)
    pub event WithdrawFungibleTokens(identifier: String, amount: UFix64)
    pub event DepositNonFungibleTokens(identifier: String, ids: [UInt64])
    pub event WithdrawNonFungibleTokens(identifier: String, ids: [UInt64])

    // BasketPublic
    //
    // allows access to read the metadata and ipfs pin of the nft
    pub resource interface BasketPublic {
        pub fun getBalances() : {String: UFix64}
        pub fun getNFTs() : {String: [UInt64]}
        pub fun depositNonFungibleTokens( from: @NonFungibleToken.Collection )
        pub fun depositFungibleTokens( from: @FungibleToken.Vault )
    }

    // BasketOwner Interface 
    //
    // capability to access these functions can be given to other users by sharing a private capability
    pub resource interface BasketOwner {
        pub fun depositFungibleTokens( from: @FungibleToken.Vault )
        pub fun withdrawFungibleTokens( identifier: String, amount: UFix64 ) : @FungibleToken.Vault 
        pub fun depositNonFungibleTokens( from: @NonFungibleToken.Collection )
        pub fun withdrawNonFungibleTokens( targetCollection: @NonFungibleToken.Collection, ids: [UInt64] ) : @NonFungibleToken.Collection 
    } 

    pub resource NFT: NonFungibleToken.INFT, BasketPublic, MetadataViews.Resolver, BasketOwner {
        pub let id: UInt64
        access(contract) let vaults: @{String: FungibleToken.Vault}
        access(contract) let collections: @{String: NonFungibleToken.Collection}
        access(contract) let metadata: {String: AnyStruct}
        access(self) let royalties: [MetadataViews.Royalty]

        init(initID: UInt64) {
            self.id = initID
            self.vaults <- {}
            self.collections <- {}
            self.metadata = {"mintedTime": getCurrentBlock().timestamp}
            self.royalties = []
        }

        destroy() {
            destroy self.vaults
            destroy self.collections
        }

        /// Function that returns all the Metadata Views implemented by a Non Fungible Token
        ///
        /// @return An array of Types defining the implemented views. This value will be used by
        ///         developers to know which parameter to pass to the resolveView() method.
        ///
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

        /// Function that resolves a metadata view for this token.
        ///
        /// @param view: The Type of the desired view.
        /// @return A structure representing the requested view.
        ///
        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "Basket",
                        description: "Basket is a NonFungibleToken that holds any number of NonFungibleToken Collections and FungibleTokens Vaults",
                        thumbnail: MetadataViews.HTTPFile(
                            url: Basket.getThumbnailURL()
                        )
                    )
                case Type<MetadataViews.Editions>():
                    let editionInfo = MetadataViews.Edition(name: "Basket NFT Edition", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.ExternalURL>():
                    return MetadataViews.ExternalURL("https://basket-sable.vercel.app/")
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Basket.CollectionStoragePath,
                        publicPath: Basket.CollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&Basket.Collection{Basket.BasketCollectionPublic}>(),
                        publicLinkedType: Type<&Basket.Collection{Basket.BasketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Basket.Collection{Basket.BasketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Basket.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: "https://basket-sable.vercel.app/_app/immutable/assets/basket-icon.41a9e902.svg"
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Basket Collection",
                        description: "Basket NFT Collection.",
                        externalURL: MetadataViews.ExternalURL("https://basket-sable.vercel.app/"),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/__basket__")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    // exclude mintedTime and foo to show other uses of Traits
                    let balances = self.getBalances()
                    let nfts = self.getNFTs()
                    let traitsView = MetadataViews.dictToTraits(dict: {
                        "Fungible Tokens": balances.keys,
                        "Non-Fungible Token Collections": nfts.keys,
                        "Fungible Token Balances": balances,
                        "Non-Fungible Token with IDs": nfts
                    }, excludedNames: nil)

                    // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
                    let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
                    traitsView.addTrait(mintedTimeTrait)
                    
                    return traitsView
                }
                return nil
            }
        

        pub fun getBalances() : {String : UFix64} {
            let balances: {String:UFix64} = {}
            for key in self.vaults.keys {
                balances.insert(key: key, self.vaults[key]?.balance!)
            }
            return balances
        }

        pub fun getNFTs() : {String : [UInt64]} {
            let nftIDs: {String:[UInt64]} = {}
            for key in self.collections.keys {
                nftIDs.insert(key: key, self.collections[key]?.getIDs()!)
            }
            return nftIDs
        }

        pub fun getCollectionViews(): AnyStruct {
            let collectionViews: {String: AnyStruct} = {}

            for key in self.collections.keys {
                let collectionRef = &self.collections[key] as &NonFungibleToken.Collection?
                let addr = Address.fromString("0x".concat(key.slice(from: 2, upTo: 18)))!
                let contractName = key.slice(from: 19, upTo: key.length - 11)
                let borrowedContract = getAccount(addr).contracts.borrow<&ViewResolver>(name: contractName) // ?? panic("contract could not be borrowed")
                
                if borrowedContract != nil {
                    collectionViews[key] = {"NFTCollectionData": borrowedContract?.resolveView(Type<MetadataViews.NFTCollectionData>())!, "NFTCollectionDisplay": borrowedContract?.resolveView(Type<MetadataViews.NFTCollectionDisplay>())!}
                }
            }
            return collectionViews
        }

        pub fun getNFTViews(key: String): AnyStruct {
            // get collection ref
            let collectionRef = &self.collections[key] as &NonFungibleToken.Collection?
            if (collectionRef == nil) {
                log("invalid collection ref returning" )
                return nil
            }

            let nftViews: {String: AnyStruct} = {}
            for id in collectionRef!.getIDs() {
                log("nft")
                log(id)

                let nftRef = collectionRef?.borrowNFT!(id: id) // as! auth &AnyResource{MetadataViews.Resolver} 
                // let viewResolver = nftRef.borrowViewResolver(id: id)
                log(nftRef)

                log(nftRef.getType())
                let nftType = nftRef.getType()
                nftViews[id.toString()] =nftRef
            }
            return nftViews
        }

        // pub fun getVaultViews()

        pub fun depositFungibleTokens(from: @FungibleToken.Vault) {
            let identifier = from.getType().identifier
            let balance = from.balance
            if self.vaults[identifier] == nil {
                self.vaults[identifier] <-! from
            } else {
                let depositRef = &self.vaults[identifier] as &FungibleToken.Vault?
                depositRef!.deposit(from: <- from)
            }
            emit DepositFungibleTokens(identifier: identifier, amount: balance)
        }

        pub fun withdrawFungibleTokens( identifier: String, amount: UFix64 ) : @FungibleToken.Vault {
            pre {
                self.vaults.containsKey(identifier) : "Not tokens with that identifier stored in this VaultNFT"
                amount <= self.vaults[identifier]?.balance! : "Insufficient balance to withdraw requested amount"
            }
            return <- self.vaults[identifier]?.withdraw(amount: amount)!
        }

        pub fun depositNonFungibleTokens(from: @NonFungibleToken.Collection) {
            let identifier = from.getType().identifier
            let ids = from.getIDs()
            if self.collections[identifier] != nil {
                for id in ids {
                    self.collections[identifier]?.deposit(token: <- from.withdraw(withdrawID: id))
                }
                destroy from
            }  else {
                    self.collections[identifier] <-! from
            }
            emit DepositNonFungibleTokens(identifier: identifier, ids: ids)
        }

        // requires passing in a correctly typed targetCollection which receives the tokens and can be created in the transaction 
        pub fun withdrawNonFungibleTokens( targetCollection: @NonFungibleToken.Collection, ids: [UInt64] ) : @NonFungibleToken.Collection {
            pre {
                self.collections.containsKey(targetCollection.getType().identifier) : "Not tokens with that identifier stored in this Basket"
            }
            for id in ids {
                targetCollection.deposit(token: <- self.collections[targetCollection.getType().identifier]?.withdraw( withdrawID: id )!)
            }
            return <- targetCollection
        }

    }

    pub resource interface BasketCollectionPublic {
        pub fun borrowBasket(id: UInt64): &Basket.NFT?
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }

    // standard implmentation for managing a collection of NFTs
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, BasketCollectionPublic {
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
            let token <- token as! @Basket.NFT

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

        // borrowNFT gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            let nftRef = &self.ownedNFTs[id] as &NonFungibleToken.NFT?
            return nftRef!
        }

        // borrowBasket gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowBasket(id: UInt64): &Basket.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Basket.NFT
            }
            return nil
        }

        /// Gets a reference to the NFT only conforming to the `{MetadataViews.Resolver}`
        /// interface so that the caller can retrieve the views that the NFT
        /// is implementing and resolve them
        ///
        /// @param id: The ID of the wanted NFT
        /// @return The resource reference conforming to the Resolver interface
        /// 
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let vault = nft as! &Basket.NFT
            return vault as &AnyResource{MetadataViews.Resolver}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // public function that anyone can call to create a new empty collection
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub fun createEmptyBasket(): @NonFungibleToken.NFT {
        var newNFT <- create NFT(initID: Basket.totalSupply)
        Basket.totalSupply = Basket.totalSupply + 1
        return <- newNFT
    }

    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: Basket.CollectionStoragePath,
                    publicPath: Basket.CollectionPublicPath,
                    providerPath: /private/BasketCollection,
                    publicCollection: Type<&Basket.Collection{Basket.BasketCollectionPublic}>(),
                    publicLinkedType: Type<&Basket.Collection{Basket.BasketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                    providerLinkedType: Type<&Basket.Collection{Basket.BasketCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                    createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                        return <-Basket.createEmptyCollection()
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "https://basket-sable.vercel.app/_app/immutable/assets/basket-icon.41a9e902.svg"
                    ),
                    mediaType: "image/svg+xml"
                )
        }
        return nil
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    pub fun getViews(): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    pub fun getThumbnailURL(): String {
        return "https://basket-sable.vercel.app/_app/immutable/assets/basket-icon.41a9e902.svg"
    }

    init() {
        // Initialize the total supply
        self.totalSupply = 0

        // Initalize paths for scripts and transactions usage
        self.CollectionStoragePath = /storage/BasketNFTCollection
        self.CollectionPublicPath = /public/BasketCollection

        // Create a Collection resource and save it to storage
        let collection <- create Collection()
        self.account.save(<-collection, to: Basket.CollectionStoragePath)

        // create a public capability for the collection
        self.account.link<&{BasketCollectionPublic, NonFungibleToken.CollectionPublic}>(
            Basket.CollectionPublicPath,
            target: Basket.CollectionStoragePath
        )

        emit ContractInitialized()
    }
}
 