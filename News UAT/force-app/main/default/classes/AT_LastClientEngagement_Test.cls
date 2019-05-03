@isTest
private class AT_LastClientEngagement_Test {
	
 private static testMethod void setupTestData(){


        Integer recordsToCreate = 20, ii=0;
        Boolean isPersonAccount = false;
                List<Account> accList = new List<Account>();
     /*Creating / Inserting Account Data*/
     
        for ( Integer i = 0 ; i < recordsToCreate ; i++ ) {
            Account tmpAccount = new Account();
                tmpAccount.Name = 'Test Account ' + String.valueOf(i);
                tmpAccount.BillingPostalCode='2000';
                tmpAccount.BillingCountry = 'Australia';
                tmpAccount.BillingState = 'NSW';
                tmpAccount.BillingCity = 'Sydney';
                tmpAccount.BillingStreet = 'George Street';
                tmpAccount.DPID_Primary_Address__c = '555' + String.valueOf(i);
                tmpAccount.AccountNumber = '12345678901';
                tmpAccount.Phone = '61021234567' + String.valueOf(i);
                tmpAccount.Revenue_Group__c = 'Classified - Marketplace';
                tmpAccount.No_Parent_Account__c = true;
            tmpAccount.Total_Customer_Spend__c = 0;
            tmpAccount.Total_Agency_Spend__c = 0;
            tmpAccount.Total_Group_Spend__c = 0;
            tmpAccount.Last_Client_Engagement__c = System.now().addDays(-10);
            
            accList.add( tmpAccount);            
        }

	    insert accList;
	    
     /*Creating / Inserting Event Data*/
	    List <Event> eve = new List <Event>();
	    for (Integer i=0; i<recordsToCreate; i++){
	    Event event_temp = new Event();
	        event_temp.Description = 'Test Description '+i;
            event_temp.ShowAs = 'Busy';
            event_temp.Subject = 'Test Subject '+i;
            event_temp.IsReminderSet = false;
            event_temp.IsPrivate = false;
            event_temp.StartDateTime = System.now().addDays(-2);
            event_temp.EndDateTime = System.now().addDays(-1);
            event_temp.whatID = accList[i].id;
            eve.add(event_temp);
	    }
	    insert eve;

     /*Starting Test*/
     	Test.startTest();
     
          /*Running Batch Process*/
        Database.executeBatch(new AT_LastClientEngagementBatchProcess());
     
          /*Stopping Test to Commit Changes Before Proceeding Further*/
     	Test.stopTest();
     
          /*Asserting Changes Post Batch Run to Compare the End Date of Event with Last Client Engagement Date*/
     	List < Account > accList_new = new List <Account>([Select id, name, Last_client_engagement__c from account order by id asc]);
        for (Account acc: accList_new){
             System.assertEquals(acc.Last_client_engagement__c, eve[ii].EndDateTime);
             ii++;
         }
     
     }
    
}