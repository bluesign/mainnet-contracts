import IStats from "./IStats.cdc"

pub contract NFT001{ 
    pub var statsContract: Address
    
    pub var statsContractName: String
    
    init(){ 
        self.statsContract = 0x9bcd6bb87052c775
        self.statsContractName = "Stats"
    }
    
    pub fun setStatsContract(address: Address, name: String){ 
        self.statsContract = address
        self.statsContractName = name
    }
    
    pub fun getMetadata():{ UInt64: String}?{ 
        // https://github.com/onflow/cadence/pull/1934
        let account = getAccount(self.statsContract)
        let borrowedContract: &IStats =
            account.contracts.borrow<&IStats>(name: self.statsContractName)
            ?? panic("Error")
        log(borrowedContract.stats[1])
        log(borrowedContract.stats[2])
        return borrowedContract.stats
    }
}
