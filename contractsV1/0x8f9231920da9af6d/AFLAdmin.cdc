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

	import AFLNFT from "./AFLNFT.cdc"

import AFLPack from "./AFLPack.cdc"

import AFLBurnExchange from "./AFLBurnExchange.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import PackRestrictions from "./PackRestrictions.cdc"

access(all)
contract AFLAdmin{ 
	
	// Admin
	// the admin resource is defined so that only the admin account
	// can have this resource. It possesses the ability to open packs
	// given a user's Pack Collection and Card Collection reference.
	// It can also create a new pack type and mint Packs.
	//
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun createTemplate(maxSupply: UInt64, immutableData:{ String: AnyStruct}): UInt64{ 
			return AFLNFT.createTemplate(maxSupply: maxSupply, immutableData: immutableData)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateImmutableData(templateID: UInt64, immutableData:{ String: AnyStruct}){ 
			let templateRef = &AFLNFT.allTemplates[templateID] as &AFLNFT.Template?
			templateRef?.updateImmutableData(immutableData) ?? panic("Template does not exist")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addRestrictedPack(id: UInt64){ 
			PackRestrictions.addPackId(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeRestrictedPack(id: UInt64){ 
			PackRestrictions.removePackId(id: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(templateInfo:{ String: UInt64}, account: Address){ 
			AFLNFT.mintNFT(templateInfo: templateInfo, account: account)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(templateInfo:{ String: UInt64}): @{NonFungibleToken.NFT}{ 
			return <-AFLNFT.mintAndReturnNFT(templateInfo: templateInfo)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addTokenForExchange(nftId: UInt64, token: @{NonFungibleToken.NFT}){ 
			AFLBurnExchange.addTokenForExchange(nftId: nftId, token: <-token)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawTokenFromBurnExchange(nftId: UInt64): @{NonFungibleToken.NFT}{ 
			return <-AFLBurnExchange.withdrawToken(nftId: nftId)
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
		self.account.storage.save(<-create Admin(), to: /storage/AFLAdmin)
	}
}
