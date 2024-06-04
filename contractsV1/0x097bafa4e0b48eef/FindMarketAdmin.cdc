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

	import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import FIND from "./FIND.cdc"

import FindMarket from "./FindMarket.cdc"

import FindMarketCutStruct from "./FindMarketCutStruct.cdc"

access(all)
contract FindMarketAdmin{ 
	
	//store the proxy for the admin
	access(all)
	let AdminProxyPublicPath: PublicPath
	
	access(all)
	let AdminProxyStoragePath: StoragePath
	
	/// ===================================================================================
	// Admin things
	/// ===================================================================================
	//Admin client to use for capability receiver pattern
	access(TMP_ENTITLEMENT_OWNER)
	fun createAdminProxyClient(): @AdminProxy{ 
		return <-create AdminProxy()
	}
	
	//interface to use for capability receiver pattern
	access(all)
	resource interface AdminProxyClient{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&FIND.Network>): Void
	}
	
	//admin proxy with capability receiver
	access(all)
	resource AdminProxy: AdminProxyClient{ 
		access(self)
		var capability: Capability<&FIND.Network>?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addCapability(_ cap: Capability<&FIND.Network>){ 
			pre{ 
				cap.check():
					"Invalid server capablity"
				self.capability == nil:
					"Server already set"
			}
			self.capability = cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createFindMarket(name: String, address: Address, findCutSaleItem: FindMarket.TenantSaleItem?): Capability<&FindMarket.Tenant>{ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			return FindMarket.createFindMarket(name: name, address: address, findCutSaleItem: findCutSaleItem)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFindMarketTenant(tenant: Address){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.removeFindMarketTenant(tenant: tenant)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getFindMarketClient(): &FindMarket.TenantClient{ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let path = FindMarket.TenantClientStoragePath
			return FindMarketAdmin.account.storage.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Find market tenant client Reference.")
		}
		
		/// ===================================================================================
		// Find Market Options
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun addSaleItemType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addMarketBidType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addSaleItemCollectionType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemCollectionType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addMarketBidCollectionType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidCollectionType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleItemType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMarketBidType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeSaleItemCollectionType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemCollectionType(type)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMarketBidCollectionType(_ type: Type){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidCollectionType(type)
		}
		
		/// ===================================================================================
		// Tenant Rules Management
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun getTenantRef(_ tenant: Address): &FindMarket.Tenant{ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let string = FindMarket.getTenantPathForAddress(tenant)
			let pp = PrivatePath(identifier: string) ?? panic("Cannot generate storage path from string : ".concat(string))
			let cap = FindMarketAdmin.account.capabilities.get<&FindMarket.Tenant>(pp)
			return cap.borrow() ?? panic("Cannot borrow tenant reference from path. Path : ".concat(pp.toString()))
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun addFindBlockItem(tenant: Address, item: FindMarket.TenantSaleItem){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(item, type: "find")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeFindBlockItem(tenant: Address, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "find")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setFindCut(tenant: Address, saleItem: FindMarket.TenantSaleItem){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "cut")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setExtraCut(tenant: Address, types: [Type], category: String, cuts: FindMarketCutStruct.Cuts){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setExtraCut(types: types, category: category, cuts: cuts)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setMarketOption(tenant: Address, saleItem: FindMarket.TenantSaleItem){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "tenant")
		//Emit Event here
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun removeMarketOption(tenant: Address, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "tenant")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun enableMarketOption(tenant: Address, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "active")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deprecateMarketOption(tenant: Address, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "deprecated")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun stopMarketOption(tenant: Address, name: String){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "stopped")
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun setupSwitchboardCut(tenant: Address){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setupSwitchboardCut()
		}
		
		/// ===================================================================================
		// Royalty Residual
		/// ===================================================================================
		access(TMP_ENTITLEMENT_OWNER)
		fun setResidualAddress(_ address: Address){ 
			pre{ 
				self.capability != nil:
					"Cannot create FIND, capability is not set"
			}
			FindMarket.setResidualAddress(address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getSwitchboardReceiverPublic(): Capability<&{FungibleToken.Receiver}>{ 
			// we hard code it here instead, to avoid importing just for path
			return FindMarketAdmin.account.capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)!
		}
		
		init(){ 
			self.capability = nil
		}
	}
	
	init(){ 
		self.AdminProxyPublicPath = /public/findMarketAdminProxy
		self.AdminProxyStoragePath = /storage/findMarketAdminProxy
	}
}
