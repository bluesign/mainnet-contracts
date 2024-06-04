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

	access(all)
contract AllCodeNFTContract{ 
	access(all)
	resource NFT{ 
		access(all)
		let id: UInt64
		
		init(initID: UInt64){ 
			self.id = initID
		}
	}
	
	access(all)
	resource interface NFTReceiver{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @AllCodeNFTContract.NFT, metadata:{ String: String}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(id: UInt64):{ String: String}
	}
	
	access(all)
	resource Collection: NFTReceiver{ 
		access(all)
		var ownedNFTs: @{UInt64: NFT}
		
		access(all)
		var metadataObjs:{ UInt64:{ String: String}}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.metadataObjs ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @NFT{ 
			let token <- self.ownedNFTs.remove(key: withdrawID)!
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @NFT, metadata:{ String: String}){ 
			self.metadataObjs[token.id] = metadata
			self.ownedNFTs[token.id] <-! token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadata(id: UInt64, metadata:{ String: String}){ 
			self.metadataObjs[id] = metadata
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata(id: UInt64):{ String: String}{ 
			return self.metadataObjs[id]!
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(): @Collection{ 
		return <-create Collection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(all)
		var idCount: UInt64
		
		init(){ 
			self.idCount = 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(): @NFT{ 
			var newNFT <- create NFT(initID: self.idCount)
			self.idCount = self.idCount + 1 as UInt64
			return <-newNFT
		}
	}
	
	//The init contract is required if the contract contains any fields
	init(){ 
		self.account.storage.save(<-self.createEmptyCollection(), to: /storage/NFTCollection)
		var capability_1 =
			self.account.capabilities.storage.issue<&{NFTReceiver}>(/storage/NFTCollection)
		self.account.capabilities.publish(capability_1, at: /public/NFTReceiver)
		self.account.storage.save(<-create NFTMinter(), to: /storage/NFTMinter)
	}
}
