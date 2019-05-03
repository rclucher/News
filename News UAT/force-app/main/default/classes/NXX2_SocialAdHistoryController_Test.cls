@isTest
private class NXX2_SocialAdHistoryController_Test {
	
	static testMethod void testSocialAddHistory(){
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
        SocialAd__History objectHistory = new SocialAd__History(ParentId = socialAd.Id, Field = 'Social_Campaign__c');
        insert objectHistory;
        Social_Ad_Content__c content = new Social_Ad_Content__c(
        	File_Name__c = 'Test1',
            File_Type__c = 'Text1',
            Social_Ad__c = socialAd.Id,
            GoogleDrive_File_Id__c = 'Test'
        );
        insert content;
        Social_Ad_Content__History objectHistory1 = new Social_Ad_Content__History(ParentId = content.Id, Field = 'File_Name__c');
        insert objectHistory1;
        Test.startTest();
        	NXX2_SocialAdHistoryController.getSocialAdHistory(socialAd.Id);
        	NXX2_SocialAdHistoryController.getIconName('Account');
        Test.stopTest();  
		
	}
	
	
}