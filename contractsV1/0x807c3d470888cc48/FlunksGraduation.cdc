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

	// SPDX-License-Identifier: MIT
import Flunks from "./Flunks.cdc"

access(all)
contract FlunksGraduation{ 
	access(all)
	event ContractInitialized()
	
	access(all)
	event Graduate(address: Address, tokenID: UInt64, templateID: UInt64)
	
	access(all)
	event GraduateTimeUpdate(tokenID: UInt64, time: UInt64)
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(self)
	var GraduatedFlunks:{ UInt64: Bool}
	
	access(self)
	var GraduationTime:{ UInt64: UInt64}
	
	access(self)
	var tokenIDToUri:{ UInt64: String}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun graduateFlunk(owner: AuthAccount, tokenID: UInt64){ 
		pre{ 
			!FlunksGraduation.GraduatedFlunks.containsKey(tokenID):
				"Flunk has already graduated"
			FlunksGraduation.GraduationTime[tokenID] ?? 1682049600 <= UInt64(getCurrentBlock().timestamp):
				"Not time yet"
		}
		
		// Check if owner is the true owner of the NFT
		let collection =
			getAccount(owner.address).capabilities.get<&Flunks.Collection>(
				Flunks.CollectionPublicPath
			).borrow()!
		let ownerCollectionTokenIds = collection.getIDs()
		if !ownerCollectionTokenIds.contains(tokenID){ 
			panic("Not owner")
		}
		let item = collection.borrowFlunks(id: tokenID)
		let templateID = (item!).templateID
		let itemTemplate = (item!).getNFTTemplate()
		
		// Update the NFT metadata and traits on-chain
		let admin =
			self.account.storage.borrow<&Flunks.Admin>(from: Flunks.AdminStoragePath)
			?? panic("Could not borrow a reference to the Flunks Admin")
		let adminSet = admin.borrowSet(setID: itemTemplate.addedToSet)
		let newMetadata = (item!).getNFTMetadata()
		newMetadata["Type"] = "Graduated"
		newMetadata["pixelUri"] = newMetadata["uri"]
		newMetadata["uri"] = FlunksGraduation.tokenIDToUri[tokenID]!
		adminSet.updateTemplateMetadata(templateID: templateID, newMetadata: newMetadata)
		// Graduate Flunks
		FlunksGraduation.GraduatedFlunks[tokenID] = true
		FlunksGraduation.GraduationTime.remove(key: tokenID)
		emit Graduate(address: owner.address, tokenID: tokenID, templateID: templateID)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun isFlunkGraduated(tokenID: UInt64): Bool{ 
		return FlunksGraduation.GraduatedFlunks[tokenID] ?? false
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getFlunksGraduationTimeTable():{ UInt64: UInt64}{ 
		return FlunksGraduation.GraduationTime
	}
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateGraduationTime(tokenID: UInt64, _timeInSeconds: UInt64){ 
			pre{ 
				!FlunksGraduation.GraduatedFlunks.containsKey(tokenID):
					"Flunk has already graduated"
			}
			FlunksGraduation.GraduationTime[tokenID] = _timeInSeconds
		
		// emit GraduateTimeUpdate(tokenID: tokenID, time: _timeInSeconds)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setGraduatedUri(tokenID: UInt64, uri: String){ 
			if FlunksGraduation.GraduatedFlunks.containsKey(tokenID){ 
				return
			}
			FlunksGraduation.tokenIDToUri[tokenID] = uri
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun alfredGraduatesForYa(ownerAddress: Address, templateID: UInt64, tokenID: UInt64){ 
			pre{ 
				!FlunksGraduation.GraduatedFlunks.containsKey(tokenID):
					"Flunk has already graduated"
			}
			
			// Update the NFT metadata and traits on-chain
			let admin =
				FlunksGraduation.account.storage.borrow<&Flunks.Admin>(
					from: Flunks.AdminStoragePath
				)
				?? panic("Could not borrow a reference to the Flunks Admin")
			let template = Flunks.getFlunksTemplateByID(templateID: templateID)
			let adminSet = admin.borrowSet(setID: template.addedToSet)
			let newMetadata = template.getMetadata()
			newMetadata["Type"] = "Graduated"
			newMetadata["pixelUri"] = newMetadata["uri"]
			newMetadata["uri"] = FlunksGraduation.tokenIDToUri[tokenID]!
			adminSet.updateTemplateMetadata(templateID: templateID, newMetadata: newMetadata)
			// Graduate Flunks
			FlunksGraduation.GraduatedFlunks[tokenID] = true
			FlunksGraduation.GraduationTime.remove(key: tokenID)
			emit Graduate(address: ownerAddress, tokenID: tokenID, templateID: templateID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun refreshGraduatedMetadata(ownerAddress: Address, templateID: UInt64, tokenID: UInt64){ 
			emit Graduate(address: ownerAddress, tokenID: tokenID, templateID: templateID)
		}
	}
	
	init(){ 
		self.AdminStoragePath = /storage/FlunksGraduationAdmin
		let admin <- create Admin()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.GraduatedFlunks ={} 
		self.GraduationTime ={} 
		self.tokenIDToUri ={} 
		emit ContractInitialized()
	}
}
