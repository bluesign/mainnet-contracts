import RewardAlgorithm from ../0x35f9e7ac86111b22;/RewardAlgorithm.cdc

access(all) contract WonderPartnerRewardAlgorithm: RewardAlgorithm {

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    access(all) event ContractInitialized()

    // -----------------------------------------------------------------------
    // Paths
    // -----------------------------------------------------------------------
    access(all) let AlgorithmStoragePath: StoragePath
    access(all) let AlgorithmPublicPath: PublicPath
    
    access(all) resource Algorithm: RewardAlgorithm.Algorithm {
        access(all) fun randomAlgorithm(): Int {
            // Generate a random number between 0 and 100_000_000
            let randomNum = Int(unsafeRandom() % 100_000_000)
            
            let threshold1 = 55_000_000 // for 55%
            let threshold2 = 91_000_000 // for 36%, cumulative 91%
            let threshold3 = 99_000_000 // for 8%, cumulative 99%
            
            // Return reward based on generated random number
            if randomNum < threshold1 { return 1 }
            else if randomNum < threshold2 { return 2 }
            else if randomNum < threshold3 { return 3 }
            else { return 4 } // for remaining 1%
        }
    }

    access(all) fun createAlgorithm(): @Algorithm {
        return <- create WonderPartnerRewardAlgorithm.Algorithm()
    }

    access(all) fun borrowAlgorithm(): &Algorithm{RewardAlgorithm.Algorithm} {
        return self.account.getCapability<&WonderPartnerRewardAlgorithm.Algorithm{RewardAlgorithm.Algorithm}>(self.AlgorithmPublicPath).borrow()!
    }

    init() {
        self.AlgorithmStoragePath = /storage/WonderPartnerRewardAlgorithm
        self.AlgorithmPublicPath = /public/WonderPartnerRewardAlgorithm

        self.account.save(<-self.createAlgorithm(), to: self.AlgorithmStoragePath)

        self.account.unlink(self.AlgorithmPublicPath)

		self.account.link<&WonderPartnerRewardAlgorithm.Algorithm{RewardAlgorithm.Algorithm}>(self.AlgorithmPublicPath, target: self.AlgorithmStoragePath)

        emit ContractInitialized()
    }
}