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
  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/

import MetadataViews from "./../../standardsV1/MetadataViews.cdc"

import ViewResolver from "../../standardsV1/ViewResolver.cdc"

access(all)
contract AnchainUtils{ 
	
	// One inconvenience with the new NFT metadata standard is that you 
	// cannot return nil from `borrowViewResolver(id: UInt64)`. Consider 
	// the case when we call the function with an ID that doesn't exist 
	// in the collection. In this scenario, we're forced to either panic 
	// or let a dereference error occcur, which may not be preferred in 
	// some situations. In order to prevent these errors from occuring we 
	// could write more code to check if the ID exists via getIDs() (cringe). 
	// OR we can simply use the interface below. This interface should help 
	// us resolve (no pun intended) the unwanted behavior described above 
	// and provides a much cleaner (and efficient) way of handling errors.
	//
	access(all)
	resource interface ResolverCollection{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun borrowViewResolverSafe(id: UInt64): &{ViewResolver.Resolver}?
	}
	
	// File
	// A MetadataViews.File with an added file extension. 
	//
	access(all)
	struct File{ 
		
		// The file extension
		//
		access(all)
		let extension: String
		
		// The file thumbnail
		//
		access(all)
		let thumbnail:{ MetadataViews.File}
		
		init(extension: String, thumbnail:{ MetadataViews.File}){ 
			self.extension = extension
			self.thumbnail = thumbnail
		}
	}
}
