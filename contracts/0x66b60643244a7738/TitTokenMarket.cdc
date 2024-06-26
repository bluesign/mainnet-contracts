import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import TitToken from 0x66b60643244a7738 // Replace with actual address

pub contract TitTokenMarket {
    pub resource Listing {
        pub let seller: Address
        pub let price: UFix64
        pub let amount: UFix64
        pub var tokenVault: @FungibleToken.Vault

        init(_seller: Address, _price: UFix64, _amount: UFix64, _vault: @FungibleToken.Vault) {
            self.seller = _seller
            self.price = _price
            self.amount = _amount
            self.tokenVault <- _vault
        }

        // This method allows the transfer of tokens to a buyer's vault
        pub fun transferTokens(buyerVaultRef: &{FungibleToken.Receiver}) {
            let amount = self.amount
            let tokens <- self.tokenVault.withdraw(amount: amount)
            buyerVaultRef.deposit(from: <- tokens)
        }

        destroy() {
            destroy self.tokenVault
        }
    }

    pub var listings: @{UInt64: Listing}
    pub var nextListingId: UInt64


    pub event ListingCreated(listingId: UInt64, seller: Address, price: UFix64, amount: UFix64)
    pub event TokensPurchased(listingId: UInt64, buyer: Address, price: UFix64, amount: UFix64)
    pub event ListingRemoved(listingId: UInt64, seller: Address)

    // Function to list TitTokens for sale
    pub fun createListing(signer: AuthAccount, price: UFix64, amount: UFix64): UInt64 {
        let vaultRef = signer.borrow<&TitToken.Vault{FungibleToken.Provider, FungibleToken.Balance}>(from: TitToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the TitToken vault")

        let tokens <- vaultRef.withdraw(amount: amount)

        let listingId = self.nextListingId
        self.nextListingId = self.nextListingId + 1

        let listing <- create Listing(_seller: signer.address, _price: price, _amount: amount, _vault: <- tokens)
        self.listings[listingId] <-! listing
        emit ListingCreated(listingId: listingId, seller: signer.address, price: price, amount: amount)

        return listingId
    }

    // Function to purchase TitTokens
    pub fun purchaseTokens(listingId: UInt64, buyer: AuthAccount, paymentVault: @FungibleToken.Vault) {
        let listing <- self.listings.remove(key: listingId)
            ?? panic("Listing does not exist.")

        let seller = getAccount(listing.seller)

        // Ensure the paymentVault is a Flow token vault and deposit Flow tokens into the seller's vault
        let receiver = seller.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            .borrow() ?? panic("Could not borrow receiver reference to the seller's Flow token vault")
        receiver.deposit(from: <- paymentVault)

        // Ensure the buyer has a TitToken receiver and transfer TitTokens from the listing to the buyer
        let buyerReceiver = buyer.getCapability<&{FungibleToken.Receiver}>(TitToken.VaultReceiverPath)
            .borrow() ?? panic("Could not borrow receiver reference to the buyer's TitToken vault")
        listing.transferTokens(buyerVaultRef: buyerReceiver)

        emit TokensPurchased(listingId: listingId, buyer: buyer.address, price: listing.price, amount: listing.amount)
        destroy listing
    }


    // Function to remove a listing
    pub fun removeListing(signer: AuthAccount, listingId: UInt64) {
        let listing <- self.listings.remove(key: listingId)
            ?? panic("Listing does not exist.")

        assert(listing.seller == signer.address, message: "Only the seller can remove the listing")

        emit ListingRemoved(listingId: listingId, seller: signer.address)
        destroy listing
    }

    init() {
        self.listings <- {}
        self.nextListingId = 1
    }
}
