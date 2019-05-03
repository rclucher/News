/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Bluewolf.com
 * Description: This is the test class for SmartTemplateLoader class
 * History:
 *
 * 2015-11-30  Atul Gupta  Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - SmartTemplateLoader   100%
 ---------------------------------------------------------*/
@isTest
private class TestSmartTemplateLoader {

    static testMethod void testChooseTemplate() {
        
        Sales_Order__c salesOrd = TestDataFactory.createSalesOrder('Source System Test');
        salesOrd.Booking_Division__c = 'GAD';
        update salesOrd;
        
        String notAgencyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
    	List<Account> accList = TestDataFactory.createAccounts(1, notAgencyRT);
    	insert accList;
    	
		String caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
    	Case singleCase = TestDataFactory.createSingleCase(caseRT, accList[0].Id);
    	singleCase.Sales_Order__c = salesOrd.Id;
    	insert singleCase;
    	
    	SmartTemplateLoader templateLoader = new SmartTemplateLoader();
    	
    	Id actualTemplateId = templateLoader.getDefaultEmailTemplateId(singleCase.Id);
    	
    	EmailTemplate expectedTemplate = [SELECT id FROM EmailTemplate WHERE DeveloperName = 'Ad_Proofing_GAD'];
        Id expectedTemplateId = expectedTemplate.Id;
        System.assertEquals(actualTemplateId, expectedTemplateId);
    	
    }
}