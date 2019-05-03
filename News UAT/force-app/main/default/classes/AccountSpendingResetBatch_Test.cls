/* 2016-02-17   Darshan Gosar    Updated
 // 2016-02-17 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for
    //  - AccountSpendingReset_Batch            95%
 */
@isTest
private class AccountSpendingResetBatch_Test
{
    static testMethod void resetSpendingTest()
    {
        // create accounts
        List<Account> accounts = TestDataFactory.createAccounts(200, false);
        
        // loop through account, give value to total spendings
        for(Account a : accounts)
        {
            a.Total_Agency_Spend__c = 100;
            a.Total_Customer_Spend__c = 200;
            a.Total_Group_Spend__c = 300;
        }
        
        insert accounts;        
        
        Test.startTest();
        
        // SFE-766 2016-02-17 darshan.gosar@bluewolfgroup.com
            // Created custom setting record to prevent test class failure
        Batch_Run_Start_Datetime__c lastRunDateTimeTgs = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTgs.Name = 'Account TGS Update Batch';
        lastRunDateTimeTgs.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTimeTgs;
                
        // call batch to reset spendings
        AccountSpendingReset_Batch accountSpendingBatch = new AccountSpendingReset_Batch();
        ID batchProcessId = Database.executeBatch(accountSpendingBatch);
        Test.stopTest();
        
        // valiate results
        for(Account a : [Select Total_Agency_Spend__c, Total_Customer_Spend__c, Total_Group_Spend__c From Account Where Id IN: accounts])
        {
            system.assertEquals(a.Total_Agency_Spend__c, 0);
            system.assertEquals(a.Total_Customer_Spend__c, 0);
            system.assertEquals(a.Total_Group_Spend__c, 0);
        }
    }
}