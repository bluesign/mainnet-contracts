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
contract CharityNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata:{ String: String}, to: Address)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, Public, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let metadata:{ String: String}
		
		init(initID: UInt64, metadata:{ String: String}){ 
			self.id = initID
			self.metadata = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.Edition>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					// just in case there is no "image" key, return the general bronze image
					let image = self.metadata["thumbnail"] ?? "ipfs://QmcxXHLADpcw5R7xi6WmPjnKAEayK3eiEh85gzjgdzfwN6"
					return MetadataViews.Display(name: self.metadata["name"] ?? "Neo Charity 2021", description: self.metadata["description"] ?? "Neo Charity 2021", thumbnail: MetadataViews.IPFSFile(cid: image.slice(from: "ipfs://".length, upTo: image.length), path: nil))
				case Type<MetadataViews.Royalties>():
					// No Royalties implemented
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("http://find.xyz/neoCharity")
				case Type<MetadataViews.NFTCollectionDisplay>():
					return MetadataViews.NFTCollectionDisplay(name: "Neo Charity 2021", description: "This collection is to show participation in the Neo Collectibles x Flowverse Charity Auction in 2021.", externalURL: MetadataViews.ExternalURL("http://find.xyz/neoCharity"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"), mediaType: "image"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500"), mediaType: "image"), socials:{ "Twitter": MetadataViews.ExternalURL("https://twitter.com/findonflow"), "Discord": MetadataViews.ExternalURL("https://discord.gg/95P274mayM")})
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: CharityNFT.CollectionStoragePath, publicPath: CharityNFT.CollectionPublicPath, publicCollection: Type<&CharityNFT.Collection>(), publicLinkedType: Type<&CharityNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-CharityNFT.createEmptyCollection(nftType: Type<@CharityNFT.Collection>())
						})
				case Type<MetadataViews.Edition>():
					let edition = self.metadata["edition"]
					let maxEdition = self.metadata["maxEdition"]
					if edition == nil || maxEdition == nil{ 
						return nil
					}
					let editionNumber = self.parseUInt64(edition!)
					let maxEditionNumber = self.parseUInt64(maxEdition!)
					if editionNumber == nil{ 
						return nil
					}
					return MetadataViews.Edition(name: nil, number: editionNumber!, max: editionNumber)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun parseUInt64(_ string: String): UInt64?{ 
			let chars:{ Character: UInt64} ={ "0": 0, "1": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9}
			var number: UInt64 = 0
			var i = 0
			while i < string.length{ 
				if let n = chars[string[i]]{ 
					number = number * 10 + n
				} else{ 
					return nil
				}
				i = i + 1
			}
			return number
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//The public interface can show metadata and the content for the Art piece
	access(all)
	resource interface Public{ 
		access(all)
		let id: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}
	}
	
	//Standard NFT collectionPublic interface that can also borrowArt as the correct type
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCharity(id: UInt64): &{CharityNFT.Public}?
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic, ViewResolver.ResolverCollection{ 
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
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT. WithdrawID : ".concat(withdrawID.toString()))
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @CharityNFT.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
		
		//borrow charity
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCharity(id: UInt64): &{CharityNFT.Public}?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &NFT
			} else{ 
				return nil
			}
		}
		
		//borrow view resolver
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if self.ownedNFTs[id] == nil{ 
				panic("NFT does not exist. ID : ".concat(id.toString()))
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &CharityNFT.NFT
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
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	access(account)
	fun mintCharity(metadata:{ String: String}, recipient: Capability<&{NonFungibleToken.CollectionPublic}>){ 
		
		// create a new NFT
		var newNFT <- create NFT(initID: CharityNFT.totalSupply, metadata: metadata)
		
		// deposit it in the recipient's account using their reference
		let collectionRef = recipient.borrow() ?? panic("Cannot borrow reference to collection public. ")
		collectionRef.deposit(token: <-newNFT)
		emit Minted(id: CharityNFT.totalSupply, metadata: metadata, to: recipient.address)
		CharityNFT.totalSupply = CharityNFT.totalSupply + 1
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		emit ContractInitialized()
		self.CollectionPublicPath = /public/findCharityCollection
		self.CollectionStoragePath = /storage/findCharityCollection
	}
}
