/************************************************************************
/* class CalloutABNLookup_Controller_Test
/* description: test class for CalloutABNLookup_ControllerX
 * Company: Salesforce.com
 * 24/05/2013   Celso de Souza   Created
 * 11/06/2013   Bohao Chen       Updated
 * 23/05/2018   David Scullion   Updated - News Limited to News PTY Limited
/************************************************************************/
@isTest
private class CalloutABNLookup_ControllerX_Test 
{
    //Case 1: blank ABN test
    static testMethod void abnBlankLookupTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        Test.startTest();
        
        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        PageReference abnLookupPage = Page.CalloutABNLookup;
        Test.setCurrentPage(abnLookupPage);
            
        ApexPages.StandardController ctr = new ApexPages.StandardController(accounts[0]);
        CalloutABNLookup_ControllerX abnLookupPageCtr = new CalloutABNLookup_ControllerX(ctr);
        
        abnLookupPageCtr.validateAbn();
        
        Test.stopTest();
    }
    
    // Case 2: valid ABN
    static testMethod void abnValidLookupTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        accounts[0].AccountNumber = '47 007 871 178';
        update accounts[0]; 
        
        Test.startTest();
        
        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        
        PageReference abnLookupPage = Page.CalloutABNLookup;
        Test.setCurrentPage(abnLookupPage);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(accounts[0]);
        CalloutABNLookup_ControllerX abnLookupPageCtr = new CalloutABNLookup_ControllerX(ctr);
            
        abnLookupPageCtr.validateAbn();
        
        system.assertEquals('47 007 871 178', accounts[0].AccountNumber);
        system.assertEquals('NEWS PTY LIMITED', accounts[0].Registered_Name__c);
        system.assertEquals('Active', accounts[0].ABN_Status__c);
        system.assertEquals(Date.today(), accounts[0].ABN_Validation__c);
        
        Test.stopTest();
    }

    // Case 3: invalid ABN test
    static testMethod void abnInvalidLookupTest() 
    {
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        accounts[0].AccountNumber = '47 007 871 176';
        update accounts[0]; 
        
        Test.startTest();
        
        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        
        PageReference abnLookupPage = Page.CalloutABNLookup;
        Test.setCurrentPage(abnLookupPage);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(accounts[0]);
        CalloutABNLookup_ControllerX abnLookupPageCtr = new CalloutABNLookup_ControllerX(ctr);
            
        abnLookupPageCtr.validateAbn();
        
        system.assertEquals('47 007 871 176', accounts[0].AccountNumber);
        system.assertEquals(null, accounts[0].Registered_Name__c);
        system.assertEquals('Invalid ABN Number', accounts[0].ABN_Status__c);
        system.assertEquals(Date.today(), accounts[0].ABN_Validation__c);
        
        Test.stopTest();
    }

    //
    static testMethod void auraEnabledValidateABNTest() {
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;

        Account acct = accounts[0];
        acct.AccountNumber = '47 007 871 178';
        update acct; 

        Test.startTest();

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Account updatedAcct = CalloutABNLookup_ControllerX.ValidateABN(acct.Id);

        system.assertEquals('47 007 871 178', updatedAcct.AccountNumber);
        system.assertEquals('NEWS PTY LIMITED', updatedAcct.Registered_Name__c);
        system.assertEquals('Active', updatedAcct.ABN_Status__c);
        system.assertEquals(Date.today(), updatedAcct.ABN_Validation__c);

        Test.stopTest();
    }



}