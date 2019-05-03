@isTest
private class ScheduleOpportunityCloneTest {
	
	@isTest static void test_method_one() {
		// Implement test code
		string CRON_EXP = '0 0 0 15 3 ? *';
		ScheduleOpportunityClone p = new ScheduleOpportunityClone();

		Test.startTest();

	    String jobId = System.Schedule('Account Clone Updation', CRON_EXP, p);
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
         System.assertEquals(CRON_EXP, ct.CronExpression);
         System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
	}
	
	
	
}