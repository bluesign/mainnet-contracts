import NFTStorefrontV2 from "../0x3cdbb3d569211ff3/NFTStorefrontV2.cdc"

pub contract FlowtyStorefront{ 
    pub fun getStorefrontRef(owner: Address): &NFTStorefrontV2.Storefront{
        NFTStorefrontV2.StorefrontPublic
    }{ 
        return getAccount(owner).getCapability<
            &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}
        >(NFTStorefrontV2.StorefrontPublicPath).borrow()
        ?? panic("Could not borrow public storefront from address")
    }
    
    pub fun getStorefrontRefSafe(owner: Address): &NFTStorefrontV2.Storefront{
        NFTStorefrontV2.StorefrontPublic
    }?{ 
        return getAccount(owner).getCapability<
            &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}
        >(NFTStorefrontV2.StorefrontPublicPath).borrow()
    }
}
