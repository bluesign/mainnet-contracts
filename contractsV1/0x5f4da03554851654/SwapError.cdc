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

	access(all)
contract SwapError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case CANNOT_CREATE_PAIR_WITH_SAME_TOKENS
		
		access(all)
		case ADD_PAIR_DUPLICATED
		
		access(all)
		case NONEXISTING_SWAP_PAIR
		
		access(all)
		case LOST_PUBLIC_CAPABILITY // 5
		
		
		access(all)
		case SLIPPAGE_OFFSET_TOO_LARGE
		
		access(all)
		case EXCESSIVE_INPUT_AMOUNT
		
		access(all)
		case EXPIRED
		
		access(all)
		case INSUFFICIENT_OUTPUT_AMOUNT
		
		access(all)
		case MISMATCH_LPTOKEN_VAULT // 10
		
		
		access(all)
		case ADD_ZERO_LIQUIDITY
		
		access(all)
		case REENTRANT
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun ErrorEncode(msg: String, err: ErrorCode): String{ 
		return "[IncSwapErrorMsg:".concat(msg).concat("]").concat("[IncSwapErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
