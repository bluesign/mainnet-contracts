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
contract MINTNFTINCBalmainV1NonFungibleToken: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event NFTMinted(id: UInt64, name: String, symbol: String, description: String, collectionName: String, tokenURI: String, mintNFTId: String, mintNFTStandard: String, mintNFTVideoURI: String, thirdPartyId: String, terms: String)
	
	access(all)
	event NFTDestroyed(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let symbol: String
		
		access(all)
		let description: String
		
		access(all)
		let collectionName: String
		
		access(all)
		let tokenURI: String
		
		access(all)
		let mintNFTId: String
		
		access(all)
		let mintNFTStandard: String
		
		access(all)
		let mintNFTVideoURI: String
		
		access(all)
		let thirdPartyId: String
		
		access(all)
		let terms: String
		
		access(all)
		let burnable: Bool
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(initID: UInt64, _name: String, _symbol: String, _description: String, _collectionName: String, _tokenURI: String, _mintNFTId: String, _mintNFTStandard: String, _mintNFTVideoURI: String, _thirdPartyId: String, _terms: String){ 
			self.id = initID
			self.name = _name
			self.symbol = _symbol
			self.description = _description
			self.collectionName = _collectionName
			self.tokenURI = _tokenURI
			self.mintNFTId = _mintNFTId
			self.mintNFTStandard = _mintNFTStandard
			self.mintNFTVideoURI = _mintNFTVideoURI
			self.thirdPartyId = _thirdPartyId
			self.terms = _terms
			self.burnable = false
			emit NFTMinted(id: self.id, name: self.name, symbol: self.symbol, description: self.description, collectionName: self.collectionName, tokenURI: self.tokenURI, mintNFTId: self.mintNFTId, mintNFTStandard: self.mintNFTStandard, mintNFTVideoURI: self.mintNFTVideoURI, thirdPartyId: self.thirdPartyId, terms: self.terms)
		}
	}
	
	access(all)
	resource interface MINTNFTINCBalmainV1CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMINTNFT(id: UInt64): &MINTNFTINCBalmainV1NonFungibleToken.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow NFT reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(all)
	resource Collection: MINTNFTINCBalmainV1CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic{ 
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
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @MINTNFTINCBalmainV1NonFungibleToken.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			if self.owner?.address != nil{ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
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
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMINTNFT(id: UInt64): &MINTNFTINCBalmainV1NonFungibleToken.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				return ref as! &MINTNFTINCBalmainV1NonFungibleToken.NFT
			} else{ 
				return nil
			}
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
	
	access(all)
	resource MINTNFTINCBalmainV1Minter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(recipient: &{MINTNFTINCBalmainV1CollectionPublic}, name: String, symbol: String, description: String, collectionName: String, tokenURI: String, mintNFTId: String, mintNFTStandard: String, mintNFTVideoURI: String, thirdPartyId: String, terms: String): UInt64{ 
			let newNFT <- create NFT(initID: MINTNFTINCBalmainV1NonFungibleToken.totalSupply, _name: name, _symbol: symbol, _description: description, _collectionName: collectionName, _tokenURI: tokenURI, _mintNFTId: mintNFTId, _mintNFTStandard: mintNFTStandard, _mintNFTVideoURI: mintNFTVideoURI, _thirdPartyId: thirdPartyId, _terms: terms)
			var tempId: UInt64 = newNFT.id
			recipient.deposit(token: <-newNFT)
			MINTNFTINCBalmainV1NonFungibleToken.totalSupply = MINTNFTINCBalmainV1NonFungibleToken.totalSupply + UInt64(1)
			return tempId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFTBatch(count: UInt64, recipients: [&{MINTNFTINCBalmainV1CollectionPublic}], names: [String], symbols: [String], descriptions: [String], collectionNames: [String], tokenURIs: [String], mintNFTIds: [String], mintNFTStandards: [String], mintNFTVideoURIs: [String], thirdPartyIds: [String], terms: [String]): [UInt64]{ 
			var nftIDs: [UInt64] = []
			var idx: UInt64 = 0
			var len: UInt64 = count - 1
			while idx < len{ 
				let nftId = self.mintNFT(recipient: recipients[idx], name: names[idx], symbol: symbols[idx], description: descriptions[idx], collectionName: collectionNames[idx], tokenURI: tokenURIs[idx], mintNFTId: mintNFTIds[idx], mintNFTStandard: mintNFTStandards[idx], mintNFTVideoURI: mintNFTVideoURIs[idx], thirdPartyId: thirdPartyIds[idx], terms: terms[idx])
				nftIDs.append(nftId)
				idx = idx + 1
			}
			return nftIDs
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.account.storage.save(<-create Collection(), to: /storage/MINTNFTINCBalmainV1Collection)
		var capability_1 = self.account.capabilities.storage.issue<&{MINTNFTINCBalmainV1CollectionPublic}>(/storage/MINTNFTINCBalmainV1Collection)
		self.account.capabilities.publish(capability_1, at: /public/MINTNFTINCBalmainV1Collection)
		self.account.storage.save(<-create MINTNFTINCBalmainV1Minter(), to: /storage/MINTNFTINCBalmainV1Minter)
		emit ContractInitialized()
	}
}
