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

	import KissoNFT from "./KissoNFT.cdc"

import AdminToken from "./AdminToken.cdc"

import Clock from "./Clock.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract DAO{ 
	access(all)
	var totalProposals: UInt64
	
	access(all)
	event ContractInitialized()
	
	access(all)
	event ProposalOpened(id: UInt64)
	
	access(all)
	event ProposalClosed(id: UInt64)
	
	access(all)
	event ProposalCancelled(id: UInt64)
	
	access(all)
	event VotesCast(voter: Address, proposalID: UInt64, choice: UInt64)
	
	// key for the proposal dictionaries represents the index of total proposals
	access(account)
	let proposals:{ UInt64: Proposal}
	
	access(account)
	var openProposalIDs: [UInt64]
	
	access(account)
	var closedProposalIDs: [UInt64]
	
	access(account)
	var cancelledProposalIDs: [UInt64]
	
	access(account)
	let ineligible:{ Address: UFix64}
	
	access(all)
	enum Status: UInt8{ 
		access(all)
		case open // icludes a proposal before voting has started
		
		
		access(all)
		case closed
		
		access(all)
		case cancelled
	}
	
	access(all)
	struct Choice{ 
		access(all)
		let title: String
		
		access(all)
		let description: String // assumed this text is unsafe, client consumers should sanitize before display
		
		
		access(all)
		var votesCount: UInt64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun incrementVotesCount(numVotes: UInt64){ 
			self.votesCount = self.votesCount + numVotes
		}
		
		init(title: String, description: String){ 
			self.title = title
			self.description = description
			self.votesCount = 0
		}
	}
	
	access(all)
	struct Vote{ 
		access(all)
		let weight: UInt64
		
		access(all)
		let choice: UInt64
		
		init(weight: UInt64, choice: UInt64){ 
			self.weight = weight
			self.choice = choice
		}
	}
	
	access(all)
	struct Votes{ 
		access(all)
		let votes:{ UInt64: Vote} // key is the uuid of a voting NFT
		
		
		access(TMP_ENTITLEMENT_OWNER)
		fun castVote(nftUUID: UInt64, weight: UInt64, choice: UInt64){ 
			pre{ 
				self.votes[nftUUID] == nil:
					"that NFT has already been used to vote in this proposal"
			}
			self.votes.insert(key: nftUUID, Vote(weight: weight, choice: choice))
		}
		
		init(){ 
			self.votes ={} 
		}
	}
	
	access(all)
	struct Proposal{ 
		access(all)
		let creator: Address
		
		access(all)
		let title: String
		
		access(all)
		let description: String
		
		access(all)
		let choices:{ UInt64: Choice} // key resresents the id of the choice
		
		
		access(all)
		let start: UFix64
		
		access(all)
		let end: UFix64
		
		access(all)
		var status: Status
		
		access(all)
		let voters:{ Address: Votes}
		
		access(all)
		let opened: UFix64
		
		access(all)
		var closed: UFix64?
		
		access(all)
		var cancelled: UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addVoter(address: Address){ 
			self.voters.insert(key: address, Votes())
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setClosed(){ 
			self.closed = Clock.getTime()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setCancelled(){ 
			self.cancelled = Clock.getTime()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markClosedStatus(){ 
			self.status = Status(rawValue: 1)!
			self.closed = Clock.getTime()
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun markCancelledStatus(){ 
			self.status = Status(rawValue: 2)!
			self.cancelled = Clock.getTime()
		}
		
		init(
			creator: Address,
			title: String,
			description: String,
			choices:{ 
				UInt64: Choice
			},
			start: UFix64,
			end: UFix64
		){ 
			self.creator = creator
			self.title = title
			self.description = description
			self.choices = choices
			self.start = start
			self.end = end
			self.status = Status(rawValue: 0)!
			self.voters ={} 
			self.opened = Clock.getTime()
			self.closed = nil
			self.cancelled = nil
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createProposal(
		nftRef: &KissoNFT.NFT,
		nftCollectionRef: &KissoNFT.Collection,
		title: String,
		description: String,
		choices:{ 
			UInt64: Choice
		},
		start: UFix64,
		end: UFix64
	){ 
		pre{ 
			(nftRef.owner!).address == (nftCollectionRef.owner!).address:
				"nft owner must be the same as the nft collection owner"
			start >= Clock.getTime():
				"Start time cannot be in the past"
			end >= Clock.getTime():
				"End time cannot be in the past"
			end > start:
				"End time must be later than the start time"
			DAO.ineligible[(nftRef.owner!).address] == nil:
				"Address is not eligible for creating a proposal"
		}
		let collectionOwnerAddress = (nftCollectionRef.owner!).address
		DAO.proposals.insert(
			key: DAO.totalProposals,
			Proposal(
				creator: collectionOwnerAddress,
				title: title,
				description: description,
				choices: choices,
				start: start,
				end: end
			)
		)
		DAO.openProposalIDs.append(DAO.totalProposals)
		emit ProposalOpened(id: DAO.totalProposals)
		DAO.totalProposals = DAO.totalProposals + UInt64(1)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun castVote(proposalID: UInt64, nftCollectionRef: &KissoNFT.Collection, choice: UInt64){ 
		pre{ 
			DAO.proposals[proposalID] != nil:
				"That proposal with that ID doesn't exist"
			(DAO.proposals[proposalID]!).start < Clock.getTime():
				"The proposal voting period has not started."
			(DAO.proposals[proposalID]!).end > Clock.getTime():
				"The proposal voting period has ended."
		}
		let collectionOwnerAddress = (nftCollectionRef.owner!).address
		
		// add the voter to this proposal if they don't exist already
		if (DAO.proposals[proposalID]!).voters[collectionOwnerAddress] == nil{ 
			(DAO.proposals[proposalID]!).addVoter(address: collectionOwnerAddress)
		}
		let collectionOwnerVotingWeights:{ UInt64: UInt64} = nftCollectionRef.getVotingWeights()
		for uuidKey in collectionOwnerVotingWeights.keys{ 
			let uuidVotingWeight: UInt64 = collectionOwnerVotingWeights[uuidKey]!
			((			  // cast vote
			  DAO.proposals[proposalID]!).voters[collectionOwnerAddress]!).castVote(nftUUID: uuidKey, weight: uuidVotingWeight, choice: choice)
			((			  
			  // increment the choices count for the proposal
			  DAO.proposals[proposalID]!).choices[choice]!).incrementVotesCount(numVotes: uuidVotingWeight)
		}
		emit VotesCast(voter: collectionOwnerAddress, proposalID: proposalID, choice: choice)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getOpenProposalIDs(): [UInt64]{ 
		return DAO.openProposalIDs
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getClosedProposalIDs(): [UInt64]{ 
		return DAO.closedProposalIDs
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getCancelledProposalIDs(): [UInt64]{ 
		return DAO.cancelledProposalIDs
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun getProposal(proposalID: UInt64): Proposal?{ 
		pre{ 
			DAO.proposals[proposalID] != nil:
				"Proposal with that ID cannot be found"
		}
		return DAO.proposals[proposalID]
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun cancelOpenProposal(proposalID: UInt64, ref: &AdminToken.Token?){ 
		pre{ 
			DAO.proposals[proposalID] != nil:
				"Proposal with that ID cannot be found"
		}
		AdminToken.checkAuthorizedAdmin(ref)
		( // check for authorized admin		 
		 DAO.proposals[proposalID]!).markCancelledStatus()
		let proposalIndex = DAO.openProposalIDs.firstIndex(of: proposalID)!
		let removedProposalID = DAO.openProposalIDs.remove(at: proposalIndex)
		DAO.cancelledProposalIDs.append(removedProposalID)
		emit ProposalCancelled(id: removedProposalID)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun closeOpenProposal(proposalID: UInt64){ 
		pre{ 
			DAO.proposals[proposalID] != nil:
				"Proposal with that ID cannot be found"
			(DAO.proposals[proposalID]!).end <= Clock.getTime():
				"The proposal open period has not yet ended."
		}
		(DAO.proposals[proposalID]!).markClosedStatus()
		let proposalIndex = DAO.openProposalIDs.firstIndex(of: proposalID)!
		let removedProposalID = DAO.openProposalIDs.remove(at: proposalIndex)
		DAO.closedProposalIDs.append(removedProposalID)
		emit ProposalClosed(id: removedProposalID)
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun addIneligibleAddress(address: Address, ref: &AdminToken.Token?){ 
		pre{ 
			DAO.ineligible[address] == nil:
				"Address is already ineligible"
		}
		AdminToken.checkAuthorizedAdmin(ref) // check for authorized admin
		
		DAO.ineligible.insert(key: address, Clock.getTime())
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun removeIneligibleAddress(address: Address, ref: &AdminToken.Token?){ 
		pre{ 
			DAO.ineligible[address] != nil:
				"Cannot find address in ineligible dictionary"
		}
		AdminToken.checkAuthorizedAdmin(ref) // check for authorized admin
		
		DAO.ineligible.remove(key: address)
	}
	
	init(){ 
		self.totalProposals = 0
		self.proposals ={} 
		self.openProposalIDs = []
		self.closedProposalIDs = []
		self.cancelledProposalIDs = []
		self.ineligible ={} 
		emit ContractInitialized()
	}
}
