/**
* @author       Kamal Sharma
* @date         2018-09-24
* @className	NXX2_SocialAdPageControllerTest
* @description  This is a test class for NXX2_SocialAdPageController.
*/
@isTest
public class NXX2_SocialAdPageControllerTest
{
	 /**
    * @author       Kamal Sharma
    * @date         2018-09-24
    * @description  This method will test saveSingleFile.
    * @param        NA
    * @return       void
    */
    static testMethod void testMethodsWithoutAPICall(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
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
        List<NXX2_ConfigModel.SocialAdType> socialAdTypes = NXX2_SocialAdPageController.getCreateAdConfigData();
        socialAd = new SocialAd__c(Ad_Headline__c = 'Test', Social_Campaign__c = proof.Id);
        socialAd = NXX2_SocialAdPageController.saveAdDetails(socialAd,'Social Ad');
        Social_Ad_Content__c content = new Social_Ad_Content__c(
        	File_Name__c = 'Test1',
            File_Type__c = 'Text',
            Social_Ad__c = socialAd.Id
        );
        List<Social_Ad_Content__c> contents = new List<Social_Ad_Content__c>();
        contents.add(content);
        contents = NXX2_SocialAdPageController.saveAdContent(JSON.serialize(contents),socialAd.Id,'Edit');
        content = new Social_Ad_Content__c(
        	File_Name__c = 'Test2',
            File_Type__c = 'Text2',
            GoogleDrive_File_Id__c = 'Test2',
            Social_Ad__c = socialAd.Id
        );
        contents = new List<Social_Ad_Content__c>();
        contents.add(content);
        contents = NXX2_SocialAdPageController.saveAdContent(JSON.serialize(contents),socialAd.Id,'CreateNewVersion');
        String initial = NXX2_SocialAdPageController.getInitialForUser();
        NXX2_SocialAdPageController.markAdAsDeleted(socialAd.Id);
        NXX2_SocialAdPageController.updateProofStatus(proof.Id,'In Review',null);
        List<Customer_Task__c> activities = NXX2_TestUtility.createCustomerActivity(new List<SocialCampaign__c>{proof});
        NXX2_SocialAdPageController.getCommunityBaseUrl();
        NXX2_SocialAdPageController.isExternalUser();
        NXX2_SocialAdPageController.getProofsForAccount(accounts[0].Id);
        NXX2_SocialAdPageController.getIconName('Account');
        Test.stopTest();
	}
     /**
    * @author       Kamal Sharma
    * @date         2018-09-24
    * @description  This method will test saveSingleFile.
    * @param        NA
    * @return       void
    */
    static testMethod void testMethodsWithAPICall(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
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
        Social_Ad_Content__c content = new Social_Ad_Content__c(
        	File_Name__c = 'Test1',
            File_Type__c = 'Text1',
            Social_Ad__c = socialAd.Id,
            GoogleDrive_File_Id__c = 'Test'
        );
        insert content;
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_LightningReqRespModel.SocialAdWithContent adWithContent = NXX2_SocialAdPageController.getAdDetails(socialAd.Id);
        List<NXX2_LightningReqRespModel.SocialAdWithContent> allAds = NXX2_SocialAdPageController.getAllAds(proof.Id);
        List<NXX2_LightningReqRespModel.SocialAdWithContent> allAdVersions = NXX2_SocialAdPageController.getAllVersionForSocialAd(socialAd.Id);
        List<NXX2_LightningReqRespModel.SocialAdContent> socialAdContents = NXX2_SocialAdPageController.getContentForSocialAd(socialAd.Id,null);
        Test.stopTest();
	}
}