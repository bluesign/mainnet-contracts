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

	import FLOATEventSeries from "./FLOATEventSeries.cdc"

access(all)
contract FLOATTreasuryStrategies{ 
	/**	____ _  _ ____ _  _ ___ ____
		   *   |___ |  | |___ |\ |  |  [__
			*  |___  \/  |___ | \|  |  ___]
			 ******************************/
	
	access(all)
	event FLOATStrategyGoalAccomplished(
		strategyIdentifier: String,
		strategyUuid: UInt64,
		user: Address
	)
	
	access(all)
	event FLOATStrategyLotteryDrawn(strategyIdentifier: String, winners: [Address])
	
	/**	____ _  _ _  _ ____ ___ _ ____ _  _ ____ _	_ ___ _   _
		   *   |___ |  | |\ | |	 |  | |  | |\ | |__| |	|  |   \_/
			*  |	|__| | \| |___  |  | |__| | \| |  | |___ |  |	|
			 ***********************************************************/
	
	access(all)
	enum StrategyType: UInt8{ 
		access(all)
		case Lottery
		
		access(all)
		case ClaimingQueue
	}
	
	// Strategy parameter
	access(all)
	struct LotteryDetail{ 
		// minimium valid users reached
		access(all)
		let minimiumValid: UInt64
		
		// datetimes ending to limit
		access(all)
		let ending:{ FLOATEventSeries.StrategyState: UFix64}
		
		// valid users to do a lottery
		access(all)
		let valid: [Address]
		
		// lottery winners
		access(all)
		let winners: [Address]
		
		init(
			_ minValid: UInt64,
			_ ending:{ 
				FLOATEventSeries.StrategyState: UFix64
			},
			_ valid: [
				Address
			],
			_ winners: [
				Address
			]
		){ 
			self.minimiumValid = minValid
			self.ending = ending
			self.valid = valid
			self.winners = winners
		}
	}
	
	// distrute reward by Lottery
	access(all)
	resource LotteryStrategy: FLOATEventSeries.ITreasuryStrategy{ 
		// strategy general controller
		access(account)
		let controller: @FLOATEventSeries.StrategyController
		
		access(self)
		let params:{ String: AnyStruct}
		
		access(self)
		let minimiumValid: UInt64
		
		access(self)
		let ending:{ FLOATEventSeries.StrategyState: UFix64}
		
		access(self)
		var valid: [Address]
		
		access(self)
		var winners: [Address]
		
		init(controller: @FLOATEventSeries.StrategyController, params:{ String: AnyStruct}){ 
			self.controller <- controller
			self.params = params
			let info = self.controller.getInfo()
			if let value = params["minValid"]{ 
				self.minimiumValid = value as! UInt64
			} else{ 
				self.minimiumValid = info.delivery.maxClaimableShares
			}
			assert(self.minimiumValid >= info.delivery.maxClaimableShares, message: "min valid amount should be greater then max claimable amount.")
			
			// user ending time
			self.ending = FLOATTreasuryStrategies.parseStrategyTime(params)
			self.valid = []
			self.winners = []
		}
		
		// Fetch detail of the strategy
		access(TMP_ENTITLEMENT_OWNER)
		fun getStrategyDetail(): LotteryDetail{ 
			return LotteryDetail(self.minimiumValid, self.ending, self.valid, self.winners)
		}
		
		// invoked when state changed
		access(account)
		fun onStateChanged(state: FLOATEventSeries.StrategyState){ 
			// if current is not `claimable`, return directly
			if state != FLOATEventSeries.StrategyState.claimable{ 
				return
			}
			
			// special for claimable
			let isValidEnough = UInt64(self.valid.length) >= self.minimiumValid
			assert(isValidEnough, message: "Valid addresses is not enough.")
			let info = self.controller.getInfo()
			let winnerAmount = info.delivery.maxClaimableShares
			
			// draw a lottery to pick winners
			var amt: UInt64 = 0
			while amt < winnerAmount{ 
				let rand = revertibleRandom<UInt64>()
				let pickedIndex = rand % UInt64(self.valid.length)
				let pickedAddress = self.valid[pickedIndex]
				if !self.winners.contains(pickedAddress){ 
					// remove from valid
					self.valid.remove(at: pickedIndex)
					// add to winners
					self.winners.append(pickedAddress)
					amt = amt + 1
				}
			}
			emit FLOATStrategyLotteryDrawn(strategyIdentifier: self.getType().identifier, winners: self.winners)
		}
		
		// ---------- opening Stage ----------
		access(account)
		fun isEligible(user: &FLOATEventSeries.Achievement): Bool{ 
			let address = user.getOwner()
			return self.valid.contains(address) || self.winners.contains(address)
		}
		
		// update user's achievement
		access(account)
		fun onGoalAccomplished(user: &FLOATEventSeries.Achievement){ 
			var isValid = false
			let now = getCurrentBlock().timestamp
			// user should accomplish goals before opening ending
			if now > self.ending[FLOATEventSeries.StrategyState.opening] ?? now{ 
				return
			}
			let info = self.controller.getInfo()
			if info.consumable{ 
				isValid = info.threshold <= user.consumableScore
			} else{ 
				isValid = info.threshold <= user.score
			}
			// add to valid
			let address = user.getOwner()
			if isValid && !self.valid.contains(address){ 
				self.valid.append(address)
				emit FLOATStrategyGoalAccomplished(strategyIdentifier: self.getType().identifier, strategyUuid: self.uuid, user: address)
			}
		}
		
		// ---------- claimable Stage ----------
		// verify if the user match the strategy
		access(account)
		fun verifyClaimable(user: &FLOATEventSeries.Achievement): Bool{ 
			let now = getCurrentBlock().timestamp
			assert(now <= self.ending[FLOATEventSeries.StrategyState.claimable] ?? now, message: "Sorry! The claimable ending time is ran out.")
			return self.winners.contains(user.getOwner())
		}
	}
	
	// Strategy parameter
	access(all)
	struct ClaimingQueueDetail{ 
		// datetimes ending to limit
		access(all)
		let ending:{ FLOATEventSeries.StrategyState: UFix64}
		
		init(_ ending:{ FLOATEventSeries.StrategyState: UFix64}){ 
			self.ending = ending
		}
	}
	
	// distrute reward by queue
	access(all)
	resource ClaimingQueueStrategy: FLOATEventSeries.ITreasuryStrategy{ 
		// strategy general controller
		access(account)
		let controller: @FLOATEventSeries.StrategyController
		
		access(self)
		let params:{ String: AnyStruct}
		
		access(self)
		let ending:{ FLOATEventSeries.StrategyState: UFix64}
		
		init(controller: @FLOATEventSeries.StrategyController, params:{ String: AnyStruct}){ 
			self.controller <- controller
			self.params = params
			
			// user ending time
			self.ending = FLOATTreasuryStrategies.parseStrategyTime(params)
		}
		
		// Fetch detail of the strategy
		access(TMP_ENTITLEMENT_OWNER)
		fun getStrategyDetail(): ClaimingQueueDetail{ 
			return ClaimingQueueDetail(self.ending)
		}
		
		// invoked when state changed
		access(account)
		fun onStateChanged(state: FLOATEventSeries.StrategyState){} 
		
		// NOTHING
		// ---------- opening Stage ----------
		access(account)
		fun isEligible(user: &FLOATEventSeries.Achievement): Bool{ 
			return true
		}
		
		// update user's achievement
		access(account)
		fun onGoalAccomplished(user: &FLOATEventSeries.Achievement){} 
		
		// NOTHING
		// ---------- claimable Stage ----------
		// verify if the user match the strategy
		access(account)
		fun verifyClaimable(user: &FLOATEventSeries.Achievement): Bool{ 
			let now = getCurrentBlock().timestamp
			assert(now <= self.ending[FLOATEventSeries.StrategyState.claimable] ?? now, message: "Sorry! The claimable ending time is ran out.")
			return true
		}
	}
	
	// parse strategy ending time from params
	access(contract)
	fun parseStrategyTime(_ params:{ String: AnyStruct}):{ FLOATEventSeries.StrategyState: UFix64}{ 
		let ending:{ FLOATEventSeries.StrategyState: UFix64} ={} 
		let now = getCurrentBlock().timestamp
		if let value = params["openingEnd"]{ 
			let timestamp = value as! UFix64
			assert(now <= timestamp, message: "Sorry! The openingEnd time has run out")
			ending[FLOATEventSeries.StrategyState.opening] = timestamp
		}
		if let value = params["claimableEnd"]{ 
			let timestamp = value as! UFix64
			assert(now <= timestamp, message: "Sorry! The claimableEnd time has run out")
			ending[FLOATEventSeries.StrategyState.claimable] = timestamp
		}
		return ending
	}
	
	// Strategy factory method
	access(TMP_ENTITLEMENT_OWNER)
	fun createStrategy(
		type: StrategyType,
		controller: @FLOATEventSeries.StrategyController,
		params:{ 
			String: AnyStruct
		}
	): @{FLOATEventSeries.ITreasuryStrategy}?{ 
		switch type{ 
			case StrategyType.Lottery:
				return <-create LotteryStrategy(controller: <-controller, params: params)
			case StrategyType.ClaimingQueue:
				return <-create ClaimingQueueStrategy(controller: <-controller, params: params)
			default:
				destroy controller
				return nil
		}
	}
}
