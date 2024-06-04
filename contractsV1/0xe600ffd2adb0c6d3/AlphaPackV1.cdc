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

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FiatToken from "./../../standardsV1/FiatToken.cdc"

import AlphaNFTV1 from "./AlphaNFTV1.cdc"

access(all)
contract AlphaPackV1{ 
	// event when a pack is bought
	access(all)
	event PackBought(templateId: UInt64, receiptAddress: Address?)
	
	access(all)
	event PurchaseDetails(
		buyer: Address,
		momentsInPack: [{
			
				String: UInt64
			}
		],
		pricePaid: UFix64,
		packID: UInt64,
		settledOnChain: Bool
	)
	
	// event when a pack is opened
	access(all)
	event PackOpened(nftId: UInt64, receiptAddress: Address?)
	
	// path for pack storage
	access(all)
	let PackStoragePath: StoragePath
	
	// path for pack public
	access(all)
	let PackPublicPath: PublicPath
	
	access(self)
	var ownerAddress: Address
	
	access(contract)
	let adminRef: Capability<&FiatToken.Vault>
	
	access(all)
	resource interface PackPublic{ 
		// making this function public to call by authorized users
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(packNFT: @AlphaNFTV1.NFT, receiptAddress: Address): Void
	}
	
	access(all)
	resource Pack: PackPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun updateOwnerAddress(owner: Address){ 
			pre{ 
				owner != nil:
					"owner must not be null"
			}
			AlphaPackV1.ownerAddress = owner
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buyPackFromAdmin(templateIds: [{String: UInt64}], packTemplateId: UInt64, receiptAddress: Address, price: UFix64){ 
			pre{ 
				templateIds.length > 0:
					"template id  must not be zero"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [{String: UInt64}] = []
			for tempID in templateIds{ 
				let nftTemplateData = AlphaNFTV1.getTemplateById(templateId: tempID["id"]!)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AlphaNFTV1.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AlphaNFTV1.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let nextTemplateId = AlphaNFTV1.getLatestTemplateId()
			AlphaNFTV1.mintNFT(templateInfo:{ "id": nextTemplateId}, account: receiptAddress)
			(AlphaNFTV1.templates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: nextTemplateId, receiptAddress: receiptAddress)
			emit PurchaseDetails(buyer: receiptAddress, momentsInPack: templateIds, pricePaid: price, packID: packTemplateId, settledOnChain: false)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun buyPack(templateIds: [{String: UInt64}], packTemplateId: UInt64, receiptAddress: Address, price: UFix64, flowPayment: @{FungibleToken.Vault}){ 
			pre{ 
				templateIds.length > 0:
					"template id  must not be zero"
				flowPayment.balance == price:
					"Your vault does not have balance to buy NFT"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var allNftTemplateExists = true
			assert(templateIds.length <= 10, message: "templates limit exceeded")
			let nftTemplateIds: [{String: UInt64}] = []
			for tempID in templateIds{ 
				let nftTemplateData = AlphaNFTV1.getTemplateById(templateId: tempID["id"]!)
				if nftTemplateData == nil{ 
					allNftTemplateExists = false
					break
				}
				nftTemplateIds.append(tempID)
			}
			let originalPackTemplateData = AlphaNFTV1.getTemplateById(templateId: packTemplateId)
			let originalPackTemplateImmutableData = originalPackTemplateData.getImmutableData()
			originalPackTemplateImmutableData["nftTemplates"] = nftTemplateIds
			assert(allNftTemplateExists, message: "Invalid NFTs")
			AlphaNFTV1.createTemplate(maxSupply: 1, immutableData: originalPackTemplateImmutableData)
			let nextTemplateId = AlphaNFTV1.getLatestTemplateId()
			let receiptAccount = getAccount(AlphaPackV1.ownerAddress)
			let recipientCollection = receiptAccount.capabilities.get<&FiatToken.Vault>(FiatToken.VaultReceiverPubPath).borrow<&FiatToken.Vault>() ?? panic("Could not get receiver reference to the flow receiver")
			recipientCollection.deposit(from: <-flowPayment)
			AlphaNFTV1.mintNFT(templateInfo:{ "id": nextTemplateId}, account: receiptAddress)
			(AlphaNFTV1.templates[packTemplateId]!).incrementIssuedSupply()
			emit PackBought(templateId: nextTemplateId, receiptAddress: receiptAddress)
			emit PurchaseDetails(buyer: receiptAddress, momentsInPack: templateIds, pricePaid: price, packID: packTemplateId, settledOnChain: true)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(packNFT: @AlphaNFTV1.NFT, receiptAddress: Address){ 
			pre{ 
				packNFT != nil:
					"pack nft must not be null"
				receiptAddress != nil:
					"receipt address must not be null"
			}
			var packNFTData = AlphaNFTV1.getNFTData(nftId: packNFT.id)
			var packTemplateData = AlphaNFTV1.getTemplateById(templateId: packNFTData.templateId)
			let templateImmutableData = packTemplateData.getImmutableData()
			let allIds = templateImmutableData["nftTemplates"]! as! [AnyStruct]
			let packSlug = templateImmutableData["slug"]! as! String
			assert(allIds.length <= 10, message: "templates limit exceeded")
			for tempID in allIds{ 
				if packSlug == "ripper-skippers"{ 
					let templateInfo ={ "id": tempID as! UInt64}
					AlphaNFTV1.mintNFT(templateInfo: templateInfo!, account: receiptAddress)
				} else{ 
					let templateInfo = tempID as?{ String: UInt64}
					AlphaNFTV1.mintNFT(templateInfo: templateInfo!, account: receiptAddress)
				}
			}
			emit PackOpened(nftId: packNFT.id, receiptAddress: self.owner?.address)
			destroy packNFT
		}
		
		init(){} 
	}
	
	init(){ 
		self.ownerAddress = (self.account!).address
		self.adminRef = self.account.capabilities.get<&FiatToken.Vault>(
				FiatToken.VaultReceiverPubPath
			)!
		self.PackStoragePath = /storage/AlphaPackV1
		self.PackPublicPath = /public/AlphaPackV1
		self.account.storage.save(<-create Pack(), to: self.PackStoragePath)
		var capability_1 =
			self.account.capabilities.storage.issue<&{PackPublic}>(self.PackStoragePath)
		self.account.capabilities.publish(capability_1, at: self.PackPublicPath)
	}
}
