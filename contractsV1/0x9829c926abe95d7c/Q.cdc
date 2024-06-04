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

	import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

import FlowSwapPair from "../0xc6c77b9f5c7a378f/FlowSwapPair.cdc"

import IPierPair from "../0x609e10301860b683/IPierPair.cdc"

import PierPair from "../0x609e10301860b683/PierPair.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Q{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun q(): [AnyStruct]{ 
		let pairInfoI_FLOWUSDC =
			(
				getAccount(0xfa82796435e15832).capabilities.get<&{SwapInterfaces.PairPublic}>(
					/public/increment_swap_pair
				).borrow()!
			).getPairInfo()
		let poolInfoM_FLOWUSDC =
			(
				getAccount(0x18187a9d276c0329).capabilities.get<&PierPair.Pool>(
					/public/metapierSwapPoolPublic
				).borrow()!
			).getReserves()
		let flowBalance =
			(
				getAccount(0x24263c125b7770e0).capabilities.get<&{FungibleToken.Balance}>(
					/public/flowTokenBalance
				).borrow()!
			).balance
		let usdcBalance =
			(
				getAccount(0x24263c125b7770e0).capabilities.get<&{FungibleToken.Balance}>(
					/public/USDCVaultBalance
				).borrow()!
			).balance
		let usdtBalance =
			(
				getAccount(0x24263c125b7770e0).capabilities.get<&{FungibleToken.Balance}>(
					/public/teleportedTetherTokenBalance
				).borrow()!
			).balance
		return [
			pairInfoI_FLOWUSDC[2],
			pairInfoI_FLOWUSDC[3],
			FlowSwapPair.getPoolAmounts().token1Amount,
			FlowSwapPair.getPoolAmounts().token2Amount,
			poolInfoM_FLOWUSDC[0],
			poolInfoM_FLOWUSDC[1],
			flowBalance,
			usdcBalance,
			usdtBalance
		]
	}
	
	init(){} 
}
