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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(TMP_ENTITLEMENT_OWNER)
contract interface ICryptoys{ 
	access(TMP_ENTITLEMENT_OWNER)
	struct interface Royalty{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let fee: UFix64
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	struct interface Display{ 
		access(all)
		let image: String
		
		access(all)
		let video: String
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface INFT{ 
		access(all)
		let id: UInt64
		
		access(account)
		let metadata:{ String: String}
		
		access(account)
		let royalties: [String]
		
		access(account)
		let bucket: @{String:{ UInt64:{ INFT}}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDisplay():{ ICryptoys.Display}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): [{ICryptoys.Royalty}]
		
		access(account)
		fun withdrawBucketItem(_ key: String, _ itemUuid: UInt64): @{ICryptoys.INFT}{ 
			pre{ 
				self.owner != nil:
					"withdrawBucketItem() failed: nft resource must be in a collection"
			}
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot withdraw bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addToBucket(_ key: String, _ nft: @{INFT}){ 
			pre{ 
				self.owner != nil:
					"addToBucket() failed: nft resource must be in a collection"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBucketKeys(): [String]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getBucketResourceIdsByKey(_ key: String): [UInt64]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBucketResourcesByKey(_ key: String): &{UInt64:{ ICryptoys.INFT}}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBucket(): &{String:{ UInt64:{ ICryptoys.INFT}}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBucketItem(_ key: String, _ itemUuid: UInt64): &{INFT}{ 
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot borrow bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun resolveView(_ view: Type): AnyStruct?
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface CryptoysCollectionPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowCryptoy(id: UInt64): &{INFT}{ 
			// If the result isn't nil, the id of the returned reference
			// should be the same as the argument to the function
			post{ 
				result == nil || result.id == id:
					"Cannot borrow Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBucketItem(_ id: UInt64, _ key: String, _ itemUuid: UInt64): &{ICryptoys.INFT}{ 
			post{ 
				result == nil || result.uuid == itemUuid:
					"Cannot borrow bucket Cryptoy reference: The ID of the returned reference is incorrect"
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Collection{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun withdrawBucketItem(parentId: UInt64, key: String, itemUuid: UInt64): @{ICryptoys.INFT}
	}
}
