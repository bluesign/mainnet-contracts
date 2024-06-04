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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ExpToken from "./ExpToken.cdc"

import DailyTask from "./DailyTask.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

access(all)
contract GamingIntegration_FLOAT{ 
	access(all)
	event ExpRewarded(amount: UFix64, to: Address)
	
	access(all)
	event NewExpWeight(weight: UFix64)
	
	access(all)
	var floatExpWeight: UFix64
	
	// The wrapper function to claim FLOAT requires the playerAddress to be passed in.
	access(TMP_ENTITLEMENT_OWNER)
	fun claim(
		playerAddr: Address,
		FLOATEvent: &FLOAT.FLOATEvent,
		recipient: &FLOAT.Collection,
		params:{ 
			String: AnyStruct
		}
	){ 
		// Gamification Rewards
		let expAmount = self.floatExpWeight
		ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)
		
		// Claim FLOAT
		FLOATEvent.claim(recipient: recipient, params: params)
		
		// Daily task
		DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "MINT_FLOAT")
		emit ExpRewarded(amount: expAmount, to: playerAddr)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setExpWeight(weight: UFix64){ 
			emit NewExpWeight(weight: weight)
			GamingIntegration_FLOAT.floatExpWeight = weight
		}
	}
	
	init(){ 
		self.floatExpWeight = 10.0
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_float)
	}
}
