@isTest
private class CS_BatchTierCalculationScheduleTest {
	@isTest
	static void test_execute() {
		Test.startTest();

		CS_BatchTierCalculationSchedule schedule = new CS_BatchTierCalculationSchedule();
		schedule.execute(null);

		Test.stopTest();
	}
}