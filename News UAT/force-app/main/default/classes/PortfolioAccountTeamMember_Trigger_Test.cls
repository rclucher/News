/*---------------------------------------------------------
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Paul Fayle
 * Company: Salesforce.com
 * Description: This is test class for trigger 'AccountTeam on Portfolio__c'
 * History:
 * 25/06/2013  Paul Fayle  Created
 * 02/07/2013  Bohao Chen  Updated
 ---------------------------------------------------------*/
@isTest (SeeAllData=false)
public with sharing class PortfolioAccountTeamMember_Trigger_Test 
{
    static testMethod void createPortofolioTest() 
    {
        List<UserRole> userRoles = [Select Id from UserRole limit 1];
        //List<UserRole> userRoles = TestDataFactory.createUserRoles(10);
        List<User> users = TestDataFactory.createUsers(20, 'System Administrator', userRoles, null, false);
        insert users;
        
        System.runAs(users[0])
        {
            // create account test data
            List<Account> accounts = TestDataFactory.createAccounts(20, false);
            insert accounts;
            
            Test.startTest();
            
            // insert portfolio
            List<Portfolio__c> portfolios = TestDataFactory.createPortfolios(accounts, users);
            
            //Start insert validation
            set<id> accountIds = new set<id>();
            set<id> userIds = new set<id>();
            set<String> teamMemberRoles = new set<String>();
    
            for(Portfolio__c p : portfolios)
            {
                accountIds.add(p.Account__c);
                userIds.add(p.User__c);
                teamMemberRoles.add(p.Team_Role__c);
            }
            
            map<String,list<AccountTeamMember>> accountTeamMemberByComplexKey = new map<String,list<AccountTeamMember>>();
    
            for(AccountTeamMember atm : [Select id, AccountId, UserId, TeamMemberRole 
                                        From AccountTeamMember
                                        Where AccountId IN :accountIds 
                                        AND UserId IN :userIds 
                                        AND TeamMemberRole IN :teamMemberRoles])
            {
                String complexKey = String.valueOf(atm.AccountId) + String.valueOf(atm.UserId) + atm.TeamMemberRole;
                
                if(!accountTeamMemberByComplexKey.containsKey(complexKey))
                {
                    accountTeamMemberByComplexKey.put(complexKey, new List<AccountTeamMember>());
                }
                    
                accountTeamMemberByComplexKey.get(complexKey).add(atm);
            }
            
            map<String, list<AccountShare>> accountShareByComplexKey = new map<String, list<AccountShare>>();
    
            for(AccountShare accountShare : [Select id, UserOrGroupId, Accountid from AccountShare
                                            Where UserOrGroupId IN :userIds
                                            AND Accountid IN :accountIds])
            {
                String complexKey = String.valueOf(accountShare.UserOrGroupId) + String.valueOf(accountShare.Accountid);
                
                if(!accountShareByComplexKey.containsKey(complexKey))
                {
                    accountShareByComplexKey.put(complexKey, new List<AccountShare>());
                }
                    
                accountShareByComplexKey.get(complexKey).add(accountShare);
            }
    
            for(Portfolio__c p : portfolios)
            {
                String complexKey = String.valueOf(p.Account__c) + String.valueOf(p.User__c) + String.valueOf(p.Team_Role__c);
                //system.assert(accountTeamMemberByComplexKey.containsKey(complexKey));
                
                complexKey = String.valueOf(p.User__c) + String.valueOf(p.Account__c);
                //system.assert(accountShareByComplexKey.containsKey(complexKey));
            }
            
            Test.stopTest();
       }
    }
    
    static testMethod void updatePortofolioTest() 
    {
        List<UserRole> userRoles = [Select Id from UserRole limit 1];
        //List<UserRole> userRoles = TestDataFactory.createUserRoles(10);

        List<User> users = TestDataFactory.createUsers(20, 'System Administrator', userRoles, null, false);
        insert users;
        
        System.runAs(users[0])
        {
            // create account test data
            List<Account> accounts = TestDataFactory.createAccounts(20, false);
            insert accounts;
            
            // insert portfolio
            List<Portfolio__c> portfolios = TestDataFactory.createPortfolios(accounts, users);
            
            Test.startTest();
            
            for(Portfolio__c p : portfolios)
            {
                p.Team_Role__c = 'Market Manager';
            }
            
            update portfolios;
            
            // start update validation
            set<id> accountIds = new set<id>();
            set<id> userIds = new set<id>();
            set<String> teamMemberRoles = new set<String>();
    
            for(Portfolio__c p : portfolios)
            {
                accountIds.add(p.Account__c);
                userIds.add(p.User__c);
                teamMemberRoles.add(p.Team_Role__c);
            }
            
            map<String,list<AccountTeamMember>> accountTeamMemberByComplexKey = new map<String,list<AccountTeamMember>>();
    
            for(AccountTeamMember atm : [Select id, AccountId, UserId, TeamMemberRole 
                                        From AccountTeamMember
                                        Where AccountId IN :accountIds 
                                        AND UserId IN :userIds 
                                        AND TeamMemberRole IN :teamMemberRoles])
            {
                String complexKey = String.valueOf(atm.AccountId) + String.valueOf(atm.UserId) + atm.TeamMemberRole;
                
                if(!accountTeamMemberByComplexKey.containsKey(complexKey))
                {
                    accountTeamMemberByComplexKey.put(complexKey, new List<AccountTeamMember>());
                }
                    
                accountTeamMemberByComplexKey.get(complexKey).add(atm);
            }
            
            for(Portfolio__c p : portfolios)
            {
                String complexKey = String.valueOf(p.Account__c) + String.valueOf(p.User__c) + String.valueOf(p.Team_Role__c);
                system.assert(accountTeamMemberByComplexKey.containsKey(complexKey));
                
                for(AccountTeamMember a : accountTeamMemberByComplexKey.get(complexKey))
                {
                    system.assertEquals('Market Manager', a.TeamMemberRole);
                }
            }
            
            Test.stopTest();
        }
    }
}