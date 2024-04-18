pub contract interface RewardAlgorithm{ 
    pub event ContractInitialized()
    
    pub resource interface Algorithm{ 
        pub fun randomAlgorithm(): Int{} 
    }
}
