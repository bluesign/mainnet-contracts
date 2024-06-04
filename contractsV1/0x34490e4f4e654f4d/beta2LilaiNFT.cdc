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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "./../../standardsV1/ViewResolver.cdc"

access(all)
contract beta2LilaiNFT: NonFungibleToken, ViewResolver{ 
	/// Total supply of beta2LilaiNFTs in existence
	access(all)
	var totalSupply: UInt64
	
	/// The event that is emitted when the contract is created
	access(all)
	event ContractInitialized()
	
	/// The event that is emitted when an NFT is withdrawn from a Collection
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	/// The event that is emitted when an NFT is deposited to a Collection
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// The event that is emitted when the Lilaiputia field of an NFT is updated
	access(all)
	event LilaiputiaUpdated(id: UInt64, updater: Address?, newLilaiputiaData: String)
	
	// Add a public path for the minter
	access(all)
	let PublicMinterPath: PublicPath
	
	/// Storage and Public Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	/// The core resource that represents a Non Fungible Token.
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		/// The unique ID that each NFT has
		access(all)
		let id: UInt64
		
		/// Metadata fields
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		access(self)
		var lilaiputia: String // Mutable field for Lilaiputia data
		
		
		init(id: UInt64, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], metadata:{ String: AnyStruct}, lilaiputia: String){ // Changed type to String 
			
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.royalties = royalties
			self.metadata = metadata
			self.lilaiputia = lilaiputia
		}
		
		/// Function to update the Lilaiputia field
		access(TMP_ENTITLEMENT_OWNER)
		fun updateLilaiputia(newLilaiputiaData: String){ 
			self.lilaiputia = newLilaiputiaData
			emit LilaiputiaUpdated(id: self.id, updater: self.owner?.address, newLilaiputiaData: newLilaiputiaData)
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		/// Function that resolves a metadata view for this token.
		///
		/// @param view: The Type of the desired view.
		/// @return A structure representing the requested view.
		///
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
				case Type<MetadataViews.Editions>():
					let editionInfo = MetadataViews.Edition(name: "Lilaiputian NFTs", number: self.id, max: nil)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("http://www.lilaiputia.com/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: beta2LilaiNFT.CollectionStoragePath, publicPath: beta2LilaiNFT.CollectionPublicPath, publicCollection: Type<&beta2LilaiNFT.Collection>(), publicLinkedType: Type<&beta2LilaiNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-beta2LilaiNFT.createEmptyCollection(nftType: Type<@beta2LilaiNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A collection of unique NFTs for the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/lilaipuita")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["mintedTime", "foo"]
					let traitsView = MetadataViews.dictToTraits(dict: self.metadata, excludedNames: excludedTraits)
					let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: self.metadata["mintedTime"]!, displayType: "Date", rarity: nil)
					traitsView.addTrait(mintedTimeTrait)
					let fooTraitRarity = MetadataViews.Rarity(score: 10.0, max: 100.0, description: "Common")
					let fooTrait = MetadataViews.Trait(name: "foo", value: self.metadata["foo"], displayType: nil, rarity: fooTraitRarity)
					traitsView.addTrait(fooTrait)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	/// Defines the methods that are particular to this NFT contract collection
	///
	access(all)
	resource interface beta2LilaiNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowbeta2LilaiNFT(id: UInt64): &beta2LilaiNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow beta2LilaiNFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	/// The resource that will be holding the NFTs inside any account.
	/// In order to be able to manage NFTs any account will need to create
	/// an empty collection first
	///
	access(all)
	resource Collection: beta2LilaiNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @beta2LilaiNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowbeta2LilaiNFT(id: UInt64): &beta2LilaiNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &beta2LilaiNFT.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let beta2LilaiNFT = nft as! &beta2LilaiNFT.NFT
			return beta2LilaiNFT as &{ViewResolver.Resolver}
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
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Interface for public access to NFTMinter
	access(all)
	resource interface NFTMinterPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], lilaiputiaData: String): Void // Note: No return type specified
	
	}
	
	access(all)
	event NFTMinted(id: UInt64)
	
	// NFTMinter resource conforming to NFTMinterPublic
	access(all)
	resource NFTMinter: NFTMinterPublic{ 
		// Implement the mintNFT function as per the new interface
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, description: String, thumbnail: String, royalties: [MetadataViews.Royalty], lilaiputiaData: String){ 
			let metadata:{ String: AnyStruct} ={} 
			let currentBlock = getCurrentBlock()
			metadata["mintedBlock"] = currentBlock.height
			metadata["mintedTime"] = currentBlock.timestamp
			metadata["minter"] = (recipient.owner!).address
			metadata["foo"] = "bar"
			// Set the Lilaiputia field with the provided data
			let lilaiputia = lilaiputiaData
			var newNFT <- create NFT(id: beta2LilaiNFT.totalSupply, name: name, description: description, thumbnail: thumbnail, royalties: royalties, metadata: metadata, lilaiputia: lilaiputia)
			recipient.deposit(token: <-newNFT)
			beta2LilaiNFT.totalSupply = beta2LilaiNFT.totalSupply + UInt64(1)
		// The NFT is deposited to the recipient's collection, so no return statement is needed
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun resolveView(_ view: Type): AnyStruct?{ 
		switch view{ 
			case Type<MetadataViews.NFTCollectionData>():
				return MetadataViews.NFTCollectionData(storagePath: beta2LilaiNFT.CollectionStoragePath, publicPath: beta2LilaiNFT.CollectionPublicPath, publicCollection: Type<&beta2LilaiNFT.Collection>(), publicLinkedType: Type<&beta2LilaiNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
						return <-beta2LilaiNFT.createEmptyCollection(nftType: Type<@beta2LilaiNFT.Collection>())
					})
			case Type<MetadataViews.NFTCollectionDisplay>():
				let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "lilaiputia.mypinata.cloud"), mediaType: "image/svg+xml")
				return MetadataViews.NFTCollectionDisplay(name: "The Lilai Collection", description: "A diverse collection of NFTs within the Lilai universe.", externalURL: MetadataViews.ExternalURL("lilaiputia.mypinata.cloud"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("hhttps://twitter.com/lilaiputia")})
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getViews(): [Type]{ 
		return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
	}
	
	init(){ 
		self.totalSupply = 0
		// Set the paths
		self.CollectionStoragePath = /storage/beta2LilaiNFTCollection
		self.CollectionPublicPath = /public/beta2LilaiNFTCollection
		self.MinterStoragePath = /storage/beta2LilaiNFTMinter
		self.PublicMinterPath = /public/beta2LilaiNFTMinter
		// Create and store the collection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		// Link the collection to the public path
		var capability_1 = self.account.capabilities.storage.issue<&beta2LilaiNFT.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		// Create and store the minter
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		// Create a public capability for the minter
		var capability_2 = self.account.capabilities.storage.issue<&beta2LilaiNFT.NFTMinter>(self.MinterStoragePath)
		self.account.capabilities.publish(capability_2, at: self.PublicMinterPath)
		emit ContractInitialized()
	}
}
