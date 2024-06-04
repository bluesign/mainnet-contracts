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

import MatrixWorldVoucher from "../0x0d77ec47bbad8ef6/MatrixWorldVoucher.cdc"

access(all)
contract tt{ 
	access(all)
	resource tr: MatrixWorldVoucher.MatrixWorldVoucherCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getIDs(): [UInt64]{ 
			return [UInt64(1479)]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT}){ 
			destroy token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFT(id: UInt64): &{NonFungibleToken.NFT}{ 
			panic("no")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowVoucher(id: UInt64): &MatrixWorldVoucher.NFT?{ 
			panic("no nft")
		}
	}
	
	init(){} 
}
