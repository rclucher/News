@IsTest(SeeAllData = true)
public with sharing class NXX2_ForgotPasswordControllerTest {
    
    /* Verifies that ForgotPasswordController handles invalid usernames appropriately */
    @IsTest
    static void testLightningForgotPasswordControllerInvalidUserName() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        contacts[0].Email = 'NXX2Test123@News.com';
        contacts[0].NewsXtend_My_Account_Access__c = true;
        insert contacts;
        NXX2_TestUtility.createPortalUser(contacts[0]);
        Test.stopTest();
        System.assertNotEquals(NXX2_ForgotPasswordController.forgotPassword('NXX2Test123@News.com', 'http://a.com'), Label.Site.invalid_email);
        System.assertNotEquals(NXX2_ForgotPasswordController.forgotPassword('fakeUser', 'http://a.com'), Label.Site.invalid_email);
        NXX2_ForgotPasswordController.setExperienceId(null);
        NXX2_ForgotPasswordController.setExperienceId('test');
    }
    /* Verifies that LightningForgotPasswordController object is instantiated correctly. */
    @IsTest
    static void LightningForgotPasswordControllerInstantiation() {
        NXX2_ForgotPasswordController controller = new NXX2_ForgotPasswordController();
        System.assertNotEquals(controller, null);
    }
}