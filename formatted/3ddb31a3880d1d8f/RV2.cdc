/**

# 

*/

import LendingInterfaces from "../0x2df970b6cdee5735/LendingInterfaces.cdc"

pub contract RV2{ 
    
    // {Referrer : {Referee: BindingTime} }
    priv let _referrerToReferees:{ Address:{ Address: UFix64}}
    
    // {Referee: Referrer}
    priv let _refereeToReferrer:{ Address: Address}
    
    /// Events
    pub event BindingReferrer(referrer: Address, referee: Address, indexer: Int)
    
    pub fun bind(
        referrer: Address,
        refereeCertificateCap: Capability<
            &{LendingInterfaces.IdentityCertificate}
        >
    ){ 
        let referee: Address =
            ((refereeCertificateCap.borrow()!).owner!).address
        assert(
            self._refereeToReferrer.containsKey(referee) == false,
            message: "Referrer already bound"
        )
        assert(referee != referrer, message: "Can't bind yourself")
        self._refereeToReferrer[referee] = referrer
        if self._referrerToReferees.containsKey(referrer) == false{ 
            self._referrerToReferees[referrer] ={} 
        }
        (self._referrerToReferees[referrer]!).insert(
            key: referee,
            getCurrentBlock().timestamp
        )
        
        // Prevent circular binding
        //assert(self.checkCirularBinding(referee: referee) == false, message: "Cirular Binding")
        
        emit BindingReferrer(
            referrer: referrer,
            referee: referee,
            indexer: (self._referrerToReferees[referrer]!).length
        )
    }
    
    priv fun checkCirularBinding(referee: Address): Bool{ 
        let checkedAddrs:{ Address: Bool} ={ referee: true}
        var i = 0
        var addr = referee
        while i < 32{ 
            if self._refereeToReferrer.containsKey(addr) == false{ 
                return false
            }
            let nextAddr = self._refereeToReferrer[addr]!
            if checkedAddrs.containsKey(nextAddr) == true{ 
                return true
            }
            checkedAddrs[nextAddr] = true
            addr = nextAddr
            i = i + 1
        }
        return false
    }
    
    pub fun getReferrerByReferee(referee: Address): Address?{ 
        if self._refereeToReferrer.containsKey(referee) == false{ 
            return nil
        }
        return self._refereeToReferrer[referee]!
    }
    
    pub fun getReferrerCount(): Int{ 
        return self._referrerToReferees.length
    }
    
    pub fun getSlicedReferrerList(from: Int, to: Int): [Address]{ 
        let len = self._referrerToReferees.length
        let upTo = to > len ? len : to
        return self._referrerToReferees.keys.slice(from: from, upTo: upTo)
    }
    
    pub fun getRefereeCountByReferrer(referrer: Address): Int{ 
        return self._referrerToReferees.containsKey(referrer)
            ? (self._referrerToReferees[referrer]!).length
            : 0
    }
    
    pub fun getSlicedRefereesByReferrer(
        referrer: Address,
        from: Int,
        to: Int
    ):{ 
        Address: UFix64
    }{ 
        if self._referrerToReferees.containsKey(referrer) == false{ 
            return{} 
        }
        let len = (self._referrerToReferees[referrer]!).length
        let endIndex = to > len ? len : to
        var curIndex = from
        let res:{ Address: UFix64} ={} 
        while curIndex < endIndex{ 
            let key: Address = (self._referrerToReferees[referrer]!).keys[curIndex]
            res[key] = (self._referrerToReferees[referrer]!)[key]
            curIndex = curIndex + 1
        }
        return res
    }
    
    /// Admin
    ///
    pub resource Admin{} 
    
    init(){ 
        self._referrerToReferees ={} 
        self._refereeToReferrer ={} 
    }
}
