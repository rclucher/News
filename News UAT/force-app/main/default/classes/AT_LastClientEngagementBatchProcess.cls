global class AT_LastClientEngagementBatchProcess implements Database.Batchable < sObject >, Schedulable {
	global void execute(SchedulableContext sc){
        AT_LastClientEngagementBatchProcess batch = new AT_LastClientEngagementBatchProcess();
        
        Database.executeBatch(batch, 10);
    }
    
    String query = 'select id, EndDateTime, AccountId, WhatId from Event where EndDateTime >= YESTERDAY and EndDateTime < TODAY order by WhatId, EndDateTime desc';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List < sObject > scope) {
        updateLCE(scope);
    }

    global void finish(Database.BatchableContext BC) {
        // notify the executing user context the job is complete
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        // Send an email to the Apex job's submitter notifying of job completion.

        string subject = 'Batch Last Client Engagement Update ' + a.Status;
        string body = 'The batch last client engagement update job processed ' + a.TotalJobItems +
            ' batches, Total Items Processed = ' + a.JobItemsProcessed + ' with ' + a.NumberOfErrors + ' failures.';
        String[] toAddresses = new String[] {
            a.CreatedBy.Email
        };

        Batch_Utility.sendEmail(toAddresses, subject, body);
    }

    public static void updateLCE(List < Event > eventsList) {
        /*Extracting the list of all events that had End Date Yesterday*/

        if (!eventsList.isEmpty()) {
            /*Creating a Map to Retain the Account ID & The Highest Event End Date*/
            Map < ID, DateTime > acc_dt = new Map < ID, DateTime > ();
            for (Event eL: eventsList) {
                if (acc_dt.get(eL.WhatId) == null) {
                    acc_dt.put(eL.WhatId, eL.EndDateTime);
                }
            }
            /*Extracting the list of Accounts that need to be updated along with the value in Last Client Engagement Date*/
            List < Account > acc = new List < Account > ([SELECT Id, Last_Client_Engagement__c FROM Account WHERE ID IN: acc_dt.keySet() FOR UPDATE]);
            for (Account acc_to_update: acc) {

                /*Checking that the Last Client Engagement is < End Date on Event or Blank*/
                if (acc_to_update.Last_Client_Engagement__c < acc_dt.get(acc_to_update.Id) || acc_to_update.Last_Client_Engagement__c == null) {
                    acc_to_update.Last_Client_Engagement__c = acc_dt.get(acc_to_update.Id);
                }
            }

            /*Updating the Last Client Engagement Date*/
            update acc;
            }
    }
}