/************************************************************************
/* class ABNLookupStub_Test
/* description: test class for ABNLookupStub
/* Company: Salesforce.com
/* date: 20/05/2013
/* author: Celso de Souza
/************************************************************************/
@isTest
private class ABNLookupStub_Test {

    //Case request from a valid ABN
    @isTest static void testCalloutValid() {

        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        //mock.setStaticResource('WSSampleResponses/ABNLookupResponseSample.xml');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/xml');



        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ABNLookupStub.AustralianBusinessNumber validABN = ABNLookupStub.ABRSearchByABN('47007871178');
        System.assert(validABN.isActive);


    }

    //Case request for an invalid ABN
    @isTest static void testCalloutNotValid() {

        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample



        StaticResourceCalloutMock mockNotFound = new StaticResourceCalloutMock();
        mockNotFound.setStaticResource('ABNLookupResponseNotFoundSample');
        mockNotFound.setStatusCode(200);
        mockNotFound.setHeader('Content-Type', 'application/xml');

         Test.setMock(HttpCalloutMock.class, mockNotFound);

        ABNLookupStub.AustralianBusinessNumber invalidABN = ABNLookupStub.ABRSearchByABN('12345678901');
        System.assert(invalidABN.isInvalid);
    }

    //Case request can not reach end point
    @isTest static void testCalloutNotReacheable() {

        //  StaticResourceCalloutMock built-in class to
        // specify fake response and include response body
        // in the staic resource ABNLookupResponseSample
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ABNLookupResponseSample');
        mock.setStatusCode(404);
        mock.setHeader('Content-Type', 'application/xml');


        Test.setMock(HttpCalloutMock.class, mock);
        
        /*Added try catch for cacthing new exception thrown from ABNLookupStub (a per Bohao's fix on 13/May/2014 for JIRA SFE-242
        Added by: LMancilla **/
        try{
            ABNLookupStub.AustralianBusinessNumber notReacheableABN = ABNLookupStub.ABRSearchByABN('47007871178');
        }catch(Exception e){
            System.assert( e.getMessage().contains('Unable to get validation result. Status code is'),e.getMessage() );        
        }
        //System.assert(notReacheableABN==null);
    }

    //checks if GUID is being retrive from the right place
     @isTest static void testGetGUID() {
        SystemParameters__c sp = new SystemParameters__c();
        sp.Name = 'ABR_GUID';
        sp.Value__c = '1234567890';
        sp.External_Id__c = '1234';
        insert sp;
        String GIUD = ABNLookupStub.GUID;
        System.assertEquals(GIUD,'1234567890');
    }



}