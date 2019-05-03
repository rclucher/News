/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-06-11
* @description  This class contains test methods that provides test coverage for the following classes,
*                   - CCN_Case_Batch             85%
*                   - CCN_Event_Batch            91%
*                   - CCN_Task_Batch             90%
*                   - CCN_EmailMessae_Batch      80%
*                   - CCN_Helper                 94%
*                   - CCN_Case_Schedule         100%    
*                   - CCN_Event_Schedule        100%        
*                   - CCN_Task_Schedule         100%    
*                   - CCN_EmailMessage_Schedule 100%    
*               Note: The batch job will be filtered based on test records CreatedDate (created in test class).
*                       As such, running test class when Server Date changes could produce unnecessary errors. 
*                       Just run again when it occurs.
// 2015-12-09 darshan.gosar@bluewolfgroup.com 
    // Change increase code coverage for below class & rest all class coverage is same as given above
        - CCN_EmailMessage_Batch      91%
// 2016-03-18 darshan.gosar@bluewolfgroup.com 
    // Updated test class to maintain code coverage for class CCN_EmailMessae_Batch & CCN_Helper as part of request Item-00031
        - CCN_EmailMessage_Batch      91%
        - CCN_Helper                  93%                
// 2017-09-22 darshan.gosar@bluewolfgroup.com Item-00809
    // Updated testMethod ccn_Task_Batch_Detect_Test to validate count considering new task getting created via Email Message
*/
@isTest (seeAllData=false)
private class CCN_Test 
{
    static List<Case> caseList = new List<Case>();
    static List<Task> taskList = new List<Task>();
    static List<Event> eventList = new List<Event>();
    static List<EmailMessage> emList = new List<EmailMessage>();
    static string currentMonth_Short = string.valueOf(System.Today()).mid(0,7); //2015-06
    static string lastMonth_Short = CCN_Helper.calc_DateString_MinusOneMonth_Short(currentMonth_Short); //2015-05
    static string firstDayOfCurrentMonth_Short = currentMonth_Short + '-01'; // 2015-06-01

    static void setup()
    {
        caseList = TestDataFactory.createCases(5, null, null);
        caseList[0].Description = 'This is a sample credit card number 4123512361237123';
        caseList[1].status = 'Closed';
        insert caseList;        

        taskList = TestDataFactory.createTasks(5);
        taskList[0].Description = 'This is a sample credit card number 3711-078176-01234';  
        update taskList;

        Event evt1 = new Event();
        evt1.DurationInMinutes = 1;
        evt1.ActivityDateTime = System.Now();
        evt1.Description = 'This is a sample credit card number 5123 4123 6123 7123';
        eventList.add(evt1);

        Event evt2 = new Event();
        evt2.DurationInMinutes = 1;
        evt2.ActivityDateTime = System.Now();
        eventList.add(evt2);
        insert eventList;

        EmailMessage em1 = TestDataFactory.createEmailMessage(caseList[1], 'test@test.com');
        em1.TextBody = 'This is a sample credit card number 6011-0009-9013-9424';
        emList.add(em1);

        EmailMessage em2 = TestDataFactory.createEmailMessage(caseList[2], 'test@test.com');
        emList.add(em2);
        insert emList;

        SystemMessages__c sm = new SystemMessages__c();
        sm.External_Id__c= 'eid';
        sm.Message__c = 'Message';
        sm.Used_by__c='';
        sm.name = 'CCN_EmailMessage_Clone';
        insert sm;

        list<Batch_Run_Start_Datetime__c> batList = new list<Batch_Run_Start_Datetime__c>();
        Batch_Run_Start_Datetime__c bat = new Batch_Run_Start_Datetime__c();
        bat.Name = 'Last Success Update CCN_Case';
        bat.Run_Start_Datetime__c = System.Now().addDays(-10);
        batList.add(bat);
        Batch_Run_Start_Datetime__c bat2 = new Batch_Run_Start_Datetime__c();
        bat2.Name = 'Last Success Update CCN_Task';
        bat2.Run_Start_Datetime__c = System.Now().addDays(-10);
        batList.add(bat2);
        Batch_Run_Start_Datetime__c bat3 = new Batch_Run_Start_Datetime__c();
        bat3.Name = 'Last Success Update CCN_Event';
        bat3.Run_Start_Datetime__c = System.Now().addDays(-10);
        batList.add(bat3);
        Batch_Run_Start_Datetime__c bat4 = new Batch_Run_Start_Datetime__c();
        bat4.Name = 'Last Success Update CCN_EmailMessage';
        bat4.Filters__c = '00590000001S9fyAAC';
        bat4.Run_Start_Datetime__c = System.Now().addDays(-10);
        batList.add(bat4);
        insert batList;
    }

    @isTest 
    static void ccn_Case_Batch_Detect_Test() 
    {
        setup();
        Test.startTest();
        // Intial Run - Detect Mode
        CCN_Case_Batch ccn1 = new CCN_Case_Batch(lastMonth_Short, currentMonth_Short, 'InitialRun', 'Detect', 'Case Detect Test');
        database.executeBatch(ccn1);
        Test.stopTest();

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 5, 1);
    }

    @isTest 
    static void ccn_Case_Batch_Update_Test() 
    {
        setup();
        Test.startTest();
        // Incremental Run - Update Mode
        CCN_Case_Batch ccn2 = new CCN_Case_Batch(null, null, 'IncrementalRun', 'Update', 'Case Update Incremental Test');
        database.executeBatch(ccn2);

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 5, 1);

        // Incremental Run - Detect Mode
        CCN_Case_Batch ccn3 = new CCN_Case_Batch(null, null, 'IncrementalRun', 'Detect', 'Case Detect Incremental Test');
        database.executeBatch(ccn3);
        Test.stopTest();

        // there should be 5 records looped, and 0 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 5, 0);
    }

    @isTest 
    static void ccn_Task_Batch_Detect_Test() 
    {
        setup();
        Test.startTest();
        // Intial Run - Detect Mode
        CCN_Task_Batch ccn1 = new CCN_Task_Batch(lastMonth_Short, currentMonth_Short, 'InitialRun', 'Detect', 'Task Detect Test');
        database.executeBatch(ccn1);
        Test.stopTest();

        // there should be 5 records looped, and 1 record detected with CCN
        // 2017-09-22 AdSales 809 darshan.gosar@bluewolfgroup.com 
        // Updated count of number of records from 5 to 7 as there are total 7 task, 5 created as part of test & 2 are getting created due to EmailMessage
        // Updated count of CNN detected count from 1 to 2 as 1 task created with CCN & 1 task is created vai EmailMessage & it contain CCN entry as well
        checkAssertions(firstDayOfCurrentMonth_Short, 7, 2);
    }

    @isTest 
    static void ccn_Task_Batch_Update_Test() 
    {
        setup();
        Test.startTest();
        // Incremental Run - Update Mode        
        CCN_Task_Batch ccn2 = new CCN_Task_Batch(null, null, 'IncrementalRun', 'Update', 'Task Update Incremental Test');
        database.executeBatch(ccn2);

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 5, 1);

        // Incremental Run - Detect Mode
        CCN_Task_Batch ccn3 = new CCN_Task_Batch(null, null, 'IncrementalRun', 'Detect', 'Task Detect Incremental Test');
        database.executeBatch(ccn3);
        Test.stopTest();

        // there should be 5 records looped, and 0 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 5, 0);
    }

    @isTest 
    static void ccn_Event_Batch_Detect_Test() 
    {
        setup();
        Test.startTest();
        // Intial Run - Detect Mode
        CCN_Event_Batch ccn1 = new CCN_Event_Batch(lastMonth_Short, currentMonth_Short, 'InitialRun', 'Detect', 'Event Detect Test');
        database.executeBatch(ccn1);
        Test.stopTest();

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 1);
    }

    @isTest 
    static void ccn_Event_Batch_Update_Test() 
    {
        setup();
        Test.startTest();
        // Incremental Run - Update Mode        
        CCN_Event_Batch ccn2 = new CCN_Event_Batch(null, null, 'IncrementalRun', 'Update', 'Event Update Incremental Test');
        database.executeBatch(ccn2);

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 1);

        // Incremental Run - Detect Mode
        CCN_Event_Batch ccn3 = new CCN_Event_Batch(null, null, 'IncrementalRun', 'Detect', 'Event Detect Incremental Test');
        database.executeBatch(ccn3);
        Test.stopTest();

        // there should be 5 records looped, and 0 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 0);
    }

    @isTest 
    static void ccn_EmailMessage_Batch_Detect_Test() 
    {
        setup();
        Test.startTest();
        // Intial Run - Detect Mode
        CCN_EmailMessage_Batch ccn1 = new CCN_EmailMessage_Batch(lastMonth_Short, currentMonth_Short, 'InitialRun', 'Detect', 'Event Detect Test');
        database.executeBatch(ccn1);
        Test.stopTest();

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 1);
    }

    @isTest 
    static void ccn_EmailMessage_Batch_Update_Test() 
    {
        setup();
        Test.startTest();
        // Incremental Run - Update Mode        
        CCN_EmailMessage_Batch ccn2 = new CCN_EmailMessage_Batch(lastMonth_Short, currentMonth_Short, 'IncrementalRun', 'Update', 'EmailMessage Update Incremental Test');
        database.executeBatch(ccn2);

        // there should be 5 records looped, and 1 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 1);
        
        // Incremental Run - Detect Mode
        CCN_EmailMessage_Batch ccn3 = new CCN_EmailMessage_Batch(null, null, 'IncrementalRun', 'Detect', 'EmailMessage Detect Incremental Test');
        database.executeBatch(ccn3);
        
        Test.stopTest();

        // there should be 5 records looped, and 0 record detected with CCN
        checkAssertions(firstDayOfCurrentMonth_Short, 2, 0);
    }

    // SFE-766 2015-12-09 darshan.gosar@bluewolfgroup.com
        // To get more code coverage added below error test condition
    @isTest 
    static void ccn_EmailMessage_Batch_Error_Test() 
    {
        setup();        
               
        Test.startTest();
        // Incremental Run - Update Mode        
        CCN_EmailMessage_Batch ccn2 = new CCN_EmailMessage_Batch(null, null, 'IncrementalRun', 'Update', 'EmailMessage Update Incremental Test');       
        
        for(EmailMessage e: emList){
            ccn2.cloneFailedIds.add(e.Id);
        }
        database.executeBatch(ccn2);
        Test.stopTest();
    }
    
    static void checkAssertions(String firstDay, Integer totalNo_Expected, Integer detectedNo_Expected)
    {
        // fetch the log records and confirm the outcome
        List<General_Batch_Log__c> gblList = [SELECT Id, CCN_Detected__c, Number_of_Records__c 
                                                FROM General_Batch_Log__c
                                                WHERE Start_Date__c =: date.valueOf(firstDay)
                                                ORDER BY CreatedDate DESC 
                                                LIMIT 1];
        integer totalNo = 0;
        integer detectedNo = 0;
        if(!gblList.isEmpty())
        {
            totalNo = integer.valueOf(gblList[0].Number_of_Records__c);
            detectedNo = integer.valueOf(gblList[0].CCN_Detected__c);

            system.assertEquals(totalNo, totalNo_Expected);
            system.assertEquals(detectedNo, detectedNo_Expected);
        }
    }

    static testmethod void CaseSchedule_Test() 
    {
        setup();
        //arbitrary cron setting  
        String CRON_EXP = '0 0 0 15 3 ? 2022';

        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('CCN Case Schedule Daily',
                                    CRON_EXP, 
                                    new CCN_Case_Schedule());
         
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

    static testmethod void TaskSchedule_Test() 
    {
        setup();
        //arbitrary cron setting  
        String CRON_EXP = '0 0 0 15 3 ? 2022';

        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('CCN Task Schedule Daily',
                                    CRON_EXP, 
                                    new CCN_Task_Schedule());
         
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

    static testmethod void EventSchedule_Test() 
    {
        setup();
        //arbitrary cron setting  
        String CRON_EXP = '0 0 0 15 3 ? 2022';

        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('CCN Event Schedule Daily',
                                    CRON_EXP, 
                                    new CCN_Event_Schedule());
         
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

    static testmethod void EmailMsgSchedule_Test() 
    {
        setup();
        //arbitrary cron setting  
        String CRON_EXP = '0 0 0 15 3 ? 2022';

        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('CCN EmailMessage Schedule Daily',
                                    CRON_EXP, 
                                    new CCN_EmailMessage_Schedule());
         
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
}