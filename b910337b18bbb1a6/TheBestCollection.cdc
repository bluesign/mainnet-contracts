
  import NonFungibleToken from ../0x1d7e57aa55817448;/NonFungibleToken.cdc
  import MetadataViews from ../0x1d7e57aa55817448;/MetadataViews.cdc
  
  pub contract TheBestCollection: NonFungibleToken {
  
    pub var totalSupply: UInt64
  
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
  
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
  
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
      pub let id: UInt64
  
      pub let name: String
      pub let description: String
      pub let thumbnail: String
      pub let metadata: {String: AnyStruct}
  
      init(
          id: UInt64,
          name: String,
          description: String,
          thumbnail: String,
          metadata: {String: AnyStruct},
      ) {
          self.id = id
          self.name = name
          self.description = description
          self.thumbnail = thumbnail
          self.metadata = metadata
      }
  
      pub fun getViews(): [Type] {
        return [
          Type<MetadataViews.Display>()
        ]
      }
  
      pub fun resolveView(_ view: Type): AnyStruct? {
        switch view {
          case Type<MetadataViews.Display>():
            return MetadataViews.Display(
              name: self.name,
              description: self.description,
              thumbnail: MetadataViews.HTTPFile(
                url: self.thumbnail
              )
            )
        }
        return nil
      }
    }
  
    pub resource interface TheBestCollectionCollectionPublic {
      pub fun deposit(token: @NonFungibleToken.NFT)
      pub fun getIDs(): [UInt64]
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    }
  
    pub resource Collection: TheBestCollectionCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
      pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
  
      init () {
        self.ownedNFTs <- {}
      }
  
      pub fun getIDs(): [UInt64] {
        return self.ownedNFTs.keys
      }
      
      pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
  
        emit Withdraw(id: token.id, from: self.owner?.address)
  
        return <-token
      }
  
      pub fun deposit(token: @NonFungibleToken.NFT) {
        let token <- token as! @TheBestCollection.NFT
  
        let id: UInt64 = token.id
  
        let oldToken: @NonFungibleToken.NFT? <- self.ownedNFTs[id] <- token
  
        emit Deposit(id: id, to: self.owner?.address)
  
        destroy oldToken
      }
  
      pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
        return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
      }
  
      pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let TheBestCollection = nft as! &TheBestCollection.NFT
        return TheBestCollection as &AnyResource{MetadataViews.Resolver}
      }
  
      destroy() {
        destroy self.ownedNFTs
      }
    }
  
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
      return <- create Collection()
    }
    pub resource NFTMinter {
    pub fun mintNFT(
      recipient: &{NonFungibleToken.CollectionPublic},
      name: String,
      description: String,
      thumbnail: String,
      metadata: {String: AnyStruct}
    ) {
      var newNFT <- create NFT(
        id: TheBestCollection.totalSupply,
        name: name,
        description: description,
        thumbnail: thumbnail,
        metadata: metadata,
      )
  
      recipient.deposit(token: <-newNFT)
  
      TheBestCollection.totalSupply = TheBestCollection.totalSupply + 1
    }
    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.NFTCollectionData>():
              return MetadataViews.NFTCollectionData(
                  storagePath: TheBestCollection.CollectionStoragePath,
                  publicPath: TheBestCollection.CollectionPublicPath,
                  providerPath: /private/TheBestCollectionCollection,
                  publicCollection: Type<&TheBestCollection.Collection{TheBestCollection.TheBestCollectionCollectionPublic}>(),
                  publicLinkedType: Type<&TheBestCollection.Collection{TheBestCollection.TheBestCollectionCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                  providerLinkedType: Type<&TheBestCollection.Collection{TheBestCollection.TheBestCollectionCollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                  createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                      return <-TheBestCollection.createEmptyCollection()
                  })
              )
      }
      return nil
  }
}
  /// Function that returns all the Metadata Views implemented by a Non Fungible Token
  ///
  /// @return An array of Types defining the implemented views. This value will be used by
  ///         developers to know which parameter to pass to the resolveView() method.
  ///
  pub fun getViews(): [Type] {
      return [
          Type<MetadataViews.NFTCollectionData>()
      ]
  }
  
    init() {
      self.totalSupply = 0
  
      self.CollectionStoragePath = /storage/TheBestCollectionCollection
      self.CollectionPublicPath = /public/TheBestCollectionCollection
      self.MinterStoragePath = /storage/TheBestCollectionMinter
  
      let collection <- create Collection()
      self.account.save(<-collection, to: self.CollectionStoragePath)
  
      self.account.link<&TheBestCollection.Collection{NonFungibleToken.CollectionPublic, TheBestCollection.TheBestCollectionCollectionPublic, MetadataViews.ResolverCollection}>(
        self.CollectionPublicPath,
        target: self.CollectionStoragePath
      )
      let minter <- create NFTMinter()
      self.account.save(<-minter, to: self.MinterStoragePath)
  
      emit ContractInitialized()
    }
  }