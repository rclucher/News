@isTest
private class NXX2_ScheduleSendEForOutstandingTaskTest {
	static testMethod void testSocialAddHistory(){
		Test.startTest();
        NXX2_ScheduleSendEmailForOutstandingTask sh1 = new NXX2_ScheduleSendEmailForOutstandingTask();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest();  	
    }
}