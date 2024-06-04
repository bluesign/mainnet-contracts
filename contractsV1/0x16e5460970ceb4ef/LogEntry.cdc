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

  LogEntry for Increment products for purpose of onchain data analysis.

  Declaring misc events not belonging to a specific product, e.g.: sign agreement tx, aggregation tx, et al. 

  Author: Increment Labs
*/

access(all)
contract LogEntry{ 
	// Naming convension: event - Log<X>E ; corresponding function - Log<X>
	access(all)
	event LogAgreementE(a: Address, t: UFix64)
	
	// User Swap Event which entered from the increment Aggregator entrance.
	// tokenInKey & tokenOutAmount are the tokens selected by the user at the frontend.
	// amountIn & amountOut are the actual swap amounts.
	access(all)
	event AggregateSwap(
		userAddr: Address,
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		amountInSplitByPoolSource:{ 
			String: UFix64
		},
		isExactAForB: Bool,
		blockHeight: UInt64,
		timestamp: UFix64
	)
	
	// SwapPool involved in Aggregator
	access(all)
	event PoolSwapInAggregator(
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		poolAddress: Address?,
		poolSource: String
	)
	
	// ... More to be added here ...
	access(TMP_ENTITLEMENT_OWNER)
	fun LogAgreement(addr: Address){ 
		emit LogAgreementE(a: addr, t: getCurrentBlock().timestamp)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun LogAggregateSwap(
		userAddr: Address,
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		amountInSplitByPoolSource:{ 
			String: UFix64
		},
		isExactAForB: Bool,
		blockHeight: UInt64,
		timestamp: UFix64
	){ 
		emit AggregateSwap(
			userAddr: userAddr,
			tokenInKey: tokenInKey,
			tokenOutKey: tokenOutKey,
			tokenInAmount: tokenInAmount,
			tokenOutAmount: tokenOutAmount,
			amountInSplitByPoolSource: amountInSplitByPoolSource,
			isExactAForB: isExactAForB,
			blockHeight: blockHeight,
			timestamp: timestamp
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun LogPoolSwapInAggregator(
		tokenInKey: String,
		tokenOutKey: String,
		tokenInAmount: UFix64,
		tokenOutAmount: UFix64,
		poolAddress: Address?,
		poolSource: String
	){ 
		emit PoolSwapInAggregator(
			tokenInKey: tokenInKey,
			tokenOutKey: tokenOutKey,
			tokenInAmount: tokenInAmount,
			tokenOutAmount: tokenOutAmount,
			poolAddress: poolAddress,
			poolSource: poolSource
		)
	}
// ... More to be added here ...
}
