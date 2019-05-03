/************************************************************************
/* class GeneraWebserviceLiteStub_Test
 * Company: Salesforce.com
/* description: test class for GeneraWebserviceLiteStub
/* date: 22/05/2013
/* author: Celso de Souza
/************************************************************************/
@isTest
private class GeneraWebserviceLiteStub_Test {

    static testMethod void generaLoginTest() {      
        Test.setMock(WebServiceMock.class, new GeneraWebserviceLoginMock());
        GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws = new  GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ();
        ws.timeout_x = 2000;
        ws.outputHttpHeaders_x = new Map<String, String>();

        ws.login();

    }


    static testMethod void generaCreateAccountTest() {

        Test.setMock(WebServiceMock.class, new GeneraWebserviceCreateAccountMock());
        GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws = new  GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ();
        ws.timeout_x = 2000;
        ws.outputHttpHeaders_x = new Map<String, String>();

        GeneraWebserviceLiteStub.AccountInfo accInfo = new GeneraWebserviceLiteStub.AccountInfo();

        accInfo.Country              = 'Australia';
        accInfo.CustomerName         = 'John Doe';
        accInfo.CustomerTitle        = 'Mr';
        accInfo.EmailAddress         = 'EmailAddress';
        accInfo.IsNew                = True;
        accInfo.Postcode             = '2000';
        accInfo.RefundTotal          = 0.0;
        accInfo.State                = 'NSW';
        accInfo.Street1              = '2 Holt st';
        accInfo.Street2              = '';
        accInfo.Suburb               = 'Hurstville';
        accInfo.TelephoneAreaCode    = '02';
        accInfo.TelephoneCountryCode = '+61';
        accInfo.TelephoneLocalNumber = '97786765';

        ws.createAccount(accInfo);

    }

    static testMethod void generaSaveAccountTest() {
        Test.setMock(WebServiceMock.class, new GeneraWebserviceSaveAccountMock());
        GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws = new  GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ();
        ws.timeout_x = 2000;
        ws.outputHttpHeaders_x = new Map<String, String>();

        ws.saveAccount('T1980508');
    }


    static testMethod void generaLogoutTest() {
        Test.setMock(WebServiceMock.class, new GeneraWebserviceLogoutMock());
        GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws = new  GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ();
        ws.timeout_x = 2000;
        ws.outputHttpHeaders_x = new Map<String, String>();


        ws.logout();

    }
 

    //checks if GUID is being retrive from the right place
     @isTest static void testGetEndpoint() {
        SystemParameters__c sp = new SystemParameters__c();
        sp.Name = 'GeneraWS_endpoint';
        sp.Value__c = '1234567890';
        sp.External_Id__c = '1234';
        insert sp;
        GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws = new  GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ();
        String endpointURL = ws.endpointURL;
        System.assertEquals(endpointURL,'1234567890');
    }

}