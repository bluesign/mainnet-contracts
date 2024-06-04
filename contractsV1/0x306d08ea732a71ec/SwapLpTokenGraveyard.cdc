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

# Swap Lp Tokens Graveyard

# Author: Increment Labs

*/

access(all)
contract SwapLpTokenGraveyard{}
// This contract acts as a graveyard for swapping LP tokens.
// LP tokens sent to this address will be permanently sealed and cannot be retrieved.

// There is no private key associated with this address, ensuring it can never be manipulated or controlled by anyone.
// The contract cannot be upgraded, and tokens cannot be misappropriated.

// It serves exclusively as a graveyard for increment swap LP tokens and does not support generic Fungible Tokens.

