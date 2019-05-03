@isTest
public class AT_CreateAccount_Test {
    @testSetup
    static void init() {
        datasan__Setting__c setting = new datasan__Setting__c(datasan__Key__c = '12345', datasan__Available_SOTs__c = 'AUPAF,GNAF,NZPAF');
        
        insert setting;
    }
    
    class MockAddressCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse resp = new HTTPResponse();
            
            resp.setStatusCode(200);
            resp.setBody('{ "status": "SUCCESS", "messages": [], "payload": [ { "fullAddress": "DARLING PARK, 201 SUSSEX ST, SYDNEY NSW 2000", "country": null, "postcode": "2000", "street2": null, "street": "SUSSEX ST", "streetNumber": "201", "postal": "", "postalType": "", "postalNumber": "", "buildingName": "DARLING PARK", "subdwelling": "", "eid": "B568F02A5339682B937C7FD3AB25265040199310344117E6", "lotNumber": "", "flatUnitNumber": "", "flatUnitType": "", "floorLevelNumber": "", "floorLevelType": "", "streetSuffix": "", "streetType": "ST", "streetName": "SUSSEX", "attributes": { "Barcode": "1301013021222201001120332100223120013", "Bsp": "015", "DPID": "97881046" }, "id": "97881046", "exception": null, "locality": "SYDNEY", "state": "NSW" } ]}');
            
            return resp;
        }
    }
    
	@isTest
    static void testRecordTypes() {
        List<AT_RecordTypeUtil.RecordTypeInfo> rts = AT_CreateAccount.getRecordTypes();
            
        System.assert(rts.size() > 0, 'No record types returned');
    }
    
    @isTest
    static void testDuplicates() {
        Account acc = new Account(Name = 'test', AccountNumber = '82608534952', No_Parent_Account__c = true);
        
        insert acc;
        
        List<AT_CreateAccount.ExistingAccount> existing = AT_CreateAccount.duplicateCheck('test', null, null, null, null, null, null);
        
        System.assertEquals(1, existing.size(), 'Should find one existing account');
        
        existing = AT_CreateAccount.duplicateCheck(null, '82608534952', null, null, null, null, null);
        
        System.assertEquals(1, existing.size(), 'Should find one existing account');
        
        existing = AT_CreateAccount.duplicateCheck('test', '82608534952', null, null, null, null, null);
        
        System.assertEquals(1, existing.size(), 'Should find one existing account');
        
        existing = AT_CreateAccount.duplicateCheck('test2', null, null, null, null, null, null);
        
        System.assertEquals(0, existing.size(), 'Should not find any existing account');
        
        existing = AT_CreateAccount.duplicateCheck(null, '123456789012', null, null, null, null, null);
        
        System.assertEquals(0, existing.size(), 'Should not find any existing account');
        
        existing = AT_CreateAccount.duplicateCheck('test2', '123456789012', null, null, null, null, null);
        
        System.assertEquals(0, existing.size(), 'Should not find any existing account');
    }
    
    @isTest
    static void testAddressLookup() {
        Test.setMock(HttpCalloutMock.class, new MockAddressCallout());
        
        Test.startTest();
        
        AT_CreateAccount.lookupAddress('test address', 'AUPAF');
        
        Test.stopTest();
    }
    
    @isTest
    static void testABNLookup() {
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

        Test.startTest();
        
        AT_CreateAccount.AccountInfo validABN = AT_CreateAccount.lookupABN('47007871178');
        
        Test.stopTest();
        
        System.assert(validABN.isActive);
    }
    
    @isTest
    static void checkAccessForNextGenUser() {
        Set<String> nextgenProfiles = new Set<String>();
        
        for (NextGen_User_Profile__mdt nup : [SELECT Label FROM NextGen_User_Profile__mdt]) {
            nextgenProfiles.add(nup.Label);
        }
        
        User nextgenUser = [SELECT Id FROM User WHERE (Profile.Name IN :nextgenProfiles) AND (IsActive = true) LIMIT 1];
        
        System.runAs(nextgenUser) {
            Test.startTest();
            
            ApexPages.StandardController controller = new ApexPages.StandardController(new Account());
            
            AT_CreateAccount createAcc = new AT_CreateAccount(controller);
            
            PageReference ref = createAcc.checkAccess();
            
            System.assertEquals(null, ref, 'Should not redirect user to anywhere else');
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void checkAccessForNonNextGenUser() {
        Set<String> nextgenProfiles = new Set<String>();
        
        for (NextGen_User_Profile__mdt nup : [SELECT Label FROM NextGen_User_Profile__mdt]) {
            nextgenProfiles.add(nup.Label);
        }
        
        User nonNextgenUser = [SELECT Id FROM User WHERE (Profile.Name = 'News Campaign Coordinator') AND (IsActive = true) LIMIT 1];
        
        System.runAs(nonNextgenUser) {
            Test.startTest();
            
            ApexPages.StandardController controller = new ApexPages.StandardController(new Account());
            
            AT_CreateAccount createAcc = new AT_CreateAccount(controller);
            
            PageReference ref = createAcc.checkAccess();
            
            System.assertNotEquals(null, ref, 'Should redirect user to standard new account screen');
            
            Test.stopTest();
        }
    }
}