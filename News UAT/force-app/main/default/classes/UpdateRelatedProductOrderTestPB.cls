@isTest
public class UpdateRelatedProductOrderTestPB {
    @isTest static void test_method_one() {
      Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        salesOrder.csmso__Status__c = 'Manually Approved';
        insert salesOrder;

        cscfga__Product_Basket__c basket = TestDataSetupClass.createProdBasket(salesOrder);
        insert basket;

        csmso__Business_Unit__c businessUnit = TestDataSetupClass.createBusinessUnit();
        insert businessUnit;

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        
        csmso__Product_Node__c productNode = TestDataSetupClass.createProductNode('NX Search - SEM (Media Spend) [>$2000 p/m]', businessUnit);
        productNode.Product_Line__c = 'Social';
        productNode.Product_Type__c = 'Setup';
        insert productNode;

        cscfga__Product_Configuration__c config = TestDataSetupClass.createProdConfig(basket);
        config.Product_ID__c = productNode.Id;
        insert config;


        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Account__c = acc.Id;
        order.Status__c = 'Draft';
        order.sales_Order__c = salesOrder.Id;
        insert order;
        
        Order__c o = [SELECT Id FROM Order__c LIMIT 1];
      
        
        Product_Order__c po = new Product_Order__c();
        po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
        po.Order__c = o.id;
        po.Status__c ='Draft';
        po.Amazon_URL__c = 'test';
        po.Ebay_URL__c = 'ebay';
        po.External_System_ID_2__c = 'ext';
        po.Facebook_URL__c = 'facebook';
        po.Google_URL__c = 'google';
        po.Other_URL__c ='OtherURL';
        po.Product_Node__c = productNode.Id;
        insert po;
    List<UpdateRelatedProductOrder.Request> testproList = new List <UpdateRelatedProductOrder.Request>();
 
    UpdateRelatedProductOrder.Request requests;
      requests = new   UpdateRelatedProductOrder.Request();
        requests.amazonUrl = po.Amazon_URL__c;
        requests.ebayUrl = po.Ebay_URL__c;
        requests.extSys = po.External_System_ID2__c;
        requests.facebookUrl = po.Facebook_URL__c;
        requests.googleUrl = po.Google_URL__c;
        requests.orderId = po.Order__c;
        requests.otherUrl = po.Other_URL__c;
        testproList.add(requests);
        
        UpdateRelatedProductOrder.doAction(testproList);
    }
  
}