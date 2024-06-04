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

	//SPDX-License-Identifier: MIT
import Digiyo from "./Digiyo.cdc"

import DigiyoSplitCollection from "./DigiyoSplitCollection.cdc"

access(all)
contract DigiyoAdminReceiver{ 
	access(all)
	let splitCollectionPath: StoragePath
	
	access(TMP_ENTITLEMENT_OWNER)
	fun storeAdmin(newAdmin: @Digiyo.Admin){ 
		self.account.storage.save(<-newAdmin, to: Digiyo.digiyoAdminPath)
	}
	
	init(){ 
		self.splitCollectionPath = /storage/SplitDigiyoNFTCollection
		if self.account.storage.borrow<&DigiyoSplitCollection.SplitCollection>(
			from: self.splitCollectionPath
		)
		== nil{ 
			let collection <- DigiyoSplitCollection.createEmptyCollection(numBuckets: 32)
			self.account.storage.save(<-collection, to: self.splitCollectionPath)
			var capability_1 =
				self.account.capabilities.storage.issue<&{Digiyo.DigiyoNFTCollectionPublic}>(
					self.splitCollectionPath
				)
			self.account.capabilities.publish(capability_1, at: Digiyo.collectionPublicPath)
		}
	}
}
