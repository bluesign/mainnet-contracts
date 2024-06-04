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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MikoSeaNFTMetadata from "./MikoSeaNFTMetadata.cdc"

access(all)
contract MIKOSEANFTV2: NonFungibleToken{ 
	// start from 1
	access(all)
	var totalSupply: UInt64
	
	access(all)
	var nextProjectId: UInt64
	
	access(all)
	var nextCommentId: UInt64
	
	// mapping nftID - holderAdderss
	access(all)
	let nftHolderMap:{ UInt64: Address}
	
	access(all)
	var mikoseaCap: Capability<&{FungibleToken.Receiver}>
	
	access(all)
	var tokenPublicPath: PublicPath
	
	//------------------------------------------------------------
	// Events
	//------------------------------------------------------------
	access(all)
	event ContractInitialized()
	
	// project events
	access(all)
	event ProjectCreated(projectId: UInt64, title: String, description: String, thumbnail: String, creatorAddress: Address, mintPrice: UFix64, maxSupply: UInt64, isPublic: Bool)
	
	access(all)
	event ProjectUpdated(projectId: UInt64, title: String, description: String, thumbnail: String, creatorAddress: Address, mintPrice: UFix64, maxSupply: UInt64)
	
	access(all)
	event ProjectPublic(projectId: UInt64)
	
	access(all)
	event ProjectUnPublic(projectId: UInt64)
	
	access(all)
	event ProjectReveal(projectId: UInt64)
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event Minted(id: UInt64, nftData: NFTData, recipient: Address)
	
	access(all)
	event NFTTransferred(nftID: UInt64, nftData: NFTData, from: Address, to: Address)
	
	access(all)
	event NFTDestroy(nftID: UInt64)
	
	access(all)
	event SetInMarket(nftID: UInt64)
	
	//------------------------------------------------------------
	// Path
	//------------------------------------------------------------
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let PrivatePath: PrivatePath
	
	access(all)
	let MinterStoragePath: StoragePath
	
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	let AdminPublicPath: PublicPath
	
	//------------------------------------------------------------
	// Comment Struct
	//------------------------------------------------------------
	access(all)
	struct CommentData{ 
		access(all)
		let commentId: UInt64
		
		access(all)
		let nftID: UInt64
		
		access(all)
		var comment: String
		
		access(all)
		let createdDate: UFix64
		
		access(all)
		var updatedDate: UFix64
		
		init(nftID: UInt64, comment: String){ 
			pre{ 
				comment.length != 0:
					"Comment can not be empty"
			}
			self.commentId = MIKOSEANFTV2.nextCommentId
			self.nftID = nftID
			self.comment = comment
			self.createdDate = getCurrentBlock().timestamp
			self.updatedDate = getCurrentBlock().timestamp
			MIKOSEANFTV2.nextCommentId = MIKOSEANFTV2.nextCommentId + 1
		}
		
		access(account)
		fun update(comment: String): CommentData{ 
			self.comment = comment
			self.updatedDate = getCurrentBlock().timestamp
			return self
		}
	}
	
	access(all)
	resource ProjectData{ 
		access(all)
		let projectId: UInt64
		
		access(all)
		var isPublic: Bool
		
		access(all)
		var title: String
		
		access(all)
		var description: String
		
		access(all)
		var thumbnail: String
		
		access(all)
		var creatorAddress: Address
		
		access(all)
		var platformFee: UFix64
		
		access(all)
		var creatorMarketFee: UFix64
		
		access(all)
		var platformMarketFee: UFix64
		
		access(all)
		var mintPrice: UFix64
		
		access(all)
		var isReveal: Bool
		
		access(all)
		var totalSupply: UInt64
		
		// nftID minted
		access(all)
		let nftMinted: [UInt64]
		
		// max mint number
		access(all)
		var maxSupply: UInt64
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(title: String, description: String, thumbnail: String, creatorAddress: Address, platformFee: UFix64, creatorMarketFee: UFix64, platformMarketFee: UFix64, mintPrice: UFix64, maxSupply: UInt64, isPublic: Bool, metadata:{ String: AnyStruct}){ 
			pre{ 
				title.length > 0:
					"PROJECT_TITLE_IS_INVALID"
				description.length > 0:
					"PROJECT_DESCRIPTION_IS_INVALID"
				maxSupply > 0:
					"PROJECT_MAX_SUPPLY_IS_INVALID"
				platformFee <= 1.0:
					"PLATFORM_FEE_IS_INVALID"
				creatorMarketFee <= 1.0:
					"CRAETER_FEE_IS_INVALID"
				platformMarketFee <= 1.0:
					"PLATFORM_FEE_IS_INVALID"
				creatorMarketFee + platformMarketFee <= 1.0:
					"TOTAL_FEE_IS_INVALID"
			}
			self.projectId = MIKOSEANFTV2.nextProjectId
			self.title = title
			self.description = description
			self.thumbnail = thumbnail
			self.creatorAddress = creatorAddress
			self.platformFee = platformFee
			self.creatorMarketFee = creatorMarketFee
			self.platformMarketFee = platformMarketFee
			self.mintPrice = mintPrice
			self.maxSupply = maxSupply
			self.isPublic = isPublic
			self.totalSupply = 0
			self.nftMinted = []
			self.isReveal = false
			self.metadata = metadata
			MIKOSEANFTV2.nextProjectId = MIKOSEANFTV2.nextProjectId + 1
			emit ProjectCreated(projectId: self.projectId, title: title, description: description, thumbnail: thumbnail, creatorAddress: creatorAddress, mintPrice: mintPrice, maxSupply: maxSupply, isPublic: isPublic)
		}
		
		access(account)
		fun public(){ 
			self.isPublic = true
			emit ProjectPublic(projectId: self.projectId)
		}
		
		access(account)
		fun unPublic(){ 
			self.isPublic = false
			emit ProjectUnPublic(projectId: self.projectId)
		}
		
		access(account)
		fun reveal(){ 
			self.isReveal = true
			emit ProjectReveal(projectId: self.projectId)
		}
		
		access(account)
		fun unRevealProject(){ 
			self.isReveal = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		access(account)
		fun setMetadata(_metadata:{ String: AnyStruct}):{ String: AnyStruct}{ 
			self.metadata = _metadata
			return _metadata
		}
		
		access(contract)
		fun update(title: String?, description: String?, thumbnail: String?, creatorAddress: Address?, platformFee: UFix64?, creatorMarketFee: UFix64?, platformMarketFee: UFix64?, mintPrice: UFix64?, maxSupply: UInt64?, metadata:{ String: AnyStruct}?){ 
			post{ 
				self.title.length > 0:
					"New Project name cannot be empty"
				self.description.length > 0:
					"New Project description cannot be empty"
				self.maxSupply > 0:
					"Max supply must be > 0"
				self.platformFee <= 1.0:
					"PLATFORM_FEE_IS_INVALID"
				self.creatorMarketFee <= 1.0:
					"CRAETER_FEE_IS_INVALID"
				self.platformMarketFee <= 1.0:
					"PLATFORM_FEE_IS_INVALID"
				self.creatorMarketFee + self.platformMarketFee <= 1.0:
					"TOTAL_FEE_IS_INVALID"
			}
			self.title = title ?? self.title
			self.description = description ?? self.description
			self.thumbnail = thumbnail ?? self.thumbnail
			self.creatorAddress = creatorAddress ?? self.creatorAddress
			self.platformFee = platformFee ?? self.platformFee
			self.creatorMarketFee = creatorMarketFee ?? self.creatorMarketFee
			self.platformMarketFee = platformMarketFee ?? self.platformMarketFee
			self.mintPrice = mintPrice ?? self.mintPrice
			self.maxSupply = maxSupply ?? self.maxSupply
			self.metadata = metadata ?? self.metadata
			emit ProjectUpdated(projectId: self.projectId, title: self.title, description: self.description, thumbnail: self.thumbnail, creatorAddress: self.creatorAddress, mintPrice: self.mintPrice, maxSupply: self.maxSupply)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties([MetadataViews.Royalty(receiver: MIKOSEANFTV2.mikoseaCap, cut: self.platformFee, description: "Platform fee"), MetadataViews.Royalty(receiver: getAccount(self.creatorAddress).capabilities.get<&{FungibleToken.Receiver}>(MIKOSEANFTV2.tokenPublicPath)!, cut: 0.0, description: "Creater market fee, when this nft is in the market, the creater fee is 5%")])
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltiesMarket(): MetadataViews.Royalties{ 
			return MetadataViews.Royalties([MetadataViews.Royalty(receiver: MIKOSEANFTV2.mikoseaCap, cut: self.platformMarketFee, description: "Platform market fee"), MetadataViews.Royalty(receiver: getAccount(self.creatorAddress).capabilities.get<&{FungibleToken.Receiver}>(MIKOSEANFTV2.tokenPublicPath)!, cut: self.creatorMarketFee, description: "Creater market fee")])
		}
		
		access(self)
		fun _mintNFT(image: String, metadata:{ String: String}, recipientRef: &{CollectionPublic}): UInt64{ 
			self.totalSupply = self.totalSupply + 1
			let newNFT: @NFT <- create NFT(projectId: self.projectId, serialNumber: self.totalSupply, image: image, metadata: metadata, royalties: self.getRoyalties(), royaltiesMarket: self.getRoyaltiesMarket())
			let nftIDminted = newNFT.id
			self.nftMinted.append(newNFT.id)
			emit Minted(id: newNFT.id, nftData: newNFT.nftData, recipient: (recipientRef.owner!).address)
			recipientRef.deposit(token: <-newNFT)
			return nftIDminted
		}
		
		// mint nfts and return list of nftID
		access(contract)
		fun batchMintNFT(quantity: UInt64, images: [String], metadatas: [{String: String}], recipientCap: Capability<&{CollectionPublic}>): [UInt64]{ 
			pre{ 
				self.isPublic:
					"PROJECT_LOCKED"
				self.totalSupply + quantity <= self.maxSupply:
					"PROJECT_NOT_ENOUGH"
				recipientCap.check():
					"ACCOUNT_NOT_CREATED"
				quantity == UInt64(images.length):
					"QUANTITY_IN_VALID"
				quantity == UInt64(metadatas.length):
					"QUANTITY_IN_VALID"
			}
			let nftIDs: [UInt64] = []
			var i: UInt64 = 0
			while i < quantity{ 
				let nftID = self._mintNFT(image: images[i], metadata: metadatas[i], recipientRef: recipientCap.borrow()!)
				i = i + 1
				nftIDs.append(nftID)
			}
			return nftIDs
		}
	}
	
	access(all)
	struct NFTData{ 
		access(all)
		let projectId: UInt64
		
		access(all)
		let serialNumber: UInt64
		
		// base image URL
		access(contract)
		let image: String
		
		access(contract)
		let metadata:{ String: String}
		
		access(all)
		let createdDate: UFix64
		
		access(all)
		let blockHeight: UInt64
		
		access(contract)
		fun updateMetadata(_ metadata:{ String: String}){ 
			for key in metadata.keys{ 
				self.metadata[key] = metadata[key]
			}
		}
		
		init(projectId: UInt64, serialNumber: UInt64, image: String, metadata:{ String: String}){ 
			self.projectId = projectId
			self.serialNumber = serialNumber
			self.metadata = metadata
			self.image = image
			self.createdDate = getCurrentBlock().timestamp
			self.blockHeight = getCurrentBlock().height
		}
	}
	
	//------------------------------------------------------------
	// NFT Resource
	//------------------------------------------------------------
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let nftData: NFTData
		
		access(self)
		var isInMarket: Bool
		
		access(self)
		let royalties: MetadataViews.Royalties
		
		access(self)
		let royaltiesMarket: MetadataViews.Royalties
		
		access(all)
		let commentData:{ UInt64: CommentData}
		
		init(projectId: UInt64, serialNumber: UInt64, image: String, metadata:{ String: String}, royalties: MetadataViews.Royalties, royaltiesMarket: MetadataViews.Royalties){ 
			MIKOSEANFTV2.totalSupply = MIKOSEANFTV2.totalSupply + 1
			self.id = MIKOSEANFTV2.totalSupply
			self.nftData = NFTData(projectId: projectId, serialNumber: serialNumber, image: image, metadata: metadata)
			self.royalties = royalties
			self.royaltiesMarket = royaltiesMarket
			self.commentData ={} 
			self.isInMarket = false
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: String}{ 
			let requiredMetadata = MikoSeaNFTMetadata.getNFTMetadata(nftType: "mikoseav2", nftID: self.id) ??{} 
			if (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).isReveal{ 
				let metadata = self.nftData.metadata
				requiredMetadata.forEachKey(fun (key: String): Bool{ 
						metadata.insert(key: key, requiredMetadata[key] ?? "")
						return true
					})
				return metadata
			}
			return requiredMetadata
		}
		
		access(account)
		fun updateMetadata(_ metadata:{ String: String}){ 
			self.nftData.updateMetadata(metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getImage(): String{ 
			if (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).isReveal{ 
				return self.nftData.image
			}
			return (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).thumbnail
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getTitle(): String{ 
			if (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).isReveal{ 
				let title = self.getMetadata()["title"] ?? MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
				return title
			}
			return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getName(): String{ 
			if (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).isReveal{ 
				let name = self.getMetadata()["name"] ?? self.getTitle()
				return name.concat(" #").concat(self.nftData.serialNumber.toString())
			}
			return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.title ?? ""
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String{ 
			if (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).isReveal{ 
				return self.getMetadata()["description"] ?? MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.description ?? ""
			}
			return MIKOSEANFTV2.getProjectById(self.nftData.projectId)?.description ?? ""
		}
		
		// receiver: Capability<&AnyResource{FungibleToken.Receiver}>, cut: UFix64, description: String
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalties(): MetadataViews.Royalties{ 
			if self.isInMarket{ 
				return self.getRoyaltiesMarket()
			}
			return (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).getRoyalties()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyaltiesMarket(): MetadataViews.Royalties{ 
			return (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).getRoyaltiesMarket()
		}
		
		access(account)
		fun setInMarket(_ value: Bool){ 
			self.isInMarket = value
			emit SetInMarket(nftID: self.id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getIsInMarket(): Bool{ 
			return self.isInMarket
		}
		
		access(account)
		fun createComment(comment: String): CommentData{ 
			let newComment = CommentData(nftID: self.id, comment: comment)
			self.commentData[newComment.commentId] = newComment
			return newComment
		}
		
		access(account)
		fun updateComment(commentId: UInt64, comment: String){ 
			let commentData = self.commentData[commentId] ?? panic("COMMENT_NOT_FOUND")
			self.commentData[commentId] = commentData.update(comment: comment)
		}
		
		access(account)
		fun deleteComment(commentId: UInt64){ 
			self.commentData.remove(key: commentId)
		}
		
		/// Function that returns all the Metadata Views implemented by a Non Fungible Token
		///
		/// @return An array of Types defining the implemented views. This value will be used by
		///		 developers to know which parameter to pass to the resolveView() method.
		///
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.Editions>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Traits>()]
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			switch view{ 
				case Type<MetadataViews.Display>():
					return MetadataViews.Display(name: self.getName(), description: self.getDescription(), thumbnail: MetadataViews.HTTPFile(url: self.getImage()))
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.nftData.serialNumber)
				case Type<MetadataViews.Royalties>():
					return self.getRoyalties()
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://mikosea.io/nft/detail/mikoseav2/".concat(self.id.toString()))
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MIKOSEANFTV2.CollectionStoragePath, publicPath: MIKOSEANFTV2.CollectionPublicPath, publicCollection: Type<&MIKOSEANFTV2.Collection>(), publicLinkedType: Type<&MIKOSEANFTV2.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MIKOSEANFTV2.createEmptyCollection(nftType: Type<@MIKOSEANFTV2.Collection>())
						})
				case Type<MetadataViews.NFTCollectionDisplay>():
					let bannerImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://storage.googleapis.com/studio-design-asset-files/projects/1pqD36e6Oj/s-300x50_aa59a692-741b-408b-aea3-bcd25d29c6bd.svg"), mediaType: "image/svg+xml")
					let projectImageType = MIKOSEANFTV2.getProjectImageType(self.nftData.projectId) ?? "png"
					let squareImage = MetadataViews.Media(file: MetadataViews.HTTPFile(url: (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).thumbnail), mediaType: "image/".concat(projectImageType))
					return MetadataViews.NFTCollectionDisplay(name: (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).title, description: (MIKOSEANFTV2.getProjectById(self.nftData.projectId)!).description, externalURL: MetadataViews.ExternalURL("https://mikosea.io/"), squareImage: squareImage, bannerImage: bannerImage, socials:{ "twitter": MetadataViews.ExternalURL("https://twitter.com/MikoSea_io")})
				case Type<MetadataViews.Traits>():
					let excludedTraits = ["image", "imageURL", "payment_uuid", "fileExt", "fileType"]
					let traitsView = MetadataViews.dictToTraits(dict: self.getMetadata(), excludedNames: excludedTraits)
					
					// mintedTime is a unix timestamp, we should mark it with a displayType so platforms know how to show it.
					let mintedTimeStr = self.getMetadata()["mintedTime"]
					if mintedTimeStr != nil{ 
						let mintedTime = UInt64.fromString(mintedTimeStr!)
						let mintedTimeTrait = MetadataViews.Trait(name: "mintedTime", value: mintedTime, displayType: "Date", rarity: nil)
						traitsView.addTrait(mintedTimeTrait)
					}
					return traitsView
			}
			return nil
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	//------------------------------------------------------------
	// Collection Public Interface
	//------------------------------------------------------------
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMIKOSEANFTV2(id: UInt64): &MIKOSEANFTV2.NFT?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMIKOSEANFTV2s(): [&MIKOSEANFTV2.NFT]
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCommentByNftID(nftID: UInt64): [CommentData]
	}
	
	//------------------------------------------------------------
	// Collection Resource
	//------------------------------------------------------------
	access(all)
	resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		access(all)
		let commentNFTMap:{ UInt64: UInt64}
		
		init(){ 
			self.ownedNFTs <-{} 
			self.commentNFTMap ={} 
		}
		
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @MIKOSEANFTV2.NFT
			let id: UInt64 = token.id
			let oldToken <- self.ownedNFTs[id] <- token
			
			// update owner
			if self.owner?.address != nil{ 
				MIKOSEANFTV2.nftHolderMap[id] = (self.owner!).address
				emit Deposit(id: id, to: (self.owner!).address)
			}
			destroy oldToken
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMIKOSEANFTV2(id: UInt64): &MIKOSEANFTV2.NFT?{ 
			if self.ownedNFTs[id] != nil{ 
				let ref = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
				return ref as! &MIKOSEANFTV2.NFT
			} else{ 
				return nil
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowMIKOSEANFTV2s(): [&MIKOSEANFTV2.NFT]{ 
			let res: [&MIKOSEANFTV2.NFT] = []
			for id in self.ownedNFTs.keys{ 
				let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
				if ref != nil{ 
					res.append(ref! as! &MIKOSEANFTV2.NFT)
				}
			}
			return res
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCommentByNftID(nftID: UInt64): [CommentData]{ 
			return self.borrowMIKOSEANFTV2(id: nftID)?.commentData?.values ?? []
		}
		
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: (self.owner!).address)
			
			// update owner
			MIKOSEANFTV2.nftHolderMap.remove(key: withdrawID)
			
			// remove comment
			let comments = self.getCommentByNftID(nftID: withdrawID)
			for comment in comments{ 
				self.deleteComment(commentId: comment.commentId)
			}
			
			// remove is in market
			self.setInMarket(nftID: withdrawID, value: false)
			return <-token
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun transfer(nftID: UInt64, recipient: &{MIKOSEANFTV2.CollectionPublic}){ 
			post{ 
				self.ownedNFTs[nftID] == nil:
					"The specified NFT was not transferred"
			}
			let nft <- self.withdraw(withdrawID: nftID)
			recipient.deposit(token: <-nft)
			let nftData = recipient.borrowMIKOSEANFTV2(id: nftID)!
			emit NFTTransferred(nftID: nftID, nftData: *nftData.nftData, from: (self.owner!).address, to: (recipient.owner!).address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun burn(id: UInt64){ 
			post{ 
				self.ownedNFTs[id] == nil:
					"The specified NFT was not burned"
			}
			destroy <-self.withdraw(withdrawID: id)
			emit NFTDestroy(nftID: id)
		}
		
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			}
			panic("NFT not found in collection.")
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let nftAs = nft as! &MIKOSEANFTV2.NFT
			return nftAs
		}
		
		/// Safe way to borrow a reference to an NFT that does not panic
		///
		/// @param id: The ID of the NFT that want to be borrowed
		/// @return An optional reference to the desired NFT, will be nil if the passed id does not exist
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}?{ 
			if self.ownedNFTs[id] != nil{ 
				return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createComment(nftID: UInt64, comment: String){ 
			let newComment = self.borrowMIKOSEANFTV2(id: nftID)?.createComment(comment: comment) ?? panic("NFT_NOT_FOUND")
			self.commentNFTMap[newComment.commentId] = nftID
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateComment(commentId: UInt64, comment: String){ 
			let nftID = self.commentNFTMap[commentId] ?? panic("COMMENT_NOT_FOUND")
			self.borrowMIKOSEANFTV2(id: nftID)?.updateComment(commentId: commentId, comment: comment) ?? panic("NFT_NOT_FOUND")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deleteComment(commentId: UInt64){ 
			if let nftID = self.commentNFTMap[commentId]{ 
				self.borrowMIKOSEANFTV2(id: nftID)?.deleteComment(commentId: commentId)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setInMarket(nftID: UInt64, value: Bool){ 
			if let nft = self.borrowMIKOSEANFTV2(id: nftID){ 
				nft.setInMarket(value)
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateMetadata(nftID: UInt64, metadata:{ String: String}){ 
			if let nft = self.borrowMIKOSEANFTV2(id: nftID){ 
				nft.updateMetadata(metadata)
			}
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
	}
	
	// createEmptyCollection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	//------------------------------------------------------------
	// Minter
	//------------------------------------------------------------
	access(all)
	resource Minter{ 
		// mint nfts and return list of nftID
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFTs(projectId: UInt64, quantity: UInt64, images: [String], metadatas: [{String: String}], recipientCap: Capability<&{CollectionPublic}>): [UInt64]{ 
			let project = MIKOSEANFTV2.getProjectById(projectId) ?? panic("NOT_FOUND_PROJECT")
			return project.batchMintNFT(quantity: quantity, images: images, metadatas: metadatas, recipientCap: recipientCap)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun revealProject(_ projectId: UInt64){ 
			(MIKOSEANFTV2.getProjectById(projectId)!).reveal()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unRevealProject(_ projectId: UInt64){ 
			(MIKOSEANFTV2.getProjectById(projectId)!).unRevealProject()
		}
	}
	
	//------------------------------------------------------------
	// Admin
	//------------------------------------------------------------
	access(all)
	resource Admin{ 
		access(all)
		var projectData: @{UInt64: ProjectData}
		
		init(){ 
			self.projectData <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectById(_ projectId: UInt64): &ProjectData?{ 
			return &self.projectData[projectId] as &ProjectData?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjectFromNftId(_ nftID: UInt64): &ProjectData?{ 
			if nftID > 0 && nftID <= MIKOSEANFTV2.totalSupply{ 
				for projectId in self.projectData.keys{ 
					if ((&self.projectData[projectId] as &ProjectData?)!).nftMinted.contains(nftID){ 
						return &self.projectData[projectId] as &ProjectData?
					}
				}
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getProjects(): [&ProjectData]{ 
			let res: [&ProjectData] = []
			for projectId in self.projectData.keys{ 
				res.append(self.getProjectById(projectId)!)
			}
			return res
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createProject(title: String, description: String, thumbnail: String, creatorAddress: Address, platformFee: UFix64, creatorMarketFee: UFix64, platformMarketFee: UFix64, mintPrice: UFix64, maxSupply: UInt64, isPublic: Bool, metadata:{ String: AnyStruct}){ 
			let projectData <- create ProjectData(title: title, description: description, thumbnail: thumbnail, creatorAddress: creatorAddress, platformFee: platformFee, creatorMarketFee: creatorMarketFee, platformMarketFee: platformMarketFee, mintPrice: mintPrice, maxSupply: maxSupply, isPublic: isPublic, metadata: metadata)
			let old <- self.projectData[projectData.projectId] <- projectData
			destroy old
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateProject(projectId: UInt64, title: String?, description: String?, thumbnail: String?, creatorAddress: Address?, platformFee: UFix64?, creatorMarketFee: UFix64?, platformMarketFee: UFix64?, mintPrice: UFix64?, maxSupply: UInt64?, metadata:{ String: AnyStruct}?){ 
			let projectData = self.getProjectById(projectId) ?? panic("PROJECT_NOT_FOUND")
			projectData.update(title: title, description: description, thumbnail: thumbnail, creatorAddress: creatorAddress, platformFee: platformFee, creatorMarketFee: creatorMarketFee, platformMarketFee: platformMarketFee, mintPrice: mintPrice, maxSupply: maxSupply, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun publicProject(projectId: UInt64){ 
			self.getProjectById(projectId)?.public() ?? panic("PROJECT_NOT_FOUND")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun unPublicProject(projectId: UInt64){ 
			self.getProjectById(projectId)?.unPublic() ?? panic("PROJECT_NOT_FOUND")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateTokenPublicPath(_ path: PublicPath){ 
			MIKOSEANFTV2.tokenPublicPath = path
			MIKOSEANFTV2.mikoseaCap = getAccount((self.owner!).address).capabilities.get<&{FungibleToken.Receiver}>(path)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createMinter(): @Minter{ 
			return <-create Minter()
		}
	}
	
	// getOwner
	// Gets the current owner of the given item
	access(TMP_ENTITLEMENT_OWNER)
	fun getHolder(nftID: UInt64): Address?{ 
		if nftID > 0 && nftID <= self.totalSupply{ 
			return MIKOSEANFTV2.nftHolderMap[nftID]
		}
		return nil
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProjectById(_ projectId: UInt64): &ProjectData?{ 
		return (self.account.storage.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!).getProjectById(projectId)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProjectImageType(_ projectId: UInt64): String?{ 
		let str = MIKOSEANFTV2.getProjectById(projectId)?.thumbnail ?? ""
		if str.length == 0{ 
			return nil
		}
		var res = ""
		let len = str.length
		var i = str.length - 1
		while i > 0{ 
			if str[i] == "."{ 
				i = i + 1
				while i < str.length{ 
					res = res.concat(str[i].toString())
					i = i + 1
				}
				return res
			}
			i = i - 1
		}
		return res
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProjectFromNftId(_ nftID: UInt64): &ProjectData?{ 
		return (self.account.storage.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!).getProjectFromNftId(nftID)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProjects(): [&ProjectData]{ 
		return (self.account.storage.borrow<&MIKOSEANFTV2.Admin>(from: MIKOSEANFTV2.AdminStoragePath)!).getProjects()
	}
	
	//------------------------------------------------------------
	// Initializer
	//------------------------------------------------------------
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/MIKOSEANFTV2Collections
		self.CollectionPublicPath = /public/MIKOSEANFTV2Collections
		self.PrivatePath = /private/MIKOSEANFTV2PrivatePath
		self.MinterStoragePath = /storage/MIKOSEANFTV2Minters
		self.AdminStoragePath = /storage/MIKOSEANFTV2Admin
		self.AdminPublicPath = /public/MIKOSEANFTV2Admin
		
		// default token path
		self.tokenPublicPath = /public/flowTokenReceiver
		self.mikoseaCap = self.account.capabilities.get<&{FungibleToken.Receiver}>(self.tokenPublicPath)!
		self.totalSupply = 0
		self.nextProjectId = 1
		self.nextCommentId = 1
		self.nftHolderMap ={} 
		let admin <- create Admin()
		let minter <- admin.createMinter()
		self.account.storage.save(<-admin, to: self.AdminStoragePath)
		self.account.storage.save(<-minter, to: self.MinterStoragePath)
		emit ContractInitialized()
	}
}
