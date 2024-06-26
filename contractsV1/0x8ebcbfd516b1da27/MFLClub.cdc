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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import MFLAdmin from "./MFLAdmin.cdc"

/**
  This contract is based on the NonFungibleToken standard on Flow.
  It allows an admin to mint clubs (NFTs) and squads. Clubs and squads have metadata that can be updated by an admin.
**/

access(all)
contract MFLClub: NonFungibleToken{ 
	
	// Global Events
	access(all)
	event ContractInitialized()
	
	// Clubs Events
	access(all)
	event Withdraw(id: UInt64, from: Address?)
	
	access(all)
	event Deposit(id: UInt64, to: Address?)
	
	access(all)
	event ClubMinted(id: UInt64)
	
	access(all)
	event ClubStatusUpdated(id: UInt64, status: UInt8)
	
	access(all)
	event ClubMetadataUpdated(id: UInt64)
	
	access(all)
	event ClubSquadsIDsUpdated(id: UInt64, squadsIDs: [UInt64])
	
	access(all)
	event ClubDestroyed(id: UInt64)
	
	access(all)
	event ClubInfoUpdateRequested(id: UInt64, info:{ String: String})
	
	access(all)
	event ClubFounded(id: UInt64, from: Address?, name: String, description: String, foundationDate: UFix64, foundationLicenseSerialNumber: UInt64?, foundationLicenseCity: String?, foundationLicenseCountry: String?, foundationLicenseSeason: UInt32?)
	
	// Squads Events
	access(all)
	event SquadMinted(id: UInt64)
	
	access(all)
	event SquadDestroyed(id: UInt64)
	
	access(all)
	event SquadMetadataUpdated(id: UInt64)
	
	access(all)
	event SquadCompetitionMembershipAdded(id: UInt64, competitionID: UInt64)
	
	access(all)
	event SquadCompetitionMembershipUpdated(id: UInt64, competitionID: UInt64)
	
	access(all)
	event SquadCompetitionMembershipRemoved(id: UInt64, competitionID: UInt64)
	
	// Named Paths
	access(all)
	let CollectionStoragePath: StoragePath
	
	access(all)
	let CollectionPrivatePath: PrivatePath
	
	access(all)
	let CollectionPublicPath: PublicPath
	
	access(all)
	let ClubAdminStoragePath: StoragePath
	
	access(all)
	let SquadAdminStoragePath: StoragePath
	
	// The total number of clubs that have been minted
	access(all)
	var totalSupply: UInt64
	
	// All clubs datas are stored in this dictionary
	access(self)
	let clubsDatas:{ UInt64: ClubData}
	
	// The total number of squads that have been minted
	access(all)
	var squadsTotalSupply: UInt64
	
	// All squads data are stored in this dictionary
	access(self)
	let squadsDatas:{ UInt64: SquadData}
	
	access(all)
	enum SquadStatus: UInt8{ 
		access(all)
		case ACTIVE
	}
	
	access(all)
	struct SquadData{ 
		access(all)
		let id: UInt64
		
		access(all)
		let clubID: UInt64
		
		access(all)
		let type: String
		
		access(self)
		var status: SquadStatus
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		access(self)
		var competitionsMemberships:{ UInt64: AnyStruct} // {competitionID: AnyStruct}
		
		
		init(id: UInt64, clubID: UInt64, type: String, metadata:{ String: AnyStruct}, competitionsMemberships:{ UInt64: AnyStruct}){ 
			self.id = id
			self.clubID = clubID
			self.type = type
			self.status = SquadStatus.ACTIVE
			self.metadata = metadata
			self.competitionsMemberships ={} 
			for competitionID in competitionsMemberships.keys{ 
				self.addCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionsMemberships[competitionID])
			}
		}
		
		// Getter for metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		// Setter for metadata
		access(contract)
		fun setMetadata(metadata:{ String: AnyStruct}){ 
			self.metadata = metadata
			emit SquadMetadataUpdated(id: self.id)
		}
		
		// Getter for competitionsMemberships
		access(TMP_ENTITLEMENT_OWNER)
		fun getCompetitionsMemberships():{ UInt64: AnyStruct}{ 
			return self.competitionsMemberships
		}
		
		// Add competitionMembership
		access(contract)
		fun addCompetitionMembership(competitionID: UInt64, competitionMembershipData: AnyStruct){ 
			self.competitionsMemberships.insert(key: competitionID, competitionMembershipData)
			emit SquadCompetitionMembershipAdded(id: self.id, competitionID: competitionID)
		}
		
		// Update competitionMembership
		access(contract)
		fun updateCompetitionMembership(competitionID: UInt64, competitionMembershipData: AnyStruct){ 
			pre{ 
				self.competitionsMemberships[competitionID] != nil:
					"Competition membership not found"
			}
			self.competitionsMemberships[competitionID] = competitionMembershipData
			emit SquadCompetitionMembershipUpdated(id: self.id, competitionID: competitionID)
		}
		
		// Remove competitionMembership
		access(contract)
		fun removeCompetitionMembership(competitionID: UInt64){ 
			self.competitionsMemberships.remove(key: competitionID)
			emit SquadCompetitionMembershipRemoved(id: self.id, competitionID: competitionID)
		}
		
		// Getter for status
		access(TMP_ENTITLEMENT_OWNER)
		fun getStatus(): SquadStatus{ 
			return self.status
		}
	}
	
	access(all)
	resource Squad{ 
		access(all)
		let id: UInt64
		
		access(all)
		let clubID: UInt64
		
		access(all)
		let type: String
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(id: UInt64, clubID: UInt64, type: String, nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}, competitionsMemberships:{ UInt64: AnyStruct}){ 
			pre{ 
				MFLClub.getSquadData(id: id) == nil:
					"Squad already exists"
			}
			self.id = id
			self.clubID = clubID
			self.type = type
			self.metadata = nftMetadata
			MFLClub.squadsTotalSupply = MFLClub.squadsTotalSupply + 1 as UInt64
			
			// Set squad data
			MFLClub.squadsDatas[id] = MFLClub.SquadData(id: id, clubID: clubID, type: type, metadata: metadata, competitionsMemberships: competitionsMemberships)
			emit SquadMinted(id: self.id)
		}
	}
	
	access(all)
	enum ClubStatus: UInt8{ 
		access(all)
		case NOT_FOUNDED
		
		access(all)
		case PENDING_VALIDATION
		
		access(all)
		case FOUNDED
	}
	
	// Data stored in clubsDatas. Updatable by an admin
	access(all)
	struct ClubData{ 
		access(all)
		let id: UInt64
		
		access(self)
		var status: ClubStatus
		
		access(self)
		var squadsIDs: [UInt64]
		
		access(self)
		var metadata:{ String: AnyStruct}
		
		init(id: UInt64, status: ClubStatus, squadsIDs: [UInt64], metadata:{ String: AnyStruct}){ 
			self.id = id
			self.status = status
			self.squadsIDs = squadsIDs
			self.metadata = metadata
		}
		
		// Getter for status
		access(TMP_ENTITLEMENT_OWNER)
		fun getStatus(): ClubStatus{ 
			return self.status
		}
		
		// Setter for status
		access(contract)
		fun setStatus(status: ClubStatus){ 
			self.status = status
			emit ClubStatusUpdated(id: self.id, status: self.status.rawValue)
		}
		
		// Getter for squadsIDs
		access(TMP_ENTITLEMENT_OWNER)
		fun getSquadIDs(): [UInt64]{ 
			return self.squadsIDs
		}
		
		// Setter for squadsIDs
		access(contract)
		fun setSquadsIDs(squadsIDs: [UInt64]){ 
			self.squadsIDs = squadsIDs
			emit ClubSquadsIDsUpdated(id: self.id, squadsIDs: self.squadsIDs)
		}
		
		// Getter for metadata
		access(TMP_ENTITLEMENT_OWNER)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		// Setter for metadata
		access(contract)
		fun setMetadata(metadata:{ String: AnyStruct}){ 
			self.metadata = metadata
			emit ClubMetadataUpdated(id: self.id)
		}
	}
	
	// The resource that represents the Club NFT
	access(all)
	resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver{ 
		access(all)
		let id: UInt64
		
		access(self)
		let squads: @{UInt64: Squad}
		
		access(self)
		let metadata:{ String: AnyStruct}
		
		init(id: UInt64, squads: @[Squad], nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}){ 
			pre{ 
				MFLClub.getClubData(id: id) == nil:
					"Club already exists"
			}
			self.id = id
			self.squads <-{} 
			self.metadata = nftMetadata
			let squadsIDs: [UInt64] = []
			var i = 0
			while i < squads.length{ 
				squadsIDs.append(squads[i].id)
				let oldSquad <- self.squads[squads[i].id] <- squads.remove(at: i)
				destroy oldSquad
				i = i + 1
			}
			destroy squads
			MFLClub.totalSupply = MFLClub.totalSupply + 1 as UInt64
			
			// Set club data
			MFLClub.clubsDatas[id] = ClubData(id: self.id, status: ClubStatus.NOT_FOUNDED, squadsIDs: squadsIDs, metadata: metadata)
			emit ClubMinted(id: self.id)
		}
		
		// Get all supported views for this NFT
		access(all)
		view fun getViews(): [Type]{ 
			return [Type<MetadataViews.Display>(), Type<MetadataViews.Royalties>(), Type<MetadataViews.NFTCollectionDisplay>(), Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.ExternalURL>(), Type<MetadataViews.Traits>(), Type<MetadataViews.Serial>()]
		}
		
		// Resolve a specific view
		access(all)
		fun resolveView(_ view: Type): AnyStruct?{ 
			let clubData = MFLClub.getClubData(id: self.id)!
			switch view{ 
				case Type<MetadataViews.Display>():
					if clubData.getStatus() == ClubStatus.NOT_FOUNDED{ 
						return MetadataViews.Display(name: "Club License #".concat(clubData.id.toString()), description: "MFL Club License #".concat(clubData.id.toString()), thumbnail: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/clubs/".concat(clubData.id.toString()).concat("/licenses/foundation.png")))
					} else{ 
						return MetadataViews.Display(name: clubData.getMetadata()["name"] as! String? ?? "", description: clubData.getMetadata()["description"] as! String? ?? "", thumbnail: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/u/clubs/".concat(clubData.id.toString()).concat("/logo.png")))
					}
				case Type<MetadataViews.Royalties>():
					let royalties: [MetadataViews.Royalty] = []
					let royaltyReceiverCap = getAccount(MFLAdmin.royaltyAddress()).capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
					royalties.append(MetadataViews.Royalty(receiver: royaltyReceiverCap!, cut: 0.05, description: "Creator Royalty"))
					return MetadataViews.Royalties(royalties)
				case Type<MetadataViews.NFTCollectionDisplay>():
					let socials ={ "twitter": MetadataViews.ExternalURL("https://twitter.com/playMFL"), "discord": MetadataViews.ExternalURL("https://discord.gg/pEDTR4wSPr"), "linkedin": MetadataViews.ExternalURL("https://www.linkedin.com/company/playmfl"), "medium": MetadataViews.ExternalURL("https://medium.com/playmfl")}
					return MetadataViews.NFTCollectionDisplay(name: "MFL Club Collection", description: "MFL is a unique Web3 Football (Soccer) Management game & ecosystem where you\u{2019}ll be able to own and develop your football players as well as build a club from the ground up. As in real football, you\u{2019}ll be able to : Be a recruiter (Scout, find, and trade players\u{2026}), be an agent (Find the best clubs for your players, negotiate contracts with club owners\u{2026}), be a club owner (Develop your club, recruit players, compete in leagues and tournaments\u{2026}) and be a coach (Train and develop your players, play matches, and define your match tactics...). This collection allows you to collect Clubs.", externalURL: MetadataViews.ExternalURL("https://playmfl.com"), squareImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/logos/mfl_logo_black_square_small.svg"), mediaType: "image/svg+xml"), bannerImage: MetadataViews.Media(file: MetadataViews.HTTPFile(url: "https://d13e14gtps4iwl.cloudfront.net/branding/players/banner_1900_X_600.png"), mediaType: "image/png"), socials: socials)
				case Type<MetadataViews.NFTCollectionData>():
					return MetadataViews.NFTCollectionData(storagePath: MFLClub.CollectionStoragePath, publicPath: MFLClub.CollectionPublicPath, publicCollection: Type<&MFLClub.Collection>(), publicLinkedType: Type<&MFLClub.Collection>(), createEmptyCollectionFunction: fun (): @{NonFungibleToken.Collection}{ 
							return <-MFLClub.createEmptyCollection(nftType: Type<@MFLClub.Collection>())
						})
				case Type<MetadataViews.ExternalURL>():
					return MetadataViews.ExternalURL("https://playmfl.com")
				case Type<MetadataViews.Traits>():
					let traits: [MetadataViews.Trait] = []
					
					// TODO must be fixed correctly in the data rather than here.
					// foundationLicenseCity and foundationLicenseCountry should always be of type String? in the metadata
					let clubMetadata = clubData.getMetadata()
					var city: String? = nil
					var country: String? = nil
					if clubData.getStatus() == ClubStatus.NOT_FOUNDED{ 
						city = clubMetadata["foundationLicenseCity"] as! String?
						country = clubMetadata["foundationLicenseCountry"] as! String?
					} else{ 
						city = clubMetadata["foundationLicenseCity"] as! String?? ?? nil
						country = clubMetadata["foundationLicenseCountry"] as! String?? ?? nil
					}
					traits.append(MetadataViews.Trait(name: "city", value: city, displayType: "String", rarity: nil))
					traits.append(MetadataViews.Trait(name: "country", value: country, displayType: "String", rarity: nil))
					let squadsIDs = clubData.getSquadIDs()
					if squadsIDs.length > 0{ 
						let firstSquadID = squadsIDs[0]
						if let squadData = MFLClub.getSquadData(id: firstSquadID){ 
							if let globalLeagueMembership = squadData.getCompetitionsMemberships()[1]{ 
								if let globalLeagueMembershipDataOptional = globalLeagueMembership as?{ String: AnyStruct}?{ 
									if let globalLeagueMembershipData = globalLeagueMembershipDataOptional{ 
										traits.append(MetadataViews.Trait(name: "division", value: globalLeagueMembershipData["division"] as! UInt32?, displayType: "Number", rarity: nil))
									}
								}
							}
						}
					}
					return MetadataViews.Traits(traits)
				case Type<MetadataViews.Serial>():
					return MetadataViews.Serial(clubData.id)
			}
			return nil
		}
		
		// Getter for metadata
		access(contract)
		fun getMetadata():{ String: AnyStruct}{ 
			return self.metadata
		}
		
		access(all)
		fun createEmptyCollection(): @{NonFungibleToken.Collection}{ 
			return <-create Collection()
		}
	}
	
	// A collection of Club NFTs owned by an account
	access(all)
	resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.Collection, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection{ 
		
		// Dictionary of NFT conforming tokens
		access(all)
		var ownedNFTs: @{UInt64:{ NonFungibleToken.NFT}}
		
		// Removes an NFT from the collection and moves it to the caller
		access(NonFungibleToken.Withdraw)
		fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}{ 
			let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
			emit Withdraw(id: token.id, from: self.owner?.address)
			return <-token
		}
		
		// Withdraws multiple Clubs and returns them as a Collection
		access(TMP_ENTITLEMENT_OWNER)
		fun batchWithdraw(ids: [UInt64]): @{NonFungibleToken.Collection}{ 
			var batchCollection <- create Collection()
			
			// Iterate through the ids and withdraw them from the Collection
			for id in ids{ 
				batchCollection.deposit(token: <-self.withdraw(withdrawID: id))
			}
			return <-batchCollection
		}
		
		// Takes a NFT and adds it to the collections dictionary and adds the ID to the id array
		access(all)
		fun deposit(token: @{NonFungibleToken.NFT}): Void{ 
			let token <- token as! @MFLClub.NFT
			let id: UInt64 = token.id
			
			// Add the new token to the dictionary which removes the old one
			let oldToken <- self.ownedNFTs[id] <- token
			emit Deposit(id: id, to: self.owner?.address)
			destroy oldToken
		}
		
		// Returns an array of the IDs that are in the collection
		access(all)
		view fun getIDs(): [UInt64]{ 
			return self.ownedNFTs.keys
		}
		
		// Gets a reference to an NFT in the collection so that the caller can read its metadata and call its methods
		access(all)
		view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?{ 
			return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
		}
		
		access(all)
		view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}?{ 
			let nft = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)!
			let clubNFT = nft as! &MFLClub.NFT
			return clubNFT as &{ViewResolver.Resolver}
		}
		
		access(self)
		fun borrowClubRef(id: UInt64): &MFLClub.NFT?{ 
			let ref = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
			return ref as! &MFLClub.NFT?
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun foundClub(id: UInt64, name: String, description: String){ 
			let clubRef = self.borrowClubRef(id: id) ?? panic("Club not found")
			let clubData = MFLClub.getClubData(id: id) ?? panic("Club data not found")
			assert(clubData.getStatus() == ClubStatus.NOT_FOUNDED, message: "Club already founded")
			let updatedMetadata = clubData.getMetadata()
			let foundationDate = getCurrentBlock().timestamp
			let foundationLicenseSerialNumber = clubRef.getMetadata()["foundationLicenseSerialNumber"] as! UInt64?
			let foundationLicenseCity = clubRef.getMetadata()["foundationLicenseCity"] as! String?
			let foundationLicenseCountry = clubRef.getMetadata()["foundationLicenseCountry"] as! String?
			let foundationLicenseSeason = clubRef.getMetadata()["foundationLicenseSeason"] as! UInt32?
			let foundationLicenseImage = clubRef.getMetadata()["foundationLicenseImage"] as! MetadataViews.IPFSFile?
			updatedMetadata.insert(key: "name", name)
			updatedMetadata.insert(key: "description", description)
			updatedMetadata.insert(key: "foundationDate", foundationDate)
			updatedMetadata.insert(key: "foundationLicenseSerialNumber", foundationLicenseSerialNumber)
			updatedMetadata.insert(key: "foundationLicenseCity", foundationLicenseCity)
			updatedMetadata.insert(key: "foundationLicenseCountry", foundationLicenseCountry)
			updatedMetadata.insert(key: "foundationLicenseSeason", foundationLicenseSeason)
			updatedMetadata.insert(key: "foundationLicenseImage", foundationLicenseImage)
			(MFLClub.clubsDatas[id]!).setMetadata(metadata: updatedMetadata)
			(MFLClub.clubsDatas[id]!).setStatus(status: ClubStatus.PENDING_VALIDATION)
			emit ClubFounded(id: id, from: self.owner?.address, name: name, description: description, foundationDate: foundationDate, foundationLicenseSerialNumber: foundationLicenseSerialNumber, foundationLicenseCity: foundationLicenseCity, foundationLicenseCountry: foundationLicenseCountry, foundationLicenseSeason: foundationLicenseSeason)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun requestClubInfoUpdate(id: UInt64, info:{ String: String}){ 
			pre{ 
				self.getIDs().contains(id) == true:
					"Club not found"
			}
			let clubData = MFLClub.getClubData(id: id) ?? panic("Club data not found")
			assert(clubData.getStatus() == ClubStatus.FOUNDED, message: "Club not founded")
			emit ClubInfoUpdateRequested(id: id, info: info)
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
	
	// Public function that anyone can call to create a new empty collection
	access(all)
	fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection}{ 
		return <-create Collection()
	}
	
	// Get data for a specific club ID
	access(TMP_ENTITLEMENT_OWNER)
	view fun getClubData(id: UInt64): ClubData?{ 
		return self.clubsDatas[id]
	}
	
	// Get data for a specific squad ID
	access(TMP_ENTITLEMENT_OWNER)
	view fun getSquadData(id: UInt64): SquadData?{ 
		return self.squadsDatas[id]
	}
	
	// This interface allows any account that has a private capability to a ClubAdminClaim to call the methods below
	access(all)
	resource interface ClubAdminClaim{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintClub(id: UInt64, squads: @[MFLClub.Squad], nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}): @MFLClub.NFT
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubStatus(id: UInt64, status: ClubStatus)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubMetadata(id: UInt64, metadata:{ String: AnyStruct})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64])
	}
	
	access(all)
	resource ClubAdmin: ClubAdminClaim{ 
		access(all)
		let name: String
		
		init(){ 
			self.name = "ClubAdminClaim"
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintClub(id: UInt64, squads: @[Squad], nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}): @MFLClub.NFT{ 
			let club <- create MFLClub.NFT(id: id, squads: <-squads, nftMetadata: nftMetadata, metadata: metadata)
			return <-club
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubStatus(id: UInt64, status: ClubStatus){ 
			pre{ 
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setStatus(status: status)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubMetadata(id: UInt64, metadata:{ String: AnyStruct}){ 
			pre{ 
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setMetadata(metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateClubSquadsIDs(id: UInt64, squadsIDs: [UInt64]){ 
			pre{ 
				MFLClub.getClubData(id: id) != nil:
					"Club data not found"
			}
			(MFLClub.clubsDatas[id]!).setSquadsIDs(squadsIDs: squadsIDs)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createClubAdmin(): @ClubAdmin{ 
			return <-create ClubAdmin()
		}
	}
	
	// This interface allows any account that has a private capability to a SquadAdminClaim to call the methods below
	access(all)
	resource interface SquadAdminClaim{ 
		access(all)
		let name: String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSquad(id: UInt64, clubID: UInt64, type: String, nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}, competitionsMemberships:{ UInt64: AnyStruct}): @MFLClub.Squad
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSquadMetadata(id: UInt64, metadata:{ String: AnyStruct})
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct)
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSquadCompetitionMembership(id: UInt64, competitionID: UInt64)
	}
	
	access(all)
	resource SquadAdmin: SquadAdminClaim{ 
		access(all)
		let name: String
		
		init(){ 
			self.name = "SquadAdminClaim"
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun mintSquad(id: UInt64, clubID: UInt64, type: String, nftMetadata:{ String: AnyStruct}, metadata:{ String: AnyStruct}, competitionsMemberships:{ UInt64: AnyStruct}): @Squad{ 
			let squad <- create Squad(id: id, clubID: clubID, type: type, nftMetadata: nftMetadata, metadata: metadata, competitionsMemberships: competitionsMemberships)
			return <-squad
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSquadMetadata(id: UInt64, metadata:{ String: AnyStruct}){ 
			pre{ 
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).setMetadata(metadata: metadata)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct){ 
			pre{ 
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).addCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionMembershipData)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun updateSquadCompetitionMembership(id: UInt64, competitionID: UInt64, competitionMembershipData: AnyStruct){ 
			pre{ 
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).updateCompetitionMembership(competitionID: competitionID, competitionMembershipData: competitionMembershipData)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSquadCompetitionMembership(id: UInt64, competitionID: UInt64){ 
			pre{ 
				MFLClub.getSquadData(id: id) != nil:
					"Squad data not found"
			}
			(MFLClub.squadsDatas[id]!).removeCompetitionMembership(competitionID: competitionID)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createSquadAdmin(): @SquadAdmin{ 
			return <-create SquadAdmin()
		}
	}
	
	init(){ 
		// Set our named paths
		self.CollectionStoragePath = /storage/MFLClubCollection
		self.CollectionPrivatePath = /private/MFLClubCollection
		self.CollectionPublicPath = /public/MFLClubCollection
		self.ClubAdminStoragePath = /storage/MFLClubAdmin
		self.SquadAdminStoragePath = /storage/MFLSquadAdmin
		
		// Put a new Collection in storage
		self.account.storage.save<@Collection>(<-create Collection(), to: self.CollectionStoragePath)
		// Create a public capability for the Collection
		var capability_1 = self.account.capabilities.storage.issue<&MFLClub.Collection>(self.CollectionStoragePath)
		self.account.capabilities.publish(capability_1, at: self.CollectionPublicPath)
		
		// Create a ClubAdmin resource and save it to storage
		self.account.storage.save(<-create ClubAdmin(), to: self.ClubAdminStoragePath)
		// Create SquadAdmin resource and save it to storage
		self.account.storage.save(<-create SquadAdmin(), to: self.SquadAdminStoragePath)
		
		// Initialize contract fields
		self.totalSupply = 0
		self.squadsTotalSupply = 0
		self.clubsDatas ={} 
		self.squadsDatas ={} 
		emit ContractInitialized()
	}
}
