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

	// MADE BY: Bohao Tang
import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import FLOATEventSeries from "./FLOATEventSeries.cdc"

access(all)
contract FLOATChallengeVerifiers{ 
	//
	// ChallengeAchievementPoint
	// 
	// Specifies a FLOAT Challenge to limit who accomplished 
	// a number of achievement point can claim the FLOAT
	access(all)
	struct ChallengeAchievementPoint: FLOAT.IVerifier{ 
		access(all)
		let challengeIdentifier: FLOATEventSeries.EventSeriesIdentifier
		
		access(all)
		let challengeThresholdPoints: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let claimee: Address = params["claimee"]! as! Address
			if let achievementBoard = getAccount(claimee).capabilities.get<&FLOATEventSeries.AchievementBoard>(FLOATEventSeries.FLOATAchievementBoardPublicPath).borrow<&FLOATEventSeries.AchievementBoard>(){ 
				// build goal status by different ways
				if let record = achievementBoard.borrowAchievementRecordRef(host: self.challengeIdentifier.host, seriesId: self.challengeIdentifier.id){ 
					assert(record.score >= self.challengeThresholdPoints, message: "You do not meet the minimum required Achievement Point for Challenge#".concat(self.challengeIdentifier.id.toString()))
				} else{ 
					panic("You do not have Challenge Achievement Record for Challenge#".concat(self.challengeIdentifier.id.toString()))
				}
			} else{ 
				panic("You do not have Challenge Achievement Board")
			}
		}
		
		init(_challengeHost: Address, _challengeId: UInt64, thresholdPoints: UInt64){ 
			self.challengeThresholdPoints = thresholdPoints
			self.challengeIdentifier = FLOATEventSeries.EventSeriesIdentifier(_challengeHost, _challengeId)
			// ensure challenge exists
			self.challengeIdentifier.getEventSeriesPublic()
		}
	}
}
