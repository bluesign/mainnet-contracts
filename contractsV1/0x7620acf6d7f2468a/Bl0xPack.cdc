/*
This tool adds a new entitlemtent called TMP_ENTITLEMENT_OWNER to some functions that it cannot be sure if it is safe to make access(all)
those functions you should check and update their entitlemtents ( or change to all access )

Please see: 
https://cadence-lang.org/docs/cadence-migration-guide/nft-guide#update-all-pub-access-modfiers

IMPORTANT SECURITY NOTICE
Please familiarize yourself with the new entitlements feature because it is extremely important for you to understand in order to build safe smart contracts.
If you change pub to access(all) without paying attention to potential downcasting from public interfaces, you might expose private functions like withdraw 
that will cause security problems for your contract.

*/

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Crypto

import Clock from "./Clock.cdc"

import Debug from "./Debug.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import Bl0x from "./Bl0x.cdc"

access(all)
contract Bl0xPack: NonFungibleToken{ 
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, typeId: UInt64)
	
	access(all)
	event Requeued(packId: UInt64, address: Address)
	
	access(all)
	event Opened(packId: UInt64, address: Address)
	
	access(all)
	event Fulfilled(packId: UInt64, address: Address)
	
	access(all)
	event PackReveal(packId: UInt64, address: Address, packTypeId: UInt64, rewardId: UInt64, nftName: String, nftImage: String, nftRarity: String)
	
	access(all)
	event Purchased(packId: UInt64, address: Address, amount: UFix64)
	
	access(all)
	event MetadataRegistered(typeId: UInt64)
	
	access(all)
	event FulfilledError(packId: UInt64, address: Address?, reason: String)
	
	access(all)
	event OpenDebug(packId: UInt64, message: String)
	
	access(all)
	let PackMetadataStoragePath: StoragePath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let OpenedCollectionPublicPath: PublicPath
	
	access(all)
	let OpenedCollectionStoragePath: StoragePath
	
	access(all)
	let DLQCollectionPublicPath: PublicPath
	
	access(all)
	let DLQCollectionStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(contract)
	let packMetadata:{ UInt64: Metadata}
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnailHash: String?
		
		access(all)
		let thumbnailUrl: String?
		
		access(all)
		let wallet: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let walletType: Type
		
		access(all)
		let price: UFix64
		
		access(all)
		let buyTime: UFix64
		
		access(all)
		let openTime: UFix64
		
		access(all)
		let whiteListTime: UFix64?
		
		access(all)
		let floatEventId: UInt64?
		
		access(all)
		let storageRequirement: UInt64
		
		access(contract)
		let providerCap: Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>
		
		access(contract)
		let royaltyCap: Capability<&{FungibleToken.Receiver}>?
		
		access(contract)
		let royaltyCut: UFix64
		
		access(all)
		let requiresReservation: Bool
		
		init(name: String, description: String, thumbnailUrl: String?, thumbnailHash: String?, wallet: Capability<&{FungibleToken.Receiver}>, price: UFix64, buyTime: UFix64, openTime: UFix64, walletType: Type, providerCap: Capability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection}>, requiresReservation: Bool, royaltyCut: UFix64, royaltyWallet: Capability<&{FungibleToken.Receiver}>, floatEventId: UInt64?, whiteListTime: UFix64?, storageRequirement: UInt64){ 
			self.name = name
			self.description = description
			self.thumbnailUrl = thumbnailUrl
			self.thumbnailHash = thumbnailHash
			self.wallet = wallet
			self.walletType = walletType
			self.price = price
			self.buyTime = buyTime
			self.openTime = openTime
			self.providerCap = providerCap
			
			//If this pack has royalties then they can be added here later. For the current implementations royalties appear to be handled offchain. 
			self.royaltyCap = royaltyWallet
			self.royaltyCut = royaltyCut
			self.floatEventId = floatEventId
			self.whiteListTime = whiteListTime
			self.storageRequirement = storageRequirement
			
			//	10000 //bytes needed for nfts of pack - pack size (since pack will be gone)
			self.requiresReservation = requiresReservation
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getThumbnail():{ MetadataViews.File}{ 
			if let hash = self.thumbnailHash{ 
				return MetadataViews.IPFSFile(cid: hash, path: nil)
			}
			return MetadataViews.HTTPFile(url: self.thumbnailUrl!)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canBeOpened(): Bool{ 
			return self.openTime >= Clock.time()
		}
	}
	
	access(account)
	fun registerMetadata(typeId: UInt64, metadata: Metadata){ 
		emit MetadataRegistered(typeId: typeId)
		self.packMetadata[typeId] = metadata
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadata(typeId: UInt64): Metadata?{ 
		return self.packMetadata[typeId]
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The token's ID
		access(all)
		let id: UInt64
		
		// The token's typeId
		access(self)
		var typeId: UInt64
		
		//this is added to the NFT when it is opened
		access(self)
		var openedBy: Capability<&{NonFungibleToken.Receiver}>?
		
		access(account)
		let hash: String
		
		// init
		//
		init(typeId: UInt64, hash: String){ 
			self.id = self.uuid
			self.typeId = typeId
			self.openedBy = nil
			self.hash = hash
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOpenedBy(): Capability<&{NonFungibleToken.Receiver}>{ 
			if self.openedBy == nil{ 
				panic("Pack is not opened")
			}
			return self.openedBy!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getHash(): String{ 
			return self.hash
		}
		
		access(contract)
		fun setTypeId(_ id: UInt64){ 
			self.typeId = id
		}
		
		access(contract)
		fun resetOpendBy(): Address{ 
			if self.openedBy == nil{ 
				panic("Pack is not opened")
			}
			let cap = self.openedBy!
			self.openedBy = nil
			return cap.address
		}
		
		access(contract)
		fun setOpenedBy(_ cap: Capability<&{NonFungibleToken.Receiver}>){ 
			if self.openedBy != nil{ 
				panic("Pack has already been opened")
			}
			self.openedBy = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTypeID(): UInt64{ 
			return self.typeId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(): Metadata{ 
			return Bl0xPack.getMetadata(typeId: self.typeId)!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<Metadata>(), Type<String>()]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getThumbnail():{ MetadataViews.File}{ 
			return self.getMetadata().getThumbnail()
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let metadata = self.getMetadata()
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: self.getThumbnail())
				case Type<String>():
					return metadata.name
				case Type<Bl0xPack.Metadata>():
					return metadata
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://find.xyz/".concat((self.owner!).address.toString()).concat("/collection/bl0xPack/").concat(self.id.toString()))
				case Type<MetadataViews.Royalties>():
					return Bl0x.royalties
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: Bl0xPack.CollectionStoragePath, publicPath: Bl0xPack.CollectionPublicPath, publicCollection: Type<&Bl0xPack.Collection>(), publicLinkedType: Type<&Bl0xPack.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-Bl0xPack.createEmptyCollection(nftType: Type<@Bl0xPack.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("https://find.xyz/mp/bl0xPack")
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://bl0x.xyz/assets/home/Bl0xlogo.webp"), mediaType: "image")
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1535883931777892352/1661105339/1500x500"), mediaType: "image")
					return MetadataViews.NFTCollectionDisplay(name: "bl0x Pack", description: "Minting a Bl0x triggers the catalyst moment of a big bang scenario. Generating a treasure that is designed to relate specifically to its holder.", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials:{ "discord": MetadataViews.ExternalURL("https://t.co/iY7AhEumR9"), "twitter": MetadataViews.ExternalURL("https://twitter.com/Bl0xNFT")})
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPacksLeftForType(_ type: UInt64): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBl0xPack(id: UInt64): &Bl0xPack.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buy(typeId: UInt64, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buyWithSignature(packId: UInt64, signature: String, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>)
	}
	
	// Collection
	// A collection of Bl0xPack NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		//
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		var nftsPerType:{ UInt64: UInt64}
		
		// since maps are not ordered in cadence this will pick any random key and that works really well
		access(self)
		fun getPackIdForType(_ typeId: UInt64): UInt64?{ 
			for key in self.ownedNFTs.keys{ 
				if let pack = self.borrowBl0xPack(id: key){ 
					if pack.getTypeID() == typeId{ 
						return key
					}
				}
			}
			return nil
		}
		
		//this has to be called on the DLQ collection
		access(TMP_ENTITLEMENT_OWNER)
		fun requeue(packId: UInt64){ 
			let token <- self.withdraw(withdrawID: packId) as! @NFT
			let address = token.resetOpendBy()
			let cap = getAccount(address).capabilities.get<&Collection>(Bl0xPack.CollectionPublicPath)
			let receiver = cap.borrow()!
			receiver.deposit(token: <-token)
			emit Requeued(packId: packId, address: cap.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun open(packId: UInt64, receiverCap: Capability<&{NonFungibleToken.Receiver}>){ 
			if !receiverCap.check(){ 
				panic("Receiver cap is not valid")
			}
			let pack = self.borrowBl0xPack(id: packId)!
			var time = pack.getMetadata().openTime
			let timestamp = Clock.time()
			if timestamp < time{ 
				panic("You cannot open the pack yet")
			}
			let token <- self.withdraw(withdrawID: packId) as! @Bl0xPack.NFT
			token.setOpenedBy(receiverCap)
			
			// establish the receiver for Redeeming Bl0xPack
			let receiver = Bl0xPack.account.capabilities.get<&{NonFungibleToken.Receiver}>(Bl0xPack.OpenedCollectionPublicPath).borrow()!
			
			// deposit for consumption
			receiver.deposit(token: <-token)
			emit Opened(packId: packId, address: (self.owner!).address)
		}
		
		//TODO: pre that needs requiresReservation
		access(TMP_ENTITLEMENT_OWNER)
		fun buyWithSignature(packId: UInt64, signature: String, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>){ 
			pre{ 
				(self.owner!).address == Bl0xPack.account.address:
					"You can only buy pack directly from the Bl0xPack account"
			}
			let nft <- self.withdraw(withdrawID: packId) as! @NFT
			let metadata = nft.getMetadata()
			if !metadata.requiresReservation{ 
				panic("This pack type does not require reservation, use the open buy method")
			}
			var time = metadata.buyTime
			let timestamp = Clock.time()
			if timestamp < time{ 
				panic("You cannot buy the pack yet")
			}
			if vault.getType() != metadata.walletType{ 
				panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
			}
			if metadata.price != vault.balance{ 
				panic("Vault does not contain required amount of FT ".concat(metadata.price.toString()))
			}
			let keyList = Crypto.KeyList()
			let accountKey = ((self.owner!).keys.get(keyIndex: 0)!).publicKey
			
			// Adds the public key to the keyList
			keyList.add(PublicKey(publicKey: accountKey.publicKey, signatureAlgorithm: accountKey.signatureAlgorithm), hashAlgorithm: HashAlgorithm.SHA3_256, weight: 1.0)
			
			// Creates a Crypto.KeyListSignature from the signature provided in the parameters
			let signatureSet: [Crypto.KeyListSignature] = []
			signatureSet.append(Crypto.KeyListSignature(keyIndex: 0, signature: signature.decodeHex()))
			
			// Verifies that the signature is valid and that it was generated from the
			// owner of the collection
			if !keyList.verify(signatureSet: signatureSet, signedData: nft.hash.utf8){ 
				panic("Unable to validate the signature for the pack!")
			}
			if metadata.royaltyCut != 0.0 && metadata.royaltyCap != nil && (metadata.royaltyCap!).check(){ 
				((metadata.royaltyCap!).borrow()!).deposit(from: <-vault.withdraw(amount: vault.balance * metadata.royaltyCut))
			}
			(metadata.wallet.borrow()!).deposit(from: <-vault)
			(collectionCapability.borrow()!).deposit(token: <-nft)
			emit Purchased(packId: packId, address: collectionCapability.address, amount: metadata.price)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buy(typeId: UInt64, vault: @{FungibleToken.Vault}, collectionCapability: Capability<&Collection>){ 
			pre{ 
				(self.owner!).address == Bl0xPack.account.address:
					"You can only buy pack directly from the Bl0xPack account"
			}
			let packId = self.getPackIdForType(typeId)
			if packId == nil{ 
				panic("No more packs of this type")
			}
			let key = packId!
			let nft <- self.withdraw(withdrawID: key) as! @NFT
			let metadata = nft.getMetadata()
			if metadata.requiresReservation{ 
				panic("Cannot buy a pack that requires reservation without a reservation signature and id")
			}
			let user = collectionCapability.address
			let timestamp = Clock.time()
			var whitelisted = false
			if let whiteListTime = metadata.whiteListTime{ 
				
				//TODO: test
				if timestamp < whiteListTime{ 
					panic("You cannot buy the pack yet")
				}
				
				//TODO: test
				if let float = metadata.floatEventId{ 
					whitelisted = Bl0xPack.hasFloat(floatEventId: float, user: collectionCapability.address)
				}
			} else if let float = metadata.floatEventId{ 
				//TODO:test
				if !Bl0xPack.hasFloat(floatEventId: float, user: collectionCapability.address){ 
					panic("Your user does not have the required float with eventId ".concat(float.toString()))
				}
			}
			var time = metadata.buyTime
			if !whitelisted && timestamp < time{ 
				panic("You cannot buy the pack yet")
			}
			if vault.getType() != metadata.walletType{ 
				panic("The vault sent in is not of the desired type ".concat(metadata.walletType.identifier))
			}
			if metadata.price != vault.balance{ 
				panic("Vault does not contain required amount of FT ".concat(metadata.price.toString()))
			}
			
			//TODO: test
			if metadata.royaltyCut != 0.0 && metadata.royaltyCap != nil && (metadata.royaltyCap!).check(){ 
				((metadata.royaltyCap!).borrow()!).deposit(from: <-vault.withdraw(amount: vault.balance * metadata.royaltyCut))
			}
			(metadata.wallet.borrow()!).deposit(from: <-vault)
			(collectionCapability.borrow()!).deposit(token: <-nft)
			emit Purchased(packId: key, address: collectionCapability.address, amount: metadata.price)
		}
		
		// withdraw
		// Removes an NFT from the collection and moves it to the caller
		//
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Could not withdraw nft")
			let nft <- token as! @NFT
			let oldNumber = self.nftsPerType[nft.getTypeID()]!
			self.nftsPerType[nft.getTypeID()] = oldNumber - 1
			emit Withdraw(id: nft.id, from: self.owner?.address)
			return <-nft
		}
		
		// deposit
		// Takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		//
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Bl0xPack.NFT
			let id: UInt64 = token.id
			let oldNumber = self.nftsPerType[token.getTypeID()] ?? 0
			self.nftsPerType[token.getTypeID()] = oldNumber + 1
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs
		// Returns an array of the IDs that are in the collection
		//
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		//return the number of packs left of a type
		access(TMP_ENTITLEMENT_OWNER)
		fun getPacksLeftForType(_ type: UInt64): UInt64{ 
			return self.nftsPerType[type] ?? 0
		}
		
		// borrowNFT
		// Gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		//
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		// borrowBl0xPack
		// Gets a reference to an NFT in the collection as a Bl0xPack.NFT,
		// exposing all of its fields.
		// This is safe as there are no functions that can be called on the Bl0xPack.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBl0xPack(id: UInt64): &Bl0xPack.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Bl0xPack.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let exampleNFT = nft as! &NFT
			return exampleNFT
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// destructor
		//
		// initializer
		//
		init(){ 
			self.ownedNFTs <-{} 
			self.nftsPerType ={} 
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, typeId: UInt64, hash: String){ 
		let nft <- create Bl0xPack.NFT(typeId: typeId, hash: hash)
		emit Minted(id: nft.id, typeId: typeId)
		
		// deposit it in the recipient's account using their reference
		recipient.deposit(token: <-nft)
	}
	
	access(account)
	fun fulfill(packId: UInt64, rewardIds: [UInt64], salt: String){ 
		let openedPacksCollection = Bl0xPack.account.storage.borrow<&Bl0xPack.Collection>(from: Bl0xPack.OpenedCollectionStoragePath)!
		let pack <- openedPacksCollection.withdraw(withdrawID: packId) as! @Bl0xPack.NFT
		let receiver = pack.getOpenedBy()
		if !receiver.check(){ 
			emit FulfilledError(packId: packId, address: receiver.address, reason: "The receiver registered in this pack is not valid")
			self.transferToDLQ(<-pack)
			return
		}
		let hash = pack.getHash()
		let rewards = pack.getMetadata().providerCap
		if !rewards.check(){ 
			emit FulfilledError(packId: packId, address: receiver.address, reason: "Cannot borrow provider capability to withdraw nfts")
			self.transferToDLQ(<-pack)
			return
		}
		let receiverAccount = getAccount(receiver.address)
		let freeStorage = receiverAccount.storage.capacity - receiverAccount.storage.used
		Debug.log("Free capacity from account ".concat(freeStorage.toString()))
		if pack.getMetadata().storageRequirement > freeStorage{ 
			emit FulfilledError(packId: packId, address: receiver.address, reason: "Not enough flow to hold the content of the pack. Please top up your account")
			self.transferToDLQ(<-pack)
			return
		}
		var string = salt
		for id in rewardIds{ 
			var seperator = "-"
			if string != salt{ 
				seperator = ","
			}
			string = string.concat(seperator).concat(id.toString())
		}
		let digest = HashAlgorithm.SHA3_384.hash(string.utf8)
		let digestAsString = String.encodeHex(digest)
		if digestAsString != hash{ 
			emit FulfilledError(packId: packId, address: receiver.address, reason: "The content of the pack was not verified with the hash provided at mint")
			self.transferToDLQ(<-pack)
			return
		}
		let target = receiver.borrow()!
		let source = rewards.borrow()!
		for reward in rewardIds{ 
			let metadata = source.borrowViewResolver(id: reward).resolveView(Type<Bl0x.Metadata>())! as! Bl0x.Metadata
			emit PackReveal(packId: packId, address: receiver.address, packTypeId: pack.getTypeID(), rewardId: reward, nftName: metadata.name, nftImage: metadata.image, nftRarity: metadata.rarity)
			let token <- source.withdraw(withdrawID: reward)
			target.deposit(token: <-token)
		}
		emit Fulfilled(packId: packId, address: receiver.address)
		destroy pack
	}
	
	access(account)
	fun transferToDLQ(_ pack: @NFT){ 
		let dlq = Bl0xPack.account.storage.borrow<&Bl0xPack.Collection>(from: Bl0xPack.DLQCollectionStoragePath)!
		dlq.deposit(token: <-pack)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPacksCollection(): &Bl0xPack.Collection{ 
		return Bl0xPack.account.capabilities.get<&Bl0xPack.Collection>(Bl0xPack.CollectionPublicPath).borrow() ?? panic("Could not borow Bl0xPack collection")
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun canBuy(packTypeId: UInt64, user: Address): Bool{ 
		let packs = Bl0xPack.getPacksCollection()
		let packsLeft = packs.getPacksLeftForType(packTypeId)
		if packsLeft == 0{ 
			return false
		}
		let packMetadata = Bl0xPack.getMetadata(typeId: packTypeId)
		if packMetadata == nil{ 
			return false
		}
		let timestamp = Clock.time()
		let metadata = packMetadata!
		var whitelisted = false
		if let whiteListTime = metadata.whiteListTime{ 
			if timestamp < whiteListTime{ 
				return false
			}
			if let float = metadata.floatEventId{ 
				whitelisted = Bl0xPack.hasFloat(floatEventId: float, user: user)
			}
		} else if let float = metadata.floatEventId{ 
			if !Bl0xPack.hasFloat(floatEventId: float, user: user){ 
				return false
			}
		}
		var time = metadata.buyTime
		if !whitelisted && timestamp < time{ 
			return false
		}
		return true
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun hasFloat(floatEventId: UInt64, user: Address): Bool{ 
		let float = getAccount(user).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>()
		if float == nil{ 
			return false
		}
		let floatsCollection = float!
		let ids = floatsCollection.getIDs()
		for id in ids{ 
			let nft: &FLOAT.NFT = floatsCollection.borrowFLOAT(id: id)!
			if nft.eventId == floatEventId{ 
				return true
			}
		}
		return false
	}
	
	// initializer
	//
	init(){ 
		self.CollectionStoragePath = /storage/Bl0xPackCollection
		self.CollectionPublicPath = /public/Bl0xPackCollection
		self.OpenedCollectionStoragePath = /storage/Bl0xPackOpenedCollection
		self.OpenedCollectionPublicPath = /public/Bl0xPackOpenedCollection
		self.DLQCollectionStoragePath = /storage/Bl0xPackDLQCollection
		self.DLQCollectionPublicPath = /public/Bl0xPackDLQCollection
		self.PackMetadataStoragePath = /storage/Bl0xPackMetadata
		
		//this will not be used, we use UUID as id
		self.totalSupply = 0
		self.packMetadata ={} 
		
		// this contract will hold a Collection that Bl0xPack can be deposited to and Admins can Consume them to transfer nfts to the depositing account
		let openedCollection <- create Collection()
		self.account.storage.save(<-openedCollection, to: self.OpenedCollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Bl0xPack.Collection>(Bl0xPack.OpenedCollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: Bl0xPack.OpenedCollectionPublicPath)
		
		//a DLQ storage slot so that the opener can put items that cannot be opened/transferred here.
		let dlqCollection <- create Collection()
		self.account.storage.save(<-dlqCollection, to: self.DLQCollectionStoragePath)
		var capability_2 = self.account.capabilities.storage.issue<&Bl0xPack.Collection>(Bl0xPack.DLQCollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: Bl0xPack.DLQCollectionPublicPath)
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-self.createEmptyCollection(nftType: Type<@Collection>()), to: self.CollectionStoragePath)
		var capability_3 = self.account.capabilities.storage.issue<&Bl0xPack.Collection>(Bl0xPack.CollectionStoragePath)
		self.account.capabilities.publish(capability_3, at: Bl0xPack.CollectionPublicPath)
		emit ContractInitialized()
	}
}
