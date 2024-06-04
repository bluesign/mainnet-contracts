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

	/// Support FT minter/burner, minimal interfaces
/// do we want mintToAccount?
import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface FTMinterBurner{ 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IMinter{ 
		// only define func for PegBridge to call, allowedAmount isn't strictly required
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(amount: UFix64): @{FungibleToken.Vault}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IBurner{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun burnTokens(from: @{FungibleToken.Vault})
	}
	
	/// token contract must also define same name resource and impl mintTokens/burnTokens
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Minter: IMinter{} 
	
	// we could add pre/post to mintTokens fun here
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Burner: IBurner{} 
// we could add pre/post to burnTokens fun here
}
