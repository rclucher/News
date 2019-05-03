@isTest(seeAllData=false)
public with sharing class container_tag_test
{

    static testMethod void test()
    {
        // Set up test data
        Account sAccount = TestDataSetupClass.createAccount();
        insert sAccount;

        Contact sContact = TestDataSetupClass.createContact(sAccount);
        insert sContact;

        Opportunity sOpportunity = TestDataSetupClass.createOpportunity(sAccount, sContact);
        insert sOpportunity;
        
         Briefing_Form__c b = new Briefing_Form__c();
        b.Status__c = 'Test';
        insert b;
        
        Order__c sOrder = TestDataSetupClass.createOrder(sOpportunity);
        insert sOrder;
        sOrder.Briefing_Form__c = b.id;
        sOrder.Opportunity__c = sOpportunity.id;
        update sOrder;
              
        //ApexPages.StandardController ctr = new ApexPages.StandardController(sOrder);
        
        //PageReference pageRef = new ApexPages.StandardController(sOrder).view();
        //pageRef.getParameters().put('id', String.valueOf(sOrder.Id));
        //test.setCurrentPage(pageRef);
        
        // Start the test
        test.startTest();
        
        // Instantiate the controller
        //container_tag controller = new container_tag(ctr);

        //Pagereference pageRefOut =
              
        ApexPages.StandardController controller = new ApexPages.StandardController(sOrder);
        container_tag ctag = new container_tag(controller);
        ctag.executeContainerLogic();
        // Stop the test and inspect the results
        test.stopTest();
        
        
    }       




}