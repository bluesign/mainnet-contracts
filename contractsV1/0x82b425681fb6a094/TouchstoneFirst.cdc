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

	// CREATED BY: Touchstone (https://touchstone.city/), a platform crafted by your best friends at Emerald City DAO (https://ecdao.org/).
// STATEMENT: This contract promises to keep the 5% royalty off of primary sales and 2.5% off of secondary sales to Emerald City DAO or risk permanent suspension from participation in the DAO and its tools.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import MintVerifiers from 0x7a696d6136e1dce2

import FUSD from "./../../standardsV1/FUSD.cdc"

import EmeraldPass from "../0x6a07dbeb03167a13/EmeraldPass.cdc"

access(all)
contract TouchstoneFirst: NonFungibleToken{ 
	
	// Collection Information
	access(self)
	let collectionInfo:{ String: AnyStruct}
	
	// Contract Information
	access(all)
	var nextEditionId: UInt64
	
	access(all)
	var nextMetadataId: UInt64
	
	access(all)
	var totalSupply: UInt64
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event TouchstonePurchase(id: UInt64, recipient: Address, metadataId: UInt64, name: String, description: String, image: MetadataViews.IPFSFile, price: UFix64)
	
	access(all)
	event Minted(id: UInt64, recipient: Address, metadataId: UInt64)
	
	access(all)
	event MintBatch(metadataIds: [UInt64], recipients: [Address])
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdministratorStoragePath: StoragePath
	
	// Maps metadataId of NFT to NFTMetadata
	access(account)
	let metadatas:{ UInt64: NFTMetadata}
	
	// Maps the metadataId of an NFT to the primary buyer
	access(account)
	let primaryBuyers:{ Address:{ UInt64: [UInt64]}}
	
	access(account)
	let nftStorage: @{Address:{ UInt64: NFT}}
	
	access(all)
	struct NFTMetadata{ 
		access(all)
		let metadataId: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		// The main image of the NFT
		access(all)
		let image: MetadataViews.IPFSFile
		
		// An optional thumbnail that can go along with it
		// for easier loading
		access(all)
		let thumbnail: MetadataViews.IPFSFile?
		
		// If price is nil, defaults to the collection price
		access(all)
		let price: UFix64?
		
		access(all)
		var extra:{ String: AnyStruct}
		
		access(all)
		let supply: UInt64
		
		access(all)
		let purchasers:{ UInt64: Address}
		
		access(account)
		fun purchased(serial: UInt64, buyer: Address){ 
			self.purchasers[serial] = buyer
		}
		
		init(_name: String, _description: String, _image: MetadataViews.IPFSFile, _thumbnail: MetadataViews.IPFSFile?, _price: UFix64?, _extra:{ String: AnyStruct}, _supply: UInt64){ 
			self.metadataId = TouchstoneFirst.nextMetadataId
			self.name = _name
			self.description = _description
			self.image = _image
			self.thumbnail = _thumbnail
			self.price = _price
			self.extra = _extra
			self.supply = _supply
			self.purchasers ={} 
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		// The 'id' is the same as the 'uuid'
		access(all)
		let id: UInt64
		
		// The 'metadataId' is what maps this NFT to its 'NFTMetadata'
		access(all)
		let metadataId: UInt64
		
		access(all)
		let serial: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(): NFTMetadata{ 
			return TouchstoneFirst.getNFTMetadata(self.metadataId)!
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>(), Type<MetadataViews.NFTView>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let metadata = self.getMetadata()
					return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: metadata.thumbnail ?? metadata.image)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: TouchstoneFirst.CollectionStoragePath, publicPath: TouchstoneFirst.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-TouchstoneFirst.createEmptyCollection(nftType: Type<@TouchstoneFirst.Collection>())
						})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://touchstone.city/discover/".concat((self.owner!).address.toString()).concat("/TouchstoneFirst"))
				case Type<MetadataViews.NFTCollectionDisplay>():
					let squareMedia = MetadataViews.Media(file: TouchstoneFirst.getCollectionAttribute(key: "image") as! MetadataViews.IPFSFile, mediaType: "image")
					
					// If a banner image exists, use it
					// Otherwise, default to the main square image
					var bannerMedia: MetadataViews.Media? = nil
					if let bannerImage = TouchstoneFirst.getOptionalCollectionAttribute(key: "bannerImage") as! MetadataViews.IPFSFile?{ 
						bannerMedia = MetadataViews.Media(file: bannerImage, mediaType: "image")
					}
					return MetadataViews.NFTCollectionDisplay(name: TouchstoneFirst.getCollectionAttribute(key: "name") as! String, description: TouchstoneFirst.getCollectionAttribute(key: "description") as! String, externalURL: MetadataViews.ExternalURL("https://touchstone.city/discover/".concat((self.owner!).address.toString()).concat("/TouchstoneFirst")), squareImage: squareMedia, bannerImage: bannerMedia ?? squareMedia, socials: TouchstoneFirst.getCollectionAttribute(key: "socials") as!{ String: MetadataViews.ExternalURL})
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([													// This is for Emerald City in favor of producing Touchstone, a free platform for our users. Failure to keep this in the contract may result in permanent suspension from Emerald City.
													MetadataViews.Royalty(receiver: getAccount(0x5643fd47a29770e7).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver), cut: 0.025, // 2.5% royalty on secondary sales																																															  
																																															  description: "Emerald City DAO receives a 2.5% royalty from secondary sales because this collection was created using Touchstone (https://touchstone.city/), a tool for creating your own NFT collections, crafted by Emerald City DAO.")])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.getMetadata().extra, excludedNames: nil)
				case Type<MetadataViews.NFTView>():
					return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?, externalURL: self.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL?, collectionData: self.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?, collectionDisplay: self.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay?, royalties: self.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties?, traits: self.resolveView(Type<MetadataViews.Traits>()) as! MetadataViews.Traits?)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_metadataId: UInt64, _serial: UInt64, _recipient: Address){ 
			pre{ 
				TouchstoneFirst.metadatas[_metadataId] != nil:
					"This NFT does not exist yet."
				_serial < (TouchstoneFirst.getNFTMetadata(_metadataId)!).supply:
					"This serial does not exist for this metadataId."
				!(TouchstoneFirst.getNFTMetadata(_metadataId)!).purchasers.containsKey(_serial):
					"This serial has already been purchased."
			}
			self.id = self.uuid
			self.metadataId = _metadataId
			self.serial = _serial
			
			// Update the buyers list so we keep track of who is purchasing
			if let buyersRef = &TouchstoneFirst.primaryBuyers[_recipient] as auth(Mutate) &{UInt64: [UInt64]}?{ 
				if let metadataIdMap = buyersRef[_metadataId] as &[UInt64]?{ 
					metadataIdMap.append(_serial)
				} else{ 
					buyersRef[_metadataId] = [_serial]
				}
			} else{ 
				TouchstoneFirst.primaryBuyers[_recipient] ={ _metadataId: [_serial]}
			}
			
			// Update who bought this serial inside NFTMetadata so it cannot be purchased again.
			let metadataRef = (&TouchstoneFirst.metadatas[_metadataId] as &NFTMetadata?)!
			metadataRef.purchased(serial: _serial, buyer: _recipient)
			TouchstoneFirst.totalSupply = TouchstoneFirst.totalSupply + 1
			emit Minted(id: self.id, recipient: _recipient, metadataId: _metadataId)
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an 'UInt64' ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary
			self.ownedNFTs[id] <-! token
			emit Deposit(id: id, to: self.owner?.address)
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let token = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nft = token as! &NFT
			return nft as &{ViewResolver.Resolver}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(){ 
			if let storage = &TouchstoneFirst.nftStorage[(self.owner!).address] as auth(Mutate) &{UInt64: NFT}?{ 
				for id in storage.keys{ 
					self.deposit(token: <-storage.remove(key: id)!)
				}
			}
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	// A function to mint NFTs. 
	// You can only call this function if minting
	// is currently active.
	access(TMP_ENTITLEMENT_OWNER)
	fun mintNFT(metadataId: UInt64, recipient: &{NonFungibleToken.Receiver}, payment: @FlowToken.Vault, serial: UInt64): UInt64{ 
		pre{ 
			self.canMint():
				"Minting is currently closed by the Administrator!"
			payment.balance == self.getPriceOfNFT(metadataId):
				"Payment does not match the price. You passed in ".concat(payment.balance.toString()).concat(" but this NFT costs ").concat((self.getPriceOfNFT(metadataId)!).toString())
		}
		let price: UFix64 = self.getPriceOfNFT(metadataId)!
		
		// Confirm recipient passes all verifiers
		for verifier in self.getMintVerifiers(){ 
			let params ={ "minter": (recipient.owner!).address}
			if let error = verifier.verify(params){ 
				panic(error)
			}
		}
		
		// Handle Emerald City DAO royalty (5%)
		let EmeraldCityTreasury = getAccount(0x5643fd47a29770e7).capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!
		let emeraldCityCut: UFix64 = 0.05 * price
		
		// Handle royalty to user that was configured upon creation
		if let royalty = TouchstoneFirst.getOptionalCollectionAttribute(key: "royalty") as! MetadataViews.Royalty?{ 
			(royalty.receiver.borrow()!).deposit(from: <-payment.withdraw(amount: price * royalty.cut))
		}
		EmeraldCityTreasury.deposit(from: <-payment.withdraw(amount: emeraldCityCut))
		
		// Give the rest to the collection owner
		let paymentRecipient = self.account.capabilities.get<&FlowToken.Vault>(/public/flowTokenReceiver).borrow<&FlowToken.Vault>()!
		paymentRecipient.deposit(from: <-payment)
		
		// Mint the nft 
		let nft <- create NFT(_metadataId: metadataId, _serial: serial, _recipient: (recipient.owner!).address)
		let nftId: UInt64 = nft.id
		let metadata = self.getNFTMetadata(metadataId)!
		self.collectionInfo["profit"] = self.getCollectionAttribute(key: "profit") as! UFix64 + price
		
		// Emit event
		emit TouchstonePurchase(id: nftId, recipient: (recipient.owner!).address, metadataId: metadataId, name: metadata.name, description: metadata.description, image: metadata.image, price: price)
		
		// Deposit nft
		recipient.deposit(token: <-nft)
		return nftId
	}
	
	access(all)
	resource Administrator{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createNFTMetadata(name: String, description: String, imagePath: String, thumbnailPath: String?, ipfsCID: String, price: UFix64?, extra:{ String: AnyStruct}, supply: UInt64){ 
			TouchstoneFirst.metadatas[TouchstoneFirst.nextMetadataId] = NFTMetadata(_name: name, _description: description, _image: MetadataViews.IPFSFile(cid: ipfsCID, path: imagePath), _thumbnail: thumbnailPath == nil ? nil : MetadataViews.IPFSFile(cid: ipfsCID, path: thumbnailPath), _price: price, _extra: extra, _supply: supply)
			TouchstoneFirst.nextMetadataId = TouchstoneFirst.nextMetadataId + 1
		}
		
		// mintNFT mints a new NFT and deposits 
		// it in the recipients collection
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(metadataId: UInt64, serial: UInt64, recipient: Address){ 
			pre{ 
				EmeraldPass.isActive(user: TouchstoneFirst.account.address):
					"You must have an active Emerald Pass subscription to airdrop NFTs. You can purchase Emerald Pass at https://pass.ecdao.org/"
			}
			let nft <- create NFT(_metadataId: metadataId, _serial: serial, _recipient: recipient)
			if let recipientCollection = getAccount(recipient).capabilities.get<&TouchstoneFirst.Collection>(TouchstoneFirst.CollectionPublicPath).borrow<&TouchstoneFirst.Collection>(){ 
				recipientCollection.deposit(token: <-nft)
			} else if let storage = &TouchstoneFirst.nftStorage[recipient] as auth(Mutate) &{UInt64: NFT}?{ 
				storage[nft.id] <-! nft
			} else{ 
				TouchstoneFirst.nftStorage[recipient] <-!{ nft.id: <-nft}
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintBatch(metadataIds: [UInt64], serials: [UInt64], recipients: [Address]){ 
			pre{ 
				metadataIds.length == recipients.length:
					"You need to pass in an equal number of metadataIds and recipients."
			}
			var i = 0
			while i < metadataIds.length{ 
				self.mintNFT(metadataId: metadataIds[i], serial: serials[i], recipient: recipients[i])
				i = i + 1
			}
			emit MintBatch(metadataIds: metadataIds, recipients: recipients)
		}
		
		// create a new Administrator resource
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Administrator{ 
			return <-create Administrator()
		}
		
		// change piece of collection info
		access(TMP_ENTITLEMENT_OWNER)
		fun changeField(key: String, value: AnyStruct){ 
			TouchstoneFirst.collectionInfo[key] = value
		}
	}
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Get information about a NFTMetadata
	access(TMP_ENTITLEMENT_OWNER)
	view fun getNFTMetadata(_ metadataId: UInt64): NFTMetadata?{ 
		return self.metadatas[metadataId]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTMetadatas():{ UInt64: NFTMetadata}{ 
		return self.metadatas
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPrimaryBuyers():{ Address:{ UInt64: [UInt64]}}{ 
		return self.primaryBuyers
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCollectionInfo():{ String: AnyStruct}{ 
		let collectionInfo = self.collectionInfo
		collectionInfo["metadatas"] = self.metadatas
		collectionInfo["primaryBuyers"] = self.primaryBuyers
		collectionInfo["totalSupply"] = self.totalSupply
		collectionInfo["nextMetadataId"] = self.nextMetadataId
		collectionInfo["version"] = 1
		return collectionInfo
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun getCollectionAttribute(key: String): AnyStruct{ 
		return self.collectionInfo[key] ?? panic(key.concat(" is not an attribute in this collection."))
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getOptionalCollectionAttribute(key: String): AnyStruct?{ 
		return self.collectionInfo[key]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMintVerifiers(): [{MintVerifiers.IVerifier}]{ 
		return self.getCollectionAttribute(key: "mintVerifiers") as! [{MintVerifiers.IVerifier}]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	view fun canMint(): Bool{ 
		return self.getCollectionAttribute(key: "minting") as! Bool
	}
	
	// Returns nil if an NFT with this metadataId doesn't exist
	access(TMP_ENTITLEMENT_OWNER)
	view fun getPriceOfNFT(_ metadataId: UInt64): UFix64?{ 
		if let metadata: TouchstoneFirst.NFTMetadata = self.getNFTMetadata(metadataId){ 
			let defaultPrice: UFix64 = self.getCollectionAttribute(key: "price") as! UFix64
			if self.getCollectionAttribute(key: "lotteryBuying") as! Bool{ 
				return defaultPrice
			}
			return metadata.price ?? defaultPrice
		}
		return nil
	}
	
	// Returns an mapping of `id` to NFTMetadata
	// for the NFTs a user can claim
	access(TMP_ENTITLEMENT_OWNER)
	fun getClaimableNFTs(user: Address):{ UInt64: NFTMetadata}{ 
		let answer:{ UInt64: NFTMetadata} ={} 
		if let storage = &TouchstoneFirst.nftStorage[user] as auth(Mutate) &{UInt64: NFT}?{ 
			for id in storage.keys{ 
				let nftRef = (storage[id] as &TouchstoneFirst.NFT?)!
				answer[id] = self.getNFTMetadata(nftRef.metadataId)
			}
		}
		return answer
	}
	
	init(_name: String, _description: String, _imagePath: String, _bannerImagePath: String?, _minting: Bool, _royalty: MetadataViews.Royalty?, _defaultPrice: UFix64, _paymentType: String, _ipfsCID: String, _lotteryBuying: Bool, _socials:{ String: MetadataViews.ExternalURL}, _mintVerifiers: [{MintVerifiers.IVerifier}]){ 
		// Collection Info
		self.collectionInfo ={} 
		self.collectionInfo["name"] = _name
		self.collectionInfo["description"] = _description
		self.collectionInfo["image"] = MetadataViews.IPFSFile(cid: _ipfsCID, path: _imagePath)
		if let bannerImagePath = _bannerImagePath{ 
			self.collectionInfo["bannerImage"] = MetadataViews.IPFSFile(cid: _ipfsCID, path: _bannerImagePath)
		}
		self.collectionInfo["ipfsCID"] = _ipfsCID
		self.collectionInfo["socials"] = _socials
		self.collectionInfo["minting"] = _minting
		self.collectionInfo["lotteryBuying"] = _lotteryBuying
		if let royalty = _royalty{ 
			assert(royalty.receiver.check(), message: "The passed in royalty receiver is not valid. The royalty account must set up the intended payment token.")
			assert(royalty.cut <= 0.95, message: "The royalty cut cannot be bigger than 95% because 5% goes to Emerald City treasury for primary sales.")
			self.collectionInfo["royalty"] = royalty
		}
		self.collectionInfo["price"] = _defaultPrice
		self.collectionInfo["paymentType"] = _paymentType
		self.collectionInfo["dateCreated"] = getCurrentBlock().timestamp
		self.collectionInfo["mintVerifiers"] = _mintVerifiers
		self.collectionInfo["profit"] = 0.0
		self.nextEditionId = 0
		self.nextMetadataId = 0
		self.totalSupply = 0
		self.metadatas ={} 
		self.primaryBuyers ={} 
		self.nftStorage <-{} 
		
		// Set the named paths
		// We include the user's address in the paths.
		// This is to prevent clashing with existing 
		// Collection paths in the ecosystem.
		self.CollectionStoragePath = /storage/TouchstoneFirstCollection_0x82b425681fb6a094
		self.CollectionPublicPath = /public/TouchstoneFirstCollection_0x82b425681fb6a094
		self.CollectionPrivatePath = /private/TouchstoneFirstCollection_0x82b425681fb6a094
		self.AdministratorStoragePath = /storage/TouchstoneFirstAdministrator_0x82b425681fb6a094
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Administrator resource and save it to storage
		let administrator <- create Administrator()
		self.account.storage.save(<-administrator, to: self.AdministratorStoragePath)
		emit ContractInitialized()
	}
}
