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

	import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract RoyaltiesLedger{ 
	access(all)
	let StoragePath: StoragePath
	
	access(all)
	resource Ledger{ 
		access(account)
		let royalties:{ UInt64: MetadataViews.Royalties}
		
		access(contract)
		fun set(_ id: UInt64, _ r: MetadataViews.Royalties?){ 
			if r == nil{ 
				return
			}
			self.royalties[id] = r
		}
		
		access(contract)
		fun get(_ id: UInt64): MetadataViews.Royalties?{ 
			return self.royalties[id]
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun remove(_ id: UInt64){ 
			self.royalties.remove(key: id)
		}
		
		init(){ 
			self.royalties ={} 
		}
	}
	
	access(account)
	fun set(_ id: UInt64, _ r: MetadataViews.Royalties){ 
		(self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).set(id, r)
	}
	
	access(account)
	fun remove(_ id: UInt64){ 
		(self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).remove(id)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun get(_ id: UInt64): MetadataViews.Royalties?{ 
		return (self.account.storage.borrow<&Ledger>(from: RoyaltiesLedger.StoragePath)!).get(id)
	}
	
	init(){ 
		self.StoragePath = /storage/RoyaltiesLedger
		self.account.storage.save(<-create Ledger(), to: self.StoragePath)
	}
}
