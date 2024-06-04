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

	import FiatToken from "./../../standardsV1/FiatToken.cdc"

import FlowSwapPair from "../0xc6c77b9f5c7a378f/FlowSwapPair.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import IPierPair from "../0x609e10301860b683/IPierPair.cdc"

import PierPair from "../0x609e10301860b683/PierPair.cdc"

import SwapConfig from "../0xb98a8c088deffb6c/SwapConfig.cdc"

import SwapFactory from "../0xb063c16cac85dbd1/SwapFactory.cdc"

import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"

import UsdcUsdtSwapPair from "../0x9c6f94adf47904b5/UsdcUsdtSwapPair.cdc"

access(all)
contract SwapPair{ 
	access(self)
	fun bloctoScaledReserves(): [UInt256]{ 
		return [
			SwapConfig.UFix64ToScaledUInt256(FlowSwapPair.getPoolAmounts().token1Amount),
			SwapConfig.UFix64ToScaledUInt256(FlowSwapPair.getPoolAmounts().token2Amount)
		]
	}
	
	access(self)
	fun bloctoUsdScaledReserves(): [UInt256]{ 
		return [
			SwapConfig.UFix64ToScaledUInt256(UsdcUsdtSwapPair.getPoolAmounts().token1Amount),
			SwapConfig.UFix64ToScaledUInt256(UsdcUsdtSwapPair.getPoolAmounts().token2Amount)
		]
	}
	
	access(self)
	fun metaScaledReserves(): [UInt256]{ 
		let mpool =
			getAccount(0x18187a9d276c0329).capabilities.get<&PierPair.Pool>(
				/public/metapierSwapPoolPublic
			).borrow()!
		let mpoolInfo = mpool.getReserves()
		return [
			SwapConfig.UFix64ToScaledUInt256(mpoolInfo[0]),
			SwapConfig.UFix64ToScaledUInt256(mpoolInfo[1])
		]
	}
	
	access(self)
	fun aggregateReserves(): [UFix64]{ 
		var fr: UInt256 = 0
		var ur: UInt256 = 0
		var r = self.metaScaledReserves()
		fr = fr + r[0]
		ur = ur + r[1]
		r = self.bloctoScaledReserves()
		fr = fr + r[0]
		ur = ur + r[1]
		return [SwapConfig.ScaledUInt256ToUFix64(fr), SwapConfig.ScaledUInt256ToUFix64(ur)]
	}
	
	access(self)
	fun getTokenOutVault(_ vaultInType: Type): @{FungibleToken.Vault}{ 
		if vaultInType == self.token0VaultType{ 
			return <-FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>())
		}
		return <-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
	}
	
	access(self)
	fun checkBloctoAmounts(_ amountIn: UFix64, _ vaultInType: Type): Bool{ 
		if UsdcUsdtSwapPair.isFrozen{ 
			return false
		}
		let ur = self.bloctoUsdScaledReserves()
		if vaultInType == self.token0VaultType{ 
			let amountOut = FlowSwapPair.quoteSwapExactToken1ForToken2(amount: amountIn)
			return amountOut <= SwapConfig.ScaledUInt256ToUFix64(ur[0])
		} else{ 
			return amountIn <= SwapConfig.ScaledUInt256ToUFix64(ur[1])
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun swap(vaultIn: @{FungibleToken.Vault}, exactAmountOut: UFix64?): @{FungibleToken.Vault}{ 
		pre{ 
			self.check(vaultIn.balance):
				"SwapPair : swap failed"
		}
		var mr: [[UInt256]] = []
		mr.append(self.metaScaledReserves())
		mr.append(self.bloctoScaledReserves())
		var idx = 0
		var odx = 1
		if vaultIn.isInstance(self.token1VaultType){ 
			idx = 1
			odx = 0
		}
		var groupAmounts = SwapConfig.splitAmountsIn(vaultIn.balance, idx, odx, mr)
		if !self.checkBloctoAmounts(groupAmounts[groupAmounts.length - 1], vaultIn.getType()){ 
			groupAmounts = [vaultIn.balance]
		}
		let swapOutVault <- self.getTokenOutVault(vaultIn.getType())
		var i = 0
		while i < groupAmounts.length{ 
			var amountIn = groupAmounts[i]
			if i == groupAmounts.length - 1{ 
				amountIn = vaultIn.balance
			}
			if amountIn > 0.0{ 
				let exactInVault <- vaultIn.withdraw(amount: amountIn)
				var vaultOut <- self.swapOnPlatform(vaultIn: <-exactInVault, p: i)
				swapOutVault.deposit(from: <-vaultOut)
			}
			i = i + 1
		}
		assert(vaultIn.balance == 0.0, message: "SwapPair: swap failed")
		destroy vaultIn
		return <-swapOutVault!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun swapOnPlatform(vaultIn: @{FungibleToken.Vault}, p: Int): @{FungibleToken.Vault}{ 
		switch p{ 
			case 0:
				let mpool =
					getAccount(0x18187a9d276c0329).capabilities.get<&PierPair.Pool>(
						/public/metapierSwapPoolPublic
					).borrow()!
				let minfo = mpool.getReserves()
				if vaultIn.isInstance(self.token0VaultType){ 
					let forAmount = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: minfo[0], reserveOut: minfo[1], swapFeeRateBps: 30)
					return <-mpool.swap(fromVault: <-vaultIn, forAmount: forAmount)
				} else{ 
					let forAmount = SwapConfig.getAmountOutVolatile(amountIn: vaultIn.balance, reserveIn: minfo[1], reserveOut: minfo[0], swapFeeRateBps: 30)
					return <-mpool.swap(fromVault: <-vaultIn, forAmount: forAmount)
				}
			case 1:
				if vaultIn.isInstance(self.token0VaultType){ 
					let token0Vault <- FlowSwapPair.swapToken1ForToken2(from: <-(vaultIn as! @FlowToken.Vault))
					return <-UsdcUsdtSwapPair.swapToken2ForToken1(from: <-token0Vault)
				} else{ 
					let token0Vault <- UsdcUsdtSwapPair.swapToken1ForToken2(from: <-(vaultIn as! @FiatToken.Vault))
					return <-FlowSwapPair.swapToken2ForToken1(from: <-token0Vault)
				}
		}
		return <-vaultIn
	}
	
	access(self)
	view fun check(_ amount: UFix64): Bool{ 
		let current = getCurrentBlock().height
		self.prune(current)
		if self.keys.containsKey(amount){ 
			return false
		}
		self.keys.insert(key: amount, current)
		return true
	}
	
	access(self)
	view fun prune(_ height: UInt64){ 
		for k in self.keys.keys{ 
			let value = self.keys[k]!
			if height - value > 100{ 
				self.keys.remove(key: k)
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun addLiquidity(tokenAVault: @{FungibleToken.Vault}, tokenBVault: @{FungibleToken.Vault}): @{
		FungibleToken.Vault
	}{ 
		pre{ 
			false:
				"SwapPair: added incompatible liquidity pair vaults"
		}
		self.token0Vault.deposit(from: <-tokenAVault)
		self.token1Vault.deposit(from: <-tokenBVault)
		return <-FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun removeLiquidity(lpTokenVault: @{FungibleToken.Vault}): @[{FungibleToken.Vault}]{ 
		pre{ 
			false:
				"SwapPair: input vault type mismatch with lpTokenVault type"
		}
		return <-[<-lpTokenVault]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getSwapFeeBps(): UInt64{ 
		return SwapFactory.getSwapFeeRateBps(stableMode: false)
	}
	
	access(all)
	resource PairPublic: SwapInterfaces.PairPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun swap(vaultIn: @{FungibleToken.Vault}, exactAmountOut: UFix64?): @{FungibleToken.Vault}{ 
			return <-SwapPair.swap(vaultIn: <-vaultIn, exactAmountOut: exactAmountOut)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun flashloan(executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>, requestedTokenVaultType: Type, requestedAmount: UFix64, params:{ String: AnyStruct}){} 
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeLiquidity(lpTokenVault: @{FungibleToken.Vault}): @[{FungibleToken.Vault}]{ 
			return <-SwapPair.removeLiquidity(lpTokenVault: <-lpTokenVault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addLiquidity(tokenAVault: @{FungibleToken.Vault}, tokenBVault: @{FungibleToken.Vault}): @{FungibleToken.Vault}{ 
			return <-SwapPair.addLiquidity(tokenAVault: <-tokenAVault, tokenBVault: <-tokenBVault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountIn(amountOut: UFix64, tokenOutKey: String): UFix64{ 
			let r = SwapPair.aggregateReserves()
			if tokenOutKey == SwapPair.token0Key{ 
				return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: r[1], reserveOut: r[0], swapFeeRateBps: SwapPair.getSwapFeeBps())
			} else{ 
				return SwapConfig.getAmountInVolatile(amountOut: amountOut, reserveIn: r[0], reserveOut: r[1], swapFeeRateBps: SwapPair.getSwapFeeBps())
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountOut(amountIn: UFix64, tokenInKey: String): UFix64{ 
			let r = SwapPair.aggregateReserves()
			if tokenInKey == SwapPair.token0Key{ 
				return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: r[0], reserveOut: r[1], swapFeeRateBps: SwapPair.getSwapFeeBps())
			} else{ 
				return SwapConfig.getAmountOutVolatile(amountIn: amountIn, reserveIn: r[1], reserveOut: r[0], swapFeeRateBps: SwapPair.getSwapFeeBps())
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice0CumulativeLastScaled(): UInt256{ 
			return 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice1CumulativeLastScaled(): UInt256{ 
			return 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBlockTimestampLast(): UFix64{ 
			return 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPairInfo(): [AnyStruct]{ 
			return []
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLpTokenVaultType(): Type{ 
			return Type<@FlowToken.Vault>()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isStableSwap(): Bool{ 
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStableCurveP(): UFix64{ 
			return 0.0
		}
	}
	
	access(self)
	let token0Vault: @{FungibleToken.Vault}
	
	access(self)
	let token1Vault: @{FungibleToken.Vault}
	
	access(self)
	let token0VaultType: Type
	
	access(self)
	let token1VaultType: Type
	
	access(self)
	let token0Key: String
	
	access(self)
	let token1Key: String
	
	access(self)
	var keys:{ UFix64: UInt64}
	
	init(){ 
		self.token0Vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
		self.token1Vault <- FiatToken.createEmptyVault(vaultType: Type<@FiatToken.Vault>())
		self.token0VaultType = self.token0Vault.getType()
		self.token1VaultType = self.token1Vault.getType()
		self.token0Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: self.token0VaultType.identifier
			)
		self.token1Key = SwapConfig.SliceTokenTypeIdentifierFromVaultType(
				vaultTypeIdentifier: self.token1VaultType.identifier
			)
		self.keys ={} 
		destroy <-self.account.storage.load<@AnyResource>(from: /storage/pair_public)
		self.account.storage.save(<-create PairPublic(), to: /storage/pair_public)
		var capability_1 =
			self.account.capabilities.storage.issue<&{SwapInterfaces.PairPublic}>(
				/storage/pair_public
			)
		self.account.capabilities.publish(capability_1, at: SwapConfig.PairPublicPath)
	}
}
