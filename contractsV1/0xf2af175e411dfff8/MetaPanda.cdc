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

	/**
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import AnchainUtils from "../0x7ba45bdcac17806a/AnchainUtils.cdc"

// MetaPanda
// NFT items for MetaPanda!
//
access(all)
contract MetaPanda: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, metadata: Metadata)
	
	access(all)
	event Burned(id: UInt64, address: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	struct Metadata{ 
		access(all)
		let clothesAccessories: String?
		
		access(all)
		let facialAccessories: String?
		
		access(all)
		let facialExpression: String?
		
		access(all)
		let headAccessories: String?
		
		access(all)
		let handAccessories: String?
		
		access(all)
		let clothesBody: String?
		
		access(all)
		let background: String?
		
		access(all)
		let foreground: String?
		
		access(all)
		let basePanda: String?
		
		init(clothesAccessories: String?, facialAccessories: String?, facialExpression: String?, headAccessories: String?, handAccessories: String?, clothesBody: String?, background: String?, foreground: String?, basePanda: String?){ 
			self.clothesAccessories = clothesAccessories
			self.facialAccessories = facialAccessories
			self.facialExpression = facialExpression
			self.headAccessories = headAccessories
			self.handAccessories = handAccessories
			self.clothesBody = clothesBody
			self.background = background
			self.foreground = foreground
			self.basePanda = basePanda
		}
	}
	
	access(all)
	struct MetaPandaView{ 
		access(all)
		let uuid: UInt64
		
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let file: AnchainUtils.File
		
		init(uuid: UInt64, id: UInt64, metadata: Metadata, file: AnchainUtils.File){ 
			self.uuid = uuid
			self.id = id
			self.metadata = metadata
			self.file = file
		}
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let metadata: Metadata
		
		access(all)
		let file: AnchainUtils.File
		
		init(metadata: Metadata, file: AnchainUtils.File){ 
			self.id = MetaPanda.totalSupply
			self.metadata = metadata
			self.file = file
			emit Minted(id: MetaPanda.totalSupply, metadata: metadata)
			MetaPanda.totalSupply = MetaPanda.totalSupply + 1
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetaPandaView>(), Type<AnchainUtils.File>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					let file = self.file.thumbnail as! MetadataViews.IPFSFile
					return MetadataViews.Display(name: "Meta Panda Club NFT", description: "Meta Panda Club NFT #".concat(self.id.toString()), thumbnail: MetadataViews.HTTPFile(url: "https://ipfs.tenzingai.com/ipfs/".concat(file.cid)))
				case Type<MetaPandaView>():
					return MetaPandaView(uuid: self.uuid, id: self.id, metadata: self.metadata, file: self.file)
				case Type<AnchainUtils.File>():
					return self.file
				case Type<MetadataViews.Editions>():
					// There is no max number of NFTs that can be minted from this contract
					// so the max edition field value is set to nil
					return MetadataViews.Editions([MetadataViews.Edition(name: "Meta Panda NFT Edition", number: self.id, max: nil)])
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties([])
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://s3.us-west-2.amazonaws.com/nft.pandas/".concat(self.id.toString()).concat(".png"))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MetaPanda.CollectionStoragePath, publicPath: MetaPanda.CollectionPublicPath, publicCollection: Type<&MetaPanda.Collection>(), publicLinkedType: Type<&MetaPanda.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MetaPanda.createEmptyCollection(nftType: Type<@MetaPanda.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://s3.us-west-2.amazonaws.com/nft.pandas/logo.png"), mediaType: "image/png")
					return MetadataViews.NFTCollectionDisplay(name: "The Meta Panda NFT Collection", description: "", externalURL: MetadataViews.ExternalURL("https://metapandaclub.com/"), squareImage: media, bannerImage: media, socials:{} )
				case Type<MetadataViews.Traits>():
					return MetadataViews.Traits([MetadataViews.Trait(name: "Clothes Accessories", value: self.metadata.clothesAccessories, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Facial Accessories", value: self.metadata.facialAccessories, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Facial Expression", value: self.metadata.facialExpression, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Head Accessories", value: self.metadata.headAccessories, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Hand Accessories", value: self.metadata.handAccessories, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Clothes Body", value: self.metadata.clothesBody, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Background", value: self.metadata.background, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Foreground", value: self.metadata.foreground, displayType: "String", rarity: nil), MetadataViews.Trait(name: "Base Panda", value: self.metadata.basePanda, displayType: "String", rarity: nil)])
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// Collection
	// A collection of MetaPanda NFTs owned by an account
	//
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, AnchainUtils.ResolverCollection{ 
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
			let token <- token as! @MetaPanda.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
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
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft
			}
			panic("NFT not found in collection.")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowViewResolverSafe(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &MetaPanda.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			if let nft = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?{ 
				return nft as! &MetaPanda.NFT
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
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: Metadata, file: AnchainUtils.File){ 
			// create a new NFT
			let newNFT <- create MetaPanda.NFT(metadata: metadata, file: file)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MetaPandaCollection
		self.CollectionPublicPath = /public/MetaPandaCollection
		self.MinterStoragePath = /storage/MetaPandaMinter
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
