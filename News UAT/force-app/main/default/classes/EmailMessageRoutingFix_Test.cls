@isTest
private class EmailMessageRoutingFix_Test {

    static List<EmailMessage> emList = new List<EmailMessage>();
    static List<Case> caseList = new List<Case>();
    static void setup()
    {
        
        caseList = TestDataFactory.createCases(5, null, null);
        caseList[0].Description = 'This is a sample credit card number 4123512361237123';
        caseList[1].status = 'Closed';
        insert caseList;        

        EmailMessage em1 = TestDataFactory.createEmailMessage(caseList[1], 'test@test.com');
        em1.TextBody = 'test';
        emList.add(em1);
 
        EmailMessage em2 = TestDataFactory.createEmailMessage(caseList[2], 'test@test.com');
        emList.add(em2);
        insert emList;
    }
    
    
    static testmethod void EmailMessageRoutingFix_Schedule_Test() 
    {
        setup();
        Case c = [Select origin, ready_for_routing__c from case where id = :emList[0].parentId limit 1];
        caseList[1].origin = 'Email - Inbound for Routing';
        caseList[1].ready_for_routing__c = false;
        Test.setCreatedDate(caseList[1].id, System.NOw().addMinutes(-3));
        update caseList[1];

        //arbitrary cron setting  

        String CRON_EXP = '0 0 0 15 3 ? 2022';
        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('EmailMessageRoutingFix_Schedule',
                                    CRON_EXP, 
                                    new EmailMessageRoutingFix_Schedule());
         
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same 
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run     
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run     
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
 
        Test.stopTest();
    }
    
    // Added by Darshan on 26 May to fix test coverage issue
    static testmethod void EmailMessageRoutingFix_Batch_Test() 
    {
        setup();
        Case c = [Select origin, ready_for_routing__c from case where id = :emList[0].parentId limit 1];
        caseList[1].origin = 'Email - Inbound for Routing';
        caseList[1].ready_for_routing__c = false;
        Test.setCreatedDate(caseList[1].id, System.NOw().addMinutes(-3));
        update caseList[1];

        Test.startTest();        
        String q = 'SELECT Id, Ready_for_Routing__c FROM Case WHERE Id = \'' + caseList[1].Id + '\'';
        EmailMessageRoutingFix_Batch emrf = new EmailMessageRoutingFix_Batch(q, 0);
        database.executeBatch(emrf);
                
        Test.stopTest();
    }
    
    // Added by Darshan on 26 May to fix test coverage issue
    static testmethod void EmailMessageRoutingFix_Batch_WithaddMinutes_Test() 
    {
        setup();
        Case c = [Select origin, ready_for_routing__c from case where id = :emList[0].parentId limit 1];
        caseList[1].origin = 'Email - Inbound for Routing';
        caseList[1].ready_for_routing__c = false;
        Test.setCreatedDate(caseList[1].id, System.NOw().addMinutes(-3));
        update caseList[1];

        Test.startTest();        
        String q = 'SELECT Id, Ready_for_Routing__c FROM Case WHERE Id = \'' + caseList[1].Id + '\'';
        EmailMessageRoutingFix_Batch emrf = new EmailMessageRoutingFix_Batch(q, -2);
        database.executeBatch(emrf);
                
        Test.stopTest();
    }                  
    
}