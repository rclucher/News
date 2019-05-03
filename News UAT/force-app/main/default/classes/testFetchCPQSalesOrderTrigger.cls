/*---------------------------------------------------------
 * Author: Logabalakrishnan (LBK) Muthukrishnan
 * Company: News
 * Description: 
 * 1. This test class is for requirement: R-NNNN.
 *              The purpose of this test class is to code cover the trigger FetchCPQSalesOrderTrigger. 
 * History:
 * 2018-03-08	LBK		Created (Code coverage achieved - 100%)
 ---------------------------------------------------------*/
@IsTest (SeeAllData=true)
public class testFetchCPQSalesOrderTrigger{
    static testmethod void testFetchSalesOrderTrigger() {      
    
        Account objTestAccount = new Account();
        objTestAccount.Name = 'Test account 27';
        objTestAccount.No_Parent_Account__c = true;
        insert objTestAccount;
        
        Opportunity objTestOpportunity = new Opportunity();
        //objTestOpportunity.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'KAC' LIMIT 1].Id;
        objTestOpportunity.Name = 'Test Opp 27';
        objTestOpportunity.Amount = 1000;
        objTestOpportunity.AccountId = objTestAccount.Id;
        objTestOpportunity.CloseDate = System.today();
        objTestOpportunity.StageName = 'Discover Needs';
        insert objTestOpportunity;
        
        csmso__Sales_Order__c objSalesOrder = new csmso__Sales_Order__c ();
        objSalesOrder.csmso__Opportunity__c = objTestOpportunity.Id;
        objSalesOrder.csmso__Advertiser__c	= objTestAccount.Id;
        insert objSalesOrder;
        //objSalesOrder
        //csmso__Sales_Order__c objSalesOrder = [SELECT Id, csmso__Opportunity__c, csmso__Opportunity__r.AccountId FROM csmso__Sales_Order__c ORDER BY CreatedDate DESC LIMIT 1];
        
        Case objCase = new Case();
        objCase.Subject = 'Test case';
        objCase.Description = 'Test Descr';
        objCase.AccountId = objSalesOrder.csmso__Opportunity__r.AccountId;
        objCase.Opportunity__c = objSalesOrder.csmso__Opportunity__c;
        objCase.Priority = 'Medium';
        objCase.Type = 'Other';
        insert objCase;
    }
}