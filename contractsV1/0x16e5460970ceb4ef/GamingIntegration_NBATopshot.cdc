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

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import Market from "../0xc1e4f4f4c4257510/Market.cdc"

import DapperUtilityCoin from "./../../standardsV1/DapperUtilityCoin.cdc"

access(all)
contract GamingIntegration_NBATopshot{ 
	access(all)
	event ExpRewarded(amount: UFix64, to: Address)
	
	access(all)
	event NewExpWeight(weight: UFix64)
	
	access(all)
	var nbaExpWeight: UFix64
	
	// The wrapper function to purchase nba nfts
	access(TMP_ENTITLEMENT_OWNER)
	fun purchase(
		playerAddr: Address,
		salePublic: &{Market.SalePublic},
		tokenID: UInt64,
		buyTokens: @DapperUtilityCoin.Vault
	): @TopShot.NFT{ 
		// Gamification Rewards
		let expAmount = buyTokens.balance * self.nbaExpWeight
		ExpToken.gainExp(expAmount: expAmount, playerAddr: playerAddr)
		emit ExpRewarded(amount: expAmount, to: playerAddr)
		
		// Daily task
		DailyTask.completeDailyTask(playerAddr: playerAddr, taskType: "BUY_NBA")
		
		// Purchase NBA
		return <-salePublic.purchase(tokenID: 15172405, buyTokens: <-buyTokens)
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setExpWeight(weight: UFix64){ 
			emit NewExpWeight(weight: weight)
			GamingIntegration_NBATopshot.nbaExpWeight = weight
		}
	}
	
	init(){ 
		self.nbaExpWeight = 1.0
		self.account.storage.save(<-create Admin(), to: /storage/adminPath_nba)
	}
}
