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

	/**

	TrmAssetV1.cdc

	Description: Contract definitions for initializing Asset Collections, Asset NFT Resource and Asset Minter

	Asset contract is used for defining the Asset NFT, Asset Collection, 
	Asset Collection Public Interface and Asset Minter

	## `NFT` resource

	The core resource type that represents an Asset NFT in the smart contract.

	## `Collection` Resource

	The resource that stores a user's Asset NFT collection.
	It includes a few functions to allow the owner to easily
	move tokens in and out of the collection.

	## `Receiver` resource interfaces

	This interface is used for depositing Asset NFTs to the Asset Collectio.
	It also exposes few functions to fetch data about Asset

	To send an NFT to another user, a user would simply withdraw the NFT
	from their Collection, then call the deposit function on another user's
	Collection to complete the transfer.

	## `Minter` Resource

	Minter resource is used for minting Asset NFTs

*/

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract TrmAssetV1: NonFungibleToken{ 
	// -----------------------------------------------------------------------
	// Asset contract Event definitions
	// -----------------------------------------------------------------------
	
	// The total number of tokens of this type in existence
	access(all)
	var totalSupply: UInt64
	
	// Event that emitted when the NFT contract is initialized
	access(all)
	event ContractInitialized()
	
	// Emitted when an Asset is minted
	access(all)
	event AssetMinted(id: UInt64, kID: String, serialNumber: UInt64, assetURL: String, assetType: String)
	
	// Emitted when an Asset is updated
	access(all)
	event AssetUpdated(id: UInt64, assetType: String)
	
	// Emitted when a batch of Assets are minted successfully
	access(all)
	event AssetBatchMinted(startId: UInt64, endId: UInt64, kID: String, assetURL: String, assetType: String, totalSerialNumbers: UInt64)
	
	// Emitted when a batch of Assets are updated successfully
	access(all)
	event AssetBatchUpdated(startId: UInt64, endId: UInt64, kID: String, assetType: String)
	
	// Emitted when an Asset is destroyed
	access(all)
	event AssetDestroyed(id: UInt64)
	
	// Event that is emitted when a token is withdrawn, indicating the owner of the collection that it was withdrawn from. If the collection is not in an account's storage, `from` will be `nil`.
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	// Event that emitted when a token is deposited to a collection. It indicates the owner of the collection that it was deposited to.
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	/// Paths where Storage and capabilities are stored
	access(all)
	let collectionStoragePath: StoragePath
	
	access(all)
	let collectionPublicPath: PublicPath
	
	access(all)
	let collectionPrivatePath: PrivatePath
	
	access(all)
	let minterStoragePath: StoragePath
	
	access(all)
	enum AssetType: UInt8{ 
		access(all)
		case private
		
		access(all)
		case public
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun assetTypeToString(_ assetType: AssetType): String{ 
		switch assetType{ 
			case AssetType.private:
				return "private"
			case AssetType.public:
				return "public"
			default:
				return ""
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun stringToAssetType(_ assetTypeStr: String): AssetType{ 
		switch assetTypeStr{ 
			case "private":
				return AssetType.private
			case "public":
				return AssetType.public
			default:
				return panic("Asset Type must be \"private\" or \"public\"")
		}
	}
	
	// AssetData
	//
	// Struct for storing metadata for Asset
	access(all)
	struct AssetData{ 
		access(all)
		let kID: String
		
		access(all)
		let serialNumber: UInt64
		
		access(all)
		let assetURL: String
		
		access(all)
		var assetType: AssetType
		
		access(contract)
		fun setAssetType(assetTypeStr: String){ 
			self.assetType = TrmAssetV1.stringToAssetType(assetTypeStr)
		}
		
		init(kID: String, serialNumber: UInt64, assetURL: String, assetTypeStr: String){ 
			pre{ 
				serialNumber >= 0:
					"Serial Number cannot be less than 0"
				kID.length > 0:
					"KID is invalid"
			}
			self.kID = kID
			self.serialNumber = serialNumber
			self.assetURL = assetURL
			self.assetType = TrmAssetV1.stringToAssetType(assetTypeStr)
		}
	}
	
	//  NFT
	//
	// The main Asset NFT resource that can be bought and sold by users
	access(all)
	resource NFT: NonFungibleToken.NFT{ 
		access(all)
		let id: UInt64
		
		access(all)
		let data: AssetData
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
		
		access(contract)
		fun setAssetType(assetType: String){ 
			self.data.setAssetType(assetTypeStr: assetType)
			emit AssetUpdated(id: self.id, assetType: assetType)
		}
		
		init(id: UInt64, kID: String, serialNumber: UInt64, assetURL: String, assetType: String){ 
			self.id = id
			self.data = AssetData(kID: kID, serialNumber: serialNumber, assetURL: assetURL, assetTypeStr: assetType)
			emit AssetMinted(id: self.id, kID: kID, serialNumber: serialNumber, assetURL: assetURL, assetType: assetType)
		}
	
	// If the Asset NFT is destroyed, emit an event to indicate to outside observers that it has been destroyed
	}
	
	// CollectionPublic
	//
	// Public interface for Asset Collection
	// This exposes functions for depositing NFTs
	// and also for returning some info for a specific
	// Asset NFT id
	access(all)
	resource interface CollectionPublic{ 
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void
		
		access(all)
		view fun getIDs(): [UInt64]
		
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAsset(id: UInt64): &TrmAssetV1.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getKID(id: UInt64): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSerialNumber(id: UInt64): UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAssetURL(id: UInt64): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAssetType(id: UInt64): String
	}
	
	// Collection
	//
	// The resource that stores a user's Asset NFT collection.
	// It includes a few functions to allow the owner to easily
	// move tokens in and out of the collection.
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, CollectionPublic{ 
		
		// Dictionary to hold the NFTs in the Collection
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Error withdrawing Asset NFT")
			emit Withdraw(id: withdrawID, from: (self.owner!).address)
			return <-token
		}
		
		// deposit takes an NFT as an argument and adds it to the Collection
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let assetToken <- token as! @NFT
			emit Deposit(id: assetToken.id, to: (self.owner!).address)
			let oldToken <- self.ownedNFTs[assetToken.id] <- assetToken
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Returns a borrowed reference to an NFT in the collection so that the caller can read data and call methods from it
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
		}
		
		// Returns a borrowed reference to the Asset in the collection so that the caller can read data and call methods from it
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowAsset(id: UInt64): &NFT{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return refNFT as! &NFT
		}
		
		// Checks if id of NFT exists in collection
		access(TMP_ENTITLEMENT_OWNER)
		fun idExists(id: UInt64): Bool{ 
			return self.ownedNFTs[id] != nil
		}
		
		// Returns the asset ID for an NFT in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getKID(id: UInt64): String{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.kID
		}
		
		// Returns the serial number for an NFT in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getSerialNumber(id: UInt64): UInt64{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.serialNumber
		}
		
		// Returns the asset URL for an NFT in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getAssetURL(id: UInt64): String{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let refAssetNFT = refNFT as! &NFT
			return refAssetNFT.data.assetURL
		}
		
		// Returns the asset type for an NFT in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun getAssetType(id: UInt64): String{ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let refAssetNFT = refNFT as! &NFT
			return TrmAssetV1.assetTypeToString(*refAssetNFT.data.assetType)
		}
		
		// Sets the asset type. Only the owner of the asset is allowed to set this
		access(TMP_ENTITLEMENT_OWNER)
		fun setAssetType(id: UInt64, assetType: String){ 
			pre{ 
				assetType == "private" || assetType == "public":
					"Asset Type must be private or public"
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			let refAssetNFT = refNFT as! &NFT
			refAssetNFT.setAssetType(assetType: assetType)
		}
		
		// Sets the asset type of multiple tokens. Only the owner of the asset is allowed to set this
		access(TMP_ENTITLEMENT_OWNER)
		fun batchSetAssetType(ids: [UInt64], kID: String, assetType: String){ 
			pre{ 
				assetType == "private" || assetType == "public":
					"Asset Type must be private or public"
				ids.length > 0:
					"Total length of ids cannot be less than 1"
			}
			for id in ids{ 
				if self.idExists(id: id){ 
					let refNFT = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
					let refAssetNFT = refNFT as! &NFT
					if refAssetNFT.data.kID != kID{ 
						panic("Asset Token ID and KID do not match")
					}
					refAssetNFT.setAssetType(assetType: assetType)
				} else{ 
					panic("Asset Token ID ".concat(id.toString()).concat(" not owned"))
				}
			}
			emit AssetBatchUpdated(startId: ids[0], endId: ids[ids.length - 1], kID: kID, assetType: assetType)
		}
		
		// Destroys specified token in the collection
		access(TMP_ENTITLEMENT_OWNER)
		fun destroyToken(id: UInt64){ 
			pre{ 
				self.ownedNFTs[id] != nil:
					"Asset Token ID does not exist"
			}
			let oldToken <- self.ownedNFTs.remove(key: id)
			destroy oldToken
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
	
	// If a transaction destroys the Collection object, all the NFTs contained within are also destroyed!
	}
	
	// createEmptyCollection creates an empty Collection and returns it to the caller so that they can own NFTs
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Minter
	//
	// Minter is a special resource that is used for minting Assets
	access(all)
	resource Minter{ 
		
		// mintNFT mints the asset NFT and stores it in the collection of recipient
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNFT(kID: String, serialNumber: UInt64, assetURL: String, assetType: String, recipient: &TrmAssetV1.Collection): UInt64{ 
			pre{ 
				assetType == "private" || assetType == "public":
					"Asset Type must be private or public"
				serialNumber >= 0:
					"Serial Number cannot be less than 0"
				kID.length > 0:
					"KID is invalid"
			}
			let tokenID = TrmAssetV1.totalSupply
			recipient.deposit(token: <-create NFT(id: tokenID, kID: kID, serialNumber: serialNumber, assetURL: assetURL, assetType: assetType))
			TrmAssetV1.totalSupply = tokenID + 1
			return TrmAssetV1.totalSupply
		}
		
		// batchMintNFTs mints the asset NFT in batch and stores it in the collection of recipient
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintNFTs(kID: String, totalSerialNumbers: UInt64, assetURL: String, assetType: String, recipient: &TrmAssetV1.Collection): UInt64{ 
			pre{ 
				assetType == "private" || assetType == "public":
					"Asset Type must be private or public"
				totalSerialNumbers > 0:
					"Total Serial Numbers cannot be less than 1"
				assetURL.length > 0:
					"Asset URL is invalid"
				kID.length > 0:
					"KID is invalid"
			}
			let startTokenID = TrmAssetV1.totalSupply
			var tokenID = startTokenID
			var counter: UInt64 = 0
			while counter < totalSerialNumbers{ 
				recipient.deposit(token: <-create NFT(id: tokenID, kID: kID, serialNumber: counter, assetURL: assetURL, assetType: assetType))
				counter = counter + 1
				tokenID = tokenID + 1
			}
			let endTokenID = tokenID - 1
			emit AssetBatchMinted(startId: startTokenID, endId: endTokenID, kID: kID, assetURL: assetURL, assetType: assetType, totalSerialNumbers: totalSerialNumbers)
			TrmAssetV1.totalSupply = tokenID
			return TrmAssetV1.totalSupply
		}
	}
	
	init(){ 
		self.totalSupply = 0
		self.collectionStoragePath = /storage/trmAssetV1Collection
		self.collectionPublicPath = /public/trmAssetV1Collection
		self.collectionPrivatePath = /private/trmAssetV1Collection
		self.minterStoragePath = /storage/trmAssetV1Minter
		
		// First, check to see if a minter resource already exists
		if self.account.storage.borrow<&TrmAssetV1.Minter>(from: self.minterStoragePath) == nil{ 
			
			// Put the minter in storage with access only to admin
			self.account.storage.save(<-create Minter(), to: self.minterStoragePath)
		}
		emit ContractInitialized()
	}
}
