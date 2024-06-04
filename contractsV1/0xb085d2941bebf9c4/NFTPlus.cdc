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

access(TMP_ENTITLEMENT_OWNER)
contract interface NFTPlus{ 
	access(all)
	event Transfer(id: UInt64, from: Address?, to: Address)
	
	access(TMP_ENTITLEMENT_OWNER)
	fun receiver(_ address: Address): Capability<&{NonFungibleToken.Receiver}>
	
	access(TMP_ENTITLEMENT_OWNER)
	fun collectionPublic(_ address: Address): Capability<&{NonFungibleToken.CollectionPublic}>
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface Royalties{ 
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface WithRoyalties{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): [{NFTPlus.Royalties}]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Transferable{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun transfer(tokenId: UInt64, to: Capability<&{NonFungibleToken.Receiver}>)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface NFT: NonFungibleToken.NFT, WithRoyalties{ 
		access(all)
		let id: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): [{NFTPlus.Royalties}]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface CollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(id: UInt64): [{NFTPlus.Royalties}]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Collection:
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic,
		Transferable,
		CollectionPublic{
	
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(id: UInt64): [{NFTPlus.Royalties}]
	}
}
