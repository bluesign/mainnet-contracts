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

	access(all)
contract TheMasterPieceContract{ 
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/TMPOwners
		self.CollectionPublicPath = /public/TMPOwners
		if self.account.storage.borrow<&TMPOwners>(from: self.CollectionStoragePath) == nil{ 
			self.account.storage.save(<-create TMPOwners(), to: self.CollectionStoragePath)
			var capability_1 = self.account.capabilities.storage.issue<&{TMPOwnersInterface}>(self.CollectionStoragePath)
			self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		}
	}
	
	access(account)
	fun setSaleSize(sectorId: UInt16, address: Address, size: UInt16){ 
		let theOwnersRef = self.account.storage.borrow<&TMPOwners>(from: /storage/TMPOwners)!
		theOwnersRef.setSaleSize(sectorId: sectorId, address: address, size: size)
	}
	
	access(account)
	fun setWalletSize(sectorId: UInt16, address: Address, size: UInt16){ 
		let theOwnersRef = self.account.storage.borrow<&TMPOwners>(from: /storage/TMPOwners)!
		theOwnersRef.setWalletSize(sectorId: sectorId, address: address, size: size)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAddress(): Address{ 
		return self.account.address
	}
	
	// ########################################################################################
	access(all)
	struct TMPOwner{ 
		access(all)
		var saleSize: UInt16
		
		access(all)
		var walletSize: UInt16
		
		init(){ 
			self.saleSize = 0
			self.walletSize = 0
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSaleSize(saleSize: UInt16){ 
			self.saleSize = saleSize
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setWalletSize(walletSize: UInt16){ 
			self.walletSize = walletSize
		}
	}
	
	access(all)
	resource TMPSectorOwners{ 
		access(self)
		var owners:{ Address: TMPOwner}
		
		init(){ 
			self.owners ={} 
		}
		
		access(self)
		fun addOwner(address: Address){ 
			var owner = self.owners[address]
			if owner == nil{ 
				owner = TMPOwner()
				self.owners[address] = owner
			}
		}
		
		access(self)
		fun removeOwner(address: Address){ 
			if self.owners.containsKey(address) && (self.owners[address]!).walletSize == 0
			&& (self.owners[address]!).saleSize == 0{ 
				self.owners.remove(key: address)
			}
		}
		
		access(contract)
		fun setWalletSize(address: Address, size: UInt16){ 
			self.addOwner(address: address)
			(self.owners[address]!).setWalletSize(walletSize: size)
			self.removeOwner(address: address)
		}
		
		access(contract)
		fun setSaleSize(address: Address, size: UInt16){ 
			(self.owners[address]!).setSaleSize(saleSize: size)
			self.removeOwner(address: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwners():{ Address: TMPOwner}{ 
			return self.owners
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwner(address: Address): TMPOwner?{ 
			return self.owners[address]
		}
	}
	
	// ########################################################################################
	access(all)
	resource interface TMPOwnersInterface{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwners(sectorId: UInt16):{ Address: TheMasterPieceContract.TMPOwner}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwner(sectorId: UInt16, address: Address): TMPOwner?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listSectors(): [UInt16]
	}
	
	access(all)
	resource TMPOwners: TMPOwnersInterface{ 
		access(self)
		var sectors: @{UInt16: TMPSectorOwners}
		
		init(){ 
			self.sectors <-{} 
		}
		
		access(account)
		fun setWalletSize(sectorId: UInt16, address: Address, size: UInt16){ 
			if self.sectors[sectorId] == nil{ 
				self.sectors[sectorId] <-! create TMPSectorOwners()
			}
			self.sectors[sectorId]?.setWalletSize(address: address, size: size)
		}
		
		access(account)
		fun setSaleSize(sectorId: UInt16, address: Address, size: UInt16){ 
			self.sectors[sectorId]?.setSaleSize(address: address, size: size)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwners(sectorId: UInt16):{ Address: TMPOwner}{ 
			if self.sectors[sectorId] == nil{ 
				return{} 
			} else{ 
				return self.sectors[sectorId]?.getOwners()!
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getOwner(sectorId: UInt16, address: Address): TMPOwner?{ 
			return self.sectors[sectorId]?.getOwner(address: address)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun listSectors(): [UInt16]{ 
			return self.sectors.keys
		}
	}
}
