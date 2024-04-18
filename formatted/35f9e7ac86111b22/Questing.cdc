import QuestReward from "./QuestReward.cdc"

import NonFungibleToken from "../0x1d7e57aa55817448/NonFungibleToken.cdc"

import RewardAlgorithm from "./RewardAlgorithm.cdc"

pub contract Questing{ 
    pub        
        // -----------------------------------------------------------------------
        // Events
        // -----------------------------------------------------------------------
        event ContractInitialized()
    
    pub event QuestStarted(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        quester: Address
    )
    
    pub event QuestEnded(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        quester: Address?
    )
    
    pub event RewardAdded(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        rewardID: UInt64,
        rewardTemplateID: UInt32,
        rewardTemplate: QuestReward.RewardTemplate
    )
    
    pub event RewardBurned(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        rewardID: UInt64,
        rewardTemplateID: UInt32,
        minterID: UInt64
    )
    
    pub event RewardMoved(
        questID: UInt64,
        typeIdentifier: String,
        fromQuestingResourceID: UInt64,
        toQuestingResourceID: UInt64,
        rewardID: UInt64,
        rewardTemplateID: UInt32,
        minterID: UInt64
    )
    
    pub event RewardPerSecondChanged(
        questID: UInt64,
        typeIdentifier: String,
        rewardPerSecond: UFix64
    )
    
    pub event RewardRevealed(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        questRewardID: UInt64,
        rewardTemplateID: UInt32
    )
    
    pub event AdjustedQuestingStartDateUpdated(
        questID: UInt64,
        typeIdentifier: String,
        questingResourceID: UInt64,
        newAdjustedQuestingStartDate: UFix64
    )
    
    pub event QuestCreated(questID: UInt64, type: Type, questCreator: Address)
    
    pub event QuestDeposited(
        questID: UInt64,
        type: Type,
        questCreator: Address,
        questReceiver: Address?
    )
    
    pub event QuestWithdrawn(
        questID: UInt64,
        type: Type,
        questCreator: Address,
        questProvider: Address?
    )
    
    pub event QuestDestroyed(questID: UInt64, type: Type, questCreator: Address)
    
    pub event MinterDeposited(
        minterID: UInt64,
        name: String,
        receiverAddress: Address?
    )
    
    pub event MinterWithdrawn(
        minterID: UInt64,
        name: String,
        providerAddress: Address?
    )
    
    // -----------------------------------------------------------------------
    // Paths
    // -----------------------------------------------------------------------
    pub let QuestManagerStoragePath: StoragePath
    
    pub let QuestManagerPublicPath: PublicPath
    
    pub let QuestManagerPrivatePath: PrivatePath
    
    pub let QuesterStoragePath: StoragePath
    
    // -----------------------------------------------------------------------
    // Contract Fields
    // -----------------------------------------------------------------------
    pub var totalSupply: UInt64
    
    // -----------------------------------------------------------------------
    // Future Contract Extensions
    // -----------------------------------------------------------------------
    priv var metadata:{ String: AnyStruct}
    
    priv var resources: @{String: AnyResource}
    
    pub resource interface Public{ 
        pub let id: UInt64
        
        pub let type: Type
        
        pub let questCreator: Address
        
        pub var rewardPerSecond: UFix64
        
        access(contract) fun quest(
            questingResource: @AnyResource,
            address: Address
        ): @AnyResource{} 
        
        access(contract) fun unquest(
            questingResource: @AnyResource,
            address: Address
        ): @AnyResource{} 
        
        access(contract) fun revealQuestReward(
            questingResource: @AnyResource,
            questRewardID: UInt64
        ): @AnyResource{} 
        
        pub fun getQuesters(): [Address]{} 
        
        pub fun getAllQuestingStartDates():{ UInt64: UFix64}{} 
        
        pub fun getQuestingStartDate(questingResourceID: UInt64): UFix64?{} 
        
        pub fun getAllAdjustedQuestingStartDates():{ UInt64: UFix64}{} 
        
        pub fun getAdjustedQuestingStartDate(
            questingResourceID: UInt64
        ): UFix64?{} 
        
        pub fun getQuestingResourceIDs(): [UInt64]{} 
        
        pub fun borrowRewardCollection(
            questingResourceID: UInt64
        ): &QuestReward.Collection{QuestReward.CollectionPublic}?{} 
    }
    
    pub resource Quest: Public{ 
        pub let id: UInt64
        
        pub let type: Type
        
        pub let questCreator: Address
        
        priv var questers: [Address]
        
        priv var questingStartDates:{ UInt64: UFix64}
        
        priv var adjustedQuestingStartDates:{ UInt64: UFix64}
        
        /*
                    Questing Rewards
                */
        
        pub var rewardPerSecond: UFix64
        
        priv var rewards: @{UInt64: QuestReward.Collection}
        
        /*
                    Future extensions
                */
        
        priv var metadata:{ String: AnyStruct}
        
        priv var resources: @{String: AnyResource}
        
        init(type: Type, questCreator: Address){ 
            self.id = self.uuid
            self.type = type
            self.questCreator = questCreator
            self.questers = []
            self.questingStartDates ={} 
            self.adjustedQuestingStartDates ={} 
            self.rewardPerSecond = 604800.0
            self.rewards <-{} 
            self.metadata ={} 
            self.resources <-{} 
            Questing.totalSupply = Questing.totalSupply + 1
            emit QuestCreated(questID: self.id, type: type, questCreator: questCreator)
        }
        
        // access(contract) to make sure user verifies with their actual address using the quest function from the quester resource
        access(contract) fun quest(questingResource: @AnyResource, address: Address): @AnyResource{ 
            pre{ 
                questingResource.getType() == self.type:
                    "Cannot quest: questingResource type does not match type required by quest"
            }
            var uuid: UInt64? = nil
            var container: @{UInt64: AnyResource} <-{} 
            container[0] <-! questingResource
            if container[0]?.isInstance(Type<@NonFungibleToken.NFT>()) == true{ 
                let ref = &container[0] as auth &AnyResource?
                let resource = (ref as! &NonFungibleToken.NFT?)!
                uuid = resource.uuid
            }
            
            // ensure we always have a UUID by this point
            assert(uuid != nil, message: "UUID should not be nil")
            
            // check if already questing
            assert(!self.questingStartDates.keys.contains(uuid!), message: "Cannot quest: questingResource is already questing")
            
            // add quester to the list of questers
            if !self.questers.contains(address){ 
                self.questers.append(address)
            }
            
            // add timers
            self.questingStartDates[uuid!] = getCurrentBlock().timestamp
            self.adjustedQuestingStartDates[uuid!] = getCurrentBlock().timestamp
            emit QuestStarted(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: uuid!, quester: address)
            let returnResource <- container.remove(key: 0)!
            destroy container
            return <-returnResource
        }
        
        access(contract) fun unquest(questingResource: @AnyResource, address: Address): @AnyResource{ 
            pre{ 
                questingResource.getType() == self.type:
                    "Cannot unquest: questingResource type does not match type required by quest"
            }
            var uuid: UInt64? = nil
            var container: @{UInt64: AnyResource} <-{} 
            container[0] <-! questingResource
            if container[0]?.isInstance(Type<@NonFungibleToken.NFT>()) == true{ 
                let ref = &container[0] as auth &AnyResource?
                let resource = (ref as! &NonFungibleToken.NFT?)!
                uuid = resource.uuid
            }
            
            // ensure we always have a UUID by this point
            assert(uuid != nil, message: "UUID should not be nil")
            
            // check if questingResource is questing
            assert(self.questingStartDates.keys.contains(uuid!), message: "Cannot unquest: questingResource is not currently questing")
            self.unquestResource(questingResourceID: uuid!)
            let returnResource <- container.remove(key: 0)!
            destroy container
            return <-returnResource
        }
        
        access(contract) fun revealQuestReward(questingResource: @AnyResource, questRewardID: UInt64): @AnyResource{ 
            var uuid: UInt64? = nil
            var container: @{UInt64: AnyResource} <-{} 
            container[0] <-! questingResource
            if container[0]?.isInstance(Type<@NonFungibleToken.NFT>()) == true{ 
                let ref = &container[0] as auth &AnyResource?
                let resource = (ref as! &NonFungibleToken.NFT?)!
                uuid = resource.uuid
            }
            
            // ensure we always have a UUID by this point
            assert(uuid != nil, message: "UUID should not be nil")
            self.revealReward(questingResourceID: uuid!, questRewardID: questRewardID)
            let returnResource <- container.remove(key: 0)!
            destroy container
            return <-returnResource
        }
        
        /*
                    Public functions
                */
        
        pub fun getQuesters(): [Address]{ 
            return self.questers
        }
        
        pub fun getAllQuestingStartDates():{ UInt64: UFix64}{ 
            return self.questingStartDates
        }
        
        pub fun getQuestingStartDate(questingResourceID: UInt64): UFix64?{ 
            return self.questingStartDates[questingResourceID]
        }
        
        pub fun getAllAdjustedQuestingStartDates():{ UInt64: UFix64}{ 
            return self.adjustedQuestingStartDates
        }
        
        pub fun getAdjustedQuestingStartDate(questingResourceID: UInt64): UFix64?{ 
            return self.adjustedQuestingStartDates[questingResourceID]
        }
        
        pub fun getQuestingResourceIDs(): [UInt64]{ 
            return self.rewards.keys
        }
        
        pub fun borrowRewardCollection(questingResourceID: UInt64): &QuestReward.Collection{QuestReward.CollectionPublic}?{ 
            return &self.rewards[questingResourceID] as &QuestReward.Collection{QuestReward.CollectionPublic}?
        }
        
        /*
                    QuestManager functions
                */
        
        pub fun unquestResource(questingResourceID: UInt64){ 
            // remove timers
            self.questingStartDates.remove(key: questingResourceID)
            self.adjustedQuestingStartDates.remove(key: questingResourceID)
            emit QuestEnded(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: questingResourceID, quester: nil)
        }
        
        pub fun addReward(questingResourceID: UInt64, minter: &QuestReward.Minter, rewardAlgo: &AnyResource{RewardAlgorithm.Algorithm}, rewardMapping:{ Int: UInt32}){ 
            //check if resource is questing
            if let adjustedQuestingStartDate = self.adjustedQuestingStartDates[questingResourceID]{ 
                let timeQuested = getCurrentBlock().timestamp - adjustedQuestingStartDate
                
                //check if resource is eligible for reward
                if timeQuested >= self.rewardPerSecond{ 
                    let rewardTemplateID = rewardMapping[rewardAlgo.randomAlgorithm()] ?? panic("RewardMapping does not contain a reward for the random algorithm")
                    var newReward <- minter.mintReward(rewardTemplateID: rewardTemplateID)
                    let rewardID = newReward.id
                    let toRef: &QuestReward.Collection? = &self.rewards[questingResourceID] as &QuestReward.Collection?
                    if toRef == nil{ 
                        let newCollection <- QuestReward.createEmptyCollection()
                        newCollection.deposit(token: <-newReward)
                        self.rewards[questingResourceID] <-! newCollection as! @QuestReward.Collection
                    } else{ 
                        (toRef!).deposit(token: <-newReward)
                    }
                    self.updateAdjustedQuestingStartDate(questingResourceID: questingResourceID, rewardPerSecond: self.rewardPerSecond)
                    emit RewardAdded(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: questingResourceID, rewardID: rewardID, rewardTemplateID: rewardTemplateID, rewardTemplate: minter.getRewardTemplate(id: rewardTemplateID)!)
                }
            }
        }
        
        pub fun burnReward(questingResourceID: UInt64, rewardID: UInt64){ 
            let collectionRef = &self.rewards[questingResourceID] as &QuestReward.Collection?
            assert(collectionRef != nil, message: "Cannot burn reward: questingResource does not have any rewards")
            let reward <- (collectionRef!).withdraw(withdrawID: rewardID) as! @QuestReward.NFT
            emit RewardBurned(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: questingResourceID, rewardID: rewardID, rewardTemplateID: reward.rewardTemplateID, minterID: reward.minterID)
            destroy reward
        }
        
        pub fun moveReward(fromID: UInt64, toID: UInt64, rewardID: UInt64){ 
            let fromRef = &self.rewards[fromID] as &QuestReward.Collection?
            assert(fromRef != nil, message: "Cannot move reward: fromID does not have any rewards")
            let toRef: &QuestReward.Collection? = &self.rewards[toID] as &QuestReward.Collection?
            assert(toRef != nil, message: "Cannot move reward: toID does not have any rewards")
            let reward <- (fromRef!).withdraw(withdrawID: rewardID) as! @QuestReward.NFT
            emit RewardMoved(questID: self.id, typeIdentifier: self.type.identifier, fromQuestingResourceID: fromID, toQuestingResourceID: toID, rewardID: rewardID, rewardTemplateID: reward.rewardTemplateID, minterID: reward.minterID)
            (toRef!).deposit(token: <-reward)
        }
        
        pub fun changeRewardPerSecond(seconds: UFix64){ 
            self.rewardPerSecond = seconds
            emit RewardPerSecondChanged(questID: self.id, typeIdentifier: self.type.identifier, rewardPerSecond: seconds)
        }
        
        pub fun revealReward(questingResourceID: UInt64, questRewardID: UInt64){ 
            let collectionRef = &self.rewards[questingResourceID] as &QuestReward.Collection?
            assert(collectionRef != nil, message: "Cannot reveal reward: questingResource does not have any rewards")
            let rewardRef = (collectionRef!).borrowEntireQuestReward(id: questRewardID)!
            rewardRef.reveal()
            emit RewardRevealed(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: questingResourceID, questRewardID: questRewardID, rewardTemplateID: rewardRef.rewardTemplateID)
        }
        
        access(contract) fun updateAdjustedQuestingStartDate(questingResourceID: UInt64, rewardPerSecond: UFix64){ 
            if self.adjustedQuestingStartDates[questingResourceID] != nil{ 
                self.adjustedQuestingStartDates[questingResourceID] = self.adjustedQuestingStartDates[questingResourceID]! + rewardPerSecond
                emit AdjustedQuestingStartDateUpdated(questID: self.id, typeIdentifier: self.type.identifier, questingResourceID: questingResourceID, newAdjustedQuestingStartDate: self.adjustedQuestingStartDates[questingResourceID]!)
            }
        }
        
        destroy(){ 
            destroy self.rewards
            destroy self.resources
        }
    }
    
    pub resource interface MinterReceiver{ 
        pub fun depositMinter(minter: @QuestReward.Minter){} 
    }
    
    pub resource interface QuestReceiver{ 
        pub fun depositQuest(quest: @Quest){} 
    }
    
    pub resource interface QuestManagerPublic{ 
        pub fun getIDs(): [UInt64]{} 
        
        pub fun getMinterIDs(): [UInt64]{} 
        
        pub fun borrowQuest(id: UInt64): &Quest{Public}?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Quest reference: The ID of the returned reference is incorrect"
            }
        }
        
        pub fun borrowMinter(id: UInt64): &QuestReward.Minter{
            QuestReward.MinterPublic
        }?{ 
            post{ 
                result == nil || result?.id == id:
                    "Cannot borrow Minter reference: The ID of the returned reference is incorrect"
            }
        }
    }
    
    pub resource QuestManager:
        QuestManagerPublic,
        QuestReceiver,
        MinterReceiver{
    
        priv var quests: @{UInt64: Quest}
        
        priv var minters: @{UInt64: QuestReward.Minter}
        
        init(){ 
            self.quests <-{} 
            self.minters <-{} 
        }
        
        pub fun getIDs(): [UInt64]{ 
            return self.quests.keys
        }
        
        pub fun getMinterIDs(): [UInt64]{ 
            return self.minters.keys
        }
        
        pub fun createQuest(type: Type){ 
            let quest <-
                create Quest(type: type, questCreator: (self.owner!).address)
            let id = quest.id
            self.quests[id] <-! quest
        }
        
        pub fun depositQuest(quest: @Quest){ 
            emit QuestDeposited(
                questID: quest.id,
                type: quest.type,
                questCreator: quest.questCreator,
                questReceiver: self.owner?.address
            )
            self.quests[quest.id] <-! quest
        }
        
        pub fun withdrawQuest(id: UInt64): @Quest{ 
            let quest <-
                self.quests.remove(key: id) ?? panic("Quest does not exist")
            emit QuestWithdrawn(
                questID: id,
                type: quest.type,
                questCreator: quest.questCreator,
                questProvider: self.owner?.address
            )
            return <-quest
        }
        
        pub fun destroyQuest(id: UInt64){ 
            let quest <-
                self.quests.remove(key: id) ?? panic("Quest does not exist")
            emit QuestDestroyed(
                questID: id,
                type: quest.type,
                questCreator: quest.questCreator
            )
            destroy quest
        }
        
        pub fun borrowQuest(id: UInt64): &Questing.Quest{Public}?{ 
            return &self.quests[id] as &Questing.Quest{Public}?
        }
        
        pub fun borrowEntireQuest(id: UInt64): &Questing.Quest?{ 
            return &self.quests[id] as &Questing.Quest?
        }
        
        pub fun depositMinter(minter: @QuestReward.Minter){ 
            emit MinterDeposited(
                minterID: minter.id,
                name: minter.name,
                receiverAddress: self.owner?.address
            )
            self.minters[minter.id] <-! minter
        }
        
        pub fun withdrawMinter(id: UInt64): @QuestReward.Minter{ 
            let minter <-
                self.minters.remove(key: id) ?? panic("Minter does not exist")
            emit MinterWithdrawn(
                minterID: id,
                name: minter.name,
                providerAddress: self.owner?.address
            )
            return <-minter
        }
        
        pub fun borrowMinter(id: UInt64): &QuestReward.Minter{
            QuestReward.MinterPublic
        }?{ 
            return &self.minters[id]
            as
            &QuestReward.Minter{QuestReward.MinterPublic}?
        }
        
        pub fun borrowEntireMinter(id: UInt64): &QuestReward.Minter?{ 
            return &self.minters[id] as &QuestReward.Minter?
        }
        
        destroy(){ 
            destroy self.quests
            destroy self.minters
        }
    }
    
    pub resource Quester{ 
        pub fun quest(
            questManager: Address,
            questID: UInt64,
            questingResource: @AnyResource
        ): @AnyResource{ 
            let questRef =
                Questing.getQuest(questManager: questManager, id: questID)
            assert(
                questRef != nil,
                message: "Quest reference should not be nil"
            )
            return <-(questRef!).quest(
                questingResource: <-questingResource,
                address: (self.owner!).address
            )
        }
        
        pub fun unquest(
            questManager: Address,
            questID: UInt64,
            questingResource: @AnyResource
        ): @AnyResource{ 
            let questRef =
                Questing.getQuest(questManager: questManager, id: questID)
            assert(
                questRef != nil,
                message: "Quest reference should not be nil"
            )
            return <-(questRef!).unquest(
                questingResource: <-questingResource,
                address: (self.owner!).address
            )
        }
        
        pub fun revealReward(
            questManager: Address,
            questID: UInt64,
            questingResource: @AnyResource,
            questRewardID: UInt64
        ): @AnyResource{ 
            let questRef =
                Questing.getQuest(questManager: questManager, id: questID)
            assert(
                questRef != nil,
                message: "Quest reference should not be nil"
            )
            return <-(questRef!).revealQuestReward(
                questingResource: <-questingResource,
                questRewardID: questRewardID
            )
        }
    }
    
    pub fun getQuest(questManager: Address, id: UInt64): &Quest{Public}?{ 
        if let questManagerRef =
            getAccount(questManager).getCapability<
                &QuestManager{QuestManagerPublic}
            >(Questing.QuestManagerPublicPath).borrow(){ 
            return questManagerRef.borrowQuest(id: id)
        } else{ 
            return nil
        }
    }
    
    pub fun createQuestManager(): @QuestManager{ 
        return <-create QuestManager()
    }
    
    pub fun createQuester(): @Quester{ 
        return <-create Quester()
    }
    
    init(){ 
        self.QuestManagerStoragePath = /storage/WonderlandQuestManager_2
        self.QuestManagerPublicPath = /public/WonderlandQuestManager_2
        self.QuestManagerPrivatePath = /private/WonderlandQuestManager_2
        self.QuesterStoragePath = /storage/WonderlandQuester_2
        self.totalSupply = 0
        self.metadata ={} 
        self.resources <-{} 
        emit ContractInitialized()
    }
}
