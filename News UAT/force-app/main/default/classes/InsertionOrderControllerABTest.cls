@isTest(seeAllData=false)
public class InsertionOrderControllerABTest {

    @testSetup static void setup() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        soApi.csmso__Line_Item_Fields_CSV__c = 'cscfga__Description__c,One_Off_Price__c';
        insert soApi;

        Insertion_Order_Spec__c insertionSpec = new Insertion_Order_Spec__c(Line_Item_Columns__c = 'Description,Price,Product Groups For IO,Total Number,Product Groups For Investment Summary,HTML IS',
                                                                            Logo_URL__c ='dummyURL');
        insert insertionSpec;

        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [SELECT Name, Id FROM RecordType
                             WHERE sObjectType='Account' AND
                                   Name = 'Prospecting Account' 
                                   AND isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        //so.Campaign_End_Date2__c = System.today().addDays(10); 
        so.Campaign_Start_Date__c = System.today();
        so.Campaign_Length__c = 2;
        so.csmso__Total_Price__c = 5.5; 
        so.Total_Impressions__c = 10;
        insert so;
        so.csmso__Status__c = 'Draft';
        
        Insertion_Order_Spec__c ios = TestDataSetupClass.createInsertOrderSpec();
        insert ios;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket );
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
        //testAttrDef.cscfga__configuration_output_mapping__c = 'test';
        insert testAttrDef;
        
        cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;   
        //testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
        testAttr1.cscfga__Value__c = 'test2';
        testAttr1.Name = 'Product Groups For IO';
        insert testAttr1; 
        
        cscfga__Attribute__c testAttr2 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr2.cscfga__Product_Configuration__c = prodConfig.Id;   
        //testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
        testAttr2.cscfga__Value__c = '1000';
        testAttr2.Name = 'Total Number';
        insert testAttr2;  
        
        cscfga__Attribute__c testAttr3 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr3.cscfga__Product_Configuration__c = prodConfig.Id;   
        //testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
        testAttr3.cscfga__Value__c = 'Display';
        testAttr3.Name = 'Product Groups For Investment Summary';
        insert testAttr3;
        
        NewsXtendIORef__c testIORef1 = TestDataSetupClass.createNewsXtendIORef();
        testIORef1.Quantity__c = 12;
        testIORef1.Details__c = 'test1details<0>';
        insert testIORef1;
        
        NewsXtendIORef__c testIORef2 = TestDataSetupClass.createNewsXtendIORef();
        testIORef2.Campaign_Element__c = 'testCampaign2';
        testIORef2.Display_Order__c = 12;
        testIORef2.Name = 'test2';
        testIORef2.Quantity__c = 11;
        testIORef2.Details__c = 'test2details<0>';
        insert testIORef2;
        
        List<NewsXtendIORef__c> refList = new List<NewsXtendIORef__c>();
        refList.add(testIORef1);
        refList.add(testIORef2);
    }

    @isTest 
    public static void testBasics() {
        
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        List<NewsXtendIORef__c> refList = [SELECT Name, Quantity__c FROM NewsXtendIORef__c];

        String test1;
        String test2;
        String test3;
        List<String> refDescList = new List<String>();
        refDescList.add(test1);
        refDescList.add(test2);
        refDescList.add(test3);
        
        List<List<String>> listRefDescList = new List<List<String>>();
        listRefDescList.add(refDescList);

        Test.startTest();
        PageReference pageRef = Page.InsertionOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(so) ;
        InsertionOrderController controller = new InsertionOrderController(sc);        
        ApexPages.currentPage().getParameters().put('id',so.id);
        controller.applyInsertionOrderConfigurables();
        controller.attributeNames = new String [] {'Product Groups For IO','Total Number','Product Groups For Investment Summary','HTML IS'};
        controller.ISDisplayStringText = 'test1';
        controller.ISSearchStringText = 'test2';
        controller.ISSocialStringText = 'test3';
        controller.ISCampaignStringText = 'test4';
        controller.ISTotalSocial = 79;
        controller.ISTotalDisplay = 80;
        controller.TotalValue = -0.9;
        controller.TotalGST = -0.7;
        controller.TotalValueGSTInclusive = -0.8;
        controller.DisplayISSummaryFlag = True;
        boolean Testerror19 = controller.DisplayISSummaryFlag;
        controller.SocialISSummaryFlag = True;
        boolean Testerror18 = controller.SocialISSummaryFlag;
        controller.IORefDescriptions = refList;
        controller.IORefFormatedDescriptions = listRefDescList;     

        try {
            controller.getCampaignElements();
        } catch(Exception e) { }

        controller.getInsertions();
       
        controller.applyInsertionOrderConfigurables();
        controller.findServiceOrderAddOns(refList);
        
        Test.stopTest();
    }
    
     @isTest 
    public static void testBasicsZero() {   

        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        List<NewsXtendIORef__c> refList = [SELECT Name, Quantity__c FROM NewsXtendIORef__c];
        
        cscfga__Attribute__c attr3 = [SELECT Id FROM cscfga__Attribute__c WHERE Name = 'Product Groups For Investment Summary' LIMIT 1];
        attr3.cscfga__Value__c = 'Search';
        update attr3;

        String test1;
        String test2;
        String test3;
        List<String> refDescList = new List<String>();
        refDescList.add(test1);
        refDescList.add(test2);
        refDescList.add(test3);
        
        List<List<String>> listRefDescList = new List<List<String>>();
        listRefDescList.add(refDescList);        
        
        Test.startTest();
        PageReference pageRef = Page.InsertionOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(so) ;
        InsertionOrderController controller = new InsertionOrderController(sc);        
        ApexPages.currentPage().getParameters().put('id',so.id);
        controller.applyInsertionOrderConfigurables();
        controller.ISDisplayStringText = 'test5';
        controller.ISSearchStringText = 'test6';
        controller.ISSocialStringText = 'test7';
        controller.ISCampaignStringText = 'test8';
        controller.ISTotalSocial = 0;
        controller.TotalValue = 0.9;
        controller.TotalGST = 0.7;
        controller.TotalValueGSTInclusive = 0.8;
        controller.ISTotalDisplay = 0;
        controller.DisplayISSummaryFlag = True;
        boolean Testerror19 = controller.DisplayISSummaryFlag;
        controller.SocialISSummaryFlag = True;
        boolean Testerror18 = controller.SocialISSummaryFlag;

        try {
            controller.getCampaignElements();
        } catch(Exception e) {}

        controller.getInsertions();
        controller.applyInsertionOrderConfigurables();
        
        Test.stopTest();
    }
}