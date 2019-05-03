public class AT_AccountTransactionDatesBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	public void execute(SchedulableContext sc){
        AT_AccountTransactionDatesBatch batch = new AT_AccountTransactionDatesBatch();
        
        Database.executeBatch(batch, 100);
    }
    
	public Database.QueryLocator start(Database.BatchableContext BC)
    {
        Set<String> recordTypeNames = new Set<String>();
        
        for (NextGen_Account_Type__mdt nat : [SELECT DeveloperName FROM NextGen_Account_Type__mdt]) {
            recordTypeNames.add(nat.DeveloperName);
        }
        
        Set<String> recordTypeIDs = new Set<String>();
        
        for (RecordType rt: [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :recordTypeNames]) {
            recordTypeIDs.add(rt.Id);
        } 
        
        return Database.getQueryLocator([SELECT Id FROM Account WHERE (RecordTypeId IN :recordTypeIDs)]);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Digital_Last_Transaction_Date__c, Print_Last_Transaction_Date__c, Xtend_Last_Transaction_Date__c FROM Account WHERE Id IN :scope FOR UPDATE]);
        
        //List<Booking__c> bookings = [SELECT Advertiser_Account__c, Last_Expiry_Stop_on_Web_Date__c, Last_Expiry_Appearance__c FROM Booking__c WHERE Advertiser_Account__c IN :scope];
        
        //List<Payment__c> payments = [SELECT Sales_Order__r.csmso__Advertiser__c, Last_End_Date__c FROM Payment__c WHERE Sales_Order__r.csmso__Advertiser__c IN :scope];
        
        for (Booking__c booking : [SELECT Advertiser_Account__c, Last_Expiry_Stop_on_Web_Date__c, Last_Expiry_Appearance__c, Source_System__c FROM Booking__c WHERE Advertiser_Account__c IN :scope]) {
        	Account acc = accountMap.get(booking.Advertiser_Account__c);
            
            if (acc != null) {
                if (booking.Source_System__c == 'AdPoint') {
                	if (acc.Digital_Last_Transaction_Date__c == null || acc.Digital_Last_Transaction_Date__c < booking.Last_Expiry_Stop_on_Web_Date__c) acc.Digital_Last_Transaction_Date__c = booking.Last_Expiry_Stop_on_Web_Date__c;
                }
                
                if (booking.Source_System__c == 'Cyber$ell') {
                	if (acc.Print_Last_Transaction_Date__c == null || acc.Print_Last_Transaction_Date__c < booking.Last_Expiry_Appearance__c) acc.Print_Last_Transaction_Date__c = booking.Last_Expiry_Appearance__c;
                }
            }
        }
        
        for (Payment__c payment : [SELECT Order__r.Account__c, Last_End_Date__c FROM Payment__c WHERE Order__r.Account__c IN :scope]) {
            Account acc = accountMap.get(payment.Order__r.Account__c);
            
            if (acc != null) {
                if (acc.Xtend_Last_Transaction_Date__c == null || acc.Xtend_Last_Transaction_Date__c < payment.Last_End_Date__c) acc.Xtend_Last_Transaction_Date__c = payment.Last_End_Date__c;
            }
        }
        
        update accountMap.values();
    }
        
    public void finish(Database.BatchableContext BC)
    {
    }
}