import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import FlowversePass from "./FlowversePass.cdc"

import FlowversePrimarySale from "./FlowversePrimarySale.cdc"

pub contract FlowversePassPrimarySaleMinter{ 
    pub resource Minter: FlowversePrimarySale.IMinter{ 
        priv let setMinter: @FlowversePass.SetMinter
        
        pub fun mint(entityID: UInt64, minterAddress: Address): @NonFungibleToken.NFT{ 
            return <-self.setMinter.mint(entityID: entityID, minterAddress: minterAddress)
        }
        
        init(setMinter: @FlowversePass.SetMinter){ 
            self.setMinter <- setMinter
        }
        
        destroy(){ 
            destroy self.setMinter
        }
    }
    
    pub fun createMinter(setMinter: @FlowversePass.SetMinter): @Minter{ 
        return <-create Minter(setMinter: <-setMinter)
    }
    
    pub fun getPrivatePath(setID: UInt64): PrivatePath{ 
        let pathIdentifier = "FlowversePassPrimarySaleMinter"
        return PrivatePath(identifier: pathIdentifier.concat(setID.toString()))!
    }
    
    pub fun getStoragePath(setID: UInt64): StoragePath{ 
        let pathIdentifier = "FlowversePassPrimarySaleMinter"
        return StoragePath(identifier: pathIdentifier.concat(setID.toString()))!
    }
}
