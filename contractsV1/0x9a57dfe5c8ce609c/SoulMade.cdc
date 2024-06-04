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

import NFTStorefront from "./../../standardsV1/NFTStorefront.cdc"

import SoulMadeComponent from "./SoulMadeComponent.cdc"

import SoulMadeMain from "./SoulMadeMain.cdc"

import SoulMadePack from "./SoulMadePack.cdc"

import SoulMadeMarketplace from "./SoulMadeMarketplace.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import FlowToken from "./../../standardsV1/FlowToken.cdc"

access(all)
contract SoulMade{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun mintComponent(
			series: String,
			name: String,
			description: String,
			category: String,
			layer: UInt64,
			edition: UInt64,
			maxEdition: UInt64,
			ipfsHash: String
		){ 
			let adminComponentsCollection =
				SoulMade.account.storage.borrow<&SoulMadeComponent.Collection>(
					from: SoulMadeComponent.CollectionStoragePath
				)!
			var newNFT <-
				SoulMadeComponent.makeEdition(
					series: series,
					name: name,
					description: description,
					category: category,
					layer: layer,
					currentEdition: edition,
					maxEdition: maxEdition,
					ipfsHash: ipfsHash
				)
			adminComponentsCollection.deposit(token: <-newNFT)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintComponents(
			series: String,
			name: String,
			description: String,
			category: String,
			layer: UInt64,
			startEdition: UInt64,
			endEdition: UInt64,
			maxEdition: UInt64,
			ipfsHash: String
		){ 
			let adminComponentsCollection =
				SoulMade.account.storage.borrow<&SoulMadeComponent.Collection>(
					from: SoulMadeComponent.CollectionStoragePath
				)!
			var edition = startEdition
			while edition <= endEdition{ 
				var newNFT <- SoulMadeComponent.makeEdition(series: series, name: name, description: description, category: category, layer: layer, currentEdition: edition, maxEdition: maxEdition, ipfsHash: ipfsHash)
				edition = edition + UInt64(1)
				adminComponentsCollection.deposit(token: <-newNFT)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun moveMainComponentToPack(
			scarcity: String,
			series: String,
			ipfsHash: String,
			mainNftIds: [
				UInt64
			],
			componentNftIds: [
				UInt64
			],
			adminStoragePath: StoragePath
		){ 
			let adminMainCollection =
				SoulMade.account.storage.borrow<&SoulMadeMain.Collection>(
					from: SoulMadeMain.CollectionStoragePath
				)!
			let adminComponentCollection =
				SoulMade.account.storage.borrow<&SoulMadeComponent.Collection>(
					from: SoulMadeComponent.CollectionStoragePath
				)!
			let adminPackCollection =
				SoulMade.account.storage.borrow<&SoulMadePack.Collection>(from: adminStoragePath)!
			var mainNftList: @[SoulMadeMain.NFT] <- []
			var componentNftList: @[SoulMadeComponent.NFT] <- []
			for mainNftId in mainNftIds{ 
				var nft <- adminMainCollection.withdraw(withdrawID: mainNftId) as! @SoulMadeMain.NFT
				mainNftList.append(<-nft)
			}
			for componentNftId in componentNftIds{ 
				var nft <- adminComponentCollection.withdraw(withdrawID: componentNftId) as! @SoulMadeComponent.NFT
				componentNftList.append(<-nft)
			}
			var packNft <-
				SoulMadePack.mintPack(
					scarcity: scarcity,
					series: series,
					ipfsHash: ipfsHash,
					mainNfts: <-mainNftList,
					componentNfts: <-componentNftList
				)
			adminPackCollection.deposit(token: <-packNft)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPackManually(
			scarcity: String,
			series: String,
			ipfsHash: String,
			mainNftIds: [
				UInt64
			],
			componentNftIds: [
				UInt64
			]
		){ 
			self.moveMainComponentToPack(
				scarcity: scarcity,
				series: series,
				ipfsHash: ipfsHash,
				mainNftIds: mainNftIds,
				componentNftIds: componentNftIds,
				adminStoragePath: SoulMadePack.CollectionStoragePath
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintPackFreeClaim(
			scarcity: String,
			series: String,
			ipfsHash: String,
			mainNftIds: [
				UInt64
			],
			componentNftIds: [
				UInt64
			]
		){ 
			self.moveMainComponentToPack(
				scarcity: scarcity,
				series: series,
				ipfsHash: ipfsHash,
				mainNftIds: mainNftIds,
				componentNftIds: componentNftIds,
				adminStoragePath: SoulMadePack.CollectionFreeClaimStoragePath
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun renewFreeClaim(){ 
			SoulMadePack.renewClaimDictionary()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updataAccountFreeClaim(address: Address, series: String){ 
			SoulMadePack.updateClaimDictionary(address: address, series: series)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updataPlatformCut(platformCut: UFix64){ 
			SoulMadeMarketplace.updatePlatformCut(platformCut: platformCut)
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMainCollectionIds(address: Address): [UInt64]{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadeMain.CollectionPublic}>(
				SoulMadeMain.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.getIDs()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getMainDetail(address: Address, mainNftId: UInt64): SoulMadeMain.MainDetail{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadeMain.CollectionPublic}>(
				SoulMadeMain.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.borrowMain(id: mainNftId).mainDetail
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getComponentCollectionIds(address: Address): [UInt64]{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadeComponent.CollectionPublic}>(
				SoulMadeComponent.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.getIDs()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getComponentDetail(
		address: Address,
		componentNftId: UInt64
	): SoulMadeComponent.ComponentDetail{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadeComponent.CollectionPublic}>(
				SoulMadeComponent.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.borrowComponent(id: componentNftId).componentDetail
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPackCollectionIds(address: Address): [UInt64]{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadePack.CollectionPublic}>(
				SoulMadePack.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.getIDs()
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPackDetail(address: Address, packNftId: UInt64): SoulMadePack.PackDetail{ 
		let receiverRef =
			getAccount(address).capabilities.get<&{SoulMadePack.CollectionPublic}>(
				SoulMadePack.CollectionPublicPath
			).borrow()
			?? panic("Could not borrow the receiver reference")
		return receiverRef.borrowPack(id: packNftId).packDetail
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getPackListingIdsPerSeries(address: Address):{ String: [UInt64]}{ 
		let storefrontRef =
			getAccount(address).capabilities.get<&NFTStorefront.Storefront>(
				NFTStorefront.StorefrontPublicPath
			).borrow()
			?? panic("Could not borrow public storefront from address")
		var res:{ String: [UInt64]} ={} 
		for listingID in storefrontRef.getListingIDs(){ 
			var listingDetail: NFTStorefront.ListingDetails = (storefrontRef.borrowListing(listingResourceID: listingID)!).getDetails()
			if listingDetail.purchased == false && listingDetail.nftType == Type<@SoulMadePack.NFT>(){ 
				var packNftId = listingDetail.nftID
				var packDetail: SoulMadePack.PackDetail = SoulMade.getPackDetail(address: address, packNftId: packNftId)!
				var packSeries = packDetail.series
				if res[packSeries] == nil{ 
					res[packSeries] = [listingID]
				} else{ 
					(res[packSeries]!).append(listingID)
				}
			}
		}
		return res
	}
	
	init(){ 
		self.AdminStoragePath = /storage/SoulMadeAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
