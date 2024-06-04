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

import FlowversePass from "./FlowversePass.cdc"

import FlowversePrimarySale from "./FlowversePrimarySale.cdc"

access(all)
contract FlowversePassPrimarySaleMinter{ 
	access(all)
	resource Minter: FlowversePrimarySale.IMinter{ 
		access(self)
		let setMinter: @FlowversePass.SetMinter
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(entityID: UInt64, minterAddress: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(entityID: entityID, minterAddress: minterAddress)
		}
		
		init(setMinter: @FlowversePass.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinter(setMinter: @FlowversePass.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPrivatePath(setID: UInt64): PrivatePath{ 
		let pathIdentifier = "FlowversePassPrimarySaleMinter"
		return PrivatePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getStoragePath(setID: UInt64): StoragePath{ 
		let pathIdentifier = "FlowversePassPrimarySaleMinter"
		return StoragePath(identifier: pathIdentifier.concat(setID.toString()))!
	}
}
