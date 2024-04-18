// You can create concrete poems with these alphabet resources.

import ConcreteAlphabets from "./ConcreteAlphabets.cdc"

pub contract ConcreteAlphabetsSpanish{ 
    pub resource U00C1{} // Á 
    
    pub resource U00C9{} // É 
    
    pub resource U00CD{} // Í 
    
    pub resource U00D3{} // Ó 
    
    pub resource U00DA{} // Ú 
    
    pub resource U00DC{} // Ü 
    
    pub resource U00D1{} // Ñ 
    
    pub resource U00E1{} // á 
    
    pub resource U00E9{} // é 
    
    pub resource U00ED{} // í 
    
    pub resource U00F3{} // ó 
    
    pub resource U00FA{} // ú 
    
    pub resource U00FC{} // ü 
    
    pub resource U00F1{} // ñ 
    
    pub resource U00AA{} // ª 
    
    pub resource U00BA{} // º 
    
    pub resource U00A1{} // ¡ 
    
    pub resource U00BF{} // ¿ 
    
    pub fun newLetter(_ ch: Character): @AnyResource{ 
        switch ch.toString(){ 
            case "\u{c1}":
                return <-create U00C1()
            case "\u{c9}":
                return <-create U00C9()
            case "\u{cd}":
                return <-create U00CD()
            case "\u{d3}":
                return <-create U00D3()
            case "\u{da}":
                return <-create U00DA()
            case "\u{dc}":
                return <-create U00DC()
            case "\u{d1}":
                return <-create U00D1()
            case "\u{e1}":
                return <-create U00E1()
            case "\u{e9}":
                return <-create U00E9()
            case "\u{ed}":
                return <-create U00ED()
            case "\u{f3}":
                return <-create U00F3()
            case "\u{fa}":
                return <-create U00FA()
            case "\u{fc}":
                return <-create U00FC()
            case "\u{f1}":
                return <-create U00F1()
            case "\u{aa}":
                return <-create U00AA()
            case "\u{ba}":
                return <-create U00BA()
            case "\u{a1}":
                return <-create U00A1()
            case "\u{bf}":
                return <-create U00BF()
            default:
                return <-ConcreteAlphabets.newLetter(ch)
        }
    }
    
    pub fun newText(_ str: String): @[AnyResource]{ 
        var res: @[AnyResource] <- []
        for ch in str{ 
            res.append(<-ConcreteAlphabetsSpanish.newLetter(ch))
        }
        return <-res
    }
    
    pub fun toCharacter(_ letter: &AnyResource): Character{ 
        switch letter.getType(){ 
            case Type<@U00C1>():
                return "\u{c1}"
            case Type<@U00C9>():
                return "\u{c9}"
            case Type<@U00CD>():
                return "\u{cd}"
            case Type<@U00D3>():
                return "\u{d3}"
            case Type<@U00DA>():
                return "\u{da}"
            case Type<@U00DC>():
                return "\u{dc}"
            case Type<@U00D1>():
                return "\u{d1}"
            case Type<@U00E1>():
                return "\u{e1}"
            case Type<@U00E9>():
                return "\u{e9}"
            case Type<@U00ED>():
                return "\u{ed}"
            case Type<@U00F3>():
                return "\u{f3}"
            case Type<@U00FA>():
                return "\u{fa}"
            case Type<@U00FC>():
                return "\u{fc}"
            case Type<@U00F1>():
                return "\u{f1}"
            case Type<@U00AA>():
                return "\u{aa}"
            case Type<@U00BA>():
                return "\u{ba}"
            case Type<@U00A1>():
                return "\u{a1}"
            case Type<@U00BF>():
                return "\u{bf}"
            default:
                return ConcreteAlphabets.toCharacter(letter)
        }
    }
    
    pub fun toString(_ text: &[AnyResource]): String{ 
        var res: String = ""
        var i = 0
        while i < text.length{ 
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabetsSpanish.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
