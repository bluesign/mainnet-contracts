/*
    Flowmap is a consensus standard that allows anyone to claim ownership of a Flow Block.
    This is achieved through the Flowmap Inscription contract, where anyone can be the first to inscribe "blocknumber.flowmap" unto a cadence resource.
    Inspired by Bitmaps on Bitcoin Ordinals. Read whitepaper here: https://bitmap.land/bitbook
    Flowmap is intended solely for entertainment purposes. It should not be regarded as an investment or used with the expectation of financial returns. 
    Users are advised to engage with it purely for enjoyment and recreational value. 0% royalties.
*/

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import FungibleToken from "../0xf233dcee88fe0abe/FungibleToken.cdc"

import FlowToken from "../0x1654653399040a61/FlowToken.cdc"

pub contract Flowmap: NonFungibleToken{ 
    pub event ContractInitialized()
    
    pub event Withdraw(id: UInt64, from: Address?)
    
    pub event Deposit(id: UInt64, to: Address?)
    
    pub let CollectionStoragePath: StoragePath
    
    pub let CollectionPublicPath: PublicPath
    
    pub var totalSupply: UInt64
    
    pub let inscriptionFee: UFix64
    
    pub resource NFT: NonFungibleToken.INFT{ 
        pub let id: UInt64
        
        pub let inscription: String
        
        init(){ 
            self.id = Flowmap.totalSupply
            self.inscription = Flowmap.totalSupply.toString().concat(".flowmap")
            Flowmap.totalSupply = Flowmap.totalSupply + 1
        }
    }
    
    pub resource interface CollectionPublic{ 
        pub fun getIDs(): [UInt64]{} 
        
        pub fun deposit(token: @NonFungibleToken.NFT){} 
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{} 
        
        pub fun borrowFlowmap(id: UInt64): &Flowmap.NFT?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Flowmap reference: the ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic{ 
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        
        init(){ 
            self.ownedNFTs <-{} 
        }
        
        pub fun getIDs(): [UInt64]{ 
            return self.ownedNFTs.keys
        }
        
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT{ 
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing Flowmap")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT){ 
            let token <- token as! @Flowmap.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }
        
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT{ 
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }
        
        pub fun borrowFlowmap(id: UInt64): &Flowmap.NFT?{ 
            if self.ownedNFTs[id] != nil{ 
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Flowmap.NFT
            }
            return nil
        }
        
        destroy(){ 
            destroy self.ownedNFTs
        }
    }
    
    pub fun createEmptyCollection(): @NonFungibleToken.Collection{ 
        return <-create Collection()
    }
    
    pub fun inscribe(inscriptionFee: @FlowToken.Vault): @Flowmap.NFT{ 
        pre{ 
            Flowmap.totalSupply <= getCurrentBlock().height:
                "Cannot inscribe more than the current block height"
            inscriptionFee.balance >= Flowmap.inscriptionFee:
                "Insufficient inscription fee"
        }
        (Flowmap.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!).deposit(from: <-inscriptionFee)
        return <-create Flowmap.NFT()
    }
    
    pub fun batchInscribe(inscriptionFee: @FlowToken.Vault, quantity: UFix64, receiver: Address){ 
        pre{ 
            Flowmap.totalSupply <= getCurrentBlock().height:
                "Cannot inscribe more than the current block height"
            inscriptionFee.balance >= Flowmap.inscriptionFee * quantity:
                "Insufficient inscription fee"
        }
        (Flowmap.account.getCapability(/public/flowTokenReceiver).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!).deposit(from: <-inscriptionFee)
        let receiverRef = getAccount(receiver).getCapability(Flowmap.CollectionPublicPath).borrow<&{Flowmap.CollectionPublic}>() ?? panic("Could not borrow reference to the owner's Collection!")
        var i = 0
        while i < Int(quantity){ 
            receiverRef.deposit(token: <-create Flowmap.NFT())
            i = i + 1
        }
    }
    
    init(){ 
        self.totalSupply = 0
        self.inscriptionFee = 0.025
        self.CollectionStoragePath = /storage/flowmapCollection
        self.CollectionPublicPath = /public/flowmapCollection
        emit ContractInitialized()
    }
}
