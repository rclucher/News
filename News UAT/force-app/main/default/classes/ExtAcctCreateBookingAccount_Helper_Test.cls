/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class ExtAcctCreateBookingAccount_Helper_Test {

    static testMethod void gbaLoginTest() 
    {
        Test.setMock(WebServiceMock.class, new GeneraWebserviceLoginMock());
        
        Test.startTest();
        
        ExternalAccountCreateGBA_Helper controller = new ExternalAccountCreateGBA_Helper();
        
        controller.login();
        
        Test.stopTest();
    }
    
 
    
    static testMethod void gbaCreateAccountTest() 
    {
        // This causes a fake response to be generated
        // Call the method that invokes a callout
        // Verify that a fake result is returned
        Test.setMock(WebServiceMock.class, new GeneraWebserviceCreateAccountMock());
        
        Test.startTest();
        
        ExternalAccountCreateGBA_Helper controller = new ExternalAccountCreateGBA_Helper();
		
		
        controller.createAccount(   'Australia',
                                    'John Tester',
                                    'Mr.',
                                    'jt@email.com',
                                    true,
                                    '2000',
                                    0,
                                    'NSW',
                                    'George street',
                                    'Level 4',
                                    'CBD',
                                    '61',
                                    '02',
                                    '12345678',
                                    'Private Party',
                                    '47 007 871 178',
                                    'John',
                                    'Tester',
                                    '55512',
                                    'Retail',
                                    'jt@email.com',
                                    null,
                                    'NWN',
                                    'NWN');
        
        Test.stopTest();
    }
    
    static testMethod void gbaSaveAccountTest() 
    {
        // This causes a fake response to be generated
        // Call the method that invokes a callout
        // Verify that a fake result is returned
        Test.setMock(WebServiceMock.class, new GeneraWebserviceSaveAccountMock());
        
        Test.startTest();
        
        ExternalAccountCreateGBA_Helper controller = new ExternalAccountCreateGBA_Helper();
        
        controller.saveAccount('12345678');
        
        Test.stopTest();
    }
    
    static testMethod void gbaLogoutTest() 
    {
        // This causes a fake response to be generated
        // Call the method that invokes a callout
        // Verify that a fake result is returned
        Test.setMock(WebServiceMock.class, new GeneraWebserviceLogoutMock());
        
        Test.startTest();
        
        ExternalAccountCreateGBA_Helper controller = new ExternalAccountCreateGBA_Helper();
        
        controller.logout();
        
        Test.stopTest();
    }
    
    static TestMethod void prepopulateExternalAccount()
    {
        Test.startTest();
        
        ExternalAccountCreateGBA_Helper controller = new ExternalAccountCreateGBA_Helper();
        
        External_Account__c extAcc = new External_Account__c();
        
        List<Account> accts = TestDataFactory.createAccounts(2,false);
        insert accts;
        
        List<Account> personAccts = TestDataFactory.createAccounts(1,true);
        insert personAccts;
        
        External_Account__c ea1 = controller.prepopulateExternalAccount(extAcc, accts[0], accts[1], true);
		
		External_Account__c ea2 = controller.prepopulateExternalAccount(extAcc, accts[0], accts[0], false);
        
        External_Account__c ea3 = controller.prepopulateExternalAccount(extAcc, personAccts[0], accts[1], true, 'Private Party');
        
        Test.stopTest();
    
    }
    
    
}