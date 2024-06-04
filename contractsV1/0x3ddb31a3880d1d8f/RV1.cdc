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

	/**

# 

*/

import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

access(all)
contract RV1{ 
	
	// {Referrer : {Referee: BindingTime} }
	access(self)
	let _referrerToReferees:{ Address:{ Address: UFix64}}
	
	// {Referee: Referrer}
	access(self)
	let _refereeToReferrer:{ Address: Address}
	
	/// Events
	access(all)
	event BindingReferrer(referrer: Address, referee: Address, indexer: Int)
	
	access(all)
	fun bind(
		referrer: Address,
		refereeCertificateCap: Capability<&{LendingInterfaces.IdentityCertificate}>
	){ 
		let referee: Address = ((refereeCertificateCap.borrow()!).owner!).address
		assert(
			self._refereeToReferrer.containsKey(referee) == false,
			message: "Referrer already bound"
		)
		self._refereeToReferrer[referee] = referrer
		if self._referrerToReferees.containsKey(referrer) == false{ 
			self._referrerToReferees[referrer] ={} 
		}
		(self._referrerToReferees[referrer]!).insert(key: referee, getCurrentBlock().timestamp)
		
		// Prevent circular binding
		assert(self.checkCirularBinding(referee: referee) == false, message: "Cirular Binding")
		emit BindingReferrer(
			referrer: referrer,
			referee: referee,
			indexer: (self._referrerToReferees[referrer]!).length
		)
	}
	
	access(self)
	fun checkCirularBinding(referee: Address): Bool{ 
		let checkedAddrs:{ Address: Bool} ={ referee: true}
		var i = 0
		var addr = referee
		while i < 32{ 
			if self._refereeToReferrer.containsKey(addr) == false{ 
				return false
			}
			let nextAddr = self._refereeToReferrer[addr]!
			if checkedAddrs.containsKey(nextAddr) == true{ 
				return true
			}
			checkedAddrs[nextAddr] = true
			addr = nextAddr
			i = i + 1
		}
		return false
	}
	
	access(all)
	fun getReferrerByReferee(referee: Address): Address?{ 
		if self._refereeToReferrer.containsKey(referee) == false{ 
			return nil
		}
		return self._refereeToReferrer[referee]!
	}
	
	access(all)
	view fun getReferrerCount(): Int{ 
		return self._referrerToReferees.length
	}
	
	access(all)
	view fun getSlicedReferrerList(from: Int, to: Int): [Address]{ 
		let len = self._referrerToReferees.length
		let upTo = to > len ? len : to
		return self._referrerToReferees.keys.slice(from: from, upTo: upTo)
	}
	
	access(all)
	view fun getRefereeCountByReferrer(referrer: Address): Int{ 
		return (self._referrerToReferees[referrer]!).length
	}
	
	access(all)
	view fun getSlicedRefereesByReferrer(referrer: Address, from: Int, to: Int):{ Address: UFix64}{ 
		if self._referrerToReferees.containsKey(referrer) == false{ 
			return{} 
		}
		let len = (self._referrerToReferees[referrer]!).length
		let endIndex = to > len ? len : to
		var curIndex = from
		let res:{ Address: UFix64} ={} 
		while curIndex < endIndex{ 
			let key: Address = (self._referrerToReferees[referrer]!).keys[curIndex]
			res[key] = (self._referrerToReferees[referrer]!)[key]
			curIndex = curIndex + 1
		}
		return res
	}
	
	/// Admin
	///
	access(all)
	resource Admin{} 
	
	init(){ 
		self._referrerToReferees ={} 
		self._refereeToReferrer ={} 
	}
}
