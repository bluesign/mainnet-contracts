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
contract DarkCountryStaking{ 
	
	// Staked Items.
	// Indicates list of NFTs staked by a user.
	access(account)
	var stakedItems:{ Address: [UInt64]}
	
	// Emitted when NFTs are staked
	access(all)
	event ItemsStaked(from: Address, ids: [UInt64])
	
	// Emitted when NFTs are requested for staking
	access(all)
	event ItemsRequestedForStaking(from: Address, ids: [UInt64])
	
	access(all)
	event ItemsRequestedForUnstaking(from: Address, ids: [UInt64])
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStakedNFTsForAddress(userAddress: Address): [UInt64]?{ 
		return self.stakedItems[userAddress]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun requestSetStakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
		emit ItemsRequestedForStaking(from: userAddress, ids: stakedNFTs)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun requestSetUnstakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
		emit ItemsRequestedForUnstaking(from: userAddress, ids: stakedNFTs)
	}
	
	// Admin is a special authorization resource that
	// allows the owner to perform functions to modify the following:
	//  1. Staked items
	access(all)
	resource Admin{ 
		// sets staked NFTs for a user by theirs addresss
		//
		// Parameters: userAddress: The address of the user's account
		// newStakedItems: new list of items
		// 
		// To be used to unstaked the NFTs for user 
		// only Admin/Minter can do that
		access(TMP_ENTITLEMENT_OWNER)
		fun setStakedNFTsForAddress(userAddress: Address, stakedNFTs: [UInt64]){ 
			DarkCountryStaking.stakedItems[userAddress] = stakedNFTs
			emit ItemsStaked(from: userAddress, ids: stakedNFTs)
		}
		
		// createNewAdmin creates a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/DarkCountryStakingAdmin
		self.stakedItems ={} 
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
	}
}
