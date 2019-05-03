/*---------------------------------------------------------
* Author:  Bohao Chen
* Description: This class contains unit tests for BookingRevenueRollup_Scheduler
* Company: Salesforce.com
* Date: 25/07/2013
* History:
* 25/07/2013   Bohao Chen       Created
---------------------------------------------------------*/
@isTest
private class BookingRevenueRollup_Scheduler_Test 
{
    static testmethod void test() 
    {
        // set up custom setting for last success run date time
        List<Batch_Run_Start_Datetime__c> lastRunDatetimeList = new List<Batch_Run_Start_Datetime__c>();
        
        Batch_Run_Start_Datetime__c lastRunDateTimeTcsTas = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTcsTas.Name = 'Account TCSTAS Update Batch';
        lastRunDateTimeTcsTas.Run_Start_Datetime__c = datetime.now().addDays(-1);
        lastRunDatetimeList.add(lastRunDateTimeTcsTas);
        
        Batch_Run_Start_Datetime__c lastRunDateTimeTgs = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTgs.Name = 'Account TGS Update Batch';
        lastRunDateTimeTgs.Run_Start_Datetime__c = datetime.now().addDays(-1);
        lastRunDatetimeList.add(lastRunDateTimeTgs);
        
        insert lastRunDatetimeList;
        
        Test.startTest();
        
        // Schedule the test job
        String CRON_EXP = '0 10 * * * ?';
        String jobId = System.schedule('TestBookingRevenueRollup_Scheduler',
                                       CRON_EXP, 
                                       new BookingRevenueRollup_Scheduler());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime
                          From CronTrigger Where id = :jobId];
        
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);
        
        // Verify the job has not run
        system.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        Datetime nextRunTime = datetime.now();
        
        if(nextRunTime.minute() >= 10)
        {
            nextRunTime = nextRunTime.addHours(1);
        }
        
        String runTimeHour = String.valueOf(nextRunTime.hour());
        
        if(nextRunTime.hour() <= 9)
        {
            runTimeHour = '0' + runTimeHour;
        }
        
        String runDatetime = String.valueOf(nextRunTime.date()).split(' ')[0] + ' '
            + runTimeHour + ':10:00';
        
        system.assertEquals(runDatetime, String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
    }
}