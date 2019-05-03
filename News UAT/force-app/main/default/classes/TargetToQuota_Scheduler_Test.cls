/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This class contains unit tests for validating the behavior of TargetToQuota_Scheduler
 * Company: Salesforce.com
 * Date: 9/10/2013
 * History:
 * 9/10/2013   Bohao Chen       Created
 ---------------------------------------------------------*/
@istest
private class TargetToQuota_Scheduler_Test 
{
   static testmethod void test() 
   {
        String CRON_EXP = '0 0 0 3 9 ? 2022';
    
        Test.startTest();
    
        // Schedule the test job
        String jobId = System.schedule('Target to Quota Scheduler', 
                CRON_EXP,  new TargetToQuota_Scheduler());
                
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