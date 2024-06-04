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
contract Circle{ 
	//Circle is the contract; circleNFT is the NFT
	access(all)
	var totalSupply: UInt64
	
	access(all)
	resource circleNFT{ 
		access(all)
		let badge_id: UInt64
		
		access(all)
		let circle: String
		
		init(){ //Initialize the the badge id  
			
			self.badge_id = Circle.totalSupply
			Circle.totalSupply = Circle.totalSupply + 1 as UInt64
			self.circle = "Producer"
		}
	}
	
	access(all)
	resource interface iCollectionPublic{ 
		//get a list of the ids
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @circleNFT)
	}
	
	access(all)
	resource circleCollection: iCollectionPublic{ 
		//Instead of storing and acccessing storage path we will access NFT 
		//from a collection. Only one thing can be stored in storage
		access(all)
		var ownedNFTs: @{UInt64: circleNFT}
		
		//map a id to an NFT (the badge)
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @circleNFT){ 
			/*The force-assignment operator (<-!) assigns a resource-typed 
						value to an optional-typed variable if the variable is nil.  */
			
			self.ownedNFTs[token.badge_id] <-! token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(id: UInt64): @circleNFT{ 
			let token <- self.ownedNFTs.remove(key: id) ?? panic("This collection does not contain NFT with that id")
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createCircleCollection(): @circleCollection{ 
		return <-create circleCollection()
	}
	
	access(all)
	resource NFTMinter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createCircleNFT(): @circleNFT{ 
			return <-create circleNFT()
		}
		
		init(){} 
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createCircleNFT(): @circleNFT{ 
		return <-create circleNFT()
	}
	
	init(){ 
		self.totalSupply = 0
		self.account.storage.save(<-create NFTMinter(), to: /storage/adminMinter)
	}
}
