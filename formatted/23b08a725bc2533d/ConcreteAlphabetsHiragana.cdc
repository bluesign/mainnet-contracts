// You can create concrete poems with these alphabet resources.

pub contract ConcreteAlphabetsHiragana{ 
    pub resource U3041{} // ぁ 
    
    pub resource U3042{} // あ 
    
    pub resource U3043{} // ぃ 
    
    pub resource U3044{} // い 
    
    pub resource U3045{} // ぅ 
    
    pub resource U3046{} // う 
    
    pub resource U3047{} // ぇ 
    
    pub resource U3048{} // え 
    
    pub resource U3049{} // ぉ 
    
    pub resource U304A{} // お 
    
    pub resource U304B{} // か 
    
    pub resource U304C{} // が 
    
    pub resource U304D{} // き 
    
    pub resource U304E{} // ぎ 
    
    pub resource U304F{} // く 
    
    pub resource U3050{} // ぐ 
    
    pub resource U3051{} // け 
    
    pub resource U3052{} // げ 
    
    pub resource U3053{} // こ 
    
    pub resource U3054{} // ご 
    
    pub resource U3055{} // さ 
    
    pub resource U3056{} // ざ 
    
    pub resource U3057{} // し 
    
    pub resource U3058{} // じ 
    
    pub resource U3059{} // す 
    
    pub resource U305A{} // ず 
    
    pub resource U305B{} // せ 
    
    pub resource U305C{} // ぜ 
    
    pub resource U305D{} // そ 
    
    pub resource U305E{} // ぞ 
    
    pub resource U305F{} // た 
    
    pub resource U3060{} // だ 
    
    pub resource U3061{} // ち 
    
    pub resource U3062{} // ぢ 
    
    pub resource U3063{} // っ 
    
    pub resource U3064{} // つ 
    
    pub resource U3065{} // づ 
    
    pub resource U3066{} // て 
    
    pub resource U3067{} // で 
    
    pub resource U3068{} // と 
    
    pub resource U3069{} // ど 
    
    pub resource U306A{} // な 
    
    pub resource U306B{} // に 
    
    pub resource U306C{} // ぬ 
    
    pub resource U306D{} // ね 
    
    pub resource U306E{} // の 
    
    pub resource U306F{} // は 
    
    pub resource U3070{} // ば 
    
    pub resource U3071{} // ぱ 
    
    pub resource U3072{} // ひ 
    
    pub resource U3073{} // び 
    
    pub resource U3074{} // ぴ 
    
    pub resource U3075{} // ふ 
    
    pub resource U3076{} // ぶ 
    
    pub resource U3077{} // ぷ 
    
    pub resource U3078{} // へ 
    
    pub resource U3079{} // べ 
    
    pub resource U307A{} // ぺ 
    
    pub resource U307B{} // ほ 
    
    pub resource U307C{} // ぼ 
    
    pub resource U307D{} // ぽ 
    
    pub resource U307E{} // ま 
    
    pub resource U307F{} // み 
    
    pub resource U3080{} // む 
    
    pub resource U3081{} // め 
    
    pub resource U3082{} // も 
    
    pub resource U3083{} // ゃ 
    
    pub resource U3084{} // や 
    
    pub resource U3085{} // ゅ 
    
    pub resource U3086{} // ゆ 
    
    pub resource U3087{} // ょ 
    
    pub resource U3088{} // よ 
    
    pub resource U3089{} // ら 
    
    pub resource U308A{} // り 
    
    pub resource U308B{} // る 
    
    pub resource U308C{} // れ 
    
    pub resource U308D{} // ろ 
    
    pub resource U308E{} // ゎ 
    
    pub resource U308F{} // わ 
    
    pub resource U3090{} // ゐ 
    
    pub resource U3091{} // ゑ 
    
    pub resource U3092{} // を 
    
    pub resource U3093{} // ん 
    
    pub resource U3094{} // ゔ 
    
    pub resource U3000{} // 　 (Idepgraphic Space) 
    
    pub fun newLetter(_ ch: Character): @AnyResource{ 
        switch ch{ 
            case "\u{3041}":
                return <-create U3041()
            case "\u{3042}":
                return <-create U3042()
            case "\u{3043}":
                return <-create U3043()
            case "\u{3044}":
                return <-create U3044()
            case "\u{3045}":
                return <-create U3045()
            case "\u{3046}":
                return <-create U3046()
            case "\u{3047}":
                return <-create U3047()
            case "\u{3048}":
                return <-create U3048()
            case "\u{3049}":
                return <-create U3049()
            case "\u{304a}":
                return <-create U304A()
            case "\u{304b}":
                return <-create U304B()
            case "\u{304c}":
                return <-create U304C()
            case "\u{304d}":
                return <-create U304D()
            case "\u{304e}":
                return <-create U304E()
            case "\u{304f}":
                return <-create U304F()
            case "\u{3050}":
                return <-create U3050()
            case "\u{3051}":
                return <-create U3051()
            case "\u{3052}":
                return <-create U3052()
            case "\u{3053}":
                return <-create U3053()
            case "\u{3054}":
                return <-create U3054()
            case "\u{3055}":
                return <-create U3055()
            case "\u{3056}":
                return <-create U3056()
            case "\u{3057}":
                return <-create U3057()
            case "\u{3058}":
                return <-create U3058()
            case "\u{3059}":
                return <-create U3059()
            case "\u{305a}":
                return <-create U305A()
            case "\u{305b}":
                return <-create U305B()
            case "\u{305c}":
                return <-create U305C()
            case "\u{305d}":
                return <-create U305D()
            case "\u{305e}":
                return <-create U305E()
            case "\u{305f}":
                return <-create U305F()
            case "\u{3060}":
                return <-create U3060()
            case "\u{3061}":
                return <-create U3061()
            case "\u{3062}":
                return <-create U3062()
            case "\u{3063}":
                return <-create U3063()
            case "\u{3064}":
                return <-create U3064()
            case "\u{3065}":
                return <-create U3065()
            case "\u{3066}":
                return <-create U3066()
            case "\u{3067}":
                return <-create U3067()
            case "\u{3068}":
                return <-create U3068()
            case "\u{3069}":
                return <-create U3069()
            case "\u{306a}":
                return <-create U306A()
            case "\u{306b}":
                return <-create U306B()
            case "\u{306c}":
                return <-create U306C()
            case "\u{306d}":
                return <-create U306D()
            case "\u{306e}":
                return <-create U306E()
            case "\u{306f}":
                return <-create U306F()
            case "\u{3070}":
                return <-create U3070()
            case "\u{3071}":
                return <-create U3071()
            case "\u{3072}":
                return <-create U3072()
            case "\u{3073}":
                return <-create U3073()
            case "\u{3074}":
                return <-create U3074()
            case "\u{3075}":
                return <-create U3075()
            case "\u{3076}":
                return <-create U3076()
            case "\u{3077}":
                return <-create U3077()
            case "\u{3078}":
                return <-create U3078()
            case "\u{3079}":
                return <-create U3079()
            case "\u{307a}":
                return <-create U307A()
            case "\u{307b}":
                return <-create U307B()
            case "\u{307c}":
                return <-create U307C()
            case "\u{307d}":
                return <-create U307D()
            case "\u{307e}":
                return <-create U307E()
            case "\u{307f}":
                return <-create U307F()
            case "\u{3080}":
                return <-create U3080()
            case "\u{3081}":
                return <-create U3081()
            case "\u{3082}":
                return <-create U3082()
            case "\u{3083}":
                return <-create U3083()
            case "\u{3084}":
                return <-create U3084()
            case "\u{3085}":
                return <-create U3085()
            case "\u{3086}":
                return <-create U3086()
            case "\u{3087}":
                return <-create U3087()
            case "\u{3088}":
                return <-create U3088()
            case "\u{3089}":
                return <-create U3089()
            case "\u{308a}":
                return <-create U308A()
            case "\u{308b}":
                return <-create U308B()
            case "\u{308c}":
                return <-create U308C()
            case "\u{308d}":
                return <-create U308D()
            case "\u{308e}":
                return <-create U308E()
            case "\u{308f}":
                return <-create U308F()
            case "\u{3090}":
                return <-create U3090()
            case "\u{3091}":
                return <-create U3091()
            case "\u{3092}":
                return <-create U3092()
            case "\u{3093}":
                return <-create U3093()
            case "\u{3094}":
                return <-create U3094()
            default:
                return <-create U3000()
        }
    }
    
    pub fun newText(_ str: String): @[AnyResource]{ 
        var res: @[AnyResource] <- []
        for ch in str{ 
            res.append(<-ConcreteAlphabetsHiragana.newLetter(ch))
        }
        return <-res
    }
    
    pub fun toCharacter(_ letter: &AnyResource): Character{ 
        switch letter.getType(){ 
            case Type<@U3041>():
                return "\u{3041}"
            case Type<@U3042>():
                return "\u{3042}"
            case Type<@U3043>():
                return "\u{3043}"
            case Type<@U3044>():
                return "\u{3044}"
            case Type<@U3045>():
                return "\u{3045}"
            case Type<@U3046>():
                return "\u{3046}"
            case Type<@U3047>():
                return "\u{3047}"
            case Type<@U3048>():
                return "\u{3048}"
            case Type<@U3049>():
                return "\u{3049}"
            case Type<@U304A>():
                return "\u{304a}"
            case Type<@U304B>():
                return "\u{304b}"
            case Type<@U304C>():
                return "\u{304c}"
            case Type<@U304D>():
                return "\u{304d}"
            case Type<@U304E>():
                return "\u{304e}"
            case Type<@U304F>():
                return "\u{304f}"
            case Type<@U3050>():
                return "\u{3050}"
            case Type<@U3051>():
                return "\u{3051}"
            case Type<@U3052>():
                return "\u{3052}"
            case Type<@U3053>():
                return "\u{3053}"
            case Type<@U3054>():
                return "\u{3054}"
            case Type<@U3055>():
                return "\u{3055}"
            case Type<@U3056>():
                return "\u{3056}"
            case Type<@U3057>():
                return "\u{3057}"
            case Type<@U3058>():
                return "\u{3058}"
            case Type<@U3059>():
                return "\u{3059}"
            case Type<@U305A>():
                return "\u{305a}"
            case Type<@U305B>():
                return "\u{305b}"
            case Type<@U305C>():
                return "\u{305c}"
            case Type<@U305D>():
                return "\u{305d}"
            case Type<@U305E>():
                return "\u{305e}"
            case Type<@U305F>():
                return "\u{305f}"
            case Type<@U3060>():
                return "\u{3060}"
            case Type<@U3061>():
                return "\u{3061}"
            case Type<@U3062>():
                return "\u{3062}"
            case Type<@U3063>():
                return "\u{3063}"
            case Type<@U3064>():
                return "\u{3064}"
            case Type<@U3065>():
                return "\u{3065}"
            case Type<@U3066>():
                return "\u{3066}"
            case Type<@U3067>():
                return "\u{3067}"
            case Type<@U3068>():
                return "\u{3068}"
            case Type<@U3069>():
                return "\u{3069}"
            case Type<@U306A>():
                return "\u{306a}"
            case Type<@U306B>():
                return "\u{306b}"
            case Type<@U306C>():
                return "\u{306c}"
            case Type<@U306D>():
                return "\u{306d}"
            case Type<@U306E>():
                return "\u{306e}"
            case Type<@U306F>():
                return "\u{306f}"
            case Type<@U3070>():
                return "\u{3070}"
            case Type<@U3071>():
                return "\u{3071}"
            case Type<@U3072>():
                return "\u{3072}"
            case Type<@U3073>():
                return "\u{3073}"
            case Type<@U3074>():
                return "\u{3074}"
            case Type<@U3075>():
                return "\u{3075}"
            case Type<@U3076>():
                return "\u{3076}"
            case Type<@U3077>():
                return "\u{3077}"
            case Type<@U3078>():
                return "\u{3078}"
            case Type<@U3079>():
                return "\u{3079}"
            case Type<@U307A>():
                return "\u{307a}"
            case Type<@U307B>():
                return "\u{307b}"
            case Type<@U307C>():
                return "\u{307c}"
            case Type<@U307D>():
                return "\u{307d}"
            case Type<@U307E>():
                return "\u{307e}"
            case Type<@U307F>():
                return "\u{307f}"
            case Type<@U3080>():
                return "\u{3080}"
            case Type<@U3081>():
                return "\u{3081}"
            case Type<@U3082>():
                return "\u{3082}"
            case Type<@U3083>():
                return "\u{3083}"
            case Type<@U3084>():
                return "\u{3084}"
            case Type<@U3085>():
                return "\u{3085}"
            case Type<@U3086>():
                return "\u{3086}"
            case Type<@U3087>():
                return "\u{3087}"
            case Type<@U3088>():
                return "\u{3088}"
            case Type<@U3089>():
                return "\u{3089}"
            case Type<@U308A>():
                return "\u{308a}"
            case Type<@U308B>():
                return "\u{308b}"
            case Type<@U308C>():
                return "\u{308c}"
            case Type<@U308D>():
                return "\u{308d}"
            case Type<@U308E>():
                return "\u{308e}"
            case Type<@U308F>():
                return "\u{308f}"
            case Type<@U3090>():
                return "\u{3090}"
            case Type<@U3091>():
                return "\u{3091}"
            case Type<@U3092>():
                return "\u{3092}"
            case Type<@U3093>():
                return "\u{3093}"
            case Type<@U3094>():
                return "\u{3094}"
            case Type<@U3000>():
                return "\u{3000}"
            default:
                return "?"
        }
    }
    
    pub fun toString(_ text: &[AnyResource]): String{ 
        var res: String = ""
        var i = 0
        while i < text.length{ 
            let letter = &text[i] as &AnyResource
            res = res.concat(ConcreteAlphabetsHiragana.toCharacter(letter).toString())
            i = i + 1
        }
        return res
    }
}
