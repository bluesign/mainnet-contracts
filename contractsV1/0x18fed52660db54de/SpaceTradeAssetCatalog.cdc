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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NFTCatalog from "./../../standardsV1/NFTCatalog.cdc"

access(all)
contract SpaceTradeAssetCatalog{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	let ManagerStoragePath: StoragePath
	
	access(self)
	let nfts:{ String: NFTCollectionMetadata}
	
	access(self)
	let fts:{ String: FTVaultMetadata}
	
	access(all)
	struct NFTCollectionMetadata{ 
		// Must be unique for this collection, e.g. ufcInt_NFT
		access(all)
		let identifier: String
		
		// Name is the collection name which we can display to the user, e.g. UFCStrike (corresponds to ufcInt_NFT)
		access(all)
		let contractName: String
		
		access(all)
		let publicPath: PublicPath
		
		access(all)
		let privatePath: PrivatePath
		
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let nftType: Type
		
		access(all)
		let publicLinkedType: Type
		
		access(all)
		let privateLinkedType: Type
		
		access(all)
		var supported: Bool
		
		init(
			identifier: String,
			contractName: String,
			publicPath: PublicPath,
			storagePath: StoragePath,
			privatePath: PrivatePath,
			nftType: Type,
			publicLinkedType: Type,
			privateLinkedType: Type,
			supported: Bool
		){ 
			self.identifier = identifier
			self.contractName = contractName
			self.privatePath = privatePath
			self.publicPath = publicPath
			self.storagePath = storagePath
			self.nftType = nftType
			self.publicLinkedType = publicLinkedType
			self.privateLinkedType = privateLinkedType
			self.supported = supported
		}
		
		access(contract)
		fun setSupported(_ supported: Bool){ 
			self.supported = supported
		}
	}
	
	access(all)
	struct FTVaultMetadata{ 
		access(all)
		let identifier: String
		
		access(all)
		let contractName: String
		
		access(all)
		let publicReceiverPath: PublicPath
		
		access(all)
		let publicBalancePath: PublicPath
		
		access(all)
		let privatePath: PrivatePath
		
		access(all)
		let storagePath: StoragePath
		
		access(all)
		let vaultType: Type
		
		access(all)
		let publicLinkedReceiverType: Type
		
		access(all)
		let publicLinkedBalanceType: Type
		
		access(all)
		let privateLinkedType: Type
		
		access(all)
		var supported: Bool
		
		init(
			identifier: String,
			contractName: String,
			publicReceiverPath: PublicPath,
			publicBalancePath: PublicPath,
			storagePath: StoragePath,
			privatePath: PrivatePath,
			vaultType: Type,
			publicLinkedReceiverType: Type,
			publicLinkedBalanceType: Type,
			privateLinkedType: Type,
			supported: Bool
		){ 
			self.identifier = identifier
			self.contractName = contractName
			self.publicReceiverPath = publicReceiverPath
			self.publicBalancePath = publicBalancePath
			self.storagePath = storagePath
			self.privatePath = privatePath
			self.vaultType = vaultType
			self.publicLinkedReceiverType = publicLinkedReceiverType
			self.publicLinkedBalanceType = publicLinkedBalanceType
			self.privateLinkedType = privateLinkedType
			self.supported = supported
		}
		
		access(contract)
		fun setSupported(_ supported: Bool){ 
			self.supported = supported
		}
	}
	
	access(all)
	resource Manager{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun upsertNFT(_ nftCollection: NFTCollectionMetadata){ 
			SpaceTradeAssetCatalog.nfts.insert(key: nftCollection.identifier, nftCollection)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun upsertFT(_ ftVault: FTVaultMetadata){ 
			SpaceTradeAssetCatalog.fts.insert(key: ftVault.identifier, ftVault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleSupportedNFT(_ identifier: String, _ supported: Bool){ 
			pre{ 
				SpaceTradeAssetCatalog.nfts[identifier] != nil:
					"NFT Collection with given name does not exist"
			}
			let ref =
				&SpaceTradeAssetCatalog.nfts[identifier]!
				as
				&SpaceTradeAssetCatalog.NFTCollectionMetadata
			ref.setSupported(supported)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleSupportedFT(_ tokenKey: String, _ supported: Bool){ 
			pre{ 
				SpaceTradeAssetCatalog.fts[tokenKey] != nil:
					"Fungible token with given name does not exist"
			}
			let ref =
				&SpaceTradeAssetCatalog.fts[tokenKey]! as &SpaceTradeAssetCatalog.FTVaultMetadata
			ref.setSupported(supported)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFT(_ tokenKey: String){ 
			pre{ 
				SpaceTradeAssetCatalog.fts[tokenKey] != nil:
					"Fungible token with given name does not exist"
			}
			SpaceTradeAssetCatalog.fts.remove(key: tokenKey)
			?? panic("Unable to remove fungible token")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeNFT(_ collectionName: String){ 
			pre{ 
				SpaceTradeAssetCatalog.nfts[collectionName] != nil:
					"NFT collection with given name does not exist"
			}
			SpaceTradeAssetCatalog.nfts.remove(key: collectionName)
			?? panic("Unable to remove NFT collection")
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isSupportedNFT(_ identifier: String): Bool{ 
		if let collection = self.nfts[identifier]{ 
			return collection.supported
		} else{ 
			// Collection is supported by default if we have not defined it explicitly in this contract
			return self.getNFTCollectionMetadataFromOfficialCatalog(identifier) != nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isSupportedFT(_ tokenKey: String): Bool{ 
		if let token = self.fts[tokenKey]{ 
			return token.supported
		} else{ 
			return false
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberOfFTs(): Int{ 
		return self.fts.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTCollectionMetadatas(_ offset: Int, _ limit: Int):{ String: NFTCollectionMetadata}{ 
		let nfts:{ String: NFTCollectionMetadata} ={} 
		let officialNFTs = NFTCatalog.getCatalog().keys
		var counter = offset
		var offsetTo = offset + limit
		while counter < offsetTo{ 
			if counter < self.nfts.keys.length{ 
				let key = self.nfts.keys[counter]
				nfts.insert(key: key, self.nfts[key]!)
			} else if counter - self.nfts.keys.length < officialNFTs.length{ 
				let identifier = officialNFTs[counter - self.nfts.keys.length]
				// Must use collectionFromOfficialCatalog.key as key because storage iteration also uses the contract name as key
				if !nfts.containsKey(identifier){ 
					let collectionFromOfficialCatalog = self.getNFTCollectionMetadataFromOfficialCatalog(identifier)!
					nfts.insert(key: collectionFromOfficialCatalog.identifier, collectionFromOfficialCatalog)
				}
			} else{ 
				break
			}
			counter = counter + 1
		}
		return nfts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTMetadatas():{ String: FTVaultMetadata}{ 
		return self.fts
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTCollectionMetadata(_ identifier: String): NFTCollectionMetadata?{ 
		return self.nfts[identifier] ?? self.getNFTCollectionMetadataFromOfficialCatalog(identifier)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTMetadata(_ tokenKey: String): FTVaultMetadata?{ 
		return self.fts[tokenKey]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTCollectionMetadataFromOfficialCatalog(_ identifier: String): NFTCollectionMetadata?{ 
		if let collectionFromOfficialCatalog =
			NFTCatalog.getCatalogEntry(collectionIdentifier: identifier){ 
			return NFTCollectionMetadata(
				identifier: identifier,
				contractName: collectionFromOfficialCatalog.contractName,
				publicPath: collectionFromOfficialCatalog.collectionData.publicPath,
				storagePath: collectionFromOfficialCatalog.collectionData.storagePath,
				privatePath: collectionFromOfficialCatalog.collectionData.privatePath,
				nftType: collectionFromOfficialCatalog.nftType,
				publicLinkedType: collectionFromOfficialCatalog.collectionData.publicLinkedType,
				privateLinkedType: collectionFromOfficialCatalog.collectionData.privateLinkedType,
				supported: true
			)
		}
		return nil
	}
	
	init(){ 
		self.nfts ={} 
		self.fts ={ 
				"flowToken":
				SpaceTradeAssetCatalog.FTVaultMetadata(
					identifier: "flowToken",
					contractName: "FlowToken",
					publicReceiverPath: /public/flowTokenReceiver,
					publicBalancePath: /public/flowTokenBalance,
					storagePath: /storage/flowTokenVault,
					privatePath: /private/flowTokenVault,
					vaultType: Type<@FlowToken.Vault>(),
					publicLinkedReceiverType: Type<&FlowToken.Vault>(),
					publicLinkedBalanceType: Type<&FlowToken.Vault>(),
					privateLinkedType: Type<@FlowToken.Vault>(),
					supported: true
				)
			}
		self.ManagerStoragePath = /storage/SpaceTradeAssetCatalogStoragePath
		self.account.storage.save(<-create Manager(), to: self.ManagerStoragePath)
		emit ContractInitialized()
	}
}
