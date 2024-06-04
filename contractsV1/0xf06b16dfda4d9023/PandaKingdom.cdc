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

access(all)
contract PandaKingdom: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(self)
	var BaseURL: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String})
	
	access(all)
	event Burned(id: UInt64, address: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		init(metadata:{ String: String}, royalties: [MetadataViews.Royalty]){ 
			self.id = PandaKingdom.totalSupply
			self.metadata = metadata
			self.royalties = royalties
			emit Minted(id: self.id, metadata: self.metadata)
			PandaKingdom.totalSupply = PandaKingdom.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.metadata["name"] ?? "", description: self.metadata["description"] ?? "", thumbnail: MetadataViews.HTTPFile(url: PandaKingdom.BaseURL.concat(self.metadata["fileURI"] ?? "")))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.HTTPFile(url: PandaKingdom.BaseURL.concat(self.metadata["fileURI"] ?? ""))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: PandaKingdom.CollectionStoragePath, publicPath: PandaKingdom.CollectionPublicPath, publicCollection: Type<&PandaKingdom.Collection>(), publicLinkedType: Type<&PandaKingdom.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-PandaKingdom.createEmptyCollection(nftType: Type<@PandaKingdom.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: PandaKingdom.BaseURL.concat("logo.png")), mediaType: "image/svg")
					return MetadataViews.NFTCollectionDisplay(name: "PandaKingdom Collection", description: "Panda Kingdom begins with a collection of 333 avatars based onpanda characters. This is the key that takes you to the Panda Kingdom, where the righteous always have to find a way to fight the dark plots to protect the peace of this land. Panda Kingdom owners have access to exclusive rewards, programs, and other perks.", externalURL: MetadataViews.ExternalURL("https://twitter.com/Pandakingdom_fm"), squareImage: media, bannerImage: media, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/Pandakingdom_fm")})
				case Type<MetadataViews.Traits>():
					return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: [])
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
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPandaKingdom(id: UInt64): &PandaKingdom.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow PandaKingdom reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
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
			let token <- token as! @PandaKingdom.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// transfer takes an NFT ID and a reference to a recipient's collection
		// and transfers the NFT corresponding to that ID to the recipient
		access(TMP_ENTITLEMENT_OWNER)
		fun transfer(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not transferred"
				recipient.borrowNFT(id) != nil:
					"Recipient did not receive the intended NFT"
			}
			let nft <- self.withdraw(withdrawID: id)
			recipient.deposit(token: <-nft)
		}
		
		// burn destroys an NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun burn(id: UInt64){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not burned"
			}
			
			// This will emit a burn event
			destroy <-self.withdraw(withdrawID: id)
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
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			}
			panic("NFT not found in collection.")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowPandaKingdom(id: UInt64): &PandaKingdom.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &PandaKingdom.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] != nil{ 
				let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				if nft != nil{ 
					return nft! as! &PandaKingdom.NFT
				}
			}
			panic("NFT not found in collection.")
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Resource that an admin or something similar would own to be
	// able to mint new NFTs
	//
	access(all)
	resource NFTMinter{ 
		// transformMetadata ensures that the NFT metadata follows a particular
		// schema. At the moment, it is much more convenient to use functions
		// rather than structs to enforce a metadata schema because functions 
		// are much more flexible, easier to maintain, and safer to update.
		access(self)
		fun transformMetadata(_ metadata:{ String: String}):{ String: String}{ 
			pre{ 
				metadata.containsKey("name") && metadata.containsKey("description") && metadata.containsKey("fileURI") && metadata.containsKey("background") && metadata.containsKey("makeup") && metadata.containsKey("dominance") && metadata.containsKey("accessories"):
					"Metadata does not conform to schema"
			}
			return{ "name": metadata["name"]!, "description": metadata["description"]!, "fileURI": metadata["fileURI"]!, "background": metadata["background"]!, "makeup": metadata["makeup"]!, "dominance": metadata["dominance"]!, "accessories": metadata["accessories"]!}
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, royalties: [MetadataViews.Royalty], metadata:{ String: String}){ 
			// create a new NFT
			let newNFT <- create NFT(metadata: self.transformMetadata(metadata), royalties: royalties)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setBaseUrl(url: String){ 
			PandaKingdom.BaseURL = url
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.BaseURL = ""
		
		// Set the named paths
		self.CollectionStoragePath = /storage/pandaKingdomCollection
		self.CollectionPublicPath = /public/pandaKingdomCollection
		self.MinterStoragePath = /storage/pandaKingdomMinter
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&PandaKingdom.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
