@isTest
private class SchedulePortfolioReassignment_Test {
	
	@isTest static void test_schedulePortfolioReassignment() {
		
		string CRON_EXP = '0 0 0 15 3 ? *';
		SchedulePortfolioReassignment p = new SchedulePortfolioReassignment();

		Test.startTest();

	    String jobId = System.Schedule('Portfolio Reassignment', CRON_EXP, p);
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
         System.assertEquals(CRON_EXP, ct.CronExpression);
         System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
	}

}