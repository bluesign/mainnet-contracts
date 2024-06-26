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
		access(all)
		let name: String
		
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
			name: String,
			publicPath: PublicPath,
			storagePath: StoragePath,
			privatePath: PrivatePath,
			nftType: Type,
			publicLinkedType: Type,
			privateLinkedType: Type,
			supported: Bool
		){ 
			self.name = name
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
		let name: String
		
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
			name: String,
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
			self.name = name
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
			SpaceTradeAssetCatalog.nfts.insert(key: nftCollection.name, nftCollection)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun upsertFT(_ ftVault: FTVaultMetadata){ 
			SpaceTradeAssetCatalog.fts.insert(key: ftVault.name, ftVault)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleSupportedNFT(_ collectionName: String, _ supported: Bool){ 
			pre{ 
				SpaceTradeAssetCatalog.nfts[collectionName] != nil:
					"NFT Collection with given name does not exist"
			}
			let ref =
				&SpaceTradeAssetCatalog.nfts[collectionName]!
				as
				&SpaceTradeAssetCatalog.NFTCollectionMetadata
			ref.setSupported(supported)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun toggleSupportedFT(_ tokenName: String, _ supported: Bool){ 
			pre{ 
				SpaceTradeAssetCatalog.fts[tokenName] != nil:
					"Fungible token with given name does not exist"
			}
			let ref =
				&SpaceTradeAssetCatalog.fts[tokenName]! as &SpaceTradeAssetCatalog.FTVaultMetadata
			ref.setSupported(supported)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFT(_ tokenName: String){ 
			pre{ 
				SpaceTradeAssetCatalog.fts[tokenName] != nil:
					"Fungible token with given name does not exist"
			}
			SpaceTradeAssetCatalog.fts.remove(key: tokenName)
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
	fun isSupportedNFT(_ collectionName: String): Bool{ 
		if let collection = self.nfts[collectionName]{ 
			return collection.supported
		} else{ 
			// Collection is supported by default if we have not defined it explicitly in this contract
			return self.getNFTCollectionMetadataFromOfficialCatalog(collectionName) != nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isSupportedFT(_ tokenName: String): Bool{ 
		if let token = self.fts[tokenName]{ 
			return token.supported
		} else{ 
			return false
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberOfNFTCollections(): Int{ 
		let ourNFTs = self.nfts.keys
		let officialNFTs = NFTCatalog.getCatalog().keys
		return ourNFTs.length + officialNFTs.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNumberOfFTs(): Int{ 
		return self.fts.length
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTCollectionMetadatas(_ offset: Int, _ limit: Int):{ String: NFTCollectionMetadata}{ 
		let nfts:{ String: NFTCollectionMetadata} ={} 
		let ourNFTs = self.nfts
		let officialNFTs = NFTCatalog.getCatalog().keys
		var counter = offset
		var offsetTo = offset + limit
		while counter < offsetTo{ 
			if counter < ourNFTs.keys.length{ 
				let key = ourNFTs.keys[counter]
				nfts.insert(key: key, ourNFTs[key]!)
			} else if counter - ourNFTs.keys.length < officialNFTs.length{ 
				let key = officialNFTs[counter - ourNFTs.keys.length]
				if nfts[key] == nil{ 
					nfts.insert(key: key, self.getNFTCollectionMetadataFromOfficialCatalog(key)!)
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
	fun getNFTCollectionMetadata(_ collectionName: String): NFTCollectionMetadata?{ 
		return self.nfts[collectionName]
		?? self.getNFTCollectionMetadataFromOfficialCatalog(collectionName)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFTMetadata(_ tokenName: String): FTVaultMetadata?{ 
		return self.fts[tokenName]
	}
	
	access(self)
	fun getNFTCollectionMetadataFromOfficialCatalog(
		_ collectionName: String
	): NFTCollectionMetadata?{ 
		if let collectionFromOfficialCatalog =
			NFTCatalog.getCatalogEntry(collectionIdentifier: collectionName){ 
			return NFTCollectionMetadata(
				name: collectionFromOfficialCatalog.contractName,
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
				"FlowToken":
				SpaceTradeAssetCatalog.FTVaultMetadata(
					name: "FlowToken",
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
