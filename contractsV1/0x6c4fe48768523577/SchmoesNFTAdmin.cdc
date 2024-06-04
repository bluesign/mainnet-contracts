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

	import SchmoesNFT from "./SchmoesNFT.cdc"

access(all)
contract SchmoesNFTAdmin{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun setIsSaleActive(_ newIsSaleActive: Bool){ 
			SchmoesNFT.setIsSaleActive(newIsSaleActive)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setPrice(_ newPrice: UFix64){ 
			SchmoesNFT.setPrice(newPrice)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMaxMintAmount(_ newMaxMintAmount: UInt64){ 
			SchmoesNFT.setMaxMintAmount(newMaxMintAmount)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIpfsBaseCID(_ ipfsBaseCID: String){ 
			SchmoesNFT.setIpfsBaseCID(ipfsBaseCID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setProvenance(_ provenance: String){ 
			SchmoesNFT.setProvenance(provenance)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setProvenanceForEdition(_ edition: UInt64, _ provenance: String){ 
			SchmoesNFT.setProvenanceForEdition(edition, provenance)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setSchmoeAsset(
			_ assetType: SchmoesNFT.SchmoeTrait,
			_ assetName: String,
			_ content: String
		){ 
			SchmoesNFT.setSchmoeAsset(assetType, assetName, content)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchUpdateSchmoeData(_ schmoeDataMap:{ UInt64: SchmoesNFT.SchmoeData}){ 
			SchmoesNFT.batchUpdateSchmoeData(schmoeDataMap)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setEarlyLaunchTime(_ earlyLaunchTime: UFix64){ 
			SchmoesNFT.setEarlyLaunchTime(earlyLaunchTime)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setLaunchTime(_ launchTime: UFix64){ 
			SchmoesNFT.setLaunchTime(launchTime)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setIdsPerIncrement(_ idsPerIncrement: UInt64){ 
			SchmoesNFT.setIdsPerIncrement(idsPerIncrement)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setTimePerIncrement(_ timePerIncrement: UInt64){ 
			SchmoesNFT.setTimePerIncrement(timePerIncrement)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	init(){ 
		self.AdminStoragePath = /storage/schmoesNFTAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
