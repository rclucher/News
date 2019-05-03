trigger AccountPortfolioManagement on Account_Portfolio_Relationship__c (before insert, before update, before delete) {
    /*if (Trigger.isInsert || Trigger.isUpdate) {
        Map<Id, Id> accountPortfolioMap = new Map<Id, Id>();
        
        for (Account_Portfolio_Relationship__c rel: Trigger.New) {
            accountPortfolioMap.put(rel.Account__c, rel.Portfolio__c);
        }
        
        AccountPortfolioManagement.addPortfoliosToAccounts(accountPortfolioMap);
    }
    
    if (Trigger.isDelete) {
        Map<Id, Id> accountPortfolioMap = new Map<Id, Id>();
        
        for (Account_Portfolio_Relationship__c rel: Trigger.Old) {
            accountPortfolioMap.put(rel.Account__c, rel.Portfolio__c);
        }
        
        AccountPortfolioManagement.removePortfoliosFromAccounts(accountPortfolioMap);
    }*/
}