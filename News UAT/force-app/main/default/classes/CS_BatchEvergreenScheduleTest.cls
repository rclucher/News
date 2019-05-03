@isTest
public class CS_BatchEvergreenScheduleTest {
    
    @isTest
    static void testRenewal() {
      Test.startTest();
      String jobId = System.schedule('CS_BatchEvergreenScheduleTest', '0 0 0 21 6 ? *', new CS_BatchEvergreenSchedule());
      Test.stopTest();        
    }

}