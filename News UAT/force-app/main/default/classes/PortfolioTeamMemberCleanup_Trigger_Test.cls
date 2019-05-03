/*---------------------------------------------------------
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Paul Fayle
 * Company: Salesforce.com
 * Description: This is test class for trigger 'AccountTeamCleanup on Portfolio__c'
 * History:
 * 25/06/2013  Paul Fayle  Created
 * 02/07/2013  Bohao Chen  Updated
 * ---------------------------------------------------------*/
@isTest(SeeAllData=false)
public with sharing class PortfolioTeamMemberCleanup_Trigger_Test 
{
    static testMethod void cleanAccountTeamTest() 
    {
        List<UserRole> userRoles = [Select Id from UserRole limit 1];
        //List<UserRole> userRoles = TestDataFactory.createUserRoles(10);
        List<User> users = TestDataFactory.createUsers(20, 'System Administrator', userRoles, null, false);
        insert users;
        
        System.runAs(users[0])
        {
            List<Account> accounts = TestDataFactory.createAccounts(20, false);
            insert accounts;
            
            List<Portfolio__c> portfolios = TestDataFactory.createPortfolios(accounts, users);
            
            // check if insert made successfully
            // Start insert validation
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
                system.assert(accountTeamMemberByComplexKey.containsKey(complexKey));
                
                complexKey = String.valueOf(p.User__c) + String.valueOf(p.Account__c);
                //system.assert(accountShareByComplexKey.containsKey(complexKey));
            }
            
            Test.startTest();
            
            // deletion test
            delete portfolios;
            
            accountTeamMemberByComplexKey = new map<String,list<AccountTeamMember>>();
    
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
            
            // check size of AccountTeamMember list should be 0
            for(String atmKey : accountTeamMemberByComplexKey.keySet())
            {
                system.assertEquals(0, accountTeamMemberByComplexKey.get(atmKey).size());
            }
            
            accountShareByComplexKey = new map<String, list<AccountShare>>();
    
            for(AccountShare accountShare : [Select id, UserOrGroupId, Accountid from AccountShare
                                            Where UserOrGroupId IN :userIds
                                            AND Accountid IN :accountIds
                                            AND RowCause = 'Manual'])
            {
                String complexKey = String.valueOf(accountShare.UserOrGroupId) + String.valueOf(accountShare.Accountid);
                
                if(!accountShareByComplexKey.containsKey(complexKey))
                {
                    accountShareByComplexKey.put(complexKey, new List<AccountShare>());
                }
                    
                accountShareByComplexKey.get(complexKey).add(accountShare);
            }
            
            // check size of AccountShare list should be 0
            for(String osrKey : accountTeamMemberByComplexKey.keySet())
            {
                system.assertEquals(0, accountShareByComplexKey.get(osrKey).size());
            }
            
            Test.stopTest();

        }     
    }
}