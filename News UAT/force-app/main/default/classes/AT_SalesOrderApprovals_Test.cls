@isTest
public class AT_SalesOrderApprovals_Test {
	
    @testSetup
    static void init() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        List<User> users = new List<User>{
            new User(FirstName = 'Sales', LastName = 'Rep', Username = 'sales@rep.user', Alias = 'sr', CommunityNickName = 'sr', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'L1', LastName = 'Approver', Username = 'l1@approver.user', Alias = 'l1', CommunityNickName = 'l1', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'L2', LastName = 'Approver', Username = 'l2@approver.user', Alias = 'l2', CommunityNickName = 'l2', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'L3', LastName = 'Approver', Username = 'l3@approver.user', Alias = 'l3', CommunityNickName = 'l3', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'L4', LastName = 'Approver', Username = 'l4@approver.user', Alias = 'l4', CommunityNickName = 'l4', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'Delegated', LastName = 'Manager', Username = 'del@approver.user', Alias = 'del', CommunityNickName = 'del', Email = 'test@test.test', ProfileId = p.Id, TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US')
        };
        
        insert users;
        
        User delegated = users[5];
        
        CPQ_Approver__c approvers = new CPQ_Approver__c(Platform__c = 'Print', Sales_Rep__c = users[0].Id, Approval_Level__c = 0, L1_Approver__c = users[1].Id, L2_Approver__c = users[2].Id, L3_Approver__c = users[3].Id, L4_Approver__c = users[4].Id);
        
        insert approvers;
        
        approvers = new CPQ_Approver__c(Platform__c = 'Threshold', Sales_Rep__c = users[0].Id, Approval_Level__c = 0, L1_Approver__c = users[1].Id, L2_Approver__c = users[2].Id, L3_Approver__c = users[3].Id, L4_Approver__c = users[4].Id);
        
        insert approvers;
        
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true, OwnerId = users[0].Id);
        
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'test', StageName = 'Identify Prospects', AccountId = acc.Id, CloseDate = System.Today().addDays(1), OwnerId = users[0].Id);
        
        insert opp;
        
        csmso__Sales_Order__c so = new csmso__Sales_Order__c(csmso__Advertiser__c = acc.Id, csmso__Opportunity__c = opp.Id, csmso__Status__c = 'Draft', Platform_Set__c = '{}', Platform__c = 'Print', OwnerId = users[0].Id);
        
        insert so;
        
        users = [SELECT DelegatedApproverId, Delegation_Start__c, Delegation_End__c FROM User WHERE LastName = 'Approver'];
        
        for (User u: users) {
            u.DelegatedApproverId = delegated.Id;
            u.Delegation_Start__c = System.today();
            u.Delegation_End__c = System.today();
        }
            
        update users;
    }
    
    @isTest
    static void testPrintApprover() {
        csmso__Sales_Order__c so = [SELECT Id, Target_Print_Price__c, Print_Display_DT_Amount_L1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Total_Print_Duration_Price__c = 200;
        so.Target_Print_Price__c = 50;
        so.Print_Display_DT_Amount_L2__c = 80;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        System.debug('Approval order: ' + so);
        
        System.assert(AT_SalesOrderApprovals.requiresApproval(so.Id), 'Should require L2 Print approval');
        
        PageReference ref = AT_SalesOrderApprovals.requestApproval(so.Id);
        
        System.debug('Approval params: ' + ref.getParameters());
        
        Test.setCurrentPage(ref);
        
        AT_SubmitSalesOrderApproval submit = new AT_SubmitSalesOrderApproval(new ApexPages.StandardController(so));
        
        submit.getSelectReason();
        submit.cancel();
        
        submit.selectedReason ='--Select Reason--';
        submit.comments = '';
        
        submit.submitSO();
        
        System.assertNotEquals(null, submit.errorMessage);
        
        submit.comments = 'test';
        
        submit.submitSO();
        
        System.assertNotEquals(null, submit.errorMessage);
        
        submit.selectedReason ='--Select Reason--';
        submit.comments = 'test';
        
        submit.submitSO();
        
        System.assertNotEquals(null, submit.errorMessage);
        
        submit.selectedReason ='test';
        submit.comments = 'test';
        
        submit.submitSO();
        
        System.assertEquals(null, submit.errorMessage);
        
        PageReference rejectRef = AT_SalesOrderApprovals.rejectSO(so.Id);
        
        Test.setCurrentPage(rejectRef);
        
        AT_SalesOrderApprovals approvals = new AT_SalesOrderApprovals(new ApexPages.StandardController(so));
        
        approvals.cancel();
        
        approvals.salesOrderID = so.Id;
        
        approvals.redirectToApproval();
        
        approvals.comments = 'test';
        
        approvals.reject();
        
        //approvals.getRejectComments();
        
        //AT_SalesOrderApprovals.approve(so.Id, 'test');
    }
    
    @isTest
    static void testThresholdApprover() {
        csmso__Sales_Order__c so = [SELECT Id, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Print_Display_MAX_PPT_Level__c = 2;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        System.debug('Approval order: ' + so);
        
        System.assert(AT_SalesOrderApprovals.requiresApproval(so.Id), 'Should require L2 Threshold approval');
        
        PageReference ref = AT_SalesOrderApprovals.requestApproval(so.Id);
        
        System.debug('Approval params: ' + ref.getParameters());
        
        Test.setCurrentPage(ref);
        
        AT_SubmitSalesOrderApproval submit = new AT_SubmitSalesOrderApproval(new ApexPages.StandardController(so));
        
        submit.getSelectReason();
        submit.cancel();
                
        submit.selectedReason ='test';
        submit.comments = 'test';
        
        submit.submitSO();
        
        so = [SELECT Id, Approver1__c, Approver1__r.Username, Approver2__r.Username FROM csmso__Sales_Order__c LIMIT 1];
        
        System.assertEquals(null, submit.errorMessage);
        
        User approver = [SELECT Id FROM User WHERE Id = :so.Approver1__c];
                
        System.debug('SO Approver: ' + so.Approver1__r.Username);
        
        System.runAs(approver) {
            System.assert(AT_SalesOrderApprovals.isApprover(so.Id));
            
            System.assertNotEquals(null, AT_SalesOrderApprovals.allowedUserActions(so.Id));
        }
        
        AT_SalesOrderApprovals.recall(so.Id);
    }
    
    @isTest
    static void testApprove() {
        csmso__Sales_Order__c so = [SELECT Id, Target_Print_Price__c, Print_Display_DT_Amount_L1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Total_Print_Duration_Price__c = 200;
        so.Target_Print_Price__c = 50;
        so.Print_Display_DT_Amount_L2__c = 80;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        System.debug('Approval order: ' + so);
        
        System.assert(AT_SalesOrderApprovals.requiresApproval(so.Id), 'Should require L2 Print approval');
        
        PageReference ref = AT_SalesOrderApprovals.requestApproval(so.Id);
        
        System.debug('Approval params: ' + ref.getParameters());
        
        Test.setCurrentPage(ref);
        
        AT_SubmitSalesOrderApproval submit = new AT_SubmitSalesOrderApproval(new ApexPages.StandardController(so));
        
        submit.selectedReason ='test';
        submit.comments = 'test';
        
        submit.submitSO();
        
        System.assertEquals(null, submit.errorMessage);
        
        so = [SELECT Id, Approver1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        User approver = [SELECT Id FROM User WHERE Id = :so.Approver1__c];
        
        Test.startTest();
        
        System.runAs(approver) {
        	AT_SalesOrderApprovals.approve(so.Id, 'test');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testReject() {
        csmso__Sales_Order__c so = [SELECT Id, Target_Print_Price__c, Print_Display_DT_Amount_L1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Total_Print_Duration_Price__c = 200;
        so.Target_Print_Price__c = 50;
        so.Print_Display_DT_Amount_L2__c = 80;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        System.debug('Approval order: ' + so);
        
        System.assert(AT_SalesOrderApprovals.requiresApproval(so.Id), 'Should require L2 Print approval');
        
        PageReference ref = AT_SalesOrderApprovals.requestApproval(so.Id);
        
        System.debug('Approval params: ' + ref.getParameters());
        
        Test.setCurrentPage(ref);
        
        AT_SubmitSalesOrderApproval submit = new AT_SubmitSalesOrderApproval(new ApexPages.StandardController(so));
        
        submit.selectedReason ='test';
        submit.comments = 'test';
        
        submit.submitSO();
        
        System.assertEquals(null, submit.errorMessage);
        
        so = [SELECT Id, Approver1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        User approver = [SELECT Id FROM User WHERE Id = :so.Approver1__c];
        
        Test.startTest();
        
        System.runAs(approver) {
            AT_SalesOrderApprovals approvals = new AT_SalesOrderApprovals(new ApexPages.StandardController(so));
        
        	approvals.cancel();
        
        	approvals.salesOrderID = so.Id;
        
        	approvals.comments = 'test';
        
        	approvals.reject();
        
        	approvals.getRejectComments();
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testApproversBelow() {
        csmso__Sales_Order__c so = [SELECT Id, Target_Print_Price__c, Print_Display_DT_Amount_L1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Total_Print_Duration_Price__c = 200;
        so.Target_Print_Price__c = 50;
        so.Print_Display_DT_Amount_L2__c = 80;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        AT_SalesOrderApprovals.PlatformLevel print2 = new AT_SalesOrderApprovals.PlatformLevel(AT_SalesOrderApprovals.Platform.Print, 4);
        
        Set<Id> approvers = AT_SalesOrderApprovals.findApproversBelow(new List<AT_SalesOrderApprovals.PlatformLevel>{print2}, so.Id);
        
        System.assertNotEquals(null, approvers);
    }
    
    @isTest
    static void testReminder() {
        csmso__Sales_Order__c so = [SELECT Id, Target_Print_Price__c, Print_Display_DT_Amount_L1__c FROM csmso__Sales_Order__c LIMIT 1];
        
        so.Total_Print_Duration_Price__c = 200;
        so.Target_Print_Price__c = 50;
        so.Print_Display_DT_Amount_L2__c = 80;
        
        update so;
        
        so = [SELECT Id, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c FROM csmso__Sales_Order__c LIMIT 1];
        
        System.debug('Approval order: ' + so);
        
        System.assert(AT_SalesOrderApprovals.requiresApproval(so.Id), 'Should require L2 Print approval');
        
        PageReference ref = AT_SalesOrderApprovals.requestApproval(so.Id);
        
        System.debug('Approval params: ' + ref.getParameters());
        
        Test.setCurrentPage(ref);
        
        AT_SubmitSalesOrderApproval submit = new AT_SubmitSalesOrderApproval(new ApexPages.StandardController(so));
        
        submit.selectedReason ='test';
        submit.comments = 'test';
        
        submit.submitSO();
        
        so = [SELECT Id, Name FROM csmso__Sales_Order__c LIMIT 1];
        
        Test.startTest();
        
        Date ts = System.today().addDays(1);
        
        AT_SalesOrderEscalationBatch.run(12, 05, ts.day(), ts.month(), ts.year(), so.Name);
        
        Test.stopTest();
        
        DateTime dt = System.now().addDays(3);
        
        AT_SalesOrderEscalationBatch batch = new AT_SalesOrderEscalationBatch(dt, so.Name);
        
        batch.execute(null, new List<csmso__Sales_Order__c>{so});
        
        dt = System.now().addDays(5);
        
        batch = new AT_SalesOrderEscalationBatch(dt, so.Name);
        
        batch.execute(null, new List<csmso__Sales_Order__c>{so});
    }
}