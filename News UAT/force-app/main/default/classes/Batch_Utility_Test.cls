/*---------------------------------------------------------
* Author:  Darshan Gosar
* Description: This class contains unit tests for validating the behavior of Batch_Utility
* Company: Salesforce.com
* History:
*  2016-01-05   Darshan Gosar       Created
// SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for 
    //  - Batch_Utility                100% 
---------------------------------------------------------*/
@isTest
private class Batch_Utility_Test
{ 

    static void setupData(){
        Batch_Run_Start_Datetime__c lastRunDateTime = new Batch_Run_Start_Datetime__c();
        lastRunDateTime.Name = 'Account TGS Update Batch';
        lastRunDateTime.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime;
        
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account; 
        Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 
        
        Id businessRecordTypeId = AccountRecordTypeInfo.get('Business Account').getRecordTypeId();
        Id agencyRecordTypeId = AccountRecordTypeInfo.get('Agency Account').getRecordTypeId();
        
        system.debug('====BC businessRecordTypeId===' + businessRecordTypeId);
        system.debug('====BC agencyRecordTypeId===' + agencyRecordTypeId);
        
        // insert top level account without parent
        Account businessTopLevelAccount = TestDataFactory.createSingleAccount(null, 0, businessRecordTypeId, null, null);
        Account agencyTopLevelAccount = TestDataFactory.createSingleAccount(null, 0, agencyRecordTypeId, null, null);
        
        List<Account> parentAccounts = new List<Account>();
        parentAccounts.add(businessTopLevelAccount);
        parentAccounts.add(agencyTopLevelAccount);
        insert parentAccounts;
        
        parentAccounts = [Select Id, Ultimate_Parent_Id__c From Account Where Id IN: parentAccounts limit 2];
        
        // insert business child accounts and link to top level business account
        List<Account> businessChildAccountsForBusinessTopLevelAccount = new List<Account>();
        businessChildAccountsForBusinessTopLevelAccount.addAll(TestDataFactory.createChildAccounts(businessChildAccountsForBusinessTopLevelAccount, new Account[]{parentAccounts[0]}, 2, 1, 5, businessRecordTypeId, 400, 500));
        
        for(Account acct : [Select Total_Group_Spend__c, Hierarchy_Level_Test__c, Total_Customer_Spend__c, ParentId From Account businessTopLevelAccount 
                            Where Id IN: businessChildAccountsForBusinessTopLevelAccount]) 
        {
            system.debug(loggingLevel.error, '==== before batch === ' + acct.Id + ' @level ' + acct.Hierarchy_Level_Test__c);
            system.debug(loggingLevel.error, '==== TGS ===' + acct.Total_Group_Spend__c);
            system.debug(loggingLevel.error, '==== TCS ===' + acct.Total_Customer_Spend__c);
            system.debug(loggingLevel.error, '==== parent ===' + acct.ParentId);
        }
        
        // insert agency child accounts and link to top level agency account
        List<Account> agencyChildAccountsForAgencyTopLevelAccount = new List<Account>();
        agencyChildAccountsForAgencyTopLevelAccount.addAll(TestDataFactory.createChildAccounts(agencyChildAccountsForAgencyTopLevelAccount, new Account[]{parentAccounts[1]}, 2, 1, 5, agencyRecordTypeId, 400, 500));
            
    
    }

    static testMethod void errorHandlingTestUncompletedStatus() 
    {              
        setupData();
        Test.startTest();
                
        String query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
            + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
            + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
            + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
            + 'From Account ' 
            + 'Where Account_Last_Modified__c > :recordStartDatetime '
            + 'And Ultimate_Parent_Id__c != NULL';
        
        AccountUpdateTgs_Batch accountUpdateTgs = new AccountUpdateTgs_Batch(query);
        ID batchProcessId = Database.executeBatch(accountUpdateTgs);
                
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                          FROM AsyncApexJob WHERE Id=:batchProcessId Limit 1];
                                 

        Batch_Utility.errorHandling(a, 'Account Update TCS TAS Batch', 0, 'Failed');
        Test.stopTest();                
    }
    
    static testMethod void errorHandlingTestCompletedStatus() 
    {          
        setupData();
        Test.startTest();        
        String query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
            + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
            + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
            + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
            + 'From Account ' 
            + 'Where Account_Last_Modified__c > :recordStartDatetime '
            + 'And Ultimate_Parent_Id__c != NULL';
        
        AccountUpdateTgs_Batch accountUpdateTgs = new AccountUpdateTgs_Batch(query);
        ID batchProcessId = Database.executeBatch(accountUpdateTgs);
                
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                          FROM AsyncApexJob WHERE Id=:batchProcessId Limit 1];
                   

        Batch_Utility.errorHandling(a, 'Account Update TCS TAS Batch', 10, 'Completed');
        Test.stopTest();                
    }    



    @isTest static void test_SendEmail() {

        string[] toEmail = new string[] { 'support@news.com.au' };

        Test.startTest();
        Batch_Utility.SendEmail(toEmail, 'testSubject', 'testBody');
            
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        system.assertEquals(1, invocations, 'An email should be sent');
    }
       
}