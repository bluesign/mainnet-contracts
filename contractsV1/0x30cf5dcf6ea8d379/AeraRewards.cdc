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

import FindViews from "../0x097bafa4e0b48eef/FindViews.cdc"

import AeraNFT from "./AeraNFT.cdc"

import Clock from "./Clock.cdc"

/*
Aera Reward is the NFT for fulfilling all the required panels for a chapter
consists of thumbnail and a DVM
*/

access(all)
contract AeraRewards: NonFungibleToken{ 
	access(all)
	var totalSupply: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	// TODO: discuss richer event: title, description, image, recipient
	access(all)
	event Minted(id: UInt64, address: Address, reward_template_id: UInt64, edition: UInt64)
	
	// we cannot have address here as it will always be nil
	access(all)
	event Burned(id: UInt64, reward_template_id: UInt64, edition: UInt64)
	
	access(all)
	event RewardMetadataRegistered(reward_template_id: UInt64, reward_name: String, thumbnail: String, video: String, max_quantity: UInt64?)
	
	access(all)
	event RewardClaimed(id: UInt64, address: Address, rewardTemplateId: UInt64, rewardName: String, description: String, thumbnailHash: String, edition: UInt64, type: String, soulBounded: Bool, rarity: String, rewardFields:{ UInt64:{ String: String}})
	
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(account)
	let royalties: [MetadataViews.Royalty]
	
	access(all)
	let rewardTemplates:{ UInt64: MintDetail}
	
	access(all)
	var currentSerial: UInt64
	
	access(all)
	struct RewardClaimedData{ 
		access(all)
		let data:{ String: String}
		
		init(_ data:{ String: String}){ 
			self.data = data
		}
	}
	
	access(all)
	struct MintDetail{ 
		access(all)
		let reward_template: RewardTemplate
		
		access(all)
		var current_edition: UInt64
		
		access(all)
		var total_supply: UInt64
		
		access(all)
		let max_quantity: UInt64?
		
		init(reward_template: RewardTemplate, current_edition: UInt64, total_supply: UInt64, max_quantity: UInt64?){ 
			self.reward_template = reward_template
			self.current_edition = current_edition
			self.total_supply = total_supply
			self.max_quantity = max_quantity
		}
		
		access(account)
		fun mint(): MintDetail{ 
			pre{ 
				self.max_quantity == nil || self.max_quantity! >= self.current_edition + UInt64(1):
					"Cannot mint reward with edition greater than max quantity"
			}
			self.current_edition = self.current_edition + 1
			self.total_supply = self.total_supply + 1
			return self
		}
		
		access(account)
		fun burn(){ 
			self.total_supply = self.total_supply - 1
		}
	}
	
	access(all)
	struct Media{ 
		access(all)
		let name: String
		
		access(all)
		let media_type: String
		
		access(all)
		let ipfs_hash: String
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(name: String, media_type: String, ipfs_hash: String){ 
			self.name = name
			self.media_type = media_type
			self.ipfs_hash = ipfs_hash
			self.extra ={} 
		}
	}
	
	access(all)
	struct RewardTemplate{ 
		access(all)
		let reward_template_id: UInt64
		
		access(all)
		let reward_name: String
		
		access(all)
		let description: String
		
		access(all)
		let thumbnail_hash: String
		
		access(all)
		let video_hash: String
		
		access(all)
		let video_file: String
		
		access(all)
		let video_type: String
		
		// for struct's use only
		access(all)
		var edition: UInt64
		
		access(all)
		let files: [Media]
		
		access(all)
		let type: String
		
		access(all)
		let detail_id:{ String: UInt64}
		
		access(all)
		let traits: [MetadataViews.Trait]
		
		access(all)
		let soulBounded: Bool
		
		access(all)
		let rarity: String
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(reward_template_id: UInt64, reward_name: String, description: String, thumbnail_hash: String, video_hash: String, video_file: String, video_type: String, files: [Media], type: String, detail_id:{ String: UInt64}, traits: [MetadataViews.Trait], soulBounded: Bool, rarity: String){ 
			pre{ 
				video_hash == "" && video_file != "" || video_file == "" && video_hash != "":
					"Requires either video_file or video_hash to be empty string"
			}
			self.reward_template_id = reward_template_id
			self.reward_name = reward_name
			self.description = description
			self.thumbnail_hash = thumbnail_hash
			self.video_hash = video_hash
			self.video_file = video_file
			self.video_type = video_type
			self.extra ={} 
			self.edition = 0
			self.type = type
			self.detail_id = detail_id
			self.traits = traits
			self.files = files
			self.soulBounded = soulBounded
			self.rarity = rarity
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPlayer(): AeraNFT.Player?{ 
			if let p = self.detail_id["player_id"]{ 
				return AeraNFT.getPlayer(p)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getLicense(): AeraNFT.License?{ 
			if let id = self.detail_id["license_id"]{ 
				return AeraNFT.getLicense(id)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFiles(): [MetadataViews.Media]{ 
			var m: [MetadataViews.Media] = []
			for f in self.files{ 
				m.append(MetadataViews.Media(file: MetadataViews.IPFSFile(cid: f.ipfs_hash, path: nil), mediaType: f.media_type))
			}
			return m
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFileAsTraits(): [MetadataViews.Trait]{ 
			var t: [MetadataViews.Trait] = []
			for f in self.files{ 
				t.append(MetadataViews.Trait(name: f.name, value: "ipfs://".concat(f.ipfs_hash), displayType: "string", rarity: nil))
			}
			return t
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getVideoAsFile():{ MetadataViews.File}{ 
			if self.video_hash != ""{ 
				return MetadataViews.IPFSFile(cid: self.video_hash, path: nil)
			}
			return MetadataViews.HTTPFile(url: self.video_file)
		}
	}
	
	access(account)
	fun addRewardTemplate(reward: RewardTemplate, maxQuantity: UInt64?){ 
		let mintDetail = MintDetail(reward_template: reward, current_edition: 0, total_supply: 0, max_quantity: maxQuantity)
		self.rewardTemplates[reward.reward_template_id] = mintDetail
		emit RewardMetadataRegistered(reward_template_id: reward.reward_template_id, reward_name: reward.reward_name, thumbnail: "ipfs://".concat(reward.thumbnail_hash), video: reward.getVideoAsFile().uri(), max_quantity: maxQuantity)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getReward(_ id: UInt64): RewardTemplate{ 
		return (AeraRewards.rewardTemplates[id]!).reward_template
	}
	
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(all)
		let reward_template_id: UInt64
		
		access(all)
		let serial: UInt64
		
		access(all)
		let edition: UInt64
		
		access(all)
		let max_edition: UInt64?
		
		access(all)
		var nounce: UInt64
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(reward_template_id: UInt64, serial: UInt64, edition: UInt64, max_edition: UInt64?){ 
			self.reward_template_id = reward_template_id
			self.nounce = 0
			self.id = self.uuid
			self.serial = serial
			self.edition = edition
			self.max_edition = max_edition
			self.extra ={ "mintedAt": Clock.time()}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReward(): AeraRewards.RewardTemplate{ 
			return (AeraRewards.rewardTemplates[self.reward_template_id]!).reward_template
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getMintedAt(): UFix64?{ 
			if let minted = self.extra["mintedAt"]{ 
				let res = minted as! UFix64
				return res
			}
			return nil
		}
		
		access(all)
		view fun getViews(): [Type]{ 
			let views: [Type] = [Type<MetadataViews.Display>(), Type<MetadataViews.Medias>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.Serial>(), Type<MetadataViews.Editions>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Rarity>(), Type<AeraNFT.License>(), Type<RewardTemplate>()]
			let reward = (AeraRewards.rewardTemplates[self.reward_template_id]!).reward_template
			if reward.soulBounded{ 
				views.append(Type<FindViews.SoulBound>())
			}
			return views
		}
		
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let reward = self.getReward()
			let thumbnail = MetadataViews.IPFSFile(cid: reward.thumbnail_hash, path: nil)
			let ipfsVideo = reward.getVideoAsFile()
			
			// mind the mediaType here, to be confirmed
			let thumbnailMedia = MetadataViews.Media(file: thumbnail, mediaType: "image/png")
			let media = MetadataViews.Media(file: ipfsVideo, mediaType: reward.video_type)
			switch view{ 
				case Type<MetadataViews.Display>():
					let name = reward.reward_name
					// Question : Any preferred description on rewrad NFT?
					let description = reward.description
					let thumbnail = thumbnail
					return MetadataViews.Display(name: name, description: description, thumbnail: thumbnail)
				case Type<MetadataViews.ExternalURL>():
					if let addr = self.owner?.address{ 
						return MetadataViews.ExternalURL("https://aera.onefootball.com/collectibles/".concat(addr.toString()).concat("/rewards/").concat(self.id.toString()))
					}
					return MetadataViews.ExternalURL("https://aera.onefootball.com/collectibles/")
				case Type<MetadataViews.Royalties>():
					// return MetadataViews.Royalties(AeraRewards.royalties)
					var address = AeraRewards.account.address
					if address == 0x46625f59708ec2f8{ 
						//testnet merchant address
						address = 0x4ff956c78244911b
					} else if address == 0x30cf5dcf6ea8d379{ 
						//mainnet merchant address
						address = 0xa9277dcbec7769df
					}
					let ducReceiver = getAccount(address).capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
					return MetadataViews.Royalties([MetadataViews.Royalty(receiver: ducReceiver!, cut: 0.06, description: "onefootball largest of 6% or 0.65")])
				case Type<MetadataViews.Medias>():
					let m = [thumbnailMedia, media]
					let r = self.getReward()
					m.appendAll(r.getFiles())
					return MetadataViews.Medias(m)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let externalURL = MetadataViews.ExternalURL("http://aera.onefootbal.com")
					let squareImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafkreiameqwyluog75u7zg3dmf56b5mbed7cdgv6uslkph6nvmdf2aipmy", path: nil), mediaType: "image/jpg")
					let bannerImage = MetadataViews.Media(file: MetadataViews.IPFSFile(cid: "bafybeiayhvr2sm4lco3tbsa74blynlnzhhzrjouteyqaq43giuyiln4xb4", path: nil), mediaType: "image/png")
					let socialMap:{ String: MetadataViews.ExternalURL} ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/aera_football"), "discord": MetadataViews.ExternalURL("https://discord.gg/aera"), "instagram": MetadataViews.ExternalURL("https://www.instagram.com/aera_football/")}
					return MetadataViews.NFTCollectionDisplay(name: "Aera Rewards", description: "Aera by OneFootball", externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage, socials: socialMap)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: AeraRewards.CollectionStoragePath, publicPath: AeraRewards.CollectionPublicPath, publicCollection: Type<&Collection>(), publicLinkedType: Type<&Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-AeraRewards.createEmptyCollection(nftType: Type<@AeraRewards.Collection>())
						})
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(self.serial)
				case Type<MetadataViews.Editions>():
					return MetadataViews.Editions([MetadataViews.Edition(name: "set", number: self.edition, max: self.max_edition)])
				case Type<MetadataViews.Traits>():
					let ts: [MetadataViews.Trait] = [MetadataViews.Trait(name: "reward_template_id", value: self.reward_template_id, displayType: "number", rarity: nil)]
					for detail in reward.detail_id.keys{ 
						ts.append(MetadataViews.Trait(name: detail, value: reward.detail_id[detail], displayType: "number", rarity: nil))
					}
					if let l = reward.getLicense(){ 
						ts.append(MetadataViews.Trait(name: "copyright", value: l.copyright, displayType: "string", rarity: nil))
					}
					if let player = reward.getPlayer(){ 
						ts.appendAll([MetadataViews.Trait(name: "player_jersey_name", value: player.jerseyname, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_position", value: player.position, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_number", value: player.number, displayType: "number", rarity: nil), MetadataViews.Trait(name: "player_nationality", value: player.nationality, displayType: "string", rarity: nil), MetadataViews.Trait(name: "player_birthday", value: player.birthday, displayType: "date", rarity: nil)])
					}
					if let m = self.getMintedAt(){ 
						ts.append(MetadataViews.Trait(name: "minted_at", value: m, displayType: "date", rarity: nil))
					}
					let r = self.getReward()
					ts.appendAll(r.getFileAsTraits())
					ts.appendAll(r.traits)
					return MetadataViews.Traits(ts)
				case Type<AeraNFT.License>():
					if let license = reward.getLicense(){ 
						return license
					}
					return nil
				case Type<AeraRewards.RewardTemplate>():
					return (AeraRewards.rewardTemplates[self.reward_template_id]!).reward_template
				case Type<FindViews.SoulBound>():
					let reward = (AeraRewards.rewardTemplates[self.reward_template_id]!).reward_template
					if reward.soulBounded{ 
						return FindViews.SoulBound("This reward is soulBounded and canned be moved. Cannot be moved. ID ".concat(self.id.toString()))
					}
					return nil
				case Type<MetadataViews.Rarity>():
					let reward = (AeraRewards.rewardTemplates[self.reward_template_id]!).reward_template
					return MetadataViews.Rarity(score: nil, max: nil, description: reward.rarity)
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun increaseNounce(){ 
			self.nounce = self.nounce + 1
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		init(){ 
			self.ownedNFTs <-{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun hasNFT(_ id: UInt64): Bool{ 
			return self.ownedNFTs.containsKey(id)
		}
		
		// TODO: discuss ownedIdsFromReward(rewardTemplateId: UInt64): [UInt64] {}
		// withdraw removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @NFT
			let id: UInt64 = token.id
			token.increaseNounce()
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// getIDs returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Reward NFT ID : ".concat(id.toString())
			}
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowRewardNFT(id: UInt64): &AeraRewards.NFT{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Reward NFT ID : ".concat(id.toString())
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			return nft as! &AeraRewards.NFT
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			pre{ 
				self.ownedNFTs.containsKey(id):
					"Cannot borrow reference to Reward NFT ID : ".concat(id.toString())
			}
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let aerarewardNFT = nft as! &NFT
			return aerarewardNFT as &{ViewResolver.Resolver}
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
	
	// public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// mintNFT mints a new NFT with a new ID
	// and deposit it in the recipients collection using their collection reference
	//The distinction between sending in a reference and sending in a capability is that when you send in a reference it cannot be stored. So it can only be used in this method
	//while a capability can be stored and used later. So in this case using a reference is the right choice, but it needs to be owned so that you can have a good event
	access(account)
	fun mintNFT(recipient: &{NonFungibleToken.Receiver}, rewardTemplateId: UInt64, rewardFields:{ UInt64:{ String: String}}): UInt64{ 
		pre{ 
			recipient.owner != nil:
				"Recipients NFT collection is not owned"
			self.rewardTemplates.containsKey(rewardTemplateId):
				"Reward template does not exist. ID : ".concat(rewardTemplateId.toString())
		}
		AeraRewards.totalSupply = AeraRewards.totalSupply + 1
		AeraRewards.currentSerial = AeraRewards.currentSerial + 1
		let rewardMintDetail = (self.rewardTemplates[rewardTemplateId]!).mint()
		// create a new NFT
		var newNFT <- create NFT(reward_template_id: rewardTemplateId, serial: AeraRewards.currentSerial, edition: rewardMintDetail.current_edition, max_edition: rewardMintDetail.max_quantity)
		let t = rewardMintDetail.reward_template
		//Always emit events on state changes! always contain human readable and machine readable information
		emit Minted(id: newNFT.id, address: (recipient.owner!).address, reward_template_id: rewardTemplateId, edition: rewardMintDetail.current_edition)
		emit RewardClaimed(id: newNFT.id, address: (recipient.owner!).address, rewardTemplateId: t.reward_template_id, rewardName: t.reward_name, description: t.description, thumbnailHash: t.thumbnail_hash, edition: rewardMintDetail.current_edition, type: t.type, soulBounded: t.soulBounded, rarity: t.rarity, rewardFields: rewardFields)
		
		// deposit it in the recipient's account using their reference
		let id = newNFT.id
		recipient.deposit(token: <-newNFT)
		return id
	}
	
	access(account)
	fun addRoyaltycut(_ cutInfo: MetadataViews.Royalty){ 
		var cutInfos = self.royalties
		cutInfos.append(cutInfo)
		// for validation only
		let royalties = MetadataViews.Royalties(cutInfos)
		self.royalties.append(cutInfo)
	}
	
	init(){ 
		// Initialize the total supply
		self.totalSupply = 0
		self.currentSerial = 0
		self.rewardTemplates ={} 
		
		// Set Royalty cuts in a transaction
		self.royalties = []
		
		// Set the named paths
		self.CollectionStoragePath = /storage/aeraRewardsNFT
		self.CollectionPublicPath = /public/aeraRewardsNFT
		self.CollectionPrivatePath = /private/aeraRewardsNFT
		self.account.storage.save<@{NonFungibleToken.Collection}>(<-AeraRewards.createEmptyCollection(nftType: Type<@AeraRewards.Collection>()), to: AeraRewards.CollectionStoragePath)
		var capability_1 = self.account.capabilities.storage.issue<&AeraRewards.Collection>(AeraRewards.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: AeraRewards.CollectionPublicPath)
		var capability_2 = self.account.capabilities.storage.issue<&AeraRewards.Collection>(AeraRewards.CollectionStoragePath)
		self.account.capabilities.publish(capability_2, at: AeraRewards.CollectionPrivatePath)
		emit ContractInitialized()
	}
}
