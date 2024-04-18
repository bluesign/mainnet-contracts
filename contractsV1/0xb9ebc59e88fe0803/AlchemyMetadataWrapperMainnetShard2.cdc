// AUTO-GENERATED CONTRACT
import AllDay from "../0xe4cf4bdc1751c65d/AllDay.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import Andbox_NFT from "../0x329feb3ab062d289/Andbox_NFT.cdc"

import BarterYardClubWerewolf from "../0x28abb9f291cadaf2/BarterYardClubWerewolf.cdc"

import BarterYardPackNFT from "../0xa95b021cf8a30d80/BarterYardPackNFT.cdc"

import Canes_Vault_NFT from "../0x329feb3ab062d289/Canes_Vault_NFT.cdc"

import Collectible from "../0xf5b0eb433389ac3f/Collectible.cdc"

import Costacos_NFT from "../0x329feb3ab062d289/Costacos_NFT.cdc"

import CryptoZooNFT from "../0x8ea44ab931cac762/CryptoZooNFT.cdc"

import DayNFT from "../0x1600b04bf033fb99/DayNFT.cdc"

import DieselNFT from "../0x497153c597783bc3/DieselNFT.cdc"

import FlowChinaBadge from "../0x99fed1e8da4c3431/FlowChinaBadge.cdc"

import GeniaceNFT from "../0xabda6627c70c7f52/GeniaceNFT.cdc"

import GooberXContract from "../0x34f2bf4a80bb0f69/GooberXContract.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MiamiNFT from "../0x429a19abea586a3e/MiamiNFT.cdc"

import MintStoreItem from "../0x20187093790b9aef/MintStoreItem.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import PackNFT from "../0xe4cf4bdc1751c65d/PackNFT.cdc"

import TFCItems from "../0x81e95660ab5308e1/TFCItems.cdc"

import TheFabricantMysteryBox_FF1 from "../0xa0cbe021821c0965/TheFabricantMysteryBox_FF1.cdc"

import ZeedzINO from "../0x62b3063fbe672fc8/ZeedzINO.cdc"

/*
	A wrapper contract around the script provided by the Alchemy GitHub respository.
	Allows for on-chain storage of NFT Metadata, allowing consumers to query upon.
	This contract will be periodically updated based on new onboarding PRs and deployed.
	Any consumers calling the public methods below will retrieve the latest and greatest data.
*/

access(all)
contract AlchemyMetadataWrapperMainnetShard2{ 
	// Structs copied over as-is from getNFT(ID)?s.cdc for backwards-compatability.
	access(all)
	struct NFTCollection{ 
		access(all)
		let owner: Address
		
		access(all)
		let nfts: [NFTData]
		
		init(owner: Address){ 
			self.owner = owner
			self.nfts = []
		}
	}
	
	access(all)
	struct NFTData{ 
		access(all)
		let contract: NFTContractData
		
		access(all)
		let id: UInt64
		
		access(all)
		let uuid: UInt64?
		
		access(all)
		let title: String?
		
		access(all)
		let description: String?
		
		access(all)
		let external_domain_view_url: String?
		
		access(all)
		let token_uri: String?
		
		access(all)
		let media: [NFTMedia?]
		
		access(all)
		let metadata:{ String: String?}
		
		init(
			_contract: NFTContractData,
			id: UInt64,
			uuid: UInt64?,
			title: String?,
			description: String?,
			external_domain_view_url: String?,
			token_uri: String?,
			media: [
				NFTMedia?
			],
			metadata:{ 
				String: String?
			}
		){ 
			self.contract = _contract
			self.id = id
			self.uuid = uuid
			self.title = title
			self.description = description
			self.external_domain_view_url = external_domain_view_url
			self.token_uri = token_uri
			self.media = media
			self.metadata = metadata
		}
	}
	
	access(all)
	struct NFTContractData{ 
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let storage_path: String
		
		access(all)
		let public_path: String
		
		access(all)
		let public_collection_name: String
		
		access(all)
		let external_domain: String
		
		init(
			name: String,
			address: Address,
			storage_path: String,
			public_path: String,
			public_collection_name: String,
			external_domain: String
		){ 
			self.name = name
			self.address = address
			self.storage_path = storage_path
			self.public_path = public_path
			self.public_collection_name = public_collection_name
			self.external_domain = external_domain
		}
	}
	
	access(all)
	struct NFTMedia{ 
		access(all)
		let uri: String?
		
		access(all)
		let mimetype: String?
		
		init(uri: String?, mimetype: String?){ 
			self.uri = uri
			self.mimetype = mimetype
		}
	}
	
	// Same method signature as getNFTs.cdc for backwards-compatability.
	access(all)
	fun getNFTs(ownerAddress: Address, ids:{ String: [UInt64]}): [NFTData?]{ 
		let NFTs: [NFTData?] = []
		let owner = getAccount(ownerAddress)
		for key in ids.keys{ 
			for id in ids[key]!{ 
				var d: NFTData? = nil
				
				// note: unfortunately dictonairy containing functions is not
				// working on mainnet for now so we have to fallback to switch
				switch key{ 
					case "CNN":
						continue
					case "Gaia":
						continue
					case "TopShot":
						continue
					case "MatrixWorldFlowFestNFT":
						continue
					case "StarlyCard":
						continue
					case "EternalShard":
						continue
					case "Mynft":
						continue
					case "Vouchers":
						continue
					case "MusicBlock":
						continue
					case "NyatheesOVO":
						continue
					case "RaceDay_NFT":
						continue
					case "Andbox_NFT":
						d = self.getAndbox_NFT(owner: owner, id: id)
					case "FantastecNFT":
						continue
					case "Everbloom":
						continue
					case "Domains":
						continue
					case "EternalMoment":
						continue
					case "ThingFund":
						continue
					case "TFCItems":
						d = self.getTFCItems(owner: owner, id: id)
					case "Gooberz":
						d = self.getGooberz(owner: owner, id: id)
					case "MintStoreItem":
						d = self.getMintStoreItem(owner: owner, id: id)
					case "BiscuitsNGroovy":
						continue
					case "GeniaceNFT":
						d = self.getGeniaceNFT(owner: owner, id: id)
					case "Xtingles":
						d = self.getXtinglesNFT(owner: owner, id: id)
					case "Beam":
						continue
					case "KOTD":
						continue
					case "KlktnNFT":
						continue
					case "KlktnNFT2":
						continue
					case "RareRooms_NFT":
						continue
					case "Crave":
						continue
					case "CricketMoments":
						continue
					case "SportsIconCollectible":
						continue
					case "InceptionAnimals":
						d = self.getInceptionAnimals(owner: owner, id: id)
					case "OneFootballCollectible":
						continue
					case "TheFabricantMysteryBox_FF1":
						d = self.getTheFabricantMysteryBox_FF1(owner: owner, id: id)
					case "DieselNFT":
						d = self.getDieselNFT(owner: owner, id: id)
					case "MiamiNFT":
						d = self.getMiamiNFT(owner: owner, id: id)
					case "Bitku":
						continue
					case "FlowFans":
						d = self.getFlowFansNFT(owner: owner, id: id)
					case "AllDay":
						d = self.getAllDay(owner: owner, id: id)
					case "PackNFT":
						d = self.getAllDayPackNFT(owner: owner, id: id)
					case "ItemNFT":
						continue
					case "TheFabricantS1ItemNFT":
						continue
					case "ZeedzINO":
						d = self.getZeedzINO(owner: owner, id: id)
					case "Kicks":
						continue
					case "BarterYardPack":
						d = self.getBarterYardPack(owner: owner, id: id)
					case "BarterYardClubWerewolf":
						d = self.getBarterYardClubWerewolf(owner: owner, id: id)
					case "DayNFT":
						d = self.getDayNFT(owner: owner, id: id)
					case "Costacos_NFT":
						d = self.getCostacosNFT(owner: owner, id: id)
					case "Canes_Vault_NFT":
						d = self.getCanesVaultNFT(owner: owner, id: id)
					case "AmericanAirlines_NFT":
						continue
					case "The_Next_Cartel_NFT":
						continue
					case "Atheletes_Unlimited_NFT":
						continue
					case "Art_NFT":
						continue
					case "DGD_NFT":
						continue
					case "NowggNFT":
						continue
					case "GogoroCollectible":
						continue
					case "YahooCollectible":
						continue
					case "YahooPartnersCollectible":
						continue
					case "BlindBoxRedeemVoucher":
						continue
					case "SomePlaceCollectible":
						continue
					case "ARTIFACTPack":
						continue
					case "ARTIFACT":
						continue
					case "NftReality":
						continue
					case "MatrixWorldAssetsNFT":
						continue
					case "TuneGO":
						continue
					case "TicalUniverse":
						continue
					case "RacingTime":
						continue
					case "Momentables":
						continue
					case "GoatedGoats":
						continue
					case "GoatedGoatsTrait":
						continue
					case "DropzToken":
						continue
					case "Necryptolis":
						continue
					case "FLOAT":
						continue
					case "BreakingT_NFT":
						continue
					case "Owners":
						continue
					case "Metaverse":
						continue
					case "NFTContract":
						continue
					case "Swaychain":
						continue
					case "Maxar":
						continue
					case "TheFabricantS2ItemNFT":
						continue
					case "VnMiss":
						continue
					case "AvatarArt":
						continue
					case "Dooverse":
						continue
					case "TrartContractNFT":
						continue
					case "SturdyItems":
						continue
					case "PartyMansionDrinksContract":
						continue
					case "CryptoPiggo":
						continue
					case "Evolution":
						continue
					case "Moments":
						continue
					case "MotoGPCard":
						continue
					case "UFC_NFT":
						continue
					case "Flovatar":
						continue
					case "FlovatarComponent":
						continue
					case "ByteNextMedalNFT":
						continue
					case "RCRDSHPNFT":
						continue
					case "Seussibles":
						continue
					case "MetaPanda":
						continue
					case "Flunks":
						continue
					default:
						panic("adapter for NFT not found: ".concat(key))
				}
				NFTs.append(d)
			}
		}
		return NFTs
	}
	
	access(all)
	fun stringStartsWith(string: String, prefix: String): Bool{ 
		if string.length < prefix.length{ 
			return false
		}
		let beginning = string.slice(from: 0, upTo: prefix.length)
		let prefixArray = prefix.utf8
		let beginningArray = beginning.utf8
		for index, element in prefixArray{ 
			if beginningArray[index] != prefixArray[index]{ 
				return false
			}
		}
		return true
	}
	
	// https://flow-view-source.com/mainnet/account/0x86b4a0010a71cfc3/contract/Beam
	access(all)
	fun getAndbox_NFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Andbox_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "Andbox_NFT.CollectionStoragePath",
				public_path: "Andbox_NFT.CollectionPublicPath",
				public_collection_name: "Andbox_NFT.Andbox_NFTCollectionPublic",
				external_domain: "https://andbox.shops.nftbridge.com/"
			)
		let col =
			(
				owner.capabilities.get<&{Andbox_NFT.Andbox_NFTCollectionPublic}>(
					Andbox_NFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowAndbox_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = Andbox_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			Andbox_NFT.getSeriesMetadata(seriesId: Andbox_NFT.getSetSeriesId(setId: (nft!).setId)!)
		let seriesId = Andbox_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = Andbox_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://andbox.shops.nftbridge.com/tokens/".concat((nft!).id.toString())
		var mimeType = "image"
		if ((setMeta!)["image_file_type"]!).toLower() == "mp4"{ 
			mimeType = "video/mp4"
		} else if ((setMeta!)["image_file_type"]!).toLower() == "glb"{ 
			mimeType = "model/gltf-binary"
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (setMeta!)["name"],
			description: (setMeta!)["description"],
			external_domain_view_url: externalTokenViewUrl,
			token_uri: nil,
			media: [
				NFTMedia(uri: (setMeta!)["image"], mimetype: mimeType),
				NFTMedia(uri: (setMeta!)["preview"], mimetype: "image")
			],
			metadata:{ 
				"editionNumber": (nft!).editionNum.toString(),
				"editionCount": (nftEditions!).toString(),
				"set_id": (nft!).setId.toString(),
				"series_id": (seriesId!).toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/RareRooms_NFT
	access(all)
	fun getTFCItems(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "TFCItems",
				address: 0x81e95660ab5308e1,
				storage_path: "/storage/TFCItemsCollection",
				public_path: "/public/TFCItemsCollection",
				public_collection_name: "TFCItem.TFCItemsCollectionPublic",
				external_domain: ""
			)
		let col =
			(
				owner.capabilities.get<&{TFCItems.TFCItemsCollectionPublic}>(
					TFCItems.CollectionPublicPath
				)!!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowTFCItem(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()
		let rawMetadata:{ String: String?} ={} 
		for key in (metadata!).keys{ 
			rawMetadata.insert(key: key, (metadata!)[key])
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata["Title"]!,
			description: nil,
			external_domain_view_url: "thefootballclub.com",
			token_uri: nil,
			media: [NFTMedia(uri: metadata["URL"]!, mimetype: "image")],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x34f2bf4a80bb0f69/contract/GooberXContract
	access(all)
	fun getGooberz(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "GooberXContract",
				address: 0x34f2bf4a80bb0f69,
				storage_path: "GooberXContract.CollectionStoragePath",
				public_path: "GooberXContract.CollectionPublicPath",
				public_collection_name: "GooberXContract.GooberCollectionPublic",
				external_domain: "partymansion.io"
			)
		let col =
			(
				owner.capabilities.get<&{GooberXContract.GooberCollectionPublic}>(
					GooberXContract.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowGoober(id: id)
		if nft == nil{ 
			return nil
		}
		let title = "Goober #".concat((nft!).id.toString())
		let description = "Goober living in the party mansion"
		let external_domain_view_url =
			"https://partymansion.io/gooberz/".concat((nft!).id.toString())
		let rawMetadata:{ String: String?} ={} 
		for key in (((nft!).data!).metadata!).keys{ 
			if ((((nft!).data!).metadata!)[key]!).getType().isSubtype(of: Type<Number>()){ 
				rawMetadata.insert(key: key, ((((nft!).data!).metadata!)[key]! as! Number).toString())
			} else if ((((nft!).data!).metadata!)[key]!).getType().isSubtype(of: Type<String>()){ 
				rawMetadata.insert(key: key, (((nft!).data!).metadata!)[key]! as! String)
			}
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: title,
			description: description,
			external_domain_view_url: external_domain_view_url,
			token_uri: nil,
			media: [NFTMedia(uri: ((nft!).data!).uri, mimetype: "image")],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x20187093790b9aef/contract/MintStoreItem
	// https://flow-view-source.com/testnet/account/0x985d410b577fd4a1/contract/MintStoreItem
	access(all)
	fun getMintStoreItem(owner: &Account, id: UInt64): NFTData?{ 
		let col =
			(
				owner.capabilities.get<&{MintStoreItem.MintStoreItemCollectionPublic}>(
					MintStoreItem.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowMintStoreItem(id: id)
		if nft == nil{ 
			return nil
		}
		let editionData = MintStoreItem.EditionData(editionID: (nft!).data.editionID)!
		let description = (editionData!).metadata["description"]!
		let merchantName = MintStoreItem.getMerchant(merchantID: (nft!).data.merchantID)!
		var external_domain = ""
		switch merchantName{ 
			case "Bulls":
				external_domain = "https://bulls.mint.store"
				break
			case "Charlotte Hornets":
				external_domain = "https://hornets.mint.store"
				break
			default:
				external_domain = ""
		}
		if (editionData!).metadata["nftType"]! == "Type C"{ 
			external_domain = "https://misa.art/collections/nft"
		}
		let _contract =
			NFTContractData(
				name: merchantName,
				address: 0x985d410b577fd4a1,
				storage_path: "MintStoreItem.CollectionStoragePath",
				public_path: "MintStoreItem.CollectionPublicPath",
				public_collection_name: "MintStoreItem.MintStoreItemCollectionPublic",
				external_domain: external_domain
			)
		let rawMetadata:{ String: String?} ={
			
				"merchantID": (nft!).data.merchantID.toString(),
				"merchantName": merchantName,
				"editionID": (editionData!).editionID.toString(),
				"numberOfItemsMinted": (editionData!).numberOfItemsMinted.toString(),
				"printingLimit": ((editionData!).printingLimit!).toString(),
				"editionNumber": (nft!).data.editionNumber.toString(),
				"description": (editionData!).metadata["description"]!,
				"name": (editionData!).metadata["name"]!,
				"nftType": (editionData!).metadata["nftType"]!,
				"editionCount": ((editionData!).printingLimit!).toString(),
				"royaltyAddress": (editionData!).metadata["royaltyAddress"],
				"royaltyPercentage": (editionData!).metadata["royaltyPercentage"]
			}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: editionData.name,
			description: description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [
				NFTMedia(
					uri: (editionData!).metadata["mediaURL"],
					mimetype: (editionData!).metadata["mimetype"]
				)
			],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x7859c48816bfea3c/contract/BnGNFT
	access(all)
	fun getGeniaceNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Geniace",
				address: 0xabda6627c70c7f52,
				storage_path: "GeniaceNFT.CollectionStoragePath",
				public_path: "GeniaceNFT.CollectionPublicPath",
				public_collection_name: "GeniaceNFT.GeniaceNFTCollectionPublic",
				external_domain: "https://www.geniace.com/"
			)
		let col =
			(
				owner.capabilities.get<&{GeniaceNFT.GeniaceNFTCollectionPublic}>(
					GeniaceNFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowGeniaceNFT(id: id)
		if nft == nil{ 
			return nil
		}
		fun getNFTMedia(): [NFTMedia?]{ 
			if (((nft!).metadata!).data!)["mimetype"] == nil{ 
				return []
			} else{ 
				return [NFTMedia(uri: ((nft!).metadata!).imageUrl, mimetype: (((nft!).metadata!).data!)["mimetype"])]
			}
		}
		fun getRarity(): String?{ 
			switch (nft!).metadata.rarity{ 
				case GeniaceNFT.Rarity.Collectible:
					return "Collectible"
				case GeniaceNFT.Rarity.Rare:
					return "Rare"
				case GeniaceNFT.Rarity.UltraRare:
					return "UltraRare"
				default:
					return ""
			}
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: ((nft!).metadata!).name,
			description: ((nft!).metadata!).description,
			external_domain_view_url: "https://www.geniace.com/product/".concat(
				(nft!).id.toString()
			),
			token_uri: nil,
			media: getNFTMedia(),
			metadata:{ 
				"celebrityName": ((nft!).metadata!).celebrityName,
				"artist": ((nft!).metadata!).artist,
				"rarity": getRarity()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xf5b0eb433389ac3f/contract/Collectible
	access(all)
	fun getXtinglesNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Xtingles",
				address: 0xf5b0eb433389ac3f,
				storage_path: "Collectible.CollectionStoragePath",
				public_path: "Collectible.CollectionPublicPath",
				public_collection_name: "Collectible.CollectionPublicPath",
				external_domain: "https://www.xtingles.com/"
			)
		let col =
			(
				owner.capabilities.get<&{Collectible.CollectionPublic}>(
					Collectible.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowCollectible(id: id)
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: ((nft!).metadata!).name,
			description: ((nft!).metadata!).description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [NFTMedia(uri: ((nft!).metadata!).link, mimetype: "video")],
			metadata:{ 
				"author": ((nft!).metadata!).author,
				"edition": ((nft!).metadata!).edition.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x8ea44ab931cac762
	access(all)
	fun getInceptionAnimals(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "InceptionAnimals",
				address: 0x8ea44ab931cac762,
				storage_path: "CryptoZooNFT.CollectionStoragePath",
				public_path: "CryptoZooNFT.CollectionPublicPath",
				public_collection_name: "CryptoZooNFT.CryptoZooNFTCollectionPublic",
				external_domain: "https://www.inceptionanimals.com/"
			)
		let col =
			(
				owner.capabilities.get<&{CryptoZooNFT.CryptoZooNFTCollectionPublic}>(
					CryptoZooNFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowCryptoZooNFT(id: id)
		if nft == nil{ 
			return nil
		}
		let rawMetadata:{ String: String?} ={} 
		for key in (((nft!).getNFTTemplate()!).getMetadata()!).keys{ 
			rawMetadata.insert(key: key, (((nft!).getNFTTemplate()!).getMetadata()!)[key])
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (nft!).name,
			description: ((nft!).getNFTTemplate()!).description,
			external_domain_view_url: nil,
			token_uri: ((nft!).getNFTTemplate()!).getMetadata()["uri"]!,
			media: [
				NFTMedia(
					uri: ((nft!).getNFTTemplate()!).getMetadata()["uri"]!,
					mimetype: ((nft!).getNFTTemplate()!).getMetadata()["mimetype"]!
				)
			],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x6831760534292098/contract/OneFootballCollectible
	access(all)
	fun getTheFabricantMysteryBox_FF1(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "TheFabricantMysteryBox_FF1",
				address: 0xa0cbe021821c0965,
				storage_path: "/storage/FabricantCollection001",
				public_path: "/public/FabricantCollection001",
				public_collection_name: "TheFabricantMysteryBox_FF1.FabricantCollectionPublic",
				external_domain: ""
			)
		let col =
			(
				owner.capabilities.get<&{TheFabricantMysteryBox_FF1.FabricantCollectionPublic}>(
					/public/FabricantCollection001
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowFabricant(id: id)!
		if nft == nil{ 
			return nil
		}
		let dataID = nft.fabricant.fabricantDataID
		let fabricantData = TheFabricantMysteryBox_FF1.getFabricantData(id: dataID)
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: nil,
			description: nil,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [NFTMedia(uri: fabricantData.mainImage, mimetype: "image")],
			metadata:{} 
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x497153c597783bc3/contract/DieselNFT
	access(all)
	fun getDieselNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "DieselNFT",
				address: 0x497153c597783bc3,
				storage_path: "/storage/DieselCollection001",
				public_path: "/public/DieselCollection001",
				public_collection_name: "DieselNFT.DieselCollectionPublic",
				external_domain: ""
			)
		let col =
			(
				owner.capabilities.get<&{DieselNFT.DieselCollectionPublic}>(
					/public/DieselCollection001
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowDiesel(id: id)!
		if nft == nil{ 
			return nil
		}
		let dataID = nft.diesel.dieselDataID
		let dieselData = DieselNFT.getDieselData(id: dataID)
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: dieselData.name,
			description: dieselData.description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [NFTMedia(uri: dieselData.mainVideo, mimetype: "video")],
			metadata:{} 
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x429a19abea586a3e/contract/MiamiNFT
	access(all)
	fun getMiamiNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "MiamiNFT",
				address: 0x429a19abea586a3e,
				storage_path: "/storage/MiamiCollection001",
				public_path: "/public/MiamiCollection001",
				public_collection_name: "MiamiNFT.MiamiCollectionPublic",
				external_domain: ""
			)
		let col =
			(owner.capabilities.get<&{MiamiNFT.MiamiCollectionPublic}>(/public/MiamiCollection001)!)
				.borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowMiami(id: id)!
		if nft == nil{ 
			return nil
		}
		let dataID = nft.miami.miamiDataID
		let miamiData = MiamiNFT.getMiamiData(id: dataID)
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: miamiData.name,
			description: miamiData.description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [NFTMedia(uri: miamiData.mainVideo, mimetype: "video")],
			metadata:{ "creator": miamiData.creator.toString(), "season": miamiData.season}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xf61e40c19db2a9e2/contract/HaikuNFT
	access(all)
	fun getFlowFansNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "FlowFans",
				address: 0x99fed1e8da4c3431,
				storage_path: "/storage/FlowChinaBadgeCollection",
				public_path: "/public/FlowChinaBadgeCollection",
				public_collection_name: "FlowChinaBadge.FlowChinaBadgeCollectionPublic",
				external_domain: "https://twitter.com/FlowFansChina"
			)
		let col =
			(
				owner.capabilities.get<&{FlowChinaBadge.FlowChinaBadgeCollectionPublic}>(
					/public/FlowChinaBadgeCollection
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowFlowChinaBadge(id: id)
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: nil,
			description: nil,
			external_domain_view_url: nil,
			token_uri: (nft!).metadata,
			media: [],
			metadata:{} 
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xe4cf4bdc1751c65d/contract/AllDay
	access(all)
	fun getAllDay(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "AllDay",
				address: 0xe4cf4bdc1751c65d,
				storage_path: "AllDay.CollectionStoragePath",
				public_path: "AllDay.CollectionPublicPath",
				public_collection_name: "AllDay.MomentNFTCollectionPublic",
				external_domain: "https://nflallday.com/"
			)
		let col =
			(
				owner.capabilities.get<&{AllDay.MomentNFTCollectionPublic}>(
					AllDay.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowMomentNFT(id: id)
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: "Moment".concat((nft!).id.toString()).concat("-Edition").concat(
				(nft!).editionID.toString()
			).concat("-SerialNumber").concat((nft!).serialNumber.toString()),
			description: nil,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [],
			metadata:{} 
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xe4cf4bdc1751c65d/contract/PackNFT
	access(all)
	fun getAllDayPackNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "PackNFT",
				address: 0xe4cf4bdc1751c65d,
				storage_path: "PackNFT.CollectionStoragePath",
				public_path: "PackNFT.CollectionPublicPath",
				public_collection_name: "NonFungibleToken.CollectionPublic",
				external_domain: "https://nflallday.com/"
			)
		let col =
			(
				owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					PackNFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowNFT(id)
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: nil,
			description: nil,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [],
			metadata:{} 
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xfc91de5e6566cc7c/contract/ItemNFT
	access(all)
	fun getZeedzINO(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "ZeedzINO",
				address: 0x62b3063fbe672fc8,
				storage_path: "/storage/ZeedzINOCollection",
				public_path: "/public/ZeedzINOCollection",
				public_collection_name: "ZeedzINO.ZeedzCollectionPublic",
				external_domain: ""
			)
		let col =
			(owner.capabilities.get<&{ZeedzINO.ZeedzCollectionPublic}>(/public/ZeedzINOCollection)!)
				.borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowZeedle(id: id)
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (nft!).name,
			description: (nft!).description,
			external_domain_view_url: "https:/www.zeedz.io",
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://zeedz.mypinata.cloud/ipfs/".concat((nft!).imageURI),
					mimetype: "image"
				)
			],
			metadata:{ 
				"typeID": (nft!).typeID.toString(),
				"evoultionStage": (nft!).evolutionStage.toString(),
				"serialNumber": (nft!).serialNumber,
				"editionNumber": (nft!).edition.toString(),
				"editionCount": (nft!).editionCap.toString(),
				"rarity": (nft!).rarity,
				"carbonOffset": (nft!).carbonOffset.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xf3cc54f4d91c2f6c/contract/Kicks
	access(all)
	fun getBarterYardPack(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "BarterYardPack",
				address: 0xa95b021cf8a30d80,
				storage_path: "BarterYardPackNFT.CollectionStoragePath",
				public_path: "BarterYardPackNFT.CollectionPublicPath",
				public_collection_name: "BarterYardPackNFT.BarterYardPackNFTCollectionPublic",
				external_domain: "https://barteryard.club"
			)
		let collection =
			(
				owner.capabilities.get<&{BarterYardPackNFT.BarterYardPackNFTCollectionPublic}>(
					BarterYardPackNFT.CollectionPublicPath
				)!
			).borrow()!
		if collection == nil{ 
			return nil
		}
		let nft = collection.borrowBarterYardPackNFT(id: id)!
		// Get the basic display information for this NFT
		let view = nft.resolveView(Type<MetadataViews.Display>())!
		let display = view as! MetadataViews.Display
		let ipfsFile = display.thumbnail as! MetadataViews.IPFSFile
		let packPartView = nft.resolveView(Type<BarterYardPackNFT.PackMetadataDisplay>())!
		let packMetadata = packPartView as! BarterYardPackNFT.PackMetadataDisplay
		let edition = packMetadata.edition
		return NFTData(
			_contract: _contract,
			id: id,
			uuid: nft.uuid,
			title: display.name.concat(" #").concat(edition.toString()),
			description: display.description,
			external_domain_view_url: "https://barteryard.club/nft/".concat(id.toString()),
			token_uri: nil,
			media: [NFTMedia(uri: "https://ipfs.io/ipfs/".concat(ipfsFile.cid), mimetype: "image")],
			metadata:{ "pack": display.name}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x28abb9f291cadaf2/contract/BarterYardClubWerewolf
	access(all)
	fun getBarterYardClubWerewolf(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "BarterYardClubWerewolf",
				address: 0x28abb9f291cadaf2,
				storage_path: "BarterYardClubWerewolf.CollectionStoragePath",
				public_path: "BarterYardClubWerewolf.CollectionPublicPath",
				public_collection_name: "BarterYardClubWerewolf.CollectionPublic",
				external_domain: "https://app.barteryard.club"
			)
		let collection =
			(
				owner.capabilities.get<&{ViewResolver.ResolverCollection}>(
					BarterYardClubWerewolf.CollectionPublicPath
				)!
			).borrow()
			?? panic("Could not borrow a reference to the collection")
		let nft = collection.borrowViewResolver(id: id)!
		let view = nft.resolveView(Type<BarterYardClubWerewolf.CompleteDisplay>())!
		let display = view as! BarterYardClubWerewolf.CompleteDisplay
		let background = display.getAttributes()[0].value
		let fur = display.getAttributes()[1].value
		let body = display.getAttributes()[2].value
		let eyes = display.getAttributes()[4].value
		let glasses = display.getAttributes()[5].value
		let headgear = display.getAttributes()[6].value
		let item = display.getAttributes()[7].value
		let mouth = display.getAttributes()[3].value
		return NFTData(
			_contract: _contract,
			id: id,
			uuid: nil,
			title: display.name,
			description: display.description,
			external_domain_view_url: "https://barteryard.club/nft/".concat(id.toString()),
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://ipfs.io/ipfs/".concat(display.thumbnail.cid).concat("/").concat(
						display.thumbnail.path!
					),
					mimetype: "image"
				)
			],
			metadata:{ 
				"Background": background,
				"Fur": fur,
				"Body": body,
				"Eyes": eyes,
				"Glasses": glasses,
				"Headgear": headgear,
				"Item": item,
				"Mouth": mouth
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x1600b04bf033fb99/contract/DayNFT
	access(all)
	fun getDayNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "DayNFT",
				address: 0x1600b04bf033fb99,
				storage_path: "DayNFT.CollectionStoragePath",
				public_path: "DayNFT.CollectionPublicPath",
				public_collection_name: "DayNFT.CollectionPublic",
				external_domain: "https://day-nft.io"
			)
		let col =
			(owner.capabilities.get<&{DayNFT.CollectionPublic}>(DayNFT.CollectionPublicPath)!)
				.borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowDayNFT(id: id)!
		if nft == nil{ 
			return nil
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (nft!).name,
			description: (nft!).description,
			external_domain_view_url: (nft!).thumbnail,
			token_uri: nil,
			media: [NFTMedia(uri: (nft!).thumbnail, mimetype: "image")],
			metadata:{ 
				"name": (nft!).name,
				"message": (nft!).title,
				"description": (nft!).description,
				"thumbnail": (nft!).thumbnail,
				"date": (nft!).dateStr,
				"editionNumber": "1",
				"editionCount": "1",
				"royaltyAddress": "0x1600b04bf033fb99",
				"royaltyPercentage": "5.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/Costacos_NFT
	access(all)
	fun getCostacosNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Costacos_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "Costacos_NFT.CollectionStoragePath",
				public_path: "Costacos_NFT.CollectionPublicPath",
				public_collection_name: "Costacos_NFT.Costacos_NFT",
				external_domain: "https://costacoscollection.com/"
			)
		let col =
			(
				owner.capabilities.get<&{Costacos_NFT.Costacos_NFTCollectionPublic}>(
					Costacos_NFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowCostacos_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = Costacos_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			Costacos_NFT.getSeriesMetadata(
				seriesId: Costacos_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = Costacos_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = Costacos_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://shop.costacoscollection.com/tokens/".concat((nft!).id.toString())
		var mimeType = "image"
		if ((setMeta!)["image_file_type"]!).toLower() == "mp4"{ 
			mimeType = "video/mp4"
		} else if ((setMeta!)["image_file_type"]!).toLower() == "glb"{ 
			mimeType = "model/gltf-binary"
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (setMeta!)["name"],
			description: (setMeta!)["description"],
			external_domain_view_url: externalTokenViewUrl,
			token_uri: nil,
			media: [
				NFTMedia(uri: (setMeta!)["image"], mimetype: mimeType),
				NFTMedia(uri: (setMeta!)["preview"], mimetype: "image")
			],
			metadata:{ 
				"editionNumber": (nft!).editionNum.toString(),
				"editionCount": (nftEditions!).toString(),
				"set_id": (nft!).setId.toString(),
				"series_id": (seriesId!).toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/Canes_Vault_NFT
	access(all)
	fun getCanesVaultNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Canes_Vault_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "Canes_Vault_NFT.CollectionStoragePath",
				public_path: "Canes_Vault_NFT.CollectionPublicPath",
				public_collection_name: "Canes_Vault_NFT.Canes_Vault_NFT",
				external_domain: "https://www.canesvault.com/"
			)
		let col =
			(
				owner.capabilities.get<&{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(
					Canes_Vault_NFT.CollectionPublicPath
				)!
			).borrow()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowCanes_Vault_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = Canes_Vault_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			Canes_Vault_NFT.getSeriesMetadata(
				seriesId: Canes_Vault_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = Canes_Vault_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = Canes_Vault_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			((setMeta!)["external_url"]!).concat("/tokens/").concat((nft!).id.toString())
		var mimeType = "image"
		if ((setMeta!)["image_file_type"]!).toLower() == "mp4"{ 
			mimeType = "video/mp4"
		} else if ((setMeta!)["image_file_type"]!).toLower() == "glb"{ 
			mimeType = "model/gltf-binary"
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (setMeta!)["name"],
			description: (setMeta!)["description"],
			external_domain_view_url: externalTokenViewUrl,
			token_uri: nil,
			media: [
				NFTMedia(uri: (setMeta!)["image"], mimetype: mimeType),
				NFTMedia(uri: (setMeta!)["preview"], mimetype: "image")
			],
			metadata:{ 
				"editionNumber": (nft!).editionNum.toString(),
				"editionCount": (nftEditions!).toString(),
				"set_id": (nft!).setId.toString(),
				"series_id": (seriesId!).toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/AmericanAirlines_NFT
	// Same method signature as getNFTIDs.cdc for backwards-compatability.
	access(all)
	fun getNFTIDs(ownerAddress: Address):{ String: [UInt64]}{ 
		let owner = getAccount(ownerAddress)
		let ids:{ String: [UInt64]} ={} 
		if let col =
			(
				owner.capabilities.get<&{TFCItems.TFCItemsCollectionPublic}>(
					TFCItems.CollectionPublicPath
				)!
			).borrow(){ 
			ids["TFCItems"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{GooberXContract.GooberCollectionPublic}>(
					GooberXContract.CollectionPublicPath
				)!
			).borrow(){ 
			ids["Gooberz"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{MintStoreItem.MintStoreItemCollectionPublic}>(
					MintStoreItem.CollectionPublicPath
				)!
			).borrow(){ 
			let mintStoreIDs = col.getIDs()
			for tokenID in mintStoreIDs{ 
				let nft = (col!).borrowMintStoreItem(id: tokenID)
				let merchantName = MintStoreItem.getMerchant(merchantID: (nft!).data.merchantID)!
				let merchKey = "MintStoreItem.".concat(merchantName)
				if ids[merchKey] == nil{ 
					ids[merchKey] = [tokenID]
				} else{ 
					(ids[merchKey]!).append(tokenID)
				}
			}
		}
		if let col =
			(
				owner.capabilities.get<&{GeniaceNFT.GeniaceNFTCollectionPublic}>(
					GeniaceNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["GeniaceNFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{Collectible.CollectionPublic}>(
					Collectible.CollectionPublicPath
				)!
			).borrow(){ 
			ids["Xtingles"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{CryptoZooNFT.CryptoZooNFTCollectionPublic}>(
					CryptoZooNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["InceptionAnimals"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{TheFabricantMysteryBox_FF1.FabricantCollectionPublic}>(
					TheFabricantMysteryBox_FF1.CollectionPublicPath
				)!
			).borrow(){ 
			ids["TheFabricantMysteryBox_FF1"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{DieselNFT.DieselCollectionPublic}>(
					DieselNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["DieselNFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{MiamiNFT.MiamiCollectionPublic}>(
					MiamiNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["MiamiNFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{FlowChinaBadge.FlowChinaBadgeCollectionPublic}>(
					FlowChinaBadge.CollectionPublicPath
				)!
			).borrow(){ 
			ids["FlowFans"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{AllDay.MomentNFTCollectionPublic}>(
					AllDay.CollectionPublicPath
				)!
			).borrow(){ 
			ids["AllDay"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
					PackNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["PackNFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{Andbox_NFT.Andbox_NFTCollectionPublic}>(
					Andbox_NFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["Andbox_NFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{ZeedzINO.ZeedzCollectionPublic}>(
					ZeedzINO.CollectionPublicPath
				)!
			).borrow(){ 
			ids["ZeedzINO"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{BarterYardPackNFT.BarterYardPackNFTCollectionPublic}>(
					BarterYardPackNFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["BarterYardPack"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&BarterYardClubWerewolf.Collection>(
					BarterYardClubWerewolf.CollectionPublicPath
				)!
			).borrow(){ 
			ids["BarterYardClubWerewolf"] = col.getIDs()
		}
		if let col =
			(owner.capabilities.get<&{DayNFT.CollectionPublic}>(DayNFT.CollectionPublicPath)!)
				.borrow(){ 
			ids["DayNFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{Costacos_NFT.Costacos_NFTCollectionPublic}>(
					Costacos_NFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["Costacos_NFT"] = col.getIDs()
		}
		if let col =
			(
				owner.capabilities.get<&{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(
					Canes_Vault_NFT.CollectionPublicPath
				)!
			).borrow(){ 
			ids["Canes_Vault_NFT"] = col.getIDs()
		}
		return ids
	}
}
