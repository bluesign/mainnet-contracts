import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract TicketNFT: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	resource NFT: NonFungibleToken.INFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let ipfsHash: String
		
		access(all)
		var metadata:{ String: String}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(_ipfsHash: String, _metadata:{ String: String}){ 
			self.id = TicketNFT.totalSupply
			TicketNFT.totalSupply = TicketNFT.totalSupply + 1
			self.ipfsHash = _ipfsHash
			self.metadata = _metadata
		}
	}
	
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun borrowEntireNFT(id: UInt64): &TicketNFT.NFT
	}
	
	access(all)
	resource Collection: NonFungibleToken.Receiver, NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			let myToken <- token as! @TicketNFT.NFT
			emit Deposit(id: myToken.id, to: self.owner?.address)
			self.ownedNFTs[myToken.id] <-! myToken
		}
		
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("This NFT does not exist")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		fun borrowEntireNFT(id: UInt64): &TicketNFT.NFT{ 
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &TicketNFT.NFT
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
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
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(all)
	fun createToken(ipfsHash: String, metadata:{ String: String}): @TicketNFT.NFT{ 
		return <-create NFT(_ipfsHash: ipfsHash, _metadata: metadata)
	}
	
	init(){ 
		self.totalSupply = 0
	}
}
