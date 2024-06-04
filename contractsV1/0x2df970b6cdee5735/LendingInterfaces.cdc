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

# Lending related interface definitions all-in-one

# Author: Increment Labs

*/

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface LendingInterfaces{ 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface PoolPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolAddress(): Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnderlyingTypeString(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnderlyingAssetType(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnderlyingToLpTokenRateScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountLpTokenBalanceScaled(account: Address): UInt256
		
		/// Return snapshot of account borrowed balance in scaled UInt256 format
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountBorrowBalanceScaled(account: Address): UInt256
		
		/// Return: [scaledExchangeRate, scaledLpTokenBalance, scaledBorrowBalance, scaledAccountBorrowPrincipal, scaledAccountBorrowIndex]
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountSnapshotScaled(account: Address): [UInt256; 5]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAccountRealtimeScaled(account: Address): [UInt256; 5]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getInterestRateModelAddress(): Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolReserveFactorScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolAccrualBlockNumber(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolTotalBorrowsScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowIndexScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolTotalSupplyScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolCash(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolTotalLpTokenSupplyScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolTotalReservesScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowRateScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolSupplyAprScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowAprScaled(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolSupplierCount(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowerCount(): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolSupplierList(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowerList(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolSupplierSlicedList(from: UInt64, to: UInt64): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolBorrowerSlicedList(from: UInt64, to: UInt64): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFlashloanRateBps(): UInt64
		
		/// Accrue pool interest and checkpoint latest data to pool states
		access(TMP_ENTITLEMENT_OWNER)
		fun accrueInterest()
		
		access(TMP_ENTITLEMENT_OWNER)
		fun accrueInterestReadonly(): [UInt256; 4]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolCertificateType(): Type
		
		/// Note: Check to ensure @callerPoolCertificate's run-time type is another LendingPool's.IdentityCertificate,
		/// so that this public seize function can only be invoked by another LendingPool contract
		access(TMP_ENTITLEMENT_OWNER)
		fun seize(
			seizerPoolCertificate: @{LendingInterfaces.IdentityCertificate},
			seizerPool: Address,
			liquidator: Address,
			borrower: Address,
			scaledBorrowerCollateralLpTokenToSeize: UInt256
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun supply(supplierAddr: Address, inUnderlyingVault: @{FungibleToken.Vault})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun redeem(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			numLpTokenToRedeem: UFix64
		): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun redeemUnderlying(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			numUnderlyingToRedeem: UFix64
		): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(
			userCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>,
			borrowAmount: UFix64
		): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun repayBorrow(borrower: Address, repayUnderlyingVault: @{FungibleToken.Vault}): @{
			FungibleToken.Vault
		}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun liquidate(
			liquidator: Address,
			borrower: Address,
			poolCollateralizedToSeize: Address,
			repayUnderlyingVault: @{FungibleToken.Vault}
		): @{FungibleToken.Vault}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun flashloan(
			executorCap: Capability<&{LendingInterfaces.FlashLoanExecutor}>,
			requestedAmount: UFix64,
			params:{ 
				String: AnyStruct
			}
		){ 
			return
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface PoolAdminPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setInterestRateModel(newInterestRateModelAddress: Address)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setReserveFactor(newReserveFactor: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPoolSeizeShare(newPoolSeizeShare: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setComptroller(newComptrollerAddress: Address)
		
		/// A pool can only be initialized once
		access(TMP_ENTITLEMENT_OWNER)
		fun initializePool(
			reserveFactor: UFix64,
			poolSeizeShare: UFix64,
			interestRateModelAddress: Address
		)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawReserves(reduceAmount: UFix64): @{FungibleToken.Vault}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFlashloanRateBps(rateBps: UInt64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFlashloanOpen(isOpen: Bool)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface FlashLoanExecutor{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun executeAndRepay(loanedToken: @{FungibleToken.Vault}, params:{ String: AnyStruct}): @{
			FungibleToken.Vault
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface InterestRateModelPublic{ 
		/// exposing model specific fields, e.g.: modelName, model params.
		access(TMP_ENTITLEMENT_OWNER)
		fun getInterestRateModelParams():{ String: AnyStruct}
		
		/// pool's capital utilization rate (scaled up by scaleFactor, e.g. 1e18)
		access(TMP_ENTITLEMENT_OWNER)
		fun getUtilizationRate(cash: UInt256, borrows: UInt256, reserves: UInt256): UInt256
		
		/// Get the borrow interest rate per block (scaled up by scaleFactor, e.g. 1e18)
		access(TMP_ENTITLEMENT_OWNER)
		fun getBorrowRate(cash: UInt256, borrows: UInt256, reserves: UInt256): UInt256
		
		/// Get the supply interest rate per block (scaled up by scaleFactor, e.g. 1e18)
		access(TMP_ENTITLEMENT_OWNER)
		fun getSupplyRate(
			cash: UInt256,
			borrows: UInt256,
			reserves: UInt256,
			reserveFactor: UInt256
		): UInt256
		
		/// Get the number of blocks per year.
		access(TMP_ENTITLEMENT_OWNER)
		fun getBlocksPerYear(): UInt256
	}
	
	/// IdentityCertificate resource which is used to identify account address or perform caller authentication
	access(TMP_ENTITLEMENT_OWNER)
	resource interface IdentityCertificate{} 
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface OraclePublic{ 
		/// Get the given pool's underlying asset price denominated in USD.
		/// Note: Return value of 0.0 means the given pool's price feed is not available.
		access(TMP_ENTITLEMENT_OWNER)
		fun getUnderlyingPrice(pool: Address): UFix64
		
		/// Return latest reported data in [timestamp, priceData]
		access(TMP_ENTITLEMENT_OWNER)
		fun latestResult(pool: Address): [UFix64; 2]
		
		/// Return supported markets' addresses
		access(TMP_ENTITLEMENT_OWNER)
		fun getSupportedFeeds(): [Address]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface ComptrollerPublic{ 
		/// Return error string on condition (or nil)
		access(TMP_ENTITLEMENT_OWNER)
		fun supplyAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			supplierAddress: Address,
			supplyUnderlyingAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun redeemAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			redeemerAddress: Address,
			redeemLpTokenAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			borrowerAddress: Address,
			borrowUnderlyingAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun repayAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolAddress: Address,
			borrowerAddress: Address,
			repayUnderlyingAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun liquidateAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			poolBorrowed: Address,
			poolCollateralized: Address,
			borrower: Address,
			repayUnderlyingAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun seizeAllowed(
			poolCertificate: @{LendingInterfaces.IdentityCertificate},
			borrowPool: Address,
			collateralPool: Address,
			liquidator: Address,
			borrower: Address,
			seizeCollateralPoolLpTokenAmountScaled: UInt256
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun callerAllowed(
			callerCertificate: @{LendingInterfaces.IdentityCertificate},
			callerAddress: Address
		): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun calculateCollateralPoolLpTokenToSeize(
			borrower: Address,
			borrowPool: Address,
			collateralPool: Address,
			actualRepaidBorrowAmountScaled: UInt256
		): UInt256
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserCertificateType(): Type
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPoolPublicRef(poolAddr: Address): &{PoolPublic}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAllMarkets(): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMarketInfo(poolAddr: Address):{ String: AnyStruct}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserMarkets(userAddr: Address): [Address]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserCrossMarketLiquidity(userAddr: Address): [String; 3]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserMarketInfo(userAddr: Address, poolAddr: Address):{ String: AnyStruct}
	}
}
