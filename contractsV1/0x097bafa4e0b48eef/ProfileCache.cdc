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

	import Clock from "./Clock.cdc"

access(all)
contract ProfileCache{ 
	
	// If there is no findName, the string is set to "". 
	access(contract)
	let addressLeaseName:{ Address: LeaseCache}
	
	access(contract)
	let nameAddress:{ String: LeaseCache}
	
	access(contract)
	let profileWalletIndex:{ Address:{ Type: Int}}
	
	// Find Leases
	access(all)
	struct LeaseCache{ 
		access(all)
		let address: Address?
		
		access(all)
		let leaseName: String
		
		access(all)
		let validUntil: UFix64
		
		init(leaseName: String, validUntil: UFix64, address: Address?){ 
			self.leaseName = leaseName
			self.validUntil = validUntil
			self.address = address
		}
	}
	
	access(account)
	fun setAddressLeaseNameCache(address: Address, leaseName: String?, validUntil: UFix64){ 
		if self.addressLeaseName[address] == nil{ 
			if leaseName == nil{ 
				self.addressLeaseName[address] = LeaseCache(leaseName: "", validUntil: validUntil, address: address)
				return
			}
			self.addressLeaseName[address] = LeaseCache(leaseName: leaseName!, validUntil: validUntil, address: address)
			return
		}
	// panic("There is already a cache for this address. Address : ".concat(address.toString()))
	// We cannot panic here, because imagine someone has expired lease. 
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAddressLeaseName(_ address: Address): String?{ 
		if self.addressLeaseName[address] == nil{ 
			return nil
		}
		if (self.addressLeaseName[address]!).validUntil >= Clock.time(){ 
			return (self.addressLeaseName[address]!).leaseName
		}
		return nil
	}
	
	access(account)
	fun setNameAddressCache(address: Address?, leaseName: String, validUntil: UFix64){ 
		if self.nameAddress[leaseName] == nil{ 
			self.nameAddress[leaseName] = LeaseCache(leaseName: leaseName, validUntil: validUntil, address: address)
			return
		}
		panic("There is already a cache for this name. Name : ".concat(leaseName))
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNameAddress(_ name: String): LeaseCache?{ 
		if (self.nameAddress[name]!).validUntil >= Clock.time(){ 
			return self.nameAddress[name]
		}
		return nil
	}
	
	access(account)
	fun resetLeaseCache(address: Address, leaseName: String){ 
		self.addressLeaseName.remove(key: address)
		self.nameAddress.remove(key: leaseName)
	}
	
	access(account)
	fun setWalletIndexCache(address: Address, walletType: Type, index: Int){ 
		if self.profileWalletIndex[address] == nil{ 
			self.profileWalletIndex[address] ={} 
			(self.profileWalletIndex[address]!).insert(key: walletType, index)
			return
		} else if (self.profileWalletIndex[address]!)[walletType] == nil{ 
			(self.profileWalletIndex[address]!).insert(key: walletType, index)
			return
		}
		panic(
			"There is already a cache for this wallet. User : ".concat(address.toString()).concat(
				". Wallet : "
			).concat(walletType.identifier)
		)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getWalletIndex(address: Address, walletType: Type): Int?{ 
		if self.profileWalletIndex[address] == nil{ 
			return nil
		}
		return (self.profileWalletIndex[address]!)[walletType]
	}
	
	access(account)
	fun resetWalletIndexCache(address: Address){ 
		self.profileWalletIndex.remove(key: address)
	}
	
	init(){ 
		self.addressLeaseName ={} 
		self.nameAddress ={} 
		self.profileWalletIndex ={} 
	}
}
