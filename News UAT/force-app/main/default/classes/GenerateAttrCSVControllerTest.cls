@isTest(seeAllData=false)
public class GenerateAttrCSVControllerTest {

    @isTest
    public static void createGroup() {
            csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
            insert soApi;

            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            insert acc;
            
            Contact con = TestDataSetupClass.createContact(acc);
            insert con;
            
            Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
            insert opp;
            
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        
            so.Margin__c = 0.3;
            insert so;
            
            cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
            insert prodBasket;
        
            cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
            insert testProdCateg;
        
            cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
            insert testProDef;
        
            cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
            prodConfig.cscfga__Configuration_Status__c ='Valid';
            prodConfig.cscfga__Product_Definition__c = testProDef.id;
            insert prodConfig;
                    
            cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
            //testAttrDef.cscfga__configuration_output_mapping__c = 'test';
            insert testAttrDef;
            
            cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
            testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;   
            //testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
            testAttr1.cscfga__Value__c = '1000';
            testAttr1.Name = 'Product Groups For IO';
            insert testAttr1;   

            Test.startTest();
            PageReference pageRef = Page.DownloadCSV;
            Test.setCurrentPage(pageRef);
            //pageRef.getParameters().put('soId', so.Id);
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(so);
			ApexPages.currentPage().getParameters().put('Id',so.id);
            GenerateAttrCSVController  testcontroller = new GenerateAttrCSVController(sc);
            String str = so.Id;
            testcontroller.csvFileData = 'testfilename';
            testcontroller.prepareCSVFileData();
        	testcontroller.attachNewFile();                   
            Test.stopTest();
        
        }
}