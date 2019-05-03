@isTest
public class AT_BatchProcesses_Test {
    @testSetup
    static void init() {
        User u = [Select Bypass_Triggers__c from User where Id =: UserInfo.getUserId()];
        
        u.Bypass_Triggers__c = 'BookingManagement;BookingLineItemManagement';
        
        update u;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        List<User> users = new List<User>{
            new User(FirstName = 'Vacant', LastName = 'NextG', Username = 'vacant@next.g', Alias = 'vng', CommunityNickName = 'vng', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'Unasssigned', LastName = 'NextG', Username = 'unassigned@next.g', Alias = 'ung', CommunityNickName = 'ung', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US')
        };
        
        insert users;
    }
    
	@isTest
    static void testBSALinks() {
        //AT_BookingSystemPortfolioJunctionManagement
        
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        External_Account__c bsa = new External_Account__c(Name = 'test', Customer_Account__c = acc.Id, External_Id__c = 'test');
        
        insert bsa;
        
        Portfolio2__c port = new Portfolio2__c(Name = 'test', Portfolio_Code__c = 'test');
        
        insert port;
        
        Booking_System_Portfolio_Junction__c bspj = new Booking_System_Portfolio_Junction__c(Booking_System_Account__c = bsa.Id, Portfolio__c = port.Id);
        
        insert bspj;
        
        bspj = [SELECT Account__c FROM Booking_System_Portfolio_Junction__c LIMIT 1];
        
        System.assertEquals(acc.Id, bspj.Account__c);
    }
    
    @isTest
    static void testTransactionDates() {
        Set<String> recordTypeNames = new Set<String>();
        
        for (NextGen_Account_Type__mdt nat : [SELECT DeveloperName FROM NextGen_Account_Type__mdt]) {
            recordTypeNames.add(nat.DeveloperName);
        }
        
        Set<String> recordTypeIDs = new Set<String>();
        
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName IN :recordTypeNames LIMIT 1];
        
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true, RecordTypeId = rt.Id);
        
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'test', StageName = 'Identify Prospects', AccountId = acc.Id, CloseDate = System.Today().addDays(1));
        
        insert opp;
        
        Sales_Order__c so = new Sales_Order__c(Advertiser_Account__c = acc.Id);
        
        insert so;
        
        Booking__c b1 = new Booking__c(Advertiser_Account__c = acc.Id, Sales_Order__c = so.Id, Source_System__c = 'AdPoint');
        Booking__c b2 = new Booking__c(Advertiser_Account__c = acc.Id, Sales_Order__c = so.Id, Source_System__c = 'Cyber$ell');
        
        insert b1;
        insert b2;
        
        Booking_Line_Item__c b1i = new Booking_Line_Item__c(Booking__c = b1.Id, Run_Date__c = System.today(), Stop_On_Web_Date__c = System.today());
        Booking_Line_Item__c b2i = new Booking_Line_Item__c(Booking__c = b2.Id, Run_Date__c = System.today(), Stop_On_Web_Date__c = System.today());
        
        insert b1i;
        insert b2i;
        
        Order__c ord = new Order__c(Account__c = acc.Id);
        
        insert ord;
        
        Payment__c pay = new Payment__c(Order__c = ord.Id, Last_End_Date__c = System.today());
        
        insert pay;
        
        Test.startTest();
        
        Database.executeBatch(new AT_AccountTransactionDatesBatch());
        
        Test.stopTest();
        
        acc = [SELECT Id, Digital_Last_Transaction_Date__c, Print_Last_Transaction_Date__c, Xtend_Last_Transaction_Date__c FROM Account LIMIT 1];
        
        System.assertEquals(System.today(), acc.Digital_Last_Transaction_Date__c);
        System.assertEquals(System.today(), acc.Print_Last_Transaction_Date__c);
        System.assertEquals(System.today(), acc.Xtend_Last_Transaction_Date__c);
    }
    
    @isTest
    static void testLastClientEngagement() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        DateTime yesterday = System.Now().addDays(-1);
        
        Event ev = new Event(WhatId = acc.Id, StartDateTime = yesterday, EndDateTime = yesterday.addHours(1), Subject = 'test');
        
        insert ev;
        
        Test.startTest();
        
        Database.executeBatch(new AT_LastClientEngagementBatchProcess());
        
        Test.stopTest();
        
        acc = [SELECT Id, Last_Client_Engagement__c FROM Account LIMIT 1];
        
        //System.assertEquals(yesterday.addHours(1), acc.Last_Client_Engagement__c);
    }
    
    @isTest
    static void testAcccount_No_Portfolios() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        Test.startTest();
        
        AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();
        
        batch.initialiseState();
        
        batch.updateAccounts([SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account]);
        
        Test.stopTest();
    }
    
    @isTest
    static void testAcccount_1Portfolio() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        External_Account__c bsa = new External_Account__c(Name = 'test', Customer_Account__c = acc.Id, External_Id__c = 'test');
        
        insert bsa;
        
        Portfolio2__c port = new Portfolio2__c(Name = 'test', Portfolio_Code__c = 'test');
        
        insert port;
        
        Portfolio_Owners__c owner = new Portfolio_Owners__c(Portfolio2__c = port.Id, Portfolio_Owner__c = UserInfo.getUserId());
        
        insert owner;
        
        Booking_System_Portfolio_Junction__c bspj = new Booking_System_Portfolio_Junction__c(Booking_System_Account__c = bsa.Id, Portfolio__c = port.Id);
        
        insert bspj;
        
        Test.startTest();
        
        AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();
        
        batch.initialiseState();
        
        batch.updateAccounts([SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account]);
        
        Test.stopTest();
    }
    
    @isTest
    static void testAcccount_1Portfolio_NoOwner() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        External_Account__c bsa = new External_Account__c(Name = 'test', Customer_Account__c = acc.Id, External_Id__c = 'test');
        
        insert bsa;
        
        Portfolio2__c port = new Portfolio2__c(Name = 'test', Portfolio_Code__c = 'test');
        
        insert port;
        
        Booking_System_Portfolio_Junction__c bspj = new Booking_System_Portfolio_Junction__c(Booking_System_Account__c = bsa.Id, Portfolio__c = port.Id);
        
        insert bspj;
        
        Test.startTest();
        
        AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();
        
        batch.initialiseState();
        
        batch.updateAccounts([SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account]);
        
        Test.stopTest();
    }
    
    @isTest
    static void testAcccount_2Portfolios() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        External_Account__c bsa = new External_Account__c(Name = 'test', Customer_Account__c = acc.Id, External_Id__c = 'test');
        
        insert bsa;
        
        Portfolio2__c port1 = new Portfolio2__c(Name = 'test1', Portfolio_Code__c = 'test1', Portfolio_Segment__c = 'SME');
        Portfolio2__c port2 = new Portfolio2__c(Name = 'test2', Portfolio_Code__c = 'test2', Portfolio_Segment__c = 'CON');
        
        insert port1;
        insert port2;
        
        Portfolio_Owners__c owner1 = new Portfolio_Owners__c(Portfolio2__c = port1.Id, Portfolio_Owner__c = UserInfo.getUserId());
        Portfolio_Owners__c owner2 = new Portfolio_Owners__c(Portfolio2__c = port2.Id, Portfolio_Owner__c = UserInfo.getUserId());
        
        insert owner1;
        insert owner2;
        
        Account_Portfolio_Relationship__c apj = new Account_Portfolio_Relationship__c(Portfolio__c = port2.Id, Account__c = acc.Id);
        
        insert apj;
        
        Booking_System_Portfolio_Junction__c bspj = new Booking_System_Portfolio_Junction__c(Booking_System_Account__c = bsa.Id, Portfolio__c = port1.Id);
        
        insert bspj;
        
        Test.startTest();
        
        AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();
        
        batch.initialiseState();
        
        batch.updateAccounts([SELECT Id, Type, Customer_Segment__c, OwnerId, Owner.ProfileId FROM Account]);
        
        Test.stopTest();
    }
    
    @isTest
    static void coverMissingFunctions() {
        AT_AccountPortfolioOwnershipBatch.getAccountIDs();
        
        AT_AccountPortfolioOwnershipBatch.updateAccounts(new List<String>());
        
        Portfolio2__c port = new Portfolio2__c(Name = 'test', Portfolio_Code__c = 'test');
        
        insert port;
        
        Portfolio_Owners__c owner = new Portfolio_Owners__c(Portfolio2__c = port.Id, Portfolio_Owner__c = UserInfo.getUserId());
        
        insert owner;
        
        AT_AccountPortfolioOwnershipBatch batch = new AT_AccountPortfolioOwnershipBatch();
        
        batch.portfoliosWithMultipleOwners.add(port.Id);
        
        Test.startTest();
        
        Database.executeBatch(batch);
        
        Test.stopTest();
    }
}