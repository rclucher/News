/************************************************************************
/* class CalloutABNLookupController_Test
/* description: test class for CalloutABNLookupController
 * Company: Salesforce.com
 * 20/05/2013   Celso de Souza   Created
 * 13/06/2013   Bohao Chen       Updated
/************************************************************************/
@isTest
private class CalloutABNLookupController_Test {

    static testMethod void abnLookupTest() {
        PageReference pageRef = Page.CalloutABNLookup;
        Test.setCurrentPage(pageRef);
        Apexpages.currentPage().getParameters().put('abn','47007871178');
 
 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');


        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock); 
        
        CalloutABNLookupController ctr = new CalloutABNLookupController();
        ctr.doABNLookup();
        
        ABNLookupStub.AustralianBusinessNumber abn = ctr.abn;
        System.assert(abn.isActive);
        
    }
    
     static testMethod void abnLookupinvalidTest() {
        PageReference pageRef = Page.CalloutABNLookup;
        Test.setCurrentPage(pageRef);
        Apexpages.currentPage().getParameters().put('abn','12345678901');
 
 
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseNotFoundSample');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');


        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock); 
        
        CalloutABNLookupController ctr = new CalloutABNLookupController();
        ctr.doABNLookup();
        
        
    }   
    
}