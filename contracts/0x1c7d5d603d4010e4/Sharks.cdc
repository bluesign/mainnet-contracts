// Description: Smart Contract for Sharks Virtual Commemorative Tickets
// SPDX-License-Identifier: UNLICENSED


import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

pub contract Sharks : NonFungibleToken{
    
    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub resource NFT : NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64
        pub var link: String
        pub var batch: UInt32
        pub var sequence: UInt16
        pub var limit: UInt16
    
        init(
            initID: UInt64,
            initlink: String,
            initbatch: UInt32,
            initsequence: UInt16,
            initlimit: UInt16
        ) {
            self.id = initID
            self.link = initlink
            self.batch = initbatch
            self.sequence = initsequence
            self.limit = initlimit
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.NFTCollectionData>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: Sharks.CollectionStoragePath,
                        publicPath: Sharks.CollectionPublicPath,
                        providerPath: /private/SharksCollection,
                        publicCollection: Type<&Sharks.Collection{Sharks.SharksCollectionPublic}>(),
                        publicLinkedType: Type<&Sharks.Collection{Sharks.SharksCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&Sharks.Collection{Sharks.SharksCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-Sharks.createEmptyCollection()
                        })
                    )

            }

            return nil
        }
    }

    pub resource interface SharksCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSharks(id: UInt64): &Sharks.NFT? {
    
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Sharks reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: SharksCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)!
            
            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Sharks.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }


        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!  
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        destroy() {
            destroy self.ownedNFTs
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let sharksNFT = nft as! &Sharks.NFT
            return sharksNFT as &AnyResource{MetadataViews.Resolver}
        }

        pub fun borrowSharks(id: UInt64): &Sharks.NFT? {
            if self.ownedNFTs[id] == nil {
                return nil
            } 
            else {
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Sharks.NFT
            }
        }

    }

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }
 
    pub resource NFTMinter {
        pub var minterID: UInt64
        
        init() {
            self.minterID = 0    
        }

        pub fun mintNFT(glink: String, gbatch: UInt32, glimit: UInt16, gsequence:UInt16): @NFT {
            let tokenID = (UInt64(gbatch) << 32) | (UInt64(glimit) << 16) | UInt64(gsequence)
            var newNFT <- create NFT(initID: tokenID, initlink: glink, initbatch: gbatch, initsequence: gsequence, initlimit: glimit)
    
            self.minterID= tokenID
            Sharks.totalSupply = Sharks.totalSupply + UInt64(1)
            return <-newNFT
        }
    }

	init() {
        self.CollectionStoragePath = /storage/SharksCollection
        self.CollectionPublicPath = /public/SharksCollection
        self.MinterStoragePath = /storage/SharksMinter

        self.totalSupply = 0		
        self.account.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)

        self.account.link<&{Sharks.SharksCollectionPublic, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )
        self.account.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
 
 