@isTest
public with sharing class DNCPhoneExtractSchedule_Test {
//Class for unit testing the DNC Phone Extract Scheduler
    
   //arbitrary cron setting  
   public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   static testmethod void DNCSchedulerTest() {
      Test.startTest();

      //Create Custom Settings for Test
      DNC_Settings__c settings = new DNC_Settings__c(
            Name = 'DNC Defaults', 
            Delete_Scope_Size__c = 1000, 
            Delete_Window__c = 1, 
            Extract_Scope_Size__c = 50,
            External_Id__c = '12345678'
        );
      
      insert settings;
      
      // Schedule the test job 
    
      String jobId = System.schedule('DNCPhoneExtractScheduleTest',
                        CRON_EXP, 
                        new DNCPhoneExtractSchedule());
         
      // Get the information from the CronTrigger API object 
    
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same 
    
      System.assertEquals(CRON_EXP, 
         ct.CronExpression);

      // Verify the job has not run 
    
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run 
    
      System.assertEquals('2022-03-15 00:00:00', 
         String.valueOf(ct.NextFireTime));
 
      // Verify the scheduled job hasn't run yet. 
    
      DNC_Wash_Register__c[] ml = [SELECT Id FROM DNC_Wash_Register__c 
                             WHERE Name = 'Scheduled Job Item'];
      System.assertEquals(ml.size(),0);
      Test.stopTest();



   }

}