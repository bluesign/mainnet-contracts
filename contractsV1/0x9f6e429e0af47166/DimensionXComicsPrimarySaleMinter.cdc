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

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import DimensionXComics from "../0xe3ad6030cbaff1c2/DimensionXComics.cdc"

access(all)
contract DimensionXComicsPrimarySaleMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event MinterCreated(maxMints: Int)
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	access(all)
	let MinterPublicPath: PublicPath
	
	access(all)
	resource interface MinterCapSetter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>): Void
	}
	
	access(all)
	resource Minter: GaiaPrimarySale.IMinter, MinterCapSetter{ 
		access(contract)
		var dmxComicsMinterCap: Capability<&DimensionXComics.NFTMinter>?
		
		access(contract)
		let escrowCollection: @DimensionXComics.Collection
		
		access(all)
		let maxMints: Int
		
		access(all)
		var currentMints: Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.currentMints < self.maxMints:
					"mints exhausted: ".concat(self.currentMints.toString()).concat("/").concat(self.maxMints.toString())
			}
			let minter = (self.dmxComicsMinterCap!).borrow() ?? panic("Unable to borrow minter")
			minter.mintNFT(recipient: &self.escrowCollection as &DimensionXComics.Collection)
			let ids = self.escrowCollection.getIDs()
			assert(ids.length == 1, message: "Escrow collection count invalid")
			let nft <- self.escrowCollection.withdraw(withdrawID: ids[0])
			self.currentMints = self.currentMints + 1
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMinterCap(minterCap: Capability<&DimensionXComics.NFTMinter>){ 
			self.dmxComicsMinterCap = minterCap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasValidMinterCap(): Bool{ 
			return self.dmxComicsMinterCap != nil && (self.dmxComicsMinterCap!).check()
		}
		
		init(maxMints: Int){ 
			self.maxMints = maxMints
			self.currentMints = 0
			self.escrowCollection <- DimensionXComics.createEmptyCollection(nftType: Type<@DimensionXComics.Collection>()) as! @DimensionXComics.Collection
			self.dmxComicsMinterCap = nil
			emit MinterCreated(maxMints: self.maxMints)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinter(maxMints: Int): @Minter{ 
		return <-create Minter(maxMints: maxMints)
	}
	
	init(){ 
		self.MinterPrivatePath = /private/DimensionXComicsPrimarySaleMinterPrivatePath001
		self.MinterStoragePath = /storage/DimensionXComicsPrimarySaleMinterStoragePath001
		self.MinterPublicPath = /public/DimensionXComicsPrimarySaleMinterPublicPath001
		emit ContractInitialized()
	}
}
