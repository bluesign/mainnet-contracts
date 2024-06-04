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

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Foo: NonFungibleToken{ 
	access(all)
	let version: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	event Burned(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	/// The total number of Foo NFTs that have been minted.
	///
	access(all)
	var totalSupply: UInt64
	
	access(all)
	struct Metadata{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let foo: String
		
		access(all)
		let bar: Int
		
		init(name: String, description: String, thumbnail: String, foo: String, bar: Int){ 
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.foo = foo
			self.bar = bar
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		init(metadata: Metadata){ 
			self.id = self.uuid
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.NFTView>(), Type<MetadataViews.Display>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Royalties>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.NFTView>():
					return self.resolveNFTView(self.metadata)
				case Type<MetadataViews.Display>():
					return self.resolveDisplay(self.metadata)
				case Type<MetadataViews.ExternalURL>():
					return self.resolveExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.resolveNFTCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return self.resolveNFTCollectionData()
				case Type<MetadataViews.Royalties>():
					return self.resolveRoyalties()
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveNFTView(_ metadata: Metadata): MetadataViews.NFTView{ 
			return MetadataViews.NFTView(id: self.id, uuid: self.uuid, display: self.resolveDisplay(metadata), externalURL: self.resolveExternalURL(), collectionData: self.resolveNFTCollectionData(), collectionDisplay: self.resolveNFTCollectionDisplay(), royalties: self.resolveRoyalties(), traits: nil)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveDisplay(_ metadata: Metadata): MetadataViews.Display{ 
			return MetadataViews.Display(name: metadata.name, description: metadata.description, thumbnail: MetadataViews.IPFSFile(cid: metadata.thumbnail, path: nil))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveExternalURL(): MetadataViews.ExternalURL{ 
			return MetadataViews.ExternalURL("http://foo.com/".concat(self.id.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			let media = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafkreicrfbblmaduqg2kmeqbymdifawex7rxqq2743mitmeia4zdybmmre", path: nil), mediaType: "image/jpeg")
			return MetadataViews.NFTCollectionDisplay(name: "My Collection", description: "This is my collection.", externalURL: MetadataViews.ExternalURL("http://foo.com"), squareImage: media, bannerImage: media, socials:{} )
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: Foo.CollectionStoragePath, publicPath: Foo.CollectionPublicPath, publicCollection: Type<&Foo.Collection>(), publicLinkedType: Type<&Foo.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-Foo.createEmptyCollection(nftType: Type<@Foo.Collection>())
				})
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveRoyalties(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties([])
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface FooCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFoo(id: UInt64): &Foo.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Foo reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: FooCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		/// A dictionary of all NFTs in this collection indexed by ID.
		///
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		/// Remove an NFT from the collection and move it to the caller.
		///
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Requested NFT to withdraw does not exist in this collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		/// Deposit an NFT into this collection.
		///
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Foo.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		/// Return an array of the NFT IDs in this collection.
		///
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		/// Return a reference to an NFT in this collection.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as Foo.NFT.
		///
		/// This function returns nil if the NFT does not exist in this collection.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowFoo(id: UInt64): &Foo.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &Foo.NFT
			}
			return nil
		}
		
		/// Return a reference to an NFT in this collection
		/// typed as MetadataViews.Resolver.
		///
		/// This function panics if the NFT does not exist in this collection.
		///
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftRef = nft as! &Foo.NFT
			return nftRef as &{ViewResolver.Resolver}
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
	
	/// Return a new empty collection.
	///
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	/// The administrator resource used to mint and reveal NFTs.
	///
	access(all)
	resource Admin{ 
		
		/// Mint a new NFT.
		///
		/// To mint an NFT, specify a value for each of its metadata fields.
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(name: String, description: String, thumbnail: String, foo: String, bar: Int): @Foo.NFT{ 
			let metadata = Metadata(name: name, description: description, thumbnail: thumbnail, foo: foo, bar: bar)
			let nft <- create Foo.NFT(metadata: metadata)
			emit Minted(id: nft.id)
			Foo.totalSupply = Foo.totalSupply + 1 as UInt64
			return <-nft
		}
	}
	
	/// Return a public path that is scoped to this contract.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun getPublicPath(suffix: String): PublicPath{ 
		return PublicPath(identifier: "Foo_".concat(suffix))!
	}
	
	/// Return a private path that is scoped to this contract.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun getPrivatePath(suffix: String): PrivatePath{ 
		return PrivatePath(identifier: "Foo_".concat(suffix))!
	}
	
	/// Return a storage path that is scoped to this contract.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun getStoragePath(suffix: String): StoragePath{ 
		return StoragePath(identifier: "Foo_".concat(suffix))!
	}
	
	access(self)
	fun initAdmin(admin: AuthAccount){ 
		// Create an empty collection and save it to storage
		let collection <- Foo.createEmptyCollection(nftType: Type<@Foo.Collection>())
		admin.save(<-collection, to: Foo.CollectionStoragePath)
		admin.link<&Foo.Collection>(Foo.CollectionPrivatePath, target: Foo.CollectionStoragePath)
		admin.link<&Foo.Collection>(Foo.CollectionPublicPath, target: Foo.CollectionStoragePath)
		
		// Create an admin resource and save it to storage
		let adminResource <- create Admin()
		admin.save(<-adminResource, to: self.AdminStoragePath)
	}
	
	init(){ 
		self.version = "0.0.24"
		self.CollectionPublicPath = Foo.getPublicPath(suffix: "Collection")
		self.CollectionStoragePath = Foo.getStoragePath(suffix: "Collection")
		self.CollectionPrivatePath = Foo.getPrivatePath(suffix: "Collection")
		self.AdminStoragePath = Foo.getStoragePath(suffix: "Admin")
		self.totalSupply = 0
		self.initAdmin(admin: self.account)
		emit ContractInitialized()
	}
}
