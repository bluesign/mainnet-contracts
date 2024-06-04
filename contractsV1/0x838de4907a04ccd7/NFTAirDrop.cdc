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

	import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

access(all)
contract NFTAirDrop{ 
	access(all)
	event Claimed(nftType: Type, nftID: UInt64, recipient: Address)
	
	access(all)
	let DropStoragePath: StoragePath
	
	access(all)
	let DropPublicPath: PublicPath
	
	access(all)
	resource interface DropPublic{ 
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(
			id: UInt64,
			signature: [
				UInt8
			],
			receiver: &{NonFungibleToken.CollectionPublic}
		): Void
	}
	
	access(all)
	resource Drop: DropPublic{ 
		access(self)
		let nftType: Type
		
		access(self)
		let collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		access(self)
		let claims:{ UInt64: [UInt8]}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT}, publicKey: [UInt8]){ 
			let collection = self.collection.borrow()!
			self.claims[token.id] = publicKey
			collection.deposit(token: <-token)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(id: UInt64, signature: [UInt8], receiver: &{NonFungibleToken.CollectionPublic}){ 
			let collection = self.collection.borrow()!
			let rawPublicKey = self.claims.remove(key: id) ?? panic("no claim exists for NFT")
			let publicKey = PublicKey(publicKey: rawPublicKey, signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
			let address = (receiver.owner!).address
			let message = self.makeClaimMessage(address: address, id: id)
			let isValidClaim = publicKey.verify(signature: signature, signedData: message, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
			assert(isValidClaim, message: "invalid claim signature")
			receiver.deposit(token: <-collection.withdraw(withdrawID: id))
			emit Claimed(nftType: self.nftType, nftID: id, recipient: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun makeClaimMessage(address: Address, id: UInt64): [UInt8]{ 
			let addressBytes = address.toBytes()
			let idBytes = id.toBigEndianBytes()
			return addressBytes.concat(idBytes)
		}
		
		init(nftType: Type, collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.nftType = nftType
			self.collection = collection
			self.claims ={} 
		}
	}
	
	access(TMP_ENTITLEMENT_OWNER)
	fun createDrop(
		nftType: Type,
		collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
	): @Drop{ 
		return <-create Drop(nftType: nftType, collection: collection)
	}
	
	init(){ 
		self.DropStoragePath = /storage/BarterYardPackNFTAirDrop
		self.DropPublicPath = /public/BarterYardPackNFTAirDrop
	}
}
