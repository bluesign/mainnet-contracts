pub contract AFLBurnRegistry {
    pub let totalBurnsByTemplateId: {UInt64: UInt64}

    access(account) fun burn(templateId: UInt64) {
        if self.totalBurnsByTemplateId[templateId] == nil {
            self.totalBurnsByTemplateId[templateId] = 1
        } else {
            self.totalBurnsByTemplateId[templateId] = self.totalBurnsByTemplateId[templateId]! + 1
        }
    }

    pub fun getBurnDetails(templateId: UInt64): UInt64 {
        return self.totalBurnsByTemplateId[templateId] ?? 0
    }
    
    init() {
        self.totalBurnsByTemplateId = {}
    }
}
