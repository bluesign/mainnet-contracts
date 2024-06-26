import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FNSConfig from "./FNSConfig.cdc"

// Domains define the domain and sub domain resource
// Use records and expired to store domain's owner and expiredTime
pub contract Domains: NonFungibleToken {
  // Sum the domain number with domain and subdomain
  pub var totalSupply: UInt64

  // Paths
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let CollectionPrivatePath: PrivatePath

  // Domain records to store the owner of Domains.Domain resource
  // When domain resource transfer to another user, the records will be update in the deposit func
  access(self) let records: {String: Address}

  // Expired records for Domains to check the domain's validity, will change at register and renew
  access(self) let expired: {String: UFix64}

  // Store the expired and deprecated domain records 
  access(self) let deprecated: {String: {UInt64: DomainDeprecatedInfo}}

  // Store the domains id with namehash key
  access(self) let idMap: {String: UInt64}


  pub let domainExpiredTip: String
  pub let domainDeprecatedTip: String


  // Events
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Created(id: UInt64, name: String)
  pub event DomainRecordChanged(name: String, resolver: Address)
  pub event DomainExpiredChanged(name: String, expiredAt: UFix64)
  pub event SubDomainCreated(id: UInt64, hash: String)
  pub event SubDomainRemoved(id: UInt64, hash: String)
  pub event SubdmoainTextChanged(nameHash: String, key: String, value: String)
  pub event SubdmoainTextRemoved(nameHash: String, key: String)
  pub event SubdmoainAddressChanged(nameHash: String, chainType: UInt64, address: String)
  pub event SubdmoainAddressRemoved(nameHash: String, chainType: UInt64)
  pub event DmoainAddressRemoved(nameHash: String, chainType: UInt64)
  pub event DmoainTextRemoved(nameHash: String, key: String)
  pub event DmoainAddressChanged(nameHash: String, chainType: UInt64, address: String)
  pub event DmoainTextChanged(nameHash: String, key: String, value: String)
  pub event DomainMinted(id: UInt64, name: String, nameHash: String, parentName: String, expiredAt: UFix64, receiver: Address)
  pub event DomainVaultDeposited(nameHash: String, vaultType: String, amount: UFix64, from: Address?)
  pub event DomainVaultWithdrawn(nameHash: String, vaultType: String, amount: UFix64, from: Address?)
  pub event DomainCollectionAdded(nameHash: String, collectionType: String)
  pub event DomainCollectionWithdrawn(nameHash: String, collectionType: String, itemId: UInt64, from: Address?)
  pub event DomainCollectionDeposited(nameHash: String, collectionType: String, itemId: UInt64, from: Address?)
  pub event DomainReceiveOpened(name: String)
  pub event DomainReceiveClosed(name: String)



  pub struct DomainDeprecatedInfo {
    pub let id: UInt64
    pub let owner: Address
    pub let name: String
    pub let nameHash: String
    pub let parentName: String
    pub let deprecatedAt: UFix64
    pub let trigger: Address


     init(
      id: UInt64,
      owner: Address,
      name: String,
      nameHash: String, 
      parentName: String,
      deprecatedAt: UFix64,
      trigger: Address
    ) {
      self.id = id
      self.owner = owner
      self.name = name
      self.nameHash = nameHash
      self.parentName = parentName
      self.deprecatedAt = deprecatedAt
      self.trigger = trigger
    }   
  }

  // Subdomain detail
  pub struct SubdomainDetail {
    pub let id: UInt64
    pub let owner: Address
    pub let name: String
    pub let nameHash: String
    pub let addresses: {UInt64: String}
    pub let texts: {String: String}
    pub let parentName: String
    pub let createdAt: UFix64 

    
    init(
      id: UInt64,
      owner: Address,
      name: String,
      nameHash: String, 
      addresses:{UInt64: String},
      texts: {String: String},
      parentName: String,
      createdAt: UFix64
    ) {
      self.id = id
      self.owner = owner
      self.name = name
      self.nameHash = nameHash
      self.addresses = addresses
      self.texts = texts
      self.parentName = parentName
      self.createdAt = createdAt
    }   
  }
  
  // Domain detail
  pub struct DomainDetail {
    pub let id: UInt64
    pub let owner: Address
    pub let name: String
    pub let nameHash: String
    pub let expiredAt: UFix64
    pub let addresses: {UInt64: String}
    pub let texts: {String: String}
    pub let parentName: String
    pub let subdomainCount: UInt64
    pub let subdomains: {String: SubdomainDetail}
    pub let createdAt: UFix64 
    pub let vaultBalances: {String: UFix64}
    pub let collections: {String: [UInt64]}
    pub let receivable: Bool
    pub let deprecated: Bool


    init(
      id: UInt64,
      owner: Address,
      name: String,
      nameHash: String, 
      expiredAt: UFix64,
      addresses: {UInt64: String},
      texts: {String: String},
      parentName: String,
      subdomainCount: UInt64,
      subdomains: {String: SubdomainDetail},
      createdAt: UFix64,
      vaultBalances: {String: UFix64},
      collections: {String: [UInt64]},
      receivable: Bool,
      deprecated: Bool
    ) {
      self.id = id
      self.owner = owner
      self.name = name
      self.nameHash = nameHash
      self.expiredAt = expiredAt
      self.addresses = addresses
      self.texts = texts
      self.parentName = parentName
      self.subdomainCount = subdomainCount
      self.subdomains = subdomains
      self.createdAt = createdAt
      self.vaultBalances = vaultBalances
      self.collections = collections
      self.receivable = receivable
      self.deprecated = deprecated
    } 
  }

  pub resource interface DomainPublic {

    pub let id: UInt64
    pub let name: String
    pub let nameHash: String
    pub let parent: String
    pub var receivable: Bool
    pub let createdAt: UFix64
   

    pub fun getText(key: String): String?

    pub fun getAddress(chainType: UInt64): String?

    pub fun getAllTexts():{String: String}

    pub fun getAllAddresses():{UInt64: String}

    pub fun getDomainName(): String

    pub fun getDetail(): DomainDetail

    pub fun getSubdomainsDetail(): [SubdomainDetail]

    pub fun getSubdomainDetail(nameHash: String): SubdomainDetail

    pub fun depositVault(from: @FungibleToken.Vault, senderRef: &{FungibleToken.Receiver}?)

    pub fun addCollection(collection: @NonFungibleToken.Collection)

    pub fun checkCollection(key: String): Bool

    pub fun depositNFT(key: String, token:@NonFungibleToken.NFT, senderRef: &{NonFungibleToken.CollectionPublic}?)
  }

  pub resource interface SubdomainPublic {
    
    pub let id: UInt64
    pub let name: String
    pub let nameHash: String
    pub let parent: String
    pub let createdAt: UFix64 


    pub fun getText(key: String): String?

    pub fun getAddress(chainType: UInt64): String?

    pub fun getAllTexts():{String: String}

    pub fun getAllAddresses():{UInt64: String}

    pub fun getDomainName(): String

    pub fun getDetail(): SubdomainDetail
  }

  pub resource interface SubdomainPrivate {

    pub fun setText(key: String, value: String)

    pub fun setAddress(chainType: UInt64, address: String)

    pub fun removeText(key: String)

    pub fun removeAddress(chainType: UInt64)
  }

  // Domain private for Domain resource owner manage domain and subdomain
  pub resource interface DomainPrivate {

    pub fun setText(key: String, value: String)

    pub fun setAddress(chainType: UInt64, address: String)

    pub fun setETHAddress(address: String, publicKey: [UInt8], signature: [UInt8])

    pub fun removeText(key: String)

    pub fun removeAddress(chainType: UInt64)

    pub fun createSubDomain(name: String)

    pub fun removeSubDomain(nameHash: String)

    pub fun setSubdomainText(nameHash: String, key: String, value: String)

    pub fun setSubdomainAddress(nameHash: String, chainType: UInt64, address: String)

    pub fun removeSubdomainText(nameHash: String, key: String)

    pub fun removeSubdomainAddress(nameHash: String, chainType: UInt64)

    pub fun withdrawVault(key: String, amount: UFix64): @FungibleToken.Vault

    pub fun withdrawNFT(key: String, itemId: UInt64): @NonFungibleToken.NFT 

    pub fun setReceivable(_ flag: Bool)

  }

  // Subdomain resource belongs Domain.NFT
  pub resource Subdomain: SubdomainPublic, SubdomainPrivate {

    pub let id: UInt64
    pub let name: String
    pub let nameHash: String
    pub let parent: String
    pub let parentNameHash: String
    pub let createdAt: UFix64
    access(self) let addresses:  {UInt64: String}
    access(self) let texts: {String: String} 


    init(id: UInt64, name: String, nameHash: String, parent: String, parentNameHash: String) {
      self.id = id
      self.name = name
      self.nameHash = nameHash
      self.addresses = {}
      self.texts ={}
      self.parent = parent
      self.parentNameHash = parentNameHash
      self.createdAt = getCurrentBlock().timestamp
    }

    // Get subdomain full name with parent name
    pub fun getDomainName(): String {
      let domainName = ""
      return domainName.concat(self.name).concat(".").concat(self.parent)
    }

    // Get subdomain property
    pub fun getText(key: String): String? {
      return self.texts[key]
    }

    // Get address of subdomain
    pub fun getAddress(chainType: UInt64): String? {
      return self.addresses[chainType]!
    }

    // get all texts
    pub fun getAllTexts():{String: String}{
      return self.texts
    }

    // get all texts
    pub fun getAllAddresses():{UInt64: String}{
      return self.addresses
    }

    // get subdomain detail
    pub fun getDetail(): SubdomainDetail {
      let owner = Domains.getRecords(self.parentNameHash)!

      let detail = SubdomainDetail(
        id: self.id,
        owner: owner,
        name: self.getDomainName(), 
        nameHash: self.nameHash,
        addresses: self.getAllAddresses(),
        texts: self.getAllTexts(),
        parentName: self.parent,
        createdAt: self.createdAt
      )
      return detail
    }


    pub fun setText(key: String, value: String){
      pre {
        !Domains.isExpired(self.parentNameHash) : Domains.domainExpiredTip
      }
      self.texts[key] = value

      emit SubdmoainTextChanged(nameHash: self.nameHash, key: key, value: value)
    }

    pub fun setAddress(chainType: UInt64, address: String){
      pre {
        !Domains.isExpired(self.parentNameHash) : Domains.domainExpiredTip
      }
      self.addresses[chainType] = address

      emit SubdmoainAddressChanged(nameHash: self.nameHash, chainType: chainType, address: address)

    }

    pub fun removeText(key: String){
      pre {
        !Domains.isExpired(self.parentNameHash) : Domains.domainExpiredTip
      }
      self.texts.remove(key: key)

      emit SubdmoainTextRemoved(nameHash: self.nameHash, key: key)

    }

    pub fun removeAddress(chainType: UInt64){
      pre {
        !Domains.isExpired(self.parentNameHash) : Domains.domainExpiredTip
      }
      self.addresses.remove(key: chainType)

      emit SubdmoainAddressRemoved(nameHash: self.nameHash, chainType: chainType)

    }

  }

  // Domain resource for NFT standard
  pub resource NFT: DomainPublic, DomainPrivate, NonFungibleToken.INFT, MetadataViews.Resolver{

    pub let id: UInt64
    pub let name: String
    pub let nameHash: String
    
    pub let createdAt: UFix64
    // parent domain name
    pub let parent: String
    pub var subdomainCount: UInt64

    pub var receivable: Bool

    access(self) var subdomains: @{String: Subdomain}
    access(self) let addresses:  {UInt64: String}
    access(self) let texts: {String: String}
    access(self) var vaults: @{String: FungibleToken.Vault}
    access(self) var collections: @{String: NonFungibleToken.Collection}

    init(id: UInt64, name: String, nameHash: String, parent: String) {
      self.id = id
      self.name = name
      self.nameHash = nameHash
      self.addresses = {}
      self.texts = {}
      self.subdomainCount = 0
      self.subdomains <- {}
      self.parent = parent
      self.vaults <- {}
      self.collections <- {}
      self.receivable = true
      self.createdAt = getCurrentBlock().timestamp
    }

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


    pub fun resolveView(_ view: Type): AnyStruct? {
      let domainName = self.getDomainName()
      let dataUrl = "https://flowns.org/api/data/domain/".concat(domainName)
      let thumbnailUrl = "https://flowns.org/api/fns?domain=".concat(domainName)
      
      switch view {
        case Type<MetadataViews.Display>():
          return MetadataViews.Display(
              name: domainName,
              description: "Flowns domain ".concat(domainName),
              thumbnail: MetadataViews.HTTPFile(
                  url: thumbnailUrl
              )
          )
        case Type<MetadataViews.Editions>():
            // There is no max number of NFTs that can be minted from this contract
            // so the max edition field value is set to nil
            let editionInfo = MetadataViews.Edition(name: "Flowns Domains NFT Edition", number: self.id, max: nil)
            let editionList: [MetadataViews.Edition] = [editionInfo]
            return MetadataViews.Editions(
                editionList
            )
        case Type<MetadataViews.Serial>():
            return MetadataViews.Serial(
                self.id
            )
        case Type<MetadataViews.Royalties>():
            let receieverCap =  Domains.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            let royalty= MetadataViews.Royalty(receiver: receieverCap, cut: 0.1, description: "Flowns will take 10% as second trade royalty fee")
            return MetadataViews.Royalties([royalty])
            
        case Type<MetadataViews.ExternalURL>():
            return MetadataViews.ExternalURL("https://flowns.org/domain/".concat(domainName))
        case Type<MetadataViews.NFTCollectionData>():
            return MetadataViews.NFTCollectionData(
                storagePath: Domains.CollectionStoragePath,
                publicPath: Domains.CollectionPublicPath,
                providerPath: Domains.CollectionPrivatePath,
                publicCollection: Type<&Domains.Collection{Domains.CollectionPublic}>(),
                publicLinkedType: Type<&Domains.Collection{Domains.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                providerLinkedType: Type<&Domains.Collection{Domains.CollectionPublic,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                    return <- Domains.createEmptyCollection()
                })
            )
        case Type<MetadataViews.NFTCollectionDisplay>():
            let squareMedia = MetadataViews.Media(
                file: MetadataViews.HTTPFile(
                    url: "https://www.flowns.org/assets/flowns_logo_light.svg"
                ),
                mediaType: "image/svg+xml"
            )
            let banerMedia = MetadataViews.Media(
                file: MetadataViews.HTTPFile(
                    url: "https://www.flowns.org/assets/flowns_logo_light.svg"
                ),
                mediaType: "image/svg+xml"
            )
            return MetadataViews.NFTCollectionDisplay(
              name: "The Flowns domain Collection",
              description: "This collection is managed by Flowns and present the ownership of domain.",
              externalURL: MetadataViews.ExternalURL("https://flowns.org"),
              squareImage: squareMedia,
              bannerImage: banerMedia,
              socials: {
                  "twitter": MetadataViews.ExternalURL("https://twitter.com/flownsorg"),
                  "discord": MetadataViews.ExternalURL("https://discord.gg/fXz4gBaYXd"),
                  "website": MetadataViews.ExternalURL("https://flowns.org"),
                  "medium": MetadataViews.ExternalURL("https://medium.com/@Flowns")
              }
            )
        case Type<MetadataViews.Traits>():
          let excludedTraits = ["mintedTime"]
          let traitsView = MetadataViews.dictToTraits(dict: self.texts, excludedNames: excludedTraits)
          // mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
          return traitsView
      }
      return nil
    }
    
    // get domain full name with root domain
    pub fun getDomainName(): String {
      return self.name.concat(".").concat(self.parent)
    }

    pub fun getText(key: String): String? {
      
      return self.texts[key]
    }

    pub fun getAddress(chainType: UInt64): String? {
     
      return self.addresses[chainType]!
    }

    pub fun getAllTexts():{String: String}{
      return self.texts
    }

    pub fun getAllAddresses():{UInt64: String}{
      return self.addresses
    }

    pub fun setText(key: String, value: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        key != "_ethSig": "`_ethSig` is reserved"
      }
      self.texts[key] = value

      emit DmoainTextChanged(nameHash: self.nameHash, key: key, value: value)
    }

    pub fun setAddress(chainType: UInt64, address: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }

      switch chainType {
        case 0 :
          self.addresses[chainType] = address
          emit DmoainAddressChanged(nameHash: self.nameHash, chainType: chainType, address: address)
          return
        case 1 :
          // verify domain name texts with signature
          return
        default:
          return
      }

    }

    pub fun setETHAddress(address: String, publicKey: [UInt8], signature: [UInt8]) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        address.length > 0 : "Cannot verify empty message"
      }

      let prefix = "\u{19}Ethereum Signed Message:\n".concat(address.length.toString())

      assert(Domains.verifySignature(message: address, messagePrefix: prefix, hashTag: nil, hashAlgorithm: HashAlgorithm.KECCAK_256, publicKey: publicKey, signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1, signature: signature) == true, message: "Invalid signature")

      let owner = Domains.getRecords(self.nameHash)
      assert(owner != nil, message: "Can not find owner")

      if owner!.toString() == address {

        let now = getCurrentBlock().timestamp
        let ethAddr = Domains.ethPublicKeyToAddress(publicKey: publicKey)
        let verifyStr = "{".concat("\"timestamp\": \"").concat(now.toString()).concat("\", \"message\": \"").concat(address).concat("\", \"publicKey\": \"").concat(String.encodeHex(publicKey)).concat("\", \"ethAddr\": \"").concat(ethAddr).concat("\"}")

        self.texts["_ethSig"] = verifyStr

        
        self.addresses[1] = ethAddr

        emit DmoainAddressChanged(nameHash: self.nameHash, chainType: 1, address: address)
      }
    }


    pub fun removeText(key: String){
        pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }

      self.texts.remove(key: key)
      
      emit DmoainTextRemoved(nameHash: self.nameHash, key: key)
    }

    pub fun removeAddress(chainType: UInt64){
        pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }

      self.addresses.remove(key: chainType)

      emit DmoainAddressRemoved(nameHash: self.nameHash, chainType: chainType)
    }

    pub fun setSubdomainText(nameHash: String, key: String, value: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.subdomains[nameHash] != nil : "Subdomain not exsit..."
      }

      let subdomain = (&self.subdomains[nameHash] as &Domains.Subdomain?)!
      subdomain.setText(key: key, value: value)
    }

    pub fun setSubdomainAddress(nameHash: String, chainType: UInt64, address: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.subdomains[nameHash] != nil : "Subdomain not exsit..."
      }

      let subdomain = (&self.subdomains[nameHash] as &Domains.Subdomain?)!
      subdomain.setAddress(chainType: chainType, address: address)
    }

    pub fun removeSubdomainText(nameHash: String, key: String) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.subdomains[nameHash] != nil : "Subdomain not exsit..."
      }
      let subdomain = (&self.subdomains[nameHash] as &Domains.Subdomain?)!
      subdomain.removeText(key: key)
    }

    pub fun removeSubdomainAddress(nameHash: String, chainType: UInt64) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.subdomains[nameHash] != nil : "Subdomain not exsit..."
      }
      let subdomain = (&self.subdomains[nameHash] as &Domains.Subdomain?)!
      subdomain.removeAddress(chainType: chainType)
    }
    
    pub fun getDetail(): DomainDetail {

      let owner = Domains.getRecords(self.nameHash) ?? panic("Cannot get owner")
      let expired = Domains.getExpiredTime(self.nameHash) ?? panic("Cannot get expired time")
      
      let subdomainKeys = self.subdomains.keys
      var subdomains: {String: SubdomainDetail} = {}
      for subdomainKey in subdomainKeys {
        let subRef = (&self.subdomains[subdomainKey] as &Subdomain?)!
        let detail = subRef.getDetail()
        subdomains[subdomainKey] = detail
      }

      var vaultBalances: {String: UFix64} = {}
      let vaultKeys = self.vaults.keys
      for vaultKey in vaultKeys {
        let balRef = (&self.vaults[vaultKey] as &FungibleToken.Vault?)!
        let balance = balRef.balance
        vaultBalances[vaultKey] = balance
      }

      var collections:{String: [UInt64]} = {}

      let collectionKeys = self.collections.keys
      for collectionKey in collectionKeys {
        let collectionRef = (&self.collections[collectionKey] as &NonFungibleToken.Collection?)!
        let ids = collectionRef!.getIDs()
        collections[collectionKey] = ids
      }

      let detail = DomainDetail(
        id: self.id,
        owner: owner,
        name: self.getDomainName(), 
        nameHash: self.nameHash,
        expiredAt: expired,
        addresses: self.getAllAddresses(),
        texts: self.getAllTexts(),
        parentName: self.parent,
        subdomainCount: self.subdomainCount,
        subdomains: subdomains,
        createdAt: self.createdAt,
        vaultBalances: vaultBalances,
        collections: collections,
        receivable: self.receivable,
        deprecated: Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id)
      )
      return detail
    }

    pub fun getSubdomainDetail(nameHash: String): SubdomainDetail {
      let subdomainRef = (&self.subdomains[nameHash] as &Subdomain?)!
      return subdomainRef.getDetail()
    }


    pub fun getSubdomainsDetail(): [SubdomainDetail] {
      let ids = self.subdomains.keys
      var subdomains:[SubdomainDetail] = []
      for id in ids {
        let subRef = (&self.subdomains[id] as! &Subdomain?)!
        let detail = subRef.getDetail()
        subdomains.append(detail)
      }
      return subdomains
    }

    // create subdomain with domain
    pub fun createSubDomain(name: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }

      let subForbidChars = self.getText(key: "_forbidChars") ?? "!@#$%^&*()<>? ./"

      for char in subForbidChars.utf8 {
      if name.utf8.contains(char) {
        panic("Domain name illegal ...")
      }
    }
    
      let domainHash = self.nameHash.slice(from: 2, upTo: 66)
      let nameSha = String.encodeHex(HashAlgorithm.SHA3_256.hash(name.utf8))
      let nameHash = "0x".concat(String.encodeHex(HashAlgorithm.SHA3_256.hash(domainHash.concat(nameSha).utf8)))
      
      if self.subdomains[nameHash] != nil {
        panic("Subdomain already existed.")
      }
      let subdomain <- create Subdomain(
        id: self.subdomainCount,
        name: name,
        nameHash: nameHash,
        parent: self.getDomainName(),
        parentNameHash: self.nameHash
      )

      let oldSubdomain <- self.subdomains[nameHash] <- subdomain
      self.subdomainCount = self.subdomainCount + (1 as UInt64)
      
      emit SubDomainCreated(id: self.subdomainCount, hash: nameHash)

      destroy oldSubdomain
    }

    pub fun removeSubDomain(nameHash: String){
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }
      self.subdomainCount = self.subdomainCount - (1 as UInt64)
      let oldToken <- self.subdomains.remove(key: nameHash) ?? panic("missing subdomain")

      emit SubDomainRemoved(id: oldToken.id, hash: nameHash)

      destroy oldToken

    }

    pub fun depositVault(from: @FungibleToken.Vault, senderRef: &{FungibleToken.Receiver}?) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.receivable : "Domain is not receivable"
      }
      let typeKey = from.getType().identifier
      // add type whitelist check 
      assert(FNSConfig.checkFTWhitelist(typeKey) == true, message: "FT type is not in inbox whitelist")
      let amount = from.balance
      let address = from.owner?.address
      if self.vaults[typeKey] == nil {
        self.vaults[typeKey] <-! from
      } else {
        let vault = (&self.vaults[typeKey] as &FungibleToken.Vault?)!
        vault.deposit(from: <- from)
      }
      emit DomainVaultDeposited(nameHash: self.nameHash, vaultType: typeKey, amount: amount, from: senderRef?.owner?.address )

    }

    pub fun withdrawVault(key: String, amount: UFix64): @FungibleToken.Vault {
      pre {
        self.vaults[key] != nil : "Vault not exsit..."
      }
      let vaultRef = (&self.vaults[key] as &FungibleToken.Vault?)!
      let balance = vaultRef.balance
      var withdrawAmount = amount
      if amount == 0.0 {
        withdrawAmount = balance
      }
      emit DomainVaultWithdrawn(nameHash: self.nameHash, vaultType: key, amount: balance, from: Domains.getRecords(self.nameHash))
      return <- vaultRef.withdraw(amount: withdrawAmount)
    }

    pub fun addCollection(collection: @NonFungibleToken.Collection) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
        self.receivable : "Domain is not receivable"
      }

      let typeKey = collection.getType().identifier
      assert(FNSConfig.checkNFTWhitelist(typeKey) == true, message: "NFT type is not in inbox whitelist")

      if collection.isInstance(Type<@Domains.Collection>()) {
        panic("Do not nest domain resource")
      }
      let address = collection.owner?.address
      if self.collections[typeKey] == nil {
        self.collections[typeKey] <-! collection
        emit DomainCollectionAdded(nameHash: self.nameHash, collectionType: typeKey)
      } else {
        if collection.getIDs().length > 0 {
          panic("collection not empty ")
        }
        destroy collection
      }
    }

    pub fun checkCollection(key: String): Bool {
      return self.collections[key] != nil
    }

    pub fun depositNFT(key: String, token: @NonFungibleToken.NFT, senderRef: &{NonFungibleToken.CollectionPublic}?) {
      pre {
        self.collections[key] != nil : "Cannot find NFT collection..."
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }
      assert(FNSConfig.checkNFTWhitelist(key) == true, message: "NFT type is not in inbox whitelist")

      let collectionRef = (&self.collections[key] as &NonFungibleToken.Collection?)!

      emit DomainCollectionDeposited(nameHash: self.nameHash, collectionType: key, itemId: token.id, from: senderRef?.owner?.address)

      collectionRef.deposit(token: <- token)
    }

    pub fun withdrawNFT(key: String, itemId: UInt64): @NonFungibleToken.NFT {
      pre {
        self.collections[key] != nil : "Cannot find NFT collection..."
      }
      let collectionRef = (&self.collections[key] as &NonFungibleToken.Collection?)!

      emit DomainCollectionWithdrawn(nameHash: self.nameHash, collectionType: key, itemId: itemId, from: Domains.getRecords(self.nameHash))

      return <- collectionRef.withdraw(withdrawID: itemId)
    }

    pub fun setReceivable(_ flag: Bool) {
      pre {
        !Domains.isExpired(self.nameHash) : Domains.domainExpiredTip
        !Domains.isDeprecated(nameHash: self.nameHash, domainId: self.id) : Domains.domainDeprecatedTip
      }
      self.receivable = flag
      if flag == false {
        emit DomainReceiveClosed(name: self.getDomainName())
      } else {
        emit DomainReceiveOpened(name: self.getDomainName())
      }
    }
    
    destroy() {
      destroy self.subdomains
      destroy self.vaults
      destroy self.collections
    }
  }

  pub resource interface CollectionPublic {

    pub fun deposit(token: @NonFungibleToken.NFT)

    pub fun getIDs(): [UInt64]

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT

    pub fun borrowDomain(id: UInt64): &{Domains.DomainPublic}

    pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver}
  }

  // return the content for this NFT
  pub resource interface CollectionPrivate {

    access(account) fun mintDomain(name: String, nameHash: String, parentName: String, expiredAt: UFix64, receiver: Capability<&{NonFungibleToken.Receiver}>)

    pub fun borrowDomainPrivate(_ id: UInt64): &Domains.NFT

  }


  // NFT collection 
  pub resource Collection: CollectionPublic, CollectionPrivate, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {

    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    init () {
      self.ownedNFTs <- {}
    }

    // withdraw removes an NFT from the collection and moves it to the caller
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let domain <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing domain")
      
      emit Withdraw(id: domain.id, from: self.owner?.address)

      return <-domain
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {

      let token <- token as! @Domains.NFT
      let id: UInt64 = token.id
      let nameHash = token.nameHash

      if Domains.isExpired(nameHash) {
        panic(Domains.domainExpiredTip)
      }

      if Domains.isDeprecated(nameHash: token.nameHash, domainId: token.id) {
        panic(Domains.domainDeprecatedTip)
      }
      // update the owner record for new domain owner
      
      Domains.updateRecords(nameHash: nameHash, address: self.owner?.address)
      
      // add the new token to the dictionary which removes the old one
      let oldToken <- self.ownedNFTs[id] <- token

      emit Deposit(id: id,to: self.owner?.address)

      destroy oldToken
    }

    // getIDs returns an array of the IDs that are in the collection
    pub fun getIDs(): [UInt64] {

      return self.ownedNFTs.keys
    }

    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }
    
    // Borrow domain for public use
    pub fun borrowDomain(id: UInt64): &{Domains.DomainPublic} {
      pre {
        self.ownedNFTs[id] != nil: "domain doesn't exist"
      }
      let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
      return ref! as! &Domains.NFT
    }

    // Borrow domain for domain owner 
    pub fun borrowDomainPrivate(_ id: UInt64): &Domains.NFT {
      pre {
        self.ownedNFTs[id] != nil: "domain doesn't exist"
      }
      let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT?
      return ref! as! &Domains.NFT
    }

     pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
        let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        let domainNFT = nft as! &Domains.NFT
        return domainNFT as &AnyResource{MetadataViews.Resolver}
      }


    access(account) fun mintDomain(name: String, nameHash: String, parentName: String, expiredAt: UFix64, receiver: Capability<&{NonFungibleToken.Receiver}>){
      
      if Domains.getRecords(nameHash) != nil {
        let isExpired = Domains.isExpired(nameHash)

        if isExpired == false {
          panic("The domain is not available")
        }
        let currentOwnerAddr = Domains.getRecords(nameHash)!
        let account = getAccount(currentOwnerAddr)

        var deprecatedDomain: &{Domains.DomainPublic}? = nil

        let currentId = Domains.getDomainId(nameHash)
        
        let deprecatedInfo = DomainDeprecatedInfo(
          id: currentId!,
          owner: currentOwnerAddr,
          name: name,
          nameHash:nameHash,
          parentName: parentName,
          deprecatedAt: getCurrentBlock().timestamp,
          trigger: receiver.address
        )
        
        var deprecatedRecords: {UInt64: DomainDeprecatedInfo} = Domains.getDeprecatedRecords(nameHash) ?? {}

        deprecatedRecords[currentId!] = deprecatedInfo

        Domains.updateDeprecatedRecords(nameHash: nameHash, records: deprecatedRecords)
       
      }

      let domain <- create Domains.NFT(
        id: Domains.totalSupply,
        name: name,
        nameHash: nameHash,
        parent: parentName,
      )
      let nft <- domain
      
      Domains.updateRecords(nameHash: nameHash, address: receiver.address)
      Domains.updateExpired(nameHash: nameHash, time: expiredAt)
      Domains.updateIdMap(nameHash: nameHash, id: nft.id)
      Domains.totalSupply = Domains.totalSupply + 1 as UInt64

      emit DomainMinted(id: nft.id, name: name, nameHash: nameHash, parentName: parentName, expiredAt: expiredAt, receiver: receiver.address)
      receiver.borrow()!.deposit(token: <- nft)
    }

    destroy() {
      destroy self.ownedNFTs
    }
  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {

    let collection <- create Collection()
    return <- collection
  }

  // Get domain's expired time in timestamp 
  pub fun getExpiredTime(_ nameHash: String) : UFix64? {
    return self.expired[nameHash]
  }

  // Get domain's expired status
  pub fun isExpired(_ nameHash: String): Bool {    
    let currentTimestamp = getCurrentBlock().timestamp
    let expiredTime =  self.expired[nameHash]
    if expiredTime != nil {
      return currentTimestamp >= expiredTime!
    }
    return false
  }

  pub fun isDeprecated(nameHash: String, domainId: UInt64): Bool {
    let deprecatedRecords = self.deprecated[nameHash] ?? {}
    return deprecatedRecords[domainId] != nil
  }

  // Get domain's owner address
  pub fun getRecords(_ nameHash: String) : Address? {
    let address = self.records[nameHash]
    return address
  }

  // Get domain's id by namehash
  pub fun getDomainId(_ nameHash: String) : UInt64? {
    let id = self.idMap[nameHash]
    return id
  }

  pub fun getDeprecatedRecords(_ nameHash: String): {UInt64: DomainDeprecatedInfo}? {
    return self.deprecated[nameHash]
  }

  pub fun getAllRecords(): {String: Address} {
    return self.records
  }

  pub fun getAllExpiredRecords(): {String: UFix64} {
    return self.expired
  }

  pub fun getAllDeprecatedRecords(): {String: {UInt64: DomainDeprecatedInfo }} {
    return self.deprecated
  }

  pub fun getIdMap(): {String: UInt64 } {
    return self.idMap
  }

  pub fun verifySignature(message: String, messagePrefix: String?, hashTag: String?, hashAlgorithm: HashAlgorithm, publicKey: [UInt8], signatureAlgorithm: SignatureAlgorithm, signature: [UInt8]) :Bool {
      
    let messageToVerify = (messagePrefix ?? "").concat(message)
    let keyToVerify = PublicKey(publicKey: publicKey, signatureAlgorithm: signatureAlgorithm)
    let isValid = keyToVerify.verify(
        signature: signature,
        signedData: messageToVerify.utf8,
        domainSeparationTag: hashTag ?? "",
        hashAlgorithm: hashAlgorithm
    )
    if !isValid {
        return false
    }
    return true
  }

   pub fun ethPublicKeyToAddress(publicKey:[UInt8]) :String {
    pre{
      publicKey.length > 0 : "Invalid public key"
    }
    let publicKeyStr = String.encodeHex(publicKey)
    // let pk = publicKeyStr.slice(from: 2, upTo: publicKey.length)
    let pkArr = publicKeyStr.decodeHex()
    let hashed = HashAlgorithm.KECCAK_256.hash(pkArr)
    let hashedStr = String.encodeHex(hashed)
    let len = hashedStr.length
    let addr = hashedStr.slice(from: len-40, upTo: len)

    return "0x".concat(addr)

   }

  access(account) fun updateDeprecatedRecords(nameHash: String, records: {UInt64: DomainDeprecatedInfo}) {
    self.deprecated[nameHash] = records
  }

  // update records in case domain name not match hash
  access(account) fun updateRecords(nameHash: String, address: Address?) {
    self.records[nameHash] = address
  }

  access(account) fun updateExpired(nameHash: String, time: UFix64) {
    self.expired[nameHash] = time
  }

  access(account) fun updateIdMap(nameHash: String, id: UInt64) {
    self.idMap[nameHash] = id
  }

	init() {

    self.totalSupply = 0
    self.CollectionPublicPath =/public/fnsDomainCollection
    self.CollectionStoragePath =/storage/fnsDomainCollection
    self.CollectionPrivatePath =/private/fnsDomainCollection
    self.domainExpiredTip =  "Domain expired, please renew it."
    self.domainDeprecatedTip =  "Domain deprecated."
    self.records = {}
    self.expired = {}
    self.deprecated = {}
    self.idMap = {}
    let account = self.account
    account.save(<- Domains.createEmptyCollection(), to: Domains.CollectionStoragePath)
    account.link<&Domains.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, Domains.CollectionPublic}>(Domains.CollectionPublicPath, target: Domains.CollectionStoragePath)
    account.link<&Domains.Collection>(Domains.CollectionPrivatePath, target: Domains.CollectionStoragePath)
    emit ContractInitialized()
	}
}

 