@isTest
public class NXX2_AppUtilityTest{
    public static testMethod void testUtility() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        contacts[0].Email = 'NXX2Test123@News.com';
        contacts[0].NewsXtend_My_Account_Access__c = true;
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        opportunities[0].Payer_Account__c = accounts[1].Id;
        opportunities[1].Payer_Account__c = accounts[2].Id;
        insert opportunities;
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
        Test.stopTest();
        NXX2_AppUtility.getDependentOptions(SocialAd__c.Creative_Type__c, SocialAd__c.Ad_Type__c);
        NXX2_AppUtility.decimalToBinary(200);
        NXX2_AppUtility.base64ToBits('Test');
        NXX2_AppUtility.findObjectNameFromRecordIdPrefix(accounts[0].Id);
        NXX2_AppUtility.processGoogleDriveResponse('{"items" : [{"id" : "Test"}]}');
        NXX2_AppUtility.processGoogleDriveFileUploadResponse('{"id" : "Test", "thumbnailLink" : "Test"}');
        NXX2_AppUtility.getIconName('Account');
        NXX2_AppUtility.getCustomerTaskListDTO(activityForCO);
        NXX2_AppUtility.formatDateForEmail(Datetime.now());
        NXX2_AppUtility.PicklistEntryWrapper wrapper = new NXX2_AppUtility.PicklistEntryWrapper();
        wrapper.active = 'Test';
        wrapper.defaultValue = 'Test';
        wrapper.label = 'Test';
        wrapper.value = 'Test';
        wrapper.validFor = 'Test';
    }
}