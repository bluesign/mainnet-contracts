// You can create concrete poems with these alphabet resources.

import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

pub contract ConcreteAlphabetsFrench{ 
    pub resource U00C0{} // À 
    
    pub resource U00C2{} // Â 
    
    pub resource U00C6{} // Æ 
    
    pub resource U00C7{} // Ç 
    
    pub resource U00C8{} // È 
    
    pub resource U00C9{} // É 
    
    pub resource U00CA{} // Ê 
    
    pub resource U00CB{} // Ë 
    
    pub resource U00CE{} // Î 
    
    pub resource U00CF{} // Ï 
    
    pub resource U00D4{} // Ô 
    
    pub resource U00D9{} // Ù 
    
    pub resource U00DB{} // Û 
    
    pub resource U00DC{} // Ü 
    
    pub resource U00E0{} // à 
    
    pub resource U00E2{} // â 
    
    pub resource U00E6{} // æ 
    
    pub resource U00E7{} // ç 
    
    pub resource U00E8{} // è 
    
    pub resource U00E9{} // é 
    
    pub resource U00EA{} // ê 
    
    pub resource U00EB{} // ë 
    
    pub resource U00EE{} // î 
    
    pub resource U00EF{} // ï 
    
    pub resource U00F4{} // ô 
    
    pub resource U00F9{} // ù 
    
    pub resource U00FB{} // û 
    
    pub resource U00FC{} // ü 
    
    pub resource U00FF{} // ÿ 
    
    pub resource U0152{} // Œ 
    
    pub resource U0153{} // œ 
    
    pub resource U0178{} // Ÿ 
    
    pub resource U02B3{} // ʳ 
    
    pub resource U02E2{} // ˢ 
    
    pub resource U1D48{} // ᵈ 
    
    pub resource U1D49{} // ᵉ 
    
    pub fun newLetter(_ ch: Character): @AnyResource{ 
        switch ch.toString(){ 
            case "\u{c0}":
                return <-create U00C0()
            case "\u{c2}":
                return <-create U00C2()
            case "\u{c6}":
                return <-create U00C6()
            case "\u{c7}":
                return <-create U00C7()
            case "\u{c8}":
                return <-create U00C8()
            case "\u{c9}":
                return <-create U00C9()
            case "\u{ca}":
                return <-create U00CA()
            case "\u{cb}":
                return <-create U00CB()
            case "\u{ce}":
                return <-create U00CE()
            case "\u{cf}":
                return <-create U00CF()
            case "\u{d4}":
                return <-create U00D4()
            case "\u{d9}":
                return <-create U00D9()
            case "\u{db}":
                return <-create U00DB()
            case "\u{dc}":
                return <-create U00DC()
            case "\u{e0}":
                return <-create U00E0()
            case "\u{e2}":
                return <-create U00E2()
            case "\u{e6}":
                return <-create U00E6()
            case "\u{e7}":
                return <-create U00E7()
            case "\u{e8}":
                return <-create U00E8()
            case "\u{e9}":
                return <-create U00E9()
            case "\u{ea}":
                return <-create U00EA()
            case "\u{eb}":
                return <-create U00EB()
            case "\u{ee}":
                return <-create U00EE()
            case "\u{ef}":
                return <-create U00EF()
            case "\u{f4}":
                return <-create U00F4()
            case "\u{f9}":
                return <-create U00F9()
            case "\u{fb}":
                return <-create U00FB()
            case "\u{fc}":
                return <-create U00FC()
            case "\u{ff}":
                return <-create U00FF()
            case "\u{152}":
                return <-create U0152()
            case "\u{153}":
                return <-create U0153()
            case "\u{178}":
                return <-create U0178()
            case "\u{2b3}":
                return <-create U02B3()
            case "\u{2e2}":
                return <-create U02E2()
            case "\u{1d48}":
                return <-create U1D48()
            case "\u{1d49}":
                return <-create U1D49()
            default:
                return <-ConcreteAlphabets.newLetter(ch)
        }
    }
    
    pub fun newText(_ str: String): @[AnyResource]{ 
        var res: @[AnyResource] <- []
        for ch in str{ 
            res.append(<-ConcreteAlphabetsFrench.newLetter(ch))
        }
        return <-res
    }
    
    pub fun toCharacter(_ letter: &AnyResource): Character{ 
        switch letter.getType(){ 
            case Type<@U00C0>():
                return "\u{c0}"
            case Type<@U00C2>():
                return "\u{c2}"
            case Type<@U00C6>():
                return "\u{c6}"
            case Type<@U00C7>():
                return "\u{c7}"
            case Type<@U00C8>():
                return "\u{c8}"
            case Type<@U00C9>():
                return "\u{c9}"
            case Type<@U00CA>():
                return "\u{ca}"
            case Type<@U00CB>():
                return "\u{cb}"
            case Type<@U00CE>():
                return "\u{ce}"
            case Type<@U00CF>():
                return "\u{cf}"
            case Type<@U00D4>():
                return "\u{d4}"
            case Type<@U00D9>():
                return "\u{d9}"
            case Type<@U00DB>():
                return "\u{db}"
            case Type<@U00DC>():
                return "\u{dc}"
            case Type<@U00E0>():
                return "\u{e0}"
            case Type<@U00E2>():
                return "\u{e2}"
            case Type<@U00E6>():
                return "\u{e6}"
            case Type<@U00E7>():
                return "\u{e7}"
            case Type<@U00E8>():
                return "\u{e8}"
            case Type<@U00E9>():
                return "\u{e9}"
            case Type<@U00EA>():
                return "\u{ea}"
            case Type<@U00EB>():
                return "\u{eb}"
            case Type<@U00EE>():
                return "\u{ee}"
            case Type<@U00EF>():
                return "\u{ef}"
            case Type<@U00F4>():
                return "\u{f4}"
            case Type<@U00F9>():
                return "\u{f9}"
            case Type<@U00FB>():
                return "\u{fb}"
            case Type<@U00FC>():
                return "\u{fc}"
            case Type<@U00FF>():
                return "\u{ff}"
            case Type<@U0152>():
                return "\u{152}"
            case Type<@U0153>():
                return "\u{153}"
            case Type<@U0178>():
                return "\u{178}"
            case Type<@U02B3>():
                return "\u{2b3}"
            case Type<@U02E2>():
                return "\u{2e2}"
            case Type<@U1D48>():
                return "\u{1d48}"
            case Type<@U1D49>():
                return "\u{1d49}"
            default:
                return ConcreteAlphabets.toCharacter(letter)
        }
    }
    
    pub fun toString(_ text: &[AnyResource]): String{ 
        var res: String = ""
        var i = 0
        while i < text.length{ 
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabetsFrench.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
