/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 */
@isTest
private class AccountTeamManagement_Trigger_Test 
{
    static testMethod void AccountTeamTest() 
    {
        
        List<UserRole> userRoles = [Select Id from UserRole limit 1];
        //List<UserRole> userRoles = TestDataFactory.createUserRoles(10);
        List<User> users = TestDataFactory.createUsers(21, 'System Administrator', userRoles, null, false);
        insert users;
        
        // set up accounts
        List<Account> accounts = TestDataFactory.createAccounts(10, false);
        System.runAs(users[0])
        {
            insert accounts;
        }
        
        // assign users to account teams
        List<AccountTeamMember> atms = new List<AccountTeamMember>();
        
        for(Account a : accounts)
        {
            for(Integer i = 1; i < users.size() - 1; i++)
            {
                atms.add(new AccountTeamMember(UserId = users[i].Id, AccountId = a.Id, TeamMemberRole = 'Sales Manager'));
            }
        }
        
        System.runAs(users[0])
        {
            insert atms;
        }
        
        // start test
        Test.startTest();
        
        Map<Id, Set<Id>> accountTeamMembersByAccountId = new Map<Id, Set<Id>>();
        
        // verify account team members before changing the owner of accounts
        for(AccountTeamMember atm : [Select AccountId, UserId From AccountTeamMember Where AccountId IN: accounts])
        {
            if(!accountTeamMembersByAccountId.containsKey(atm.AccountId))
            {
                accountTeamMembersByAccountId.put(atm.AccountId, new Set<Id>());
            }
            
            accountTeamMembersByAccountId.get(atm.AccountId).add(atm.UserId);
        }
        
        
        system.debug(logginglevel.error, '@accountTeamMembersByAccountId: ' + accountTeamMembersByAccountId);
        
        for(Account acct : Accounts)
        {
            Set<Id> teamMemberUserIds = accountTeamMembersByAccountId.get(acct.Id);
            
            system.debug(logginglevel.error, '===teamMemberUserIds 1=== ' + teamMemberUserIds);
            
            for(Integer i = 1; i < Users.size() - 1; i++)
            {
                system.debug(logginglevel.error, '@Users[i].Id ' + Users[i].Id);
                system.assert(teamMemberUserIds.contains(Users[i].Id));
            }
        }
        
        // change owner of accounts
        for(Account acct : Accounts)
        {
            acct.OwnerId = users[users.size() - 1].Id;
        }
        
        System.runAs(users[0])
        {
            update Accounts;
        }
        
        // verify account team members after changing the owner of accounts
        accountTeamMembersByAccountId.clear();
        
        for(AccountTeamMember atm : [Select AccountId, UserId From AccountTeamMember Where AccountId IN: accounts])
        {
            if(!accountTeamMembersByAccountId.containsKey(atm.AccountId))
            {
                accountTeamMembersByAccountId.put(atm.AccountId, new Set<Id>());
            }
            
            accountTeamMembersByAccountId.get(atm.AccountId).add(atm.UserId);
        }
        
        for(Account acct : Accounts)
        {
            Set<Id> teamMemberUserIds = accountTeamMembersByAccountId.get(acct.Id);
            
            system.debug(logginglevel.error, '===teamMemberUserIds 2=== ' + teamMemberUserIds);
            
            for(Integer i = 1; i < Users.size(); i++)
            {
                system.assert(teamMemberUserIds.contains(Users[i].Id));
            }
        }
        
        Test.stopTest();
    }
}