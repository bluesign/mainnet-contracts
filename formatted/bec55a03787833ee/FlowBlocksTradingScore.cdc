pub contract FlowBlocksTradingScore{ 
    pub        // -----------------------------------------------------------------------
        // Contract Events
        // -----------------------------------------------------------------------
        event ContractInitialized()
    
    pub event TradingScoreIncreased(wallet: Address, points: UInt32)
    
    pub event TradingScoreDecreased(wallet: Address, points: UInt32)
    
    // -----------------------------------------------------------------------
    // Named Paths
    // -----------------------------------------------------------------------
    pub let AdminStoragePath: StoragePath
    
    pub let AdminPrivatePath: PrivatePath
    
    // -----------------------------------------------------------------------
    // Contract Fields
    // -----------------------------------------------------------------------
    priv var tradingScores:{ Address: UInt32}
    
    pub resource Admin{ 
        pub fun deductPoints(wallet: Address, pointsToDeduct: UInt32){ 
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
        
        pub fun createNewAdmin(): @Admin{ 
            return <-create Admin()
        }
    }
    
    access(account) fun increaseTradingScore(wallet: Address, points: UInt32){ 
        if FlowBlocksTradingScore.tradingScores[wallet] == nil{ 
            FlowBlocksTradingScore.tradingScores[wallet] = points
        } else{ 
            FlowBlocksTradingScore.tradingScores[wallet] = FlowBlocksTradingScore.tradingScores[wallet]! + points
        }
        emit TradingScoreIncreased(wallet: wallet, points: points)
    }
    
    pub fun getTradingScores():{ Address: UInt32}{ 
        return FlowBlocksTradingScore.tradingScores
    }
    
    pub fun getTradingScore(wallet: Address): UInt32?{ 
        return FlowBlocksTradingScore.tradingScores[wallet]
    }
    
    init(){ 
        self.AdminStoragePath = /storage/FlowBlocksTradingScoreAdmin_3
        self.AdminPrivatePath = /private/FlowBlocksTradingScoreAdmin_3
        self.tradingScores ={} 
        self.account.save(<-create Admin(), to: self.AdminStoragePath)
        self.account.link<&FlowBlocksTradingScore.Admin>(
            self.AdminPrivatePath,
            target: self.AdminStoragePath
        )
        ?? panic("Could not get a capability to the admin")
        emit ContractInitialized()
    }
}
