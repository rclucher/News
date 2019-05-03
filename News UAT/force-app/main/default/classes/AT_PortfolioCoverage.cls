public class AT_PortfolioCoverage {
    public class Coverage {
        @AuraEnabled
        Map<Id, String> portfolioNames {get; set;}
        
        @AuraEnabled
        Map<Id, Set<Id>> portfolioAccounts {get; set;}
        
        @AuraEnabled
        Map<Id, Account> clients {get; set;}
        
        @AuraEnabled
        Map<Id, Boolean> futureBookings {get; set;}
    }
    
	@AuraEnabled
    public static Coverage getCoverage() {
        Set<Id> roleIDs = AT_AccessUtil.getCurrentUserRoleAndSubordinates();

        Set<String> accountTypes =  new Set<String>();
        
        for (NextGen_Account_Type__mdt accType: [SELECT DeveloperName FROM NextGen_Account_Type__mdt]) {
            accountTypes.add(accType.DeveloperName);
        }
        
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE (SObjectType = 'Account') AND (DeveloperName IN :accountTypes)];
        
        Set<Id> accountIDs = new Set<Id>();
     
        Coverage coverage = new Coverage();
        
        coverage.portfolioAccounts = new Map<Id, Set<Id>>();
        coverage.portfolioNames = new Map<Id, String>();
        
        /* Changing this to use the Account OwnerId instead of Portfolio_Owners__c object
         
        for (Portfolio_Owners__c portfolio : [SELECT Portfolio2__c, Portfolio2__r.Name FROM Portfolio_Owners__c WHERE (Portfolio_Owner__c = :UserInfo.getUserId()) OR (Portfolio_Owner__r.UserRoleId IN :roleIDs)]) {
            coverage.portfolioNames.put(portfolio.Portfolio2__c, portfolio.Portfolio2__r.Name);
        }
        
        for (Account_Portfolio_Relationship__c rel: [SELECT Account__c, Portfolio__c FROM Account_Portfolio_Relationship__c WHERE (Portfolio__c IN :coverage.portfolioNames.keySet()) AND (Account__r.RecordTypeId IN :recordTypes)]) {
            accountIDs.add(rel.Account__c);
            addtoMap(coverage.portfolioAccounts, rel.Portfolio__c, rel.Account__c);
        }
        
        for (Booking_System_Portfolio_Junction__c rel: [SELECT Booking_System_Account__r.Customer_Account__c, Portfolio__c FROM Booking_System_Portfolio_Junction__c WHERE (Portfolio__c IN :coverage.portfolioNames.keySet()) AND (Booking_System_Account__r.Customer_Account__r.RecordTypeId IN :recordTypes)]) {
            accountIDs.add(rel.Booking_System_Account__r.Customer_Account__c);
            addtoMap(coverage.portfolioAccounts, rel.Portfolio__c, rel.Booking_System_Account__r.Customer_Account__c);
        }*/
        
        for (Account_Portfolio_Relationship__c rel: [SELECT Account__c, Portfolio__c, Portfolio__r.Name FROM Account_Portfolio_Relationship__c WHERE ((Account__r.OwnerId = :UserInfo.getUserId()) OR (Account__r.Owner.UserRoleId IN :roleIDs)) AND (Account__r.RecordTypeId IN :recordTypes)]) {
            coverage.portfolioNames.put(rel.Portfolio__c, rel.Portfolio__r.Name);
            
            accountIDs.add(rel.Account__c);
            addtoMap(coverage.portfolioAccounts, rel.Portfolio__c, rel.Account__c);
        }
        
        for (Booking_System_Portfolio_Junction__c rel: [SELECT Booking_System_Account__r.Customer_Account__c, Portfolio__c, Portfolio__r.Name FROM Booking_System_Portfolio_Junction__c WHERE ((Account__r.OwnerId = :UserInfo.getUserId()) OR (Account__r.Owner.UserRoleId IN :roleIDs)) AND (Booking_System_Account__r.Customer_Account__r.RecordTypeId IN :recordTypes)]) {
            coverage.portfolioNames.put(rel.Portfolio__c, rel.Portfolio__r.Name);
            
            accountIDs.add(rel.Booking_System_Account__r.Customer_Account__c);
            addtoMap(coverage.portfolioAccounts, rel.Portfolio__c, rel.Booking_System_Account__r.Customer_Account__c);
        }
        
        coverage.clients = new Map<Id, Account>([SELECT Id, Name, Last_Client_Engagement__c, RecordType.Name, Last_Booking_Last_Expiry_Appearance__c FROM Account WHERE (Id IN :accountIDs) AND (RecordTypeId IN :recordTypes)]);

        coverage.futureBookings = new Map<Id, Boolean>();
        
        for (Account acc: [SELECT Id FROM Account WHERE Id IN (SELECT Advertiser_Account__c FROM Booking__c WHERE (Advertiser_Account__c IN :accountIDs) AND (First_Expiry_Appearance__c > TODAY))]) {
            coverage.futureBookings.put(acc.Id, true);
        }

        return coverage;
    }
    
    private static void addToMap(Map<Id, Set<Id>> mapSet, Id key, Id value) {
        Set<Id> values = mapSet.get(key);
        
        if (values == null) values = new Set<Id>();
        
        values.add(value);
        
        mapSet.put(key, values);
    }
}