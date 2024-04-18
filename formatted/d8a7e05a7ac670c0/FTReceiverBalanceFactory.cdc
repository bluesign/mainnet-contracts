import CapabilityFactory from "./CapabilityFactory.cdc"

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

pub contract FTReceiverBalanceFactory{ 
    pub struct Factory: CapabilityFactory.Factory{ 
        pub fun getCapability(acct: &AuthAccount, path: CapabilityPath): Capability{ 
            return acct.getCapability<&{FungibleToken.Receiver, FungibleToken.Balance}>(path)
        }
    }
}
