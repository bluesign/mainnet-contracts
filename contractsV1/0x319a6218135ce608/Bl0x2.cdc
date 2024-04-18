import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Bl0x2: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextID: UInt64
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//pub var CollectionPrivatePath: PrivatePath
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64, creator: Address, metadata:{ String: String})
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	var baseURI: String
	
	access(all)
	var tokenData:{ UInt64: AnyStruct}
	
	access(all)
	var extraFields:{ String: AnyStruct}
	
	access(all)
	fun getTokenURI(id: UInt64): String{ 
		return self.baseURI.concat("/").concat(id.toString())
	}
	
	// We use dict to store raw metadata
	access(all)
	resource interface RawMetadata{ 
		access(all)
		fun getRawMetadata():{ String: String}
	}
	
	access(all)
	resource NFT: NonFungibleToken.INFT, ViewResolver.Resolver, RawMetadata{ 
		access(all)
		let id: UInt64
		
		access(all)
		let creator: Address
		
		access(self)
		let metadata:{ String: String}
		
		init(id: UInt64, creator: Address, metadata:{ String: String}){ 
			self.id = id
			self.creator = creator
			self.metadata = metadata
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return []
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			return nil
		}
		
		access(all)
		fun getRawMetadata():{ String: String}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface Bl0x2CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(all)
		fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(all)
		fun borrow_NFT_NAME_(id: UInt64): &Bl0x2.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: the ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: Bl0x2CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let token <- token as! @Bl0x2.NFT
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
		
		access(all)
		fun borrow_NFT_NAME_(id: UInt64): &Bl0x2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				// Create an authorized reference to allow downcasting
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &Bl0x2.NFT?
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let mlNFT = nft as! &Bl0x2.NFT
			return mlNFT
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
		
		// mintNFTWithID mints a new NFT with id
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFTWithID(id: UInt64, recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			if Bl0x2.nextID <= id{ 
				Bl0x2.nextID = id + 1
			}
			let creator = (self.owner!).address
			// create a new NFT
			var newNFT <- create NFT(id: id, creator: creator, metadata: metadata)
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Bl0x2.totalSupply = Bl0x2.totalSupply + 1
			emit Mint(id: tokenRef.id, creator: creator, metadata: metadata)
			return tokenRef
		}
		
		// mintNFT mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		access(all)
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata:{ String: String}): &{NonFungibleToken.NFT}{ 
			let creator = (self.owner!).address
			// create a new NFT
			var newNFT <- create NFT(id: Bl0x2.nextID, creator: creator, metadata: metadata)
			Bl0x2.nextID = Bl0x2.nextID + 1
			let tokenRef = &newNFT as &{NonFungibleToken.NFT}
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			Bl0x2.totalSupply = Bl0x2.totalSupply + 1
			emit Mint(id: tokenRef.id, creator: creator, metadata: metadata)
			return tokenRef
		}
	}
	
	access(all)
	resource Admin{ 
		access(all)
		fun setBaseURI(baseURI: String){ 
			Bl0x2.baseURI = baseURI
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.nextID = 0
		
		// Set the named paths
		self.CollectionStoragePath = /storage/MatrixMarketBl0x2Collection
		self.CollectionPublicPath = /public/MatrixMarketBl0x2Collection
		self.MinterStoragePath = /storage/MatrixMarketBl0x2Minter
		self.AdminStoragePath = /storage/MatrixMarketBl0x2Admin
		self.baseURI = "https://alpha.chainbase-api.matrixlabs.org/metadata/api/v1/apps/flow:testnet:1IEzdAr_iDJvek4-CE4-p/contracts/testnet_flow-A.7f3812b53dd4de20.Bl0x2/metadata/tokens"
		self.tokenData ={} 
		self.extraFields ={} 
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&Bl0x2.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		emit ContractInitialized()
	}
}
