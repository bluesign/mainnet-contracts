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

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract BloomlyNFT: NonFungibleToken{ 
	
	// Events
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event NFTDestroyed(id: UInt64, owner: Address?)
	
	access(all)
	event CollectionDestroyed(owner: Address?)
	
	access(all)
	event AdminCreated(address: Address)
	
	access(all)
	event AdminRemoved(address: Address)
	
	access(all)
	event BrandCreated(brandId: UInt64, brandName: String, registrationNo: String, authors: [Address], externalURL: String, data:{ String: String}, platormFee: UFix64)
	
	access(all)
	event BrandUpdated(brandId: UInt64, brandName: String, externalURL: String, data:{ String: String})
	
	access(all)
	event BrandNameUpdated(brandId: UInt64, brandName: String)
	
	access(all)
	event BrandAuthorUpdated(brandId: UInt64, authors: [Address])
	
	access(all)
	event BrandExternalUrlUpdated(brandId: UInt64, externalURL: String)
	
	access(all)
	event BrandDataUpdated(brandId: UInt64, data:{ String: String})
	
	access(all)
	event BrandPlatformFeeUpdated(brandId: UInt64, platormFee: UFix64)
	
	access(all)
	event BrandRoyaltiesAdded(brandId: UInt64)
	
	access(all)
	event BrandContributorsAdded(brandId: UInt64)
	
	access(all)
	event TemplateCreated(templateId: UInt64, brandId: UInt64, maxSupply: UInt64?, transferable: Bool, isRoyaltyEnabled: Bool)
	
	access(all)
	event TemplateRemoved(templateId: UInt64)
	
	access(all)
	event TemplateLocked(templateId: UInt64)
	
	access(all)
	event TemplateUpdated(templateId: UInt64)
	
	access(all)
	event NFTMinted(nftId: UInt64, brandId: UInt64, templateId: UInt64?, mintNumber: UInt64, name: String, description: String, thumbnail: String, isTransferable: Bool)
	
	// Paths
	access(all)
	var BrandAdminStoragePath: StoragePath
	
	access(all)
	var NFTMethodsCapabilityPrivatePath: PrivatePath
	
	access(all)
	var CollectionStoragePath: StoragePath
	
	access(all)
	var CollectionPublicPath: PublicPath
	
	access(all)
	var AdminStorageCapability: StoragePath
	
	access(all)
	var SuperAdminStoragePath: StoragePath
	
	// Latest brand-id
	access(all)
	var lastIssuedBrandId: UInt64
	
	// Latest template-id
	access(all)
	var lastIssuedTemplateId: UInt64
	
	// Total supply of all NFTs that are minted using this contract
	access(all)
	var totalSupply: UInt64
	
	// An array to store and manage admins
	access(account)
	var allAdmins: [Address]
	
	// A dictionary that stores all Brands against it's brand-id.
	access(self)
	var allBrands:{ UInt64: Brand}
	
	// A dictionary that stores all Templates against it's template-id.
	access(self)
	var allTemplates:{ UInt64: Template}
	
	// A dictionary that stores all NFTs against it's nft-id.
	access(self)
	var allNFTs:{ UInt64: NFTDataView}
	
	// A dictionary that stores all payouts against it's brand-id. e.g: {brand-id : {user-address: Payout}}
	access(self)
	var payouts:{ UInt64: Payout}
	
	// A structure that contain all payout related data
	access(all)
	struct Payout{ 
		access(all)
		var royalties: [MetadataViews.Royalty]
		
		access(all)
		var contributors:{ Address: UFix64} // receiver : cut
		
		
		init(royalties: [MetadataViews.Royalty], contributors:{ Address: UFix64}){ 
			self.royalties = royalties
			self.contributors = contributors
		}
	}
	
	// A structure that contain all the data related to a Brand
	access(all)
	struct Brand{ 
		access(all)
		let brandId: UInt64
		
		access(all)
		var brandName: String
		
		access(all)
		let registrationNo: String
		
		access(all)
		var authors: [Address]
		
		access(all)
		var externalURL: String
		
		access(all)
		var platormFee: UFix64
		
		access(contract)
		var data:{ String: String}
		
		access(contract)
		var templates: [UInt64]
		
		access(contract)
		var nfts: [UInt64]
		
		init(brandName: String, registrationNo: String, authors: [Address], externalURL: String, data:{ String: String}, platormFee: UFix64){ 
			pre{ 
				brandName.length > 0:
					"Brand name is required"
				registrationNo.length > 0:
					"Brand Registration No. is required"
				authors.length > 0:
					"Brand must have at least 1 author"
			}
			let newBrandId = BloomlyNFT.lastIssuedBrandId
			self.brandId = newBrandId
			self.brandName = brandName
			self.registrationNo = registrationNo
			self.authors = authors
			self.externalURL = externalURL
			self.data = data
			self.platormFee = platormFee
			self.templates = []
			self.nfts = []
		}
		
		//This method will update the brand data 
		access(TMP_ENTITLEMENT_OWNER)
		fun update(brandName: String, externalURL: String, data:{ String: String}){ 
			pre{ 
				externalURL.length > 0:
					"External url is required"
				brandName.length > 0:
					"Brand name is required"
				data.keys.length > 0:
					"Data must have at least 1 key"
			}
			self.brandName = brandName
			self.externalURL = externalURL
			self.data = data
		}
		
		//This method will update the brand name 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandName(brandName: String){ 
			pre{ 
				brandName.length > 0:
					"Brand name is required"
			}
			self.brandName = brandName
		}
		
		//This method will update the brand author 
		access(contract)
		fun updateBrandAuthor(authors: [Address]){ 
			pre{ 
				authors.length > 0:
					"Brand must have at least 1 author"
			}
			self.authors = authors
		}
		
		//This method will update the brand externanl url
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandExternalUrl(externalURL: String){ 
			pre{ 
				externalURL.length > 0:
					"External url is required"
			}
			self.externalURL = externalURL
		}
		
		//This method will update the brand data
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandData(data:{ String: String}){ 
			pre{ 
				data.keys.length > 0:
					"Data must have at least 1 key"
			}
			self.data = data
		}
		
		//This method will update the brand platform fee 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandPlatformFee(platormFee: UFix64){ 
			self.platormFee = platormFee
		}
		
		//This method will add template-id which is created under that brand
		access(contract)
		fun appendTemplateId(templateId: UInt64){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Invalid template id"
			}
			self.templates.append(templateId)
		}
		
		//This method will add nft-id which is created under that brand
		access(contract)
		fun appendNFTId(nftId: UInt64){ 
			pre{ 
				BloomlyNFT.allNFTs[nftId] != nil:
					"Invalid nft id"
			}
			self.nfts.append(nftId)
		}
		
		//This method will remove template 
		access(contract)
		fun removeTemplateId(templateId: UInt64){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Invalid template id"
				self.templates.contains(templateId):
					"Template does not exists in this brand"
			}
			self.templates.remove(at: self.templates.firstIndex(of: UInt64(templateId))!)
		}
		
		//This method will remove nft from brand 
		access(contract)
		fun removeNFTId(nftId: UInt64){ 
			pre{ 
				BloomlyNFT.allNFTs[nftId] != nil:
					"Invalid nft id"
				self.nfts.contains(nftId):
					"NFT does not exists in this brand"
			}
			self.nfts.remove(at: self.nfts.firstIndex(of: UInt64(nftId))!)
		}
		
		//A public method to provide all templates under that brand
		access(TMP_ENTITLEMENT_OWNER)
		fun getTemplates(): [UInt64]{ 
			return self.templates
		}
		
		//A public method to provide all nfts under that brand
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTs(): [UInt64]{ 
			return self.nfts
		}
		
		//A public method to provide data of brand
		access(TMP_ENTITLEMENT_OWNER)
		fun getData():{ String: String}{ 
			return self.data
		}
	}
	
	// A structure that contain all the data and methods related to Template
	access(all)
	struct Template{ 
		access(all)
		let templateId: UInt64
		
		access(all)
		let brandId: UInt64
		
		access(all)
		var maxSupply: UInt64?
		
		access(all)
		var issuedSupply: UInt64
		
		access(all)
		var locked: Bool
		
		access(all)
		var transferable: Bool
		
		access(all)
		var nfts: [UInt64]
		
		access(contract)
		var immutableData:{ String: AnyStruct}
		
		access(contract)
		var mutableData:{ String: AnyStruct}?
		
		access(contract)
		var royalties: [MetadataViews.Royalty]?
		
		access(contract)
		var contributors:{ Address: UFix64}?
		
		access(contract)
		var isRoyaltyEnabled: Bool
		
		init(brandId: UInt64, maxSupply: UInt64?, transferable: Bool, immutableData:{ String: AnyStruct}, mutableData:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]?, contributors:{ Address: UFix64}?, isRoyaltyEnabled: Bool){ 
			self.brandId = brandId
			self.templateId = BloomlyNFT.lastIssuedTemplateId
			self.immutableData = immutableData
			self.mutableData = mutableData
			self.locked = false
			self.transferable = transferable
			self.issuedSupply = 0
			self.maxSupply = maxSupply
			self.nfts = []
			self.royalties = royalties
			self.contributors = contributors
			self.isRoyaltyEnabled = isRoyaltyEnabled
		}
		
		// a method to update entire MutableData field of Template
		access(contract)
		fun updateMutableData(mutableData:{ String: AnyStruct}){ 
			self.mutableData = mutableData
		}
		
		// a method to update or add particular attribute to mutable data of Template
		access(contract)
		fun updateMutableAttribute(key: String, value: AnyStruct){ 
			pre{ 
				key != "":
					"Invalid attribute for template"
			}
			if self.mutableData == nil{ 
				self.mutableData ={} 
			}
			self.mutableData?.insert(key: key, value)
		}
		
		// A method to lock the template
		access(contract)
		fun lockTemplate(){ 
			pre{ 
				self.locked == false:
					"Template is already locked"
			}
			self.locked = true
			self.maxSupply = self.issuedSupply
		}
		
		// a method to increment issued supply for template
		access(contract)
		fun incrementIssuedSupply(): UInt64{ 
			pre{ 
				self.locked == false:
					"Template is already locked"
			}
			if self.maxSupply != nil{ 
				assert(self.issuedSupply < self.maxSupply!, message: "Template reached it's max-supply")
			}
			self.issuedSupply = self.issuedSupply + 1
			return self.issuedSupply
		}
		
		// a method to add new NFT's id to a specific template
		access(contract)
		fun appendNFTId(nftId: UInt64){ 
			pre{ 
				BloomlyNFT.allNFTs[nftId] != nil:
					"Invalid nft id"
			}
			self.nfts.append(nftId)
		}
		
		// a method to set template royalties
		access(contract)
		fun setRoyalites(royalties: [MetadataViews.Royalty]){ 
			self.royalties = royalties
		}
		
		// a method to set template contributors
		access(contract)
		fun setContributors(contributors:{ Address: UFix64}){ 
			self.contributors = contributors
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNFTIds(): [UInt64]{ 
			return self.nfts
		}
		
		// a method to get ImmutableData field of Template
		access(TMP_ENTITLEMENT_OWNER)
		fun getImmutableData():{ String: AnyStruct}{ 
			return self.immutableData
		}
		
		// a method to get MutableData field of Template
		access(TMP_ENTITLEMENT_OWNER)
		fun getMutableData():{ String: AnyStruct}?{ 
			return self.mutableData
		}
		
		// a method to get royalities of Template
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): [MetadataViews.Royalty]?{ 
			return self.royalties
		}
		
		// a method to get contributors of Template
		access(TMP_ENTITLEMENT_OWNER)
		fun getContibutors():{ Address: UFix64}?{ 
			return self.contributors
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltyEnabledCheck(): Bool{ 
			return self.isRoyaltyEnabled
		}
	}
	
	// A structure that represent nft data
	access(all)
	struct NFTDataView{ 
		access(all)
		let brandId: UInt64
		
		access(all)
		let templateId: UInt64?
		
		access(all)
		let mintNumber: UInt64
		
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail: String
		
		access(all)
		let isTransferable: Bool
		
		access(contract)
		var immutableData:{ String: AnyStruct}?
		
		access(contract)
		var mutableData:{ String: AnyStruct}?
		
		init(brandId: UInt64, templateId: UInt64?, mintNumber: UInt64, name: String, description: String, thumbnail: String, immutableData:{ String: AnyStruct}?, mutableData:{ String: AnyStruct}?, isTransferable: Bool){ 
			self.brandId = brandId
			self.templateId = templateId
			self.mintNumber = mintNumber
			self.name = name
			self.description = description
			self.thumbnail = thumbnail
			self.immutableData = immutableData
			self.mutableData = mutableData
			self.isTransferable = isTransferable
		}
		
		// a method to update mutable data  of NFT
		access(contract)
		fun updateMutableData(mutableData:{ String: AnyStruct}){ 
			self.mutableData = mutableData
		}
		
		// a method to update or add particular attribute to the mutable data of NFT
		access(contract)
		fun updateMutableAttribute(key: String, value: AnyStruct){ 
			pre{ 
				key != "":
					"Invalid attribute for nft"
			}
			if self.mutableData == nil{ 
				self.mutableData ={} 
			}
			self.mutableData?.insert(key: key, value)
		}
		
		// a method to get the immutable data of the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun getImmutableData():{ String: AnyStruct}?{ 
			return self.immutableData
		}
		
		// a method to get the mutable data of the NFT
		access(TMP_ENTITLEMENT_OWNER)
		fun getMutableData():{ String: AnyStruct}?{ 
			return self.mutableData
		}
	}
	
	// The resource that represents the Bloomly NFTs
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let royalties: [MetadataViews.Royalty]
		
		access(contract)
		let data: NFTDataView
		
		init(brandId: UInt64, templateId: UInt64?, mintNumber: UInt64, name: String, description: String, thumbnail: String, isTransferable: Bool, immutableData:{ String: AnyStruct}?, mutableData:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]){ 
			BloomlyNFT.totalSupply = BloomlyNFT.totalSupply + 1
			self.id = BloomlyNFT.totalSupply
			self.royalties = royalties
			self.data = NFTDataView(brandId: brandId, templateId: templateId, mintNumber: mintNumber, name: name, description: description, thumbnail: thumbnail, immutableData: immutableData, mutableData: mutableData, isTransferable: isTransferable)
			BloomlyNFT.allNFTs[self.id] = self.data
			if templateId != nil{ 
				(BloomlyNFT.allTemplates[templateId!]!).appendNFTId(nftId: self.id)
			}
			(BloomlyNFT.allBrands[brandId]!).appendNFTId(nftId: self.id)
			emit NFTMinted(nftId: self.id, brandId: brandId, templateId: templateId, mintNumber: mintNumber, name: name, description: description, thumbnail: thumbnail, isTransferable: isTransferable)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getUserNFTData(): NFTDataView{ 
			return self.data
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let templateDetails = self.data.templateId != nil ? BloomlyNFT.allTemplates[self.data.templateId!] : nil
			let brandDetails = BloomlyNFT.allBrands[self.data.brandId]
			let maxSupply = templateDetails != nil ? templateDetails?.maxSupply : 1 as UInt64
			var editionName: String = "Bloomly NFTs"
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.data.name, description: self.data.description, thumbnail: MetadataViews.HTTPFile(url: self.data.thumbnail))
				case Type<MetadataViews.Editions>():
					//Need to fetch template details
					let editionInfo = MetadataViews.Edition(name: editionName, number: self.data.mintNumber, max: maxSupply!)
					let editionList: [MetadataViews.Edition] = [editionInfo]
					return MetadataViews.Editions(editionList)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.id)
				case Type<MetadataViews.Royalties>():
					return MetadataViews.Royalties(self.royalties)
				case Type<MetadataViews.ExternalURL>():
					//Fetch brand data
					return MetadataViews.ExternalURL((brandDetails!).externalURL)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: BloomlyNFT.CollectionStoragePath, publicPath: BloomlyNFT.CollectionPublicPath, publicCollection: Type<&BloomlyNFT.Collection>(), publicLinkedType: Type<&BloomlyNFT.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-BloomlyNFT.createEmptyCollection(nftType: Type<@BloomlyNFT.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let mediaSquare = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d1b6upo1s7pshq.cloudfront.net/images/Bloctobay+marketplace+profile+.png") //brandDetails!.externalURL																																											  
																																											  , mediaType: "image/svg+xml")
					let mediaBanner = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d1b6upo1s7pshq.cloudfront.net/images/Bloctobay+marketplace+cover.png") //brandDetails!.externalURL																																										   
																																										   , mediaType: "image/svg+xml")
					return MetadataViews.NFTCollectionDisplay(name: "Bloomly", description: "Bloomly is a pre-built, fully functional no code NFT private label software platform enables you to bring your NFT business to market quickly", externalURL: MetadataViews.ExternalURL("https://bloomly.xyz"), squareImage: mediaSquare, bannerImage: mediaBanner, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/Bloomly_xyz"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/bloomly.xyz")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = [""] // exclude keys, which you want to exclude
					
					var immutableData:{ String: AnyStruct} ={} 
					if self.data.immutableData != nil{ 
						immutableData = self.data.immutableData!
					}
					let traitsView = MetadataViews.dictToTraits(dict: immutableData, excludedNames: excludedTraits)
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//Bloomly NFT public interface
	access(all)
	resource interface BloomlyNFTCollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBloomlyNFT(id: UInt64): &BloomlyNFT.NFT
	}
	
	// Collection is a resource, which is used by every user who owns NFTs 
	// It is stored in their account to manage their NFTS
	access(all)
	resource Collection: BloomlyNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let nftData = BloomlyNFT.getNFTDataById(nftId: withdrawID)
			//check if nft is transferable 
			assert(nftData.isTransferable == true, message: "NFT is non-transferable")
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Invalid nft id")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun burnNFT(nftId: UInt64){ 
			let token <- self.ownedNFTs.remove(key: nftId) ?? panic("Invalid nft id")
			destroy token
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @BloomlyNFT.NFT
			let id = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowBloomlyNFT(id: UInt64): &BloomlyNFT.NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Invalid nft id"
			}
			let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return ref as! &BloomlyNFT.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let BloomlyNFT = nft as! &BloomlyNFT.NFT
			return BloomlyNFT
		}
		
		access(all)
		view fun getSupportedNFTTypes():{ Type: Bool}{ 
			panic("implement me")
		}
		
		access(all)
		view fun isSupportedNFTType(type: Type): Bool{ 
			panic("implement me")
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
	}
	
	//A Super-Admin resource can create Admimn resrouce
	access(all)
	resource SuperAdmin{ 
		
		//method to create Admin resource 
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdminResource(adminAddress: Address): @Admin{ 
			pre{ 
				BloomlyNFT.allAdmins.contains(adminAddress) == false:
					"Already added as Admin"
			}
			BloomlyNFT.allAdmins.append(adminAddress)
			emit AdminCreated(address: adminAddress)
			return <-create Admin()
		}
		
		//method to remove Admin address
		access(TMP_ENTITLEMENT_OWNER)
		fun removeAdminAddress(adminAddress: Address){ 
			pre{ 
				BloomlyNFT.allAdmins.contains(adminAddress) == true:
					"Given addrerss is not added as Admin"
			}
			BloomlyNFT.allAdmins.remove(at: BloomlyNFT.allAdmins.firstIndex(of: adminAddress)!)
			emit AdminRemoved(address: adminAddress)
		}
	}
	
	//An Admin resource which Create new Brands and create BrandAdmin resource
	access(all)
	resource Admin{ 
		
		// method to create new Brand, only access by the verified user
		access(TMP_ENTITLEMENT_OWNER)
		fun createBrand(brandName: String, registrationNo: String, authors: [Address], externalURL: String, data:{ String: String}, platormFee: UFix64){ 
			pre{ 
				BloomlyNFT.allAdmins.contains((self.owner!).address) == true:
					"Only Admin can create Brand"
				platormFee < 1.0:
					"Platform fee should be in this range [0,1]"
			}
			let newBrand = BloomlyNFT.Brand(brandName: brandName, registrationNo: registrationNo, authors: authors, externalURL: externalURL, data: data, platormFee: platormFee)
			BloomlyNFT.allBrands[BloomlyNFT.lastIssuedBrandId] = newBrand
			BloomlyNFT.lastIssuedBrandId = BloomlyNFT.lastIssuedBrandId + 1
			let royalties: [MetadataViews.Royalty] = []
			var contributors:{ Address: UFix64} ={} 
			contributors[authors[0]] = 1.0 - platormFee
			let brandPayout = Payout(royalties: royalties, contributors: contributors)
			BloomlyNFT.payouts[newBrand.brandId] = brandPayout
			emit BrandCreated(brandId: newBrand.brandId, brandName: brandName, registrationNo: registrationNo, authors: authors, externalURL: externalURL, data: data, platormFee: platormFee)
		}
		
		// method to update Brand author
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandAuthor(brandId: UInt64, newAuthors: [Address]){ 
			pre{ 
				BloomlyNFT.allAdmins.contains((self.owner!).address) == true:
					"Only Admin can updatte Brand Author"
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
			//BloomlyNFT.allBrands[brandId]!.authors != newAuthors: "New author has same address"
			}
			(BloomlyNFT.allBrands[brandId]!).updateBrandAuthor(authors: newAuthors)
			emit BrandAuthorUpdated(brandId: brandId, authors: newAuthors)
		}
		
		//method to create BrandAdmin resource and give the interface capability to the new brand admins
		access(TMP_ENTITLEMENT_OWNER)
		fun createBrandAdminResource(): @BloomlyNFT.BrandAdmin{ 
			pre{ 
				BloomlyNFT.allAdmins.contains((self.owner!).address) == true:
					"Only Admin can create Brand resource"
			}
			return <-create BrandAdmin()
		}
		
		// method to update Brand platform fee
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandPlatformFee(brandId: UInt64, platormFee: UFix64){ 
			pre{ 
				BloomlyNFT.allAdmins.contains((self.owner!).address) == true:
					"Only Admin can update platform fee"
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				platormFee < 1.0:
					"Platform fee should be in this range [0,1]"
			}
			var contributorSum = 0.0
			var brandPlatformFee = platormFee
			let contributors = (BloomlyNFT.payouts[brandId]!).contributors
			for contributorCut in contributors.values{ 
				contributorSum = contributorSum + contributorCut
			}
			assert(contributorSum + brandPlatformFee == 1.0, message: "Sum of all contributor's cut and platform fee should be equal to 1.0")
			(BloomlyNFT.allBrands[brandId]!).updateBrandPlatformFee(platormFee: platormFee)
			emit BrandPlatformFeeUpdated(brandId: brandId, platormFee: platormFee)
		}
	}
	
	// Interface, which contains all the methods that are called by any user to mint NFT and manage brand, and template funtionality
	access(all)
	resource interface NFTMethodsCapability{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrand(brandId: UInt64, brandName: String, externalURL: String, data:{ String: String}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandName(brandId: UInt64, brandName: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandExternalUrl(brandId: UInt64, externalURL: String)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandData(brandId: UInt64, data:{ String: String})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createTemplate(brandId: UInt64, maxSupply: UInt64?, transferable: Bool, immutableData:{ String: AnyStruct}, mutableData:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]?, contributors:{ Address: UFix64}?, isRoyaltyEnabled: Bool)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTemplateMutableData(templateId: UInt64, mutableData:{ String: AnyStruct})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTemplateMutableAttribute(templateId: UInt64, key: String, value: AnyStruct)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun lockTemplate(templateId: UInt64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeTemplateById(templateId: UInt64)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(brandId: UInt64, templateId: UInt64?, receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic}, immutableData:{ String: AnyStruct}?, mutableData:{ String: AnyStruct}?, name: String, description: String, thumbnail: String, transferable: Bool, royalties: [MetadataViews.Royalty])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRoyalties(brandId: UInt64, royalties: [MetadataViews.Royalty])
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setContributors(brandId: UInt64, contributors:{ Address: UFix64})
	}
	
	// BrandAdmin, where are defining all the methods related to Brands, Template and NFTs
	access(all)
	resource BrandAdmin: NFTMethodsCapability{ 
		// a dictionary which stores all Templates owned by a user
		access(self)
		var ownedTemplates:{ UInt64: Template}
		
		//method to update the existing Brand, only author of brand can update this brand
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrand(brandId: UInt64, brandName: String, externalURL: String, data:{ String: String}){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only owner can update brand"
			}
			(BloomlyNFT.allBrands[brandId]!).update(brandName: brandName, externalURL: externalURL, data: data)
			emit BrandUpdated(brandId: brandId, brandName: brandName, externalURL: externalURL, data: data)
		}
		
		//method to update the existing Brand name, only author of brand can update this brand
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandName(brandId: UInt64, brandName: String){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only owner can update brand"
			}
			(BloomlyNFT.allBrands[brandId]!).updateBrandName(brandName: brandName)
			emit BrandNameUpdated(brandId: brandId, brandName: brandName)
		}
		
		//method to update the existing Brand external url, only author of brand can update this brand
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandExternalUrl(brandId: UInt64, externalURL: String){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only owner can update brand"
			}
			(BloomlyNFT.allBrands[brandId]!).updateBrandExternalUrl(externalURL: externalURL)
			emit BrandExternalUrlUpdated(brandId: brandId, externalURL: externalURL)
		}
		
		//method to update the existing Brand data, only author of brand can update this brand
		access(TMP_ENTITLEMENT_OWNER)
		fun updateBrandData(brandId: UInt64, data:{ String: String}){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only owner can update brand"
			}
			(BloomlyNFT.allBrands[brandId]!).updateBrandData(data: data)
			emit BrandDataUpdated(brandId: brandId, data: data)
		}
		
		//method to create new Template, only access by the verified user
		access(TMP_ENTITLEMENT_OWNER)
		fun createTemplate(brandId: UInt64, maxSupply: UInt64?, transferable: Bool, immutableData:{ String: AnyStruct}, mutableData:{ String: AnyStruct}?, royalties: [MetadataViews.Royalty]?, contributors:{ Address: UFix64}?, isRoyaltyEnabled: Bool){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only owner can create template"
			}
			let newTemplate = Template(brandId: brandId, maxSupply: maxSupply, transferable: transferable, immutableData: immutableData, mutableData: mutableData, royalties: royalties, contributors: contributors, isRoyaltyEnabled: isRoyaltyEnabled)
			BloomlyNFT.allTemplates[BloomlyNFT.lastIssuedTemplateId] = newTemplate
			self.ownedTemplates[BloomlyNFT.lastIssuedTemplateId] = newTemplate
			(BloomlyNFT.allBrands[brandId]!).appendTemplateId(templateId: newTemplate.templateId)
			BloomlyNFT.lastIssuedTemplateId = BloomlyNFT.lastIssuedTemplateId + 1
			emit TemplateCreated(templateId: newTemplate.templateId, brandId: brandId, maxSupply: maxSupply, transferable: transferable, isRoyaltyEnabled: isRoyaltyEnabled)
		}
		
		//method to update the existing template's mutable data, only author of brand can update this template
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTemplateMutableData(templateId: UInt64, mutableData:{ String: AnyStruct}){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Template id does not exists"
			}
			let templateData = BloomlyNFT.getTemplateById(templateId: templateId)
			let brandId = templateData.brandId
			assert((BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address), message: "Only owner can update template")
			(BloomlyNFT.allTemplates[templateId]!).updateMutableData(mutableData: mutableData)
			emit TemplateUpdated(templateId: templateId)
		}
		
		//method to update or add particular key-value pair in Template's mutable data, only author of brand can update this template
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTemplateMutableAttribute(templateId: UInt64, key: String, value: AnyStruct){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Template id does not exists"
			}
			let templateData = BloomlyNFT.getTemplateById(templateId: templateId)
			let brandId = templateData.brandId
			assert((BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address), message: "Only owner can update template")
			(BloomlyNFT.allTemplates[templateId]!).updateMutableAttribute(key: key, value: value)
			emit TemplateUpdated(templateId: templateId)
		}
		
		//method to lock the template to not mint more nfts
		access(TMP_ENTITLEMENT_OWNER)
		fun lockTemplate(templateId: UInt64){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Template id does not exists"
			}
			let templateData = BloomlyNFT.getTemplateById(templateId: templateId)
			let brandId = templateData.brandId
			assert((BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address), message: "Only owner can lock template")
			(BloomlyNFT.allTemplates[templateId]!).lockTemplate()
			emit TemplateLocked(templateId: templateId)
		}
		
		//method to remove template by id
		access(TMP_ENTITLEMENT_OWNER)
		fun removeTemplateById(templateId: UInt64){ 
			pre{ 
				BloomlyNFT.allTemplates[templateId] != nil:
					"Template id does not exists"
				(BloomlyNFT.allTemplates[templateId]!).issuedSupply == 0:
					"Template can't be removed, NFTs already minted under this template"
			}
			let templateData = BloomlyNFT.getTemplateById(templateId: templateId)
			let brandId = templateData.brandId
			assert((BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address), message: "Only owner can remove template")
			(BloomlyNFT.allBrands[brandId]!).removeTemplateId(templateId: templateId)
			self.ownedTemplates.remove(key: templateId)
			BloomlyNFT.allTemplates.remove(key: templateId)
			emit TemplateRemoved(templateId: templateId)
		}
		
		//method to mint NFT, only access by the verified user
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(brandId: UInt64, templateId: UInt64?, receiverRef: &{BloomlyNFT.BloomlyNFTCollectionPublic}, immutableData:{ String: AnyStruct}?, mutableData:{ String: AnyStruct}?, name: String, description: String, thumbnail: String, transferable: Bool, royalties: [MetadataViews.Royalty]){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address) || BloomlyNFT.account.address == (self.owner!).address:
					"Only brand or contract owner can mint nft"
				name.length != 0:
					"Name of nft is required"
				description.length != 0:
					"Description of nft is required"
				thumbnail.length != 0:
					"Thumbnail of nft is required"
				receiverRef.owner != nil:
					"Recipients NFT collection is not owned"
			}
			var mintNumber: UInt64 = 1
			var isTransferable = transferable
			var nftRoyalties = royalties
			if templateId != nil{ 
				assert(BloomlyNFT.allTemplates[templateId!] != nil, message: "Template id does not exists")
				let templateData = BloomlyNFT.getTemplateById(templateId: templateId!)
				let templateBrandId = templateData.brandId
				assert(templateBrandId == brandId, message: "Template does not exists in this brand")
				mintNumber = (BloomlyNFT.allTemplates[templateId!]!).incrementIssuedSupply()
				isTransferable = (BloomlyNFT.allTemplates[templateId!]!).transferable
				if nftRoyalties.length == 0{ 
					nftRoyalties = (BloomlyNFT.allTemplates[templateId!]!).royalties ?? []
				}
			} else{ 
				assert(immutableData != nil, message: "NFT must have immutable data")
			}
			let newNFT: @NFT <- create NFT(brandId: brandId, templateId: templateId, mintNumber: mintNumber, name: name, description: description, thumbnail: thumbnail, isTransferable: isTransferable, immutableData: immutableData, mutableData: mutableData, royalties: nftRoyalties)
			let id = newNFT.id
			receiverRef.deposit(token: <-newNFT)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setRoyalties(brandId: UInt64, royalties: [MetadataViews.Royalty]){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only brand owner can set royalties"
			}
			var brandPayout = BloomlyNFT.payouts[brandId]
			let payout = Payout(royalties: royalties, contributors: (brandPayout!).contributors)
			BloomlyNFT.payouts[brandId] = payout
			emit BrandRoyaltiesAdded(brandId: brandId)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setContributors(brandId: UInt64, contributors:{ Address: UFix64}){ 
			pre{ 
				BloomlyNFT.allBrands[brandId] != nil:
					"Brand Id does not exists"
				(BloomlyNFT.allBrands[brandId]!).authors.contains((self.owner!).address):
					"Only brand owner can set contributros"
				contributors.keys.length > 0:
					"Contributors should have at leaset 1 contributor"
			}
			var contributorSum = 0.0
			var brandPlatformFee = (BloomlyNFT.allBrands[brandId]!).platormFee
			for contributorCut in contributors.values{ 
				contributorSum = contributorSum + contributorCut
			}
			assert(contributorSum + brandPlatformFee == 1.0, message: "Sum of all contributor's cut and platform fee should be equal to 1.0")
			var brandPayout = BloomlyNFT.payouts[brandId]
			let payout = Payout(royalties: (brandPayout!).royalties, contributors: contributors)
			BloomlyNFT.payouts[brandId] = payout
			emit BrandContributorsAdded(brandId: brandId)
		}
		
		init(){ 
			self.ownedTemplates ={} 
		}
	}
	
	//method to create empty Collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create BloomlyNFT.Collection()
	}
	
	//method to get all Brands
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllBrands():{ UInt64: Brand}{ 
		return BloomlyNFT.allBrands
	}
	
	//method to get brand by id
	access(TMP_ENTITLEMENT_OWNER)
	fun getBrandById(brandId: UInt64): Brand{ 
		pre{ 
			BloomlyNFT.allBrands[brandId] != nil:
				"Brand Id does not exists"
		}
		return BloomlyNFT.allBrands[brandId]!
	}
	
	//method to get all templates
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllTemplates():{ UInt64: Template}{ 
		return BloomlyNFT.allTemplates
	}
	
	//method to get template by id
	access(TMP_ENTITLEMENT_OWNER)
	fun getTemplateById(templateId: UInt64): Template{ 
		pre{ 
			BloomlyNFT.allTemplates[templateId] != nil:
				"Template id does not exists"
		}
		return BloomlyNFT.allTemplates[templateId]!
	}
	
	//method to get nft-data by id
	access(TMP_ENTITLEMENT_OWNER)
	fun getNFTDataById(nftId: UInt64): NFTDataView{ 
		pre{ 
			BloomlyNFT.allNFTs[nftId] != nil:
				"NFT id does not exists"
		}
		return BloomlyNFT.allNFTs[nftId]!
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllNFTs():{ UInt64: NFTDataView}{ 
		return BloomlyNFT.allNFTs
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getBrandPayouts(brandId: UInt64): Payout?{ 
		return BloomlyNFT.payouts[brandId]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getAllAdmins(): [Address]{ 
		return BloomlyNFT.allAdmins
	}
	
	//Initialize all variables with default values
	init(){ 
		self.lastIssuedBrandId = 1
		self.lastIssuedTemplateId = 1
		self.totalSupply = 0
		self.allBrands ={} 
		self.allTemplates ={} 
		self.allNFTs ={} 
		self.payouts ={} 
		self.allAdmins = [self.account.address]
		self.BrandAdminStoragePath = /storage/BloomlyNFTBrandAdmin
		self.CollectionStoragePath = /storage/BloomlyNFTCollection
		self.CollectionPublicPath = /public/BloomlyNFTCollection
		self.AdminStorageCapability = /storage/AdminBrand
		self.SuperAdminStoragePath = /storage/SuperAdmin
		self.NFTMethodsCapabilityPrivatePath = /private/BloomlyNFTNFTMethodsCapability
		self.account.storage.save(<-create SuperAdmin(), to: self.SuperAdminStoragePath)
		self.account.storage.save(<-create Admin(), to: self.AdminStorageCapability)
		self.account.storage.save<@BrandAdmin>(<-create BrandAdmin(), to: self.BrandAdminStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&{NFTMethodsCapability}>(self.BrandAdminStoragePath)
		self.account.capabilities.publish(capability_1, at: self.NFTMethodsCapabilityPrivatePath)
		emit ContractInitialized()
	}
}
