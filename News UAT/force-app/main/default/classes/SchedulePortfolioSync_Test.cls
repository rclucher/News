@isTest
private class SchedulePortfolioSync_Test {
	
	@isTest static void test_scheduler() {
		
		string CRON_EXP = '0 0 0 15 3 ? *';
		SchedulePortfolioSync p = new SchedulePortfolioSync();

		Test.startTest();

	    String jobId = System.Schedule('PortfolioSync', CRON_EXP, p);
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
         System.assertEquals(CRON_EXP, ct.CronExpression);
         System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
	}
	
	
}