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
contract MelodyError{ 
	access(all)
	enum ErrorCode: UInt8{ 
		access(all)
		case NO_ERROR
		
		access(all)
		case PAUSED
		
		access(all)
		case NOT_EXIST
		
		access(all)
		case INVALID_PARAMETERS
		
		access(all)
		case NEGATIVE_VALUE_NOT_ALLOWED
		
		access(all)
		case ALREADY_EXIST
		
		access(all)
		case CAN_NOT_BE_ZERO
		
		access(all)
		case SAME_BOOL_STATE
		
		access(all)
		case WRONG_LIFE_CYCLE_STATE
		
		access(all)
		case ACCESS_DENIED
		
		access(all)
		case PAYMENT_NOT_REVOKABLE
		
		access(all)
		case NOT_TRANSFERABLE
		
		access(all)
		case TYPE_MISMATCH
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun errorEncode(msg: String, err: ErrorCode): String{ 
		return "[MelodyErrorMsg:".concat(msg).concat("]").concat("[MelodyErrorCode:").concat(
			err.rawValue.toString()
		).concat("]")
	}
	
	init(){} 
}
