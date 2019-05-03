/*---------------------------------------------------------
* Author:  Darshan Gosar
* Description: This class contains unit tests for validating the behavior of AccountBatch_Helper
* Company: Salesforce.com
* History:
* 2015-12-15   Darshan Gosar       Created
// SFE-766 2015-12-15 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for 
    //  - AccountBatch_Helper                      91% 
---------------------------------------------------------*/
@isTest
private class AccountBatch_Helper_Test 
{

    static List<Account> advertiserAccounts;
    
    static public void setupTestData(){    
        
        SystemParameters__c batchSetting = new SystemParameters__c(Name = 'Spending_Batch_Exception_Recipients', Value__c = 'test.test@test.com', External_Id__c = '1234');
        insert batchSetting;  
                
        advertiserAccounts = TestDataFactory.createAccounts(10, false);
        insert advertiserAccounts; 
    }
    

    static testMethod void sendBatchErrorMessagesTest() 
    {
        setupTestData();  
        
        Map<String, List<String>> errorMessageByFailedAcctId = new Map<String, List<String>>();
        
        for(Account a: advertiserAccounts){
            List<String> errorMessages = new List<String>();
            errorMessages.add('Test Message 1');
            errorMessages.add('Test Message 2');
            errorMessageByFailedAcctId.put(a.Id, errorMessages);
        }
              
        Test.startTest();
        AccountBatch_Helper.sendBatchErrorMessages(errorMessageByFailedAcctId, 'AccountCalculateTcsTas_Batch');
        Test.stopTest();                
    }
    
    static testMethod void processFailRecordsTest() 
    {
        setupTestData();  
        
        Map<String, List<String>> errorMessageByFailedAcctId = new Map<String, List<String>>();
        
        for(Account a: advertiserAccounts){
            List<String> errorMessages = new List<String>();
            errorMessages.add('Test Message 1');
            errorMessages.add('Test Message 2');
            errorMessageByFailedAcctId.put(a.Id, errorMessages);
        }
              
        Test.startTest();
        AccountBatch_Helper.processFailRecords(errorMessageByFailedAcctId, 'Insert');
        Test.stopTest();  
        
        List<Exception_Record__c> exceptionRecordList = new List<Exception_Record__c>();
        exceptionRecordList = [Select Id from Exception_Record__c];
        
        system.assertEquals(advertiserAccounts.size(), exceptionRecordList.size(), 'Exception Records are not created as expected');
    }  
    
    static testMethod void runAccountCalculateTcsTasBatchTest() 
    {
        setupTestData(); 
              
        Test.startTest();
        AccountBatch_Helper.runAccountCalculateTcsTasBatch(advertiserAccounts[0].Id);
        Test.stopTest();  
    }     
}