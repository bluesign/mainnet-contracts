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

	// A gift is not a gift.
//
// This NFT will not emit Withdraw/Deposit events until it is recognized.
// Unless the owner recognizes it himself, external viewers will probably not be able to see it.
// Once recognized by the owner, it is no longer a gift.
//
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract Gift: NonFungibleToken{ 
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var giftThumbnail:{ MetadataViews.File}
	
	access(all)
	var notGiftThumbnail:{ MetadataViews.File}
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Mint(id: UInt64)
	
	access(all)
	event Destroy(id: UInt64)
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		var recognized: Bool
		
		init(id: UInt64){ 
			self.id = id
			self.recognized = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun recognize(){ 
			self.recognized = true
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isGift(): Bool{ 
			return !self.recognized
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: (self.isGift() ? "Gift #" : "NOT Gift #").concat(self.id.toString()), description: self.isGift() ? "This is a gift." : "This is NOT a gift.", thumbnail: self.isGift() ? Gift.giftThumbnail : Gift.notGiftThumbnail)
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource interface GiftCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowGift(id: UInt64): &Gift.NFT?{ 
			post{ 
				result == nil || result?.id == id:
					"Cannot borrow Gift reference"
			}
		}
	}
	
	access(all)
	resource Collection: GiftCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
			let tokenRef = (&token as &{NonFungibleToken.NFT})! as! &Gift.NFT
			if !tokenRef.isGift(){ 
				emit Withdraw(id: token.id, from: self.owner?.address)
			}
			return <-token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @Gift.NFT
			let id: UInt64 = token.id
			if !token.isGift(){ 
				emit Deposit(id: id, to: self.owner?.address)
			}
			self.ownedNFTs[id] <-! token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowGift(id: UInt64): &Gift.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &Gift.NFT
			}
			return nil
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)! as! &Gift.NFT
			return nft as &{ViewResolver.Resolver}
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Maintainer{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setThumbnail(giftThumbnail:{ MetadataViews.File}, notGiftThumbnail:{ MetadataViews.File}){ 
			Gift.giftThumbnail = giftThumbnail
			Gift.notGiftThumbnail = notGiftThumbnail
		}
	}
	
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun mintNFT(): @NFT{ 
		Gift.totalSupply = Gift.totalSupply + 1
		emit Mint(id: Gift.totalSupply)
		return <-create NFT(id: Gift.totalSupply)
	}
	
	init(){ 
		self.CollectionPublicPath = /public/GiftCollection
		self.CollectionStoragePath = /storage/GiftCollection
		self.totalSupply = 0
		self.giftThumbnail = MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreicmoh2ummsp4qgyp6fvk7lj7uy44jmnymhl6v75h5bbexf5i6njdm")
		self.notGiftThumbnail = MetadataViews.HTTPFile(url: "https://nftstorage.link/ipfs/bafkreiftdj3uj25a4tdnofc3ht6ir2pftwbn2dvtxsajj3rzkrsbdvkkqi")
		self.account.storage.save(<-create Maintainer(), to: /storage/GiftMaintainer)
		self.account.storage.save(<-create Collection(), to: self.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&Gift.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		emit ContractInitialized()
	}
}
