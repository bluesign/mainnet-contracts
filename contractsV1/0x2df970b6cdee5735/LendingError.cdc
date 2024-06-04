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

# Common lending errors

# Author: Increment Labs

*/

access(all)
contract LendingError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		/// Pool related:
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case INVALID_USER_CERTIFICATE
		
		access(all)
		case INVALID_POOL_CERTIFICATE
		
		access(all)
		case CANNOT_ACCESS_POOL_PUBLIC_CAPABILITY
		
		access(all)
		case CANNOT_ACCESS_COMPTROLLER_PUBLIC_CAPABILITY // 5
		
		
		access(all)
		case CANNOT_ACCESS_INTEREST_RATE_MODEL_CAPABILITY
		
		access(all)
		case POOL_INITIALIZED
		
		access(all)
		case EMPTY_FUNGIBLE_TOKEN_VAULT
		
		access(all)
		case MISMATCHED_INPUT_VAULT_TYPE_WITH_POOL
		
		access(all)
		case INSUFFICIENT_POOL_LIQUIDITY // 10
		
		
		access(all)
		case REDEEM_FAILED_NO_ENOUGH_LP_TOKEN
		
		access(all)
		case SAME_LIQUIDATOR_AND_BORROWER
		
		access(all)
		case EXTERNAL_SEIZE_FROM_SELF
		
		access(all)
		case EXCEED_TOTAL_RESERVES
		
		/// Comptroller:
		access(all)
		case ADD_MARKET_DUPLICATED // 15
		
		
		access(all)
		case ADD_MARKET_NO_ORACLE_PRICE
		
		access(all)
		case UNKNOWN_MARKET
		
		access(all)
		case MARKET_NOT_OPEN
		
		access(all)
		case REDEEM_NOT_ALLOWED_POSITION_UNDER_WATER
		
		access(all)
		case BORROW_NOT_ALLOWED_EXCEED_BORROW_CAP // 20
		
		
		access(all)
		case BORROW_NOT_ALLOWED_POSITION_UNDER_WATER
		
		access(all)
		case LIQUIDATION_NOT_ALLOWED_SEIZE_MORE_THAN_BALANCE
		
		access(all)
		case LIQUIDATION_NOT_ALLOWED_POSITION_ABOVE_WATER
		
		access(all)
		case LIQUIDATION_NOT_ALLOWED_TOO_MUCH_REPAY
		
		access(all)
		case SUPPLY_NOT_ALLOWED_EXCEED_SUPPLY_CAP // 25
		
		
		access(all)
		case FLASHLOAN_EXECUTOR_SETUP
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun ErrorEncode(msg: String, err: ErrorCode): String{ 
		return "[IncErrorMsg:".concat(msg).concat("]").concat("[IncErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
