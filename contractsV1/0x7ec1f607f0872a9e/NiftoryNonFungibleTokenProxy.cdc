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

	import NiftoryNonFungibleToken from "./NiftoryNonFungibleToken.cdc"

access(all)
contract NiftoryNonFungibleTokenProxy{ 
	access(all)
	let STORAGE_PATH: StoragePath
	
	access(all)
	let PUBLIC_PATH: PublicPath
	
	access(all)
	let PRIVATE_PATH: PrivatePath
	
	access(all)
	resource interface Public{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun add(
			registryAddress: Address,
			brand: String,
			cap: Capability<
				&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}
			>
		): Void
	}
	
	access(all)
	resource interface Private{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun replace(
			registryAddress: Address,
			brand: String,
			cap: Capability<
				&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}
			>
		): Void
		
		access(TMP_ENTITLEMENT_OWNER)
		fun _access(registryAddress: Address, brand: String): &{
			NiftoryNonFungibleToken.ManagerPrivate,
			NiftoryNonFungibleToken.ManagerPublic
		}
	}
	
	access(all)
	resource Proxy: Public, Private{ 
		
		// NFT contract address -> Manager capabilities
		access(self)
		let _proxies:{ Address:{ String: Capability<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>}}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun add(registryAddress: Address, brand: String, cap: Capability<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>){ 
			pre{ 
				self._proxies[registryAddress] == nil || (self._proxies[registryAddress]!)[brand] == nil:
					"NFT Manager capability already exists for contract at address ".concat(registryAddress.toString()).concat(" for brand ").concat(brand)
			}
			if self._proxies[registryAddress] == nil{ 
				self._proxies[registryAddress] ={} 
			}
			let caps = &self._proxies[registryAddress]! as auth(Mutate) &{String: Capability<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>}
			caps[brand] = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun replace(registryAddress: Address, brand: String, cap: Capability<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>){ 
			if self._proxies[registryAddress] == nil{ 
				self._proxies[registryAddress] ={} 
			}
			let caps = &self._proxies[registryAddress]! as auth(Mutate) &{String: Capability<&{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}>}
			caps[brand] = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun _access(registryAddress: Address, brand: String): &{NiftoryNonFungibleToken.ManagerPrivate, NiftoryNonFungibleToken.ManagerPublic}{ 
			pre{ 
				self._proxies[registryAddress] != nil && (self._proxies[registryAddress]!)[brand] != nil:
					"No NFT Manager capability for contract at address ".concat(registryAddress.toString()).concat(" for brand ").concat(brand)
				((self._proxies[registryAddress]!)[brand]!).check():
					"Cannot find NFT Manager for capability for contract at address".concat(registryAddress.toString()).concat(" for brand ").concat(brand)
			}
			return ((self._proxies[registryAddress]!)[brand]!).borrow()!
		}
		
		init(){ 
			self._proxies ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun _create(): @Proxy{ 
		return <-create Proxy()
	}
	
	init(){ 
		self.STORAGE_PATH = /storage/niftory_nft_manager_proxy
		self.PUBLIC_PATH = /public/niftory_nft_manager_proxy
		self.PRIVATE_PATH = /private/niftory_nft_manager_proxy
	}
}
