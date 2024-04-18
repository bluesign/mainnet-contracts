import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import GaiaPrimarySale from "../0x01ddf82c652e36ef/GaiaPrimarySale.cdc"

import SadboiNFT from "../0xd714ab2d9943c4a5/SadboiNFT.cdc"

pub contract SadboiNFTPrimarySaleMinter{ 
    pub resource Minter: GaiaPrimarySale.IMinter{ 
        priv let setMinter: @SadboiNFT.SetMinter
        
        pub fun mint(assetID: UInt64, creator: Address): @NonFungibleToken.NFT{ 
            return <-self.setMinter.mint(templateID: assetID, creator: creator)
        }
        
        init(setMinter: @SadboiNFT.SetMinter){ 
            self.setMinter <- setMinter
        }
        
        destroy(){ 
            destroy self.setMinter
        }
    }
    
    pub fun createMinter(setMinter: @SadboiNFT.SetMinter): @Minter{ 
        return <-create Minter(setMinter: <-setMinter)
    }
}
