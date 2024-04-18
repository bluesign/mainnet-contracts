import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import SNKRHUDNFT from "../0x80af1db15aa6535a/SNKRHUDNFT.cdc"

pub contract SNKRHUDNFTPrimarySaleMinter{ 
    pub resource Minter: GaiaPrimarySale.IMinter{ 
        priv let setMinter: @SNKRHUDNFT.SetMinter
        
        pub fun mint(assetID: UInt64, creator: Address): @NonFungibleToken.NFT{ 
            return <-self.setMinter.mint(templateID: assetID, creator: creator)
        }
        
        init(setMinter: @SNKRHUDNFT.SetMinter){ 
            self.setMinter <- setMinter
        }
        
        destroy(){ 
            destroy self.setMinter
        }
    }
    
    pub fun createMinter(setMinter: @SNKRHUDNFT.SetMinter): @Minter{ 
        return <-create Minter(setMinter: <-setMinter)
    }
}
