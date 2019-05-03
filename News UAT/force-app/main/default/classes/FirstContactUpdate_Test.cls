@isTest
private class FirstContactUpdate_Test 
{
    static testMethod void updateFirstContactTest() 
    {
    	User u = TestDataFactory.createUser('System Administrator', 'test', 'test', null, null, false);
    	u.Bypass_Triggers__c = 'ContactManagement';
    	insert u;
    	
    	system.runAs(u)
    	{
	    	// create accounts
	    	List<Account> accounts = TestDataFactory.createAccounts(10, false);
	    	insert accounts;
	    	
	    	// create contacts
	    	List<Contact> contacts = new List<Contact>();
	    	
	    	for(Account a : accounts)
	    	{
	    	   contacts.addAll(TestDataFactory.createContacts(10, a));
	    	}
	        
	    	insert contacts;
	    	
	    	Test.startTest();
	
	    	FirstContactUpdate_Helper.processContacts(accounts);
	    	
	    	Test.stopTest();
    	}
    }
    
    static testMethod void updateFirstContactTest1() 
    {
        User u = TestDataFactory.createUser('System Administrator', 'test', 'test', null, null, false);
        u.Bypass_Triggers__c = 'ContactManagement';
        insert u;
        
        system.runAs(u)
        {
	        // create accounts
	        List<Account> accounts = TestDataFactory.createAccounts(10, false);
	        insert accounts;
	        
	        // create contacts
	        List<Contact> contacts = new List<Contact>();
	        
	        for(Account a : accounts)
	        {
	           contacts.addAll(TestDataFactory.createContacts(10, a));
	        }
	        
	        for(Contact c : contacts)
	        {
	        	c.First_Contact_in_Account__c = true;
	        }
	        
	        insert contacts;
	        
	        Test.startTest();
	
	        FirstContactUpdate_Helper.processContacts(accounts);
	        
	        Test.stopTest();
        }
    }
    
    
    static testMethod void sendingErrorEmailsTest() 
    {
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
    	List<Contact> contacts = TestDataFactory.createContacts(10, accounts[0]);
    	insert contacts;
    	
    	Test.startTest();
    	
    	for(Contact c : contacts)
    	{
    		c.Phone = 'fdsfadfds';
    		c.MobilePhone = 'fdsfsdfdsfsd';
    	}
    	
    	List<Database.SaveResult> srList = Database.update(contacts, false);
    	
    	FirstContactUpdate_Helper.sendErrorResults(srList, contacts);
    	
        Test.stopTest();
    }
    
   static testmethod void scheduledBatchTest() 
   {
   	    // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(10, false);
        insert accounts;
        
        String CRON_EXP = '0 0 0 3 9 ? 2022';
    
        Test.startTest();
    
        // Schedule the test job
        String jobId = System.schedule('FirstContactUpdateScheduler', 
                CRON_EXP,  new FirstContactUpdate_Scheduler());
                
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                           FROM CronTrigger 
                           WHERE id = :jobId];
    
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
    
        // Verify the next time the job will run
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
    
        Test.stopTest();
    }
}