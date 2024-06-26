import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"
import FIND from "./FIND.cdc"
import FindForgeOrder from "./FindForgeOrder.cdc"
import Profile from "./Profile.cdc"


pub contract FindForge {

    pub event Minted(nftType: String, id: UInt64, uuid: UInt64, nftName: String, nftThumbnail: String, from: Address, fromName: String, to: Address, toName: String?)

    access(contract) let minterPlatforms : {Type : {String: MinterPlatform}}
    access(contract) let verifier : @Verifier

    access(contract) let forgeTypes : @{Type : {Forge}}
    access(contract) let publicForges : [Type]
    access(contract) var platformCut: UFix64 

    pub struct MinterPlatform {
        pub let platform: Capability<&{FungibleToken.Receiver}>
        pub let platformPercentCut: UFix64
        pub let name: String 
        pub let minter: Address

        pub var description: String 
        pub var externalURL: String 
        pub var squareImage: String 
        pub var bannerImage: String 
        pub let minterCut: UFix64?
        pub var socials: {String : String}

        init(name: String, platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64, minterCut: UFix64? ,description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
            self.name=name
            self.minter=FIND.lookupAddress(self.name)!
            self.platform=platform
            self.platformPercentCut=platformPercentCut
            self.description=description 
            self.externalURL=externalURL 
            self.squareImage=squareImage 
            self.bannerImage=bannerImage
            self.minterCut=minterCut 
            self.socials=socials
        }

        pub fun getMinterFTReceiver() : Capability<&{FungibleToken.Receiver}> {
            return getAccount(self.minter).getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        }

        pub fun updateExternalURL(_ d: String) {
            self.externalURL = d
        }

        pub fun updateDesription(_ d: String) {
            self.description = d
        }

        pub fun updateSquareImagen(_ d: String) {
            self.squareImage = d
        }

        pub fun updateBannerImage(_ d: String) {
            self.bannerImage = d
        }

        pub fun updateSocials(_ d: {String : String}) {
            self.socials = d
        }

    }

    // This is an empty resource that is created and passed into mint methods to verify that it comes from .find
    pub resource Verifier {

    }

    // ForgeMinter Interface 
    pub resource interface Forge{
        pub fun mint(platform: MinterPlatform, data: AnyStruct, verifier: &Verifier) : @NonFungibleToken.NFT 
        pub fun addContractData(platform: MinterPlatform, data: AnyStruct, verifier: &Verifier)
    }

    access(contract) fun borrowForge(_ type: Type) : &{Forge}? {
        return &FindForge.forgeTypes[type] as &{Forge}?
    }

    pub fun getMinterPlatform(name: String, forgeType: Type) : MinterPlatform? {
        if FindForge.minterPlatforms[forgeType] == nil {
            return nil
        }
        return FindForge.minterPlatforms[forgeType]![name]
    }

    pub fun getMinterPlatformsByName() : {Type : {String : MinterPlatform}} {
        return FindForge.minterPlatforms
    }

    pub fun checkMinterPlatform(name: String, forgeType: Type) : Bool {
        if FindForge.minterPlatforms[forgeType] == nil {
            return false
        }
        if FindForge.minterPlatforms[forgeType]![name] == nil {
            return false
        } else if FindForge.minterPlatforms[forgeType]![name]!.description == "" {
            return false
        }
        return true 
    }

    pub fun setMinterPlatform(lease: &FIND.Lease, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            panic("This forge type is not supported. type : ".concat(forgeType.identifier))
        }

        if description == "" {
            panic("Description of collection cannot be empty")
        }

        let name = lease.getName() 
        if FindForge.minterPlatforms[forgeType]![name] == nil {
            if !FindForge.publicForges.contains(forgeType) {
                panic("This forge is not supported publicly. Forge Type : ".concat(forgeType.identifier))
            }
        }

        // If they have a premium forge, platform will not take any royalty
        if lease.checkAddon(addon: "premiumForge") {
            let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
            let minterPlatform = MinterPlatform(name:name, platform:receiverCap, platformPercentCut: 0.0, minterCut: minterCut ,description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials) 

            FindForge.minterPlatforms[forgeType]!.insert(key: name, minterPlatform)
            return
        }

        if lease.checkAddon(addon: "forge") {
            let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
            let minterPlatform = MinterPlatform(name:name, platform:receiverCap, platformPercentCut: FindForge.platformCut, minterCut: minterCut ,description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials) 

            FindForge.minterPlatforms[forgeType]!.insert(key: name, minterPlatform)
            return
        }

        panic("Please purchase forge addon to start forging. Name: ".concat(lease.getName()))
    }

    access(account) fun adminSetMinterPlatform(leaseName: String, forgeType: Type, minterCut: UFix64?, description: String, externalURL: String, squareImage: String, bannerImage: String, socials: {String : String}) {
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            FindForge.addPrivateForgeType(name: leaseName, forgeType: forgeType)
        }

        if description == "" {
            panic("Description of collection cannot be empty")
        }

        let user = FIND.lookupAddress(leaseName) ?? panic("Cannot find lease owner. Lease : ".concat(leaseName))
        let leaseCollection = getAccount(user).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow() ?? panic("Cannot borrow reference to lease collection of user : ".concat(leaseName))

        // If they have a premium forge, platform will not take any royalty
        if leaseCollection.checkAddon(name: leaseName, addon: "premiumForge") {
            let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
            let minterPlatform = MinterPlatform(name:leaseName, platform:receiverCap, platformPercentCut: 0.0, minterCut: minterCut ,description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials) 

            FindForge.minterPlatforms[forgeType]!.insert(key: leaseName, minterPlatform)
            return
        }

        if leaseCollection.checkAddon(name: leaseName, addon: "forge") {
            let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
            let minterPlatform = MinterPlatform(name:leaseName, platform:receiverCap, platformPercentCut: FindForge.platformCut, minterCut: minterCut ,description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socials) 

            FindForge.minterPlatforms[forgeType]!.insert(key: leaseName, minterPlatform)
            return
        }

        panic("Please give the user forge addon to start forging. Name: ".concat(leaseName))
    }

    pub fun removeMinterPlatform(lease: &FIND.Lease, forgeType: Type) {
        if FindForge.minterPlatforms[forgeType] == nil {
            panic("This minter platform does not exist. Forge Type : ".concat(forgeType.identifier))
        }
        let name = lease.getName() 

        if FindForge.minterPlatforms[forgeType]![name] == nil {
            panic("This user does not have corresponding minter platform under this forge.  Forge Type : ".concat(forgeType.identifier))
        }

        FindForge.minterPlatforms[forgeType]!.remove(key: name)
    }

    access(account) fun mintAdmin(leaseName: String, forgeType: Type , data: AnyStruct, receiver: &{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}) {
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            panic("The minter platform is not set. Please set up properly before mint.")
        }

        let minterPlatform = FindForge.minterPlatforms[forgeType]![leaseName] ?? panic("The minter platform is not set. Please set up properly before mint.")

        if minterPlatform.description == "" {
            panic("Please set up minter platform before mint")
        }

        let verifier = self.borrowVerifier()

        let forge = FindForge.borrowForge(forgeType) ?? panic("The forge type passed in is not supported. Forge Type : ".concat(forgeType.identifier))

        let nft <- forge.mint(platform: minterPlatform, data: data, verifier: verifier) 

        let id = nft.id 
        let uuid = nft.uuid 
        let nftType = nft.getType().identifier
        receiver.deposit(token: <- nft)

        /*
        let vr = receiver.borrowViewResolver(id: id)
        let view = vr.resolveView(Type<MetadataViews.Display>())  ?? panic("The minting nft should implement MetadataViews Display view.") 
        let display = view as! MetadataViews.Display
        let nftName = display.name 
        let thumbnail = display.thumbnail.uri()
        let to = receiver.owner!.address 
        let toName = FIND.reverseLookup(to)
        let new = FIND.reverseLookup(to)
        let from = FindForge.account.address

        emit Minted(nftType: nftType, id: id, uuid: uuid, nftName: nftName, nftThumbnail: thumbnail, from: from, fromName: leaseName, to: to, toName: toName)
        */

    }

    pub fun orderForge(lease: &FIND.Lease, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay){
        if !lease.checkAddon(addon: "forge") && !lease.checkAddon(addon: "premiumForge") {
            panic("Please purchase forge addon to start forging. Name: ".concat(lease.getName()))
        }

        FindForgeOrder.orderForge(leaseName: lease.getName(), mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
    }

    access(account) fun adminOrderForge(leaseName: String, mintType: String, minterCut: UFix64?, collectionDisplay: MetadataViews.NFTCollectionDisplay){
        FindForgeOrder.orderForge(leaseName: leaseName, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
    }

    access(account) fun cancelForgeOrder(leaseName: String, mintType: String) {
        FindForgeOrder.cancelForgeOrder(leaseName: leaseName, mintType: mintType)
    }

    access(account) fun fulfillForgeOrder(_ contractName: String, forgeType: Type) : MetadataViews.NFTCollectionDisplay {
        let order = FindForgeOrder.fulfillForgeOrder(contractName, forgeType: forgeType)
        let c = order.collectionDisplay
        let s : {String : String} = {}
        for social in c.socials.keys {
            s[social] = c.socials[social]!.url
        } 
        FindForge.adminSetMinterPlatform(leaseName: order.leaseName, 
        forgeType: forgeType, 
        minterCut: order.minterCut, 
        description: c.description, 
        externalURL: c.externalURL.url, 
        squareImage: c.squareImage.file.uri(), 
        bannerImage: c.bannerImage.file.uri(), 
        socials: s)
        return c
    }

    pub fun mint (lease: &FIND.Lease, forgeType: Type , data: AnyStruct, receiver: &{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}) {
        let leaseName = lease.getName()
        FindForge.adminMint(lease: leaseName, forgeType: forgeType , data: data, receiver: receiver)
    }

    access(account) fun adminMint(lease: String, forgeType: Type , data: AnyStruct, receiver: &{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}){
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            panic("The minter platform is not set. Please set up properly before adding contract data.")
        }
        let address = FIND.lookupAddress(lease) ?? panic("This name is not owned by anyone. Name : ".concat(lease))
        let leaseCol = getAccount(address).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow() ?? panic("Cannot borrow lease collection to lease owner. Owner : ".concat(address.toString()))

        if !leaseCol.checkAddon(name:lease, addon: "forge") && !leaseCol.checkAddon(name:lease, addon: "premiumForge") {
            panic("Please purchase forge addon to start forging. Name: ".concat(lease))
        }

        let minterPlatform = FindForge.minterPlatforms[forgeType]![lease] ?? panic("The minter platform is not set. Please set up properly before mint.")

        if minterPlatform.description == "" {
            panic("Please set up minter platform before mint")
        }

        let verifier = self.borrowVerifier()

        let forge = FindForge.borrowForge(forgeType) ?? panic("The forge type passed in is not supported. Forge Type : ".concat(forgeType.identifier))

        let nft <- forge.mint(platform: minterPlatform, data: data, verifier: verifier) 

        let id = nft.id 
        let uuid = nft.uuid 
        let nftType = nft.getType().identifier
        receiver.deposit(token: <- nft)

        let vr = receiver.borrowViewResolver(id: id)
        let view = vr.resolveView(Type<MetadataViews.Display>())  ?? panic("The minting nft should implement MetadataViews Display view.") 
        let display = view as! MetadataViews.Display
        let nftName = display.name 
        let thumbnail = display.thumbnail.uri()
        let to = receiver.owner!.address 
        let toName = FIND.reverseLookup(to)
        let new = FIND.reverseLookup(to)
        let from = FindForge.account.address

        emit Minted(nftType: nftType, id: id, uuid: uuid, nftName: nftName, nftThumbnail: thumbnail, from: from, fromName: "find", to: to, toName: toName)

    }

    pub fun addContractData(lease: &FIND.Lease, forgeType: Type , data: AnyStruct) {
        FindForge.adminAddContractData(lease: lease.getName(), forgeType: forgeType , data: data)
    }

    access(account) fun adminAddContractData(lease: String, forgeType: Type , data: AnyStruct) {

        if !FindForge.minterPlatforms.containsKey(forgeType) {
            panic("The minter platform is not set. Please set up properly before adding contract data.")
        }
        let address = FIND.lookupAddress(lease) ?? panic("This name is not owned by anyone. Name : ".concat(lease))
        let leaseCol = getAccount(address).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow() ?? panic("Cannot borrow lease collection to lease owner. Owner : ".concat(address.toString()))

        if !leaseCol.checkAddon(name:lease, addon: "forge") && !leaseCol.checkAddon(name:lease, addon: "premiumForge") {
            panic("Please purchase forge addon to start forging. Name: ".concat(lease))
        }

        let minterPlatform = FindForge.minterPlatforms[forgeType]![lease] ?? panic("The minter platform is not set. Please set up properly.")

        if minterPlatform.description == "" {
            panic("Please set up minter platform")
        }

        let verifier = self.borrowVerifier()

        let forge = FindForge.borrowForge(forgeType) ?? panic("The forge type passed in is not supported. Forge Type : ".concat(forgeType.identifier))
        forge.addContractData(platform: minterPlatform, data: data, verifier: verifier)
    }

    pub fun addForgeType(_ forge: @{Forge}) {
        if FindForge.forgeTypes.containsKey(forge.getType()) {
            panic("This type is already registered to the registry. Type : ".concat(forge.getType().identifier))
        }

        FindForge.forgeTypes[forge.getType()] <-! forge
    }

    access(account) fun addPublicForgeType(forgeType: Type) {
        if !FindForge.forgeTypes.containsKey(forgeType) {
            panic("This type is not registered to the registry. Type : ".concat(forgeType.identifier))
        }
        if FindForge.publicForges.contains(forgeType) {
            panic("This type is already registered as public forge. Type : ".concat(forgeType.identifier))
        }
        FindForge.publicForges.append(forgeType)
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            FindForge.minterPlatforms[forgeType] = {}
        }
    }

    access(account) fun addPrivateForgeType(name: String, forgeType: Type) {
        if !FindForge.forgeTypes.containsKey(forgeType) {
            panic("This type is not registered to the registry. Type : ".concat(forgeType.identifier))
        }

        if !FindForge.minterPlatforms.containsKey(forgeType) {
            FindForge.minterPlatforms[forgeType] = {}
        }
        let receiverCap=FindForge.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let minterPlatform = MinterPlatform(name:name, platform:receiverCap, platformPercentCut: FindForge.platformCut, minterCut: nil ,description: "", externalURL: "", squareImage: "", bannerImage: "", socials: {}) 
        FindForge.minterPlatforms[forgeType]!.insert(key: name, minterPlatform)
    }

    access(account) fun adminRemoveMinterPlatform(name: String, forgeType: Type) {
        if !FindForge.minterPlatforms.containsKey(forgeType) {
            panic("This type is not registered as minterPlatform. Type : ".concat(forgeType.identifier))
        }
        if !FindForge.minterPlatforms[forgeType]!.containsKey(name) {
            panic("This name is not registered as minterPlatform under this input type. ".concat(name))
        }
        FindForge.minterPlatforms[forgeType]!.remove(key: name)
    }

    access(account) fun removeForgeType(type: Type) {
        if !FindForge.forgeTypes.containsKey(type) {
            panic( "This type is not registered to the registry. Type : ".concat(type.identifier))
        }

        var i = 0
        for forge in FindForge.publicForges {
            if forge == type {
                FindForge.publicForges.remove(at: i)
                break
            }
            i = i + 1
        }
        FindForge.minterPlatforms.remove(key: type)

    }

    access(account) fun setPlatformCut(_ cut: UFix64) {
        FindForge.platformCut = cut
    }

    access(account) fun borrowVerifier() : &Verifier {
        return &self.verifier as &Verifier
    }

    pub fun createForgeAdminProxyClient() : @ForgeAdminProxy {
        return <- create ForgeAdminProxy()
    }

    //interface to use for capability receiver pattern
    pub resource interface ForgeAdminProxyClient {
        pub fun addCapability(_ cap: Capability<&FIND.Network>)
    }

    //admin proxy with capability receiver 
    pub resource ForgeAdminProxy: ForgeAdminProxyClient {

        access(self) var capability: Capability<&FIND.Network>?

        init() {
            self.capability = nil
        }

        pub fun addCapability(_ cap: Capability<&FIND.Network>) {
            pre {
                cap.check() : "Invalid server capablity"
                self.capability == nil : "Server already set"
            }
            self.capability = cap
        }

        pub fun fulfillForgeOrder(_ contractName: String, forgeType: Type) : MetadataViews.NFTCollectionDisplay {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            return FindForge.fulfillForgeOrder(contractName, forgeType: forgeType)
        }
    }

    init() {
        self.minterPlatforms={}
        self.publicForges=[]
        self.forgeTypes<-{}
        self.platformCut=0.025

        self.verifier <- create Verifier()
    }

}
