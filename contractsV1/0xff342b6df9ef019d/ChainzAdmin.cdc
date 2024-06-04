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

	import ChainzPack from "./ChainzPack.cdc"

import ChainzNFT from "./ChainzNFT.cdc"

import ChainzKey from "./ChainzKey.cdc"

access(all)
contract ChainzAdmin{ 
	access(all)
	let AdminStoragePath: StoragePath
	
	access(all)
	resource Admin{ 
		
		// openPack
		// calls openPack on the user's Pack Collection
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun openPack(
			id: UInt64,
			packCollectionRef: &ChainzPack.Collection,
			cardCollectionRef: &ChainzNFT.Collection,
			names: [
				String
			],
			descriptions: [
				String
			],
			thumbnails: [
				String
			],
			metadatas: [{
				
					String: String
				}
			],
			keyTiers: [
				String
			],
			keyTypes: [
				String
			],
			keySerials: [
				UInt64
			],
			keyMetadatas: [{
				
					String: String
				}
			]
		){ 
			packCollectionRef.openPack(
				id: id,
				cardCollectionRef: cardCollectionRef,
				names: names,
				descriptions: descriptions,
				thumbnails: thumbnails,
				metadatas: metadatas
			)
			
			// Mint the user a Chainz Ket
			let recipient = (packCollectionRef.owner!).address
			let chainzKeyCollection =
				getAccount(recipient).capabilities.get<&ChainzKey.Collection>(
					ChainzKey.CollectionPublicPath
				).borrow<&ChainzKey.Collection>()
				?? panic("This user does not have a ChainzKey Collection set up.")
			var i: Int = 0
			while i < keyTiers.length{ 
				chainzKeyCollection.deposit(token: <-ChainzKey.createNFT(tier: keyTiers[i], type: keyTypes[i], serial: keySerials[i], metadata: keyMetadatas[i]))
				i = i + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun airdropMoments(
			cardCollectionRef: &ChainzNFT.Collection,
			names: [
				String
			],
			descriptions: [
				String
			],
			thumbnails: [
				String
			],
			metadatas: [{
				
					String: String
				}
			]
		){ 
			let recipient = (cardCollectionRef.owner!).address
			let chainzNFTCollection =
				getAccount(recipient).capabilities.get<&ChainzNFT.Collection>(
					ChainzNFT.CollectionPublicPath
				).borrow<&ChainzNFT.Collection>()
				?? panic("This user does not have a ChainzNFT Collection set up.")
			var i: Int = 0
			while i < names.length{ 
				chainzNFTCollection.deposit(token: <-ChainzNFT.createNFT(name: names[i], description: descriptions[i], thumbnail: thumbnails[i], metadata: metadatas[i]))
				i = i + 1
			}
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun createPackType(
			name: String,
			price: UFix64,
			maxSupply: UInt64,
			reserved: UInt64,
			extra:{ 
				String: String
			}
		){ 
			ChainzPack.createPackType(
				name: name,
				price: price,
				maxSupply: maxSupply,
				reserved: reserved,
				extra: extra
			)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun togglePackTypeActive(id: UInt64){ 
			ChainzPack.toggleActive(packTypeId: id)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun reserveMintPack(packCollectionRef: &ChainzPack.Collection, packTypeId: UInt64){ 
			ChainzPack.reserveMint(packCollectionRef: packCollectionRef, packTypeId: packTypeId)
		}
		
		// createAdmin
		// only an admin can ever create
		// a new Admin resource
		//
		access(TMP_ENTITLEMENT_OWNER)
		fun createAdmin(): @Admin{ 
			return <-create Admin()
		}
		
		init(){} 
	}
	
	init(){ 
		self.AdminStoragePath = /storage/ChainzAdmin
		self.account.storage.save(<-create Admin(), to: self.AdminStoragePath)
	}
}
