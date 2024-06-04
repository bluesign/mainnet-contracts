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
contract FlowBlocksTradingScore{ 
	// -----------------------------------------------------------------------
	// Contract Events
	// -----------------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	access(all)
	event TradingScoreIncreased(wallet: Address, points: UInt32)
	
	access(all)
	event TradingScoreDecreased(wallet: Address, points: UInt32)
	
	// -----------------------------------------------------------------------
	// Named Paths
	// -----------------------------------------------------------------------
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPrivatePath: PrivatePath
	
	// -----------------------------------------------------------------------
	// Contract Fields
	// -----------------------------------------------------------------------
	access(self)
	var tradingScores:{ Address: UInt32}
	
	access(all)
	resource Admin{ 
		access(all)
		fun deductPoints(wallet: Address, pointsToDeduct: UInt32){ 
			pre{ 
				FlowBlocksTradingScore.tradingScores[wallet] != nil:
					"Can't deduct points: Address has no trading score."
			}
			if pointsToDeduct > FlowBlocksTradingScore.tradingScores[wallet]!{ 
				FlowBlocksTradingScore.tradingScores.insert(key: wallet, 0)
			} else{ 
				FlowBlocksTradingScore.tradingScores.insert(key: wallet, FlowBlocksTradingScore.tradingScores[wallet]! - pointsToDeduct)
			}
			emit TradingScoreDecreased(wallet: wallet, points: pointsToDeduct)
		}
		
		access(all)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	access(account)
	fun increaseTradingScore(wallet: Address, points: UInt32){ 
		if FlowBlocksTradingScore.tradingScores[wallet] == nil{ 
			FlowBlocksTradingScore.tradingScores[wallet] = points
		} else{ 
			FlowBlocksTradingScore.tradingScores[wallet] = FlowBlocksTradingScore.tradingScores[wallet]! + points
		}
		emit TradingScoreIncreased(wallet: wallet, points: points)
	}
	
	access(all)
	fun getTradingScores():{ Address: UInt32}{ 
		return FlowBlocksTradingScore.tradingScores
	}
	
	access(all)
	fun getTradingScore(wallet: Address): UInt32?{ 
		return FlowBlocksTradingScore.tradingScores[wallet]
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlowBlocksTradingScoreAdmin_3
		self.AdminPrivatePath = /private/FlowBlocksTradingScoreAdmin_3
		self.tradingScores ={} 
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&FlowBlocksTradingScore.Admin>(
				self.AdminStoragePath
			)
		self.account.capabilities.publish(capability_1, at: self.AdminPrivatePath)
		?? panic("Could not get a capability to the admin")
		emit ContractInitialized()
	}
}
