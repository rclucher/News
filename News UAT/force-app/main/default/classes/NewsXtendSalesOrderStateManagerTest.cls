@isTest(seeAllData=false)
public class NewsXtendSalesOrderStateManagerTest {

    @isTest 
    public static void validateChangeTest(){
        
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
        NewsXtendSalesOrderStateManager nxsomClass = new NewsXtendSalesOrderStateManager();
        nxsomClass.validateChange(so);
        Test.stopTest();
    }
    
    @isTest 
    public static void validateChange_DraftTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact contact = TestDataSetupClass.createContact(acc);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c      = 'Draft';
		so.Basket_Products__c = 'Print Display';
		so.Platform_Set__c = 'Xtend,Print'; //dummy values to trigger the logic
		so.OwnerId = UserInfo.getUserId();//set owner in memory instead of query
		
        Test.startTest();
        NewsXtendSalesOrderStateManager nxsomClass = new NewsXtendSalesOrderStateManager();
        nxsomClass.getFieldAttributesForSalesOrder(so);
        Test.stopTest();
    }
    
     @isTest 
    public static void validateChange_NotDraftTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact contact = TestDataSetupClass.createContact(acc);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c      = 'Sent For Internal Approval';
		so.Basket_Products__c = 'Print Display';
		so.Platform_Set__c = 'Xtend,Print'; //dummy values to trigger the logic
        insert so;
        so.OwnerId = UserInfo.getUserId();//set owner in memory instead of query
        Test.startTest();
        NewsXtendSalesOrderStateManager nxsomClass = new NewsXtendSalesOrderStateManager();
        nxsomClass.getFieldAttributesForSalesOrder(so);
        Test.stopTest();
    }
	
	/**
	 * Same as validateChange_NotDraftTest but ran as non Opp owner user
	 * @type {[type]}
	 */
	@isTest
	public static void validateChange_NotDraftTestNotOwner(){
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User user = new User(Alias = 'newUser', Email = 'newuser@testorg.com',
							 EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
							 LocaleSidKey = 'en_US', ProfileId = p.Id,
							 TimeZoneSidKey = 'Australia/Sydney', UserName = 'testuserforcallout@testorg.com');
		insert user;
		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact contact = TestDataSetupClass.createContact(acc);
		insert contact;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
		insert opp;
		//create approver record
		CPQ_Approver__c cpqApp = new CPQ_Approver__c(
			Platform__c = 'Print',
			Sales_Rep__c = UserInfo.getUserId(),
			L1_Approver__c = user.Id,
			L2_Approver__c = user.Id,
			L3_Approver__c = user.Id,
			L4_Approver__c = null);
		insert cpqApp;
		
		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.csmso__Status__c = 'Sent For Internal Approval';
		so.Basket_Products__c = 'Print Display';
		so.Platform_Set__c = 'Xtend,Print'; //dummy values to trigger the logic
		insert so;
		//populate some values in memory as state manager class needs them, easier than query
		opp.OwnerId = UserInfo.getUserId();
		so.csmso__Opportunity__r = opp;
		so.OwnerId = UserInfo.getUserId();//set owner in memory instead of query
		
		Test.startTest();
		NewsXtendSalesOrderStateManager nxsomClass = new NewsXtendSalesOrderStateManager();
		System.runAs(user) {
			nxsomClass.getFieldAttributesForSalesOrder(so);
		}
		Test.stopTest();
	}
}