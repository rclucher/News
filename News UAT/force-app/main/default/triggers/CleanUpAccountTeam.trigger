/*---------------------------------------------------------
 * Author: Paul fayle
 * Company: Salesforce.com
 * Description: Trigger to cleanup AccountTeam members and shares based
 * on Portfolio removal
 * History:
 * 25/06/2013   Paul Fayle  Created
 * 01/07/2013   Bohao Chen  Updated
 ---------------------------------------------------------*/
 trigger CleanUpAccountTeam on Portfolio__c (after delete) 
 {
 	if (Global_Helper.canTrigger( 'CleanUpAccountTeam' ) ){
 	set<id> accountIdsFromOld = new set<id>();
 	set<id> userIdsFromOld = new set<id>();
 	set<String> teamMemberRolesFromOld = new set<String>();
 	
 	for(Portfolio__c p : trigger.old)
 	{
 		accountIdsFromOld.add(p.Account__c);
        userIdsFromOld.add(p.User__c);
        teamMemberRolesFromOld.add(p.Team_Role__c);
 	}
 	
 	map<String,list<AccountTeamMember>> accountTeamMemberByComplexKey = new map<String,list<AccountTeamMember>>();
 	
 	for(AccountTeamMember atm : [Select id, AccountId, UserId, TeamMemberRole 
                                From AccountTeamMember
                                Where AccountId IN :accountIdsFromOld 
                                AND UserId IN :userIdsFromOld 
                                AND TeamMemberRole IN :teamMemberRolesFromOld])
    {
        String complexKey = String.valueOf(atm.AccountId) + String.valueOf(atm.UserId) + atm.TeamMemberRole;
        
        if(!accountTeamMemberByComplexKey.containsKey(complexKey))
        {
        	accountTeamMemberByComplexKey.put(complexKey, new List<AccountTeamMember>());
        }
            
        accountTeamMemberByComplexKey.get(complexKey).add(atm);
    }
 	
 	map<String, list<AccountShare>> accountShareByComplexKey = new map<String, list<AccountShare>>();
 	
 	for(AccountShare accountShare : [Select id, UserOrGroupId, Accountid, RowCause from AccountShare
 	                                Where UserOrGroupId IN :userIdsFromOld 
 	                                AND Accountid IN :accountIdsFromOld
 	                                AND RowCause = 'Manual'])
 	{
 		System.debug(LoggingLevel.ERROR, '===RowCause=== ' + accountShare.RowCause);
 		
        String complexKey = String.valueOf(accountShare.UserOrGroupId) + String.valueOf(accountShare.Accountid);
        
        if(!accountShareByComplexKey.containsKey(complexKey))
        {
            accountShareByComplexKey.put(complexKey, new List<AccountShare>());
        }
            
        accountShareByComplexKey.get(complexKey).add(accountShare);
 	}
 	
 	list<AccountTeamMember> atmToDelete = new list<AccountTeamMember>();
 	list<AccountShare> osrToDelete = new list<AccountShare>();
 	 
    for (Integer i = 0; i < Trigger.old.size(); i++) 
    {
        //remove Account Team Members
        String complexKey1 = String.valueOf(trigger.old[i].Account__c) + String.valueOf(trigger.old[i].User__c) + String.valueOf(trigger.old[i].Team_Role__c);
        
        if(accountTeamMemberByComplexKey.containsKey(complexKey1))
        {
            atmToDelete.addAll(accountTeamMemberByComplexKey.get(complexKey1));
        }
        
        //remove Account Share
        String complexKey2 = String.valueOf(trigger.old[i].User__c) + String.valueOf(trigger.old[i].Account__c);
        
        if(accountShareByComplexKey.containsKey(complexKey2))
        {
        	osrToDelete.addAll(accountShareByComplexKey.get(complexKey2));
        }
    }
            
    if(osrToDelete.size() > 0)
    {
    	delete osrToDelete;
    }
    
    if(atmToDelete.size() > 0)
    {
        delete atmToDelete;
    }
}
}