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

	import ShipOfTheseus from "./ShipOfTheseus.cdc"

access(all)
contract ShipOfTheseusWarehouse{ 
	access(all)
	event Withdraw(id: UInt64, uuid: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, uuid: UInt64, to: Address?)
	
	access(all)
	resource interface WarehousePublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(ship: @ShipOfTheseus.Ship): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUUIDs(): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship?
	}
	
	access(all)
	resource Warehouse: WarehousePublic{ 
		access(all)
		var ships: @{UInt64: ShipOfTheseus.Ship}
		
		init(){ 
			self.ships <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun withdraw(uuid: UInt64): @ShipOfTheseus.Ship{ 
			let ship <- self.ships.remove(key: uuid) ?? panic("Missing Ship")
			emit Withdraw(id: ship.id, uuid: ship.uuid, from: self.owner?.address)
			return <-ship
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(ship: @ShipOfTheseus.Ship){ 
			let id: UInt64 = ship.id
			let uuid: UInt64 = ship.uuid
			self.ships[uuid] <-! ship
			emit Deposit(id: id, uuid: uuid, to: self.owner?.address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUUIDs(): [UInt64]{ 
			return self.ships.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowShip(uuid: UInt64): &ShipOfTheseus.Ship?{ 
			return &self.ships[uuid] as &ShipOfTheseus.Ship?
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createWarehouse(): @Warehouse{ 
		return <-create Warehouse()
	}
	
	init(){ 
		self.account.storage.save(<-create Warehouse(), to: /storage/ShipOfTheseusWarehouse)
		var capability_1 =
			self.account.capabilities.storage.issue<&Warehouse>(/storage/ShipOfTheseusWarehouse)
		self.account.capabilities.publish(capability_1, at: /public/ShipOfTheseusWarehouse)
	}
}
