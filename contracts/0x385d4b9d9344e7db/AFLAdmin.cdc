import AFLNFT from "./AFLNFT.cdc"
import AFLPack from "./AFLPack.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
pub contract AFLAdmin {

    // Admin
    // the admin resource is defined so that only the admin account
    // can have this resource. It possesses the ability to open packs
    // given a user's Pack Collection and Card Collection reference.
    // It can also create a new pack type and mint Packs.
    //
    pub resource Admin {

        pub fun createTemplate(maxSupply:UInt64, immutableData:{String: AnyStruct}){
            AFLNFT.createTemplate(maxSupply:maxSupply, immutableData:immutableData)
        }

        pub fun openPack(templateId: UInt64, account: Address){
            AFLNFT.mintNFT(templateId:templateId, account:account)
        }
        // createAdmin
        // only an admin can ever create
        // a new Admin resource
        //
        pub fun createAdmin(): @Admin {
            return <- create Admin()
        }

        init() {
            
        }
    }

    init() {
        self.account.save(<- create Admin(), to: /storage/AFLAdmin)
    }
}