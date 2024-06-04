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
## The FLOAT Verifiers for FLOATs on Flow Quests

> Author: Bohao Tang<tech@btang.cn>
*/

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import Interfaces from "./Interfaces.cdc"

import UserProfile from "./UserProfile.cdc"

import CompetitionService from "./CompetitionService.cdc"

access(all)
contract FLOATVerifiers{ 
	access(all)
	struct EnsureFLOATExists: FLOAT.IVerifier{ 
		access(all)
		let eventId: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let collection = getAccount(claimee).capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<&FLOAT.Collection>(){ 
				let len = collection.ownedIdsFromEvent(eventId: self.eventId).length
				assert(len > 0, message: "You haven't the required FLOAT: #".concat(self.eventId.toString()))
			} else{ 
				panic("You do not have FLOAT Collection")
			}
		}
		
		init(eventId: UInt64){ 
			self.eventId = eventId
		}
	}
	
	access(all)
	struct BountyCompleted: FLOAT.IVerifier{ 
		access(all)
		let bountyId: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let profile = getAccount(claimee).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let isCompleted = profile.isBountyCompleted(bountyId: self.bountyId)
				assert(isCompleted, message: "You didn't finish the bounty #:".concat(self.bountyId.toString()))
			} else{ 
				panic("You do not have Profile resource")
			}
		}
		
		init(bountyId: UInt64){ 
			self.bountyId = bountyId
		}
	}
	
	access(all)
	struct MissionCompleted: FLOAT.IVerifier{ 
		access(all)
		let missionKey: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let profile = getAccount(claimee).capabilities.get<&UserProfile.Profile>(UserProfile.ProfilePublicPath).borrow<&UserProfile.Profile>(){ 
				let status = profile.getMissionStatus(missionKey: self.missionKey)
				assert(status.completed, message: "You didn't complete the mission #:".concat(self.missionKey))
			} else{ 
				panic("You do not have Profile resource")
			}
		}
		
		init(missionKey: String){ 
			self.missionKey = missionKey
		}
	}
}
