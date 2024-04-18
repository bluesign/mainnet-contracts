import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract SeekEarlySupporters: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let maxSupply: UInt64
	
	access(all)
	let mintedAdresses: [Address?]
	
	access(all)
	var imageUri: String
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		init(id: UInt64, name: String, description: String, thumbnail: String){ 
			self.id = id
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.name, description: self.description, thumbnail: MetadataViews.HTTPFile(url: self.thumbnail))
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface SeekCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
	}
	
	access(all)
	resource Collection: SeekCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @SeekEarlySupporters.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			SeekEarlySupporters.totalSupply = SeekEarlySupporters.totalSupply + UInt64(1)
			SeekEarlySupporters.mintedAdresses.append(self.owner?.address)
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let seekEarlySupporters = nft as! &SeekEarlySupporters.NFT
			return seekEarlySupporters as &{ViewResolver.Resolver}
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
	
	access(all)
	fun mintNFT(address: Address): @NFT{ 
		let recipient = (getAccount(address).capabilities.get<&{NonFungibleToken.CollectionPublic}>(SeekEarlySupporters.CollectionPublicPath)!).borrow() ?? panic("Could not get receiver reference to the NFT Collection")
		// check if user has already minted an NFT
		if self.mintedAdresses.contains(self.account.address){ 
			panic("User has already minted an NFT")
		}
		// check if max supply has been reached
		if self.maxSupply == self.totalSupply{ 
			panic("Max supply reached")
		}
		// mint NFT
		var newNFT <- create NFT(id: SeekEarlySupporters.totalSupply + UInt64(1), name: "Seek Early Supporter", description: "Cherishing our early supporters! First 1.000 supporters can claim a NFT that will offer perks in the future.", thumbnail: self.imageUri)
		return <-newNFT
	}
	
	init(){ 
		self.totalSupply = 0
		self.maxSupply = 1000
		self.mintedAdresses = []
		self.imageUri = "https://gateway.pinata.cloud/ipfs/Qma44AYC7MrnVYM7qa8yf4Nwy5cTKyuwv2U5XUFH8VwbgX?_gl=1*1q8izqv*_ga*MTIzOTA5MjA1Ny4xNjc2MDM5MDkz*_ga_5RMPXG14TE*MTY3NjkwMjEzNC42LjEuMTY3NjkwMjI2MS42MC4wLjA"
		self.CollectionStoragePath = /storage/SeekEarlySupportersCollection
		self.CollectionPublicPath = /public/SeekEarlySupportersCollection
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&SeekEarlySupporters.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
