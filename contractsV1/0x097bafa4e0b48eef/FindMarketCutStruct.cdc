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

access(all)
contract FindMarketCutStruct{ 
	access(all)
	struct Cuts{ 
		access(all)
		let cuts: [{Cut}]
		
		access(contract)
		let extra:{ String: AnyStruct}
		
		init(cuts: [{Cut}]){ 
			self.cuts = cuts
			self.extra ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEventSafeCuts(): [EventSafeCut]{ 
			let cuts: [EventSafeCut] = []
			for c in self.cuts{ 
				cuts.append(c.getEventSafeCut())
			}
			return cuts
		}
	}
	
	access(all)
	struct EventSafeCut{ 
		access(all)
		let name: String
		
		access(all)
		let description: String
		
		access(all)
		let cut: UFix64
		
		access(all)
		let receiver: Address
		
		access(all)
		let extra:{ String: String}
		
		init(
			name: String,
			description: String,
			cut: UFix64,
			receiver: Address,
			extra:{ 
				String: String
			}
		){ 
			self.name = name
			self.description = description
			self.cut = cut
			self.receiver = receiver
			self.extra = extra
		}
	}
	
	access(all)
	struct interface Cut{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun getName(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReceiverCap(): Capability<&{FungibleToken.Receiver}>
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCut(): UFix64
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(): Address
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPayableLogic(): fun (UFix64): UFix64?
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtra():{ String: String}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getRoyalty(): MetadataViews.Royalty{ 
			let cap = self.getReceiverCap()
			return MetadataViews.Royalty(
				receiver: cap,
				cut: self.getCut(),
				description: self.getName()
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAmountPayable(_ salePrice: UFix64): UFix64?{ 
			if let cut = self.getPayableLogic()(salePrice){ 
				return cut
			}
			return nil
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getEventSafeCut(): EventSafeCut{ 
			return EventSafeCut(
				name: self.getName(),
				description: self.getDescription(),
				cut: self.getCut(),
				receiver: self.getAddress(),
				extra: self.getExtra()
			)
		}
	}
	
	access(all)
	struct GeneralCut: Cut{ 
		// This is the description of the royalty struct
		access(all)
		let name: String
		
		access(all)
		let cap: Capability<&{FungibleToken.Receiver}>
		
		access(all)
		let cut: UFix64
		
		// This is the description to the cut that can be visible to give detail on detail page
		access(all)
		let description: String
		
		access(self)
		let extra:{ String: AnyStruct}
		
		init(name: String, cap: Capability<&{FungibleToken.Receiver}>, cut: UFix64, description: String){ 
			self.name = name
			self.cap = cap
			self.cut = cut
			self.description = description
			self.extra ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReceiverCap(): Capability<&{FungibleToken.Receiver}>{ 
			return self.cap
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getName(): String{ 
			return self.name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCut(): UFix64{ 
			return self.cut
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(): Address{ 
			return self.cap.address
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtra():{ String: String}{ 
			return{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPayableLogic(): fun (UFix64): UFix64?{ 
			return fun (_ salePrice: UFix64): UFix64?{ 
				return salePrice * self.cut
			}
		}
	}
	
	access(all)
	struct ThresholdCut: Cut{ 
		// This is the description of the royalty struct
		access(all)
		let name: String
		
		access(all)
		let address: Address
		
		access(all)
		let cut: UFix64
		
		// This is the description to the cut that can be visible to give detail on detail page
		access(all)
		let description: String
		
		access(all)
		let publicPath: String
		
		access(all)
		let minimumPayment: UFix64
		
		access(self)
		let extra:{ String: AnyStruct}
		
		init(name: String, address: Address, cut: UFix64, description: String, publicPath: String, minimumPayment: UFix64){ 
			self.name = name
			self.address = address
			self.cut = cut
			self.description = description
			self.publicPath = publicPath
			self.minimumPayment = minimumPayment
			self.extra ={} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getReceiverCap(): Capability<&{FungibleToken.Receiver}>{ 
			let pp = PublicPath(identifier: self.publicPath)!
			return getAccount(self.address).capabilities.get<&{FungibleToken.Receiver}>(pp)!
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getName(): String{ 
			return self.name
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getCut(): UFix64{ 
			return self.cut
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getAddress(): Address{ 
			return self.address
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getDescription(): String{ 
			return self.description
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getExtra():{ String: String}{ 
			return{} 
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getPayableLogic(): fun (UFix64): UFix64?{ 
			return fun (_ salePrice: UFix64): UFix64?{ 
				let rPayable = salePrice * self.cut
				if rPayable < self.minimumPayment{ 
					return self.minimumPayment
				}
				return rPayable
			}
		}
	}
}
