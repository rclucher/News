@isTest
private class NXX2_SchedulerForDataMigrationTest {
	static testMethod void testDataMigration(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        opportunities[0].Payer_Account__c = accounts[1].Id;
        opportunities[1].Payer_Account__c = accounts[2].Id;
        insert opportunities;
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<csmso__Product_Node__c> nodes = NXX2_TestUtility.createProductNodesForProductLine('Display');
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrderWithProductNodes(campaignOrder.Id,nodes);
        pos = [SELECT Name, Fulfillment_Type__c FROM Product_Order__c];
        NXX2_TestUtility.insertStagingTasks(pos);
        List<NXX2_Proof_Staging__c> proofs = NXX2_TestUtility.insertStagingProofs(pos);
        List<NXX2_ProofAd_Staging__c> proofAds = NXX2_TestUtility.insertStagingProofAds(pos);
        NXX2_TestUtility.insertStagingAssets(proofAds,proofs,false);
        NXX2_TestUtility.insertStagingSocialForm(proofAds);
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_SchedulerForDataMigration sh1 = new NXX2_SchedulerForDataMigration();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Data Migration', sch, sh1);
        Test.stopTest();  	
    }
    static testMethod void testDataMigration1(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        opportunities[0].Payer_Account__c = accounts[1].Id;
        opportunities[1].Payer_Account__c = accounts[2].Id;
        insert opportunities;
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<csmso__Product_Node__c> nodes = NXX2_TestUtility.createProductNodesForProductLine('Social');
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrderWithProductNodes(campaignOrder.Id,nodes);
        pos = [SELECT Name, Fulfillment_Type__c FROM Product_Order__c];
        NXX2_TestUtility.insertStagingTasks(pos);
        List<NXX2_Proof_Staging__c> proofs = NXX2_TestUtility.insertStagingProofs(pos);
        List<NXX2_ProofAd_Staging__c> proofAds = NXX2_TestUtility.insertStagingProofAds(pos);
        NXX2_TestUtility.insertStagingAssets(proofAds,proofs,false);
        NXX2_TestUtility.insertStagingSocialForm(proofAds);
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_SchedulerForDataMigration sh1 = new NXX2_SchedulerForDataMigration();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Data Migration', sch, sh1);
        Test.stopTest();  	
    }
    static testMethod void testDataMigration2(){
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        opportunities[0].Payer_Account__c = accounts[1].Id;
        opportunities[1].Payer_Account__c = accounts[2].Id;
        insert opportunities;
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<csmso__Product_Node__c> nodes = NXX2_TestUtility.createProductNodesForProductLine('Social');
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrderWithProductNodes(campaignOrder.Id,nodes);
        pos = [SELECT Name, Fulfillment_Type__c FROM Product_Order__c];
        NXX2_TestUtility.insertErrorStagingTasks(pos);
        List<NXX2_Proof_Staging__c> errorProofs = NXX2_TestUtility.insertErrorStagingProofs(pos);
        List<NXX2_ProofAd_Staging__c> errorProofAds = NXX2_TestUtility.insertErrorStagingProofAds(pos);
        NXX2_TestUtility.insertErrorStagingAssets(errorProofAds,errorProofs,false);
        NXX2_TestUtility.insertErrorStagingSocialForm(errorProofAds);
		Test.startTest();
        Test.setMock(HttpCalloutMock.class, new NXX2_GoogleDriveAPIMockUp());
        NXX2_SchedulerForDataMigration sh1 = new NXX2_SchedulerForDataMigration();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Data Migration', sch, sh1);
        Test.stopTest();  	
    }
}