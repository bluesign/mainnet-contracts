import Crypto
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import NFTCatalog from "../0x49a7cda3a1eecc29/NFTCatalog.cdc"
import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FIND from "../0x097bafa4e0b48eef/FIND.cdc"
import EmeraldIdentity from "../0x39e42c67cc851cfb/EmeraldIdentity.cdc"
import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"
import LiquidStaking from "../0xd6f80565193ad727/LiquidStaking.cdc"
import FlowToken from "../0x1654653399040a61/FlowToken.cdc"
import stFlowToken from "../0xd6f80565193ad727/stFlowToken.cdc"

pub contract ToucansUtils {
  pub fun ownsNFTFromCatalogCollectionIdentifier(collectionIdentifier: String, user: Address): Bool {
    if let entry: NFTCatalog.NFTCatalogMetadata = NFTCatalog.getCatalogEntry(collectionIdentifier: collectionIdentifier) {
      let publicPath: PublicPath = entry.collectionData.publicPath
      let contractAddressToString: String = entry.contractAddress.toString()
      let constructedIdentifier: String = "A.".concat(contractAddressToString.slice(from: 2, upTo: contractAddressToString.length)).concat(".").concat(entry.contractName).concat(".Collection")

      var addresses: [Address] = [user]
      if let discordID: String = EmeraldIdentity.getDiscordFromAccount(account: user) {
        addresses = EmeraldIdentity.getEmeraldIDs(discordID: discordID).values
      }
      assert(addresses.contains(user), message: "Should always be true. Just making sure so the user doesn't get punished accidentally ;)")
      for address in addresses {
        if let collection: &{NonFungibleToken.CollectionPublic} = getAccount(address).getCapability(publicPath).borrow<&{NonFungibleToken.CollectionPublic}>() {
          let identifier: String = collection.getType().identifier
          if identifier == constructedIdentifier && collection.getIDs().length > 0 {
            return true
          }
        }
      }
    }
    
    return false
  }

  pub fun depositTokensToAccount(funds: @FungibleToken.Vault, to: Address, publicPath: PublicPath) {
    let vault = getAccount(to).getCapability(publicPath).borrow<&{FungibleToken.Receiver}>() 
              ?? panic("Account does not have a proper Vault set up.")
    vault.deposit(from: <- funds)
  }

  pub fun rangeFunc(_ start: Int, _ end: Int, _ f : ((Int):Void) ) {
    var current = start
    while current < end{
        f(current)
        current = current + 1
    }
  } 

  pub fun range(_ start: Int, _ end: Int): [Int]{
    var res:[Int] = []
    self.rangeFunc(start, end, fun (i:Int){
        res.append(i)
    })
    return res
  }

  pub fun index(_ s : String, _ substr : String, _ startIndex: Int): Int?{
    for i in self.range(startIndex,s.length-substr.length+1){
        if s[i]==substr[0] && s.slice(from:i, upTo:i+substr.length) == substr{
            return i
        }
    }
    return nil
  }

  pub fun getFind(_ address: Address): String {
    if let name = FIND.reverseLookup(address) {
      return name.concat(".find")
    }
    return address.toString()
  }

  pub fun fixToReadableString(num: UFix64): String {
    let numToString: String = num.toString()
    let indexOfDot: Int = ToucansUtils.index(numToString, ".", 1)!
    return numToString.slice(from: 0, upTo: indexOfDot + 3)
  }

  // stringAddress DOES NOT include the `0x`
  pub fun stringToAddress(stringAddress: String): Address {
    var r: UInt64 = 0
    var bytes: [UInt8] = stringAddress.decodeHex()

    while bytes.length > 0 {
      r = r + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8))
    }

    return Address(r)
  }

  // returns:
  // [address, contractname]
  pub fun getAddressAndContractNameFromCollectionIdentifier(identifier: String): [AnyStruct] {
    let address: Address = self.stringToAddress(stringAddress: identifier.slice(from: 2, upTo: 18))
    let contractName: String = identifier.slice(from: 19, upTo: identifier.length - 11)
    return [address, contractName]
  }

  pub fun getEstimatedOut(amountIn: UFix64, tokenInKey: String): UFix64 {
    // normal xyk pool
    let poolCapV1 = getAccount(0x396c0cda3302d8c5).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
    // stableswap pool with most liquidity
    let poolCapStable = getAccount(0xc353b9d685ec427d).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
    
    let estimatedSwapOutV1 = poolCapV1.getAmountOut(amountIn: amountIn, tokenInKey: tokenInKey)
    let estimatedSwapOutStable = poolCapStable.getAmountOut(amountIn: amountIn, tokenInKey: tokenInKey)
    let estimatedSwapOut = (estimatedSwapOutStable > estimatedSwapOutV1) ? estimatedSwapOutStable : estimatedSwapOutV1

    if tokenInKey == "A.1654653399040a61.FlowToken" {
      let estimatedStakeOut = LiquidStaking.calcStFlowFromFlow(flowAmount: amountIn)
      return (estimatedSwapOut > estimatedStakeOut) ? estimatedSwapOut : estimatedStakeOut
    }

    return estimatedSwapOut
  }

  pub fun swapTokensWithPotentialStake(inVault: @FungibleToken.Vault, tokenInKey: String): @FungibleToken.Vault {
    let amountIn = inVault.balance
    // normal xyk pool
    let poolCapV1 = getAccount(0x396c0cda3302d8c5).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
    let estimatedSwapOutV1 = poolCapV1.getAmountOut(amountIn: amountIn, tokenInKey: tokenInKey)
    // stableswap pool with most liquidity
    let poolCapStable = getAccount(0xc353b9d685ec427d).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!
    let estimatedSwapOutStable = poolCapStable.getAmountOut(amountIn: amountIn, tokenInKey: tokenInKey)

    let estimatedSwapPoolCap = (estimatedSwapOutStable > estimatedSwapOutV1) ? poolCapStable : poolCapV1
    
    let estimatedSwapOut = (estimatedSwapOutStable > estimatedSwapOutV1) ? estimatedSwapOutStable : estimatedSwapOutV1
    let estimatedStakeOut = LiquidStaking.calcStFlowFromFlow(flowAmount: amountIn)

    if tokenInKey == "A.1654653399040a61.FlowToken" && estimatedStakeOut > estimatedSwapOut {
      return <- LiquidStaking.stake(flowVault: <- (inVault as! @FlowToken.Vault))
    }

    return <- estimatedSwapPoolCap.swap(vaultIn: <- inVault, exactAmountOut: nil)
  }

  pub fun getNFTCatalogCollectionIdentifierFromCollectionIdentifier(collectionIdentifier: String): String {
    let nftTypeIdentifier: String = collectionIdentifier.slice(from: 0, upTo: collectionIdentifier.length - 10).concat("NFT")
    let collectionsForType: {String: Bool} = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftTypeIdentifier) ?? panic("This collection is not supported in the NFTCatalog.")
    let collectionIdentifier: String = collectionsForType.keys[0]
    return collectionIdentifier
  }
}