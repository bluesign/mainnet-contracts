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

	import IStats from "./IStats.cdc"

access(all)
contract NFT001{ 
	access(all)
	var statsContract: Address
	
	access(all)
	var statsContractName: String
	
	init(){ 
		self.statsContract = 0x9bcd6bb87052c775
		self.statsContractName = "Stats"
	}
	
	access(all)
	fun setStatsContract(address: Address, name: String){ 
		self.statsContract = address
		self.statsContractName = name
	}
	
	access(all)
	fun getMetadata():{ UInt64: String}?{ 
		// https://github.com/onflow/cadence/pull/1934
		let account = getAccount(self.statsContract)
		let borrowedContract: &{IStats} =
			account.contracts.borrow<&{IStats}>(name: self.statsContractName) ?? panic("Error")
		log(borrowedContract.stats[1])
		log(borrowedContract.stats[2])
		return borrowedContract.stats
	}
}
