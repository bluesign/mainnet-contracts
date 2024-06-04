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

	import AlphaNFTV1 from "./AlphaNFTV1.cdc"

import AlphaPackV1 from "./AlphaPackV1.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract AlphaAdminV1{ 
	
	// Admin
	// the admin resource is defined so that only the admin account
	// can have this resource. It possesses the ability to open packs
	// given a user's Pack Collection and Card Collection reference.
	// It can also create a new pack type and mint Packs.
	//
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createTemplate(maxSupply: UInt64, immutableData:{ String: AnyStruct}){ 
			AlphaNFTV1.createTemplate(maxSupply: maxSupply, immutableData: immutableData)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(templateInfo:{ String: UInt64}, account: Address){ 
			AlphaNFTV1.mintNFT(templateInfo: templateInfo, account: account)
		}
		
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		init(){} 
	}
	
	init(){ 
		self.account.storage.save(<-create Admin(), to: /storage/AlphaAdminV1)
	}
}
