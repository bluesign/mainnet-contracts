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

	Parsing failed:
error: unexpected token in type: '<<'
    --> :1033:419
     |
1033 |         access(TMP_ENTITLEMENT_OWNER) fun createListing(nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>, nftPublicCollectionCapability: Capability<&{NonFungibleToken.CollectionPublic}>, ownerFungibleTokenReceiver: Capability<&{FungibleToken.Receiver}>, nftType: Type, nftID: UInt64, amount: UFix64, deposit: UFix64, term: UFix64, paymentVaultType: Type, paymentCut: <<invalid>>, expiresAfter: UFix64, renter: Address?): UInt64
     |                                                                                                                                                                                                                                                                                                                                                                                                                                    ^
