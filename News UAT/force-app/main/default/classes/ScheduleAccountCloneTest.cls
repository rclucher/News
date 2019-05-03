@isTest
private class ScheduleAccountCloneTest {
	
	@isTest static void test_accountClone() {
		
		string CRON_EXP = '0 0 0 15 3 ? *';
		ScheduleAccountClone p = new ScheduleAccountClone();

		Test.startTest();

	    String jobId = System.Schedule('Account Clone Updation', CRON_EXP, p);
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
         System.assertEquals(CRON_EXP, ct.CronExpression);
         System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
	}
}