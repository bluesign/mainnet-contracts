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

	import FLOATEventSeries from "./FLOATEventSeries.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

access(all)
contract FLOATEventSeriesViews{ 
	
	// EventSeries Slot information
	access(all)
	struct SeriesSlotInfo{ 
		access(all)
		let event: FLOATEventSeries.EventIdentifier?
		
		access(all)
		let required: Bool
		
		init(_ identifier: FLOATEventSeries.EventIdentifier?, _ isRequired: Bool){ 
			self.event = identifier
			self.required = isRequired
		}
	}
	
	// EventSeries Metadata
	access(all)
	struct EventSeriesMetadata{ 
		access(all)
		let host: Address
		
		access(all)
		let id: UInt64
		
		access(all)
		let sequence: UInt64
		
		access(all)
		let display: MetadataViews.Display?
		
		access(all)
		let slots: [SeriesSlotInfo]
		
		access(all)
		let extra:{ String: AnyStruct}
		
		init(_ eventSeries: &FLOATEventSeries.EventSeries, _ resolver: &{ViewResolver.Resolver}){ 
			self.host = (eventSeries.owner!).address
			self.id = eventSeries.uuid
			self.sequence = eventSeries.sequence
			self.display = MetadataViews.getDisplay(resolver)
			self.slots = []
			// fill slots
			let slots = eventSeries.getSlots()
			for slot in slots{ 
				self.slots.append(SeriesSlotInfo(slot.getIdentifier(), slot.isEventRequired()))
			}
			self.extra = eventSeries.getExtra()
		}
	}
	
	// Treasury return data
	access(all)
	struct TreasuryData{ 
		access(all)
		let tokenBalances:{ String: UFix64}
		
		access(all)
		let collectionIDs:{ String: [UInt64]}
		
		init(balances:{ String: UFix64}, ids:{ String: [UInt64]}){ 
			self.tokenBalances = balances
			self.collectionIDs = ids
		}
	}
}
