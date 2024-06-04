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

# Common liquid staking errors

# Author: Increment Labs

*/

access(all)
contract LiquidStakingError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case STAKING_REWARD_NOT_PAID
		
		access(all)
		case EXCEED_STAKE_CAP
		
		access(all)
		case STAKE_NOT_OPEN
		
		access(all)
		case UNSTAKE_NOT_OPEN
		
		access(all)
		case MIGRATE_NOT_OPEN
		
		access(all)
		case STAKING_AUCTION_NOT_IN_PROGRESS
		
		access(all)
		case QUOTE_EPOCH_EXPIRED
		
		access(all)
		case CANNOT_CASHOUT_WITHDRAW_VOUCHER
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun ErrorEncode(msg: String, err: ErrorCode): String{ 
		return "[IncLiquidStakingErrorMsg:".concat(msg).concat("]").concat(
			"[IncLiquidStakingErrorCode:"
		).concat(err.rawValue.toString()).concat("]")
	}
}
