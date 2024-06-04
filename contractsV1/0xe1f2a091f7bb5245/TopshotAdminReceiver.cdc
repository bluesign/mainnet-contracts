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

  AdminReceiver.cdc

  This contract defines a function that takes a TopShot admin
  object and stores it in the storage of the contract account
  so it can be used normally

 */

import TopShot from "../0x0b2a3299cc857e29/TopShot.cdc"

import TopShotShardedCollection from "../0xef4d8b44dd7f7ef6/TopShotShardedCollection.cdc"

access(all)
contract TopshotAdminReceiver{ 
	access(TMP_ENTITLEMENT_OWNER)
	fun storeAdmin(newAdmin: @TopShot.Admin){ 
		self.account.storage.save(<-newAdmin, to: /storage/TopShotAdmin)
	}
	
	init(){ 
		if self.account.storage.borrow<&TopShotShardedCollection.ShardedCollection>(
			from: /storage/ShardedMomentCollection
		)
		== nil{ 
			let collection <- TopShotShardedCollection.createEmptyCollection(numBuckets: 32)
			// Put a new Collection in storage
			self.account.storage.save(<-collection, to: /storage/ShardedMomentCollection)
			var capability_1 =
				self.account.capabilities.storage.issue<&{TopShot.MomentCollectionPublic}>(
					/storage/ShardedMomentCollection
				)
			self.account.capabilities.publish(capability_1, at: /public/MomentCollection)
		}
	}
}
