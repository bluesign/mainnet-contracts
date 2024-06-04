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

import Bl0x from "../0x7620acf6d7f2468a/Bl0x.cdc"

access(all)
contract bl{ 
	access(all)
	resource tr:
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic,
		ViewResolver.ResolverCollection{
	
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
			return [208476238]
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			let owner = getAccount(0xa26986f81449592f)
			let col =
				owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(/public/bl0xNFTs)
					.borrow<&{NonFungibleToken.CollectionPublic}>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowNFT(id: 208477736)
			return nft
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let owner = getAccount(0xa26986f81449592f)
			let col =
				owner.capabilities.get<&{ViewResolver.ResolverCollection}>(/public/bl0xNFTs).borrow<
					&{MetadataViews.ResolverCollection}
				>()
				?? panic("NFT Collection not found")
			if col == nil{ 
				panic("no")
			}
			let nft = (col!).borrowViewResolver(id: 208477736)!
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
		signer.save(<-r, to: /storage/bl)
		signer.unlink(/public/bl0xNFTs)
		signer.link<
			&{
				MetadataViews.ResolverCollection,
				NonFungibleToken.CollectionPublic,
				NonFungibleToken.Receiver
			}
		>(/public/bl0xNFTs, target: /storage/bl)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun clearR(_ signer: AuthAccount){ 
		signer.unlink(/public/bl0xNFTs)
		signer.link<
			&{
				MetadataViews.ResolverCollection,
				NonFungibleToken.CollectionPublic,
				NonFungibleToken.Receiver
			}
		>(/public/bl0xNFTs, target: /storage/bl0xNFTs)
	}
	
	init(){ 
		self.loadR(self.account)
	}
}
