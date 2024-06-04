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

	// SPDX-License-Identifier: MIT
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract TrartContractNFT: NonFungibleToken{ 
	
	// -----------------------------------------------------------------------
	// Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Burn(id: UInt64)
	
	// -----------------------------------------------------------------------
	// fields.
	// -----------------------------------------------------------------------
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(self)
	let metadatas:{ UInt64: Metadata}
	
	// -----------------------------------------------------------------------
	// Metadata
	// -----------------------------------------------------------------------
	// Metadatas are content data of NFTs, those are public data. Anyone can query this to find the detail. 
	// Initialize the metadata value directly during init phase in the NFT resource section. There is no remove function since as a proof of existence.
	access(all)
	struct Metadata{ 
		access(all)
		let cardID: UInt64
		
		access(all)
		let data:{ String: String}
		
		init(cardID: UInt64, data:{ String: String}){ 
			self.cardID = cardID
			self.data = data
		}
	}
	
	// Get all metadatas
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadatas():{ UInt64: Metadata}{ 
		return self.metadatas
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadatasCount(): UInt64{ 
		return UInt64(self.metadatas.length)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMetadataForCardID(cardID: UInt64): Metadata?{ 
		return self.metadatas[cardID]
	}
	
	// -----------------------------------------------------------------------
	// NFT
	// -----------------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		init(initID: UInt64, metadata:{ String: String}){ 
			TrartContractNFT.totalSupply = TrartContractNFT.totalSupply + 1 as UInt64
			TrartContractNFT.metadatas[initID] = Metadata(cardID: initID, data: metadata)
			self.id = initID
			emit Mint(id: self.id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCardMetadata(): Metadata?{ 
			return TrartContractNFT.getMetadataForCardID(cardID: self.id)
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Traits>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return self.getDisplay()
				case Type<MetadataViews.Royalties>():
					return self.getRoyalties()
				case Type<MetadataViews.Traits>():
					return self.getTraits()
				case Type<MetadataViews.ExternalURL>():
					return self.getExternalURL()
				case Type<MetadataViews.NFTCollectionDisplay>():
					return self.getNFTCollectionDisplay()
				case Type<MetadataViews.NFTCollectionData>():
					return self.getNFTCollectionData()
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplay(): MetadataViews.Display?{ 
			if let info = self.getCardMetadata(){ 
				let metadata = info.data
				var nftTitle: String = metadata["NAME"] ?? ""
				var nftDesc: String = metadata["CARD NUMBER"] ?? ""
				if metadata["CARD SERIES"] != nil && metadata["CARD NUMBER"] != nil{ 
					nftDesc = metadata["CARD SERIES"] ?? "".concat(" - ").concat(metadata["CARD NUMBER"] ?? "")
				}
				let ipfsScheme = "ipfs://"
				let httpsScheme = "https://"
				var mediaURL: String = metadata["URI"] ?? metadata["URL"] ?? ""
				if mediaURL.length > ipfsScheme.length && self.stringStartsWith(string: mediaURL, prefix: ipfsScheme){ 
					mediaURL = "https://trartgateway.mypinata.cloud/ipfs/".concat(mediaURL.slice(from: ipfsScheme.length, upTo: mediaURL.length))
				} else if mediaURL.length > httpsScheme.length && self.stringStartsWith(string: mediaURL, prefix: httpsScheme){ 
					mediaURL = mediaURL
				}
				return MetadataViews.Display(name: nftTitle, description: nftDesc, thumbnail: MetadataViews.HTTPFile(url: mediaURL))
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): MetadataViews.Royalties?{ 
			let royalties: [MetadataViews.Royalty] = [MetadataViews.Royalty(receiver: getAccount(0x416e01b78d5b45ff).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, cut: 0.025, description: "Royalty (2.5%)")]
			return MetadataViews.Royalties(royalties)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTraits(): MetadataViews.Traits?{ 
			if let info = self.getCardMetadata(){ 
				let metadata = info.data
				let traits = MetadataViews.Traits([])
				for key in metadata.keys{ 
					traits.addTrait(MetadataViews.Trait(name: key, value: metadata[key] ?? "", displayType: "String", rarity: nil))
				}
				return traits
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExternalURL(): MetadataViews.ExternalURL?{ 
			if let info = self.getCardMetadata(){ 
				let metadata = info.data
				let ipfsScheme = "ipfs://"
				let httpsScheme = "https://"
				var mediaURL: String = metadata["URI"] ?? metadata["URL"] ?? ""
				if mediaURL.length > ipfsScheme.length && self.stringStartsWith(string: mediaURL, prefix: ipfsScheme){ 
					mediaURL = "https://trartgateway.mypinata.cloud/ipfs/".concat(mediaURL.slice(from: ipfsScheme.length, upTo: mediaURL.length))
				} else if mediaURL.length > httpsScheme.length && self.stringStartsWith(string: mediaURL, prefix: httpsScheme){ 
					mediaURL = mediaURL
				}
				return MetadataViews.ExternalURL(mediaURL)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTCollectionDisplay(): MetadataViews.NFTCollectionDisplay{ 
			return MetadataViews.NFTCollectionDisplay(name: "Trart", description: "TRART is an international platform with NFTs (non-fungible tokens) from well-known artists around the world.", externalURL: MetadataViews.ExternalURL("https://trart.io"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trart.io/images/TRART_Logo.svg"), mediaType: "image/svg+xml"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://trart.io/images/TRART_Banner_1200x630px.png"), mediaType: "image/png"), socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/IoTrart"), "discord": MetadataViews.ExternalURL("https://discord.com/invite/yEyse2VkQB")})
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTCollectionData(): MetadataViews.NFTCollectionData{ 
			return MetadataViews.NFTCollectionData(storagePath: TrartContractNFT.CollectionStoragePath, publicPath: TrartContractNFT.CollectionPublicPath, publicCollection: Type<&TrartContractNFT.Collection>(), publicLinkedType: Type<&TrartContractNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
					return <-TrartContractNFT.createEmptyCollection(nftType: Type<@TrartContractNFT.Collection>())
				})
		}
		
		access(self)
		fun stringStartsWith(string: String, prefix: String): Bool{ 
			let beginning = string.slice(from: 0, upTo: prefix.length)
			let prefixArray = prefix.utf8
			let beginningArray = beginning.utf8
			for index, element in prefixArray{ 
				if beginningArray[index] != prefixArray[index]{ 
					return false
				}
			}
			return true
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// createNFT
	access(account)
	fun createNFT(cardID: UInt64, metadata:{ String: String}): @NFT{ 
		return <-create NFT(initID: cardID, metadata: metadata)
	}
	
	// -----------------------------------------------------------------------
	// Collection
	// -----------------------------------------------------------------------
	access(all)
	resource interface ICardCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCard(id: UInt64): &TrartContractNFT.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: The ID reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: ICardCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Cannot withdraw: NFT does not exist in the collection")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @TrartContractNFT.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
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
		fun borrowCard(id: UInt64): &TrartContractNFT.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &TrartContractNFT.NFT
			} else{ 
				return nil
			}
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let card = nft as! &TrartContractNFT.NFT
			return card as &{ViewResolver.Resolver}
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
	
	// -----------------------------------------------------------------------
	// minter
	// -----------------------------------------------------------------------
	access(all)
	resource NFTMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun newNFT(cardID: UInt64, data:{ String: String}): @NFT{ 
			return <-TrartContractNFT.createNFT(cardID: cardID, metadata: data)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, cardID: UInt64, data:{ String: String}){ 
			recipient.deposit(token: <-TrartContractNFT.createNFT(cardID: cardID, metadata: data))
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/TrartContractNFTCollection
		self.CollectionPublicPath = /public/TrartContractNFTCollection
		self.MinterStoragePath = /storage/TrartContractNFTMinter
		
		// Initialize the member variants
		self.totalSupply = 0
		self.metadatas ={} 
		
		//collection
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&TrartContractNFT.Collection>(TrartContractNFT.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: TrartContractNFT.CollectionPublicPath)
		
		// minter
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
