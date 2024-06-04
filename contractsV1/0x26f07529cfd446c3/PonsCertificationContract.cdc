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

	/*
	Pons Certification Contract

	This smart contract contains the PonsCertification resource, which acts as authorisation by the Pons account.
*/

access(all)
contract PonsCertificationContract{ 
	/*
		Pons Certification Resource
	
		This resource acts as authorisation by the Pons account.
	*/
	
	access(all)
	resource PonsCertification{} 
	
	/* Smart contracts on the Pons account can create PonsCertification instances using this function */
	access(account)
	fun makePonsCertification(): @PonsCertification{ 
		return <-create PonsCertification()
	}
}
