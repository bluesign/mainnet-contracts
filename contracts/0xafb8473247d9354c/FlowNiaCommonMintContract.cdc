import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"
import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"
import FlowNia from "./FlowNia.cdc"

pub contract FlowNiaCommonMintContract {
    pub let AdminStoragePath: StoragePath

    pub var whitelist: {Address: Bool}
    pub var extraFields: {String: AnyStruct}
    init() {
        self.whitelist = {}
        
        self.extraFields = {}
        
        self.AdminStoragePath = /storage/FlowNiaCommonMintContractAdmin

        self.account.save(<- create Administrator(), to: self.AdminStoragePath)
    }
    
    pub resource Administrator {
        pub fun setFields(fields:{String:AnyStruct}){
            for key in fields.keys {
                if(key == "whitelist"){
                    FlowNiaCommonMintContract.whitelist = fields[key] as! {Address: Bool}? ?? {}
                } else if(key == "whitelistToAdd"){
                    let whitelistToAdd = fields[key] as! {Address: Bool}? ?? {}
                    for k in whitelistToAdd.keys {
                      FlowNiaCommonMintContract.whitelist[k] = whitelistToAdd[k]!
                    }
                }
                else {
                    FlowNiaCommonMintContract.extraFields[key] = fields[key]
                }
            }
        }
    }
    
    pub fun paymentMint(
        recipient: &{NonFungibleToken.CollectionPublic}
    ){
        var opened = self.extraFields["opened"] as! Bool? ?? false
        var startTime = self.extraFields["startTime"] as! UFix64?
        var endTime = self.extraFields["endTime"] as! UFix64?
        var currentTokenId = UInt64(self.extraFields["currentTokenId"] as! Number? ?? 0)
        var maxTokenId = UInt64(self.extraFields["maxTokenId"] as! Number? ?? 0)

        if !opened {
            panic("sale closed")
        }
        if !(startTime == nil || startTime! <= getCurrentBlock().timestamp){
            panic("sale not started yet")
        }
        if !(endTime == nil || endTime! > getCurrentBlock().timestamp){
            panic("sale already ended")
        }
        if !(currentTokenId <= maxTokenId){
            panic("all minted")
        }
        
        if(self.whitelist[recipient.owner!.address] == nil){
            panic("address not in whitelist")
        }
        if(self.whitelist[recipient.owner!.address]!){
            panic("address in whitelist already used")
        }

        self.whitelist[recipient.owner!.address] = true

        let minter = self.account.borrow<&FlowNia.NFTMinter>(from: FlowNia.MinterStoragePath)!
        let metadata: {String:String} = {}

        if(currentTokenId == 0){
            currentTokenId = FlowNia.totalSupply
        }
        
        // metadata code here
        
        
        minter.mintNFT(id: currentTokenId, recipient: recipient, metadata: metadata)
        
        self.extraFields["currentTokenId"] = currentTokenId + 1
    }
}
