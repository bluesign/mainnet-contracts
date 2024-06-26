import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

access(all) contract Swap {

    /// ProposalCreated
    /// Event to notify when a user has created a swap proposal
    access(all) event ProposalCreated(proposal: ReadableSwapProposal)

    /// ProposalExecuted
    /// Event to notify when a user has executed a previously created swap proposal
    access(all) event ProposalExecuted(proposal: ReadableSwapProposal)

    /// ProposalDeleted
    /// Event to notify when a user has deleted a previously created swap proposal
    access(all) event ProposalDeleted(proposal: ReadableSwapProposal)

    /// AllowSwapProposalCreation
    /// Toggle to control creation of new swap proposals
    access(all) var AllowSwapProposalCreation: Bool

    /// SwapCollectionStoragePath
    /// Storage directory used to store the SwapCollection object
    access(all) let SwapCollectionStoragePath: StoragePath

    /// SwapCollectionPrivatePath
    /// Private directory used to expose the SwapCollectionManager capability
    access(all) let SwapCollectionPrivatePath: PrivatePath

    /// SwapCollectionPublicPath
    /// Public directory used to store the SwapCollectionPublic capability
    access(all) let SwapCollectionPublicPath: PublicPath

    /// SwapAdminStoragePath
    /// Storage directory used to store SwapAdmin object
    access(all) let SwapAdminStoragePath: StoragePath

    /// SwapAdminPrivatePath
    /// Storage directory used to store SwapAdmin capability
    access(all) let SwapAdminPrivatePath: PrivatePath

    /// SwapFees
    /// Array of all fees currently applied to swap proposals
    access(all) let SwapFees: [Fee]

    /// SwapProposalMinExpirationMinutes
    /// Minimum number of minutes that a swap proposal can be set to expire in
    access(all) var SwapProposalMinExpirationMinutes: UFix64

    /// SwapProposalMaxExpirationMinutes
    /// Maximum number of minutes that a swap proposal can be set to expire in
    access(all) var SwapProposalMaxExpirationMinutes: UFix64

    /// SwapProposalDefaultExpirationMinutes
    /// Default nubmer of minutes for swap proposal exiration
    access(all) var SwapProposalDefaultExpirationMinutes: UFix64

    /// Readable
    /// An interface for publicly readable structs.
    access(all) struct interface Readable {
        access(all) view fun getReadable(): {String: AnyStruct}
    }

    /// ProposedTradeAsset
    /// An NFT asset proposed as part of a swap.
    access(all) struct ProposedTradeAsset: Readable {
        access(all) let nftID: UInt64
        access(all) let type: Type
        access(all) let collectionData: MetadataViews.NFTCollectionData

        access(all) view fun getReadable(): {String: String} {
            return {
                "nftID": self.nftID.toString(),
                "type": self.type.identifier
            }
        }

        init(
            nftID: UInt64,
            type: String,
            collectionData: MetadataViews.NFTCollectionData
        ) {

            let inputType = CompositeType(type) ?? panic("unable to cast type; must be a valid NFT type reference")

            self.nftID = nftID
            self.type = inputType
            self.collectionData = collectionData
        }
    }

    /// Fee
    /// This struct represents a fee to be paid upon execution of the swap proposal.
    /// The feeGroup indicates the set of payment methods to which this fee belongs. For each feeGroup, the user is only
    /// required to provide one matching feeProvider in the UserCapabilities objects. This allows for a single fee to be
    /// payable in multiple currencies.
    access(all) struct Fee: Readable {
        access(all) let receiver: Capability<&AnyResource{FungibleToken.Receiver}>
        access(all) let amount: UFix64
        access(all) let feeGroup: UInt8
        access(all) let tokenType: Type

        init(
            receiver: Capability<&AnyResource{FungibleToken.Receiver}>,
            amount: UFix64,
            feeGroup: UInt8
        ) {

            assert(receiver.check(), message: "invalid fee receiver")
            let tokenType = receiver.borrow()!.getType()
            assert(amount > 0.0, message: "fee amount must be greater than zero")

            self.receiver = receiver
            self.amount = amount
            self.feeGroup = feeGroup
            self.tokenType = tokenType
        }

        access(all) view fun getReadable(): {String: String} {
            return {
                "receiverAddress": self.receiver.address.toString(),
                "amount": self.amount.toString(),
                "feeGroup": self.feeGroup.toString(),
                "tokenType": self.tokenType.identifier
            }
        }
    }

    /// UserOffer
    /// This struct represents one user's half of a swap, detailing their address and proposed assets as well as any
    /// metadata that might be required (currently not used)
    access(all) struct UserOffer: Readable {
        access(all) let userAddress: Address
        access(all) let proposedNfts: [ProposedTradeAsset]
        access(all) let metadata: {String: String}?

        access(all) view fun getReadable(): {String: [{String: String}]} {

            let readableOffer: {String: [{String: String}]} = {}
            let readableProposedNfts: [{String: String}] = []
            for proposedNft in self.proposedNfts {
                readableProposedNfts.append(proposedNft.getReadable())
            }
            readableOffer.insert(key: "proposedNfts", readableProposedNfts)

            if (self.metadata != nil && self.metadata!.keys!.length! > 0) {
                readableOffer.insert(key: "metadata", [self.metadata!])
            }

            return readableOffer
        }

        init(
            userAddress: Address,
            proposedNfts: [ProposedTradeAsset],
            metadata: {String: String}?
        ) {
            self.userAddress = userAddress
            self.proposedNfts = proposedNfts
            self.metadata = metadata
        }
    }

    /// UserCapabilities
    /// This struct contains the providers needed to send the user's offered tokens and any required fees, as well as the
    /// receivers needed to accept the trading partner's tokens and any extra capabilities that might be required.
    /// For capability dictionaries, each token's type identifier is used as the key for each entry in each dict.
    access(all) struct UserCapabilities {
        access(contract) let collectionReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>}
        access(contract) let collectionProviderCapabilities: {String: Capability<&{NonFungibleToken.Provider}>}
        access(contract) let feeProviderCapabilities: {String: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>}?
        access(contract) let extraCapabilities: {String: Capability}?

        init(
            collectionReceiverCapabilities: {String: Capability<&{NonFungibleToken.Receiver}>},
            collectionProviderCapabilities: {String: Capability<&{NonFungibleToken.Provider}>},
            feeProviderCapabilities: {String: Capability<&{FungibleToken.Provider, FungibleToken.Balance}>}?,
            extraCapabilities: {String: Capability}?
        ) {
            self.collectionReceiverCapabilities = collectionReceiverCapabilities
            self.collectionProviderCapabilities = collectionProviderCapabilities
            self.feeProviderCapabilities = feeProviderCapabilities
            self.extraCapabilities = extraCapabilities
        }
    }

    /// ReadableSwapProposal
    /// Struct for return type to SwapProposal.getReadable()
    access(all) struct ReadableSwapProposal {
        access(all) let id: String
        access(all) let fees: [{String: String}]
        access(all) let minutesRemainingBeforeExpiration: String
        access(all) let leftUserAddress: String
        access(all) let leftUserOffer: {String: [{String: String}]}
        access(all) let rightUserAddress: String
        access(all) let rightUserOffer: {String: [{String: String}]}
        access(all) let metadata: {String: String}?

        init(
            id: String,
            fees: [Fee],
            expirationEpochMilliseconds: UFix64,
            leftUserOffer: UserOffer,
            rightUserOffer: UserOffer,
            metadata: {String: String}?
        ) {

            let readableFees: [{String: String}] = []
            for fee in fees {
                readableFees.append(fee.getReadable())
            }

            let currentTimestamp: UFix64 = getCurrentBlock().timestamp
            var minutesRemaining: UFix64 = 0.0
            if (expirationEpochMilliseconds > currentTimestamp) {
                minutesRemaining = (expirationEpochMilliseconds - currentTimestamp) / 60000.0
            }

            self.id = id
            self.fees = readableFees
            self.minutesRemainingBeforeExpiration = minutesRemaining.toString()
            self.leftUserAddress = leftUserOffer.userAddress.toString()
            self.leftUserOffer = leftUserOffer.getReadable()
            self.rightUserAddress = rightUserOffer.userAddress.toString()
            self.rightUserOffer = rightUserOffer.getReadable()
            self.metadata = metadata
        }
    }

    /// SwapProposal
    /// Struct to represent a proposed swap, which is stored in a user's SwapCollection until executed by the right user
    access(all) struct SwapProposal {

        // Semi-unique identifier (unique within the left user's account) to identify swap proposals
        access(all) let id: String

        // Array of all fees to be paid out on execution of swap proposal (can be empty array in case of zero fees)
        access(all) let fees: [Fee]

        // When this swap proposal should no longer be eligible to be accepted (in epoch milliseconds)
        access(all) let expirationEpochMilliseconds: UFix64

        // The offer of the initializing user
        access(all) let leftUserOffer: UserOffer

        // The offer of the secondary proposer
        access(all) let rightUserOffer: UserOffer

        // The trading capabilities of the initializing user
        access(self) let leftUserCapabilities: UserCapabilities

        // A dictionary of metadata
        // Currently used for "sourceId"
        access(self) let metadata: {String: String}?

        init(
            id: String,
            leftUserOffer: UserOffer,
            rightUserOffer: UserOffer,
            leftUserCapabilities: UserCapabilities,
            expirationOffsetMinutes: UFix64,
            metadata: {String: String}?
        ) {

            assert(expirationOffsetMinutes >= Swap.SwapProposalMinExpirationMinutes,
                message: "expirationOffsetMinutes must be greater than or equal to Swap.SwapProposalMinExpirationMinutes")
            assert(expirationOffsetMinutes <= Swap.SwapProposalMaxExpirationMinutes,
                message: "expirationOffsetMinutes must be less than or equal to Swap.SwapProposalMaxExpirationMinutes")
            assert(Swap.AllowSwapProposalCreation, message: "swap proposal creation is paused")

            // convert offset minutes to epoch milliseconds
            let expirationEpochMilliseconds = getCurrentBlock().timestamp + (expirationOffsetMinutes * 1000.0 * 60.0)

            // verify that the left user owns their proposed assets has supplied proper capabilities
            Swap.verifyUserOffer(
                userOffer: leftUserOffer,
                userCapabilities: leftUserCapabilities,
                partnerOffer: rightUserOffer,
                fees: Swap.SwapFees
            )

            self.id = id
            self.fees = Swap.SwapFees
            self.leftUserOffer = leftUserOffer
            self.rightUserOffer = rightUserOffer
            self.leftUserCapabilities = leftUserCapabilities
            self.expirationEpochMilliseconds = expirationEpochMilliseconds
            self.metadata = metadata

            emit ProposalCreated(proposal: self.getReadableSwapProposal())
        }

        // Get a human-readable version of the swap proposal data
        access(contract) view fun getReadableSwapProposal(): ReadableSwapProposal {
            return ReadableSwapProposal(
                id: self.id,
                fees: self.fees,
                expirationEpochMilliseconds: self.expirationEpochMilliseconds,
                leftUserOffer: self.leftUserOffer,
                rightUserOffer: self.rightUserOffer,
                metadata: self.metadata
            )
        }

        // Function to execute the proposed swap
        access(contract) fun execute(rightUserCapabilities: UserCapabilities) {

            assert(getCurrentBlock().timestamp <= self.expirationEpochMilliseconds, message: "swap proposal is expired")

            // verify capabilities and ownership of tokens for both users
            Swap.verifyUserOffer(
                userOffer: self.leftUserOffer,
                userCapabilities: self.leftUserCapabilities,
                partnerOffer: self.rightUserOffer,
                fees: self.fees
            )
            Swap.verifyUserOffer(
                userOffer: self.rightUserOffer,
                userCapabilities: rightUserCapabilities,
                partnerOffer: self.leftUserOffer,
                fees: self.fees
            )

            // execute both sides of the offer
            Swap.executeUserOffer(
                userOffer: self.leftUserOffer,
                userCapabilities: self.leftUserCapabilities,
                partnerCapabilities: rightUserCapabilities,
                fees: self.fees
            )
            Swap.executeUserOffer(
                userOffer: self.rightUserOffer,
                userCapabilities: rightUserCapabilities,
                partnerCapabilities: self.leftUserCapabilities,
                fees: self.fees
            )

            emit ProposalExecuted(proposal: self.getReadableSwapProposal())
        }
    }

    /// SwapCollectionManager
    /// This interface allows private linking of management methods for the SwapCollection owner
    access(all) resource interface SwapCollectionManager {
        access(all) fun createProposal(
            leftUserOffer: UserOffer,
            rightUserOffer: UserOffer,
            leftUserCapabilities: UserCapabilities,
            expirationOffsetMinutes: UFix64?,
            metadata: {String: String}?
        ): String
        access(all) view fun getAllProposals(): {String: ReadableSwapProposal}
        access(all) fun deleteProposal(id: String)
    }

    /// SwapCollectionPublic
    /// This interface allows public linking of the get and execute methods for trading partners
    access(all) resource interface SwapCollectionPublic {
        access(all) view fun getProposal(id: String): ReadableSwapProposal
        access(all) view fun getUserOffer(proposalId: String, leftOrRight: String): UserOffer
        access(all) fun executeProposal(id: String, rightUserCapabilities: UserCapabilities)
    }

    access(all) resource SwapCollection: SwapCollectionManager, SwapCollectionPublic {

        // Dict to store by swap id all trade offers created by the end user
        access(self) let swapProposals: {String: SwapProposal}

        // Function to create and store a swap proposal
        access(all) fun createProposal(
            leftUserOffer: UserOffer,
            rightUserOffer: UserOffer,
            leftUserCapabilities: UserCapabilities,
            expirationOffsetMinutes: UFix64?,
            metadata: {String: String}?
        ): String {

            // generate semi-random number for the SwapProposal id
            var semiRandomId: String = unsafeRandom().toString()
            while (self.swapProposals[semiRandomId] != nil) {
                semiRandomId = unsafeRandom().toString()
            }

            // create swap proposal and add to swapProposals
            let newSwapProposal = SwapProposal(
                id: semiRandomId,
                leftUserOffer: leftUserOffer,
                rightUserOffer: rightUserOffer,
                leftUserCapabilities: leftUserCapabilities,
                expirationOffsetMinutes: expirationOffsetMinutes ?? Swap.SwapProposalDefaultExpirationMinutes,
                metadata: metadata
            )
            self.swapProposals.insert(key: semiRandomId, newSwapProposal)

            return semiRandomId
        }

        // Function to get a readable version of a single swap proposal
        access(all) view fun getProposal(id: String): ReadableSwapProposal {

            let noSwapProposalMessage: String = "found no swap proposal with id "
            let swapProposal: SwapProposal = self.swapProposals[id] ?? panic(noSwapProposalMessage.concat(id))

            return swapProposal.getReadableSwapProposal()
        }

        // Function to get a readable version of all swap proposals
        access(all) view fun getAllProposals(): {String: ReadableSwapProposal} {

            let proposalReadErrorMessage: String = "unable to get readable swap proposal for id "
            let readableSwapProposals: {String: ReadableSwapProposal} = {}

            for swapProposalId in self.swapProposals.keys {
                let swapProposal = self.swapProposals[swapProposalId] ?? panic(proposalReadErrorMessage.concat(swapProposalId))
                readableSwapProposals.insert(key: swapProposalId, swapProposal!.getReadableSwapProposal())
            }

            return readableSwapProposals
        }

        // Function to provide the specified user offer details
        access(all) view fun getUserOffer(proposalId: String, leftOrRight: String): UserOffer {

            let noSwapProposalMessage: String = "found no swap proposal with id "
            let swapProposal: SwapProposal = self.swapProposals[proposalId] ?? panic(noSwapProposalMessage.concat(proposalId))

            var userOffer: UserOffer? = nil

            switch leftOrRight.toLower() {
                case "left":
                    userOffer = swapProposal.leftUserOffer
                case "right":
                    userOffer = swapProposal.rightUserOffer
                default:
                    panic("argument leftOrRight must be either 'left' or 'right'")
            }

            return userOffer!
        }

        // Function to delete a swap proposal
        access(all) fun deleteProposal(id: String) {

            let noSwapProposalMessage: String = "found no swap proposal with id "
            let swapProposal: SwapProposal = self.swapProposals[id] ?? panic(noSwapProposalMessage.concat(id))
            let readableSwapProposal: ReadableSwapProposal = swapProposal.getReadableSwapProposal()

            self.swapProposals.remove(key: id)
            emit ProposalDeleted(proposal: readableSwapProposal)
        }

        // Function to execute a previously created swap proposal
        access(all) fun executeProposal(id: String, rightUserCapabilities: UserCapabilities) {

            let noSwapProposalMessage: String = "found no swap proposal with id "
            let swapProposal: SwapProposal = self.swapProposals[id] ?? panic(noSwapProposalMessage.concat(id))

            swapProposal.execute(rightUserCapabilities: rightUserCapabilities)
            self.deleteProposal(id: id)
        }

        init() {
            self.swapProposals = {}
        }
    }

    /// SwapProposalManager
    /// This interface allows private linking of swap proposal management functionality
    access(all) resource interface SwapProposalManager {
        access(account) fun stopProposalCreation()
        access(account) fun startProposalCreation()
        access(account) fun updateMinExpiration(_ exp: UFix64)
        access(all) fun updateMaxExpiration(_ exp: UFix64)
        access(account) fun updateDefaultExpiration(_ exp: UFix64)
    }

    access(all) resource interface SwapFeeManager {
        access(account) fun addFee(fee: Fee)
        access(account) fun removeFeeGroup(feeGroup: UInt8)
    }

    /// SwapAdmin
    /// This object provides admin controls for swap proposals
    access(all) resource SwapAdmin: SwapProposalManager, SwapFeeManager {

        // Pause all new swap proposal creation (for maintenance)
        access(account) fun stopProposalCreation() {
            Swap.AllowSwapProposalCreation = false
        }

        // Resume new swap proposal creation
        access(account) fun startProposalCreation() {
            Swap.AllowSwapProposalCreation = true
        }

        access(account) fun updateMinExpiration(_ exp: UFix64) {
            Swap.SwapProposalMinExpirationMinutes = exp
        }

        access(all) fun updateMaxExpiration(_ exp: UFix64) {
            Swap.SwapProposalMaxExpirationMinutes = exp
        }

        access(account) fun updateDefaultExpiration(_ exp: UFix64) {
            Swap.SwapProposalDefaultExpirationMinutes = exp
        }

        access(account) fun addFee(fee: Fee) {
            Swap.SwapFees.append(fee)
        }

        access(account) fun removeFeeGroup(feeGroup: UInt8) {
            for index, fee in Swap.SwapFees {
                if (fee.feeGroup == feeGroup) {
                    Swap.SwapFees.remove(at: index)
                }
            }
        }
    }

    access(all) view fun getFees(): [Fee] {
        return Swap.SwapFees
    }

    /// createEmptySwapCollection
    /// This function allows user to create a swap collection resource for future swap proposal creation.
    access(all) fun createEmptySwapCollection(): @SwapCollection {
        return <-create SwapCollection()
    }

    /// verifyUserOffer
    /// This function verifies that all assets in user offer are owned by the user.
    /// If userCapabilities is provided, the function checks that the provider capabilities are valid and that the
    /// address of each capability matches the address of the userOffer.
    /// If partnerOffer is provided in addition to userCapabilities, the function checks that the receiver
    /// capabilities are valid and that one exists for each of the collections in the partnerOffer.
    access(contract) fun verifyUserOffer(
        userOffer: UserOffer,
        userCapabilities: UserCapabilities?,
        partnerOffer: UserOffer?,
        fees: [Fee]
    ) {

        let capabilityNilMessage: String = "capability not found for "
        let addressMismatchMessage: String = "capability address does not match userOffer address for "
        let capabilityCheckMessage: String = "capability is invalid for "

        let userPublicAccount: PublicAccount = getAccount(userOffer.userAddress)

        for proposedNft in userOffer.proposedNfts {

            // attempt to load CollectionPublic capability and verify ownership
            let publicCapability = userPublicAccount.getCapability<&AnyResource{NonFungibleToken.CollectionPublic}>(proposedNft.collectionData.publicPath)

            let collectionPublicRef = publicCapability.borrow()
                ?? panic("could not borrow collectionPublic for ".concat(proposedNft.type.identifier))

            let ownedNftIds: [UInt64] = collectionPublicRef.getIDs()
            assert(ownedNftIds.contains(proposedNft.nftID),
                message: "could not verify ownership for ".concat(proposedNft.type.identifier))

            let nftRef = collectionPublicRef.borrowNFT(id: proposedNft.nftID)
            assert(nftRef.getType() == proposedNft.type,
                message: "proposedNft.type and stored asset type do not match for ".concat(proposedNft.type.identifier))

            if (userCapabilities != nil) {

                // check NFT provider capabilities
                let providerCapability = userCapabilities!.collectionProviderCapabilities[proposedNft.type.identifier]
                assert(providerCapability != nil, message: capabilityNilMessage.concat(proposedNft.type.identifier))
                assert(providerCapability!.address == userOffer.userAddress, message: addressMismatchMessage.concat(proposedNft.type.identifier))
                assert(providerCapability!.check(), message: capabilityCheckMessage.concat(proposedNft.type.identifier))
            }
        }

        if (userCapabilities != nil && partnerOffer != nil) {

            for partnerProposedNft in partnerOffer!.proposedNfts {

                // check NFT receiver capabilities
                let receiverCapability = userCapabilities!.collectionReceiverCapabilities[partnerProposedNft.type.identifier]
                assert(receiverCapability != nil, message: capabilityNilMessage.concat(partnerProposedNft.type.identifier))
                assert(receiverCapability!.address == userOffer.userAddress, message: addressMismatchMessage.concat(partnerProposedNft.type.identifier))
                assert(receiverCapability!.check(), message: capabilityCheckMessage.concat(partnerProposedNft.type.identifier))
            }
        }

        // check fee provider and receiver capabilities
        if (fees.length > 0 && userCapabilities != nil) {

            assert(userCapabilities!.feeProviderCapabilities != nil && userCapabilities!.feeProviderCapabilities!.keys.length > 0,
                message: "feeProviderCapabilities dictionary cannot be empty if fees are required")

            let feeTotals: {String: UFix64} = {}
            let feeGroupPaymentMap: {UInt8: Bool} = {}

            for fee in fees {

                if (feeGroupPaymentMap[fee.feeGroup] != true) {
                    feeGroupPaymentMap.insert(key: fee.feeGroup, false)

                    // check whether capability was provided for this fee
                    let feeProviderCapability = userCapabilities!.feeProviderCapabilities![fee.tokenType.identifier]
                    if (feeProviderCapability != nil && feeProviderCapability!.check()) {

                        let feeProviderRef: &AnyResource{FungibleToken.Provider, FungibleToken.Balance}? = feeProviderCapability!.borrow()
                        let feeReceiverRef = fee.receiver.borrow()
                            ?? panic("could not borrow feeReceiverRef for ".concat(fee.tokenType.identifier))

                        // if this is a payment option for the feeGroup, check balance, otherwise continue
                        if (feeProviderRef != nil && feeProviderRef!.getType() == feeReceiverRef.getType()) {

                            // tally running fee totals
                            let previousFeeTotal = feeTotals[fee.tokenType.identifier] ?? 0.0
                            let newFeeTotal = previousFeeTotal + fee.amount

                            // ensure that user has enough available balance of token for fee
                            if (feeProviderRef!.balance >= newFeeTotal) {

                                // update feeTotals and mark feeGroup as payable
                                feeTotals.insert(key: fee.tokenType.identifier, newFeeTotal)
                                feeGroupPaymentMap.insert(key: fee.feeGroup, true)
                            }
                        }
                    }
                }
            }

            // check that all feeGroups have been marked as payable
            feeGroupPaymentMap.forEachKey(fun (key: UInt8): Bool {
                if (feeGroupPaymentMap[key] != true) {
                    panic("no valid payment method provided for feeGroup ".concat(key.toString()))
                }
                return true
            })
        }
    }

    /// executeUserOffer
    /// This function verifies for each token in the user offer that both users have the required capabilites for the
    /// trade and that the token type matches that of the offer, and then it moves the token to the receiving collection.
    access(contract) fun executeUserOffer(
        userOffer: UserOffer,
        userCapabilities: UserCapabilities,
        partnerCapabilities: UserCapabilities,
        fees: [Fee]
    ) {

        let typeMismatchMessage: String = "token type mismatch for "
        let receiverRefMessage: String = "could not borrow receiver reference for "
        let providerRefMessage: String = "could not borrow provider reference for "

        let feeGroupPaymentMap: {UInt8: Bool} = {}

        for fee in fees {

            if (feeGroupPaymentMap[fee.feeGroup] != true) {
                feeGroupPaymentMap.insert(key: fee.feeGroup, false)

                // check whether capability was provided for this fee
                let feeProviderCapability = userCapabilities.feeProviderCapabilities![fee.tokenType.identifier]
                if (feeProviderCapability != nil && feeProviderCapability!.check()) {

                    // get fee provider and receiver
                    let feeProviderRef = feeProviderCapability!.borrow()
                    let feeReceiverRef = fee.receiver.borrow()
                        ?? panic(receiverRefMessage.concat(fee.tokenType.identifier))

                    if (feeProviderRef != nil && feeReceiverRef.getType() == feeProviderRef!.getType()) {

                        // verify token type and tranfer fee
                        let feePayment <- feeProviderRef!.withdraw(amount: fee.amount)
                        assert(feePayment.isInstance(fee.tokenType), message: typeMismatchMessage.concat(fee.tokenType.identifier))
                        feeReceiverRef.deposit(from: <-feePayment)
                        feeGroupPaymentMap.insert(key: fee.feeGroup, true)
                    }
                }
            }
        }

        // check that all feeGroups have been marked as paid
        feeGroupPaymentMap.forEachKey(fun (key: UInt8): Bool {
            if (feeGroupPaymentMap[key] != true) {
                panic("no valid payment provided for feeGroup ".concat(key.toString()))
            }
            return true
        })

        for proposedNft in userOffer.proposedNfts {

            // get receiver and provider
            let receiverReference = partnerCapabilities.collectionReceiverCapabilities[proposedNft.type.identifier]!.borrow()
                ?? panic(receiverRefMessage.concat(proposedNft.type.identifier))
            let providerReference = userCapabilities.collectionProviderCapabilities[proposedNft.type.identifier]!.borrow()
                ?? panic(providerRefMessage.concat(proposedNft.type.identifier))

            // verify token type
            let nft <- providerReference.withdraw(withdrawID: proposedNft.nftID)
            assert(nft.isInstance(proposedNft.type), message: typeMismatchMessage.concat(proposedNft.type.identifier))

            // transfer token
            receiverReference.deposit(token: <-nft)
        }
    }

    init() {

        // initialize contract constants
        self.AllowSwapProposalCreation = true
        self.SwapCollectionStoragePath = /storage/emSwapCollection
        self.SwapCollectionPrivatePath = /private/emSwapCollectionManager
        self.SwapCollectionPublicPath = /public/emSwapCollectionPublic
        self.SwapAdminStoragePath = /storage/emSwapAdmin
        self.SwapAdminPrivatePath = /private/emSwapAdmin
        self.SwapFees = []
        self.SwapProposalMinExpirationMinutes = 2.0
        self.SwapProposalMaxExpirationMinutes = 43800.0
        self.SwapProposalDefaultExpirationMinutes = 5.0

        // save swap proposal admin object and link capabilities
        self.account.save(<- create SwapAdmin(), to: self.SwapAdminStoragePath)
        self.account.link<&SwapAdmin{SwapProposalManager, SwapFeeManager}>(self.SwapAdminPrivatePath, target: self.SwapAdminStoragePath)
    }
}
