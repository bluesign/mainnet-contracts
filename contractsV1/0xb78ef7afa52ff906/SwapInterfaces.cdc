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

	/**

# Swap related interface definitions all-in-one

# Author: Increment Labs

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface SwapInterfaces{ 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface PairPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addLiquidity(
			tokenAVault: @{FungibleToken.Vault},
			tokenBVault: @{FungibleToken.Vault}
		): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeLiquidity(lpTokenVault: @{FungibleToken.Vault}): @[{FungibleToken.Vault}]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun swap(vaultIn: @{FungibleToken.Vault}, exactAmountOut: UFix64?): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun flashloan(
			executorCap: Capability<&{SwapInterfaces.FlashLoanExecutor}>,
			requestedTokenVaultType: Type,
			requestedAmount: UFix64,
			params:{ 
				String: AnyStruct
			}
		){ 
			return
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountIn(amountOut: UFix64, tokenOutKey: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountOut(amountIn: UFix64, tokenInKey: String): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice0CumulativeLastScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrice1CumulativeLastScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBlockTimestampLast(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPairInfo(): [AnyStruct]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLpTokenVaultType(): Type
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isStableSwap(): Bool{ 
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getStableCurveP(): UFix64{ 
			return 1.0
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface LpTokenCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(pairAddr: Address, lpTokenVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCollectionLength(): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLpTokenBalance(pairAddr: Address): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllLPTokens(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSlicedLPTokens(from: UInt64, to: UInt64): [Address]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface FlashLoanExecutor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun executeAndRepay(loanedToken: @{FungibleToken.Vault}, params:{ String: AnyStruct}): @{
			FungibleToken.Vault
		}
	}
}
