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

	import Minter from "./Minter.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowUtilityToken from "../0xead892083b3e2c6c/FlowUtilityToken.cdc"

access(all)
contract FlowUtilityTokenMinter{ 
	access(all)
	resource FungibleTokenMinter: Minter.FungibleTokenMinter{ 
		access(all)
		let type: Type
		
		access(all)
		let addr: Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintTokens(acct: AuthAccount, amount: UFix64): @{FungibleToken.Vault}{ 
			let mainVault = acct.borrow<&FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault) ?? panic("vault not found")
			let tokens <- mainVault.withdraw(amount: amount)
			return <-tokens
		}
		
		init(_ t: Type, _ a: Address){ 
			self.type = t
			self.addr = a
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createMinter(_ t: Type, _ a: Address): @FungibleTokenMinter{ 
		return <-create FungibleTokenMinter(t, a)
	}
}
