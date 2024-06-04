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

	// Mainnet
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NGPrimarySale from "./NGPrimarySale.cdc"

import NastyGirlz from "./NastyGirlz.cdc"

access(all)
contract NastyGirlzPrimarySaleMinter{ 
	access(all)
	resource Minter: NGPrimarySale.IMinter{ 
		access(self)
		let setMinter: @NastyGirlz.SetMinter
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mint(assetID: UInt64, creator: Address): @{NonFungibleToken.NFT}{ 
			return <-self.setMinter.mint(templateID: assetID, creator: creator)
		}
		
		init(setMinter: @NastyGirlz.SetMinter){ 
			self.setMinter <- setMinter
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinter(setMinter: @NastyGirlz.SetMinter): @Minter{ 
		return <-create Minter(setMinter: <-setMinter)
	}
}
