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

import FungibleToken from "./../../standardsV1/FungibleToken.cdc"

access(all)
contract NFTAirDrop{ 
	access(all)
	event Claimed(nftType: Type, nftID: UInt64, recipient: Address)
	
	access(all)
	let DropStoragePath: StoragePath
	
	access(all)
	let DropPublicPath: PublicPath
	
	/* Custom public interface for our drop capability. */
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
		
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaims():{ UInt64: String}
	}
	
	/* Drop
		Resource that will store pre-minted claimable NFTs.
		Upon minting, a public/private key pair is generated,
		users will be able to claim the NFT with the private key
		and NFTs are stored along with the public key to verify it matches.
		The project using this smart contract will only have to pre-mint,
		and share the private keys with users ahead of time.
		This smart contract is generic and can be used to store any NFT type.
		But the DropStoragePath still limits to 1 drop (hence 1 type) per account.
		*/
	
	access(all)
	resource Drop: DropPublic{ 
		access(self)
		let nftType: Type
		
		access(self)
		let collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
		
		// map of nft ids to decoded public claim keys
		access(self)
		let claims:{ UInt64: [UInt8]}
		
		init(nftType: Type, collection: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>){ 
			self.nftType = nftType
			self.collection = collection
			self.claims ={} 
		}
		
		// list yet-to-be-claimed NFTs along with the public claim keys
		access(TMP_ENTITLEMENT_OWNER)
		fun getClaims():{ UInt64: String}{ 
			let encodedClaims:{ UInt64: String} ={} 
			for nftID in self.claims.keys{ 
				encodedClaims[nftID] = String.encodeHex(self.claims[nftID]!)
			}
			return encodedClaims
		}
		
		/* A Drop acts as a proxy for a Collection:
				when a token is deposited, add the (token.id, claimKey) pair to the Drop resource,
				and forward the token to the Collection that the Drop was initialised with.
				*/
		
		access(TMP_ENTITLEMENT_OWNER)
		fun deposit(token: @{NonFungibleToken.NFT}, publicKey: [UInt8]){ 
			let collection = self.collection.borrow()!
			self.claims[token.id] = publicKey
			collection.deposit(token: <-token)
		}
		
		// claim a claimable NFT part of the Drop using a cryptographic signature
		access(TMP_ENTITLEMENT_OWNER)
		fun claim(id: UInt64, signature: [UInt8], receiver: &{NonFungibleToken.CollectionPublic}){ 
			let collection = self.collection.borrow()!
			let rawPublicKey = self.claims.remove(key: id) ?? panic("no claim exists for NFT")
			let publicKey = PublicKey(publicKey: rawPublicKey, signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
			let address = (receiver.owner!).address
			let message = self.makeClaimMessage(receiverAddress: address, nftID: id)
			let isValidClaim = publicKey.verify(signature: signature, signedData: message, domainSeparationTag: "FLOW-V0.0-user", hashAlgorithm: HashAlgorithm.SHA3_256)
			assert(isValidClaim, message: "invalid claim signature")
			receiver.deposit(token: <-collection.withdraw(withdrawID: id))
			emit Claimed(nftType: self.nftType, nftID: id, recipient: address)
		}
		
		access(TMP_ENTITLEMENT_OWNER)
		fun makeClaimMessage(receiverAddress: Address, nftID: UInt64): [UInt8]{ 
			let addressBytes = receiverAddress.toBytes()
			let idBytes = nftID.toBigEndianBytes()
			return addressBytes.concat(idBytes)
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
		self.DropStoragePath = /storage/NFTAirDrop
		self.DropPublicPath = /public/NFTAirDrop
	}
}
