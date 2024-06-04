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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import StringUtils from "./../../standardsV1/StringUtils.cdc"

access(all)
contract Utils{ 
	
	/// getCollectionPaths
	/// This function searches the specified account and returns a dictionary of NFTCollectionData structs by
	/// collectionIdentifier. If a collectionIdentifier is not found in the specified ownerAddress, or that collection
	/// does not provide a resolver for NFTCollectionData, the response value will be "nil".
	access(all)
	fun getNFTCollectionData(ownerAddress: Address, nftIdentifiers: [String]):{ 
		String: MetadataViews.NFTCollectionData
	}{ 
		let response:{ String: MetadataViews.NFTCollectionData} ={} 
		let account = getAccount(ownerAddress)
		account.forEachPublic(fun (path: PublicPath, type: Type): Bool{ 
				let collectionPublic = account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(path).borrow()
				if collectionPublic == nil{ 
					return true
				}
				let contractParts = StringUtils.split((collectionPublic!).getType().identifier, ".")
				let contractIdentifier = StringUtils.join(contractParts.slice(from: 0, upTo: contractParts.length - 1), ".")
				let nftIdentifier = contractIdentifier.concat(".NFT")
				if !nftIdentifiers.contains(nftIdentifier) || response.containsKey(nftIdentifier){ 
					return true
				}
				let nftRef: &{NonFungibleToken.INFT} = (collectionPublic!).borrowNFT(id: (collectionPublic!).getIDs()[0]) as &{NonFungibleToken.INFT}
				let collectionData = nftRef.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData? ?? panic("collection lookup failed")
				response.insert(key: nftIdentifier, collectionData)
				return true
			})
		return response
	}
}
