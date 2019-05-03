@isTest
public class NXX2_GoogleDriveFileBrowserCtrlTest{
    public static testMethod void testContants() {
        Contact con = new Contact(Firstname = 'Test',Lastname = 'Test',Email = 'Test@gmail.com');
        insert con;
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        Order__c order = new Order__c(Campaign_Customer_Contact__c = con.Id,Account__c = accounts[0].Id);
        insert order;
        Product_Order__c po = new Product_Order__c(order__c = order.Id);
        insert po;
        SocialCampaign__c proof = new SocialCampaign__c(Product_Order__c = po.Id,Status__c = 'New');
        insert proof;
        SocialAd__c socialAd = new SocialAd__c(Social_Campaign__c = proof.Id);
        insert socialAd;
        Test.startTest();
		Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_GoogleDriveFileBrowserController.fetchProofNumberForGoogleDriveRecord(proof.Id);
        NXX2_GoogleDriveFileBrowserController.uploadFilesInGoogleDrive('Test','Test','Test',socialAd.Id);
        NXX2_GoogleDriveFileBrowserController.loadFilesFromGoogleDrive(socialAd.Id,'Test');
        NXX2_GoogleDriveFileBrowserController.deleteFilesInGoogleDrive('Test');
        NXX2_GoogleDriveFileBrowserController.readUploadedFilesFromGoogleDrive('Test');
        NXX2_GoogleDriveFileBrowserController.saveChunk(socialAd.Id, 'Test', 'Test', 'Test', 'Test', '1000', '0', '100','Test');
        NXX2_GoogleDriveFileBrowserController.saveTheFile(socialAd.Id, 'Test', 'Test', 'Test', '1000', 0, 100,'Test');
        NXX2_GoogleDriveFileBrowserController.appendToFile(socialAd.Id, 'Test', 'Test', 'Test', 'Test', '1000', 0, 100,'Test');
        Test.stopTest();
    }
}