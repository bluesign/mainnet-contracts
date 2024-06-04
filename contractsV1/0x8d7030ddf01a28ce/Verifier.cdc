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

	/*
============================================================
Name: NFT Verifier Contract for Mindtrix
============================================================
This contract is inspired from FLOATVerifiers that comes from
Emerald City, Jacob Tucker.
It abstracts the verification logic out of the main conteact.
Therefore, this contract is scalable with other forms of
conditions.
*/

// import Mindtrix from "../"./Mindtrix.cdc"/Mindtrix.cdc"

//dev
// import Mindtrix from "../0xf8d6e0586b0a20c7/Mindtrix.cdc"

// staging
// import Mindtrix from "../0x1ed02a22a3821c65/Mindtrix.cdc"

// pro
import Mindtrix from "./Mindtrix.cdc"

access(all)
contract Verifier{ 
	access(all)
	struct TimeLock: Mindtrix.IVerifier{ 
		access(all)
		let startTime: UFix64
		
		access(all)
		let endTime: UFix64
		
		// The _ (underscore) indicates that a parameter in a function has no argument label.
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let currentTime = getCurrentBlock().timestamp
			log("essence start time:".concat(self.startTime.toString()))
			log("essence end time:".concat(self.endTime.toString()))
			assert(currentTime >= self.startTime, message: "This Mindtrix NFT is yet to start.")
			assert(currentTime <= self.endTime, message: "Oops! The time has run out to mint this Mindtrix NFT.")
		}
		
		init(startTime: UFix64, duration: UFix64){ 
			self.startTime = startTime
			self.endTime = self.startTime + duration
		}
	}
	
	access(all)
	struct LimitedQuantity: Mindtrix.IVerifier{ 
		access(all)
		var capacity: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun verify(_ params:{ String: AnyStruct}){ 
			let totalSupply = Mindtrix.totalSupply
			assert(totalSupply < self.capacity, message: "Oops! Run out of the supply!")
		}
		
		init(capacity: UInt64){ 
			self.capacity = capacity
		}
	}
}
