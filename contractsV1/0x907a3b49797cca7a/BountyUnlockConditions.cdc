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
## The contract of bounty unlock condition on Flow Quest

> Author: Bohao Tang<tech@btang.cn>
*/

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import Interfaces from "./Interfaces.cdc"

import UserProfile from "./UserProfile.cdc"

access(all)
contract BountyUnlockConditions{ 
	access(all)
	enum UnlockConditionTypes: UInt8{ 
		access(all)
		case MinimumPoint
		
		access(all)
		case FLOATRequired
		
		access(all)
		case CompletedBountyAmount
		
		access(all)
		case BountyCompleted
	}
	
	access(all)
	struct MinimumPointRequired: Interfaces.UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(all)
		let seasonId: UInt64
		
		access(all)
		let amount: UInt64
		
		init(seasonId: UInt64, amount: UInt64){ 
			self.type = UnlockConditionTypes.MinimumPoint.rawValue
			self.seasonId = seasonId
			self.amount = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool{ 
			let profileAddr: Address = params["profile"]! as! Address
			if let profile = getAccount(profileAddr).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let points = profile.getSeasonPoints(seasonId: self.seasonId)
				return points >= self.amount
			} else{ 
				return false
			}
		}
	}
	
	access(all)
	struct FLOATRequired: Interfaces.UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(all)
		let host: Address
		
		access(all)
		let eventId: UInt64
		
		init(host: Address, eventId: UInt64){ 
			self.type = UnlockConditionTypes.FLOATRequired.rawValue
			self.host = host
			self.eventId = eventId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool{ 
			let profileAddr: Address = params["profile"]! as! Address
			if let collection = getAccount(profileAddr).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>(){ 
				let len = collection.ownedIdsFromEvent(eventId: self.eventId).length
				return len > 0
			} else{ 
				return false
			}
		}
	}
	
	access(all)
	struct CompletedBountyAmount: Interfaces.UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(all)
		let amount: UInt64
		
		init(amount: UInt64){ 
			self.type = UnlockConditionTypes.CompletedBountyAmount.rawValue
			self.amount = amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool{ 
			let profileAddr: Address = params["profile"]! as! Address
			if let profile = getAccount(profileAddr).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let completed = profile.getBountiesCompleted()
				return UInt64(completed.keys.length) >= self.amount
			} else{ 
				return false
			}
		}
	}
	
	access(all)
	struct BountyCompleted: Interfaces.UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(all)
		let bountyId: UInt64
		
		init(bountyId: UInt64){ 
			self.type = UnlockConditionTypes.BountyCompleted.rawValue
			self.bountyId = bountyId
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool{ 
			let profileAddr: Address = params["profile"]! as! Address
			if let profile = getAccount(profileAddr).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				return profile.isBountyCompleted(bountyId: self.bountyId)
			} else{ 
				return false
			}
		}
	}
}
