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

	// AUTO-GENERATED CONTRACT
import ARTIFACT from "../0x24de869c5e40b2eb/ARTIFACT.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import ARTIFACTPack from "../0x24de869c5e40b2eb/ARTIFACTPack.cdc"

import AmericanAirlines_NFT from "../0x329feb3ab062d289/AmericanAirlines_NFT.cdc"

import Art_NFT from "../0x329feb3ab062d289/Art_NFT.cdc"

import Atheletes_Unlimited_NFT from "../0x329feb3ab062d289/Atheletes_Unlimited_NFT.cdc"

import BlindBoxRedeemVoucher from "../0x910514afa41bfeac/BlindBoxRedeemVoucher.cdc"

import BreakingT_NFT from "../0x329feb3ab062d289/BreakingT_NFT.cdc"

import DGD_NFT from "../0x329feb3ab062d289/DGD_NFT.cdc"

import FLOAT from "../0x2d4c3caffbeab845/FLOAT.cdc"

import GoatedGoats from "../0x2068315349bdfce5/GoatedGoats.cdc"

import GoatedGoatsTrait from "../0x2068315349bdfce5/GoatedGoatsTrait.cdc"

import GogoroCollectible from "../0x8c9bbcdcd7514081/GogoroCollectible.cdc"

import MatrixWorldAssetsNFT from "../0xf20df769e658c257/MatrixWorldAssetsNFT.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import Metaverse from "../0x256599e1b091be12/Metaverse.cdc"

import Momentables from "../0x9d21537544d9123d/Momentables.cdc"

import NftReality from "../0x5892036f9111fbb8/NftReality.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import NowggNFT from "../0x85b8bbf926dcddfa/NowggNFT.cdc"

import SomePlaceCollectible from "../0x667a16294a089ef8/SomePlaceCollectible.cdc"

import The_Next_Cartel_NFT from "../0x329feb3ab062d289/The_Next_Cartel_NFT.cdc"

import YahooCollectible from "../0x758252ab932a3416/YahooCollectible.cdc"

import YahooPartnersCollectible from "../0x758252ab932a3416/YahooPartnersCollectible.cdc"

/*
	A wrapper contract around the script provided by the Alchemy GitHub respository.
	Allows for on-chain storage of NFT Metadata, allowing consumers to query upon.
	This contract will be periodically updated based on new onboarding PRs and deployed.
	Any consumers calling the public methods below will retrieve the latest and greatest data.
*/

access(all)
contract AlchemyMetadataWrapperMainnetShard3{ 
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
	access(TMP_ENTITLEMENT_OWNER)
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
						continue
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
						continue
					case "Gooberz":
						continue
					case "MintStoreItem":
						continue
					case "BiscuitsNGroovy":
						continue
					case "GeniaceNFT":
						continue
					case "Xtingles":
						continue
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
						continue
					case "OneFootballCollectible":
						continue
					case "TheFabricantMysteryBox_FF1":
						continue
					case "DieselNFT":
						continue
					case "MiamiNFT":
						continue
					case "Bitku":
						continue
					case "FlowFans":
						continue
					case "AllDay":
						continue
					case "PackNFT":
						continue
					case "ItemNFT":
						continue
					case "TheFabricantS1ItemNFT":
						continue
					case "ZeedzINO":
						continue
					case "Kicks":
						continue
					case "BarterYardPack":
						continue
					case "BarterYardClubWerewolf":
						continue
					case "DayNFT":
						continue
					case "Costacos_NFT":
						continue
					case "Canes_Vault_NFT":
						continue
					case "AmericanAirlines_NFT":
						d = self.getAmericanAirlinesNFT(owner: owner, id: id)
					case "The_Next_Cartel_NFT":
						d = self.getTheNextCartelNFT(owner: owner, id: id)
					case "Atheletes_Unlimited_NFT":
						d = self.getAthletesUnlimitedNFT(owner: owner, id: id)
					case "Art_NFT":
						d = self.getArtNFT(owner: owner, id: id)
					case "DGD_NFT":
						d = self.getDGDNFT(owner: owner, id: id)
					case "NowggNFT":
						d = self.getNowggNFT(owner: owner, id: id)
					case "GogoroCollectible":
						d = self.getGogoroCollectibleNFT(owner: owner, id: id)
					case "YahooCollectible":
						d = self.getYahooCollectibleNFT(owner: owner, id: id)
					case "YahooPartnersCollectible":
						d = self.getYahooPartnersCollectibleNFT(owner: owner, id: id)
					case "BlindBoxRedeemVoucher":
						d = self.getBlindBoxRedeemVoucherNFT(owner: owner, id: id)
					case "SomePlaceCollectible":
						d = self.getSomePlaceCollectibleNFT(owner: owner, id: id)
					case "ARTIFACTPack":
						d = self.getARTIFACTPack(owner: owner, id: id)
					case "ARTIFACT":
						d = self.getARTIFACT(owner: owner, id: id)
					case "NftReality":
						d = self.getNftRealityNFT(owner: owner, id: id)
					case "MatrixWorldAssetsNFT":
						d = self.getNftMatrixWorldAssetsNFT(owner: owner, id: id)
					case "TuneGO":
						continue
					case "TicalUniverse":
						continue
					case "RacingTime":
						continue
					case "Momentables":
						d = self.getMomentables(owner: owner, id: id)
					case "GoatedGoats":
						d = self.getGoatedGoats(owner: owner, id: id)
					case "GoatedGoatsTrait":
						d = self.getGoatedGoatsTrait(owner: owner, id: id)
					case "DropzToken":
						continue
					case "Necryptolis":
						continue
					case "FLOAT":
						d = self.getFLOAT(owner: owner, id: id)
					case "BreakingT_NFT":
						d = self.getBreakingTNFT(owner: owner, id: id)
					case "Owners":
						continue
					case "Metaverse":
						d = self.getOzoneMetaverseNFT(owner: owner, id: id)
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
	
	access(TMP_ENTITLEMENT_OWNER)
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
	access(TMP_ENTITLEMENT_OWNER)
	fun getAmericanAirlinesNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "AmericanAirlines_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "AmericanAirlines_NFT.CollectionStoragePath",
				public_path: "AmericanAirlines_NFT.CollectionPublicPath",
				public_collection_name: "AmericanAirlines_NFT.AmericanAirlines_NFT",
				external_domain: ""
			)
		let col =
			owner.capabilities.get<&{AmericanAirlines_NFT.AmericanAirlines_NFTCollectionPublic}>(
				AmericanAirlines_NFT.CollectionPublicPath
			).borrow<&{AmericanAirlines_NFT.AmericanAirlines_NFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowAmericanAirlines_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = AmericanAirlines_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			AmericanAirlines_NFT.getSeriesMetadata(
				seriesId: AmericanAirlines_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = AmericanAirlines_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = AmericanAirlines_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://americanairlines.nftbridge.com/tokens/".concat((nft!).id.toString())
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (setMeta!)["name"],
			description: (setMeta!)["description"],
			external_domain_view_url: externalTokenViewUrl,
			token_uri: nil,
			media: [
				NFTMedia(uri: (setMeta!)["image"], mimetype: (setMeta!)["image_file_type"]),
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
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/The_Next_Cartel_NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getTheNextCartelNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "The_Next_Cartel_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "The_Next_Cartel_NFT.CollectionStoragePath",
				public_path: "The_Next_Cartel_NFT.CollectionPublicPath",
				public_collection_name: "The_Next_Cartel_NFT.The_Next_Cartel_NFT",
				external_domain: "https://thenextcartel.com/nft-store"
			)
		let col =
			owner.capabilities.get<&{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(
				The_Next_Cartel_NFT.CollectionPublicPath
			).borrow<&{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowThe_Next_Cartel_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = The_Next_Cartel_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			The_Next_Cartel_NFT.getSeriesMetadata(
				seriesId: The_Next_Cartel_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = The_Next_Cartel_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = The_Next_Cartel_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://thenextcartel.shops.nftbridge.com/tokens/".concat((nft!).id.toString())
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
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/Atheletes_Unlimited_NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getAthletesUnlimitedNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Atheletes_Unlimited_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "Atheletes_Unlimited_NFT.CollectionStoragePath",
				public_path: "Atheletes_Unlimited_NFT.CollectionPublicPath",
				public_collection_name: "Atheletes_Unlimited_NFT.Atheletes_Unlimited_NFT",
				external_domain: "https://nft.auprosports.com/"
			)
		let col =
			owner.capabilities.get<
				&{Atheletes_Unlimited_NFT.Atheletes_Unlimited_NFTCollectionPublic}
			>(Atheletes_Unlimited_NFT.CollectionPublicPath).borrow<
				&{Atheletes_Unlimited_NFT.Atheletes_Unlimited_NFTCollectionPublic}
			>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowAtheletes_Unlimited_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = Atheletes_Unlimited_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			Atheletes_Unlimited_NFT.getSeriesMetadata(
				seriesId: Atheletes_Unlimited_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = Atheletes_Unlimited_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = Atheletes_Unlimited_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://nft.auprosports.com/tokens/".concat((nft!).id.toString())
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
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/Art_NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getArtNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Art_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "Art_NFT.CollectionStoragePath",
				public_path: "Art_NFT.CollectionPublicPath",
				public_collection_name: "Art_NFT.Art_NFT",
				external_domain: ""
			)
		let col =
			owner.capabilities.get<&{Art_NFT.Art_NFTCollectionPublic}>(Art_NFT.CollectionPublicPath)
				.borrow<&{Art_NFT.Art_NFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowArt_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = Art_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			Art_NFT.getSeriesMetadata(seriesId: Art_NFT.getSetSeriesId(setId: (nft!).setId)!)
		let seriesId = Art_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = Art_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl = "https://art.nftbridge.com/tokens/".concat((nft!).id.toString())
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
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/DGD_NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getDGDNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "DGD_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "DGD_NFT.CollectionStoragePath",
				public_path: "DGD_NFT.CollectionPublicPath",
				public_collection_name: "DGD_NFT.DGD_NFT",
				external_domain: "https://www.theplayerslounge.io/"
			)
		let col =
			owner.capabilities.get<&{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
				.borrow<&{DGD_NFT.DGD_NFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowDGD_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = DGD_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			DGD_NFT.getSeriesMetadata(seriesId: DGD_NFT.getSetSeriesId(setId: (nft!).setId)!)
		let seriesId = DGD_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = DGD_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://app.theplayerslounge.io/tokens/".concat((nft!).id.toString())
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
	
	// https://flow-view-source.com/mainnet/account/0x8c9bbcdcd7514081/contract/GogoroCollectible
	access(TMP_ENTITLEMENT_OWNER)
	fun getGogoroCollectibleNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "GogoroCollectible",
				address: 0x8c9bbcdcd7514081,
				storage_path: "GogoroCollectible.CollectionStoragePath",
				public_path: "GogoroCollectible.CollectionPublicPath",
				public_collection_name: "GogoroCollectible.CollectionPublic",
				external_domain: "https://www.gogoro.com/"
			)
		let col =
			owner.capabilities.get<&{GogoroCollectible.CollectionPublic}>(
				GogoroCollectible.CollectionPublicPath
			).borrow<&{GogoroCollectible.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowGogoroCollectible(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()!
		let additional = metadata.getAdditional()
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata.name,
			description: metadata.description,
			external_domain_view_url: "https://bay.blocto.app/flow/gogoro/".concat(
				(nft!).id.toString()
			),
			token_uri: nil,
			media: [NFTMedia(uri: additional["mediaUrl"]!, mimetype: metadata.mediaType)],
			metadata:{ 
				"rarity": additional["rarity"]!,
				"editionNumber": (nft!).editionNumber.toString(),
				"editionCount": metadata.itemCount.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x758252ab932a3416/contract/YahooCollectible
	access(TMP_ENTITLEMENT_OWNER)
	fun getYahooCollectibleNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "YahooCollectible",
				address: 0x758252ab932a3416,
				storage_path: "YahooCollectible.CollectionStoragePath",
				public_path: "YahooCollectible.CollectionPublicPath",
				public_collection_name: "YahooCollectible.CollectionPublic",
				external_domain: "https://tw.yahoo.com/"
			)
		let col =
			owner.capabilities.get<&{YahooCollectible.CollectionPublic}>(
				YahooCollectible.CollectionPublicPath
			).borrow<&{YahooCollectible.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowYahooCollectible(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()!
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata.name,
			description: metadata.description,
			external_domain_view_url: "https://bay.blocto.app/flow/yahoo/".concat(
				(nft!).id.toString()
			),
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://ipfs.io/ipfs/".concat(metadata.mediaHash),
					mimetype: metadata.mediaType
				)
			],
			metadata:{ 
				"rarity": metadata.getAdditional()["rarity"]!,
				"editionNumber": (nft!).editionNumber.toString(),
				"editionCount": metadata.itemCount.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x758252ab932a3416/contract/YahooPartnersCollectible
	access(TMP_ENTITLEMENT_OWNER)
	fun getYahooPartnersCollectibleNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "YahooPartnersCollectible",
				address: 0x758252ab932a3416,
				storage_path: "YahooPartnersCollectible.CollectionStoragePath",
				public_path: "YahooPartnersCollectible.CollectionPublicPath",
				public_collection_name: "YahooPartnersCollectible.CollectionPublic",
				external_domain: "https://tw.yahoo.com/"
			)
		let col =
			owner.capabilities.get<&{YahooPartnersCollectible.CollectionPublic}>(
				YahooPartnersCollectible.CollectionPublicPath
			).borrow<&{YahooPartnersCollectible.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowYahooPartnersCollectible(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()!
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata.name,
			description: metadata.description,
			external_domain_view_url: "https://bay.blocto.app/flow/yahoo-partners/".concat(
				(nft!).id.toString()
			),
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://ipfs.io/ipfs/".concat(metadata.mediaHash),
					mimetype: metadata.mediaType
				)
			],
			metadata:{ 
				"rarity": metadata.getAdditional()["rarity"]!,
				"editionNumber": (nft!).editionNumber.toString(),
				"editionCount": metadata.itemCount.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x910514afa41bfeac/contract/BlindBoxRedeemVoucher
	access(TMP_ENTITLEMENT_OWNER)
	fun getBlindBoxRedeemVoucherNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "BlindBoxRedeemVoucher",
				address: 0x910514afa41bfeac,
				storage_path: "BlindBoxRedeemVoucher.CollectionStoragePath",
				public_path: "BlindBoxRedeemVoucher.CollectionPublicPath",
				public_collection_name: "BlindBoxRedeemVoucher.CollectionPublic",
				external_domain: "https://flow.com/"
			)
		let col =
			owner.capabilities.get<&{BlindBoxRedeemVoucher.CollectionPublic}>(
				BlindBoxRedeemVoucher.CollectionPublicPath
			).borrow<&{BlindBoxRedeemVoucher.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowBlindBoxRedeemVoucher(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()!
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata.name,
			description: metadata.description,
			external_domain_view_url: "https://bay.blocto.app/flow/blindbox-voucher/".concat(
				(nft!).id.toString()
			),
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://ipfs.io/ipfs/".concat(metadata.mediaHash),
					mimetype: metadata.mediaType
				)
			],
			metadata:{ 
				"rarity": metadata.getAdditional()["rarity"]!,
				"editionNumber": (nft!).editionNumber.toString(),
				"editionCount": metadata.itemCount.toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x85b8bbf926dcddfa/contract/NowggNFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getNowggNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "NowggNFT",
				address: 0x85b8bbf926dcddfa,
				storage_path: "NowggNFT.CollectionStoragePath",
				public_path: "NowggNFT.CollectionPublicPath",
				public_collection_name: "NowggNFT.NowggNFTCollectionPublic",
				external_domain: "https://nft.now.gg/"
			)
		let col =
			owner.capabilities.get<&{NowggNFT.NowggNFTCollectionPublic}>(
				NowggNFT.CollectionPublicPath
			).borrow<&{NowggNFT.NowggNFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowNowggNFT(id: id)
		if nft == nil{ 
			return nil
		}
		let nftInfo = nft!
		let metadata = nftInfo.getMetadata()!
		let nftTypeId = metadata["nftTypeId"]! as! String
		let externalViewUrl = "https://nft.now.gg/nft/".concat(nftTypeId)
		return NFTData(
			_contract: _contract,
			id: nftInfo.id,
			uuid: nftInfo.uuid,
			title: metadata["title"]! as? String,
			description: metadata["description"]! as? String,
			external_domain_view_url: externalViewUrl,
			token_uri: nil,
			media: [
				NFTMedia(
					uri: metadata["displayUrl"]! as? String,
					mimetype: metadata["displayUrlMediaType"]! as? String
				),
				NFTMedia(
					uri: metadata["contentUrl"]! as? String,
					mimetype: metadata["contentType"]! as? String
				)
			],
			metadata:{ 
				"clientName": metadata["clientName"]! as? String,
				"nftTypeId": metadata["nftTypeId"]! as? String,
				"creatorName": metadata["creatorName"]! as? String,
				"clientId": metadata["clientId"]! as? String,
				"maxCount": ((metadata["maxCount"]! as? UInt64)!).toString(),
				"copyNumber": ((metadata["copyNumber"]! as? UInt64)!).toString()
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x667a16294a089ef8/contract/SomePlaceCollectible
	access(TMP_ENTITLEMENT_OWNER)
	fun getSomePlaceCollectibleNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "SomePlaceCollectible",
				address: 0x667a16294a089ef8,
				storage_path: "SomePlaceCollectible.CollectionStoragePath",
				public_path: "SomePlaceCollectible.CollectionPublicPath",
				public_collection_name: "SomePlaceCollectible.CollectibleCollectionPublic",
				external_domain: "https://some.place"
			)
		let col =
			owner.capabilities.get<&{SomePlaceCollectible.CollectibleCollectionPublic}>(
				SomePlaceCollectible.CollectionPublicPath
			).borrow<&{SomePlaceCollectible.CollectibleCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let optNft = (col!).borrowCollectible(id: id)
		if optNft == nil{ 
			return nil
		}
		let nft = optNft!
		let setID = nft.setID
		let setMetadata = SomePlaceCollectible.getMetadataForSetID(setID: setID)!
		let editionMetadata = SomePlaceCollectible.getMetadataForNFTByUUID(uuid: nft.id)!
		return NFTData(
			_contract: _contract,
			id: nft.id,
			uuid: nft.uuid,
			title: editionMetadata.getMetadata()["title"]
			?? setMetadata.getMetadata()["title"] ?? "",
			description: editionMetadata.getMetadata()["description"]
			?? setMetadata.getMetadata()["description"] ?? "",
			external_domain_view_url: "https://some.place",
			token_uri: nil,
			media: [
				NFTMedia(
					uri: editionMetadata.getMetadata()["mediaURL"]
					?? setMetadata.getMetadata()["mediaURL"] ?? "",
					mimetype: "image"
				)
			],
			metadata:{ 
				"editionNumber": nft.editionNumber.toString(),
				"editionCount": setMetadata.getMaxNumberOfEditions().toString(),
				"royaltyAddress": "0x8e2e0ebf3c03aa88",
				"royaltyPercentage": "10.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x24de869c5e40b2eb/contract/ARTIFACT
	access(TMP_ENTITLEMENT_OWNER)
	fun getARTIFACT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "ARTIFACT",
				address: 0x24de869c5e40b2eb,
				storage_path: "ARTIFACT.collectionStoragePath",
				public_path: "ARTIFACT.collectionPublicPath",
				public_collection_name: "ARTIFACT.CollectionPublic",
				external_domain: "https://artifact.scmp.com/"
			)
		let col =
			owner.capabilities.get<&{ARTIFACT.CollectionPublic}>(ARTIFACT.collectionPublicPath)
				.borrow<&{ARTIFACT.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrow(id: id)
		if nft == nil{ 
			return nil
		}
		var metadata = (nft!).data.metadata
		let title = metadata["artifactName"]!
		let description = metadata["artifactShortDescription"]!
		let series = metadata["artifactLookupId"]!
		metadata["editionNumber"] = metadata["artifactEditionNumber"]!
		metadata["editionCount"] = metadata["artifactNumberOfEditions"]!
		metadata["royaltyAddress"] = "0xe9e563d7021d6eda"
		metadata["royaltyPercentage"] = "10.0"
		metadata["rarity"] = metadata["artifactRarityLevel"]!
		let rawMetadata:{ String: String?} ={} 
		for key in metadata.keys{ 
			rawMetadata.insert(key: key, metadata[key])
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: title,
			description: description,
			external_domain_view_url: "https://artifact.scmp.com/".concat(series),
			token_uri: nil,
			media: [NFTMedia(uri: metadata["artifactFileUri"], mimetype: "video/mp4")],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x24de869c5e40b2eb/contract/ARTIFACTPack
	access(TMP_ENTITLEMENT_OWNER)
	fun getARTIFACTPack(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "ARTIFACTPack",
				address: 0x24de869c5e40b2eb,
				storage_path: "ARTIFACTPack.collectionStoragePath",
				public_path: "ARTIFACTPack.collectionPublicPath",
				public_collection_name: "ARTIFACTPack.CollectionPublic",
				external_domain: "https://artifact.scmp.com/"
			)
		let col =
			owner.capabilities.get<&{ARTIFACTPack.CollectionPublic}>(
				ARTIFACTPack.collectionPublicPath
			).borrow<&{ARTIFACTPack.CollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrow(id: id)
		if nft == nil{ 
			return nil
		}
		var description = ""
		var mediaUri = ""
		let isOpen = (nft!).isOpen
		var metadata = (nft!).metadata
		var series = metadata["lookupId"]!
		var title = metadata["name"]!
		if isOpen{ 
			description = metadata["descriptionOpened"]!
			mediaUri = metadata["fileUriOpened"]!
		} else{ 
			description = metadata["descriptionUnopened"]!
			mediaUri = metadata["fileUriUnopened"]!
		}
		metadata["editionNumber"] = (nft!).edition.toString()
		metadata["editionCount"] = metadata["numberOfEditions"]!
		metadata["royaltyAddress"] = "0xe9e563d7021d6eda"
		metadata["royaltyPercentage"] = "10.0"
		metadata["rarity"] = metadata["rarityLevel"]!
		let rawMetadata:{ String: String?} ={} 
		for key in metadata.keys{ 
			rawMetadata.insert(key: key, metadata[key])
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: title,
			description: description,
			external_domain_view_url: "https://artifact.scmp.com/".concat(series),
			token_uri: nil,
			media: [NFTMedia(uri: mediaUri, mimetype: "image/png")],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x5892036f9111fbb8/contract/NftReality
	access(TMP_ENTITLEMENT_OWNER)
	fun getNftRealityNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "NftReality",
				address: 0x5892036f9111fbb8,
				storage_path: "NftReality.CollectionStoragePath",
				public_path: "NftReality.CollectionPublicPath",
				public_collection_name: "NftReality.NftRealityCollectionPublic",
				external_domain: "nftreality.pl"
			)
		let col =
			owner.capabilities.get<&{NftReality.NftRealityCollectionPublic}>(
				NftReality.CollectionPublicPath
			).borrow<&{NftReality.NftRealityCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowNftReality(id: id)
		if nft == nil{ 
			return nil
		}
		let displayView = (nft!).resolveView(Type<MetadataViews.Display>())!
		let display = displayView as! MetadataViews.Display
		let metadataView = (nft!).resolveView(Type<NftReality.NftRealityMetadataView>())!
		let metadata = metadataView as! NftReality.NftRealityMetadataView
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: display.name,
			description: display.description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://ipfs.io/ipfs/".concat(metadata.artwork).concat("/").concat(
						"artwork"
					),
					mimetype: "image"
				)
			],
			metadata:{ 
				"editionNumber": metadata.unit.toString(),
				"editionCount": metadata.totalUnits.toString(),
				"company": metadata.company,
				"role": metadata.role,
				"description": metadata.description,
				"artwork": metadata.artwork,
				"logotype": metadata.logotype,
				"creator": metadata.creator,
				"creationDate": metadata.creationDate
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0xf20df769e658c257/contract/MatrixWorldAssetsNFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getNftMatrixWorldAssetsNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "MatrixWorldAssetsNFT",
				address: 0xf20df769e658c257,
				storage_path: "MatrixWorldAssetsNFT.collectionStoragePath",
				public_path: "MatrixWorldAssetsNFT.collectionPublicPath",
				public_collection_name: "NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MatrixWorldAssetsNFT.Metadata", // interfaces required for initialization
				
				external_domain: "https://matrixworld.org"
			)
		let col =
			owner.capabilities.get<
				&{MatrixWorldAssetsNFT.Metadata, NonFungibleToken.CollectionPublic}
			>(MatrixWorldAssetsNFT.collectionPublicPath).borrow<
				&{MatrixWorldAssetsNFT.Metadata, NonFungibleToken.CollectionPublic}
			>()
			?? panic("NFT Collection not found")
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowNFT(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = col.getMetadata(id: id)
		let rawMetadata:{ String: String?} ={} 
		for key in metadata.keys{ 
			rawMetadata.insert(key: key, metadata[key])
		}
		return NFTData(
			_contract: _contract,
			id: id,
			uuid: nft.uuid,
			title: metadata["name"],
			description: metadata["description"],
			external_domain_view_url: "https://matrixworld.org/profile",
			token_uri: nil,
			media: [NFTMedia(uri: metadata["image"], mimetype: "image")],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x8d4fa88ffa2d9117/contract/RacingTime
	access(TMP_ENTITLEMENT_OWNER)
	fun getMomentables(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Momentables",
				address: 0x9d21537544d9123d,
				storage_path: "Momentables.CollectionStoragePath",
				public_path: "Momentables.CollectionPublicPath",
				public_collection_name: "Momentables.MomentablesCollectionPublic",
				external_domain: "https://nextdecentrum.com"
			)
		let col =
			owner.capabilities.get<&{Momentables.MomentablesCollectionPublic}>(
				Momentables.CollectionPublicPath
			).borrow<&{Momentables.MomentablesCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowMomentables(id: id)
		if nft == nil{ 
			return nil
		}
		
		//let metadata = Gaia.getTemplateMetaData(templateID: nft!.data.templateID)
		let ipfsURL = "https://gateway.pinata.cloud/ipfs/".concat((nft!).imageCID)
		let traits = (nft!).getTraits()
		let rawMetadata:{ String: String?} ={} 
		
		// Core metadata attributes
		rawMetadata.insert(key: "editionNumber", (nft!).id.toString())
		rawMetadata.insert(key: "editionCount", "7006")
		rawMetadata.insert(key: "royaltyAddress", "0x7dc1aa82a2f8d409")
		rawMetadata.insert(key: "royaltyPercentage", "10.1")
		
		// NFT Traits metadata
		for key in traits.keys{ 
			let currentTrait = traits[key]!
			for currentTraitKey in currentTrait.keys{ 
				rawMetadata.insert(key: key.concat("-").concat(currentTraitKey), currentTrait[currentTraitKey])
			}
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: (nft!).name,
			description: (nft!).description,
			external_domain_view_url: nil,
			token_uri: nil,
			media: [NFTMedia(uri: ipfsURL, mimetype: "image")],
			metadata:{ 
				"editionNumber": (nft!).id.toString(),
				"editionCount": "7006",
				"royaltyAddress": "0x7dc1aa82a2f8d409",
				"royaltyPercentage": "10.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x2068315349bdfce5/contract/GoatedGoats
	access(TMP_ENTITLEMENT_OWNER)
	fun getGoatedGoats(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "GoatedGoats",
				address: 0x2068315349bdfce5,
				storage_path: "GoatedGoats.CollectionStoragePath",
				public_path: "GoatedGoats.CollectionPublicPath",
				public_collection_name: "GoatedGoats.GoatCollectionPublic",
				external_domain: "https://goatedgoats.com/"
			)
		let col =
			owner.capabilities.get<
				&{ViewResolver.ResolverCollection, GoatedGoats.GoatCollectionPublic}
			>(GoatedGoats.CollectionPublicPath).borrow<
				&{MetadataViews.ResolverCollection, GoatedGoats.GoatCollectionPublic}
			>()
		if col == nil{ 
			return nil
		}
		let optNft = (col!).borrowGoat(id: id)
		if optNft == nil{ 
			return nil
		}
		let nft = optNft!
		let displayView = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		return NFTData(
			_contract: _contract,
			id: nft.id,
			uuid: nft.uuid,
			title: displayView.name,
			description: displayView.description,
			external_domain_view_url: "https://goatedgoats.com",
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://goatedgoats.mypinata.cloud/ipfs/".concat(
						(displayView.thumbnail as! MetadataViews.IPFSFile).cid
					),
					mimetype: "image"
				)
			],
			metadata:{ 
				"editionNumber": nft.goatID.toString(),
				"editionCount": "10000",
				"royaltyAddress": "0xd7081a5c66dc3e7f",
				"royaltyPercentage": "5.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x2068315349bdfce5/contract/GoatedGoatsTrait
	access(TMP_ENTITLEMENT_OWNER)
	fun getGoatedGoatsTrait(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "GoatedGoatsTrait",
				address: 0x2068315349bdfce5,
				storage_path: "GoatedGoatsTrait.CollectionStoragePath",
				public_path: "GoatedGoatsTrait.CollectionPublicPath",
				public_collection_name: "GoatedGoatsTrait.TraitCollectionPublic",
				external_domain: "https://goatedgoats.com/"
			)
		let col =
			owner.capabilities.get<
				&{ViewResolver.ResolverCollection, GoatedGoatsTrait.TraitCollectionPublic}
			>(GoatedGoatsTrait.CollectionPublicPath).borrow<
				&{MetadataViews.ResolverCollection, GoatedGoatsTrait.TraitCollectionPublic}
			>()
		if col == nil{ 
			return nil
		}
		let optNft = (col!).borrowTrait(id: id)
		if optNft == nil{ 
			return nil
		}
		let nft = optNft!
		let displayView = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		return NFTData(
			_contract: _contract,
			id: nft.id,
			uuid: nft.uuid,
			title: displayView.name,
			description: displayView.description,
			external_domain_view_url: "https://goatedgoats.com",
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://goatedgoats.mypinata.cloud/ipfs/".concat(
						(displayView.thumbnail as! MetadataViews.IPFSFile).cid
					),
					mimetype: "image"
				)
			],
			metadata:{ 
				"editionNumber": nft.id.toString(),
				"editionCount": GoatedGoatsTrait.totalSupply.toString(),
				"royaltyAddress": "0xd7081a5c66dc3e7f",
				"royaltyPercentage": "5.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x2ba17360b76f0143/contract/DropzToken
	access(TMP_ENTITLEMENT_OWNER)
	fun getFLOAT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "FLOAT",
				address: 0x2d4c3caffbeab845,
				storage_path: "FLOAT.FLOATCollectionStoragePath",
				public_path: "FLOAT.FLOATCollectionPublicPath",
				public_collection_name: "FLOAT.CollectionPublic",
				external_domain: "https://floats.city/"
			)
		let col =
			owner.capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<
				&FLOAT.Collection
			>()
		if col == nil{ 
			return nil
		}
		let float = (col!).borrowFLOAT(id: id)
		if float == nil{ 
			return nil
		}
		let display = (float!).resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
		return NFTData(
			_contract: _contract,
			id: (float!).id,
			uuid: (float!).uuid,
			title: display.name,
			description: display.description,
			external_domain_view_url: "https://floats.city/".concat(
				(owner.address as Address).toString()
			).concat("/float/").concat((float!).id.toString()),
			token_uri: nil,
			media: [
				NFTMedia(
					uri: "https://nftstorage.link/ipfs/".concat((float!).eventImage),
					mimetype: "image"
				)
			],
			metadata:{ 
				"eventName": (float!).eventName,
				"eventDescription": (float!).eventDescription,
				"eventHost": ((float!).eventHost as Address).toString(),
				"eventId": (float!).eventId.toString(),
				"eventImage": (float!).eventImage,
				"serial": (float!).serial.toString(),
				"dateReceived": (float!).dateReceived.toString(),
				"royaltyAddress": "0x5643fd47a29770e7",
				"royaltyPercentage": "5.0"
			}
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x329feb3ab062d289/contract/BreakingT_NFT
	access(TMP_ENTITLEMENT_OWNER)
	fun getBreakingTNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "BreakingT_NFT",
				address: 0x329feb3ab062d289,
				storage_path: "BreakingT_NFT.CollectionStoragePath",
				public_path: "BreakingT_NFT.CollectionPublicPath",
				public_collection_name: "BreakingT_NFT.BreakingT_NFT",
				external_domain: "https://breakingt.com/"
			)
		let col =
			owner.capabilities.get<&{BreakingT_NFT.BreakingT_NFTCollectionPublic}>(
				BreakingT_NFT.CollectionPublicPath
			).borrow<&{BreakingT_NFT.BreakingT_NFTCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowBreakingT_NFT(id: id)
		if nft == nil{ 
			return nil
		}
		let setMeta = BreakingT_NFT.getSetMetadata(setId: (nft!).setId)!
		let seriesMeta =
			BreakingT_NFT.getSeriesMetadata(
				seriesId: BreakingT_NFT.getSetSeriesId(setId: (nft!).setId)!
			)
		let seriesId = BreakingT_NFT.getSetSeriesId(setId: (nft!).setId)!
		let nftEditions = BreakingT_NFT.getSetMaxEditions(setId: (nft!).setId)!
		let externalTokenViewUrl =
			"https://marketplace.breakingt.com/tokens/".concat((nft!).id.toString())
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
	
	// https://flow-view-source.com/mainnet/account/0x41cad19decccdf25/contract/Owners
	access(TMP_ENTITLEMENT_OWNER)
	fun getOzoneMetaverseNFT(owner: &Account, id: UInt64): NFTData?{ 
		let _contract =
			NFTContractData(
				name: "Metaverse",
				address: 0x256599e1b091be12,
				storage_path: "Metaverse.CollectionStoragePath",
				public_path: "Metaverse.CollectionPublicPath",
				public_collection_name: "Metaverse.MetaverseCollectionPublic",
				external_domain: "https://ozonemetaverse.io"
			)
		let col =
			owner.capabilities.get<&{Metaverse.MetaverseCollectionPublic}>(
				Metaverse.CollectionPublicPath
			).borrow<&{Metaverse.MetaverseCollectionPublic}>()
		if col == nil{ 
			return nil
		}
		let nft = (col!).borrowMetaverse(id: id)
		if nft == nil{ 
			return nil
		}
		let metadata = (nft!).getMetadata()
		if metadata == nil{ 
			return nil
		}
		let rawMetadata:{ String: String?} ={} 
		for key in metadata.keys{ 
			rawMetadata.insert(key: key, metadata[key])
		}
		if !metadata.containsKey("editionNumber"){ 
			rawMetadata.insert(key: "editionNumber", (nft!).id.toString())
		}
		if !metadata.containsKey("editionCount"){ 
			rawMetadata.insert(key: "editionCount", Metaverse.totalSupply.toString())
		}
		if !metadata.containsKey("royaltyAddress"){ 
			rawMetadata.insert(key: "royaltyAddress", "0xbf8ada6bb945651f")
		}
		if !metadata.containsKey("royaltyPercentage"){ 
			rawMetadata.insert(key: "royaltyPercentage", "10.0")
		}
		return NFTData(
			_contract: _contract,
			id: (nft!).id,
			uuid: (nft!).uuid,
			title: metadata["name"],
			description: metadata["description"],
			external_domain_view_url: metadata["url"],
			token_uri: nil,
			media: [
				NFTMedia(uri: metadata["videoUrl"], mimetype: metadata["videoMimeType"]),
				NFTMedia(uri: metadata["imageUrl"], mimetype: metadata["imageMimeType"])
			],
			metadata: rawMetadata
		)
	}
	
	// https://flow-view-source.com/mainnet/account/0x1e075b24abe6eca6/contract/NFTContract
	// Same method signature as getNFTIDs.cdc for backwards-compatability.
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTIDs(ownerAddress: Address):{ String: [UInt64]}{ 
		let owner = getAccount(ownerAddress)
		let ids:{ String: [UInt64]} ={} 
		if let col =
			owner.capabilities.get<&{AmericanAirlines_NFT.AmericanAirlines_NFTCollectionPublic}>(
				AmericanAirlines_NFT.CollectionPublicPath
			).borrow<&{AmericanAirlines_NFT.AmericanAirlines_NFTCollectionPublic}>(){ 
			ids["AmericanAirlines_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(
				The_Next_Cartel_NFT.CollectionPublicPath
			).borrow<&{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(){ 
			ids["The_Next_Cartel_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<
				&{Atheletes_Unlimited_NFT.Atheletes_Unlimited_NFTCollectionPublic}
			>(Atheletes_Unlimited_NFT.CollectionPublicPath).borrow<
				&{Atheletes_Unlimited_NFT.Atheletes_Unlimited_NFTCollectionPublic}
			>(){ 
			ids["Atheletes_Unlimited_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{Art_NFT.Art_NFTCollectionPublic}>(Art_NFT.CollectionPublicPath)
				.borrow<&{Art_NFT.Art_NFTCollectionPublic}>(){ 
			ids["Art_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
				.borrow<&{DGD_NFT.DGD_NFTCollectionPublic}>(){ 
			ids["DGD_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NowggNFT.NowggNFTCollectionPublic}>(
				NowggNFT.CollectionPublicPath
			).borrow<&{NowggNFT.NowggNFTCollectionPublic}>(){ 
			ids["NowggNFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{GogoroCollectible.CollectionPublic}>(
				GogoroCollectible.CollectionPublicPath
			).borrow<&{GogoroCollectible.CollectionPublic}>(){ 
			ids["GogoroCollectible"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{YahooCollectible.CollectionPublic}>(
				YahooCollectible.CollectionPublicPath
			).borrow<&{YahooCollectible.CollectionPublic}>(){ 
			ids["YahooCollectible"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{YahooPartnersCollectible.CollectionPublic}>(
				YahooPartnersCollectible.CollectionPublicPath
			).borrow<&{YahooPartnersCollectible.CollectionPublic}>(){ 
			ids["YahooPartnersCollectible"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{BlindBoxRedeemVoucher.CollectionPublic}>(
				BlindBoxRedeemVoucher.CollectionPublicPath
			).borrow<&{BlindBoxRedeemVoucher.CollectionPublic}>(){ 
			ids["BlindBoxRedeemVoucher"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				SomePlaceCollectible.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>(){ 
			ids["SomePlaceCollectible"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{ARTIFACTPack.CollectionPublic}>(
				ARTIFACTPack.collectionPublicPath
			).borrow<&{ARTIFACTPack.CollectionPublic}>(){ 
			ids["ARTIFACTPack"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{ARTIFACT.CollectionPublic}>(ARTIFACT.collectionPublicPath)
				.borrow<&{ARTIFACT.CollectionPublic}>(){ 
			ids["ARTIFACT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NftReality.NftRealityCollectionPublic}>(
				NftReality.CollectionPublicPath
			).borrow<&{NftReality.NftRealityCollectionPublic}>(){ 
			ids["NftReality"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				MatrixWorldAssetsNFT.collectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>(){ 
			ids["MatrixWorldAssetsNFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{Momentables.MomentablesCollectionPublic}>(
				Momentables.CollectionPublicPath
			).borrow<&{Momentables.MomentablesCollectionPublic}>(){ 
			ids["Momentables"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				GoatedGoats.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>(){ 
			ids["GoatedGoats"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
				GoatedGoatsTrait.CollectionPublicPath
			).borrow<&{NonFungibleToken.CollectionPublic}>(){ 
			ids["GoatedGoatsTrait"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow<
				&FLOAT.Collection
			>(){ 
			ids["FLOAT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{BreakingT_NFT.BreakingT_NFTCollectionPublic}>(
				BreakingT_NFT.CollectionPublicPath
			).borrow<&{BreakingT_NFT.BreakingT_NFTCollectionPublic}>(){ 
			ids["BreakingT_NFT"] = col.getIDs()
		}
		if let col =
			owner.capabilities.get<&{Metaverse.MetaverseCollectionPublic}>(
				Metaverse.CollectionPublicPath
			).borrow<&{Metaverse.MetaverseCollectionPublic}>(){ 
			ids["Metaverse"] = col.getIDs()
		}
		return ids
	}
}
