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
error: statements on the same line must be separated with a semicolon
   --> :232:29
    |
232 |         self.capabilitiesvar capability_1 = self.account.capabilities.storage.issue<&Admin>( /storage/FanTopAdmin)
    |                              ^

error: statements on the same line must be separated with a semicolon
   --> :236:29
    |
236 |         self.capabilitiesvar capability_2 = self.account.capabilities.storage.issue<&Operator>( /storage/FanTopOperator)
    |                              ^

error: statements on the same line must be separated with a semicolon
   --> :240:29
    |
240 |         self.capabilitiesvar capability_3 = self.account.capabilities.storage.issue<&Minter>( /storage/FanTopMinter)
    |                              ^
