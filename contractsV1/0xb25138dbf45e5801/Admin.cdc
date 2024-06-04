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

	import Debug from "./Debug.cdc"

import Clock from "./Clock.cdc"

import NeoMotorcycle from "./NeoMotorcycle.cdc"

import NeoFounder from "./NeoFounder.cdc"

import NeoMember from "./NeoMember.cdc"

import NeoVoucher from "./NeoVoucher.cdc"

import NeoAvatar from "./NeoAvatar.cdc"

import NeoSticker from "./NeoSticker.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract Admin{ 
	
	/// The path to the proxy
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	/// The path to storage of the porxy
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	//Admin client to use for capability receiver pattern
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&NeoMotorcycle.Collection>): Void
	}
	
	//admin proxy with capability receiver 
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&NeoMotorcycle.Collection>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&NeoMotorcycle.Collection>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addPhysicalLink(id: UInt64, physicalLink: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			let motorcycleCap = Admin.account.capabilities.get<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath)
			((motorcycleCap.borrow()!).borrowNeoMotorcycle(id: id)!).addPhysicalLink(physicalLink)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMotorcycleName(id: UInt64, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			let motorcycleCap = Admin.account.capabilities.get<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath)
			((motorcycleCap.borrow()!).borrowNeoMotorcycle(id: id)!).setName(name)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun registerNeoVoucherMetadata(typeID: UInt64, metadata: NeoVoucher.Metadata){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			NeoVoucher.registerMetadata(typeID: typeID, metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun batchMintNeoVoucher(count: Int){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			let recipient = Admin.account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(NeoVoucher.CollectionPublicPath).borrow()!
			
			//We only have one type right now
			NeoVoucher.batchMintNFT(recipient: recipient, typeID: 1, count: count)
		}
		
		//This will consume the voucher and send the reward to the user
		access(TMP_ENTITLEMENT_OWNER)
		fun consumeNeoVoucher(voucherID: UInt64, rewardID: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			NeoVoucher.consume(voucherID: voucherID, rewardID: rewardID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNeoMember(): &{NonFungibleToken.Collection}{ 
			return Admin.account.storage.borrow<&{NonFungibleToken.Collection}>(from: NeoMember.CollectionStoragePath) ?? panic("Could not borrow a reference to the admin's collection")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getNeoVouchers(): &{NonFungibleToken.Collection}{ 
			return Admin.account.storage.borrow<&{NonFungibleToken.Collection}>(from: NeoVoucher.CollectionStoragePath) ?? panic("Could not borrow a reference to the admin's collection")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getWallet(): Capability<&{FungibleToken.Receiver}>{ 
			return Admin.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAchievementToMember(user: Address, memberId: UInt64, name: String, description: String){ 
			let userAccount = getAccount(user)
			let memberCap = userAccount.capabilities.get<&{NeoMember.CollectionPublic}>(NeoMember.CollectionPublicPath)
			let member = memberCap.borrow()!
			member.addAchievement(id: memberId, achievement: NeoMotorcycle.Achievement(name: name, description: description))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAchievementToFounder(user: Address, founderId: UInt64, name: String, description: String){ 
			let userAccount = getAccount(user)
			let founderCap = userAccount.capabilities.get<&{NeoFounder.CollectionPublic}>(NeoFounder.CollectionPublicPath)
			let founder = founderCap.borrow()!
			founder.addAchievement(id: founderId, achievement: NeoMotorcycle.Achievement(name: name, description: description))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addAchievementToTeam(teamId: UInt64, name: String, description: String){ 
			let motorcycleCap = Admin.account.capabilities.get<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath)
			((motorcycleCap.borrow()!).borrowNeoMotorcycle(id: teamId)!).addAchievement(NeoMotorcycle.Achievement(name: name, description: description))
		}
		
		/*
				pub fun mintAndAddStickerToFounder(user:Address, founderId:UInt64, name:String, description:String, thumbnailHash:String) {
					pre {
						self.capability != nil: "Cannot create Neo Admin, capability is not set"
					}
		
					let userAccount=getAccount(user)
					let founderCap=userAccount.getCapability<&{NeoFounder.CollectionPublic}>(NeoFounder.CollectionPublicPath)
		
					let founder=founderCap.borrow()!
				  let nft <- NeoSticker.mintNeoSticker(name:name, description:description, thumbnailHash:thumbnailHash)
					founder.addSticker(id: founderId, sticker: <- nft)
					
				}
		
				pub fun mintAndAddStickerToMember(user:Address, memberId:UInt64, name:String, description:String, thumbnailHash:String) {
					pre {
						self.capability != nil: "Cannot create Neo Admin, capability is not set"
					}
		
					let userAccount=getAccount(user)
					let memberCap=userAccount.getCapability<&{NeoMember.CollectionPublic}>(NeoMember.CollectionPublicPath)
		
					let member=memberCap.borrow()!
				  let nft <- NeoSticker.mintNeoSticker(name:name, description:description, thumbnailHash:thumbnailHash)
					member.addSticker(id: memberId, sticker: <- nft)
					
				}
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNeoAvatar(teamId: UInt64, series: String, role: String, mediaHash: String, wallet: Capability<&{FungibleToken.Receiver}>, collection: Capability<&{NonFungibleToken.Receiver}>){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			NeoAvatar.mint(teamId: teamId, series: series, role: role, imageHash: mediaHash, wallet: wallet, collection: collection)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNeoMotorcycle(description: String, metadata:{ String: String}){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			let motorscycle <- NeoMotorcycle.mint()
			let id = motorscycle.id
			let motorcycleCap = Admin.account.capabilities.get<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath)
			(motorcycleCap.borrow()!).deposit(token: <-motorscycle)
			let motorcyclePointer = NeoMotorcycle.Pointer(collection: motorcycleCap, id: id)
			if motorcyclePointer.resolve() == nil{ 
				panic("Invalid motorcycle id")
			}
			let nft <- NeoFounder.mint(motorcyclePointer: motorcyclePointer, description: description)
			let unique = Admin.account.storage.borrow<&NeoFounder.Collection>(from: NeoFounder.CollectionStoragePath)!
			unique.deposit(token: <-nft)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintNeoMember(edition: UInt64, maxEdition: UInt64, role: String, description: String, motorcycleId: UInt64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			let motorcycleCap = Admin.account.capabilities.get<&NeoMotorcycle.Collection>(NeoMotorcycle.CollectionPrivatePath)
			let motorcyclePointer = NeoMotorcycle.Pointer(collection: motorcycleCap, id: motorcycleId)
			if motorcyclePointer.resolve() == nil{ 
				panic("Invalid motorcycle id")
			}
			let nft <- NeoMember.mint(edition: edition, maxEdition: maxEdition, role: role, description: description, motorcyclePointer: motorcyclePointer)
			let editioned = Admin.account.storage.borrow<&NeoMember.Collection>(from: NeoMember.CollectionStoragePath)!
			editioned.deposit(token: <-nft)
		}
		
		/// Advance the clock and enable debug mode
		access(TMP_ENTITLEMENT_OWNER)
		fun advanceClock(_ time: UFix64){ 
			pre{ 
				self.capability != nil:
					"Cannot create Neo Admin, capability is not set"
			}
			Debug.enable()
			Clock.enable()
			Clock.tick(time)
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/neoAdminClient
		self.AdminProxyStoragePath = /storage/neoAdminClient
	}
}
