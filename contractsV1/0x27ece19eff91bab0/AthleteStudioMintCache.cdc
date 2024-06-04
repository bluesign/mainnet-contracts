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

	/// AthleteStudioMintCache is a utility contract to keep track of Athlete Studio editions
/// that have been minted in order to prevent duplicate mints.
///
/// It should be deployed to the same account as the AthleteStudio contract.
///
access(all)
contract AthleteStudioMintCache{ 
	
	/// This dictionary indexes editions by their mint ID.
	///
	/// It is populated at mint time and used to prevent duplicate mints.
	/// The mint ID can be any unique string value,
	/// for example the hash of the edition metadata.
	///
	access(self)
	let editionsByMintID:{ String: UInt64}
	
	/// Get an edition ID by its mint ID.
	///
	/// This function returns nil if the edition is not in this index.
	///
	access(TMP_ENTITLEMENT_OWNER)
	fun getEditionByMintID(mintID: String): UInt64?{ 
		return AthleteStudioMintCache.editionsByMintID[mintID]
	}
	
	/// Insert an edition mint ID into the index.
	/// 
	/// This function can only be called by other contracts deployed to this account.
	/// It is intended to be called by the AthleteStudio contract when
	/// creating new editions.
	///
	access(account)
	fun insertEditionMintID(mintID: String, editionID: UInt64){ 
		AthleteStudioMintCache.editionsByMintID[mintID] = editionID
	}
	
	init(){ 
		self.editionsByMintID ={} 
	}
}
