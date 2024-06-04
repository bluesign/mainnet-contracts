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

import S1GarmentNFT from "./S1GarmentNFT.cdc"

import S1MaterialNFT from "./S1MaterialNFT.cdc"

import S1ItemNFT from "./S1ItemNFT.cdc"

access(all)
contract S1MintTransferClaim{ 
	access(all)
	event ItemMintedAndTransferred(
		garmentDataID: UInt32,
		materialDataID: UInt32,
		primaryColor: String,
		secondaryColor: String,
		itemID: UInt64
	)
	
	// dictionary of addresses and how many items they have minted
	access(self)
	var addressMintCount:{ Address: UInt32}
	
	access(all)
	let AdminStoragePath: StoragePath
	
	//is the contract closed
	access(all)
	var closed: Bool
	
	access(all)
	resource Admin{ 
		
		//prevent minting
		access(TMP_ENTITLEMENT_OWNER)
		fun closeClaim(){ 
			S1MintTransferClaim.closed = true
		}
		
		//call S1ItemNFT's mintItem function
		//each address can only mint 2 times
		access(TMP_ENTITLEMENT_OWNER)
		fun mintAndTransferItem(
			name: String,
			recipientAddr: Address,
			royalty: S1ItemNFT.Royalty,
			garment: @S1GarmentNFT.NFT,
			material: @S1MaterialNFT.NFT,
			primaryColor: String,
			secondaryColor: String
		): @S1ItemNFT.NFT{ 
			pre{ 
				!S1MintTransferClaim.closed:
					"Minting is closed"
				S1MintTransferClaim.addressMintCount[recipientAddr] != 2:
					"Address has minted 2 items already"
			}
			let garmentDataID = garment.garment.garmentDataID
			let materialDataID = material.material.materialDataID
			
			// we check using the itemdataallocation using the garment/material dataid and primary/secondary color
			let itemDataID =
				S1ItemNFT.getItemDataAllocation(
					garmentDataID: garmentDataID,
					materialDataID: materialDataID,
					primaryColor: primaryColor,
					secondaryColor: secondaryColor
				)
			
			//set mint count of transacter as 1 if first time, else 2
			if S1MintTransferClaim.addressMintCount[recipientAddr] == nil{ 
				S1MintTransferClaim.addressMintCount[recipientAddr] = 1
			} else{ 
				S1MintTransferClaim.addressMintCount[recipientAddr] = 2
			}
			let garmentID = garment.id
			let materialID = material.id
			
			//admin mints the item
			let item <-
				S1ItemNFT.mintNFT(
					name: name,
					royaltyVault: royalty,
					garment: <-garment,
					material: <-material,
					primaryColor: primaryColor,
					secondaryColor: secondaryColor
				)
			emit ItemMintedAndTransferred(
				garmentDataID: garmentDataID,
				materialDataID: materialDataID,
				primaryColor: primaryColor,
				secondaryColor: secondaryColor,
				itemID: item.id
			)
			return <-item
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createNewAdmin(): @Admin{ 
			return <-create Admin()
		}
	}
	
	// get each address' current mint count
	access(TMP_ENTITLEMENT_OWNER)
	fun getAddressMintCount():{ Address: UInt32}{ 
		return S1MintTransferClaim.addressMintCount
	}
	
	init(){ 
		self.closed = false
		self.addressMintCount ={} 
		self.AdminStoragePath = /storage/S1MintTransferClaimAdmin0015
		self.account.storage.save<@Admin>(<-create Admin(), to: self.AdminStoragePath)
	}
}
