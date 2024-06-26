
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import Crypto

pub contract DriverzNFT: NonFungibleToken {

  // Events
  //
  // This contract is initialized
  pub event ContractInitialized()

  // NFT is minted
  pub event NFTMinted(
    nftID: UInt64,
    setID: UInt64,
    templateID: UInt64,
    displayName: String,
    displayDescription: String,
    displayURI: String,
    creator: Address,
  )

  // NFT is withdrawn from a collection
  pub event Withdraw(id: UInt64, from: Address?)

  // NFT is deposited from a collection
  pub event Deposit(id: UInt64, to: Address?)

  // NFT is destroyed
  pub event NFTDestroyed(id: UInt64)

  // NFT template metadata is revealed
  pub event NFTRevealed(
    nftID: UInt64,
    setID: UInt64,
    templateID: UInt64,
    displayName: String,
    displayDescription: String,
    displayURI: String,
    metadata: {String: String},
  )

  // Set has been created
  pub event SetCreated(setID: UInt64, metadata: SetMetadata)

  // Template has been added
  pub event TemplateAdded(setID: UInt64, templateID: UInt64, displayName: String, displayDescription: String, displayURI: String)

  // Set has been marked Locked
  pub event SetLocked(setID: UInt64, numTemplates: UInt64)

  // Paths
  //
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let CollectionPrivatePath: PrivatePath
  pub let AdminStoragePath: StoragePath

  // Total NFT supply
  pub var totalSupply: UInt64

  pub fun externalURL(): MetadataViews.ExternalURL {
    return MetadataViews.ExternalURL("https://driverz.world")
  }

  pub fun royaltyAddress(): Address {
    return 0xa039bd7d55a96c0c
  }

  pub fun squareImageCID(): String {
    return "QmV4FsnFiU7QY8ybwd5uuXwogVo9wcRExQLwedh7HU1mrU"
  }

  pub fun bannerImageCID(): String {
    return "QmYn6vg1pCuKb6jWT3SDHuyX4NDyJB4wvcYarmsyppoGDS"
  }

  // Total number of sets
  access(self) var totalSets: UInt64

  // Dictionary mapping from set IDs to Set resources
  access(self) var sets: @{UInt64: Set}

  // Template metadata can have custom definitions but must have the
  // following implemented in order to power all the features of the
  // NFT contract.
  pub struct interface TemplateMetadata {

    // Hash representation of implementing structs.
    pub fun hash(): [UInt8]

    // Representative Display
    pub fun display(): MetadataViews.Display

    // Representative {string: string} serialization
    pub fun repr(): {String: String}
  }

  pub struct DynamicTemplateMetadata: TemplateMetadata {
    access(self) let _display: MetadataViews.Display
    access(self) let _metadata: {String: String}

    pub fun hash(): [UInt8] {
      return []
    }

    pub fun display(): MetadataViews.Display {
      return self._display
    }

    pub fun repr(): {String: String} {
      return self.metadata()
    }

    pub fun metadata(): {String: String} {
      return self._metadata
    }

    init(display: MetadataViews.Display, metadata: {String: String}) {
      self._display = display
      self._metadata = metadata
    }
  }

  // NFT
  //
  // "Standard" NFTs that implement MetadataViews and point
  // to a Template struct that give information about the NFTs metadata
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

    // id is unique among all DriverzNFT NFTs on Flow, ordered sequentially from 0
    pub let id: UInt64

    // setID and templateID help us locate the specific template in the
    // specific set which stores this NFTs metadata
    pub let setID: UInt64
    pub let templateID: UInt64

    // The creator of the NFT
    pub let creator: Address

    // Fetch the metadata Template represented by this NFT
    pub fun template(): {NFTTemplate} {
      return DriverzNFT.getTemplate(setID: self.setID, templateID: self.templateID)
    }

    // Proxy for MetadataViews.Resolver.getViews implemented by Template
    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.NFTView>(),
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.NFTCollectionData>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
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
        case Type<MetadataViews.Display>():
          let template = self.template()
          if template.revealed() {
            return template.metadata!.display()
          }
          return template.defaultDisplay
        case Type<MetadataViews.Royalties>():
          let royalties: [MetadataViews.Royalty] = []
          let royaltyReceiverCap =
            getAccount(DriverzNFT.royaltyAddress()).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
          if royaltyReceiverCap.check() {
            royalties.append(
              MetadataViews.Royalty(
                  receiver: royaltyReceiverCap,
                  cut:  0.05,
                  description: "Creator royalty fee."
              )
            )
          }
          return MetadataViews.Royalties(royalties)
        case Type<MetadataViews.ExternalURL>():
          return DriverzNFT.externalURL()
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: DriverzNFT.CollectionStoragePath,
            publicPath: DriverzNFT.CollectionPublicPath,
            providerPath: DriverzNFT.CollectionPrivatePath,
            publicCollection: Type<@DriverzNFT.Collection>(),
            publicLinkedType: Type<&DriverzNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&DriverzNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(),
            createEmptyCollectionFunction: fun(): @NonFungibleToken.Collection{
              return <- DriverzNFT.createEmptyCollection()
            }
          )
        case Type<MetadataViews.NFTCollectionDisplay>():
          return MetadataViews.NFTCollectionDisplay(
            name: "Driverz",
            description: "An exclusive collection of energetic Driverz ready to vroom vroom on FLOW.",
            externalURL: DriverzNFT.externalURL(),
            squareImage:
              MetadataViews.Media(
                file: MetadataViews.IPFSFile(cid: DriverzNFT.squareImageCID(), path: nil),
                mediaType: "image/svg+xml"
              ),
            bannerImage:
              MetadataViews.Media(
                file: MetadataViews.IPFSFile(cid: DriverzNFT.bannerImageCID(), path: nil),
                mediaType: "image/svg+xml"
              ),
            socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/DriverzWorld/"),
                            "discord": MetadataViews.ExternalURL("https://discord.gg/driverz"),
                            "instagram": MetadataViews.ExternalURL("https://www.instagram.com/driverzworld/")
            }
          )
      }
      return nil
    }

    // NFT needs to be told which Template it follows
    init(setID: UInt64, templateID: UInt64, creator: Address) {
      self.id = DriverzNFT.totalSupply
      DriverzNFT.totalSupply = DriverzNFT.totalSupply + 1
      self.setID = setID
      self.templateID = templateID
      self.creator = creator
      let defaultDisplay = self.template().defaultDisplay
      emit NFTMinted(
        nftID: self.id,
        setID: self.setID,
        templateID: self.templateID,
        displayName: defaultDisplay.name,
        displayDescription: defaultDisplay.description,
        displayURI: defaultDisplay.thumbnail.uri(),
        creator: self.creator
      )
    }

    // Emit NFTDestroyed when destroyed
    destroy() {
      emit NFTDestroyed(
        id: self.id,
      )
    }
  }

  // Collection
  //
  // Collections provide a way for collectors to store DriverzNFT NFTs in their
  // Flow account.

  // Exposing this interface allows external parties to inspect a Flow
  // account's DriverzNFT Collection and deposit NFTs
  pub resource interface CollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowDriverzNFT(id: UInt64): &NFT
  }

  pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

    // NFTs are indexed by its globally assigned id
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    // Deposit a DriverzNFT into the collection. Safe to assume id's are unique.
    pub fun deposit(token: @NonFungibleToken.NFT) {
      // Required to ensure this is a DriverzNFT
      let token <- token as! @DriverzNFT.NFT
      let id: UInt64 = token.id
      let oldToken <- self.ownedNFTs[id] <- token
      emit Deposit(id: id, to: self.owner?.address)
      destroy oldToken
    }

    // Withdraw an NFT from the collection.
    // Panics if NFT does not exist in the collection
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      pre {
        self.ownedNFTs.containsKey(withdrawID)
          : "NFT does not exist in collection."
      }
      let token <- self.ownedNFTs.remove(key: withdrawID)!
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <-token
    }

    // Return all the IDs from the collection.
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    // Borrow a reference to the specified NFT
    // Panics if NFT does not exist in the collection
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      pre {
        self.ownedNFTs.containsKey(id)
          : "NFT does not exist in collection."
      }
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    // Borrow a reference to the specified NFT as a DriverzNFT.
    // Panics if NFT does not exist in the collection
    pub fun borrowDriverzNFT(id: UInt64): &NFT {
      pre {
        self.ownedNFTs.containsKey(id)
          : "NFT does not exist in collection."
      }
      let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      return ref as! &NFT
    }

    // Return the MetadataViews.Resolver of the specified NFT
    // Panics if NFT does not exist in the collection
    pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
      pre {
        self.ownedNFTs.containsKey(id)
          : "NFT does not exist in collection."
      }
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let typedNFT = nft as! &NFT
      return typedNFT
    }

    init() {
      self.ownedNFTs <- {}
    }

    // If the collection is destroyed, destroy the NFTs it holds, as well
    destroy() {
      destroy self.ownedNFTs
    }
  }

  // Anyone can make and store collections
  pub fun createEmptyCollection(): @Collection {
    return <-create Collection()
  }

  pub resource Set {

    // Globally assigned id based on number of created Sets.
    pub let id: UInt64

    pub var isLocked: Bool

    // Metadata for the Set
    pub var metadata: SetMetadata

    // Templates configured to be minted from this Set
    access(contract) var templates: [Template]

    // Number of NFTs that have minted from this Set
    pub var minted: UInt64

    // Add a new Template to the Set, only if the Set is Open
    pub fun addTemplate(template: Template) {
      pre {
        !self.isLocked : "Set is locked. It cannot be modified"
      }
      let templateID = self.templates.length
      self.templates.append(template)

      let display = template.defaultDisplay
      emit TemplateAdded(setID: self.id, templateID: UInt64(templateID), displayName: display.name, displayDescription: display.description, displayURI: display.thumbnail.uri())
    }

    // Lock the Set if it is Open. This signals that this Set
    // will mint NFTs based only on the Templates configured in this Set.
    pub fun lock() {
      pre {
        !self.isLocked : "Only an Open set can be locked."
        self.templates.length > 0
          : "Set must be configured with at least one Template."
      }
      self.isLocked = true
      emit SetLocked(setID: self.id, numTemplates: UInt64(self.templates.length))
    }

    // Mint numToMint NFTs with the supplied creator attribute. The NFT will
    // be minted into the provided receiver
    pub fun mint(
      templateID: UInt64,
      creator: Address
    ): @NFT {
      pre {
        templateID < UInt64(self.templates.length)
          : "templateID does not exist in Set."
        self.templates[templateID].mintID == nil
          : "Template has already been marked as minted."
      }
      let nft <-create NFT(
          setID: self.id,
          templateID: templateID,
          creator: creator
        )
      self.templates[templateID].markMinted(nftID: nft.id)
      self.minted = self.minted + 1
      return <- nft
    }

    // Reveal a specified Template in a Set.
    pub fun revealTemplate(
      templateID: UInt64,
      metadata: {TemplateMetadata},
      salt: [UInt8]
    ) {
      pre {
        templateID < UInt64(self.templates.length)
          : "templateId does not exist in Set."
        self.templates[templateID].mintID != nil
          : "Template has not been marked as minted."
      }
      let template = &self.templates[templateID] as &Template
      template.reveal(metadata: metadata, salt: salt)

      let display = metadata.display()
      emit NFTRevealed(
        nftID: template.mintID!,
        setID: self.id,
        templateID: templateID,
        displayName: display.name,
        displayDescription: display.description,
        displayURI: display.thumbnail.uri(),
        metadata: metadata.repr(),
      )
    }

    init(id: UInt64, metadata: SetMetadata) {
      self.id = id
      self.metadata = metadata

      self.isLocked = false
      self.templates = []

      self.minted = 0
      emit SetCreated(setID: id, metadata: metadata)
    }
  }

  // Create and store a new Set. Return the id of the new Set.
  access(contract) fun createSet(metadata: SetMetadata): UInt64 {
    let setID = DriverzNFT.totalSets

    let newSet <- create Set(
      id: setID,
      metadata: metadata
    )
    DriverzNFT.sets[setID] <-! newSet
    DriverzNFT.totalSets = DriverzNFT.totalSets + 1
    return setID
  }

  // Number of sets created by contract
  pub fun setsCount(): UInt64 {
    return DriverzNFT.totalSets
  }

  // Metadata for the Set
  pub struct SetMetadata {
    pub var name: String
    pub var description: String
    pub var externalID: String

    init(name: String, description: String, externalID: String) {
      self.name = name
      self.description = description
      self.externalID = externalID
    }
  }

  // A summary report of a Set
  pub struct SetReport {
    pub let id: UInt64
    pub let isLocked: Bool
    pub let metadata: SetMetadata
    pub let numTemplates: Int
    pub let numMinted: UInt64
    init(
      id: UInt64,
      isLocked: Bool,
      metadata: SetMetadata,
      numTemplates: Int,
      numMinted: UInt64
    ) {
      self.id = id
      self.isLocked = isLocked
      self.metadata = metadata
      self.numTemplates = numTemplates
      self.numMinted = numMinted
    }
  }

  // Generate a SetReport for informational purposes (to be used with scripts)
  pub fun generateSetReport(setID: UInt64): SetReport {
    let setRef = (&self.sets[setID] as &Set?)!
    return SetReport(
      id: setID,
      isLocked: setRef.isLocked,
      metadata: setRef.metadata,
      numTemplates: setRef.templates.length,
      numMinted: setRef.minted
    )
  }

  // Template
  //
  // Templates are mechanisms for handling NFT metadata. These should ideally
  // have a one to one mapping with NFTs, with the assumption that NFTs are
  // designed to be unique. Template allows the creator to commit to an NFTs
  // metadata without having to reveal the metadata itself. The constructor
  // accepts a byte array checksum. After construction, anyone with access
  // to this struct will be able to reveal the metadata, which must be any
  // struct which implements TemplateMetadata and MetadataViews.Resolver such that
  // SHA3_256(salt || metadata.hash()) == checksum.
  //
  // Templates can be seen as metadata managers for NFTs. As such, Templates
  // also implement the MetadataResolver interface to conform with standards.

  // Safe Template interface for anyone inspecting NFTs
  pub struct interface NFTTemplate {
    pub let defaultDisplay: MetadataViews.Display
    pub var metadata: {TemplateMetadata}?
    pub var mintID: UInt64?
    pub fun checksum(): [UInt8]
    pub fun salt(): [UInt8]?
    pub fun revealed(): Bool
  }

  pub struct Template: NFTTemplate {

    // checksum as described above
    access(self) let _checksum: [UInt8]

    // Default Display in case the Template has not yet been revealed
    pub let defaultDisplay: MetadataViews.Display

    // salt and metadata are optional so they can be revealed later, such that
    // SHA3_256(salt || metadata.hash()) == checksum
    access(self) var _salt: [UInt8]?
    pub var metadata: {TemplateMetadata}?

    // Convenience attribute to mark whether or not Template has minted NFT
    pub var mintID: UInt64?

    // Helper function to check if a proposed metadata and salt reveal would
    // produce the configured checksum in a Template
    pub fun validate(metadata: {TemplateMetadata}, salt: [UInt8]): Bool {
      let hash = String.encodeHex(
        HashAlgorithm.SHA3_256.hash(
          salt.concat(metadata.hash())
        )
      )
      let checksum = String.encodeHex(self.checksum())
      return hash == checksum
    }

    // Reveal template metadata and salt. validate() is called as a precondition
    // so collector can be assured metadata was not changed
    pub fun reveal(metadata: AnyStruct{TemplateMetadata}, salt: [UInt8]) {
      pre {
        self.mintID != nil
          : "Template has not yet been minted."
        !self.revealed()
          : "NFT Template has already been revealed"
        self.validate(metadata: metadata, salt: salt)
          : "salt || metadata.hash() does not hash to checksum"
      }
      self.metadata = metadata
      self._salt = salt
    }

    pub fun checksum(): [UInt8] {
      return self._checksum
    }

    pub fun salt(): [UInt8]? {
      return self._salt
    }

    // Check to see if metadata has been revealed
    pub fun revealed(): Bool {
      return self.metadata != nil
    }

    // Mark the NFT as minted
    pub fun markMinted(nftID: UInt64) {
      self.mintID = nftID
    }

    init(checksum: [UInt8], defaultDisplay: MetadataViews.Display) {
      self._checksum = checksum
      self.defaultDisplay = defaultDisplay

      self._salt = nil
      self.metadata = nil
      self.mintID = nil
    }
  }

  // Public helper function to be able to inspect any Template
  pub fun getTemplate(setID: UInt64, templateID: UInt64): {NFTTemplate} {
    let setRef = (&self.sets[setID] as &Set?)!
    return setRef.templates[templateID]
  }

  pub resource SetMinter {
    pub let setID: UInt64

    init(setID: UInt64) {
      self.setID = setID
    }

    pub fun mint(templateID: UInt64, creator: Address): @NFT {
      let set = (&DriverzNFT.sets[self.setID] as &Set?)!
      return <- set.mint(templateID: templateID, creator: creator)
    }
  }

  // Admin
  //
  // The Admin is meant to be a singleton superuser of the contract. The Admin
  // is responsible for creating Sets and SetManagers for managing the sets.
  pub resource Admin {

    // Create a set with the provided SetMetadata.
    pub fun createSet(metadata: SetMetadata): UInt64 {
      return DriverzNFT.createSet(metadata: metadata)
    }

    pub fun borrowSet(setID: UInt64): &Set {
      return (&DriverzNFT.sets[setID] as &Set?)!
    }

    pub fun createSetMinter(setID: UInt64): @SetMinter {
      return <- create SetMinter(setID: setID)
    }
  }

  // Contract constructor
  init() {

    // Collection Paths
    self.CollectionStoragePath = /storage/DriverzNFTCollection
    self.CollectionPublicPath = /public/DriverzNFTCollection
    self.CollectionPrivatePath = /private/DriverzNFTCollection

    // Admin Storage Path. Save the singleton Admin resource to contract
    // storage.
    self.AdminStoragePath = /storage/DriverzNFTAdmin
    self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)

    // Initializations
    self.totalSupply = 0
    self.totalSets = 0
    self.sets <- {}

    emit ContractInitialized()
  }
}
