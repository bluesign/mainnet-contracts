import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import StarlyMetadata from "../0x5b82f21c0edf76e3/StarlyMetadata.cdc"

import StarlyMetadataViews from "../0x5b82f21c0edf76e3/StarlyMetadataViews.cdc"

import StarlyCard from "../0x5b82f21c0edf76e3/StarlyCard.cdc"

access(all)
contract sc{ 
	access(all)
	resource tr:
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic,
		ViewResolver.ResolverCollection,
		StarlyCard.StarlyCardCollectionPublic{
	
		access(NonFungibleToken.Withdraw |NonFungibleToken.Owner)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			panic("no")
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			panic("no")
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return [25176]
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let owner = getAccount(0x19816b733ab0dd2c)
			let col =
				(
					owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
						/public/starlyCardCollection
					)!
				).borrow()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowNFT(662)
			return nft!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let owner = getAccount(0x19816b733ab0dd2c)
			let col =
				(
					owner.capabilities.get<&{ViewResolver.ResolverCollection}>(
						/public/starlyCardCollection
					)!
				).borrow()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowViewResolver(id: 662)!
			return nft
		}
		
		access(all)
		fun borrowStarlyCard(id: UInt64): &StarlyCard.NFT?{ 
			let owner = getAccount(0x19816b733ab0dd2c)
			let col =
				(
					owner.capabilities.get<&{StarlyCard.StarlyCardCollectionPublic}>(
						/public/starlyCardCollection
					)!
				).borrow()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowStarlyCard(id: 662)
			return nft
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create tr()
		}
	}
	
	access(all)
	fun loadR(_ signer: AuthAccount){ 
		let r <- create tr()
		let old <- signer.load<@StarlyCard.Collection>(from: /storage/starlyCardCollection)!
		signer.save(<-r, to: /storage/starlyCardCollection)
		signer.save(<-old, to: /storage/sc)
	}
	
	access(all)
	fun clearR(_ signer: AuthAccount){ 
		let old <- signer.load<@StarlyCard.Collection>(from: /storage/sc)!
		let r <- signer.load<@sc.tr>(from: /storage/starlyCardCollection)!
		signer.save(<-old, to: /storage/starlyCardCollection)
		destroy r
	}
	
	init(){ 
		self.loadR(self.account)
	}
}
