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

	/// Pausable
///
/// The interface that pausable contracts implement.
///
access(TMP_ENTITLEMENT_OWNER)
contract interface Pausable{ 
	/// paused
	/// If current contract is paused
	///
	access(contract)
	var paused: Bool
	
	/// Paused
	///
	/// Emitted when the pause is triggered.
	access(all)
	event Paused()
	
	/// Unpaused
	///
	/// Emitted when the pause is lifted.
	access(all)
	event Unpaused()
	
	/// Pausable Checker
	/// 
	/// some methods to check if paused
	/// 
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Checker{ 
		/// Returns true if the contract is paused, and false otherwise.
		///
		access(TMP_ENTITLEMENT_OWNER)
		view fun paused(): Bool
		
		/// a function callable only when the contract is not paused.
		/// 
		/// Requirements:
		/// - The contract must not be paused.
		///
		access(contract)
		fun whenNotPaused(){ 
			pre{ 
				!self.paused():
					"Pausable: paused"
			}
		}
		
		/// a function callable only when the contract is paused.
		/// 
		/// Requirements:
		/// - The contract must be paused.
		///
		access(contract)
		fun whenPaused(){ 
			pre{ 
				self.paused():
					"Pausable: not paused"
			}
		}
	}
	
	/// Puasable Pauser
	///
	access(TMP_ENTITLEMENT_OWNER)
	resource interface Pauser{ 
		/// pause
		/// 
		access(TMP_ENTITLEMENT_OWNER)
		fun pause()
		
		/// unpause
		///
		access(TMP_ENTITLEMENT_OWNER)
		fun unpause()
	}
}
