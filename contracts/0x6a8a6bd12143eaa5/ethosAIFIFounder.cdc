 /*
    Description: Central Smart Contract for ethosAIFIFounder
    
    This smart contract contains the core functionality for 
    ethosAIFIFounder, created by ethos Multiverse Inc.
    
    The contract manages the data associated with each NFT and 
    the distribution of each NFT to recipients.
    
    Admins throught their admin resource object have the power 
    to do all of the important actions in the smart contract such 
    as minting and batch minting.
    
    When NFTs are minted, they are initialized with a metadata object and then
    stored in the admins Collection.
    
    The contract also defines a Collection resource. This is an object that 
    every ethosAIFIFounder NFT owner will store in their account
    to manage their NFT collection.
    
    The main ethosAIFIFounder account operated by ethos Multiverse Inc. 
    will also have its own ethosAIFIFounder collection it can use to hold its 
    own NFT's that have not yet been sent to users.
    
    Note: All state changing functions will panic if an invalid argument is
    provided or one of its pre-conditions or post conditions aren't met.
    Functions that don't modify state will simply return 0 or nil 
    and those cases need to be handled by the caller.
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"


pub contract ethosAIFIFounder: NonFungibleToken {

  // -----------------------------------------------------------------------
  // ethosAIFIFounder contract Events
  // -----------------------------------------------------------------------

  // Emited when the ethosAIFIFounder contract is created
  pub event ContractInitialized()

  // Emmited when a user transfers a ethosAIFIFounder NFT out of their collection
  pub event Withdraw(id: UInt64, from: Address?)

  // Emmited when a user recieves a ethosAIFIFounder NFT into their collection
  pub event Deposit(id: UInt64, to: Address?)

  // Emmited when a ethosAIFIFounder NFT is minted
  pub event Minted(id: UInt64)

  // Emmited when a batch of ethosAIFIFounder NFTs are minted
  pub event BatchMint(metadatas: [{String: String}])

  // -----------------------------------------------------------------------
  // ethosAIFIFounder Named Paths
  // -----------------------------------------------------------------------

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath
  pub let AdminStoragePath: StoragePath
  pub let AdminPrivatePath: PrivatePath

  // -----------------------------------------------------------------------
  // ethosAIFIFounder contract-level fields.
  // These contain actual values that are stored in the smart contract.
  // -----------------------------------------------------------------------

  // Collection Information
  access(self) let collectionInfo: {String: AnyStruct}

  // Array of all existing ethosAIFIFounder NFTs
  access(self) var metadatas: [{String: String}]

  // The total number of ethosAIFIFounder NFTs that have been created
  // Because NFTs can be destroyed, it doesn't necessarily mean that this
  // reflects the total number of NFTs in existence, just the number that
  // have been minted to date. Also used as NFT IDs for minting.
  pub var totalSupply: UInt64

  // -----------------------------------------------------------------------
  // ethosAIFIFounder contract-level Composite Type definitions
  // -----------------------------------------------------------------------

  // The resource that represents the ethosAIFIFounder NFTs
  //
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
    pub let id: UInt64

    pub var metadata: {String: String}

    init(_metadata: {String: String}) {
      self.id = ethosAIFIFounder.totalSupply
      self.metadata = _metadata

      // Total Supply
      ethosAIFIFounder.totalSupply = ethosAIFIFounder.totalSupply + 1

      // Add the metadata to the metadatas array
      ethosAIFIFounder.metadatas.append(_metadata)

      // Emit Minted Event
      emit Minted(id: self.id)
    }

    pub fun getViews(): [Type] {
      return [
          Type<MetadataViews.Display>(),
          Type<MetadataViews.ExternalURL>(),
          Type<MetadataViews.NFTCollectionData>(),
          Type<MetadataViews.NFTCollectionDisplay>(),
          Type<MetadataViews.Royalties>(),
  				Type<MetadataViews.NFTView>()

      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      switch view {
          case Type<MetadataViews.Display>():
            return MetadataViews.Display(
                name: self.metadata["name"]!,
                description: self.metadata["description"]!,
                thumbnail: MetadataViews.HTTPFile(url: self.metadata["external_url"]!)
            )
          case Type<MetadataViews.ExternalURL>():
            return MetadataViews.ExternalURL("https://jade.ethosnft.com/collections/".concat(self.owner!.address.toString()).concat("/ethosAIFIFounder"))
          case Type<MetadataViews.NFTCollectionData>():
            return MetadataViews.NFTCollectionData(
                storagePath: ethosAIFIFounder.CollectionStoragePath,
                publicPath: ethosAIFIFounder.CollectionPublicPath,
                providerPath: ethosAIFIFounder.CollectionPrivatePath,
						    publicCollection: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
						    publicLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
						    providerLinkedType: Type<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, NonFungibleToken.Provider}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                  return <- ethosAIFIFounder.createEmptyCollection()
                })
            )
          case Type<MetadataViews.NFTCollectionDisplay>():
            let squareMedia: MetadataViews.Media = MetadataViews.Media(
              file: ethosAIFIFounder.getCollectionAttribute(key: "image") as! MetadataViews.HTTPFile,
              mediaType: "image"
            )

            // Check if banner image exists
            var bannerMedia: MetadataViews.Media? = nil
            if let bannerImage: MetadataViews.IPFSFile = ethosAIFIFounder.getCollectionAttribute(key: "bannerImage") as! MetadataViews.IPFSFile? {
              bannerMedia = MetadataViews.Media(
                file: bannerImage,
                mediaType: "image"
              )
            }
            return MetadataViews.NFTCollectionDisplay(
              name: ethosAIFIFounder.getCollectionAttribute(key: "name") as! String,
              description: ethosAIFIFounder.getCollectionAttribute(key: "description") as! String,
              externalURL: MetadataViews.ExternalURL("https://jade.ethosnft.com/collections/".concat(self.owner!.address.toString()).concat("/ethosAIFIFounder")),
              squareImage: squareMedia,
              bannerImage: bannerMedia ?? squareMedia,
              socials: ethosAIFIFounder.getCollectionAttribute(key: "socials") as! {String: MetadataViews.ExternalURL}
            )
          case Type<MetadataViews.Royalties>():
            return MetadataViews.Royalties([
              // For ethos Multiverse Inc. in favor of producing Jade, a tool for deploying NFT contracts and minting/managing collections.
              MetadataViews.Royalty(
                receiver: getAccount(0xeaf1bb3f70a73336).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver),
                cut: 0.025, // 2.5% on secondary sales
                description: "ethos Multiverse Inc. receives a 2.5% royalty from secondary sales because this collection was created using Jade (https://jade.ethosnft.com), a tool for deploying NFT contracts and minting/managing collections, created by ethos Multiverse Inc."
              )
            ])
          case Type<MetadataViews.NFTView>():
            return MetadataViews.NFTView(
              id: self.id,
              uuid: self.uuid,
						  display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?,
						  externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?,
						  collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?,
              collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?,
              royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?,
						  traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?
            )
      }
      return nil 
    }
  }

  // The interface that users can cast their ethosAIFIFounder Collection as
  // to allow others to deposit ethosAIFIFounder into thier Collection. It also
  // allows for the reading of the details of ethosAIFIFounder
  pub resource interface CollectionPublic {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowEntireNFT(id: UInt64): &ethosAIFIFounder.NFT?
  }

  // Collection is a resource that every user who owns NFTs
  // will store in their account to manage their NFTs
  pub resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, CollectionPublic, MetadataViews.ResolverCollection {
    // dictionary of NFT conforming tokens
    // NFT is a resource type with an UInt64 ID field
    //
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
    
    // withdraw
    // Removes an NFT from the collection and moves it to the caller
    //
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Token not found")
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <- token
    }

    // deposit
    // Takes a NFT and adds it to the collections dictionary
    //
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let myToken <- token as! @ethosAIFIFounder.NFT
      emit Deposit(id: myToken.id, to: self.owner?.address)
      self.ownedNFTs[myToken.id] <-! myToken
    }

    // getIDs returns an array of the IDs that are in the collection
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    // borrowNFT Returns a borrowed reference to a ethosAIFIFounder NFT in the Collection
    // so that the caller can read its ID
    //
    // Parameters: id: The ID of the NFT to get the reference for
    //
    // Returns: A reference to the NFT
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    // borrowEntireNFT returns a borrowed reference to a ethosAIFIFounder 
    // NFT so that the caller can read its data.
    // They can use this to read its id, description, and edition.
    //
    // Parameters: id: The ID of the NFT to get the reference for
    //
    // Returns: A reference to the NFT
    pub fun borrowEntireNFT(id: UInt64): &ethosAIFIFounder.NFT? {
      if self.ownedNFTs[id] != nil {
        let reference = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        return reference as! &ethosAIFIFounder.NFT
      } else {
        return nil
      }
    }

		pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
			let token = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = token as! &NFT
			return nft as &AnyResource{MetadataViews.Resolver}
		}

    init() {
      self.ownedNFTs <- {}
    }

    destroy() {
      destroy self.ownedNFTs 
    }
  }

  // Admin is a special authorization resource that
  // allows the owner to perform important NFT
  // functions
  pub resource Admin {
    // mint
    // Mints an new NFT
    // and deposits it in the Admins collection
    //
    pub fun mint(recipient: &{NonFungibleToken.CollectionPublic}, metadata: {String: String}) {
        // create a new NFT 
        var newNFT <- create NFT(_metadata: metadata)

        // Deposit it in Admins account using their reference
        recipient.deposit(token: <- newNFT)
    }

    // batchMint
    // Batch mints ethosAIFIFounder NFTs
    // and deposits in the Admins collection
    //
    pub fun batchMint(recipient: &{NonFungibleToken.CollectionPublic}, metadataArray: [{String: String}]) {
        var i: Int = 0
        while i < metadataArray.length {
            self.mint(recipient: recipient, metadata: metadataArray[i])
            i = i + 1;
        }
        emit BatchMint(metadatas: metadataArray)
    }

    // updateCollectionInfo
    // change piece of collection info
    pub fun updateCollectionInfo(key: String, value: AnyStruct) {
      ethosAIFIFounder.collectionInfo[key] = value
    }

    pub fun createNewAdmin(): @Admin {
        return <- create Admin()
    }
  }

  // The interface that Admins can use to give adminRights to other users
  pub resource interface AdminProxyPublic {
    pub fun giveAdminRights(cap: Capability<&Admin>)
  }

  // AdminProxy is a special procxy resource that
  // allows the owner to give adminRights to other users
  // to perform important NFT functions
  pub resource AdminProxy: AdminProxyPublic {
    access(self) var cap: Capability<&Admin>

    init() {
      self.cap = nil!
    }

    pub fun giveAdminRights(cap: Capability<&Admin>) {
      pre {
        self.cap == nil : "Capability is already set."
      }
      self.cap = cap
    }

    pub fun checkAdminRights(): Bool {
      return self.cap.check()
    }

    access(self) fun borrow(): &Admin {
      pre {
        self.cap != nil : "Capability is not set."
        self.checkAdminRights() : "Admin unliked capability."
      }
      return self.cap.borrow()!
    }

    pub fun mint(recipient: &{NonFungibleToken.CollectionPublic}, metadata: {String: String}) {
      let admin = self.borrow()
      admin.mint(recipient: recipient, metadata: metadata)
    }

    pub fun batchMint(recipient: &{NonFungibleToken.CollectionPublic}, metadataArray: [{String: String}]) {
      let admin = self.borrow()
      admin.batchMint(recipient: recipient, metadataArray:metadataArray)
    }

    pub fun updateCollectionInfo(key: String, value: AnyStruct) {
      let admin = self.borrow()
      admin.updateCollectionInfo(key: key, value: value)
    }
  }

  // -----------------------------------------------------------------------
  // ethosAIFIFounder contract-level function definitions
  // -----------------------------------------------------------------------

  // createEmptyCollection
  // public function that anyone can call to create a new empty collection
  //
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  // getNFTMetadata
  // public function that anyone can call to get information about a NFT
  //
  pub fun getNFTMetadata(_ metadataId: UInt64): {String: String} {
		return self.metadatas[metadataId]
  }

  // getNFTMetadatas
  // public function that anyone can call to get all NFT metadata
  pub fun getNFTMetadatas(): [{String: String}] {
		return self.metadatas
	}

  // getCollectionInfo
  // public function that anyone can call to get information about the collection
  //
  pub fun getCollectionInfo(): {String: AnyStruct} {
		let collectionInfo = self.collectionInfo
		collectionInfo["metadatas"] = self.metadatas
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["version"] = 1
		return collectionInfo
	}

  // getCollectionAttribute
  // public function that anyone can call to get a specific piece of collection info
  //
  pub fun getCollectionAttribute(key: String): AnyStruct {
		return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
	}

  // getOptionalCollectionAttribute
  // public function that anyone can call to get an optional piece of collection info
  //
  pub fun getOptionalCollectionAttribute(key: String): AnyStruct? {
		return self.collectionInfo[key]
	}

  // canMint
  // public function that anyone can call to check if the contract can mint more NFTs
  //
  pub fun canMint(): Bool {
		return self.getCollectionAttribute(key: "minting") as! Bool
	}



  // -----------------------------------------------------------------------
  // ethosAIFIFounder initialization function
  // -----------------------------------------------------------------------

  // initializer
  //
  init() {
    // Set contract level fields
    self.collectionInfo = {}
    self.collectionInfo["name"] = "ethosAIFIFounder"
    self.collectionInfo["description"] = "Collection of AIF I Founders NFTs"
    self.collectionInfo["image"] = MetadataViews.IPFSFile(cid: "", path: "")
		self.collectionInfo["ipfsCID"] = ""
		self.collectionInfo["minting"] = true
		self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
    self.totalSupply = 1
    self.metadatas = []

    // Set named paths
    self.CollectionStoragePath = /storage/ethosAIFIFounderCollection
    self.CollectionPublicPath = /public/ethosAIFIFounderCollection
    self.CollectionPrivatePath = /private/ethosAIFIFounderCollection
    self.AdminStoragePath = /storage/ethosAIFIFounderAdmin
    self.AdminPrivatePath = /private/ethosAIFIFounderAdminUpgrade

    // Create admin resource and save it to storage
    self.account.save(<-create Admin(), to: self.AdminStoragePath)

    // Create a Collection resource and save it to storage
    let collection <- create Collection()
    self.account.save(<-collection, to: self.CollectionStoragePath)

    // Create a public capability for the collection
    self.account.link<&ethosAIFIFounder.Collection{NonFungibleToken.CollectionPublic, ethosAIFIFounder.CollectionPublic, MetadataViews.ResolverCollection}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )

    // Create a private capability for the admin resource
    self.account.link<&ethosAIFIFounder.Admin>(self.AdminPrivatePath, target: self.AdminStoragePath) ?? panic("Could not get Admin capability")

    emit ContractInitialized()
  }
}
 