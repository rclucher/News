/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
// 2015-12-01 darshan.gosar@bluewolfgroup.com
    // Removed seeAllData condition 
    // This class provides test coverage for
    //  - GlobalViewPointGetToken                87% 
    //  - svc_GlobalViewPointWebServiceStub      98% 
*/        
@isTest
private class GlobalViewPointGetToken_Test 
{
    static testMethod void myUnitTest() 
    {
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new svc_GvpWebServiceGenerateTokenMock());
        
        system.runAs(users[0])
        {
           String a = GlobalViewPointGetToken.getAccessToken('1234567');
        }
        
        Test.stopTest();
    }
}