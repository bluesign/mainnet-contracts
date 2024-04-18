import IStats from "./IStats.cdc"

pub contract NFT{ 
    pub var statsContract: Address
    
    init(){ 
        self.statsContract = 0x9bcd6bb87052c775
    }
    
    pub fun setStatsContract(address: Address){ 
        self.statsContract = address
    }
    
    pub fun getMetadata():{ UInt64: String}?{ 
        // https://github.com/onflow/cadence/pull/1934
        let account = getAccount(self.statsContract)
        let borrowedContract: &IStats =
            account.contracts.borrow<&IStats>(name: "Stats") ?? panic("Error")
        log(borrowedContract.stats[1])
        log(borrowedContract.stats[2])
        return borrowedContract.stats
    }
}
