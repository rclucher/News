@isTest(SeeAllData=false)
public class AT_AccountUpdateBatchJob_Test {
    testMethod static void testAccountBatchUpdate(){
        Profile p = [select id from Profile where name = 'System Administrator'];
                
        User TestUser = new User(Alias = 'testUser', Email='testuser@test.com', 
             EmailEncodingKey='UTF-8', LastName='Testing001', LanguageLocaleKey='en_US', TimeZoneSidKey='America/Los_Angeles' ,
             LocaleSidKey='en_US', ProfileId = p.Id, UserName='testuser@test.news.com');
        insert TestUser;
         
        Account acc = TestDataSetupClass.createAccount();
        //acc.Customer_Segment__c = '';
        insert acc;
        
        List<Portfolio2__c> portfolioList = new List<Portfolio2__c>();
        Portfolio2__c portfolio1 = new Portfolio2__c();
        Portfolio2__c portfolio2 = new Portfolio2__c();
        portfolio1.Name = 'Product';
        portfolio2.Name = 'Marketing';
        portfolio1.Portfolio_Segment__c = 'CON';
        portfolio2.Portfolio_Segment__c = 'Key';
        portfolioList.add(portfolio1);
        portfolioList.add(portfolio2);
        insert portfolioList;
        
        List<Account_Portfolio_Relationship__c> accportList = new List<Account_Portfolio_Relationship__c>();
        Account_Portfolio_Relationship__c accport1 = new Account_Portfolio_Relationship__c();
        accport1.Name = 'NewsCorp Digital - Test';
        accport1.Portfolio__c = portfolio1.Id;
        accport1.Account__c = acc.Id;
        accportList.add(accport1);
        
        Account_Portfolio_Relationship__c accport2 = new Account_Portfolio_Relationship__c();
        accport2.Name = 'NewsCorp Digital - Test';
        accport2.Portfolio__c = portfolio1.Id;
        accport2.Account__c = acc.Id;
        accportList.add(accport2);
        insert accportList;
        
        
        External_Account__c extacc = new External_Account__c();
        extacc.Customer_Account__c = acc.Id;
        extacc.Name = 'Booking System for Account'; 
        extacc.External_Id__c = '1et1yuia0';
        insert extacc;
        
        Booking_System_Portfolio_Junction__c bookingSysPortfolio = new Booking_System_Portfolio_Junction__c ();
        bookingSysPortfolio.Booking_System_Account__c = extacc.Id;
        bookingSysPortfolio.Portfolio__c = portfolio1.Id;
        insert bookingSysPortfolio;
        
        System.test.startTest();
            Database.executeBatch(new AT_AccountUpdateBatchJob());
        System.Test.stopTest();
     
     }
}