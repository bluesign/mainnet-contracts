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

import DimensionX from "../0xe3ad6030cbaff1c2/DimensionX.cdc"

access(all)
contract DimensionXPrimarySaleMinter{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event MinterCreated(maxMints: Int)
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let MinterPrivatePath: PrivatePath
	
	access(all)
	resource Minter: GaiaPrimarySale.IMinter{ 
		access(contract)
		let dmxMinter: @DimensionX.NFTMinter
		
		access(contract)
		var escrowCap: Capability<&DimensionX.Collection>
		
		access(all)
		let maxMints: Int
		
		access(all)
		var currentMints: Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			pre{ 
				self.currentMints <= self.maxMints:
					"mints exhausted: ".concat(self.currentMints.toString()).concat("/").concat(self.maxMints.toString())
				self.escrowCap.check():
					"invalid escrow capability"
			}
			let escrow = self.escrowCap.borrow()!
			let nftID = self.dmxMinter.getNextGenesisID() // get newly Minted NFT id
			
			self.dmxMinter.mintGenesisNFT(recipient: escrow)
			let nft <- escrow.withdraw(withdrawID: nftID)
			self.currentMints = self.currentMints + 1
			return <-nft
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateEscrowCap(_ cap: Capability<&DimensionX.Collection>){ 
			self.escrowCap = cap
		}
		
		init(minter: @DimensionX.NFTMinter, maxMints: Int, escrowCap: Capability<&DimensionX.Collection>){ 
			self.dmxMinter <- minter
			self.maxMints = maxMints
			self.currentMints = 1
			self.escrowCap = escrowCap
			emit MinterCreated(maxMints: self.maxMints)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinter(
		dmxMinter: @DimensionX.NFTMinter,
		maxMints: Int,
		escrowCap: Capability<&DimensionX.Collection>
	): @Minter{ 
		pre{ 
			escrowCap.check():
				"invalid escrow capability"
		}
		return <-create Minter(minter: <-dmxMinter, maxMints: maxMints, escrowCap: escrowCap)
	}
	
	init(){ 
		self.MinterPrivatePath = /private/DimensionXPrimarySaleMinterPrivatePath001
		self.MinterStoragePath = /storage/DimensionXPrimarySaleMinterStoragePath001
		emit ContractInitialized()
	}
}
