import SwapInterfaces from "../0xb78ef7afa52ff906/SwapInterfaces.cdc"
import FlowSwapPair from "../0xc6c77b9f5c7a378f/FlowSwapPair.cdc"
import IPierPair from "../0x609e10301860b683/IPierPair.cdc"
import PierPair from "../0x609e10301860b683/PierPair.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract Q {
    pub fun q(): [AnyStruct] {
        let pairInfoI_FLOWUSDC = getAccount(0xfa82796435e15832).getCapability<&{SwapInterfaces.PairPublic}>(/public/increment_swap_pair).borrow()!.getPairInfo()
        let poolInfoM_FLOWUSDC = getAccount(0x18187a9d276c0329).getCapability<&PierPair.Pool{IPierPair.IPool}>(/public/metapierSwapPoolPublic).borrow()!.getReserves()
        
        let flowBalance = getAccount(0x24263c125b7770e0).getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance).borrow()!.balance
        let usdcBalance = getAccount(0x24263c125b7770e0).getCapability<&{FungibleToken.Balance}>(/public/USDCVaultBalance).borrow()!.balance
        let usdtBalance = getAccount(0x24263c125b7770e0).getCapability<&{FungibleToken.Balance}>(/public/teleportedTetherTokenBalance).borrow()!.balance
        return [
            pairInfoI_FLOWUSDC[2],
            pairInfoI_FLOWUSDC[3],
            FlowSwapPair.getPoolAmounts().token1Amount,
            FlowSwapPair.getPoolAmounts().token2Amount,
            poolInfoM_FLOWUSDC[0],
            poolInfoM_FLOWUSDC[1],
            flowBalance,
            usdcBalance,
            usdtBalance
        ]
    }
    init() {
    }
}