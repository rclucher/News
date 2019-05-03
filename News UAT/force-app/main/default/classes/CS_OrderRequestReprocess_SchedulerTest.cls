/**
 * CS_OrderRequestReprocess_Scheduler test class.
 * Creates schedule and confirms that it is as expected.
 */
@isTest
public class CS_OrderRequestReprocess_SchedulerTest {

	@IsTest
	static void testSchedule(){
		String cronExp = '0 20 * * * ?';
		Test.startTest();

		String jobId   = System.schedule('Test sch', cronExp, new CS_OrderRequestReprocess_Scheduler());
		CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
		//validate result
		// Verify the expressions are the same
		System.assertEquals(cronExp, ct.CronExpression);

		Test.stopTest();
	}
}