@isTest(seeAllData=false)
public class OpportunitySalesOrderIntegrationTest {

     @isTest 
    public static void testBasics(){
         Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        insert so;
        so.csmso__Status__c = 'Draft';
        
        Test.startTest();
        PageReference pageRef = Page.Opp2SalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(opp) ;
        OpportunitySalesOrderIntegration controller = new OpportunitySalesOrderIntegration(sc);        
        ApexPages.currentPage().getParameters().put('id',opp.id);
        controller.generateSalesOrder();
    }
}