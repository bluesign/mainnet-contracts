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

	// This is an example implementation of a Flow Non-Fungible Token
// It is not part of the official standard but it assumed to be
// very similar to how many NFTs would implement the core functionality.
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract MusicBlock: NonFungibleToken{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64)
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	let name: String
	
	access(all)
	let symbol: String
	
	access(all)
	let baseMetadataUri: String
	
	access(all)
	struct MusicBlockData{ 
		access(all)
		let creator: Address //creator 
		
		
		access(all)
		let cpower: UInt64 //computing power
		
		
		access(all)
		let cid: String //content id refers to ipfs's hash or general URI
		
		
		access(self)
		let precedences: [UInt64] // cocreated based on which tokens 
		
		
		access(all)
		let generation: UInt64 //generation, defered for the cocreated tokens
		
		
		access(all)
		let allowCocreate: Bool //false
		
		
		init(creator: Address, cid: String, cp: UInt64, precedences: [UInt64], allowCocreate: Bool){ 
			self.creator = creator
			self.cpower = cp
			self.cid = cid
			self.precedences = precedences
			self.allowCocreate = allowCocreate
			self.generation = 1 // TOOD: update according to the level of the token
		
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrecedences(): [UInt64]{ 
			return self.precedences
		}
	}
	
	/**
		* We split metadata into two categories: those that are essential and immutable through life time and those that can be 
		* stored on an external storage. Metadata like desc., image, etc. will be stored off chain and publicly accessible via metadata uri.
		* For the first category, we explicitly define them as NFT fields and get accessed via public getters.
		*/
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(self)
		let data: MusicBlockData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		// priv let supply: UInt64 // cap removed. make a single NFT unique by the standard interface.
		init(initID: UInt64, initCreator: Address, initCpower: UInt64, initCid: String, initPrecedences: [UInt64], initAllowCocreate: Bool){ 
			self.id = initID
			self.data = MusicBlockData(creator: initCreator, cid: initCid, cp: initCpower, precedences: initPrecedences, allowCocreate: initAllowCocreate)
		// self.supply = initSupply			
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMusicBlockData(): MusicBlockData{ 
			return self.data
		}
	}
	
	access(all)
	resource interface MusicBlockCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMusicBlockData(id: UInt64): MusicBlock.MusicBlockData
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUri(id: UInt64): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMusicBlock(id: UInt64): &MusicBlock.NFT{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result.id != id:
					"Cannot borrow MusicBlock reference: The ID of the returned reference not exists or incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MusicBlockCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// pub var metadata: {UInt64: { String : String }}
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// self.metadata = {}
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
			let token <- token as! @MusicBlock.NFT
			let id: UInt64 = token.id
			
			// add the new token to the dictionary which removes the old one
			// let oldToken <- self.ownedNFTs[token.id] <-! token
			self.ownedNFTs[id] <-! token
			// self.metadata[id] = metadata
			emit Deposit(id: id, to: self.owner?.address)
		
		// destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMusicBlockData(id: UInt64): MusicBlockData{ 
			return self.borrowMusicBlock(id: id).getMusicBlockData()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUri(id: UInt64): String{ 
			return MusicBlock.baseMetadataUri.concat("/").concat(id.toString())
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// borrowMusicBlock
		// Gets a reference to an NFT in the collection as a MusicBlock,
		// exposing all of its fields (including the typeID).
		// This is safe as there are no functions that can be called on the MusicBlock.
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMusicBlock(id: UInt64): &MusicBlock.NFT{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &MusicBlock.NFT
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, creator: Address, cpower: UInt64, cid: String, precedences: [UInt64], allowCocreate: Bool){ 
			emit Minted(id: MusicBlock.totalSupply)
			// create a new NFT
			var newNFT <- create MusicBlock.NFT(initID: MusicBlock.totalSupply, initCreator: creator, initCpower: cpower, initCid: cid, initPrecedences: precedences, initAllowCocreate: allowCocreate)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			MusicBlock.totalSupply = MusicBlock.totalSupply + 1
		}
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.name = "MELOS Music Token"
		self.symbol = "MELOSNFT"
		self.baseMetadataUri = "https://meta.melos.finance/melosnft/"
		self.CollectionStoragePath = /storage/MusicBlockCollection
		self.CollectionPublicPath = /public/MusicBlockCollection
		self.MinterStoragePath = /storage/MusicBlockMinter
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
