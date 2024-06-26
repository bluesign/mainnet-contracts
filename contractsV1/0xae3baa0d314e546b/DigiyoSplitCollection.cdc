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
import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import Digiyo from "./Digiyo.cdc"

access(all)
contract DigiyoSplitCollection{ 
	
	// SplitCollection stores a dictionary of Digiyo Collections
	// An instance is stored in the field corresponding to its id % numBuckets
	access(all)
	resource SplitCollection:
		Digiyo.DigiyoNFTCollectionPublic,
		NonFungibleToken.Provider,
		NonFungibleToken.Receiver,
		NonFungibleToken.Collection,
		NonFungibleToken.CollectionPublic{
	
		access(all)
		var collections: @{UInt64: Digiyo.Collection}
		
		access(all)
		let numBuckets: UInt64
		
		init(numBuckets: UInt64){ 
			self.collections <-{} 
			self.numBuckets = numBuckets
			var i: UInt64 = 0
			while i < numBuckets{ 
				self.collections[i] <-! Digiyo.createEmptyCollection(nftType: Type<@Digiyo.Collection>()) as! @Digiyo.Collection
				i = i + UInt64(1)
			}
		}
		
		// withdraw removes an instance from a collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			post{ 
				result.id == withdrawID:
					"The ID of the withdrawn NFT is incorrect"
			}
			let bucket = withdrawID % self.numBuckets
			let token <- self.collections[bucket]?.withdraw(withdrawID: withdrawID)!
			return <-token
		}
		
		// batchWithdraw withdraws multiple tokens and returns them as a Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- Digiyo.createEmptyCollection(nftType: Type<@Digiyo.Collection>())
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// deposit takes a instance and adds it to the collections dictionary
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let bucket = token.id % self.numBuckets
			let collection <- self.collections.remove(key: bucket)!
			collection.deposit(token: <-token)
			self.collections[bucket] <-! collection
		}
		
		// batchDeposit deposits all instances into the passed collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchDeposit(tokens: @{NonFungibleToken.Collection}){ 
			let keys = tokens.getIDs()
			for key in keys{ 
				self.deposit(token: <-tokens.withdraw(withdrawID: key))
			}
			destroy tokens
		}
		
		// getIDs returns an array of IDs corresponding to instances in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			var ids: [UInt64] = []
			for key in self.collections.keys{ 
				for id in self.collections[key]?.getIDs() ?? []{ 
					ids.append(id)
				}
			}
			return ids
		}
		
		// borrowNFT Returns a reference to a Instance in the collection
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			post{ 
				result.id == id:
					"The ID of the reference is incorrect"
			}
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowNFT(id)!!
		}
		
		// borrowInstance Returns a reference to an Instance in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowInstance(id: UInt64): &Digiyo.NFT?{ 
			let bucket = id % self.numBuckets
			return self.collections[bucket]?.borrowInstance(id: id) ?? nil
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createEmptyCollection(numBuckets: UInt64): @SplitCollection{ 
		return <-create SplitCollection(numBuckets: numBuckets)
	}
}
