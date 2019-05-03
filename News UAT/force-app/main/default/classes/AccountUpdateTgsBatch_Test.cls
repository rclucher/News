/*---------------------------------------------------------
* Author:  Bohao Chen
* Description: This class contains unit tests for validating the behavior of AccountUpdateTgs_Batch
* Company: Salesforce.com
* Date: 24/07/2013
* History:
* 24/07/2013   Bohao Chen       Created
---------------------------------------------------------*/
@isTest
private class AccountUpdateTgsBatch_Test 
{
    static testMethod void createAccountTest() 
    {
        // set up custom setting for last success run date time
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
        
        Test.startTest();
        
        // when TCS or TAS or parent account get updated, Account_Last_Modified__c will timestamp it.
        // Only rollup accounts' whose Account_Last_Modified__c is greater than last success batch run time.
        String query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
            + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
            + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
            + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
            + 'From Account ' 
            + 'Where Account_Last_Modified__c > :recordStartDatetime '
            + 'And Ultimate_Parent_Id__c != NULL';
        
        AccountUpdateTgs_Batch accountUpdateTgs = new AccountUpdateTgs_Batch(query);
        ID batchProcessId = Database.executeBatch(accountUpdateTgs);
        System.debug('Returned batch process ID: ' + batchProcessId);
        
        Test.stopTest();
        
        businessTopLevelAccount = [Select Total_Group_Spend__c From Account Where Id =: businessTopLevelAccount.Id limit 1];
        
        system.debug(loggingLevel.error, '---top level---- ' + businessTopLevelAccount);
        
        for(Account acct : [Select Total_Group_Spend__c, Hierarchy_Level_Test__c, Total_Customer_Spend__c, ParentId From Account 
                            Where Id IN: businessChildAccountsForBusinessTopLevelAccount]) 
        {
            system.debug(loggingLevel.error, '==== after batch === ' + acct.Id + ' @level ' + acct.Hierarchy_Level_Test__c 
                         + '==== TGS is ===' + acct.Total_Group_Spend__c + '==== TCS is ===' + acct.Total_Customer_Spend__c 
                         + '==== parent is ===' + acct.ParentId);
            
            if(acct.Hierarchy_Level_Test__c == 1)
            {
                system.assertEquals(12400, acct.Total_Group_Spend__c);
            }
            else if(acct.Hierarchy_Level_Test__c == 2)
            {
                system.assertEquals(6000, acct.Total_Group_Spend__c);
            }
            else if(acct.Hierarchy_Level_Test__c == 3)
            {
                system.assertEquals(2800, acct.Total_Group_Spend__c);
            }
            else if(acct.Hierarchy_Level_Test__c == 4)
            {
                system.assertEquals(1200, acct.Total_Group_Spend__c);
            }
            else if(acct.Hierarchy_Level_Test__c == 5)
            {
                system.assertEquals(0, acct.Total_Group_Spend__c);
            }
        }
    }
}