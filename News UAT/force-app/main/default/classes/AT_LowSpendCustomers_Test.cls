@isTest
public class AT_LowSpendCustomers_Test {
    @isTest
    static void testLowSpendCustomer() {
        RecordType accountRT = [SELECT Id FROM RecordType WHERE (SObjectType = 'Account') AND (DeveloperName = 'SME') LIMIT 1];
        
        Account acc1 = new Account(Name = 'Test', No_Parent_Account__c = true, RecordTypeId = accountRT.Id);
        
        insert acc1;
        
        Contact cont1 = new Contact(AccountId = acc1.Id, LastName = 'test', FirstName = 'test', Email = 'test@example.com');
        
        insert cont1;
        
        Date thisFY = System.today();
        
        Date lastFY = Date.newInstance(thisFY.year() - 1, thisFY.month(), thisFY.day());
        
        Opportunity oppOld = new Opportunity(Name = 'Last FY Opp', Description = 'test', Contact__c = cont1.Id, StageName = 'Establish Rapport', Competitor__c = 'No Competitor', Classification__c = 'Existing Business', AccountId = acc1.Id, CloseDate = lastFY, Amount = 1000);
        Opportunity oppNew = new Opportunity(Name = 'Current FY Opp', Description = 'test', Contact__c = cont1.Id, StageName = 'Establish Rapport',Competitor__c = 'No Competitor',Classification__c = 'Existing Business',  AccountId = acc1.Id, CloseDate = thisFY, Amount = 500);
        
        insert oppOld;
        insert oppNew;
        
        Test.startTest();
        
        List<AT_LowSpendCustomers.AccountSpend> lowSpend = AT_LowSpendCustomers.getSpending(UserInfo.getUserId(), 5);
        
        System.assertEquals(1, lowSpend.size());
        
        Test.stopTest();
    }
    
    @isTest
    static void testSorting() {
        AT_LowSpendCustomers.AccountSpend less = new AT_LowSpendCustomers.AccountSpend();
        AT_LowSpendCustomers.AccountSpend more = new AT_LowSpendCustomers.AccountSpend();
        
        List<AT_LowSpendCustomers.AccountSpend> spends = new List<AT_LowSpendCustomers.AccountSpend>();
        
        less.Difference = 10;
        more.Difference = 20;
        
        spends.add(less);
        spends.add(more);
        
        spends.sort();
        
        System.assertEquals(spends[0].Difference, more.Difference);
        System.assertEquals(spends[1].Difference, less.Difference);
        
        spends = new List<AT_LowSpendCustomers.AccountSpend>();
        
        less.Difference = 15;
        more.Difference = 25;
        
        spends.add(more);
        spends.add(less);
        
        spends.sort();
        
        System.assertEquals(spends[0].Difference, more.Difference);
        System.assertEquals(spends[1].Difference, less.Difference);
        
        spends = new List<AT_LowSpendCustomers.AccountSpend>();
        
        spends.add(more);
        spends.add(more);
        
        spends.sort();
        
        System.assertEquals(spends[0].Difference, more.Difference);
        System.assertEquals(spends[1].Difference, more.Difference);
    }
}