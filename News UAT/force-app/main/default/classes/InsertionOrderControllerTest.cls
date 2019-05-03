@IsTest
public with sharing class InsertionOrderControllerTest {

    @testSetup static void setup() {
        
        /*
         * Create Products
         */
        Pricebook2 pb = TestDataSetupClass.createPriceBook();
        insert pb;
            
        // Print
        Product2 product2Print = TestDataSetupClass.createProduct2('The Advertiser');
        insert product2Print;

        PriceBookEntry printPbe = TestDataSetupClass.createPriceBookEntry(product2Print);
        insert printPbe;

        Publication_Product__c pbPrint = TestDataSetupClass.createPublicationProduct(product2Print);
        pbPrint.Publication__c = 'The Advertiser';
        insert pbPrint;

        // Digital
        Product2 product2Digital = TestDataSetupClass.createProduct2('RoN medrec roadblock Desktop');
        insert product2Digital;

        PriceBookEntry digitalPbe = TestDataSetupClass.createPriceBookEntry(product2Digital);
        insert digitalPbe;

        Publication_Product__c pbDigital = TestDataSetupClass.createPublicationProduct(product2Digital);
        pbDigital.Publication__c = 'RoN medrec roadblock Desktop';
        insert pbDigital;

        // Xtend
        Product2 product2Xtend = TestDataSetupClass.createProduct2('NewsXtend');
        insert product2Xtend;

        PriceBookEntry xtendPbe = TestDataSetupClass.createPriceBookEntry(product2Xtend);
        insert xtendPbe;

        Publication_Product__c pbXtend = TestDataSetupClass.createPublicationProduct(product2Xtend);
        pbXtend.Publication__c = 'NewsXtend';
        insert pbXtend;
 
        /*
         * Create Product Definitions
         * Otherwise Campaign_Products_Type__c field on Sales Order will not be populated correctly.
         * createOpportunityProducts() code testing depends on this value
         */
        cscfga__Product_Category__c productCategory = TestDataSetupClass.createProdCateg();
        insert productCategory;

        cscfga__Product_Definition__c printLedProdDef = TestDataSetupClass.createProDef(productCategory);
        printLedProdDef.Name = 'Print Led';
        insert printLedProdDef;

        cscfga__Product_Definition__c xtendLedProdDef = TestDataSetupClass.createProDef(productCategory);
        xtendLedProdDef.Name = 'News Xtend Led';
        insert xtendLedProdDef;

        cscfga__Product_Definition__c bundlePrintProdDef = TestDataSetupClass.createProDef(productCategory);
        bundlePrintProdDef.Name = 'Bundle Print';
        insert bundlePrintProdDef;

        cscfga__Product_Definition__c bundleXtendProdDef = TestDataSetupClass.createProDef(productCategory);
        bundleXtendProdDef.Name = 'Bundle Xtend';
        insert bundleXtendProdDef;

        cscfga__Product_Definition__c bundleDigitalProdDef = TestDataSetupClass.createProDef(productCategory);
        bundleDigitalProdDef.Name = 'Bundle Digital';
        insert bundleDigitalProdDef;

        Account account = TestDataSetupClass.createAccount();
        insert account;

        Contact contact = TestDataSetupClass.createContact(account);
        insert contact;

        Opportunity opportunity = TestDataSetupClass.createOpportunity(account, contact);
        insert opportunity;

        csmso__Sales_Order__c so  = TestDataSetupClass.createSalesOrder(account, opportunity);
        so.Platform_Set__c        = '{Xtend,Digital,Print}';
        //added status to avoid exception if the status is draft
        so.csmso__Status__c       = 'Manually Approved';
        so.Campaign_Length__c     = 6;
        so.Campaign_Start_Date__c = Date.today()+1;
        so.csmso__Total_Price__c  = 500;
        so.Dashboard__c           = True;
        so.Conversion_Tracking__c = True;
        so.Creative_Services__c   = True;
        insert so;

        cscfga__Product_Basket__c seasonalSOPB     = TestDataSetupClass.createProdBasket(so);
        insert seasonalSOPB;

        // bundle PC
        cscfga__Product_Configuration__c bundlePC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
        bundlePC1.cscfga__Product_Definition__c    = printLedProdDef.Id;
        bundlePC1.Bundle_Name__c = 'Always-On LITE';
        insert bundlePC1;

        cscfga__Product_Configuration__c bundlePrintPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
        bundlePrintPC1.cscfga__Parent_Configuration__c  = bundlePC1.Id;
        bundlePrintPC1.cscfga__Product_Definition__c    = bundlePrintProdDef.Id;
        bundlePrintPC1.Bundle_Name__c = '';
        bundlePrintPC1.Platform__c = 'Print';
        bundlePrintPC1.Publication__c = 'The Advertiser';
        bundlePrintPC1.Total_Print_Price__c = 100;
        bundlePrintPC1.Duration_Months__c = 6;
        insert bundlePrintPC1;

        cscfga__Product_Configuration__c bundleDigitalPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
        bundleDigitalPC1.cscfga__Parent_Configuration__c = bundlePC1.Id;
        bundleDigitalPC1.cscfga__Product_Definition__c    = bundleDigitalProdDef.Id;
        bundleDigitalPC1.Bundle_Name__c = '';
        bundleDigitalPC1.Platform__c = 'Digital';
        bundleDigitalPC1.Bespoke_Digital_Description__c = 'RoN medrec roadblock Desktop';
        bundleDigitalPC1.Total_Digital_Price__c = 100;
        bundleDigitalPC1.Duration_Months__c = 6;
        insert bundleDigitalPC1;

        cscfga__Product_Configuration__c bundleXtendPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
        bundleXtendPC1.cscfga__Parent_Configuration__c  = bundlePC1.Id;
        bundleXtendPC1.cscfga__Product_Definition__c    = bundleXtendProdDef.Id;
        bundleXtendPC1.Bundle_Name__c = '';
        bundleXtendPC1.Platform__c = 'Xtend';
        bundleXtendPC1.Total_Invoice__c = 100;
        bundleXtendPC1.Duration_Months__c = 6;
        insert bundleXtendPC1;

        // SO needs to be updated so that Platform_Set__c is populated
        update so;

        Insertion_Order_Spec__c insertionSpec = new Insertion_Order_Spec__c(Line_Item_Columns__c = 'Description,Price,Product Groups For IO,Total Number,Product Groups For Investment Summary,HTML IS,Publication State,Digital Product Name',
                                                                            Logo_URL__c ='dummyURL');
        insert insertionSpec;  

        csmso__SalesOrderAPI__c soapi = new csmso__SalesOrderAPI__c(csmso__Line_Item_Fields_CSV__c = 'cscfga__Description__c,One_Off_Price__c');
        insert soapi; 

        NewsXtendIORef__c IORef1 = new NewsXtendIORef__c (Name = 'Landing Page', Campaign_Element__c = 'Landing Page', Details__c = 'Detail', Quantity__c=1, Display_Order__c = 300);
        insert IORef1;

        NewsXtendIORef__c IORef2 = new NewsXtendIORef__c (Name = 'Dashboard', Campaign_Element__c = 'Dashboard', Details__c = 'Detail', Quantity__c=1, Display_Order__c = 2000);
        insert IORef2;

        /*
         * Xtend PC Attributes
         */
        List<cscfga__Attribute__c> testAttributes = new List<cscfga__Attribute__c>();
        testAttributes.add(new cscfga__Attribute__c(name = 'Description',
                                                    cscfga__Value__c = 'Test Description Attribute',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'Date Range',
                                                    cscfga__Value__c = '1/1/2014 - 1/3/2014 (25 Insertions)', 
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'Price',
                                                    cscfga__Value__c = '1234',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'Product Groups for IO',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'Total Number',
                                                    cscfga__Value__c = '100',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'Product Groups For Investment Summary',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
        testAttributes.add(new cscfga__Attribute__c(name = 'HTML IS',
                                                    cscfga__Value__c = '2018-03-23',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
         testAttributes.add(new cscfga__Attribute__c(name = 'Digital Product Name',
                                                    cscfga__Value__c = 'Example Digital Product Name',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));
         testAttributes.add(new cscfga__Attribute__c(name = 'Publication State',
                                                    cscfga__Value__c = 'Publication State',
                                                    cscfga__Product_Configuration__c = bundleXtendPC1.Id));

        insert testAttributes;

        List<cscfga__Attribute_Field__c> testAttributeFields = new List<cscfga__Attribute_Field__c>();
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(0).Id, cscfga__Value__c = 'someTestValue0'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(1).Id, cscfga__Value__c = 'someTestValue1'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(2).Id, cscfga__Value__c = 'someTestValue2'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(3).Id, cscfga__Value__c = 'someTestValue3'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(4).Id, cscfga__Value__c = 'someTestValue4'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(5).Id, cscfga__Value__c = 'someTestValue5'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(6).Id, cscfga__Value__c = 'someTestValue6'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(7).Id, cscfga__Value__c = 'someTestValue7'));
        testAttributeFields.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes.get(8).Id, cscfga__Value__c = 'someTestValue8'));
        insert testAttributeFields;

        /*
         * Digital PC Attributes
         */
        List<cscfga__Attribute__c> testAttributes2 = new List<cscfga__Attribute__c>();
        testAttributes2.add(new cscfga__Attribute__c(name = 'Description',
                                                    cscfga__Value__c = 'Test Description Attribute',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Date Range',
                                                    cscfga__Value__c = '1/1/2014 - 1/3/2014 (25 Insertions)', 
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Price',
                                                    cscfga__Value__c = '1234',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Product Groups for IO',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Total Number',
                                                    cscfga__Value__c = '100',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Product Groups For Investment Summary',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'HTML IS',
                                                    cscfga__Value__c = '2018-03-23',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Digital Product Name',
                                                    cscfga__Value__c = 'Example Digital Product Name',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes2.add(new cscfga__Attribute__c(name = 'Publication State',
                                                    cscfga__Value__c = 'Publication State',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        insert testAttributes2;

        List<cscfga__Attribute_Field__c> testAttributeFields2 = new List<cscfga__Attribute_Field__c>();
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(0).Id, cscfga__Value__c = 'someTestValue0'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(1).Id, cscfga__Value__c = 'someTestValue1'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(2).Id, cscfga__Value__c = 'someTestValue2'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(3).Id, cscfga__Value__c = 'someTestValue3'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(4).Id, cscfga__Value__c = 'someTestValue4'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(5).Id, cscfga__Value__c = 'someTestValue5'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(6).Id, cscfga__Value__c = 'someTestValue6'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(7).Id, cscfga__Value__c = 'someTestValue7'));
        testAttributeFields2.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes2.get(8).Id, cscfga__Value__c = 'someTestValue8'));
        insert testAttributeFields2;

       /*
         * Print PC Attributes
         */
        List<cscfga__Attribute__c> testAttributes3 = new List<cscfga__Attribute__c>();
        testAttributes3.add(new cscfga__Attribute__c(name = 'Description',
                                                    cscfga__Value__c = 'Test Description Attribute',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Date Range',
                                                    cscfga__Value__c = '1/1/2014 - 1/3/2014 (25 Insertions)', 
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Price',
                                                    cscfga__Value__c = '1234',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Product Groups for IO',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Total Number',
                                                    cscfga__Value__c = '100',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Product Groups For Investment Summary',
                                                    cscfga__Value__c = 'Landing Page',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'HTML IS',
                                                    cscfga__Value__c = '2018-03-23',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Digital Product Name',
                                                    cscfga__Value__c = 'Example Digital Product Name',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        testAttributes3.add(new cscfga__Attribute__c(name = 'Publication State',
                                                    cscfga__Value__c = 'Publication State',
                                                    cscfga__Product_Configuration__c = bundleDigitalPC1.Id));
        insert testAttributes3;

        List<cscfga__Attribute_Field__c> testAttributeFields3 = new List<cscfga__Attribute_Field__c>();
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(0).Id, cscfga__Value__c = 'someTestValue0'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(1).Id, cscfga__Value__c = 'someTestValue1'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(2).Id, cscfga__Value__c = 'someTestValue2'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(3).Id, cscfga__Value__c = 'someTestValue3'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(4).Id, cscfga__Value__c = 'someTestValue4'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(5).Id, cscfga__Value__c = 'someTestValue5'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(6).Id, cscfga__Value__c = 'someTestValue6'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(7).Id, cscfga__Value__c = 'someTestValue7'));
        testAttributeFields3.add(new cscfga__Attribute_Field__c(name = 'testAF', cscfga__Attribute__c = testAttributes3.get(8).Id, cscfga__Value__c = 'someTestValue8'));
        insert testAttributeFields3;


    }

    public static TestMethod void testBasics() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();

    }
   
    public static TestMethod void testBasics_Social() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }

    public static TestMethod void testBasics_Display() {    

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }

    public static TestMethod void testBasics_Search() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }
 
    public static TestMethod void testBasics_Email() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }

    public static TestMethod void testBasics_LP() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }

    public static TestMethod void testBasics_CL() {
        
        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }
 
    public static TestMethod void testBasics_DO() {  

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');

        testCtrl.getCampaignElements();

        Boolean testFlag;
        testFlag = testCtrl.DisplayISSummaryFlag;
        testFlag = testCtrl.SocialISSummaryFlag;
        testFlag = testCtrl.SearchISSummaryFlag;
        testFlag = testCtrl.CampaignISSummaryFlag;
        testFlag = testCtrl.LandingISSummaryFlag;
        testFlag = testCtrl.EmailISSummaryFlag;
        Test.stopTest();
    }
    
    public static TestMethod void testBasicsNull() {

        Test.startTest();
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c where csmso__Status__c  = 'Manually Approved' LIMIT 1];

        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));

        System.assertNotEquals(null,testCtrl.getInsertions(),'List of String Lists should not be null');
        Test.stopTest();
    }
    
    /*
    public static TestMethod void getColTest() {
        csmso__Sales_Order__c so = new csmso__Sales_Order__c();
        InsertionOrderController testCtrl = new InsertionOrderController(new ApexPages.StandardController(so));
        testCtrl.getColumns();
    }*/
}