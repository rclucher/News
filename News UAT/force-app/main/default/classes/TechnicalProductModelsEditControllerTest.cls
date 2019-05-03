/**
 * Created by petar.mikic on 15/10/2018.
 */
@isTest(seeAllData=false)
public with sharing class TechnicalProductModelsEditControllerTest {

    @testSetup static void setup() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        soApi.csmso__Line_Item_Fields_CSV__c = 'cscfga__Description__c,One_Off_Price__c';
        insert soApi;

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
        so.csmso__Status__c = 'Draft';
        insert so;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;

        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;

        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;

        MLE_Tab_Product_Association__c mlePDAssoc = new MLE_Tab_Product_Association__c(Name = 'Test', Associated_Product_Definition__c = testProDef.Id);
        insert mlePDAssoc;

    }

    @isTest public static void testMleTabProductModelPage() {

        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];


        Test.startTest();
        PageReference pageRef = Page.MleTabProductModel;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('salesOrderId',so.id);

        ApexPages.StandardController sc = new ApexPages.standardController(so) ;
        TechnicalProductModelsEditController controller = new TechnicalProductModelsEditController();
        controller.refreshPrintFields();
        controller.getHasPrintDisplay();
        controller.logger('Testing logger');

        Test.stopTest();
    }

}