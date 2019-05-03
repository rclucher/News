/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CS_SetupProductNodeBatchTest {

    @testSetup static void prepareTest() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        RecordType recordType = [SELECT id FROM RecordType
                                 WHERE Name = 'Product' AND 
                                       sObjectType = 'News_Xtend_Product_Ref__c'];

        List<News_Xtend_Product_Ref__c> xtendRefs = new List<News_Xtend_Product_Ref__c> {
                                                        new News_Xtend_Product_Ref__c(Provider__c = 'News Xtend',
                                                                                      Product_Line__c = 'Search', 
                                                                                      Product_Type__c = 'SEM',  
                                                                                      Network__c = 'Network',
                                                                                      Name = 'test SEM',
                                                                                      RecordTypeId = recordType.Id),
                                                        new News_Xtend_Product_Ref__c(Provider__c = 'News Xtend',
                                                                                      Product_Line__c = 'Search', 
                                                                                      Product_Type__c = 'SEM',  
                                                                                      Network__c = 'Network',
                                                                                      Name = 'test SEM 2',
                                                                                      RecordTypeId = recordType.Id)};    
        insert xtendRefs;
    }


    static testMethod void myUnitTest() 
    {
        Test.startTest();
        Database.executeBatch(new CS_SetupProductNodeBatch());
        Test.stopTest(); 	
        // TO DO: implement unit test
        
        // Assert
        List<csmso__Product_Node__c> pn = [SELECT Name FROM csmso__Product_Node__c ORDER BY Name LIMIT 2];

        System.assertEquals('test SEM', pn[0].Name);
        System.assertEquals('test SEM 2', pn[1].Name);

        List<News_Xtend_Product_Ref__c> pr = [SELECT Product_Node__c FROM News_Xtend_Product_Ref__c ORDER BY Product_Node__c LIMIT 2];

        System.assertEquals(pr[0].Product_Node__c,  pn[0].id);
        System.assertEquals(pr[1].Product_Node__c,  pn[1].id);
    }

    static testMethod void myUnitTestWithArgument() {
        List<News_Xtend_Product_Ref__c> xtendRefs = [SELECT Id FROM News_Xtend_Product_Ref__c];

        List<id> newsXtendIDsList = new List<Id>();

        for (News_Xtend_Product_Ref__c xtendRef : xtendRefs) {
            newsXtendIDsList.add(xtendRef.Id);
        }
        
        // Test
        Test.startTest();
        Database.executeBatch(new CS_SetupProductNodeBatch(newsXtendIDsList));
        Test.stopTest();  
        
        // Assert
        List<csmso__Product_Node__c> pn = [SELECT Name FROM csmso__Product_Node__c ORDER BY Name LIMIT 2];

        System.assertEquals('test SEM', pn[0].Name);
        System.assertEquals('test SEM 2', pn[1].Name);

        List<News_Xtend_Product_Ref__c> pr = [SELECT Product_Node__c FROM News_Xtend_Product_Ref__c ORDER BY Product_Node__c LIMIT 2];

        System.assertEquals(pr[0].Product_Node__c,  pn[0].id);
        System.assertEquals(pr[1].Product_Node__c,  pn[1].id);
    }

    static testMethod void myUnitTestNoScope() {
        csmso__Business_Unit__c businessUnit = TestDataSetupClass.createBusinessUnit();
        insert businessUnit;

        csmso__Product_Node__c  productNode  = TestDataSetupClass.createProductNode('Old product node 1', businessUnit);
        insert productNode;

        List<News_Xtend_Product_Ref__c> xtendRefs = [SELECT Id, Name FROM News_Xtend_Product_Ref__c];

        for (News_Xtend_Product_Ref__c xtendRef : xtendRefs) {
            xtendRef.Product_Node__c = productNode.Id;
        }

        update xtendRefs;

        // Test
        Test.startTest();
        Database.executeBatch(new CS_SetupProductNodeBatch());
        Test.stopTest();  
        
        // Assert - since Xtend Refs had Product IDs set, no new prodcut nodes were created 
        List<csmso__Product_Node__c> pn = [SELECT Name FROM csmso__Product_Node__c ORDER BY Name LIMIT 3];

        System.assertEquals(pn[0].Name, 'Old product node 1');
        System.assertEquals(pn.size(), 1);
    }
}