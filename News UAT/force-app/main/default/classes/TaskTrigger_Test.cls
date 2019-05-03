@isTest
public class TaskTrigger_Test {
	@isTest
    static void testTaskCompleted() {
        Account acc = new Account(Name = 'Test', AccountNumber = '1234567890', No_Parent_Account__c = true, ABN_Exempt__c = true);
        
        insert acc;
        
        Task tk = new Task(ActivityDate = System.Today(), Subject = 'test', OwnerId = UserInfo.getUserId(), WhatId = acc.Id);
        
        insert tk;
        
        tk.Status = 'Completed';
        
        update tk;
        
        acc = [SELECT Last_Client_Engagement__c FROM Account WHERE Id = :acc.Id];
            
        System.assertNotEquals(null, acc.Last_Client_Engagement__c);
        
        System.assertEquals(System.Today(), acc.Last_Client_Engagement__c.date());
    }
}