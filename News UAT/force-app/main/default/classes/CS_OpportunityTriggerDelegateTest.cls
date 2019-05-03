@isTest
private class CS_OpportunityTriggerDelegateTest {
    
    @isTest static void test_insert() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);

        Test.startTest();

        insert opp;

        Test.stopTest();
    }

    @isTest static void test_update() {
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup'
        );
        insert template;
        Industry_Code__c ic = new Industry_Code__c ();
        insert ic;

        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = '7010';
        payerAcc.Is_Digital__c = true;
        payerAcc.Digital_Status__c = 'Active';
        payerAcc.Industry_Code__c = ic.Id;
        insert payerAcc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        opp.OpportunityGroup__c = 'NewsXtend';
        opp.Payer_Account__c = payerAcc.Id;
        insert opp;



        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Manually Approved';
        so.csmso__Total_Price__c  = 2500;
        so.One_Off_Price__c = 0;
        so.Platform_Set__c = '{Xtend}';
        insert so;

        List<Product2> products = TestDataFactory.createProducts(1);
        
        // create pricebooks
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        Id stdPricebookId = Test.getStandardPricebookId();

        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp},
                products, pricebookEntries, null);
        insert olis;

        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;

        Test.startTest();

        opp.StageName = 'Closed Won';
        opp.Classification__c = 'Great';
        opp.Competitor__c = 'competitor';
        opp.Description = 'Great';
        opp.Has_an_Approved_SO__c = true;
        opp.Briefing_Form__c = briefingForm.Id;
        opp.Campaign_Brief_Form_Completed__c = true;
        update opp;

        Test.stopTest();
    }
}