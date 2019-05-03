/**
* @author       Kamal Sharma
* @date         2018-09-24
* @className	NXX2_ProofTriggerTest
* @description  This is a test class for NXX2_UploadFilesController.
*/
@isTest
public class NXX2_UploadFilesControllerTest
{
	 /**
    * @author       Kamal Sharma
    * @date         2018-09-24
    * @description  This method will test saveSingleFile.
    * @param        NA
    * @return       void
    */
    static testMethod void  testSaveSingleFile(){
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
        String fileId = NXX2_UploadFilesController.saveSingleFile(socialAd.Id, 'Test', 'Test', 'Test');
        system.assertEquals(fileId, 'Test');
        fileId = NXX2_UploadFilesController.saveFileInChunk(socialAd.Id, 'Test', 'Test', 'Test', 'Test', '1000', '0', '100');
        system.assertEquals(fileId, 'Test');
        Test.stopTest();
	}
}