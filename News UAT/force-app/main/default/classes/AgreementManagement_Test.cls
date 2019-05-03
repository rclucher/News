/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest(SeeAllData=true)
private class AgreementManagement_Test 
{

    static testMethod void agreementExpirationMessageTest() 
    {
    	Agreement__c agree = new Agreement__c(	Name='Test Agreement',
    											Type__c='Advertising Expenditure Agreement',
    											Status__c='Current',
    											Start_Date__c= System.today().addDays(-30),
    											End_Date__c= System.today().addDays(30));

    	insert agree;

    	List<Account> accounts = TestDataFactory.createAccounts(1,false);
    	insert accounts;
   		
   		List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
   		insert contacts;

   		Account_Agreement_Relationship__c aagree = new Account_Agreement_Relationship__c(Agreement__c=agree.id,Account__c=accounts[0].id);
   		insert  aagree;

   		agree.Trigger_Send_emails_to_account_owners__c = true;
   		update agree;

      agree.Trigger_Send_emails_for_QTR_Review_AMs__c = true;
      update agree;

    }
    
}