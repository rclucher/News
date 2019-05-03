/* History
2016-01-05   Darshan G   Updated
-----------------------------------------*/
global class Booking_Refresh_YTD_Revenue_Batch implements Database.Batchable<sObject>, Database.Stateful { // Updated By Bohao Chen on 30/05/2014 to keep values in sales order set
    
    global String query;
    global final List<Booking_Line_Item__c> bookingLineItemIds;
    global final Set<Id> salesOrderIds; // Updated By Bohao Chen on 30/05/2014 passing salesOrder only for testing purpose

    global Booking_Refresh_YTD_Revenue_Batch(List<Booking_Line_Item__c> bookingLineItemIds) 
    {    
        this.query = 'SELECT Id, Ad_Type__c, Cancelled__c, Gross_Price__c, Gross_Price_Change_Datetime__c, Gross_Price_YTD__c, Run_Date__c, Status__c ' +
                     'FROM Booking_Line_Item__c ' +
                     'ORDER BY Booking__c';
        
        if(Test.isRunningTest() && bookingLineItemIds != null)
        {
            this.bookingLineItemIds = bookingLineItemIds;
            this.salesOrderIds = new Set<Id>();
            this.query = 'SELECT Id, Ad_Type__c, Cancelled__c, Gross_Price__c, Gross_Price_Change_Datetime__c, ' + 
                         'Gross_Price_YTD__c, Run_Date__c, Status__c, Booking__r.Sales_Order__c ' +
                         'FROM Booking_Line_Item__c ' +
                         'Where Id IN: bookingLineItemIds ' + 
                         'ORDER BY Booking__c limit 200';
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        system.debug('## Start Booking_Refresh_YTD_Revenue_Batch query: ' + query); 
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // create the opportunity line item schedules

        system.debug('## Execute Booking_Refresh_YTD_Revenue_Batch ##'); 

        List<Booking_Line_Item__c> bookingItems = (List<Booking_Line_Item__c>)scope;
        List<Booking_Line_Item__c> bookingItemsUpdate = new List<Booking_Line_Item__c>();

        for (Booking_Line_Item__c bi : bookingItems) {

            if (bi.Run_Date__c != null && bi.Run_Date__c.year() == date.today().year()) {
                // Revenue falls this year
                // Ensure Gross Price YTD = Gross Price 
                if ((bi.Gross_Price__c == null && bi.Gross_Price_YTD__c != null) ||
                    (bi.Gross_Price__c != null && bi.Gross_Price_YTD__c == null) ||
                    (bi.Gross_Price__c != bi.Gross_Price_YTD__c)) 
                {
                    bi.Gross_Price_YTD__c = bi.Gross_Price__c;
                    bookingItemsUpdate.add(bi);
                }
            } else {
                // Revenue is not this year
                // Ensure Gross Price YTD is null
                if (bi.Gross_Price_YTD__c != null && bi.Gross_Price_YTD__c != 0) {
                    bi.Gross_Price_YTD__c = null;
                    bookingItemsUpdate.add(bi);
                }
            }

            // Updated by Bohao Chen on 30/05/2014
            if(Test.isRunningTest())
                salesOrderIds.add(bi.Booking__r.Sales_Order__c);
        }
        Database.update(bookingItemsUpdate, false); 
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        system.debug('## Finish Booking_Refresh_YTD_Revenue_Batch ##');
        
       // Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id = :BC.getJobId()];                        
        
        // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
            // Consolidate common function in Batch Utility class
        Batch_Utility.errorHandling(a, 'Booking Refresh YTD Revenue Batch');
                        
        // Roll-up revenue to Accounts
        AccountUpdateTcsTas_Batch att;

        this.query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Payer_Account__r.RecordType.Name, '
                     + 's.Advertiser_Account__c, s.Advertiser_Account__r.RecordType.Name, s.Total_Gross_Price_YTD_Last_Modified__c ' 
                     + 'From Sales_Order__c s';
        
        if(Test.isRunningTest())
            att = new AccountUpdateTcsTas_Batch(salesOrderIds, query);
        else
            att = new AccountUpdateTcsTas_Batch(null, query);

        Id batchProcessId = Database.executeBatch(att);

    }
}