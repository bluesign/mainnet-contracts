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

	/*
	Help manage a primary sale for SomePlace collectibles utilizing preminted NFTs that are in storage.
	This is meant to be curated for specific drops where there are leftover NFTs to be sold publically from a private sale.
*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import SomePlaceCollectible from "./SomePlaceCollectible.cdc"

access(all)
contract SomePlacePrimarySaleHelper{ 
	access(self)
	let premintedNFTCap: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
	
	access(account)
	fun retrieveAvailableNFT(): @SomePlaceCollectible.NFT{ 
		let nftCollection = self.premintedNFTCap.borrow()!
		let randomIndex = revertibleRandom<UInt64>() % UInt64(nftCollection.getIDs().length)
		return <-(
			nftCollection.withdraw(withdrawID: nftCollection.getIDs()[randomIndex])
			as!
			@SomePlaceCollectible.NFT
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getRemainingNFTCount(): Int{ 
		return (self.premintedNFTCap.borrow()!).getIDs().length
	}
	
	init(){ 
		var capability_1 =
			self.account.capabilities.storage.issue<&SomePlaceCollectible.Collection>(
				SomePlaceCollectible.CollectionStoragePath
			)
		self.account.capabilities.publish(
			capability_1,
			at: /private/SomePlacePrimarySaleHelperAccess
		)
		self.premintedNFTCap = self.account.capabilities.get<
				&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}
			>(/private/SomePlacePrimarySaleHelperAccess)!
	}
}
