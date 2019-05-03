/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2016-01-14  Atul Gupta Updated
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - ExternalAccountCreateBA_Controller 81%
    //  - AccountManagement_Trigger_Helper   100%
 */
@isTest
private class ExternalAccountCreateBA_Ctr_Test {
	
	static testMethod void externalforAccountRT_Agency_Account_Type(){
		
		
		list<CyberAd_User_Credential__c> cyberList = TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
		
		String agencyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency Account').getRecordTypeId();
    	List<Account> accList = TestDataFactory.createAccounts(1, agencyRT);
    	insert accList;
		
		ApexPages.StandardController sc = new ApexPages.StandardController(accList[0]);
        
        ExternalAccountCreateBA_Controller externalAcct = new ExternalAccountCreateBA_Controller(sc);
        
    	PageReference pg = new PageReference('/apex/ExternalAccountCreateBookingAccount');
        pg.getParameters().put('acctId', accList[0].Id);
        
        Test.setCurrentPage(pg); 
        
        //assert statement to check if the account id is set properly
        system.assertEquals(pg.getParameters().get('acctId'), accList[0].Id);
        
        externalAcct.bookingType = 'InDirect';
        externalAcct.getIsIndirect();
        
        //assert if getIsIndirect is true
        system.assertEquals(externalAcct.getIsIndirect(), true);
        
        externalAcct.ExternalAccountInitCreateBookingAccount();
        externalAcct.onBookingTypeChange();
        externalAcct.onPayerChange();
        externalAcct.doCancelAndRedirectToSource();
        externalAcct.getGBATypes();
	}
	
	static testMethod void externalforAccountRT_NOT_Agency_Account_Type(){
		
		list<CyberAd_User_Credential__c> cyberList = TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
		String notAgencyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
    	List<Account> accList = TestDataFactory.createAccounts(1, notAgencyRT);
    	
    	insert accList;

    	PageReference pg = new PageReference('/apex/ExternalAccountCreateBookingAccount');
        pg.getParameters().put('acctId', accList[0].Id);
        
        Test.setCurrentPage(pg); 
        
        //assert statement to check if the account id is set properly
        system.assertEquals(pg.getParameters().get('acctId'), accList[0].Id);
        
        ExternalAccountCreateBA_Controller externalAcct = new ExternalAccountCreateBA_Controller();

        externalAcct.bookingType = 'InDirect';
        externalAcct.getIsIndirect();
        
        //assert if getIsIndirect is not false
        system.assertNotEquals(externalAcct.getIsIndirect(), false);
        
        externalAcct.ExternalAccountInitCreateBookingAccount();
        
        //assert to check if the boolean is true
        system.assertEquals(externalAcct.isCyberSellEnabled, true);
        
        externalAcct.onBookingTypeChange();
        externalAcct.onPayerChange();
        externalAcct.doCancelAndRedirectToSource();
        externalAcct.getGBATypes();
	}
	
	static testMethod void externalforAccountCase(){
		
		list<CyberAd_User_Credential__c> cyberList = TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
		
		String notAgencyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
    	List<Account> accList = TestDataFactory.createAccounts(1, notAgencyRT);
    	insert accList;
    	
		String caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
    	Case singleCase = TestDataFactory.createSingleCase(caseRT, accList[0].Id);
    	
    	insert singleCase;

    	PageReference pg = new PageReference('/apex/ExternalAccountCreateBookingAccount');
        pg.getParameters().put('caseId', singleCase.Id);
        
        Test.setCurrentPage(pg); 
        
        //assert statement to check if the account id is set properly
        system.assertEquals(pg.getParameters().get('caseId'), singleCase.Id);
        
        ExternalAccountCreateBA_Controller externalAcct = new ExternalAccountCreateBA_Controller();

        externalAcct.bookingType = 'InDirect';
        externalAcct.getIsIndirect();
        
        //assert if getIsIndirect is true
        system.assertEquals(externalAcct.getIsIndirect(), true);
        
        externalAcct.ExternalAccountInitCreateBookingAccount();
        
        //assert to check if the boolean is true
        system.assertEquals(externalAcct.isCyberSellEnabled, true);
        
        externalAcct.onBookingTypeChange();
        externalAcct.onPayerChange();
        externalAcct.doCancelAndRedirectToSource();
        externalAcct.getGBATypes();
        externalAcct.getIsDirect();
	}
	
	static testMethod void testShowSideBar(){
		

    	PageReference pg = new PageReference('/apex/ExternalAccountCreateBookingAccount');
        pg.getParameters().put('s', '123');
        
        Test.setCurrentPage(pg); 
        
        //assert statement to check if the account id is set properly
        system.assertEquals(pg.getParameters().get('s'), '123');
        
        ExternalAccountCreateBA_Controller externalAcct = new ExternalAccountCreateBA_Controller();

	}
	
	static testMethod void externalForInvalidCase(){
		
    	String invalidCaseId = '001O000000oByfD';
    	PageReference pg = new PageReference('/apex/ExternalAccountCreateBookingAccount');
        pg.getParameters().put('caseId', invalidCaseId);
        
        Test.setCurrentPage(pg); 
        
        try{
        	ExternalAccountCreateBA_Controller externalAcct = new ExternalAccountCreateBA_Controller();
        } catch(Exception ex){
        	system.assertEquals(ex.getMessage(), 'Invalid Case');
        }
	}
}