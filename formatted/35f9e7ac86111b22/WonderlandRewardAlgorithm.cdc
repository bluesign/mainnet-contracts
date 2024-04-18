import RewardAlgorithm from "../0x35f9e7ac86111b22;/RewardAlgorithm.cdc"

pub contract WonderlandRewardAlgorithm: RewardAlgorithm{ 
    
    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    pub event ContractInitialized()
    
    pub        
        // -----------------------------------------------------------------------
        // Paths
        // -----------------------------------------------------------------------
        let AlgorithmStoragePath: StoragePath
    
    pub let AlgorithmPublicPath: PublicPath
    
    pub resource Algorithm: RewardAlgorithm.Algorithm{ 
        pub fun randomAlgorithm(): Int{ 
            // Generate a random number between 0 and 100_000_000
            let randomNum = Int(unsafeRandom() % 100_000_000)
            let threshold1 = 69_000_000 // for 69%
            let threshold2 = 87_000_000 // for 18%, cumulative 87%
            let threshold3 = 95_000_000 // for 8%, cumulative 95%
            let threshold4 = 99_000_000 // for 4%, cumulative 99%
            
            // Return reward based on generated random number
            if randomNum < threshold1{ 
                return 1
            } else if randomNum < threshold2{ 
                return 2
            } else if randomNum < threshold3{ 
                return 3
            } else if randomNum < threshold4{ 
                return 4
            } else{ 
                return 5
            } // for remaining 1%
        }
    }
    
    pub fun createAlgorithm(): @Algorithm{ 
        return <-create WonderlandRewardAlgorithm.Algorithm()
    }
    
    pub fun borrowAlgorithm(): &Algorithm{RewardAlgorithm.Algorithm}{ 
        return self.account.getCapability<&WonderlandRewardAlgorithm.Algorithm{RewardAlgorithm.Algorithm}>(self.AlgorithmPublicPath).borrow()!
    }
    
    init(){ 
        self.AlgorithmStoragePath = /storage/WonderlandRewardAlgorithm_2
        self.AlgorithmPublicPath = /public/WonderlandRewardAlgorithm_2
        self.account.save(<-self.createAlgorithm(), to: self.AlgorithmStoragePath)
        self.account.unlink(self.AlgorithmPublicPath)
        self.account.link<&WonderlandRewardAlgorithm.Algorithm{RewardAlgorithm.Algorithm}>(self.AlgorithmPublicPath, target: self.AlgorithmStoragePath)
        emit ContractInitialized()
    }
}
