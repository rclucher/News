@isTest
public class CS_ScheduleBillingFileCreationTest {

    @isTest
    static void testDelete() {
      Test.startTest();
      String jobId = System.schedule('CS_ScheduleBillingFileCreationTest', '0 0 0 21 6 ? *', new CS_ScheduleBillingFileCreation());
      Test.stopTest();        
    }
}