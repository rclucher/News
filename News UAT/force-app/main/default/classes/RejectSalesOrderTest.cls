@isTest(seeAllData = true)
public class RejectSalesOrderTest {

    @isTest
    public static void createGroup()
    {
        Id runningUserId = UserInfo.getUserId();
        // Insert user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u    = new User(Alias = 'standt', Email = 'test@test.com',
                             EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                             LocaleSidKey = 'en_US', ProfileId = p.Id,
                             TimeZoneSidKey = 'America/Los_Angeles', UserName = 'sdss123@test.com',
                             ManagerId = runningUserId);
        insert u;

        // Insert group
        Group grp = new Group();
        grp.Name = 'News Xtend Approvers';
        insert grp;
        GroupMember gm = new GroupMember(GroupId = grp.Id, UserOrGroupId = u.Id);
        insert gm;

        System.runAs(u) {
            Account acc       = TestDataSetupClass.createAccount();
            RecordType rtypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Prospecting Account' AND isActive = true];
            acc.RecordTypeId = rtypes.Id;
            insert acc;

            Contact con = TestDataSetupClass.createContact(acc);
            insert con;

            Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
            insert opp;

            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.Margin__c       = 0.3;
            so.Platform_Set__c = '{Xtend}';
            so.Approver1__c = runningUserId;
            insert so;

            //create approval
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(so.id);
            // Submit on behalf of a specific submitter
            req1.setSubmitterId(u.Id);
            // Submit the record to specific process and skip the criteria evaluation
            req1.setProcessDefinitionNameOrId('SO_Approvals');
            req1.setSkipEntryCriteria(true);
            // Submit the approval request
            Approval.ProcessResult result = Approval.process(req1);

            Test.startTest();
            RejectSalesOrder asoClass = new RejectSalesOrder();
            String str                = so.Id;
            String paStr              = asoClass.performAction(str);
            Test.stopTest();
        }
    }


    @isTest
    public static void ApproveSalesOrderStatusTest(){
        Account acc       = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.Margin__c = 0.3;

        insert so;

        so = [Select id,Margin__c from csmso__Sales_Order__c where id =:so.id];
        System.debug('Margin' + so.Margin__c);

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(so.id);

        // Submit on behalf of a specific submitter
        req1.setSubmitterId(UserInfo.getUserId());

        // Submit the record to specific process and skip the criteria evaluation
        //req1.setProcessDefinitionNameOrId('Margin Approval');
        req1.setSkipEntryCriteria(false);

        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);



        Test.startTest();
        RejectSalesOrder asoClass = new RejectSalesOrder();
        String str                = so.Id;
        String paStr              = asoClass.performAction(str);
        Test.stopTest();
    }

    @isTest
    public static void ApproveSalesOrder_BlankTest(){
        Account acc       = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = '';
        insert so;

        Test.startTest();
        RejectSalesOrder asobClass = new RejectSalesOrder();
        String str                 = so.Id;
        String paStr               = asobClass.performAction(str);
        Test.stopTest();
    }


}