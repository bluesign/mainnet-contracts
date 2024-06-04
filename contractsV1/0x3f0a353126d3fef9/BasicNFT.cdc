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
contract BasicNFT{ 
	access(all)
	var totalSupply: UInt64
	
	init(){ 
		self.totalSupply = 0
	}
	
	access(all)
	resource interface NFTPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getID(): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getURL(): String
	}
	
	access(all)
	resource NFT: NFTPublic{ 
		access(all)
		let id: UInt64
		
		access(all)
		var metadata:{ String: String}
		
		init(InitURL: String){ 
			self.id = BasicNFT.totalSupply
			self.metadata ={ "URL": InitURL}
			BasicNFT.totalSupply = BasicNFT.totalSupply + 1
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getID(): UInt64{ 
			return self.id
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getURL(): String{ 
			return self.metadata["URL"]!
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createNFT(url: String): @NFT{ 
		return <-create NFT(InitURL: url)
	}
}
