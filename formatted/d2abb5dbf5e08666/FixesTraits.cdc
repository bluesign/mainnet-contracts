/**
> Author: FIXeS World <https://fixes.world/>

# FixesTraits

TODO: Add description

*/


// Thirdparty Imports
import MetadataViews from "../0x1d7e57aa55817448/MetadataViews.cdc"

/// The `FixesTraits` contract
///
pub contract FixesTraits{ 
    pub        
        /// =============  Trait: Season 0 - Secret Garden =============
        
        
        /// The Definition of the Marketplace Season 0
        enum Season0SecretPlaces: UInt8{ 
        pub case HeartOfTheAzureOcean
        
        pub // 蔚蓝海洋之心 case HeartOfTheDarkForest
        
        pub case // 黑暗森林之心 GardenofVenus
        
        pub case CityOfTheDead // 维纳斯的花园
        
        pub case DragonboneWasteland
        
        pub // 亡者之城 case MysticForest
        
        pub case // 龙骨荒原 SoulWaterfall
        
        pub case AbyssalHollow // 神秘森林
        
        pub case SilentGlacier
        
        pub // 灵魂瀑布 case FrostWasteland
        
        pub case // 深渊之穴 DesolateGround
        
        pub case MirageCity // 静寂冰川
        
        pub case ScorpionGorge
        
        pub // 霜冻荒原 case MysteriousIceLake
        
        pub case // 荒芜之地 NightShadowForest
        
        pub case SpiritualValley // 海市蜃楼
        
        pub case RavensPerch
        
        pub // 蛇蝎峡谷 case RainbowFalls
        
        pub case // 神秘冰湖 TwilightValley
        
        pub case RuggedHill // 夜影密林 // 灵犀山谷 // 乌鸦栖息地 // 彩虹瀑布 // 暮色谷地 // 乱石山岗
    }
    
    pub fun getSeason0SecretPlacesDefs(): [Definition]{ 
        return [Definition(5, 100), // 1% chance, rarity 2 Definition(12, 1900), // 19% chance, rarity 1 Definition(20, 8000)] // 80% chance, rarity 0
    }
    
    /// =============  Trait: Season 0 - Ability =============
    
    /// The Definition of the Marketplace Season 0
    ///
    pub enum Season0Ability: UInt8{ 
        pub case Omniscience
        
        pub // 全知全能 case ElementalMastery
        
        pub case // 全元素掌控 TimeStand
        
        pub case MillenniumFreeze // 时间静止
        
        pub case FossilResurgence
        
        pub // 千年冰封 case MysticVision
        
        pub case // 化石重生 PhoenixRebirth
        
        pub case SoulBind // 神秘视界
        
        pub case PrayerOfLight
        
        pub // 凤凰复生 case Starfall
        
        pub case // 灵魂束缚 DragonsBreath
        
        pub case PsychicSense // 光明祈祷
        
        pub case MindControl
        
        pub // 星辰坠落 case EndlessTorment
        
        pub case // 龙焰吐息 MeditationInDespair
        
        pub case SilenceFear // 心灵感应
        
        pub case GloryChallenge
        
        pub // 心灵控制 case ShieldWall
        
        pub case // 无尽痛苦 TidalCall
        
        pub case FountainOfLife // 绝境冥思
        
        pub case PsychicInteraction
        
        pub // 沉默恐惧 case PlagueTransmission
        
        pub case // 荣耀挑战 NinjaStealth
        
        pub case BattleRoar // 防御罩墙
        
        pub case CongestiveStrike
        
        pub // 海潮呼唤 case HolyGuidance
        
        pub case // 生命之泉 EmpoweredBarrier
        
        pub case PerpetualLife // 精神互动
        
        pub case CombatEvade
        
        pub // 疫病传染 case AbyssArrow
        
        pub case // 忍者潜行 SoulEcho
        
        pub case ArcaneBlink // 战斗吼叫
        
        pub case ArcaneExplosion
        
        pub // 充血打击 case ShadowStep
        
        pub case // 圣光指引 JadeStoneSpell
        
        pub case PhantomDodge // 强化结界
        
        pub case KissOfDeath
        
        pub // 生生不息 case PhantomSummoning
        
        pub case // 战斗闪避 EyeOfTheRaven
        
        pub case RatSwarmSurge // 深渊之箭
        
        pub case FlameShock
        
        pub // 灵魂回响 case GaleSpeedBlade
        
        pub case // 魔力闪现 InterstellarFlight
        
        pub case WraithSeal // 魔力爆炸
        
        pub case DivineRestoration
        
        pub // 暗黑影步 case LifePull
        
        pub case // 玉石咒语 RapidFire
        
        pub case MightyBlow // 鬼魅闪避
        
        pub case PhysicalTraining // 死亡之吻 // 幻影召唤 // 乌鸦之眼 // 鼠群涌动 // 烈焰冲击 // 疾风快剑 // 星界飞行 // 怨灵封印 // 神力恢复 // 生命拉扯 // 快速射击 // 强力打击 // 锻炼体魄
    }
    
    pub fun getSeason0AbilityDefs(): [Definition]{ 
        return [
            Definition(5, 20), // 0.2% chance, rarity 3
            Definition(12, 100), // 1% chance, rarity 2
            Definition(25, 1880), // 18.8% chance, rarity 1
            Definition(49, 8000)
        ] // 80% chance, rarity 0
    }
    
    /// =============  Trait: Season 0 - Weapons =============
    
    pub enum Season0Weapons: UInt8{ 
        pub case Starstaff
        
        pub // 星辰法杖 case BowOfTheMysteriousBird
        
        pub case // 九天玄鸟之弓 VoidSpiritWand
        
        pub case GodlyWand // 虚空灵杖
        
        pub case SunriseHolySword
        
        pub // 神祇法杖 case DeepSeaTrident
        
        pub case // 旭日圣剑 DragonboneBow
        
        pub case RainbowHolySword // 深海三叉戟
        
        pub case MysticalGrimoire
        
        pub // 龙骨弓 case SaintsStaff
        
        pub case // 虹光圣剑 FirePhoenixWhip
        
        pub case SoulOrb // 神秘法书
        
        pub case LightningSpear
        
        pub // 圣者圣杖 case DarkScepter
        
        pub case // 火凤长鞭 DawnLance
        
        pub case RedLotusRocket // 灵魂法球
        
        pub case DemonBoneSpike
        
        pub // 闪电长矛 case EvilStarCatapult
        
        pub case // 黑暗权杖 SwordOfTenderness
        
        pub case WindWarriorLongbow // 破晓长枪
        
        pub case NightDagger
        
        pub // 红莲火箭 case GalaxyHalberd
        
        pub case // 恶魔骨刺 MoonshadowScimitar
        
        pub case IceCrownDagger // 魔星投石器
        
        pub case StormBattleAxe
        
        pub // 温柔之剑 case ArcaneStaff
        
        pub case // 风战者长弓 AxeOfInferno
        
        pub case SkybreakerDualBlade // 黑夜匕首
        
        pub case IceGiantSword
        
        pub // 银河双戟 case TrollsHammer // 影月弯刀 // 冰冠短剑 // 风暴战斧 // 奥术长杖 // 烈火之斧 // 破空双刃 // 寒冰巨剑 // 巨魔之锤
    }
    
    pub fun getSeason0WeaponsDefs(): [Definition]{ 
        return [
            Definition(5, 20), // 0.2% chance, rarity 3
            Definition(12, 100), // 1% chance, rarity 2
            Definition(20, 1880), // 18.8% chance, rarity 1
            Definition(30, 8000)
        ] // 80% chance, rarity 0
    }
    
    access(account) fun attemptToGenerateRandomEntryForSeason0(): @Entry?{ 
        let randForType = revertibleRandom()
        // 5% for secret places, 10% for ability, 15% for weapons, 70% for nothing
        let randForTypePercent = UInt8(randForType % 100)
        if randForTypePercent >= 30{ 
            return nil
        }
        var type: Type? = nil
        if randForTypePercent < 5{ 
            type = Type<Season0SecretPlaces>()
        } else if randForTypePercent < 15{ 
            type = Type<Season0Ability>()
        } else{ 
            type = Type<Season0Weapons>()
        }
        return <-self.generateRandomEntry(type!)
    }
    
    /**
            ------------------------ Public Methods ------------------------
        */
    
    /// Get the rarity definition array for a given series
    /// The higher the rarity in front.
    ///
    pub fun getRarityDefinition(_ series: Type): [Definition]?{ 
        switch series{ 
            case Type<Season0SecretPlaces>():
                return self.getSeason0SecretPlacesDefs()
            case Type<Season0Ability>():
                return self.getSeason0AbilityDefs()
            case Type<Season0Weapons>():
                return self.getSeason0WeaponsDefs()
        }
        return nil
    }
    
    /// Get the maximum rarity for a given series
    ///
    pub fun getMaxRarity(_ series: Type): UInt8{ 
        if let arr = self.getRarityDefinition(series){ 
            return UInt8(arr.length - 1)
        }
        return UInt8.max
    }
    
    /**
            ------------------------ Genreal Interfaces & Resources ------------------------
        */
    
    /// The Entry Definition
    ///
    pub struct Definition{ 
        pub let threshold: UInt8 // max value for this rarity, not included
        
        pub let weight: UInt64 // weight of this rarity
        
        init(_ threshold: UInt8, _ weight: UInt64){ 
            self.threshold = threshold
            self.weight = weight
        }
    }
    
    /// The TraitWithOffset Definition
    ///
    pub struct TraitWithOffset{ 
        pub            // Series is the identifier of the series enum
            let series: Type
        
        // Value is the value of the trait, as the rawValue of the enum
        pub let value: UInt8
        
        // Rarity is the rarity of the trait, from 0 to maxRarity
        pub let rarity: UInt8
        
        // Offset is random between -20 and 20, to be used for rarity extension
        pub let offset: Int8
        
        init(series: Type, value: UInt8, rarity: UInt8){ 
            self.series = series
            self.value = value
            self.rarity = rarity
            // Offset is random between -20 and 20
            let rand = revertibleRandom()
            self.offset = Int8(rand % 40) - 20
        }
    }
    
    /// The `Entry` resource
    ///
    pub resource Entry: MetadataViews.Resolver{ 
        priv let trait: TraitWithOffset
        
        init(series: Type, value: UInt8, rarity: UInt8){ 
            self.trait = TraitWithOffset(series: series, value: value, rarity: rarity)
        }
        
        /// Get the trait
        ///
        pub fun getTrait(): TraitWithOffset{ 
            return self.trait
        }
        
        // ---- implement Resolver ----
        
        /// Function that returns all the Metadata Views available for this profile
        ///
        pub fun getViews(): [Type]{ 
            return [Type<TraitWithOffset>(), Type<MetadataViews.Trait>()]
        }
        
        /// Function that resolves a metadata view for this profile
        ///
        pub fun resolveView(_ view: Type): AnyStruct?{ 
            switch view{ 
                case Type<TraitWithOffset>():
                    return self.trait
                case Type<MetadataViews.Trait>():
                    return MetadataViews.Trait(name: self.trait.series.identifier, value: self.trait.value, displayType: "number", rarity: MetadataViews.Rarity(score: UFix64(self.trait.rarity), max: UFix64(FixesTraits.getMaxRarity(self.trait.series)), description: nil))
            }
            return nil
        }
    }
    
    /// Create a new entry
    ///
    access(account) fun createEntry(
        _ series: Type,
        _ value: UInt8,
        _ rarity: UInt8
    ): @Entry{ 
        return <-create Entry(series: series, value: value, rarity: rarity)
    }
    
    /// Generate a random entry
    ///
    access(account) fun generateRandomEntry(_ series: Type): @Entry?{ 
        let defs = self.getRarityDefinition(series)
        if defs == nil{ 
            return nil // DO NOT PANIC
        }
        
        // generate a random number for the entry
        let randForEntry = revertibleRandom() % 10000
        // calculate the rarity
        var totalWeight: UInt64 = 0
        var lastThreshold: UInt8 = 0
        var currentThreshold: UInt8 = 0
        let maxRarity = UInt8((defs!).length - 1)
        var currentRarity: UInt8 = 0
        // find the right rarity
        for i, def in defs!{ 
            totalWeight = totalWeight + def.weight
            if randForEntry < totalWeight{ 
                currentThreshold = def.threshold
                currentRarity = maxRarity - UInt8(i)
                break
            }
            lastThreshold = def.threshold
        }
        // create the entry
        return <-self.createEntry(
            series,
            // calculate the value
            lastThreshold
            + UInt8(randForEntry % 255) % (currentThreshold - lastThreshold),
            currentRarity
        )
    }
}
