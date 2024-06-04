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

	import GomokuType from "./GomokuType.cdc"

access(all)
contract GomokuIdentity{ 
	
	// Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	// Events
	access(all)
	event Create(id: UInt32, address: Address, role: UInt8)
	
	access(all)
	event CollectionCreated()
	
	access(all)
	event Withdraw(id: UInt32, from: Address?)
	
	access(all)
	event Deposit(id: UInt32, to: Address?)
	
	init(){ 
		self.CollectionStoragePath = /storage/gomokuIdentityCollection
		self.CollectionPublicPath = /public/gomokuIdentityCollection
	}
	
	access(all)
	resource IdentityToken{ 
		access(all)
		let id: UInt32
		
		access(all)
		let address: Address
		
		access(all)
		let role: GomokuType.Role
		
		access(all)
		var stoneColor: GomokuType.StoneColor
		
		access(self)
		var destroyable: Bool
		
		init(
			id: UInt32,
			address: Address,
			role: GomokuType.Role,
			stoneColor: GomokuType.StoneColor
		){ 
			self.id = id
			self.address = address
			self.role = role
			self.stoneColor = stoneColor
			self.destroyable = false
		}
		
		access(account)
		fun switchIdentity(){ 
			switch self.stoneColor{ 
				case GomokuType.StoneColor.black:
					self.stoneColor = GomokuType.StoneColor.white
				case GomokuType.StoneColor.white:
					self.stoneColor = GomokuType.StoneColor.black
			}
		}
		
		access(account)
		fun setDestroyable(_ value: Bool){ 
			self.destroyable = value
		}
	}
	
	access(account)
	fun createIdentity(
		id: UInt32,
		address: Address,
		role: GomokuType.Role,
		stoneColor: GomokuType.StoneColor
	): @IdentityToken{ 
		emit Create(id: id, address: address, role: role.rawValue)
		return <-create IdentityToken(id: id, address: address, role: role, stoneColor: stoneColor)
	}
	
	access(all)
	resource IdentityCollection{ 
		access(all)
		let StoragePath: StoragePath
		
		access(all)
		let PublicPath: PublicPath
		
		access(self)
		var ownedIdentityTokenMap: @{UInt32: IdentityToken}
		
		access(self)
		var destroyable: Bool
		
		init(){ 
			self.ownedIdentityTokenMap <-{} 
			self.destroyable = false
			self.StoragePath = /storage/compositionIdentity
			self.PublicPath = /public/compositionIdentity
		}
		
		access(account)
		fun withdraw(by id: UInt32): @IdentityToken?{ 
			if let token <- self.ownedIdentityTokenMap.remove(key: id){ 
				emit Withdraw(id: token.id, from: self.owner?.address)
				if self.ownedIdentityTokenMap.keys.length == 0{ 
					self.destroyable = true
				}
				return <-token
			} else{ 
				return nil
			}
		}
		
		access(account)
		fun deposit(token: @IdentityToken){ 
			let token <- token
			let id: UInt32 = token.id
			let oldToken <- self.ownedIdentityTokenMap[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			self.destroyable = false
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIds(): [UInt32]{ 
			return self.ownedIdentityTokenMap.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBalance(): Int{ 
			return self.ownedIdentityTokenMap.keys.length
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrow(id: UInt32): &IdentityToken?{ 
			return &self.ownedIdentityTokenMap[id] as &IdentityToken?
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyVault(): @IdentityCollection{ 
		emit CollectionCreated()
		return <-create IdentityCollection()
	}
}
