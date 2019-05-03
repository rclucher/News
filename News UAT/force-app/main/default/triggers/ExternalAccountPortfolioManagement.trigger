trigger ExternalAccountPortfolioManagement on Booking_System_Portfolio_Junction__c (before insert, before update) {
    /*if (Trigger.isInsert || Trigger.isUpdate) {
        Map<Id, Id> bsaPortfolios = new Map<Id, Id>();
        Map<Id, Id> accountPortfolioMap = new Map<Id, Id>();
        
        for (Booking_System_Portfolio_Junction__c rel: Trigger.New) {
            bsaPortfolios.put(rel.Booking_System_Account__c, rel.Portfolio__c);
        }
        
        for (External_Account__c acc: [SELECT Id, Customer_Account__c FROM External_Account__c WHERE Id IN :bsaPortfolios.keySet()]) {
            accountPortfolioMap.put(acc.Customer_Account__c, bsaPortfolios.get(acc.Id));
        }
        
        AccountPortfolioManagement.addPortfoliosToAccounts(accountPortfolioMap);
    }
    
    if (Trigger.isDelete) {
        Map<Id, Id> bsaPortfolios = new Map<Id, Id>();
        Map<Id, Id> accountPortfolioMap = new Map<Id, Id>();
        
        for (Booking_System_Portfolio_Junction__c rel: Trigger.New) {
            bsaPortfolios.put(rel.Booking_System_Account__c, rel.Portfolio__c);
        }
        
        for (External_Account__c acc: [SELECT Id, Customer_Account__c FROM External_Account__c WHERE Id IN :bsaPortfolios.keySet()]) {
            accountPortfolioMap.put(acc.Customer_Account__c, bsaPortfolios.get(acc.Id));
        }
          
        AccountPortfolioManagement.removePortfoliosFromAccounts(accountPortfolioMap);
    }*/
}