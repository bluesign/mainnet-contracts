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

	import PierSwapFactory from "../0xe31c5fc93a43c6bb/PierSwapFactory.cdc"

import PierSwapSettings from "../0x5d30644e4445aebb/PierSwapSettings.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import IPierPair from "../0xe31c5fc93a43c6bb/IPierPair.cdc"

import PierPair from "../0xe31c5fc93a43c6bb/PierPair.cdc"

import PierMath from "../0x3620aa78dc6c5b54/PierMath.cdc"

/**

PierRouterLib provides utility functions for PierRouter,

@author Metapier Foundation Ltd.

 */

access(all)
contract PierRouterLib{ 
	
	// Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
	access(TMP_ENTITLEMENT_OWNER)
	fun quote(amountA: UFix64, reserveA: UFix64, reserveB: UFix64): UFix64{ 
		pre{ 
			amountA > 0.0:
				"Metapier PierRouterLib: amountA cannot be 0"
			reserveA > 0.0 && reserveB > 0.0:
				"Metapier PierRouterLib: Insufficient liquidity"
		}
		
		// amountB = amountA * reserveB / reserveA
		let amountB =
			PierMath.UFix64ToRawUInt256(amountA) * PierMath.UFix64ToRawUInt256(reserveB)
			/ PierMath.UFix64ToRawUInt256(reserveA)
		return PierMath.rawUInt256ToUFix64(amountB)
	}
	
	// Performs a sequence of swaps following the given pools and amounts.
	//
	// @param inputVault The vault that stores the input tokens for the initial swap.
	// @param pools An array of liquidity pools in the order of the swap path. 
	//  E.g., [<A.0x01.TokenA, A.0x02.TokenB>, <A.0x02.TokenB, A.0x03.TokenC>]
	// @param amounts The expected amount of tokens in each step of the swap path.
	//  E.g., [TokenA amount (input), TokenB amount, TokenC amount (output)]
	// @return A vault of the last token in the swap path, with its balance equals to
	//  the last amount in `amounts`
	access(TMP_ENTITLEMENT_OWNER)
	fun makeSwaps(
		inputVault: @{FungibleToken.Vault},
		pools: &[
			&{IPierPair.IPool}
		],
		amounts: &[
			UFix64
		]
	): @{FungibleToken.Vault}{ 
		pre{ 
			pools.length == amounts.length - 1:
				"Metapier PierRouterLib: Invalid swap path"
		}
		var index = 1
		var toVault: @{FungibleToken.Vault}? <- inputVault
		while index < amounts.length{ 
			let pool = pools[index - 1]
			let fromVault <- toVault <- nil
			toVault <-! pool.swap(fromVault: <-fromVault!, forAmount: amounts[index])
			index = index + 1
		}
		return <-toVault!
	}
	
	// Given a swap path, returns the corresponding array of pools
	access(TMP_ENTITLEMENT_OWNER)
	fun getPoolsByPath(path: &[String]): [&PierPair.Pool]{ 
		pre{ 
			path.length >= 2:
				"Metapier PierRouterLib: Invalid path"
		}
		var index = 0
		let pools: [&PierPair.Pool] = []
		while index < path.length - 1{ 
			let pool = PierSwapFactory.getPoolByTypeIdentifiers(tokenATypeIdentifier: path[index], tokenBTypeIdentifier: path[index + 1]) ?? panic("Metapier PierRouterLib: Pool not found")
			pools.append(pool)
			index = index + 1
		}
		return pools
	}
	
	// Returns the sorted reserve amounts of the pool according to 
	// the order of [tokenATypeIdentifier, tokenBTypeIdentifier]
	access(TMP_ENTITLEMENT_OWNER)
	fun getSortedReserves(
		pool: &{IPierPair.IPool},
		tokenATypeIdentifier: String,
		tokenBTypeIdentifier: String
	): [
		UFix64; 2
	]{ 
		let reserves = pool.getReserves()
		if pool.tokenAType.identifier == tokenBTypeIdentifier{ 
			// sort reserves to match with the given order of types
			reserves[0] <-> reserves[1]
		}
		return reserves
	}
	
	// Given amountIn as the expected input of the first token in path,
	// returns amounts of each token in path
	access(TMP_ENTITLEMENT_OWNER)
	fun getAmountsByAmountIn(amountIn: UFix64, path: &[String], pools: &[&{IPierPair.IPool}]): [
		UFix64
	]{ 
		pre{ 
			path.length >= 2:
				"Metapier PierRouterLib: Invalid path"
		}
		let amounts = [amountIn]
		var index = 0
		while index < path.length - 1{ 
			let reserves = self.getSortedReserves(pool: pools[index], tokenATypeIdentifier: path[index], tokenBTypeIdentifier: path[index + 1])
			let nextAmount = self.getAmountOut(amountIn: amounts[index], reserveIn: reserves[0], reserveOut: reserves[1])
			amounts.append(nextAmount)
			index = index + 1
		}
		return amounts
	}
	
	// Given amountOut as the expected output of the last token in path,
	// returns amounts of each token in path
	access(TMP_ENTITLEMENT_OWNER)
	fun getAmountsByAmountOut(amountOut: UFix64, path: &[String], pools: &[&{IPierPair.IPool}]): [
		UFix64
	]{ 
		pre{ 
			path.length >= 2:
				"Metapier PierRouterLib: Invalid path"
		}
		let amounts: [UFix64] = [amountOut]
		var index = path.length - 1
		while index > 0{ 
			let reserves = self.getSortedReserves(pool: pools[index - 1], tokenATypeIdentifier: path[index - 1], tokenBTypeIdentifier: path[index])
			let nextAmount = self.getAmountIn(amountOut: amounts[0], reserveIn: reserves[0], reserveOut: reserves[1])
			amounts.insert(at: 0, nextAmount)
			index = index - 1
		}
		return amounts
	}
	
	// Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
	access(TMP_ENTITLEMENT_OWNER)
	fun getAmountOut(amountIn: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64{ 
		pre{ 
			amountIn > 0.0:
				"Metapier PierRouterLib: amountIn cannot be 0"
			reserveIn > 0.0 && reserveOut > 0.0:
				"Metapier PierRouterLib: Insufficient liquidity"
		}
		
		// amountInWithFee = amountIn * (1000 - TotalFeeCoefficient)
		let amountInWithFee =
			PierMath.UFix64ToRawUInt256(amountIn)
			* (1000 - UInt256(PierSwapSettings.getPoolTotalFeeCoefficient()))
		
		// numerator = amountInWithFee * reserveOut
		let numerator = amountInWithFee * PierMath.UFix64ToRawUInt256(reserveOut)
		
		// denominator = reserveIn * 1000 + amountInWithFee
		let denominator = PierMath.UFix64ToRawUInt256(reserveIn) * 1000 + amountInWithFee
		return PierMath.rawUInt256ToUFix64(numerator / denominator)
	}
	
	// Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	access(TMP_ENTITLEMENT_OWNER)
	fun getAmountIn(amountOut: UFix64, reserveIn: UFix64, reserveOut: UFix64): UFix64{ 
		pre{ 
			amountOut > 0.0:
				"Metapier PierRouterLib: amountOut cannot be 0"
			reserveIn > 0.0 && reserveOut > 0.0:
				"Metapier PierRouterLib: Insufficient liquidity"
		}
		
		// numerator = reserveIn * amountOut * 1000.0
		let numerator =
			PierMath.UFix64ToRawUInt256(reserveIn) * PierMath.UFix64ToRawUInt256(amountOut) * 1000
		
		// denominator = (reserveOut - amountOut) * (1000.0 - TotalFeeCoefficient)
		let denominator =
			PierMath.UFix64ToRawUInt256(reserveOut - amountOut)
			* (1000 - UInt256(PierSwapSettings.getPoolTotalFeeCoefficient()))
		return PierMath.rawUInt256ToUFix64(numerator / denominator + 1)
	}
}
