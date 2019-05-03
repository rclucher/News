trigger AT_BookingSystemPortfolioJunctionManagement on Booking_System_Portfolio_Junction__c (before insert, before update) {
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Set<Id> externalAccountIDs = new Set<Id>();
        
        for (Booking_System_Portfolio_Junction__c bspj : Trigger.New) externalAccountIDs.add(bspj.Booking_System_Account__c);
        
        Map<Id, External_Account__c> externalAccounts = new Map<Id, External_Account__c>([SELECT Id, Customer_Account__c FROM External_Account__c WHERE Id IN :externalAccountIDs]);
        
        for (Booking_System_Portfolio_Junction__c bspj : Trigger.New) bspj.Account__c = externalAccounts.get(bspj.Booking_System_Account__c).Customer_Account__c;
    }
}