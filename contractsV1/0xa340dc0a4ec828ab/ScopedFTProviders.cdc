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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import StringUtils from "./../../standardsV1/StringUtils.cdc"

// ScopedFTProviders
//
// TO AVOID RISK, PLEASE DEPLOY YOUR OWN VERSION OF THIS CONTRACT SO THAT
// MALICIOUS UPDATES ARE NOT POSSIBLE
//
// ScopedProviders are meant to solve the issue of unbounded access FungibleToken vaults
// when a provider is called for.
access(all)
contract ScopedFTProviders{ 
	access(all)
	struct interface FTFilter{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdrawAmount(_ amount: UFix64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markAmountWithdrawn(_ amount: UFix64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails():{ String: AnyStruct}
	}
	
	access(all)
	struct AllowanceFilter: FTFilter{ 
		access(self)
		let allowance: UFix64
		
		access(self)
		var allowanceUsed: UFix64
		
		init(_ allowance: UFix64){ 
			self.allowance = allowance
			self.allowanceUsed = 0.0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdrawAmount(_ amount: UFix64): Bool{ 
			return amount + self.allowanceUsed <= self.allowance
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markAmountWithdrawn(_ amount: UFix64){ 
			self.allowanceUsed = self.allowanceUsed + amount
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails():{ String: AnyStruct}{ 
			return{ "allowance": self.allowance, "allowanceUsed": self.allowanceUsed}
		}
	}
	
	// ScopedFTProvider
	//
	// A ScopedFTProvider is a wrapped FungibleTokenProvider with
	// filters that can be defined by anyone using the ScopedFTProvider.
	access(all)
	resource ScopedFTProvider: FungibleToken.Vault, FungibleToken.Provider{ 
		access(self)
		let provider: Capability<&{FungibleToken.Provider}>
		
		access(self)
		var filters: [{FTFilter}]
		
		// block timestamp that this provider can no longer be used after
		access(self)
		let expiration: UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		init(provider: Capability<&{FungibleToken.Provider}>, filters: [{FTFilter}], expiration: UFix64?){ 
			self.provider = provider
			self.filters = filters
			self.expiration = expiration
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun check(): Bool{ 
			return self.provider.check()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		view fun isExpired(): Bool{ 
			if let expiration = self.expiration{ 
				return getCurrentBlock().timestamp >= expiration
			}
			return false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun canWithdraw(_ amount: UFix64): Bool{ 
			if self.isExpired(){ 
				return false
			}
			for filter in self.filters{ 
				if !filter.canWithdrawAmount(amount){ 
					return false
				}
			}
			return true
		}
		
		access(FungibleToken.Withdraw)
		fun withdraw(amount: UFix64): @{FungibleToken.Vault}{ 
			pre{ 
				!self.isExpired():
					"provider has expired"
			}
			var i = 0
			while i < self.filters.length{ 
				if !self.filters[i].canWithdrawAmount(amount){ 
					panic(StringUtils.join(["cannot withdraw tokens. filter of type", self.filters[i].getType().identifier, "failed."], " "))
				}
				self.filters[i].markAmountWithdrawn(amount)
				i = i + 1
			}
			return <-(self.provider.borrow()!).withdraw(amount: amount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDetails(): [{String: AnyStruct}]{ 
			let details: [{String: AnyStruct}] = []
			for filter in self.filters{ 
				details.append(filter.getDetails())
			}
			return details
		}
		
		access(all)
		fun deposit(from: @{FungibleToken.Vault}): Void{ 
			panic("implement me")
		}
		
		access(all)
		view fun isAvailableToWithdraw(amount: UFix64): Bool{ 
			return self.balance >= amount
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createScopedFTProvider(
		provider: Capability<&{FungibleToken.Provider}>,
		filters: [{
			FTFilter}
		],
		expiration: UFix64?
	): @ScopedFTProvider{ 
		return <-create ScopedFTProvider(
			provider: provider,
			filters: filters,
			expiration: expiration
		)
	}
}
