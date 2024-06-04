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

import FlowToken from "./../../standardsV1/FlowToken.cdc"

import NonFungibleToken from "./../../standardsV1/NonFungibleToken.cdc"

/*
	Pons Utils Contract

	This smart contract contains useful type definitions and convenience methods.
*/

access(all)
contract PonsUtils{ 
	/* Flow Units struct */
	access(all)
	struct FlowUnits{ 
		/* Represents the amount of Flow tokens */
		access(all)
		let flowAmount: UFix64
		
		init(flowAmount: UFix64){ 
			self.flowAmount = flowAmount
		}
		
		/* Check whether the amount is at least the amount of another FlowUnits */
		access(TMP_ENTITLEMENT_OWNER)
		fun isAtLeast(_ flowUnits: FlowUnits): Bool{ 
			return self.flowAmount >= flowUnits.flowAmount
		}
		
		/* Make another FlowUnits equivalent to the amount being scaled by a ratio */
		access(TMP_ENTITLEMENT_OWNER)
		fun scale(ratio: Ratio): FlowUnits{ 
			return FlowUnits(flowAmount: self.flowAmount * ratio.amount)
		}
		
		/* Make another FlowUnits equivalent to the amount being subtracted by another amount of FlowUnits */
		access(TMP_ENTITLEMENT_OWNER)
		fun cut(_ flowUnits: FlowUnits): FlowUnits{ 
			return FlowUnits(flowAmount: self.flowAmount - flowUnits.flowAmount)
		}
		
		/* Produce a string representation in a format like "1234.56 FLOW" */
		access(TMP_ENTITLEMENT_OWNER)
		fun toString(): String{ 
			return self.flowAmount.toString().concat(" FLOW")
		}
	}
	
	/* Ratio struct */
	access(all)
	struct Ratio{ 
		/* Represents the numerical ratio, so that for example 0.1 represents 10%, and 1.0 represents 100% */
		access(all)
		let amount: UFix64
		
		init(amount: UFix64){ 
			self.amount = amount
		}
	}
	
	/* Produce a FlowUnits equivalent to the sum of the two separate amounts of FlowUnits */
	access(TMP_ENTITLEMENT_OWNER)
	fun sumFlowUnits(_ flowUnits1: FlowUnits, _ flowUnits2: FlowUnits): FlowUnits{ 
		let flowAmount1 = flowUnits1.flowAmount
		let flowAmount2 = flowUnits2.flowAmount
		return FlowUnits(flowAmount: flowAmount1 + flowAmount2)
	}

// WORKAROUND -- ignore
// For some inexplicable reason Flow is not recognising `&PonsNftContract_v1.Collection` as `&NonFungibleToken.Collection`
//	/* Ensures that the NFTs in a NFT Collection are stored at the correct keys */
//	pub fun normaliseCollection (_ nftCollection : &NonFungibleToken.Collection) : Void {
//		post {
//			nftCollection .ownedNFTs .keys .length == before (nftCollection .ownedNFTs .keys .length):
//				"Size of NFT collection changed" }
//
//		for id in nftCollection .ownedNFTs .keys {
//			PonsUtils .normaliseId (nftCollection, id: id) } }
//
//	/* Ensures that the NFT in a NFT Collection stored at a certain key occupies the key corresponding to its NFT id */
//	priv fun normaliseId (_ nftCollection : &NonFungibleToken.Collection, id : UInt64) : Void {
//		var nftOptional <- nftCollection .ownedNFTs .remove (key: id)
//
//		if nftOptional == nil {
//			destroy nftOptional }
//		else {
//			var nft <- nftOptional !
//
//			if nft .id != id {
//				PonsUtils .normaliseId (nftCollection, id: nft .id) }
//
//			var nftBin <- nftCollection .ownedNFTs .insert (key: nft .id, <- nft)
//			assert (nftBin == nil, message: "Failed to normalise NFT collection")
//			destroy nftBin } }
}
