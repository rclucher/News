/* test class for AccountReportBatch*/
@isTest
public class AccountReportBatchTest {
	static public List<Product2> products;
    static public List<Pricebook2> pricebooks;
    static public List<PricebookEntry> pricebookEntries;
@testSetup static void prepareTest() {
		List<Account> accts = TestDataFactory.createAccounts(1, false);
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, acct);
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        insert oppties;

        // setupProductData();
         products = TestDataFactory.createProducts(1);
        // create pricebooks
        pricebooks = TestDataFactory.createCustomPricebookData();
        pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        
        oppties[0].StageName = 'Closed Won';
        oppties[0].closeDate = System.today();
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        update oppties;


       Opportunity opp = [select id,StageName from Opportunity where StageName='Closed Won'];
      
}
@isTest static void runTest() {
        Test.startTest();

        AccountReportBatch obj = new AccountReportBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
	}


}