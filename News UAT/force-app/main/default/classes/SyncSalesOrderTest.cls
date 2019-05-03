/**
 * Created by petar.mikic on 15/10/2018.
 */

@isTest public class SyncSalesOrderTest {
    @testSetup static void setup() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        soApi.csmso__Line_Item_Fields_CSV__c = 'cscfga__Description__c,One_Off_Price__c';
        insert soApi;

        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [
                SELECT Name, Id
                FROM RecordType
                WHERE sObjectType = 'Account' AND
                Name = 'Prospecting Account'
                AND isActive = true
        ];
        acc.RecordTypeId = rtypes.Id;
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.Campaign_Start_Date__c = System.today();
        so.csmso__Status__c = 'Draft';
        insert so;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
    }


    @isTest static void testSync() {
        csmso__Sales_Order__c SO = [Select Id from csmso__Sales_Order__c LIMIT 1];

        Test.startTest();
        SyncSalesOrder syncObject = new SyncSalesOrder();
        syncObject.performAction(String.valueOf(SO.id));

        SyncSalesOrder.SyncSalesOrderException testSOrderException = new SyncSalesOrder.SyncSalesOrderException();
        Test.stopTest();
    }
}