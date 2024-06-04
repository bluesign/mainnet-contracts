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
## The Interfaces of Flow Quest

> Author: Bohao Tang<tech@btang.cn>

*/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Helper from "./Helper.cdc"

access(all)
contract Interfaces{ 
	
	// =================== Profile ====================
	access(all)
	struct LinkedIdentity{ 
		access(all)
		let platform: String
		
		access(all)
		let uid: String
		
		access(all)
		let display: MetadataViews.Display
		
		init(platform: String, uid: String, display: MetadataViews.Display){ 
			self.platform = platform
			self.uid = uid
			self.display = display
		}
	}
	
	access(all)
	struct MissionStatus{ 
		access(all)
		let steps: [Bool]
		
		access(all)
		let completed: Bool
		
		init(steps: [Bool]){ 
			self.steps = steps
			var completed = true
			for one in steps{ 
				completed = one && completed
			}
			self.completed = completed
		}
	}
	
	// Profile
	access(all)
	resource interface ProfilePublic{ 
		// readable
		access(TMP_ENTITLEMENT_OWNER)
		fun getId(): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReferredFrom(): Address?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReferralCode(): String?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIdentities(): [LinkedIdentity]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIdentity(platform: String): LinkedIdentity
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBountiesCompleted():{ UInt64: UFix64}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isBountyCompleted(bountyId: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMissionStatus(missionKey: String): MissionStatus
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMissionsParticipanted(): [String]
		
		// season points
		access(TMP_ENTITLEMENT_OWNER)
		fun isRegistered(seasonId: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeasonsJoined(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeasonPoints(seasonId: UInt64): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProfilePoints(): UInt64
		
		// writable
		access(account)
		fun addPoints(seasonId: UInt64, points: UInt64)
		
		access(account)
		fun completeBounty(bountyId: UInt64)
		
		access(account)
		fun updateMissionNewParams(missionKey: String, step: Int, params:{ String: AnyStruct})
		
		access(account)
		fun updateMissionVerificationResult(missionKey: String, step: Int, result: Bool)
		
		access(account)
		fun setupReferralCode(code: String)
	}
	
	// =================== Community ====================
	access(all)
	enum BountyType: UInt8{ 
		access(all)
		case mission
		
		access(all)
		case quest
	}
	
	access(all)
	struct interface BountyEntityIdentifier{ 
		access(all)
		let category: BountyType
		
		// The offchain key of the mission
		access(all)
		let key: String
		
		// The community belongs to
		access(all)
		let communityId: UInt64
		
		// get Bounty Entity
		access(TMP_ENTITLEMENT_OWNER)
		fun getBountyEntity(): &{BountyEntityPublic}
		
		// To simple string uid
		access(TMP_ENTITLEMENT_OWNER)
		fun toString(): String{ 
			return self.communityId.toString().concat(":").concat(self.key)
		}
	}
	
	access(all)
	struct interface BountyEntityPublic{ 
		access(all)
		let category: BountyType
		
		// The offchain key of the mission
		access(all)
		let key: String
		
		// The community belongs to
		access(all)
		let communityId: UInt64
		
		// display
		access(TMP_ENTITLEMENT_OWNER)
		fun getStandardDisplay(): MetadataViews.Display
		
		// To simple string uid
		access(TMP_ENTITLEMENT_OWNER)
		fun toString(): String{ 
			return self.communityId.toString().concat(":").concat(self.key)
		}
	}
	
	access(all)
	struct interface MissionInfoPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetail(): MissionDetail
	}
	
	access(all)
	struct MissionDetail{ 
		access(all)
		let steps: UInt64
		
		access(all)
		let stepsCfg: String
		
		init(steps: UInt64, stepsCfg: String){ 
			self.steps = steps
			self.stepsCfg = stepsCfg
		}
	}
	
	access(all)
	struct interface QuestInfoPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetail(): QuestDetail
	}
	
	access(all)
	struct QuestDetail{ 
		access(all)
		let missions: [{BountyEntityIdentifier}]
		
		access(all)
		let achievement: Helper.EventIdentifier?
		
		init(missions: [{BountyEntityIdentifier}], achievement: Helper.EventIdentifier?){ 
			self.missions = missions
			self.achievement = achievement
		}
	}
	
	// =================== Competition ====================
	access(all)
	struct interface UnlockCondition{ 
		access(all)
		let type: UInt8
		
		access(TMP_ENTITLEMENT_OWNER)
		fun isUnlocked(_ params:{ String: AnyStruct}): Bool
	}
	
	// Bounty information
	access(all)
	resource interface BountyInfoPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getID(): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPreconditions(): [{UnlockCondition}]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIdentifier():{ BountyEntityIdentifier}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRequiredMissionKeys(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRewardType(): Helper.MissionRewardType
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPointReward(): Helper.PointReward
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFLOATReward(): Helper.FLOATReward
	}
	
	// Competition public interface
	access(all)
	resource interface CompetitionPublic{ 
		// status
		access(TMP_ENTITLEMENT_OWNER)
		fun isActive(): Bool
		
		// information
		access(TMP_ENTITLEMENT_OWNER)
		fun getSeasonId(): UInt64
		
		// leaderboard
		access(TMP_ENTITLEMENT_OWNER)
		fun getRank(_ addr: Address): Int
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLeaderboardRanking(limit: Int?):{ UInt64: [Address]}
		
		// onProfile
		access(account)
		fun onProfileRegistered(acct: Address)
	}
	
	access(all)
	resource interface CompetitionServicePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getReferralAddress(_ code: String): Address?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReferralCode(_ addr: Address): String?
		
		// season
		access(TMP_ENTITLEMENT_OWNER)
		fun getActiveSeasonID(): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowSeason(seasonId: UInt64): &{CompetitionPublic}
		
		// bounties
		access(TMP_ENTITLEMENT_OWNER)
		fun getBountyIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPrimaryBountyIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasBountyByKey(_ key: String): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun checkBountyCompleteStatus(acct: Address, bountyId: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBountyInfo(_ bountyId: UInt64): &{BountyInfoPublic}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMissionRef(_ missionKey: String): &{BountyEntityPublic, MissionInfoPublic}
		
		access(account)
		fun onBountyCompleted(bountyId: UInt64, acct: Address)
	}
}
