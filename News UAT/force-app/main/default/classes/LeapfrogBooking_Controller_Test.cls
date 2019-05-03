@isTest(SeeAllData=false)
private class LeapfrogBooking_Controller_Test {

    @testSetup static void setupTestData(){

        // query leapfrog permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Leapfrog_User_Permission'];

        // create user records
        List<User> users = TestDataFactory.createUsers(2, 'System Administrator', null, false, false);
        insert users;

        // assign user to permission set
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>();
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = users[0].Id; // only assign first user with this permission set
        psa.PermissionSetId = ps.Id;
        psas.add(psa);
        insert psas;

        Id businessAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        
        System.runAs(users[0]) {
            // 2017-09-20 AdSales 351 darshan.gosar@bluewolfgroup.com Added new GBA Type custom setting valye as its being user in GBA drop down query
            List<Leapfrog_Account_Types__c> tempAccTypes = new List<Leapfrog_Account_Types__c>();
            tempAccTypes.add(new Leapfrog_Account_Types__c(Name='Established', Booking_Type__c='Direct'));
            tempAccTypes.add(new Leapfrog_Account_Types__c(Name='Client of Ad Agency', Booking_Type__c='Agency'));                        
            insert tempAccTypes;
            // set default sales rep
            // treat last user in the list as default sales rep
            SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
            insert salesRep;

            // create account record
            Account acct = TestDataFactory.createSingleAccount(null, null, businessAccountRecordTypeId, null, null);
            insert acct;

            // create account record
            Account privatePartyAct = TestDataFactory.createAccounts(1, true)[0];
            insert privatePartyAct;
            
            // create contact records for account
            List<Contact> contacts = TestDataFactory.createContacts(1, acct);
            insert contacts;

            // create booking system record for account
            List<External_Account__c> externalAccounts = new List<External_Account__c>();
            External_Account__c ex = TestDataFactory.createExternalAccount(acct, 'NewsAdds_Booking_System', '1234', null, false);
            externalAccounts.add(ex);
            //gbas
            ex = TestDataFactory.createExternalAccount(acct, 'Booking_Account', '111111', null, false);
            externalAccounts.add(ex);
            ex = TestDataFactory.createExternalAccount(acct, 'Booking_Account', '000000', null, false);
            externalAccounts.add(ex);
            //netDA
            ex = TestDataFactory.createExternalAccount(acct, 'Billing_Account', '12347', null, false);
            ex.Division__c = 'National';
            ex.JDE_Account_Number__c = 'JDE123456';
            externalAccounts.add(ex);
            insert externalAccounts;
            for (External_Account__c ea : externalAccounts) {
                ea.Account_Type__c = 'Established';
            }
            
            //need to reset record type
            RecordType rt = [SELECT id from RecordType WHERE developerName = 'NewsAdds_Booking_System' AND sObjectType = 'External_Account__c' LIMIT 1];
            externalAccounts[0].RecordTypeId = rt.Id;
            rt = [SELECT id from RecordType WHERE developerName = 'Billing_Account' AND sObjectType = 'External_Account__c' LIMIT 1];
            externalAccounts[3].RecordTypeId = rt.Id;
            externalAccounts[3].Account_Type__c = 'Client of Ad Agency';
            //Set gbas
            //2018-01-12 NicD ADSALES-01104 - Addressed test class validation issue
            externalAccounts[0].BSA__c=externalAccounts[1].ID; 
            //Set netDA
            //2018-01-12 NicD ADSALES-01104 - Addressed test class validation issue
            externalAccounts[0].BSA_Net_DA__c=externalAccounts[3].ID;
            update externalAccounts;
            //System.debug('@bookingSystemAccount: ' + bookingSystemAccount);
            
           
            

            // create sales order for booking system record
            List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, acct, acct, acct, contacts[0], 'Leapfrog');
            insert salesOrders;

            // create booking for booking system record
            Booking__c booking = TestDataFactory.createBooking(salesOrders[0]);

            // create case for account
            List<Case> cases = new List<Case>();
            // case with booking
            cases.addAll(TestDataFactory.createCases(1, null, booking));
            // case without booking
            cases.addAll(TestDataFactory.createCases(1, null, null));

            insert cases;
        }
    }

    // this is to test permission checking.
    // users have valid permission only when they have been assigned to permission set 'Leapfrog_User_Permission'
    @isTest static void permissionsetTest() {

        // even though we use seealldata=false, we can still see other assignee in permission set assginment records.
        // For testing purpose, we just need to test testing users
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        //System.debug('@usersById: ' + usersById);

        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            // this user should have permission to access leapfrog system
            
            PageReference pageRef = Page.LeapfrogBooking;
            Test.setCurrentPage(pageRef);

            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();
            
            // check error message
            Boolean messageFound = false;

            for(ApexPages.Message message : ApexPages.getMessages()) {
                if(message.getDetail().contains('don\'t have permission')) {
                    messageFound = true;        
                }
            }

            System.assert(!messageFound);
        }

        System.runAs(usersById.values()[0]) {
            // this user should not have permission to access leapfrog system
            PageReference pageRef = Page.LeapfrogBooking;
            Test.setCurrentPage(pageRef);

            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            // check error message
            Boolean messageFound = false;

            for(ApexPages.Message message : ApexPages.getMessages()) {
                if(message.getDetail().contains('don\'t have permission')) {
                    messageFound = true;        
                }
            }

            System.assert(messageFound);
        }
    }

    // this is to test whether code is sending correct action type to Leapfrog booking system 
    // depends on which object the user starts the booking from.

    // this test method also tests whether confirmation window shows up based on use cases.
    // show confirmation window if booking starts from account and case record.
    // hide confirmation window if booking starts from booking and booking system account.
  /*  @isTest static void actionTypeTest() {

        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {

            // Case 1: action type should be "createOrder" when the user click "NewsAdds Booking" on the account record
            Account acct = [Select Id From Account Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();
            System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
            System.assert(leapfrogCtr.showConfirmation);

            // Case 2: action type should be "editOrder" when the user click "Goto Booking" on the booking record
            Booking__c booking = [Select Id From Booking__c Limit 1];
            pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', booking.Id);
            Test.setCurrentPage(pageRef);
            leapfrogCtr = new LeapfrogBooking_Controller();
            System.assertEquals('EditOrder', leapfrogCtr.actionTypeName);
            System.assert(!leapfrogCtr.showConfirmation);

            for(Case c : [Select Id, Booking__c From Case]) {
                // Case 3: action type should be "editOrder" when the user click "NewsAdds Booking" on the case record if booking field has value.
                //Changed to create order for FB-255
                if(c.Booking__c != NULL) {
                    pageRef = Page.LeapfrogBooking;
                    pageRef.getParameters().put('Id', c.Id);
                    Test.setCurrentPage(pageRef);
                    leapfrogCtr = new LeapfrogBooking_Controller();
                    System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
                }
                // Case 4: action type should be "createOrder" when the user click "NewsAdds Booking" on the case record if booking field is blank.
                else {
                    pageRef = Page.LeapfrogBooking;
                    pageRef.getParameters().put('Id', c.Id);
                    Test.setCurrentPage(pageRef);
                    leapfrogCtr = new LeapfrogBooking_Controller();
                    System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
                }
                System.assert(leapfrogCtr.showConfirmation);
            }

            // Case 5: action type should be "editAccount" when the user click "Manage NewsAdds Account" on the booking system account record
            External_Account__c bookingSystemAccount = [Select Id From External_Account__c Limit 1];
            pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', bookingSystemAccount.Id);
            Test.setCurrentPage(pageRef);
            leapfrogCtr = new LeapfrogBooking_Controller();
            System.assertEquals('EditAccount', leapfrogCtr.actionTypeName);
            System.assert(!leapfrogCtr.showConfirmation);
        }

    }  */
    
     @isTest static void actionTypeTest() {
        
        List<User> usersWithPermission = new List<User>();
        
        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);
        
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                           From PermissionSetAssignment 
                                           Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                           And AssigneeId IN: usersById.keySet()]) {
                                               usersWithPermission.add(usersById.get(psa.AssigneeId));
                                               usersById.remove(psa.AssigneeId);
                                           }
        
        //System.debug('@usersWithPermission: ' + usersWithPermission);
        
        System.runAs(usersWithPermission[0]) {
            
            // Case 1: action type should be "createOrder" when the user click "NewsAdds Booking" on the account record
            Account acct = [Select Id From Account Limit 1];
            LeapfrogBooking_Controller leapfrogCtr;
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            
            Test.startTest();
            leapfrogCtr = new LeapfrogBooking_Controller();
            Test.stopTest();
            System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
            System.assert(leapfrogCtr.showConfirmation);
            
            
        }
        
    }
    
    @isTest static void actionTypeEditOrderTest() {
        
        List<User> usersWithPermission = new List<User>();
        
        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);
        
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                           From PermissionSetAssignment 
                                           Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                           And AssigneeId IN: usersById.keySet()]) {
                                               usersWithPermission.add(usersById.get(psa.AssigneeId));
                                               usersById.remove(psa.AssigneeId);
                                           }
        
        //System.debug('@usersWithPermission: ' + usersWithPermission);
        
        System.runAs(usersWithPermission[0]) {
            
            
            // Case 2: action type should be "editOrder" when the user click "Goto Booking" on the booking record
            Booking__c booking = [Select Id From Booking__c Limit 1];
            LeapfrogBooking_Controller leapfrogCtr;
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', booking.Id);
            Test.setCurrentPage(pageRef);
            
            Test.startTest();
            leapfrogCtr = new LeapfrogBooking_Controller();
            Test.stopTest();
            System.assertEquals('EditOrder', leapfrogCtr.actionTypeName);
            System.assert(!leapfrogCtr.showConfirmation);
            
        }
        
    }
    @isTest static void actionTypeCreateOrderTest() {
        
        List<User> usersWithPermission = new List<User>();
        
        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);
        
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                           From PermissionSetAssignment 
                                           Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                           And AssigneeId IN: usersById.keySet()]) {
                                               usersWithPermission.add(usersById.get(psa.AssigneeId));
                                               usersById.remove(psa.AssigneeId);
                                           }
        
        //System.debug('@usersWithPermission: ' + usersWithPermission);
        
        System.runAs(usersWithPermission[0]) {
            LeapfrogBooking_Controller leapfrogCtr;
            for(Case c : [Select Id, Booking__c From Case]) {
                // Case 3: action type should be "editOrder" when the user click "NewsAdds Booking" on the case record if booking field has value.
                //Changed to create order for FB-255
                if(c.Booking__c != NULL) {
                    PageReference pageRef = Page.LeapfrogBooking;
                    pageRef.getParameters().put('Id', c.Id);
                    Test.setCurrentPage(pageRef);
                    
                    Test.startTest();
                    leapfrogCtr = new LeapfrogBooking_Controller();
                    Test.stopTest();
                    System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
                }
            }
        }
        
    }
    
    @isTest static void actionTypeCreateOrderIfNullTest() {
        
        List<User> usersWithPermission = new List<User>();
        
        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);
        
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                           From PermissionSetAssignment 
                                           Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                           And AssigneeId IN: usersById.keySet()]) {
                                               usersWithPermission.add(usersById.get(psa.AssigneeId));
                                               usersById.remove(psa.AssigneeId);
                                           }
        
        //System.debug('@usersWithPermission: ' + usersWithPermission);
        
        System.runAs(usersWithPermission[0]) {
            LeapfrogBooking_Controller leapfrogCtr;
            
            
            for(Case c : [Select Id, Booking__c From Case]) {
                // Case 3: action type should be "editOrder" when the user click "NewsAdds Booking" on the case record if booking field has value.
                //Changed to create order for FB-255
                if(c.Booking__c == NULL) {
                    PageReference pageRef = Page.LeapfrogBooking;
                    pageRef.getParameters().put('Id', c.Id);
                    Test.setCurrentPage(pageRef);
                    
                    Test.startTest();
                    leapfrogCtr = new LeapfrogBooking_Controller();
                    Test.stopTest();
                    System.assertEquals('CreateOrder', leapfrogCtr.actionTypeName);
                }
            }
        }
        
    }
    @isTest static void actionTypeEditAccountManageTest() {
        
        List<User> usersWithPermission = new List<User>();
        
        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);
        
        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                           From PermissionSetAssignment 
                                           Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                           And AssigneeId IN: usersById.keySet()]) {
                                               usersWithPermission.add(usersById.get(psa.AssigneeId));
                                               usersById.remove(psa.AssigneeId);
                                           }
        
        //System.debug('@usersWithPermission: ' + usersWithPermission);
        
        System.runAs(usersWithPermission[0]) {
            
            
            // Case 5: action type should be "editAccount" when the user click "Manage NewsAdds Account" on the booking system account record
            External_Account__c bookingSystemAccount = [Select Id From External_Account__c Limit 1];
            LeapfrogBooking_Controller leapfrogCtr;
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', bookingSystemAccount.Id);
            Test.setCurrentPage(pageRef);
            
            Test.startTest();
            leapfrogCtr = new LeapfrogBooking_Controller();
            Test.stopTest();
            System.assertEquals('EditAccount', leapfrogCtr.actionTypeName);
            System.assert(!leapfrogCtr.showConfirmation);
        }
        
    }
    
    

    // this test method is to test contact dropdown.
    // To test inital contact list size. Also, to test contact list size when a new contact has been created.
    @isTest static void refreshContactListTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            System.assertEquals(1, leapfrogCtr.contactList.size());

            // add a new contact
            List<Contact> contacts = TestDataFactory.createContacts(1, acct);
            insert contacts;

            // check contact dropdown size, it should be 3 including 2 contacts and '--select contact--' option
            leapfrogCtr.refreshContactList();
            System.assertEquals(3, leapfrogCtr.contactList.size());
        }
    }

    // this test method is to test confirm() method and see if error message can be displayed correctly.
    // It also test if canvas section can be displayed correctly if there is no error from confirmation window
    @isTest static void hideCanvasTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            // unselect sales rep and contact and check error message
            leapfrogCtr.contactId = NULL;
            leapfrogCtr.salesRepId = NULL;

            pageRef = leapfrogCtr.confirm();

            // check error message
            Boolean foundNoSalesRepMsg = false;
            Boolean foundNoContactMsg = false;

            for(ApexPages.Message message : ApexPages.getMessages()) {
                if(message.getDetail().contains('haven\'t confirmed the sales rep')) {
                    foundNoSalesRepMsg = true;        
                }

                else if(message.getDetail().contains('haven\'t confirmed the contact')) {
                    foundNoContactMsg = true;        
                }
            }

            // error message
            System.assert(foundNoSalesRepMsg);
            System.assert(foundNoContactMsg);

            // don't show canvas app if errors present
            System.assert(!leapfrogCtr.showCanvasApp);
        }
    }

    @isTest static void showCanvasTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account where IsPersonAccount = true Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();

            //System.debug('@showCanvasTest contactId: ' + leapfrogCtr.contactId);
            pageRef = leapfrogCtr.confirm();

            Boolean foundNoSalesRepMsg = false;
            Boolean foundNoContactMsg = false;



            for(ApexPages.Message message : ApexPages.getMessages()) {
                if(message.getDetail().contains('haven\'t confirmed the sales rep')) {
                    foundNoSalesRepMsg = true;        
                }

                else if(message.getDetail().contains('haven\'t confirmed the contact')) {
                    foundNoContactMsg = true;        
                }
            }

            // no error message
            System.assert(!foundNoSalesRepMsg);
            System.assert(!foundNoContactMsg);
            // show canvas app
            System.assert(leapfrogCtr.showCanvasApp);
        }
    }

    @isTest static void esbCalloutTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            //System.debug('@@@@@@testExternalAccount: ' + [SELECT Id, External_Id__c, RecordTypeId, Customer_Account__c, Account_Type__c, Division__c, JDE_Account_Number__c FROM External_Account__c]);
            
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            ESB_GetNetDAForGBAMock esbMock = new ESB_GetNetDAForGBAMock();
            esbMock.success = true;
            Test.setMock(WebServiceMock.class, esbMock);

            Test.startTest();

            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();
            List<SelectOption> salesRepList = leapfrogCtr.salesRepList;

            External_Account__c gba = [SELECT Id FROM External_Account__c WHERE External_Id__c = '111111'];
            leapfrogCtr.bsaId = gba.Id;

            pageRef = leapfrogCtr.confirm();

            External_Account__c bookingSystemAccount = [SELECT Id, BSA__r.External_Id__c, BSA_Net_DA__r.External_Id__c FROM External_Account__c WHERE External_Id__c = '1234'];
            
            System.assertEquals('111111', bookingSystemAccount.BSA__r.External_Id__c);
            
            System.assertEquals('12347', bookingSystemAccount.BSA_Net_DA__r.External_Id__c);

            esbMock = new ESB_GetNetDAForGBAMock();
            Test.setMock(WebServiceMock.class, esbMock);
            //reset mock callout response order
            ESB_GetNetDAForGBAMock.TEST_CALLOUT_INDEX = 0;

            //rerun with stored data
            leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();

            //use existing gba on newsAdds Booking
            //leapfrogCtr.bsaId = gba.Id;

            pageRef = leapfrogCtr.confirm();

            System.assertEquals('111111', bookingSystemAccount.BSA__r.External_Id__c);
            System.assertEquals('12347', bookingSystemAccount.BSA_Net_DA__r.External_Id__c);

            Test.stopTest();

        }
    }

    @isTest static void esbCalloutErrorTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            //System.debug('@@@@@@testExternalAccount: ' + [SELECT Id, External_Id__c, RecordTypeId, Customer_Account__c, Account_Type__c, Division__c, JDE_Account_Number__c FROM External_Account__c]);
            
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            ESB_GetNetDAForGBAMock esbMock = new ESB_GetNetDAForGBAMock();
            esbMock.success = true;
            Test.setMock(WebServiceMock.class, esbMock);

            Test.startTest();

            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();
            List<SelectOption> salesRepList = leapfrogCtr.salesRepList;

            External_Account__c gba = [SELECT Id FROM External_Account__c WHERE External_Id__c = '111111'];
            leapfrogCtr.bsaId = gba.Id;

            pageRef = leapfrogCtr.confirm();

            External_Account__c bookingSystemAccount = [SELECT Id, BSA__r.External_Id__c, BSA_Net_DA__r.External_Id__c FROM External_Account__c WHERE External_Id__c = '1234'];
            //System.assertEquals('111111', bookingSystemAccount.BSA__r.External_Id__c);
            System.assertEquals('111111', bookingSystemAccount.BSA__r.External_Id__c);
            
            System.assertEquals('12347', bookingSystemAccount.BSA_Net_DA__r.External_Id__c);

            esbMock = new ESB_GetNetDAForGBAMock();
            Test.setMock(WebServiceMock.class, esbMock);
            //reset mock callout response order
            ESB_GetNetDAForGBAMock.TEST_CALLOUT_INDEX = 6;

            //rerun with stored data
            leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();

            System.debug('TEST_CALLOUT_INDEX: ' + ESB_GetNetDAForGBAMock.TEST_CALLOUT_INDEX);
            pageRef = leapfrogCtr.confirm();
            System.debug('TEST_CALLOUT_INDEX: ' + ESB_GetNetDAForGBAMock.TEST_CALLOUT_INDEX);
            pageRef = leapfrogCtr.confirm();
            Test.stopTest();

        }
    }

   /* @isTest static void esbCalloutCreateNetDATest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            ESB_GetNetDAForGBAMock esbMock = new ESB_GetNetDAForGBAMock();
            ESB_GetNetDAForGBAMock.TEST_CALLOUT_INDEX = 0;
            
            esbMock.success = false;
            Test.setMock(WebServiceMock.class, esbMock);

            Test.startTest();

            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            leapfrogCtr.contactId = leapfrogCtr.contactList[0].getValue();
            List<SelectOption> salesRepList = leapfrogCtr.salesRepList;

            External_Account__c gba = [SELECT Id FROM External_Account__c WHERE External_Id__c = '111111'];
            leapfrogCtr.bsaId = gba.Id;

            pageRef = leapfrogCtr.confirm();

            External_Account__c bookingSystemAccount = [SELECT Id, BSA__r.External_Id__c, BSA_Net_DA__r.External_Id__c FROM External_Account__c WHERE External_Id__c = '1234'];
            System.assertEquals('111111', bookingSystemAccount.BSA__r.External_Id__c);
            System.assertEquals(null, bookingSystemAccount.BSA_Net_DA__c);

            Test.stopTest();
        }
    } */

    // this is to test findObjectNameFromRecordIdPrefix() method to see if it 
    // can differentiate different object types based on record id
    @isTest static void checkObjectTypeTest() {

        // account record
        Account acct = [Select Id From Account Limit 1];
        String acctType = LeapfrogBooking_Controller.findObjectNameFromRecordIdPrefix(acct.Id);
        System.assertEquals('Account', acctType);

        // case record
        Case ca = [Select Id From Case Limit 1];
        String caseType = LeapfrogBooking_Controller.findObjectNameFromRecordIdPrefix(ca.Id);
        System.assertEquals('Case', caseType);

        // booking record
        Booking__c booking = [Select Id From Booking__c Limit 1];
        String bookingType = LeapfrogBooking_Controller.findObjectNameFromRecordIdPrefix(booking.Id);
        System.assertEquals('Booking__c', bookingType);

        // booking system account record
        External_Account__c bookingSystemAccount = [Select Id From External_Account__c Limit 1];
        String bookingSystemAccountType = LeapfrogBooking_Controller.findObjectNameFromRecordIdPrefix(bookingSystemAccount.Id);
        System.assertEquals('External_Account__c', bookingSystemAccountType);
    }

    @isTest static void exceptionTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {

            // test exception when there is no placer contact on the current booking
            Sales_Order__c so = [Select Id, Contact__c From Sales_Order__c Limit 1];
            so.Contact__c = NULL;
            update so;

            Booking__c booking = [Select Id, Placer_Contact__c From Booking__c Limit 1];
            booking.Placer_Contact__c = NULL;
            update booking;

            // test exception when there is no contact 
            //Contact c = [Select Id, AccountId From Contact Limit 1];
            //c.AccountId = NULL;
            //update c;



            Test.startTest();

            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', booking.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            

            Boolean noPlacerContactOnBooking = false;

            for(ApexPages.Message message : ApexPages.getMessages()) {
                if(message.getDetail().contains('Couldn\'t find any placer contact')) {
                    noPlacerContactOnBooking = true;        
                }

                //else if(message.getDetail().contains('haven\'t confirmed the contact')) {
                //    foundNoContactMsg = true;        
                //}
            }

            System.assert(noPlacerContactOnBooking);
            Test.stopTest();
        }
    }
    
    // AdSales 897, 810 darshan.gosar@bluewolfgroup.com Added to new method for code coverage of adsales 897, 810
    @isTest static void checknewBSATypeMethods() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();            

            System.assertEquals(1, leapfrogCtr.bookingSystemAccountList.size());
            
            List<External_Account__c> eList = [Select Id, BSA_Account_No__c From External_Account__c WHERE RecordType.DeveloperName = 'NewsAdds_Booking_System'];
                        
            leapfrogCtr.newBooking();            
            leapfrogCtr.selectedBookingSystemAccount = eList[0].Id;
            leapfrogCtr.modifyBooking();
        }
    }
    
    // AdSales 897, 810 darshan.gosar@bluewolfgroup.com Added to new method for code coverage of adsales 897
    @isTest static void refreshContactListInActiveContactTest() {
        List<User> usersWithPermission = new List<User>();

        // query permission assignee
        Map<String, User> usersById = new Map<String, User>([Select Id From User Where Firstname = 'User' And LastName Like '%TestUser']);

        for(PermissionSetAssignment psa : [Select Id, PermissionSetId, AssigneeId 
                                            From PermissionSetAssignment 
                                            Where PermissionSet.Name = 'Leapfrog_User_Permission'
                                            And AssigneeId IN: usersById.keySet()]) {
            usersWithPermission.add(usersById.get(psa.AssigneeId));
            usersById.remove(psa.AssigneeId);
        }

        //System.debug('@usersWithPermission: ' + usersWithPermission);

        System.runAs(usersWithPermission[0]) {
            Account acct = [Select Id From Account Limit 1];
            PageReference pageRef = Page.LeapfrogBooking;
            pageRef.getParameters().put('Id', acct.Id);
            Test.setCurrentPage(pageRef);
            LeapfrogBooking_Controller leapfrogCtr = new LeapfrogBooking_Controller();

            System.assertEquals(1, leapfrogCtr.contactList.size());

            // add a new contact
            List<Contact> contacts = TestDataFactory.createContacts(1, acct);
            contacts[0].Contact_Status__c = 'Inactive';
            insert contacts;

            // check contact dropdown size, it should be 1 as Inactive contact should not show up
            leapfrogCtr.refreshContactList();
            System.assertEquals(1, leapfrogCtr.contactList.size());            
            
        }
    }        
    
}