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
contract TestNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// Named Paths
	//
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64){ 
			self.id = initID
			self.metadata ={} 
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
			let token <- token as! @TestNFT.NFT
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
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
		fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}){ 
			
			// create a new NFT
			var newNFT <- create NFT(initID: TestNFT.totalSupply)
			
			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-newNFT)
			TestNFT.totalSupply = TestNFT.totalSupply + UInt64(1)
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/testNFTCollection
		self.CollectionPublicPath = /public/testNFTCollection
		self.MinterStoragePath = /storage/testNFTMinter
		
		// Initialize the total supply
		self.totalSupply = 0
		
		// Create a Collection resource and save it to storage
		let collection <- create Collection()
		self.account.storage.save(<-collection, to: self.CollectionStoragePath)
		
		// create a public capability for the collection
		var capability_1 = self.account.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a Minter resource and save it to storage
		let minter <- create NFTMinter()
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
