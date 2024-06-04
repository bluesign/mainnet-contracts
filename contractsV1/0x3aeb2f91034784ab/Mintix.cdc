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

access(all)
contract Mintix: NonFungibleToken{ 
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let eventId: UInt64
		
		access(all)
		let supplyId: UInt64
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_eventId: UInt64, _supplyId: UInt64){ 
			self.id = Mintix.totalSupply
			Mintix.totalSupply = Mintix.totalSupply + 1
			self.eventId = _eventId
			self.supplyId = _supplyId
		}
	}
	
	access(all)
	resource interface NFTReceiver{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &Mintix.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, NFTReceiver{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Mintix.NFT
			emit Deposit(id: token.id, to: self.owner?.address)
			self.ownedNFTs[token.id] <-! token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}? ?? panic("We couldn't borrow this NFT")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowEntireNFT(id: UInt64): &NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &NFT
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
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(all)
	resource NFTMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(eventId: UInt64, supplyId: UInt64): @NFT{ 
			return <-create NFT(_eventId: eventId, _supplyId: supplyId)
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	init(){ 
		self.CollectionStoragePath = /storage/MintixCollection
		self.CollectionPublicPath = /public/MintixCollection
		self.MinterStoragePath = /storage/MintixMinter
		self.totalSupply = 0
		self.account.storage.save(<-create NFTMinter(), to: self.MinterStoragePath)
	}
}
