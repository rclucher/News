global class AT_AccountUpdateBatchJob implements Database.Batchable<sObject>, Schedulable, Database.Stateful
{
    Id theAusSalesId;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        theAusSalesId = [SELECT Id FROM Profile WHERE Name = 'The Aus Sales'].Id;
        
        String query = 'SELECT Id,Name,Customer_Segment__c FROM Account where Customer_Segment__c = \'\''; 
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> scope)
    {
        
        // Map of Account Id to List of Portfolios
        Map<Id, Set<Id>> accountPortfolioMap = new Map<Id, Set<Id>>();
        
        SeT<Id> portfolioIDs = new Set<Id>();
        
        for (Account_Portfolio_Relationship__c apr: [SELECT Portfolio__c,Account__c, Account__r.Name FROM Account_Portfolio_Relationship__c WHERE Account__c IN: scope]) {
            Set<Id> portfolios = accountPortfolioMap.get(apr.Account__c);
            
            if (portfolios == null) portfolios = new Set<Id>();
            
            portfolios.add(apr.Portfolio__c);
            
            portfolioIDs.add(apr.Portfolio__c);
            
            accountPortfolioMap.put(apr.Account__c, portfolios);
        }
        
        for (Booking_System_Portfolio_Junction__c bspj: [SELECT Portfolio__c,Booking_System_Account__c, Booking_System_Account__r.Customer_Account__c FROM Booking_System_Portfolio_Junction__c WHERE Booking_System_Account__c IN (SELECT Id FROM External_Account__c WHERE Customer_Account__c IN: scope)]) {
            Set<Id> portfolios = accountPortfolioMap.get(bspj.Booking_System_Account__r.Customer_Account__c);
            
            if (portfolios == null) portfolios = new Set<Id>();
            
            portfolios.add(bspj.Portfolio__c);
            
            portfolioIDs.add(bspj.Portfolio__c);
            
            accountPortfolioMap.put(bspj.Booking_System_Account__r.Customer_Account__c, portfolios);
        }
        
        Map<Id, Portfolio2__c> portfolioMap = new Map<Id, Portfolio2__c>([SELECT Id, Portfolio_Segment__c, Priority_Sequence__c FROM Portfolio2__c WHERE Id IN :portfolioIDs]);
        
        List<Account> accounts = [SELECT Id, Name, Customer_Segment__c, Owner.ProfileId FROM Account WHERE Id IN :scope FOR UPDATE];
        
        for (Account acc: accounts) {
            String accountSegment = null;
            Decimal sequence = 100;
            
            if (acc.Owner.ProfileId == theAusSalesId) {
                acc.Customer_Segment__c = 'AUS';
            } else {
                Set<Id> portfolios = accountPortfolioMap.get(acc.Id);
                
                for (Id pId: portfolios) {
                    Portfolio2__c p = portfolioMap.get(pId);
                    
                    if (p.Priority_Sequence__c < sequence) {
                        accountSegment = p.Portfolio_Segment__c;
                        sequence = p.Priority_Sequence__c;
                    }
                }
                
                acc.Customer_Segment__c = accountSegment;
            }
        }
        
        update accounts;
    }
    global void finish(Database.BatchableContext BC) {
        
    }
    global void execute(SchedulableContext sc) {
         AT_AccountUpdateBatchJob b = new AT_AccountUpdateBatchJob ();
         database.executebatch(b);
     }
}