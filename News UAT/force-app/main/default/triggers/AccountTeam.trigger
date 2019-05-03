/*---------------------------------------------------------
 * Author: Paul Fayle
 * Company: Salesforce.com
 * Description: Trigger to populate Account Team and Sharing from Portfolio
 * History:
 * 25/06/2013  Paul Fayle  Created
 * 01/07/2013  Bohao Chen  Updated
 ---------------------------------------------------------*/
trigger AccountTeam on Portfolio__c (after insert, after update) 
{
	if (Global_Helper.canTrigger( 'AccountTeam' ) ){
	// for update, it only update account team member
    if(trigger.isUpdate && trigger.isAfter)
    {
        AccountTeamMember[] newMembers = new AccountTeamMember[]{};  // list of new team members to add.  
    	
	    set<id> accountIdsFromOld = new set<id>();
        set<id> userIdsFromOld = new set<id>();
        set<String> teamMemberRolesFromOld = new set<String>();
    
	    for(Portfolio__c p : trigger.old)
	    {
	    	// update AccountTeamMember only when Team_Role__c on portfolio has changed 
	    	if(trigger.oldMap.get(p.Id).Team_Role__c != trigger.newMap.get(p.Id).Team_Role__c)
	    	{
		        accountIdsFromOld.add(p.Account__c);
		        userIdsFromOld.add(p.User__c);
		        teamMemberRolesFromOld.add(p.Team_Role__c);
	    	}
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
	     
        for (Integer i = 0; i < Trigger.old.size(); i++) 
        {
	        //remove Account Team Members
	        String complexKey = String.valueOf(trigger.old[i].Account__c) + String.valueOf(trigger.old[i].User__c) + String.valueOf(trigger.old[i].Team_Role__c);
	        
	        if(accountTeamMemberByComplexKey.containsKey(complexKey))
	        {
	            for(AccountTeamMember a : accountTeamMemberByComplexKey.get(complexKey))
	            {
		            a.TeamMemberRole = trigger.new[i].Team_Role__c;
		            newMembers.add(a);
	            }
	        }	
        }
           
        if(newMembers.size() > 0)
        {
        	update newMembers;
        }
    }
    // if it is insert, create new account team member according to portofolio
    // then, create new account share for this newly created account team member
	else if(trigger.isInsert && trigger.isAfter)
	{
        AccountTeamMember[] newMembers = new AccountTeamMember[]{};  // list of new team members to add.  
        AccountShare[] newShares = new AccountShare[]{};  //list of new shares to add
        
        for(Portfolio__c p:trigger.new)
        {
			AccountTeamMember teamMember = new AccountTeamMember();
			teamMember.AccountId = p.Account__c;
			teamMember.UserId = p.User__c;
			teamMember.TeamMemberRole = p.Team_Role__c;
			newMembers.add(teamMember);
        }
     
        Database.SaveResult[] lsr = Database.insert(newMembers, false);//insert any valid members then add their share entry if they were successfully added
        Integer newcnt=0;
     
        Set<Id> teamMemberIdSet = new Set<Id>();
        
		for(Database.SaveResult sr:lsr)
		{
		    if(!sr.isSuccess())
		    {
		        Database.Error emsg =sr.getErrors()[0];
		        system.debug('\n\nERROR ADDING TEAM MEMBER:'+emsg);
		    }
		    else
		    {
		    	teamMemberIdSet.add(sr.getId()); // get set of new inserted members ids
		    }
		    newcnt++;           
		}
        
        for(AccountTeamMember acctTeamMember : [Select UserId, Accountid From AccountTeamMember Where Id IN: teamMemberIdSet])
        {
            newShares.add(new AccountShare(UserOrGroupId = acctTeamMember.UserId, 
                                          AccountId = acctTeamMember.Accountid, 
                                          AccountAccessLevel='Read/Write',
                                          CaseAccessLevel = 'Read/Write',
							              OpportunityAccessLevel = 'Read/Write'
							              ));
        }
        
        // BC: you can reset value, not neccessary to create another variable
        lsr = Database.insert(newShares,false); //insert the new shares
        
        newcnt = 0;
        
        for(Database.SaveResult sr : lsr)
        {
            if(!sr.isSuccess())
            {
                //Database.Error emsg = sr.getErrors()[0];
                
                // BC: not sure if we can use the following line, because we are not sure order of insertion is the same as order of insertion results 
                //system.debug('\n\nERROR ADDING SHARING:' + newShares[newcnt]+'::'+emsg);
                
		        // Operation failed, so get all errors                
		        for(Database.Error err : sr.getErrors()) 
		        {
		            System.debug('The following error has occurred.');                    
		            System.debug(err.getStatusCode() + ': ' + err.getMessage());
		            System.debug('AccountShare fields that affected this error: ' + err.getFields());
		        }
            }
            
            //newcnt++;
        }
	}

	}
	
     
     
     
}