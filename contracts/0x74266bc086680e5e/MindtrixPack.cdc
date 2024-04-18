/*
MindtrixPack is an experimental contract to establish Fair Distribution.

Pack NFT is like a claim ticket to receive unpacked NFT.
To control when to unpack and mint Pack NFT, the contract creates a Tracker 
resource to record and update Pack's status, such as Sealed, Distributed, and Opened. 

To control what can be unpacked, the distributor creates MetadataHash of unpacked NFT 
off-chain and imports them into the contract. In the distribution phase, the contract 
will assign Pack a MetadataHash to map the one from the open pack tx.
If they are identical, it means that the rarity of each unpacked NFT has been consistent 
since distribution phase.

To make sure the distribution is random enough, we implement a pseudo-random generator 
from PRNG contract. Use the future block hash decided by all Pack holders and the tracker 
UUID as the two random seeds to prevent both contract deployer and buyer can predict 
the unpacking result during Public Sales. Also, when entering the distribution phase, 
Public Sales will be closed.
If the contract deployer changed their contract, the tx of updating the contract 
will be recorded on-chain.

Resources: 
1. NFT
It's Pack NFT as a claim ticket to receive unpacked NFT from Set owner.

2. Collection
It stores Pack NFTs for Pack owners to withdraw, deposit or view them.

3. Tracker
It records Pack status to determine when the Pack owner can use their Pack NFT to claim the unpacked NFT.
It records MetadataHash of unpacked NFT to verify the on-chain distribution.
It's stored in Set only accessed by Set owner.

4. Set
It allows the owner to create distributions containing Entity structs as templates that define what can be unpacked inside Pack NFT.
It allows the owner to perform minting, distributing, opening Pack operations.
It allows the owner to manage an allowlist to receive Pack NFT.
It stores Trackers to verify MetadataHash and Pack status when distributing and opening Pack NFT.

5. SetCollection
It stores the owner's Sets and Entities.
It allows the owner to create and mutate their Set and Entity

6. Admin
It's the Admin of MindtrixPack contract that defines who can create SetCollection.
*/

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import DapperUtilityCoin from "../0xead892083b3e2c6c/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"
import FiatToken from "../0xb19436aae4d94622/FiatToken.cdc"
import FUSD from "../0x3c5959b568896393/FUSD.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import MindtrixUtility from "./MindtrixUtility.cdc"
import MindtrixViews from "./MindtrixViews.cdc"
import MindtrixVerifier from "./MindtrixVerifier.cdc"
import MindtrixOtter from "./MindtrixOtter.cdc"
import PRNG from "../0x5d60e2a0dfe7a922/PRNG.cdc"

pub contract MindtrixPack: NonFungibleToken {

//========================================================
// EVENT
//========================================================

  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)

  pub event EntityCreated(setID: UInt64, entityID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64})
  pub event EntityUpdated(setID: UInt64, entityID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64})
  pub event EntityRetiredFromSet(setID: UInt64, entityID: UInt64, numNFTs: UInt64)

  pub event SetCreated(setID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64})
  pub event SetUpdated(setID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64})
  pub event SetLocked(setID: UInt64)
  pub event SetBurned(setID: UInt64)

  pub event PackCreated(packID: UInt64, setID: UInt64, entityID: UInt64)
  pub event PackDistributed(packID: UInt64, setID: UInt64, metadataHash: [UInt8])
  pub event PackOpened(packID: UInt64)
  pub event PackDestroyed(nftID: UInt64)

  pub event MetadataHashesImported(importedLen: UInt64, totalLen: UInt64)
  pub event MetadataHashesConsumerCopied(importedLen: UInt64, totalLen: UInt64)

  pub event AllowListAdded(address: Address, entityIDs: [UInt64])
  pub event AllowListRevoked(address: Address, entityIDs: [UInt64])
  pub event AllowListClaimed(address: Address, packID: UInt64)

//========================================================
// PATH
//========================================================

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let SetCollectionStoragePath: StoragePath
  pub let SetCollectionPublicPath: PublicPath
  pub let SetCollectionPrivatePath: PrivatePath
  pub let AdminStoragePath: StoragePath

//========================================================
// MUTABLE STATE
//========================================================

  pub var totalSupply: UInt64
  pub var nextEntityID: UInt64
  access(self) var beneficiaryAddress: Address
  access(self) var setIDToOwner: {UInt64: Address}
  access(self) var entityIDToOwner: {UInt64: Address}

//========================================================
// ENUM
//========================================================

  pub enum PackStatus: UInt8 {
    // "Sealed" is the default status of a minted Pack.
    pub case Sealed
    // "Distributed" means the contract has assigned metadata to the Pack as the rarity of its unpacked NFT.
    pub case Distributed
    // "Opened" is an irreversible status that the Pack holder has opened and received the concrete NFT.
    pub case Opened
  }

//========================================================
// STRUCT
//========================================================

  // Entity is the template of a Pack
  pub struct Entity {
    pub let setID: UInt64
    pub let entityID: UInt64

    access(self) let intMetadata: {String: UInt64}
    access(self) let fixMetadata: {String: UFix64}
    access(self) let strMetadata: {String: String}

    pub fun getIntMetadata(): {String: UInt64} {
      return self.intMetadata
    }

    pub fun getFixMetadata(): {String: UFix64} {
      return self.fixMetadata
    }

    pub fun getStrMetadata(): {String: String} {
      return self.strMetadata
    }      

    pub fun getPriceUSD(): UFix64? {
      return self.getFixMetadata()["price_usd"]
    }

    pub fun updateMetadata(strMetadata: {String: String}, intMetadata: {String: UInt64}) {
      for k in strMetadata.keys {
        self.strMetadata.insert(key: k, strMetadata[k]!)
      }

      for k in intMetadata.keys {
        self.intMetadata.insert(key: k, intMetadata[k]!)
      }
    }

    pub fun updatePrice(_ price_usd: UFix64){
      self.fixMetadata["price_usd"] = price_usd
    }

    pub fun updateMaxSupply(_ max_supply: UInt64){
      self.intMetadata["max_supply"] = max_supply
    }

    init(
      intMetadata: {String: UInt64},
      fixMetadata: {String: UFix64},
      strMetadata: {String: String},
      setID: UInt64,
      nextEntityID: UInt64) {
        pre {
          strMetadata.length != 0: "New Entity metadata cannot be empty"
        }
        self.entityID = nextEntityID
        self.intMetadata = intMetadata
        self.fixMetadata = fixMetadata
        self.setID = setID
        self.strMetadata = strMetadata
    }
  }

  // EntityVo contains essential fields of Entity for the viewer.
  pub struct EntityVo {
    pub let entityID: UInt64
    pub let name: String
    pub let description: String
    pub let externalURL: String
    pub let thumbnailURL: String
    pub let bannerURL: String
    pub let landmarkName: String
    pub var totalMinted: UInt64
    pub let maxSupply: UInt64
    pub let priceUSD: UFix64
    pub let traits: MetadataViews.Traits

    init(_ entityID: UInt64, _ packID: UInt64?) {

      let entity = MindtrixPack.getEntity(entityID: entityID)!
      let setID = entity.setID
      let entityMetadata = entity.getStrMetadata()
      let totalMinted = MindtrixPack.getEntityMintedNum(setID: setID, entityID: entityID) ?? 0      
      let setRef = MindtrixPack.borrowSetCollectionPublicRef(setID: setID).borrowSetPublic(setID: setID)
      let packStatus = packID != nil ? setRef.getTrackerStatus(packID: packID!) : PackStatus.Sealed

      self.entityID = entity.entityID
      self.name = entityMetadata["name"] ?? ""
      self.description = entityMetadata["description"] ?? ""
      self.externalURL = MindtrixPack.getExternalURL()
      self.thumbnailURL = packStatus == PackStatus.Opened ? entityMetadata["opened_img_url"] ?? "" : entityMetadata["unopened_img_url"] ?? ""
      self.bannerURL = entityMetadata["banner_url"] ?? ""
      self.landmarkName = entityMetadata["landmark_name"] ?? ""
      self.totalMinted = totalMinted
      self.maxSupply = setRef.getMaxSupplyFromSingleEntity(entityID: self.entityID) ?? entity.getIntMetadata()["max_supply"] ?? 0
      self.priceUSD = entity.getFixMetadata()["price_usd"] ?? 0.0
      let traits: [MetadataViews.Trait] = []
      let trait = MetadataViews.Trait(name: "Landmark", value: self.landmarkName, displayType:"String", rarity: nil)
      traits.append(trait)
      self.traits = MetadataViews.Traits(traits)
    }
  }

  // SetVo contains essential fields of Set for the viewer.
  pub struct SetVo {
    pub let setID: UInt64
    pub let name: String
    pub let description: String
    pub let externalURL: String
    pub let thumbnailURL: String
    pub let bannerURL: String
    pub var locked: Bool
    pub var totalMinted: UInt64

    access(self) var entities: [UInt64]
    access(self) var retiredEntities: {UInt64: Bool}
    access(self) var numMintedPerEntity: {UInt64: UInt64}

    init(_ setID: UInt64) {
      let set = MindtrixPack.borrowSetCollectionPublicRef(setID: setID).borrowSetPublic(setID: setID)
      let strMetadata = set.getStrMetadata()

      self.setID = setID
      self.name = strMetadata["name"] ?? ""
      self.description = strMetadata["description"] ?? ""
      self.externalURL = strMetadata["externalURL"] ?? ""
      self.thumbnailURL = strMetadata["thumbnailURL"] ?? ""
      self.bannerURL = strMetadata["bannerURL"] ?? ""
      self.locked = set.getLocked()
      self.totalMinted = set.getTotalMinted()
      self.entities = set.getEntityIDs()
      self.retiredEntities = set.getRetiredEntities()
      self.numMintedPerEntity = set.getNumMintedPerEntity()
    }

    // getEntityIDs returns the IDs of all the entities in the Set
    pub fun getEntityIDs(): [UInt64] {
      return self.entities
    }

    // getRetired returns a mapping of entity IDs to retired state
    pub fun getRetiredEntities(): {UInt64: Bool} {
      return self.retiredEntities
    }

    // getNumMintedPerEntity returns a mapping of entity IDs to the number of NFTs minted for that entity
    pub fun getNumMintedPerEntity(): {UInt64: UInt64} {
      return self.numMintedPerEntity
    }
  }

  // PackVo contains essential fields of Pack for the viewer.
  pub struct PackVo {
    pub let packID: UInt64
    pub let packStatus: PackStatus
    pub let name: String
    pub let metadataHashString: String?
    pub let minterAddress: Address
    pub let mintedTime: UFix64
    pub let serial: UInt64
    pub let setVo: SetVo
    pub let entityVo: EntityVo

    init(setID: UInt64, entityID: UInt64, packID: UInt64, packSerial: UInt64, packMinterAddress: Address, mintedTime: UFix64) {

      let entity = MindtrixPack.getEntity(entityID: entityID)!
      let setVo = MindtrixPack.SetVo(setID)
      let setRef = MindtrixPack.borrowSetCollectionPublicRef(setID: setVo.setID)
          .borrowSetPublic(setID: setVo.setID)
      let packStatus = setRef.getTrackerStatus(packID: packID)
      let packMetadataHashStringFromTracker = setRef.getTrackerMetadataHash(packID: packID)
      let packMetadataIndexFromTracker = setRef.getTrackerMetadataIndex(packID: packID)
      let updatedMaxSupply = MindtrixPack.getMaxSupplyFromSingleEntity(setID: entity.setID, entityID: entity.entityID)
      entity.updateMaxSupply(updatedMaxSupply)
      let entityVo = EntityVo(entityID, packID)

      let metadataHashString = packMetadataIndexFromTracker == nil ? nil : packMetadataHashStringFromTracker

      self.packID = packID
      self.packStatus = packStatus
      self.metadataHashString = metadataHashString
      self.name = entityVo.name.concat(" #").concat(packSerial.toString())
      self.serial = packSerial
      self.minterAddress = packMinterAddress
      self.mintedTime = mintedTime
      self.setVo = setVo
      self.entityVo = entityVo
    }
  }

//========================================================
// RESOURCE
//========================================================

  // Tracker records Pack status to determine when the buyer can use their Pack NFT to mint and receive the Otter NFT.
  pub resource Tracker: MindtrixViews.IHashVerifier {
    pub var id: UInt64
    pub let setID: UInt64
    pub let entityID: UInt64
    pub let packID: UInt64
    pub var metadataHash: [UInt8]
    pub let serial: UInt64
    pub var metadataHashIndex: UInt64?
    pub let issuer: Address
    pub var status: PackStatus

    init(issuer: Address, setID: UInt64, entityID: UInt64, packID: UInt64, serial: UInt64) {
      self.id = self.uuid
      self.setID = setID
      self.entityID = entityID
      self.packID = packID
      self.metadataHash = []
      self.serial = serial
      self.metadataHashIndex = nil
      self.status = PackStatus.Sealed
      self.issuer = issuer
    }

    pub fun updateStatusToDistributed(packID: UInt64, metadataHash: [UInt8]){
      pre {
        self.status != PackStatus.Opened : "Cannot revert the status from Opened to Distributed."
        self.status != PackStatus.Distributed : "The pack is alredy Distributed."
      }
      self.status = PackStatus.Distributed
      emit PackDistributed(packID: packID, setID: self.setID, metadataHash: metadataHash)
    }

    pub fun updateStatusToOpened(){
      pre {
        self.status != PackStatus.Sealed : "Cannot open the pack which is yet to be Distributed."
        self.status != PackStatus.Opened : "The pack is alredy Opened."
      }
      self.status = PackStatus.Opened
      emit PackOpened(packID: self.packID)
    }

    pub fun getMetadataHashIndex(): UInt64? {
      return self.metadataHashIndex
    }

    pub fun getMetadataHash(): [UInt8] {
      return self.metadataHash
    }

    // verifyHash verifies if the metadataHash generated from Otter NFT is identical to the Tracker's hash.
    // If they are identical, it means that the rarity of each Otter NFT has been consistent since Mindtrix distributed packs.
    // If they are different, it means someone changed the rarity to cause the mismatched metadataHash.
    // The generation process of metadataHash can be found in MindtrixUtility.cdc -> generateMetadataHash()
    // All this ensures the fairness of opening a Pack to get the unique Otter NFT.
    // It removes the possibility that anyone including Mindtrix team can manipulate the rarity behind the scenes.
    pub fun verifyHash(setID: UInt64, packID: UInt64, metadataHash: [UInt8]): Bool {
      let index = self.getMetadataHashIndex() ?? panic("The metadataHashIndex is yet to be assigned.")
      let isSetIDIdentical = self.setID == setID
      let isPackIDIdentical = self.packID == packID
      let metadataHashStringFromTracker = String.encodeHex(self.metadataHash)
      let matadataHashStringFromParams = String.encodeHex(metadataHash)
      let indexFromSet = MindtrixPack.getMetadataHashIndexByString(setID: setID, metadataHashedString: matadataHashStringFromParams)
      let isMetadataHashIdentical = metadataHashStringFromTracker == matadataHashStringFromParams && index == indexFromSet
      // store buyer's public key during Pack purchase.
      // in the tx, sign a random message from backend, and pass to this fun. then we use the target pub to verify the signature
      // using unpacker's public key to verify the signature generated during Pack purchase
      return isSetIDIdentical && isPackIDIdentical && isMetadataHashIdentical
    }

    access(account) fun distribute(metadataHashIndex: UInt64, metadataHash: [UInt8]): Bool {
      if (self.status != PackStatus.Sealed) || self.metadataHashIndex != nil {
        // skip the distributed packs
        return false
      } else {
        self.metadataHashIndex = metadataHashIndex
        self.metadataHash = metadataHash
        self.updateStatusToDistributed(packID: self.packID, metadataHash: self.metadataHash)
        return true
      }
    }
  }

  pub resource interface INFTPublic {
    pub let id: UInt64
    pub let setID: UInt64
    pub let entityID: UInt64
    pub let minterAddress: Address
    pub let mintedTime: UFix64
    pub let serial: UInt64
    pub fun getVo(): PackVo
  }

  // NFT is the Pack NFT.
  // Holders use Pack NFT to mint and get Otter NFT by passing verifications of Tracker stored in this contract.
  pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, INFTPublic {
    pub let id: UInt64
    pub let setID: UInt64
    pub let entityID: UInt64
    pub let minterAddress: Address
    pub let mintedTime: UFix64
    // The mint index number starts from 1.
    pub let serial: UInt64

    init(serial: UInt64, entityID: UInt64, setID: UInt64, minterAddress: Address) {
      MindtrixPack.totalSupply = MindtrixPack.totalSupply + UInt64(1)

      self.id = self.uuid
      self.serial = serial
      self.entityID = entityID
      self.setID = setID
      self.minterAddress = minterAddress
      self.mintedTime = getCurrentBlock().timestamp

      emit PackCreated(packID: self.id, setID: self.setID, entityID: self.entityID)
    }

    destroy() {
      emit PackDestroyed(nftID: self.id)
    }

    pub fun name(): String {
      let name: String = MindtrixPack.getEntityStrMetaDataByField(entityID: self.entityID, field: "name") ?? ""
      return name.concat(" #").concat(self.serial.toString())
    }

    pub fun getVo(): PackVo {
      return PackVo(
        setID: self.setID, 
        entityID: self.entityID, 
        packID: self.id,
        packSerial: self.serial, 
        packMinterAddress: self.minterAddress, 
        mintedTime: self.mintedTime)
    }

    pub fun getMedia(landmarkName: String, packStatus: PackStatus) : MetadataViews.Medias {
      let mediaURLDic: {String: {PackStatus: [String]}} = {
        "bush village": {
          PackStatus.Opened: ["https://bafybeie3cdgghiipgaesavnnns4kvqfzqqohbudhpsacqjjdpdz2sha4ly.ipfs.w3s.link/media_bush_village_open_1.jpg", "https://bafybeif62nxjtbfr7innbp5uxsbnj4ehzjzjfdcncgqzhzsn5xzyl2phce.ipfs.w3s.link/media_bush_village_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeiakloh64wsnmxiwwxue32yeh3i2pcmaewoynybhjhtd56zfhsqfwm.ipfs.w3s.link/media_bush_village_default_1.jpg", "https://bafybeid2j5pmtehyxjmxzkk4hfjslbtl7m3vw6lbuerwnutl3hej56ec6e.ipfs.w3s.link/media_bush_village_default_2.jpg"]
        },
        "echo cliff": {
          PackStatus.Opened: ["https://bafybeifkmy37gvuydlr34a57vmhv3pifuobdurhp4w25iu4gp3ldq4t33i.ipfs.w3s.link/media_echo_cliff_open_1.jpg", "https://bafybeig32nwwxygwyf7gajiaamo5wacz54ikiyxhkgbbs3z27ulbe5usfi.ipfs.w3s.link/media_echo_cliff_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeifvo5zgbebnqwba7fkkge4fmy7fbsjpohz3k56am4o5u2upxvqb7y.ipfs.w3s.link/media_echo_cliff_default_1.jpg", "https://bafybeibevrm5abxr36szvjwo3isfotn6czvym7cofbylpggdkcfpt3tc3m.ipfs.w3s.link/media_echo_cliff_default_2.jpg"]
        },
        "podment temple": {
          PackStatus.Opened: ["https://bafybeielwealoqjz7cihl3l2lioyevmp4hv6eqgnj2dntagnk7mbwcbddu.ipfs.w3s.link/media_podment_temple_open_1.jpg", "https://bafybeihf6ndpepif4tv77udpp4mnc4edosuj5mtn7nyqdrbskdxwv6u7ey.ipfs.w3s.link/media_podment_temple_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeigtjp3kzmrrzcpfymrizdzhdvwg7usecbtbjja4zkubjdscbb5tvm.ipfs.w3s.link/media_podment_temple_default_1.jpg", "https://bafybeidzvzg5aum5hzlnt542hyji3ua5fvjokbdjurlh66vashu4dwcata.ipfs.w3s.link/media_podment_temple_default_2.jpg"]
        },
        "green bazaar": {
          PackStatus.Opened: ["https://bafybeiaxabvir6oyp7nfn76zg2tugphwppyhhnx6uw5uhu7bxzezxiimkq.ipfs.w3s.link/media_green_bazaar_open_1.jpg", "https://bafybeigklewgn67knvvj6vgjcccmlrzvto4f5e2fjweoerqfhnqjv74kay.ipfs.w3s.link/media_green_bazaar_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeiejrt2iftiqbdxxfqvdrg34kja3p2cut2kfj3d4oq3ga5ejmjhcqe.ipfs.w3s.link/media_green_bazaar_default_1.jpg", "https://bafybeigyjo2z3sdththrz3k32bas2tv6ki7uifte42mtorw6eh3jrq3pyy.ipfs.w3s.link/media_green_bazaar_default_2.jpg"]
        },
        "kabbalah sacred trees": {
          PackStatus.Opened: ["https://bafybeicawrbep7tlxm5agmas53dmmspbbm7wis3rroimxmmclzmmbzg5iq.ipfs.w3s.link/media_kabbalah_sacred_trees_open_1.jpg", "https://bafybeih7gbamdfttpkoqwgujyk5avdnxmvv5pfezbmtix6s2vamutctl3y.ipfs.w3s.link/media_kabbalah_sacred_trees_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeifkfaltdn2dpokvqrlitadjkssmnbjddonfy4puzcqldkikcz6nsu.ipfs.w3s.link/media_kabbalah_sacred_trees_default_1.jpg", "https://bafybeihnkfa4mrtmst23ghvktrmsillrwbealzaexax3m7sb47ce2iv7cy.ipfs.w3s.link/media_kabbalah_sacred_trees_default_2.jpg"]
        },
        "mimir swamp": {
          PackStatus.Opened: ["https://bafybeihizzaimh6a4cdwsq42e4fqmt5u2xlzajaimpebpjp2vcr5ggzxry.ipfs.w3s.link/media_mimir_swamp_open_1.jpg", "https://bafybeia6mjkzxxc2tnwci5koasijtzo6brxcnyicphadoeupxfpsw7d4rq.ipfs.w3s.link/media_mimir_swamp_open_2.jpg"],
          PackStatus.Sealed: ["https://bafybeigass6kxaretip23m5xbu6n3u5f33aex4wvoqitaqxks767qdhxhm.ipfs.w3s.link/media_mimir_swamp_default_1.jpg", "https://bafybeiadckumpaf4ndvxsrtg3v6fddd5kbdzewewtboquqiya5p2uy3wdm.ipfs.w3s.link/media_mimir_swamp_default_2.jpg"]
        }
      }

      var medias: [MetadataViews.Media] = []
      let mediaURLs = mediaURLDic[landmarkName]![packStatus] ?? []
      for url in mediaURLs {
        medias.append(MetadataViews.Media(file: MetadataViews.HTTPFile(url: url), mediaType: "image/jpeg"))
      }
      return MetadataViews.Medias(items: medias)
    }

    pub fun getViews(): [Type] {
      return [
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>(),
        Type<MetadataViews.Display>(),
        Type<MetadataViews.Royalties>(),
        Type<MetadataViews.Serial>(),
        Type<MetadataViews.Edition>(),
        Type<MetadataViews.Traits>(),
        Type<MetadataViews.ExternalURL>(),
        Type<MetadataViews.Medias>()
      ]
    }

    pub fun resolveView(_ view: Type): AnyStruct? {
      let data = self.getVo()

      switch view {
        case Type<MetadataViews.NFTCollectionData>():
          return MetadataViews.NFTCollectionData(
            storagePath: MindtrixPack.CollectionStoragePath,
            publicPath: MindtrixPack.CollectionPublicPath,
            providerPath: /private/MindtrixPackCollection,
            publicCollection: Type<&MindtrixPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MindtrixPack.CollectionPublic, MetadataViews.ResolverCollection}>(),
            publicLinkedType: Type<&MindtrixPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MindtrixPack.CollectionPublic, MetadataViews.ResolverCollection}>(),
            providerLinkedType: Type<&MindtrixPack.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, MindtrixPack.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(),
            createEmptyCollection: (fun(): @NonFungibleToken.Collection {return <- MindtrixPack.createEmptyCollection()})
          )
        case Type<MetadataViews.NFTCollectionDisplay>():
          let squareImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: data.setVo.thumbnailURL),
            mediaType: "image"
          )
          let bannerImage = MetadataViews.Media(
            file: MetadataViews.HTTPFile(url: data.setVo.bannerURL),
            mediaType: "image"
          )
          return MetadataViews.NFTCollectionDisplay(
            name: "Mindtrix Pack",
            description: data.setVo.description,
            externalURL: MetadataViews.ExternalURL(MindtrixPack.getExternalURL()),
            squareImage: squareImage,
            bannerImage: bannerImage,
            socials: {
              "discord": MetadataViews.ExternalURL("https://link.mindtrix.xyz/Discord"),
              "instagram": MetadataViews.ExternalURL("https://www.instagram.com/mindtrix_dao"),
              "facebook": MetadataViews.ExternalURL("https://www.facebook.com/mindtrix.dao"),
              "twitter": MetadataViews.ExternalURL("https://twitter.com/mindtrix_dao")
            }
          )
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
            name: self.name(),
            description: data.entityVo.description,
            thumbnail: MetadataViews.HTTPFile(url: data.entityVo.thumbnailURL)
          )
        case Type<MetadataViews.Royalties>():
          let feeCut: UFix64 = 0.05
          let royalties : [MetadataViews.Royalty] = [
            MetadataViews.Royalty(
                receiver: getAccount(self.minterAddress).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!,
                cut: feeCut,
                description: "The first minter's royalty cut")
          ]
          return MetadataViews.Royalties(cutInfos: royalties)
        case Type<MetadataViews.Serial>():
          return MetadataViews.Serial(self.serial)
        case Type<MetadataViews.Edition>():
          return MetadataViews.Edition(
              name: data.setVo.name,
              number: self.serial,
              max: data.entityVo.maxSupply
          )
        case Type<MetadataViews.Traits>():
          return data.entityVo.traits
        case Type<MetadataViews.ExternalURL>():
          // TODO: show the specific Pack in the gallery site
          return MetadataViews.ExternalURL(MindtrixPack.getExternalURL())
        case Type<MetadataViews.Medias>():
          let landmarkName = data.entityVo.landmarkName.toLower()
          let packStatus = data.packStatus
          return self.getMedia(landmarkName: landmarkName, packStatus: packStatus)
      }
      return nil
    }
  }

  // Public interface for the MindtrixPack Collection that allows users access to certain functionalities
  pub resource interface CollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
    pub fun getIDs(): [UInt64]
    pub fun getUnopenedIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowMindtrixPackNFTPublic(id: UInt64): &MindtrixPack.NFT{INFTPublic}? {
      post {
        (result == nil) || (result?.id == id):
            "Cannot borrow MindtrixPack reference: The ID of the returned reference is incorrect"
      }
    }
    pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver}
  }

  // A collection of MindtrixPack NFTs owned by an account
  pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <-token
    }

    pub fun batchWithdraw(ids: [UInt64]): @NonFungibleToken.Collection {
      var batchCollection <- create Collection()
      for id in ids {
          batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
      }
      return <-batchCollection
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @MindtrixPack.NFT
      let id: UInt64 = token.id
      let oldToken <- self.ownedNFTs[id] <- token
      emit Deposit(id: id, to: self.owner?.address)
      destroy oldToken
    }

    pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {
      let keys = tokens.getIDs()
      for key in keys {
          self.deposit(token: <-tokens.withdraw(withdrawID: key))
      }
      destroy tokens
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    pub fun getUnopenedIDs(): [UInt64] {
      var ids: [UInt64] = []
      for id in self.ownedNFTs.keys {
        let pack = self.borrowMindtrixPackNFTPublic(id: id)!
        let packVo = MindtrixPack.PackVo(
          setID: pack.setID, 
          entityID: pack.entityID, 
          packID: pack.id,
          packSerial: pack.serial, 
          packMinterAddress: pack.minterAddress, 
          mintedTime: pack.mintedTime)
        if packVo.packStatus != MindtrixPack.PackStatus.Opened {
          ids.append(packVo.packID)
        }
      }
      return ids
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowMindtrixPackNFTPublic(id: UInt64): &MindtrixPack.NFT{MindtrixPack.INFTPublic}? {
      if self.ownedNFTs[id] != nil {
        let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let pack = ref as! &MindtrixPack.NFT
        let packPublic = pack as &MindtrixPack.NFT{MindtrixPack.INFTPublic}
        return packPublic
      } else {
          return nil
      }
    }

    pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
      let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      let mindtrixPackNFT = nft as! &MindtrixPack.NFT
      return mindtrixPackNFT as &{MetadataViews.Resolver}
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub resource interface ISetCollectionAdmin {
    access(contract) fun getMetadataHashesFromSet(setID: UInt64): [String]
    access(contract) fun getMetadataHashIndexFromSet(setID: UInt64, metadataHashedString: String): UInt64
    pub fun borrowSet(setID: UInt64): &Set
  }

  pub resource interface ISetCollectionPublic {
    pub fun borrowSetPublic(setID: UInt64): &{ISetPublic}
    pub fun getSetIDs(): [UInt64]
    pub fun getAllowListDic(setID: UInt64): {Address: [UInt64]}
    pub fun getAllowListPackVos(inboxAddress: Address, setID: UInt64): [MindtrixPack.PackVo]
    pub fun getEntityVo(entityID: UInt64): EntityVo?
    pub fun getEntity(entityID: UInt64): Entity?
    pub fun getEntityIDs(): [UInt64]
    pub fun getEntitiesMaxSupplyInSet(setID: UInt64): {UInt64: UInt64}
  }

  // SetCollection authorizes the owner to create, mutate their Set, Entity
  pub resource SetCollection: ISetCollectionPublic, ISetCollectionAdmin, MindtrixViews.IHashProvider {

    access(self) var sets: @{UInt64: Set}
    access(self) var entities: {UInt64: Entity}
    access(self) var extra: {String: AnyStruct}

    // createEntity creates a new Entity struct and stores it in the Entities dictionary in this smart contract
    pub fun createEntity(intMetadata: {String: UInt64}, fixMetadata: {String: UFix64}, strMetadata: {String: String}, setID: UInt64): UInt64 {
      var entity = Entity(intMetadata: intMetadata, fixMetadata: fixMetadata, strMetadata: strMetadata, setID: setID, nextEntityID: MindtrixPack.nextEntityID)
      let entityID = entity.entityID

      emit EntityCreated(setID: setID, entityID: entityID, strMetadata: strMetadata, intMetadata: intMetadata)

      // Increasing the ID here instead of the struct's init() because everyone can create a struct.
      MindtrixPack.nextEntityID = MindtrixPack.nextEntityID + UInt64(1)
      MindtrixPack.entityIDToOwner.insert(key: entityID, self.owner!.address)
      self.entities[entityID] = entity

      return entityID
    }

    pub fun createEntityAndAddToSet(intMetadata: {String: UInt64}, fixMetadata: {String: UFix64}, strMetadata: {String: String}, setID: UInt64): UInt64 {
      let entityID = self.createEntity(intMetadata: intMetadata, fixMetadata: fixMetadata, strMetadata: strMetadata, setID: setID)
      let setRef = self.borrowSet(setID: setID)
      setRef.addEntities(entityIDs: [entityID])
      return entityID
    }

    pub fun createSet(strMetadata: {String: String}, intMetadata: {String: UInt64}): UInt64 {

      var set <- create Set(strMetadata: strMetadata, intMetadata: intMetadata)
      let setID = set.setID

      self.sets[setID] <-! set
      MindtrixPack.setIDToOwner.insert(key: setID, self.owner!.address)

      return setID
    }

    pub fun updateSetMetadata(setID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64}) {
      pre {
          self.sets[setID] != nil : "Set data does not exist"
          self.sets[setID]?.locked == false: "Locked set data cannot be updated"
      }
      var setVo = MindtrixPack.SetVo(setID)
      let setRef = self.borrowSet(setID: setID)
      setRef.updateMetadata(strMetadata: strMetadata, intMetadata: intMetadata)
    }

    pub fun updateEntityMetadata(entityID: UInt64, strMetadata: {String: String}, intMetadata: {String: UInt64}) {
      pre {
          self.entities[entityID] != nil: "Cannot update a non-existed entity."
          self.sets[self.entities[entityID]!.setID]?.locked == false: "Locked set data cannot be updated"
      }
      let setID = self.entities[entityID]!.setID
      self.entities[entityID]!.updateMetadata(strMetadata: strMetadata, intMetadata: intMetadata)
      emit EntityUpdated(setID: setID, entityID: entityID, strMetadata: self.entities[entityID]!.getStrMetadata(), intMetadata: self.entities[entityID]!.getIntMetadata())
    }

    pub fun updateEntityPrice(entityID: UInt64, priceUSD: UFix64) {
      pre {
        self.entities.keys.contains(entityID) : "Cannot update a non-existed entity's price."
      }
      let copiedEntity = self.entities[entityID]!
      copiedEntity.updatePrice(priceUSD)
      self.entities[entityID] = copiedEntity
    }

    pub fun borrowSet(setID: UInt64): &Set {
      pre {
          self.sets[setID] != nil: "Cannot borrow Set: The Set doesn't exist"
      }
      return (&self.sets[setID] as &Set?)!
    }

    pub fun borrowHashVerifier(setID: UInt64, packID: UInt64): &{MindtrixViews.IHashVerifier} {
      pre {
          self.sets[setID] != nil: "Cannot borrow Set: The Set doesn't exist"
      }
      let set = self.borrowSet(setID: setID)
      return set.borrowHashVerifier(packID: packID)
    }

    pub fun borrowSetPublic(setID: UInt64): &Set{ISetPublic} {
      return (&self.sets[setID] as &Set{ISetPublic}?)!
    }

    pub fun getSetIDs(): [UInt64] {
      return self.sets.keys
    }

    pub fun updateDistributionTimestamp(setID: UInt64, distributionTimestamp: UFix64) {
      self.sets[setID]?.updateDistributionTimestamp(distributionTimestamp: distributionTimestamp)
    }

    pub fun updateDistributionBlockHeight(setID: UInt64) {
      self.sets[setID]?.updateDistributionBlockHeight()
    }

    pub fun getSetEntityIDs(setID: UInt64): [UInt64] {
      let set = (&self.sets[setID] as &Set?)!
      if set == nil {
        return []
      } else {
        return set.getEntityIDs()
      }
    }

    access(contract) fun getMetadataHashesFromSet(setID: UInt64): [String] {
      let set = (&self.sets[setID] as &Set?)!
      var keys: [String] = []
      for setKey in set.getMetadataHashesString().keys {
        keys.appendAll(set.getMetadataHashesString()[setKey]!.keys)
      }
      return keys
    }

    access(contract) fun getMetadataHashIndexFromSet(setID: UInt64, metadataHashedString: String): UInt64 {
      let set = (&self.sets[setID] as &Set?)!
      return set.getMetadataHashIndexByString(metadataHashedString: metadataHashedString)
    }

    pub fun getAllowListDic(setID: UInt64): {Address: [UInt64]}{
      let set = (&self.sets[setID] as &Set?)!
      return set.getAllowListDic()
    }

    pub fun getAllowListPackVos(inboxAddress: Address, setID: UInt64): [MindtrixPack.PackVo]{
      let set = (&self.sets[setID] as &Set?)!
      return set.getAllowListPackVos(inboxAddress: inboxAddress)
    }

    pub fun getEntityVo(entityID: UInt64): EntityVo? {
      let entity = self.entities[entityID]
      if entity == nil {
        return nil
      } else {
        let setID = entity!.setID
        let totalMinted = MindtrixPack.getEntityMintedNum(setID: entity!.setID, entityID: entityID) ?? 0
        return EntityVo(entityID, nil)
      }
    }

    pub fun getEntity(entityID: UInt64): Entity? {
      let entity = self.entities[entityID]
      if entity == nil {
        return nil
      } else {
        return entity
      }
    }

    pub fun getEntityIDs(): [UInt64] {
      return self.entities.keys
    }

    pub fun getEntitiesMaxSupplyInSet(setID: UInt64): {UInt64: UInt64} {
      return self.sets[setID]?.getMaxSupplyPerEntity() ?? {}
    }

    pub fun getEntitiesInSet(setID: UInt64): [UInt64]? {
      return self.sets[setID]?.getEntityIDs()
    }

    pub fun isSetLocked(setID: UInt64): Bool? {
      return self.sets[setID]?.locked
    }

    pub fun getMetadataHashesString(setID: UInt64): {UInt64: {String: UInt64}} {
      let setRef = (&self.sets[setID] as &Set{ISetPublic}?)!
      return setRef.getMetadataHashesString();
    }

    init(){
      self.sets <- {}
      self.entities = {}
      self.extra = {}
    }

    destroy() {
      assert(self.sets.length > 0, message: "Cannot destory sets ")
      destroy self.sets
    }
  }

  pub resource interface ISetPublic {
    pub fun getMetadataHashesString(): {UInt64: {String: UInt64}}
    pub fun getMetadataHashBySetIndex(setIndex: UInt64): {String: UInt64}
    pub fun getLocked(): Bool
    pub fun getEntityIDs(): [UInt64]
    pub fun getRetiredEntities(): {UInt64: Bool}
    pub fun getTotalMinted(): UInt64
    pub fun getTrackerStatus(packID: UInt64): PackStatus
    pub fun getTrackerMetadataHash(packID: UInt64): String
    pub fun getTrackerMetadataIndex(packID: UInt64): UInt64?
    pub fun getNumMintedPerEntity(): {UInt64: UInt64}
    pub fun getMaxSupplyPerEntity(): {UInt64: UInt64}
    pub fun getMaxSupplyPerRound(): UInt64?
    pub fun getMaxSupplyFromSingleEntity(entityID: UInt64): UInt64?
    pub fun getMaxSupplySumOfEntities(): UInt64
    pub fun verifyMintingConditions(entityID: UInt64, minterAddress: Address?, quantity: UInt64, isAssert: Bool): {String: Bool}
    pub fun claimAllowList(recipient: &{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}, quantity: Int)
    pub fun getTotalHashConsumerLength(): UInt64
    pub fun openPack(setID: UInt64, entityID: UInt64, packID: UInt64, packCollectionRef: &{NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}, recvRef: &{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}, strMetadata: {String: String})
    pub fun getStrMetadata(): {String: String}
    pub fun getDistributionBlockHeight(): UInt64?
    pub fun getIsAllowPublicSale(): Bool
    pub fun getIsAllowRevealUtility(): Bool
    pub fun getIsAllowOpen(): Bool
    pub fun getStatusToTrackerSerials(): {MindtrixPack.PackStatus: {UInt64: UInt64}}
  }

  pub resource Set: ISetPublic {

    pub let setID: UInt64

    access(self) var entities: [UInt64]
    access(self) var retiredEntities: {UInt64: Bool}
    pub var locked: Bool
    pub var isEnableDropMaxSupply: Bool
    pub var isAllowOpen: Bool
    pub var isAllowPublicSale: Bool
    pub var isAllowRevealUtility: Bool
    access(self) var maxSupplyPerEntity: {UInt64: UInt64}
    // {{entityID}: {mintedNum}}
    access(self) var numMintedPerEntity: {UInt64: UInt64}
    // Minters record the history of each address that creates an entity.
    access(self) var minters: {Address: {UInt64: [MindtrixViews.NFTIdentifier]}}

    pub let hashSetSize: UInt64
    pub var distributionBlockHeight: UInt64?
    pub var distributionTimestamp: UFix64
    pub var nextDistributingIndex: Int

    // {1: {"face": "shades", "body": "Military Uniform",...}, {2: {...}}}
    access(self) var entityMetadataSources: {UInt32: {String: String}}
    access(self) var mintedNFTIDToNFTIdentifiers: {UInt64: MindtrixViews.NFTIdentifier}
    access(self) var minterAddressToNFTID: {Address: [UInt64]}
    access(self) var entityIDToMinterAddressToNFTIdentifiers: {UInt64: {Address: [UInt64]}}

    access(self) var strMetadata: {String: String}
    access(self) var intMetadata: {String: UInt64}
    access(self) var fixMetadata: {String: UFix64}
    access(self) var boolMetadata: {String: Bool}

    access(self) var trackers: @{UInt64: MindtrixPack.Tracker}
    // {MindtrixPack.PackStatus.Distributed: {1(TrackerSerial):143954166(PackID), 2: 143954178,...}, MindtrixPack.PackStatus.Opened: ,,,}
    access(self) var statusToTrackerSerials: {MindtrixPack.PackStatus: {UInt64: UInt64}}
    access(self) var allowList: @{Address: MindtrixPack.Collection}
    access(self) var extra: {String: AnyStruct}

    pub var allowListTotalMintedQuantity: UInt8
    pub var allowListMintedQuantityPerAddress: {Address: UInt8}
    // Separate 9,999 Otter NFT into multiple dictionaries to avoid reaching gas limit when iterating in a bigger dictionary.
    access(self) var metadataHashesString: {UInt64: {String: UInt64}}
    access(self) var metadataHashesStringConsumer: [[String]]
    pub var nextTrackerSerial: UInt64

    init(strMetadata: {String: String}, intMetadata: {String: UInt64}){
      self.setID = self.uuid
      self.entities = []
      self.retiredEntities = {}
      self.locked = false
      self.isEnableDropMaxSupply = false
      self.isAllowOpen = false
      self.isAllowPublicSale = false
      self.isAllowRevealUtility = false
      self.numMintedPerEntity = {}
      self.minters = {}
      self.hashSetSize = 2000
      self.distributionBlockHeight = nil
      self.distributionTimestamp = UFix64(0)
      self.maxSupplyPerEntity = {}
      self.entityMetadataSources = {}
      self.mintedNFTIDToNFTIdentifiers = {}
      self.minterAddressToNFTID = {}
      self.entityIDToMinterAddressToNFTIdentifiers = {}
      self.strMetadata = strMetadata
      self.intMetadata = intMetadata
      self.fixMetadata = {}
      self.boolMetadata = {}
      self.trackers <- {}
      self.statusToTrackerSerials = {}
      self.extra = {}
      self.allowList <- {}
      self.allowListTotalMintedQuantity = 0
      self.allowListMintedQuantityPerAddress = {}
      self.metadataHashesString = {}
      self.metadataHashesStringConsumer = []
      self.nextDistributingIndex = 1
      self.nextTrackerSerial = 1

      emit SetCreated(setID: self.setID, strMetadata: self.strMetadata, intMetadata: self.intMetadata)
    }

    destroy() {
      pre {
        self.allowList.length == 0: "Cannot destroy the set because there are unclaimed allowlist."
        self.trackers.length == 0: "Cannot destroy the set because there are unclaimed packs."
      }
      destroy self.allowList
      destroy self.trackers

      emit SetBurned(setID: self.setID)
    }

    pub fun replaceEntityMetadataSources(entityMetadataSources: {UInt32: {String: String}}){
      pre {
        entityMetadataSources.keys.length > 0 : "Cannot add an empty source"
        self.entityMetadataSources.keys.length <= 0 : "Cannot replace the existing sources"
      }
      self.entityMetadataSources = entityMetadataSources
    }

    pub fun patchEntityMetadataSources(entityMetadataSources: {UInt32: {String: String}}){
      pre {
        entityMetadataSources.keys.length > 0 : "Cannot add an empty source"
      }
      for serial in entityMetadataSources.keys {
        self.entityMetadataSources.insert(key: serial, entityMetadataSources[serial]!)
      }
    }

    pub fun dropEntitySupply(entityID: UInt64, dropNum: UInt64){
      pre {
        !self.locked : "Cannot drop the max supply after the set has been locked."
        self.isEnableDropMaxSupply : "Not allow to drop the max supply."
        self.getEntityIDs().contains(entityID) : "Cannot find the entity from the given entityID:".concat(entityID.toString())
        self.maxSupplyPerEntity[entityID] != nil : "Cannot find the max supply of the entity from the given entityID:".concat(entityID.toString())
        self.numMintedPerEntity[entityID] != nil : "Cannot find the minted number of the entity from the given entityID:".concat(entityID.toString())
        (self.maxSupplyPerEntity[entityID]! - UInt64(dropNum)) >= self.numMintedPerEntity[entityID]!: "Cannot drop the entity number which would lower than the minted number."
        dropNum <= 15 : "Cannot drop over 15 each time."
      }
      post {
        self.maxSupplyPerEntity[entityID]! >= self.numMintedPerEntity[entityID]!: "Cannot drop the entity number which would lower than the minted number."
      }
      self.maxSupplyPerEntity[entityID] = self.maxSupplyPerEntity[entityID]! - UInt64(dropNum)
    }

    pub fun updateEntitiesPriceAfterRevealUtility(priceUSD: UFix64) {
       let setCollectionRef = MindtrixPack.account.borrow<
        &MindtrixPack.SetCollection
      >(from: MindtrixPack.SetCollectionStoragePath)
        ?? panic("Cannot borrow the set collection.")
      for entityID in self.entities {
        setCollectionRef.updateEntityPrice(entityID: entityID, priceUSD: priceUSD)
      }
    }

    pub fun updateIsAllowPublicSale(_ isAllow: Bool){
      self.isAllowPublicSale = isAllow
    }

    pub fun updateIsAllowRevealUtility(_ isAllow: Bool){
      self.isAllowRevealUtility = isAllow
    }

    pub fun updateIsAllowOpen(_ isAllow: Bool){
      if(isAllow) {
        assert(self.statusToTrackerSerials[MindtrixPack.PackStatus.Sealed]?.keys?.length ?? 0 == 0, message: "Cannot update to allowed-open when there are still undistributed Packs.")
      }
      self.isAllowOpen = isAllow
    }

    pub fun getIsAllowPublicSale(): Bool {
      return self.isAllowPublicSale
    }

    pub fun getIsAllowRevealUtility(): Bool {
      return self.isAllowRevealUtility
    }

    pub fun getIsAllowOpen(): Bool {
      return self.isAllowOpen
    }

    // updateMetadata replaces the old fields and inserts the new fields in the dictionary
    pub fun updateMetadata(strMetadata: {String: String}, intMetadata: {String: UInt64}) {
      for key in strMetadata.keys {
        self.strMetadata.insert(key: key, strMetadata[key]!)
      }
      for key in intMetadata.keys {
        self.intMetadata.insert(key: key, intMetadata[key]!)
      }
      emit SetUpdated(setID: self.setID, strMetadata: self.strMetadata, intMetadata: self.intMetadata)
    }

    pub fun addEntity(entityID: UInt64) {
      pre {
          !self.locked: "Cannot add the entity to the Set after the set has been locked."
          self.numMintedPerEntity[entityID] == nil: "The entity has already been added to the set."
      }

      let entity = self.getEntityVoFromSetCollection(entityID: entityID)

      let maxSupply = entity.maxSupply
      if maxSupply != nil {
        self.maxSupplyPerEntity.insert(key: entity.entityID, maxSupply!)
      }

      // Add the entity to the array of entities
      self.entities.append(entityID)

      // Allow the entity to be minted
      self.retiredEntities[entityID] = false

      // Initialize the entity minted count to zero
      self.numMintedPerEntity[entityID] = 0

    }

    pub fun updateTrackerStatusDic(preStatus: MindtrixPack.PackStatus?, nextStatus: MindtrixPack.PackStatus, trackerSerial: UInt64, packID: UInt64) {
      if preStatus != nil && self.statusToTrackerSerials[preStatus!] != nil {
        self.statusToTrackerSerials[preStatus!]!.remove(key: trackerSerial)
      }
      if self.statusToTrackerSerials[nextStatus] == nil {
        var trackerSerialToID: {UInt64: UInt64} = {}
        trackerSerialToID.insert(key: trackerSerial, packID)
        self.statusToTrackerSerials.insert(key: nextStatus, trackerSerialToID)
      } else {
        self.statusToTrackerSerials[nextStatus]!.insert(key: trackerSerial, packID)
      }
    }

    pub fun getStatusToTrackerSerials(): {MindtrixPack.PackStatus: {UInt64: UInt64}} {
      return self.statusToTrackerSerials
    }

    // updateMinters updates the history of each address associated with an entity.
    pub fun updateMinters(entityID: UInt64, packIdentifier: MindtrixViews.NFTIdentifier) {
      let address = packIdentifier.holder
      if self.minters[address] == nil {
        var entityIDToIdentifier: {UInt64: [MindtrixViews.NFTIdentifier]} = {}
        entityIDToIdentifier.insert(key: entityID, [packIdentifier])
        self.minters.insert(key: address, entityIDToIdentifier)
      } else {
        if self.minters[address]![entityID] == nil {
          self.minters[address]!.insert(key: entityID, [packIdentifier])
        } else {
          self.minters[address]![entityID]!.append(packIdentifier)
        }
      }
    }

    pub fun getEntityIDsFromSetCollection(): [UInt64] {
      let collectionPublicRef = MindtrixPack.borrowSetCollectionPublicRef(setID: self.setID)
      return collectionPublicRef.getEntityIDs()
    }

    pub fun getEntityVoFromSetCollection(entityID: UInt64): EntityVo {
      let collectionPublicRef = MindtrixPack.borrowSetCollectionPublicRef(setID: self.setID)
      return collectionPublicRef.getEntityVo(entityID: entityID)!
    }

    // addEntities adds multiple entities to the Set
    pub fun addEntities(entityIDs: [UInt64]) {
      for entity in entityIDs {
          self.addEntity(entityID: entity)
      }
    }

    pub fun resetNextDistributingIndex() {
      self.nextDistributingIndex = 1
    }

    // distributePack is a irreversible operation to distribute Otter NFT metadata into Trackers by assigning a pseudo random number to each.
    pub fun distributePack(patchSize: Int) {
      pre {
        self.distributionTimestamp != nil : "The distribution timestamp is yet to assigned."
        self.distributionBlockHeight != nil : "The distribution block height is yet to assigned."
        self.distributionBlockHeight! <= getCurrentBlock().height : "Cannot distribution Packs until reaching the distribution block height."
      }
      // The blockHeight will be determined by Pack holders in Mindtrix Discord. The contract uses the block hash from the height as a seed param.
      // Using the last Tracker's uuid as one of seed param aims to prevent holders to know the id and pre-calculated the unpacking result.
      // Both params aims to create the PRNG resource generating the independent pseudo random number.
      // Therefore, both Mindtrix team and holders cannot predict the two params to pre-calculated the unpacking result.

      // packSerial to packID
      var unopenedPackIDs: {UInt64: UInt64} = self.statusToTrackerSerials[MindtrixPack.PackStatus.Sealed]!
      let unopenedPackIDKeys = unopenedPackIDs.keys
      let unopenedPackLen = unopenedPackIDKeys.length
      let lastPackSerial = unopenedPackIDKeys[unopenedPackLen - 1]
      let lastPackID = unopenedPackIDs[lastPackSerial]!
      let lastTrackerID = self.borrowTracker(packID: lastPackID).id
      let randomRes <- PRNG.createFrom(blockHeight: self.distributionBlockHeight!, uuid: lastTrackerID)
      var count = Int(0)
      while count <= patchSize {
        if count > unopenedPackLen - 1 {
          break
        }
        let i = self.nextDistributingIndex
        let packID = unopenedPackIDs[UInt64(i)] ?? panic("Cannot find the packID by the index:".concat(i.toString()))
        let trackerRes = self.borrowTracker(packID: packID)
        let consumedIndex = UInt64(randomRes.generate()) % self.getTotalHashConsumerLength()
        // each hashSet stores 2,000 hashes
        let hashSetIndex = consumedIndex / self.hashSetSize
        let currentHashSetLen = self.getMetadataHashConsumerBySetIndex(setIndex: hashSetIndex).length
        let consumedIndexInHashSet = consumedIndex % UInt64(currentHashSetLen)
        let consumedMetadataHashString = self.metadataHashesStringConsumer[hashSetIndex][consumedIndexInHashSet]
        let originalMetadataIndex = self.metadataHashesString[hashSetIndex]![consumedMetadataHashString]
            ?? panic("The consumedMetadataHashString does not exist.")

        let isSuccess = trackerRes.distribute(metadataHashIndex: originalMetadataIndex, metadataHash: consumedMetadataHashString.decodeHex())
        if isSuccess {
          let a = self.metadataHashesStringConsumer[hashSetIndex].remove(at: consumedIndexInHashSet)
          self.intMetadata["metadataHashConsumerLen"] = self.getTotalHashConsumerLength() - 1
          self.updateTrackerStatusDic(preStatus: MindtrixPack.PackStatus.Sealed, nextStatus: MindtrixPack.PackStatus.Distributed, trackerSerial: trackerRes.serial, packID: packID)
          self.nextDistributingIndex = self.nextDistributingIndex + 1
        }
        count = count + 1
      }
        destroy randomRes
    }

    pub fun getStrMetadata(): {String: String}{
      return self.strMetadata
    }

    pub fun getLocked(): Bool {
      return self.locked
    }
    
    pub fun openPack(setID: UInt64, entityID: UInt64, packID: UInt64, packCollectionRef: &{NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}, recvRef: &{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}, strMetadata: {String: String}) {
      pre {
        packCollectionRef.getIDs().contains(packID) : "Cannot find the packID in holder's collection: ".concat(packID.toString())
        packCollectionRef.owner!.address == recvRef.owner!.address : "The Pack owner and the receiver are not identical."
        self.trackers[packID] != nil : "Cannot tract this pack:".concat(packID.toString())
        self.borrowTracker(packID:packID)!.status == PackStatus.Distributed: "Pack is yet to be Distributed"
        self.isAllowOpen == true : "Not yet for opening the pack."
      }
      let trackerRef = self.borrowTracker(packID: packID)
      let setCollectionPublicCap = getAccount(self.owner!.address).getCapability<
        &MindtrixPack.SetCollection{ISetCollectionPublic, MindtrixViews.IHashProvider}
      >(MindtrixPack.SetCollectionPublicPath)
      assert(setCollectionPublicCap.check(), message: "Cannot use the setCollectionPublicCap")
      let setCollectionPublicRef = setCollectionPublicCap.borrow()!

      // 2. mint Otter NFT based on metadata hash
      let entityVo = setCollectionPublicRef.getEntityVo(entityID: entityID)!

      let metadataHashFromTracker = trackerRef.getMetadataHash()
      let metadataHashFromMinting = MindtrixUtility.generateMetadataHash(strMetadata: strMetadata)

      let isPassed = trackerRef.verifyHash(setID: setID, packID: packID, metadataHash: metadataHashFromMinting)
      assert(isPassed, message: "Cannot pass the hash verification.")

      let intMetadata = {
        "setID": self.setID,
        "entityID": entityID,
        "packID": packID
      }

      // mint Otter NFT and deposit it into opener's address
      var royalties: [MetadataViews.Royalty] = []
      let royaltyReceiverPublicPath: PublicPath = /public/flowTokenReceiver
      let beneficiaryCapability = MindtrixPack.account.getCapability<&{FungibleToken.Receiver}>(royaltyReceiverPublicPath)
      royalties.append(
        MetadataViews.Royalty(
          receiver: beneficiaryCapability,
          cut: 0.05,
          description: "5% royalty for the first minter.",
        )
      )

      // 3. change the Pack status to Opened
      trackerRef.updateStatusToOpened()
      self.updateTrackerStatusDic(preStatus: MindtrixPack.PackStatus.Distributed, nextStatus: MindtrixPack.PackStatus.Opened, trackerSerial: trackerRef.serial, packID: packID)
      // 4. deposit Otter NFT into user's wallet
      recvRef.deposit(token: <-  MindtrixOtter.mintNFT(
        minterAddress: recvRef.owner!.address,
        metadataHash: metadataHashFromTracker,
        setCollectionPublicCap: setCollectionPublicCap,
        strMetadata: strMetadata,
        intMetadata: intMetadata,
        fixMetadata: {},
        components: {},
        royalties: royalties)
      )
    }

    pub fun getIsAllowListExisted(_ address: Address): Bool {
      if self.allowList[address] == nil {
        return false
      } else {
        return true
      }
    }

    pub fun getAllowListEntityIDs(address: Address): [UInt64] {
      if self.getIsAllowListExisted(address) {
        return []
      } else {
        let collectionRef = (&self.allowList[address] as &MindtrixPack.Collection{MindtrixPack.CollectionPublic}?)!
        return collectionRef.getIDs()
      }
    }

    pub fun getAllowListDic(): {Address: [UInt64]} {
      var allowListPackIDs: {Address: [UInt64]} = {}
      for address in self.allowList.keys {
        let collectionRef = (&self.allowList[address] as auth &MindtrixPack.Collection{MindtrixPack.CollectionPublic}?)!
        allowListPackIDs.insert(key: address, collectionRef.getIDs())
      }
      return allowListPackIDs
    }

    pub fun getIsOnAllowList(_ address: Address): Bool {
      return self.getAllowListDic().keys.contains(address)
    }

    pub fun getAllowListPackVos(inboxAddress: Address): [MindtrixPack.PackVo] {
      var packVos: [MindtrixPack.PackVo] = []
      let collectionRef = (&self.allowList[inboxAddress] as auth &MindtrixPack.Collection{MindtrixPack.CollectionPublic}?)!
      let packIDs = collectionRef.getIDs()
      for id in packIDs {
        let packRef = collectionRef.borrowMindtrixPackNFTPublic(id: id)
        let packVo = packRef?.getVo() ?? nil
        if packVo != nil {
          packVos.append(packVo!)
        }        
       }
      return packVos
    }

    pub fun getTotalAllowListMintedQuantity(): UInt8 {
      var totalQuantity = UInt8(0)
      for address in self.allowListMintedQuantityPerAddress.keys {
        totalQuantity = totalQuantity + self.allowListMintedQuantityPerAddress[address]!
      }
      return totalQuantity
    }

    pub fun updateAllowListMintedQuantityPerAddress(address: Address, quantity: UInt8) {
      self.allowListMintedQuantityPerAddress[address] = (self.allowListMintedQuantityPerAddress[address] ?? 0) + quantity
    }

    pub fun mintAndAddAllowList(minterAddress: Address, entityIDToQuantity: {UInt64: UInt8}){
      let allowListLimitedMintQuantity = UInt8(100)
      for entityID in entityIDToQuantity.keys {
        let requestQuantity = entityIDToQuantity[entityID] ?? 0
        if !self.getIsAllowListExisted(minterAddress) {
          self.allowList[minterAddress] <-! MindtrixPack.createEmptyCollection() as! @MindtrixPack.Collection
        }
        let collectionRef = (&self.allowList[minterAddress] as &MindtrixPack.Collection?)!
        let mintedQuantity= UInt8(collectionRef.getIDs().length)
        assert((self.allowListMintedQuantityPerAddress[minterAddress] ?? 0) <= 5, message: "Cannot mint over 5 entities for an address.")
        assert(self.allowListTotalMintedQuantity <= allowListLimitedMintQuantity, message: "Cannot mint over the limited quantity.")
        // start minting from the entity
        let newCollection <-! self.batchMint(entityID: entityID, quantity: UInt64(requestQuantity), minterAddress: minterAddress)
        self.updateAllowListMintedQuantityPerAddress(address: minterAddress, quantity: requestQuantity)
        self.addAllowList(address: minterAddress, entityCollection: <- newCollection)
        self.allowListTotalMintedQuantity = self.getTotalAllowListMintedQuantity()
      }
    }

    pub fun addAllowList(address: Address, entityCollection: @MindtrixPack.Collection) {

      let entityIDs = entityCollection.getIDs()
      if !self.getIsAllowListExisted(address) {
        self.allowList[address] <-! MindtrixPack.createEmptyCollection() as! @MindtrixPack.Collection
      }
      let collectionRef = (&self.allowList[address] as &MindtrixPack.Collection?)!
      for id in entityIDs {
          collectionRef.deposit(token: <- entityCollection.withdraw(withdrawID: id))
      }
      assert(entityCollection.getIDs().length == 0, message: "Cannot destroy left resources in nfts.")
      destroy entityCollection
      emit AllowListAdded(address: address, entityIDs: entityIDs)
    }

    pub fun revokeAllowList(address: Address) {
      // revoke entities and transfer them to the set owner's address
      if self.getIsAllowListExisted(address) {
          let setOwnerAddress = self.owner!.address
          let tmpCollection: @MindtrixPack.Collection <-! self.allowList.remove(key: address)!
          let entityIDs = tmpCollection.getIDs()
          emit AllowListRevoked(address:address, entityIDs: entityIDs)
          self.addAllowList(address: setOwnerAddress, entityCollection: <- tmpCollection)
      }
    }

    pub fun claimAllowList(recipient: &{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver}, quantity: Int) {
      let address = recipient.owner!.address

      if self.getIsAllowListExisted(address) {
        let collectionRef = (&self.allowList[address] as &MindtrixPack.Collection?)!
        let unopenedIDs = collectionRef.getIDs()
        for i, packID in unopenedIDs {
          // avoid reaching gas limit
          if i > quantity {
            break;
          }
          recipient.deposit(token: <-collectionRef.withdraw(withdrawID: packID))
          emit AllowListClaimed(address: address, packID: packID)
        }
      }
    }

    // pub fun recordBuyer

    pub fun importMetadataHashStr(metadataHashesString: {String: UInt64}){
      let keys = metadataHashesString.keys
      let currentLen = self.getTotalHashLength()
      let importedLen = UInt64(keys.length)
      for i, k in keys {
        let newIndex = currentLen + UInt64(i)
        let hashSetIndex = (newIndex) / self.hashSetSize
        if self.metadataHashesString[hashSetIndex] == nil {
          self.metadataHashesString.insert(key: hashSetIndex, {})
          self.metadataHashesStringConsumer.append([])
        }
        self.metadataHashesString[hashSetIndex]!.insert(key: k, metadataHashesString[k]!)
      }

      self.intMetadata["metadataHashLen"] = (self.intMetadata["metadataHashLen"] ?? 0) + importedLen
      let totalLen = self.getTotalHashLength()
      assert(totalLen <= 9999, message: "Cannot add the metadata hashes over 9,999.")
      emit MetadataHashesImported(importedLen: importedLen, totalLen: totalLen)
    }

    pub fun copyMetadataHashStrToConsumer() {
      pre {
        self.intMetadata["metadataHashConsumerLen"] ?? 0 < 9999 : "Cannot add hash consumer over 9999!"
      }
      let currentLen = self.getTotalHashConsumerLength()
      // every set contains 2,000 hashes, so metadataHashesString[0] contains 2,000th, and 2,001st go to the metadataHashesString[1]
      let hashSetIndex = currentLen / self.hashSetSize
      let keys = self.metadataHashesString[hashSetIndex]!.keys
      self.metadataHashesStringConsumer[hashSetIndex].appendAll(keys)
      let importedLen = UInt64(keys.length)
      self.intMetadata["metadataHashConsumerLen"] = self.getTotalHashConsumerLength() + importedLen
      let totalLen = self.getTotalHashConsumerLength()
      emit MetadataHashesConsumerCopied(importedLen: importedLen, totalLen: totalLen)
    }

    pub fun getTotalHashLength(): UInt64 {
      return self.intMetadata["metadataHashLen"] ?? 0
    }

    pub fun getTotalHashConsumerLength(): UInt64 {
      return self.intMetadata["metadataHashConsumerLen"] ?? 0
    }

    pub fun getMetadataHashIndexByString(metadataHashedString: String): UInt64 {
      for setKey in self.metadataHashesString.keys {
        if self.metadataHashesString[setKey]![metadataHashedString] != nil {
          let hashSet = self.metadataHashesString[setKey]!
          return hashSet[metadataHashedString]!
        }
      }
      panic("Cannot find the metadataHashedString")
    }

    pub fun getMetadataHashIndexBySetIndex(hashSetIndex: UInt64): {String: UInt64} {
      pre {
        self.metadataHashesString[hashSetIndex] != nil : "Cannot find the hashSetIndex: ".concat(hashSetIndex.toString())
      }
      return self.metadataHashesString[hashSetIndex]!
    }

    pub fun getMaxSupplyPerEntity(): {UInt64: UInt64} {
      return self.maxSupplyPerEntity
    }

    pub fun getMaxSupplyPerRound(): UInt64? {
      return self.intMetadata["maxPackSupply"]
    }

    pub fun getMaxSupplyFromSingleEntity(entityID: UInt64) : UInt64? {
      return self.getMaxSupplyPerEntity()[entityID]
    }

    pub fun getMaxSupplySumOfEntities(): UInt64 {
      let eachSupply = self.maxSupplyPerEntity
      var sumSupply = UInt64(0)
      let retiredEntities = self.getRetiredEntities()
      for entityID in eachSupply.keys {
        if (retiredEntities[entityID] ?? false) == false {
          sumSupply = sumSupply + UInt64(eachSupply[entityID]!)
        }
      }
      return sumSupply
    }

    // retireEntity retires an entity from the Set so that it cannot mint new NFTs
    pub fun retireEntity(entityID: UInt64) {
      pre {
          self.retiredEntities[entityID] == false: "Cannot retire the entity: Entity must exist in the Set and not be retired."
      }
      self.retiredEntities[entityID] = true
      emit EntityRetiredFromSet(setID: self.setID, entityID: entityID, numNFTs: self.numMintedPerEntity[entityID]!)
    }

    // retireAll retires all the entities in the Set
    pub fun retireAll() {
        for entity in self.entities {
            self.retireEntity(entityID: entity)
        }
    }

    // lock() locks the Set so that no more entities can be added to it
    pub fun lock() {
      pre {
          self.locked == false: "Cannot lock the set: Set is already locked."
      }
      self.locked = true
      emit SetLocked(setID: self.setID)
    }

    pub fun enableDropMaxSupply(){
      self.isEnableDropMaxSupply = true
    }

    pub fun disableDropMaxSupply(){
      self.isEnableDropMaxSupply = false
    }

    pub fun getBlockHeightFromTimestamp(targetedTimestamp: UFix64): UInt64 {
      pre {
        targetedTimestamp <= getCurrentBlock().timestamp : "The targeted timestamp should not be a future time."
      }

      let currentBlock = getCurrentBlock()
      let currentTimeStamp = currentBlock.timestamp

      var diffTimeStamp = currentTimeStamp - targetedTimestamp

      let currentBlockHeight = currentBlock.height
      // https://developers.flow.com/flow/faq/operators#does-the-blockheight-go-up-1-every-second
      let averageBlockFinalizedTime = 1.0
      var diffBlockHeight = UInt64(diffTimeStamp / averageBlockFinalizedTime)
      var presumedBlockHeight = currentBlock.height - diffBlockHeight
      var presumedBlock = getBlock(at: presumedBlockHeight) ?? panic("Something went wrong! The block is blow the current height, so theoretically it must exist!")
      var presumedBlockTimestamp = presumedBlock.timestamp

      while presumedBlockTimestamp > targetedTimestamp {
        diffTimeStamp = presumedBlockTimestamp - targetedTimestamp
        diffBlockHeight = UInt64(diffTimeStamp / averageBlockFinalizedTime)
        presumedBlockHeight = UInt64(presumedBlockHeight - diffBlockHeight)
        presumedBlock = getBlock(at: presumedBlockHeight)!
        presumedBlockTimestamp = presumedBlock.timestamp
      }
      // if presumedBlockTimestamp goes lower than targetedTimestamp, we should add presumedBlockHeihgt one by one to ensure we get the nearest block.
      while presumedBlockTimestamp < targetedTimestamp {
        presumedBlockHeight = presumedBlockHeight + 1
        if presumedBlockHeight > currentBlockHeight {
        break
        }
        presumedBlock = getBlock(at: presumedBlockHeight)!
        presumedBlockTimestamp = presumedBlock.timestamp
        // the result block's timestamp should be equal to or higher than the targeted timestamp so that the targeted one is finalized in that block.
        if presumedBlockTimestamp > targetedTimestamp {
        break
        }
      }
      return presumedBlockHeight
    }

    pub fun updateDistributionTimestamp(distributionTimestamp: UFix64) {
      self.distributionTimestamp = distributionTimestamp
    }

    pub fun updateDistributionBlockHeight() {
      let blockHeight = self.getBlockHeightFromTimestamp(targetedTimestamp: self.distributionTimestamp)
      self.distributionBlockHeight = blockHeight
    }

    pub fun updateMaxPackSupply(maxPackSupply: UInt64){
      pre {
        maxPackSupply >= self.getTotalMinted() : "Pack supply limit should not lower than total minted number."
      }
      self.intMetadata["maxPackSupply"] = maxPackSupply
    }

    pub fun getDistributionBlockHeight(): UInt64? {
      return self.distributionBlockHeight
    }

    pub fun getMintedRecordsByAddress(_ address: Address): {UInt64: [MindtrixViews.NFTIdentifier]}? {
      let entityIDToPackIdentifiers: {UInt64: [MindtrixViews.NFTIdentifier]}?  = self.minters[address]
      return entityIDToPackIdentifiers == nil ? nil : entityIDToPackIdentifiers
    }

    pub fun getPackMintTimesFromMinter(_ address: Address?): UInt64 {
      if address == nil {
        return 0
      }
      let entityIDToPackIdentifiers = self.getMintedRecordsByAddress(address!)
      var packMintTimes = 0
      if entityIDToPackIdentifiers == nil {
        return 0
      }
      for entityID in entityIDToPackIdentifiers!.keys {
        if entityIDToPackIdentifiers![entityID] != nil && entityIDToPackIdentifiers![entityID]!.length > 0 {
          packMintTimes = packMintTimes + entityIDToPackIdentifiers![entityID]!.length
        }
      }
      return UInt64(packMintTimes)
    }

    pub fun getPackMintTimesOfEntityFromMinter(_ address: Address?, _ entityID: UInt64): UInt64 {
      if address == nil {
        return 0
      }
      let entityIDToPackIdentifiers = self.getMintedRecordsByAddress(address!)
      if entityIDToPackIdentifiers == nil || entityIDToPackIdentifiers![entityID] == nil {
        return 0
      }
      return UInt64(entityIDToPackIdentifiers![entityID]!.length)
    }

    pub fun verifyMintingConditions(entityID: UInt64, minterAddress: Address?, quantity: UInt64, isAssert: Bool): {String: Bool} {    
      let currentEdition = self.getTotalMinted()
      let currentEntityEdition = self.getNumMintedPerEntity()[entityID]
      let recipientMaxMintTimesPerAddress = self.getPackMintTimesFromMinter(minterAddress)
      let recipientMintQuantityPerEntity = self.getPackMintTimesOfEntityFromMinter(minterAddress, entityID)
      let params: {String: AnyStruct} = {
        "currentEdition": currentEdition,
        "currentEntityEdition": currentEntityEdition,
        "recipientAddress": minterAddress,
        "recipientMaxMintTimesPerAddress": recipientMaxMintTimesPerAddress,
        "recipientMintQuantityPerTransaction": quantity,
        "recipientMintQuantityPerEntity": recipientMintQuantityPerEntity
      }
      let isOnAllowList = minterAddress == nil ? false : self.getIsOnAllowList(minterAddress!)
      let intDic: {String: UInt64} = {
        "maxEdition": self.getMaxSupplySumOfEntities(),
        // maxSupplyPerRound indicates the supply limit of each Public Sale round.
        "maxSupplyPerRound": self.intMetadata["maxPackSupply"] ?? 0,
        "maxSupplyPerEntity": self.getMaxSupplyFromSingleEntity(entityID: entityID) ?? 0,
        // each allowlist member can get five free Packs at most for cooperation, so they can still buy the other 3 Packs themselves.
        "maxMintTimesPerAddress": isOnAllowList ? 8 : 3,
        "maxMintQuantityPerTransaction": 1,
        "maxMintTimesPerEntity": 1
      }
      let fixDic: {String: UFix64} = {}
      let LimitedQuantityV2 = MindtrixVerifier.LimitedQuantityV2(intDic: intDic, fixDic: fixDic)
      return LimitedQuantityV2.verify(params, isAssert)
    }

    // mint mints a new entity instance and returns the newly minted instance of an entity
    pub fun mint(entityID: UInt64, minterAddress: Address): @NFT {
      pre {
        self.retiredEntities[entityID] == false: "Cannot mint: the entity doesn't exist or has been retired."
        (self.intMetadata["maxPackSupply"] ?? 100) >= (self.getTotalMinted() + UInt64(1)) : "Cannot mint over the supply limitation:".concat((self.intMetadata["maxPackSupply"] ?? 100).toString())
      }
      let currentEdition = self.numMintedPerEntity[entityID]!
      let nextEdition = currentEdition + UInt64(1)
      self.verifyMintingConditions(entityID: entityID, minterAddress: minterAddress, quantity: 1, isAssert: true)

      // Gets the number of NFTs that have been minted for this Entity
      // to use as this NFT's serial number

      let entityMaxSupply = self.getMaxSupplyFromSingleEntity(entityID: entityID)!
      let pack: @NFT <- create NFT(
        serial: nextEdition,
        entityID: entityID,
        setID: self.setID,
        minterAddress: minterAddress
      )
      let packID = pack.id
      // Creating Tracker is to track Pack's status
      let tracker: @Tracker <- create Tracker(
        issuer: self.owner!.address,
        setID: self.setID,
        entityID: entityID,
        packID: packID,
        serial: self.nextTrackerSerial
      )
      // Manually maintaining a serial outside of a resource init() ensures only to increase the number under mint() funs.
      self.nextTrackerSerial = self.nextTrackerSerial + 1

      let packIdentifier = MindtrixViews.NFTIdentifier(
        uuid: packID,
        serial: pack.serial,
        holder: minterAddress
      )  
      self.updateMinters(entityID: entityID, packIdentifier: packIdentifier)
      self.updateTrackerStatusDic(preStatus: nil, nextStatus: MindtrixPack.PackStatus.Sealed, trackerSerial: tracker.serial, packID: packID)
      self.trackers[packID] <-! tracker

      // Increment the number of copies minted for this NFT
      self.numMintedPerEntity[entityID] = nextEdition

      return <-pack
    }

    // batchMint mints an arbitrary quantity of NFTs and returns them as a Collection
    pub fun batchMint(entityID: UInt64, quantity: UInt64, minterAddress: Address): @Collection {
      let collection <- create Collection()
      var i: UInt64 = 0
      while i < quantity {
          collection.deposit(token: <-self.mint(entityID: entityID, minterAddress: minterAddress))
          i = i + UInt64(1)
      }
      return <-collection
    }

    pub fun getTrackerStatus(packID: UInt64): PackStatus {
      return (&self.trackers[packID] as &Tracker?)!.status
    }

    pub fun getTrackerMetadataHash(packID: UInt64): String {
      return String.encodeHex((&self.trackers[packID] as &Tracker?)!.getMetadataHash())
    }

    pub fun getTrackerMetadataIndex(packID: UInt64): UInt64? {
      return (&self.trackers[packID] as &Tracker?)!.getMetadataHashIndex()
    }

    pub fun borrowTracker(packID: UInt64): &Tracker {
      return (&self.trackers[packID] as &Tracker?)!
    }

    pub fun borrowHashVerifier(packID: UInt64): &Tracker{MindtrixViews.IHashVerifier} {
      return (&self.trackers[packID] as &Tracker{MindtrixViews.IHashVerifier}?)!
    }

    pub fun getEntityIDs(): [UInt64] {
      return self.entities
    }

    pub fun getRetiredEntities(): {UInt64: Bool} {
      return self.retiredEntities
    }

    pub fun getNumMintedPerEntity(): {UInt64: UInt64} {
      return self.numMintedPerEntity
    }

    pub fun getTotalMinted(): UInt64 {
      var totalMinted = UInt64(0)
      for k in self.numMintedPerEntity.keys {
        totalMinted = totalMinted + self.numMintedPerEntity[k]!
      }
      return totalMinted
    }

    pub fun getMetadataHashesString(): {UInt64: {String: UInt64}} {
      return self.metadataHashesString
    }

    pub fun getMetadataHashBySetIndex(setIndex: UInt64): {String: UInt64} {
      return self.metadataHashesString[setIndex] ?? {}
    }

    pub fun getMetadataHashConsumerBySetIndex(setIndex: UInt64): [String] {
      let consumer = self.metadataHashesStringConsumer[setIndex]
      return consumer
    }

  }

  // Admin determines which account can create a SetCollection
  pub resource Admin {

    pub fun createSetCollection(): @SetCollection {
      return <- create SetCollection()
    }

    // createNewAdmin creates a new Admin resource
    pub fun createNewAdmin(): @Admin {
      return <-create Admin()
    }
  }

//========================================================
// CONTRACT-LEVEL ACCESS(ACCOUNT) FUNCTION
//========================================================

access(account) fun borrowSetCollectionAdminRef(setID: UInt64): &MindtrixPack.SetCollection{ISetCollectionAdmin} {
  let setOwnerAddress = MindtrixPack.getSetOwner(setID: setID)
  return getAccount(setOwnerAddress).getCapability<
    &MindtrixPack.SetCollection{ISetCollectionAdmin}
  >(MindtrixPack.SetCollectionPublicPath).borrow()
    ?? panic("Cannot borrow the set collection")
}

access(account) fun getMetadataHashByIndex(setID: UInt64, index: UInt256): String {
  let cap = self.borrowSetCollectionAdminRef(setID: setID)
  let array = cap.getMetadataHashesFromSet(setID: setID)
  return cap.getMetadataHashesFromSet(setID: setID)[index]
}

access(account) fun getMetadataHashIndexByString(setID: UInt64, metadataHashedString: String): UInt64 {
  let cap = self.borrowSetCollectionAdminRef(setID: setID)
  return cap.getMetadataHashIndexFromSet(setID: setID, metadataHashedString: metadataHashedString)
}

//========================================================
// CONTRACT-LEVEL PUBLIC FUNCTION
//========================================================

  pub fun createEmptyCollection(): @Collection {
    return <- create MindtrixPack.Collection()
  }

  pub fun borrowSetCollectionPublicRefFromSetOwnerAddress(setOwnerAddress: Address): &MindtrixPack.SetCollection{ISetCollectionPublic, MindtrixViews.IHashProvider} {
    return getAccount(setOwnerAddress).getCapability<
      &MindtrixPack.SetCollection{ISetCollectionPublic, MindtrixViews.IHashProvider}
    >(MindtrixPack.SetCollectionPublicPath).borrow()
      ?? panic("Cannot borrow the set collection")
  }

  pub fun borrowSetCollectionPublicRef(setID: UInt64): &MindtrixPack.SetCollection{ISetCollectionPublic, MindtrixViews.IHashProvider} {
    let setOwnerAddress = MindtrixPack.getSetOwner(setID: setID)
    return MindtrixPack.borrowSetCollectionPublicRefFromSetOwnerAddress(setOwnerAddress: setOwnerAddress)
  }

  pub fun getHashVerifierRef(setID: UInt64, packID: UInt64): &{MindtrixViews.IHashVerifier} {
    let setCollectionRef = MindtrixPack.borrowSetCollectionPublicRef(setID: setID)
    return setCollectionRef.borrowHashVerifier(setID: setID, packID: packID)
  }

  pub fun getSetOwner(setID: UInt64): Address {
    return MindtrixPack.setIDToOwner[setID] ?? panic("Cannot find the owner of the set.")
  }

  pub fun getEntityOwner(entityID: UInt64): Address {
    return MindtrixPack.entityIDToOwner[entityID] ?? panic("Cannot find the owner of the entity.")
  }

  pub fun getEntityVo(entityID: UInt64): EntityVo? {
    let ownerAddress = MindtrixPack.getEntityOwner(entityID: entityID)
    let setCollectionPublicRef = MindtrixPack.borrowSetCollectionPublicRefFromSetOwnerAddress(setOwnerAddress: ownerAddress)
    return setCollectionPublicRef.getEntityVo(entityID: entityID)
  }

  pub fun getEntity(entityID: UInt64): Entity? {
    let ownerAddress = MindtrixPack.getEntityOwner(entityID: entityID)
    let setCollectionPublicRef = MindtrixPack.borrowSetCollectionPublicRefFromSetOwnerAddress(setOwnerAddress: ownerAddress)
    return setCollectionPublicRef.getEntity(entityID: entityID)
  }

  // getEntityMetaData returns all the metadata associated with a specific entity
  pub fun getEntityStrMetaData(entityID: UInt64): {String: String}? {
    return MindtrixPack.getEntity(entityID: entityID)?.getStrMetadata()
  }

  pub fun getEntityStrMetaDataByField(entityID: UInt64, field: String): String? {
    let strMetadata = MindtrixPack.getEntityStrMetaData(entityID: entityID)
    if strMetadata != nil {
      return strMetadata![field]
    } else {
      return nil
    }
  }

  pub fun getEntityIDsBySetID(setID: UInt64): [UInt64] {
    let setCollectionPublicRef = MindtrixPack.borrowSetCollectionPublicRef(setID: setID)
    return setCollectionPublicRef.getEntityIDs()
  }

  pub fun getEntityMintedNum(setID: UInt64, entityID: UInt64): UInt64? {
    let setVo = MindtrixPack.SetVo(setID)
    return setVo!.getNumMintedPerEntity()[entityID]
  }

  pub fun generateHash(_ identifier: String): [UInt8] {
    return HashAlgorithm.SHA3_256.hash(identifier.utf8)
  }

  pub fun getMaxSupplyFromSingleEntity(setID: UInt64, entityID: UInt64): UInt64 {
    let setCollectionRef = MindtrixPack.borrowSetCollectionPublicRef(setID: setID)
    let setRef = setCollectionRef.borrowSetPublic(setID: setID)
    return setRef.getMaxSupplyFromSingleEntity(entityID: entityID) ?? 0
  }

  pub fun getExternalURL(): String {
    // TODO: add the specific gallery URL when the gallery site releases
    return "https://mindtrix.xyz/verse"
  }

  // The fun supports USDC, FUSD, FLOW, FUT, DUC payment.
  pub fun buyPack(
    recipient: &MindtrixPack.Collection{MindtrixPack.CollectionPublic},
    paymentVault: @FungibleToken.Vault,
    setID: UInt64,
    entityID: UInt64,
    numberOfPacks: UInt64,
    merchantAccount: Address?){

    pre {
      numberOfPacks == 1 : "Cannot buy more than one Pack in a landmarks."
      UFix64(numberOfPacks) * MindtrixPack.getEntityVo(entityID: entityID)!.priceUSD == paymentVault.balance : "The withdrew balance is not equal to the expected price."
      paymentVault.getType().isSubtype(of: Type<@FungibleToken.Vault>()): "The type of payment vault is not a subtype of FungibleToken.Vault.Vault."
    }
    let DucReceiverPublicPath = /public/dapperUtilityCoinReceiver
    let FutReceiverPublicPath = /public/flowUtilityTokenReceiver
    let setRef = MindtrixPack.borrowSetCollectionAdminRef(setID: setID).borrowSet(setID: setID)
    assert(setRef.isAllowPublicSale, message: "Public Sale is yet to be open.")

    let paymentType = paymentVault.getType()
    let beneficiaryAccount = getAccount(self.beneficiaryAddress)
    // default is USDC
    var merchantReceiverCap: Capability<&{FungibleToken.Receiver}> = beneficiaryAccount.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)    
    if paymentType == Type<@FiatToken.Vault>() {
      merchantReceiverCap = beneficiaryAccount.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
    } else if paymentType == Type<@FUSD.Vault>() {
       merchantReceiverCap = beneficiaryAccount.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
    } else if paymentType == Type<@FlowToken.Vault>() {
      merchantReceiverCap = beneficiaryAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    }
    // The following below are Dapper Wallet Payments
    else if paymentType == Type<@FlowUtilityToken.Vault>() {
      merchantReceiverCap = getAccount(merchantAccount!).getCapability<&{FungibleToken.Receiver}>(FutReceiverPublicPath)
      assert(merchantReceiverCap.borrow() != nil, message: "Missing or mis-typed merchant FUT receiver")
    } else {
      merchantReceiverCap = getAccount(merchantAccount!).getCapability<&{FungibleToken.Receiver}>(DucReceiverPublicPath)
      assert(merchantReceiverCap.borrow() != nil, message: "Missing or mis-typed merchant DUC receiver")
    }

    merchantReceiverCap.borrow()!.deposit(from: <- paymentVault)
    recipient.deposit(token: <- setRef.mint(entityID: entityID, minterAddress: recipient.owner!.address))
  }

  init(){
    self.CollectionStoragePath = /storage/MindtrixPackCollection
    self.CollectionPublicPath = /public/MindtrixPackCollection
    self.SetCollectionStoragePath = /storage/MindtrixPackSetCollection
    self.SetCollectionPublicPath = /public/MindtrixPackSetCollection
    self.SetCollectionPrivatePath = /private/MindtrixPackSetCollection
    self.AdminStoragePath = /storage/MindtrixPackAdmin
    self.beneficiaryAddress = self.account.address

    self.setIDToOwner = {}
    self.entityIDToOwner = {}

    self.totalSupply = 0
    self.nextEntityID = 1

    self.account.save<@Collection>(<- create Collection(), to: self.CollectionStoragePath)
    self.account.link<&Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, CollectionPublic, MetadataViews.ResolverCollection}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

    self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)
    emit ContractInitialized()
  }
}
 