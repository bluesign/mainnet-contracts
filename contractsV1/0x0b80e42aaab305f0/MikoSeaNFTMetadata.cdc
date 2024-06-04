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

	
// this contract used to storage required NFT metadata
access(all)
contract MikoSeaNFTMetadata{ 
	// map nftType, NFT ID and required metadata
	// {nftType: {nftID: metadata}}
	access(self)
	var NFTMetadata:{ String:{ UInt64:{ String: String}}}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun patchMetadata(nftType: String, nftID: UInt64, metadata:{ String: String}){ 
			if !MikoSeaNFTMetadata.NFTMetadata.containsKey(nftType){ 
				MikoSeaNFTMetadata.NFTMetadata[nftType] ={} 
			}
			if !(MikoSeaNFTMetadata.NFTMetadata[nftType]!).containsKey(nftID){ 
				(MikoSeaNFTMetadata.NFTMetadata[nftType]!).insert(key: nftID, metadata)
				return
			}
			metadata.forEachKey(fun (key: String): Bool{ 
					((MikoSeaNFTMetadata.NFTMetadata[nftType]!)[nftID]!).insert(key: key, metadata[key] ?? "")
					return true
				})
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMetadataByKeys(nftType: String, nftID: UInt64, metadataKeys: [String]){ 
			if let nftTypeMetadata = MikoSeaNFTMetadata.NFTMetadata[nftType]{ 
				if let nftMetadata = nftTypeMetadata[nftID]{ 
					nftMetadata.forEachKey(fun (key: String): Bool{ 
							if metadataKeys.contains(key){ 
								nftMetadata.remove(key: key)
							}
							return true
						})
					nftTypeMetadata.insert(key: nftID, nftMetadata)
					MikoSeaNFTMetadata.NFTMetadata.insert(key: nftType, nftTypeMetadata)
				}
			}
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTMetadata(nftType: String, nftID: UInt64):{ String: String}?{ 
		return (self.NFTMetadata[nftType] ??{} )[nftID]
	}
	
	init(){ 
		self.AdminStoragePath = /storage/MikoSeaNFTMetadataAdminStoragePath
		self.NFTMetadata ={} 
		
		// Put the Admin in storage
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
