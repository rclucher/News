/*---------------------------------------------------------------------------------------------------
* Author: Christopher Henschke
* Company: Salesforce.com
* Description: This class is for the NLM Project to stamp Opportunity Team members to the Opportunity record
*              for use in the approval workflow. Called by a trigger on insert and update.
*
* Note: This trigger will not work when a user has a default Opportunity Team. 
* Please see https://help.salesforce.com/HTViewSolution?id=000187820&language=en_US
*
* History:
*
* 15/01/2015  Christopher Henschke  Created
* 25/01/2015  Christopher Henschke  Updated to only require 1 approver. Original requirement had from 4 to 10 approvers
* 29/01/2015  Christopher Henschke  Updated to replace NLM Brand Strategy Manager role with NLM Lead Brand Strategy Manager and
*                                   added the role NLM Creative Services Traffic Manager who can also approve opportunities
---------------------------------------------------------------------------------------------------*/

public without sharing class OpportunityTeamManagement {
 
/*---------------------------------------------------------------------------------------------------
* 
* Trigger handler class for after insert event
*
---------------------------------------------------------------------------------------------------*/
   
  public static void onAfterInsert(List <OpportunityTeamMember> newRecords, Map <Id, OpportunityTeamMember> newMap)
  {
    // method variable declaration      
    List <ID> listTeamMemberID = new List<ID>();
    List <String> listTeamMemberRole = new List<String>();
    List <ID> listOpportunityID = new List<ID>();

    Integer index = 0;
      
    // find all NLM team members in the Opportunity Team and add to the list listTeamMemberID and listTeamMemberRole
    for (OpportunityTeamMember NLMTeam: newRecords)
    { 
      if (NLMTeam.TeamMemberRole == 'NLM Lead Brand Strategy Manager' || NLMTeam.TeamMemberRole == 'NLM Operations' ||
          NLMTeam.TeamMemberRole == 'NLM Creative Services Traffic Manager')
      {       	
        listTeamMemberID.add(NLMTeam.UserId);
        listTeamMemberRole.add(NLMTeam.TeamMemberRole);    
      	listOpportunityID.add(NLMTeam.OpportunityId);  
      }
    }  
      
    system.debug('@@@debug_insert_trigger_listTeamMemberID ' + listTeamMemberID);
    system.debug('@@@debug_insert_trigger_listTeamMemberRole ' + listTeamMemberRole);
    system.debug('@@@debug_insert_trigger_listOpportunityID ' + listOpportunityID);
            
    // get parent opportunity and fields to update
    Opportunity[] parentOpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, NLM_Opportunity_Team_Member_2__c,
      NLM_Opportunity_Team_Member_3__c from Opportunity where ID IN :listOpportunityID order by ID limit 200];
      
    system.debug('@@@debug_insert_trigger_parentOpptyList ' + parentOpptyList);
            
    for (Opportunity oppty : parentOpptyList)
    {
	  for (ID opptyID : listOpportunityID)
	  {
	    if (oppty.ID == opptyID && index < listOpportunityID.size())
	    {
          if (oppty.NLM_Opportunity_Team_Member_1__c == NULL && listTeamMemberRole[index] == 'NLM Lead Brand Strategy Manager')
          {
            oppty.NLM_Opportunity_Team_Member_1__c = listTeamMemberID[index];
          } 
          else if (oppty.NLM_Opportunity_Team_Member_2__c == NULL && listTeamMemberRole[index] == 'NLM Operations')
          {
            oppty.NLM_Opportunity_Team_Member_2__c = listTeamMemberID[index];
          }
          else if (oppty.NLM_Opportunity_Team_Member_3__c == NULL && listTeamMemberRole[index] == 'NLM Creative Services Traffic Manager')
          {
            oppty.NLM_Opportunity_Team_Member_3__c = listTeamMemberID[index];
          }
	    }
	     
	    index ++;
	  }
    }
   
    try
    {
      update parentOpptyList;
    } 
    catch (Exception e)
    {
      system.debug('The following exception has occurred: ' + e.getMessage());
    }
  }

/*---------------------------------------------------------------------------------------------------
* 
* Trigger handler class for after update event
*
---------------------------------------------------------------------------------------------------*/
    
  public static void onAfterUpdate(List<OpportunityTeamMember> oldRecords, List<OpportunityTeamMember> newRecords, 
    Map <Id, OpportunityTeamMember> oldMap, Map <Id, OpportunityTeamMember> newMap)
  {
    system.debug('@@@update_trigger_oldRecords ' + oldRecords);
    system.debug('@@@update_trigger_newRecords ' + newRecords);
    
    // 1. Get a list of opportunity id's, user id's and roles that have been updated (old values and new values)
    List <ID> oldlistOpportunityID = new List<ID>();
    List <ID> oldlistUserID = new List<ID>();
    List <String> oldlistTeamMemberRole = new List<String>(); 
    List <String> newlistTeamMemberRole = new List<String>(); 
    
    Integer index = 0;
      
    for (OpportunityTeamMember NLMTeam: oldRecords)
    {    
      oldlistOpportunityID.add(NLMTeam.OpportunityId);  
      oldlistUserID.add(NLMTeam.UserId);
      oldlistTeamMemberRole.add(NLMTeam.TeamMemberRole);
    }  
    
    for (OpportunityTeamMember NLMTeam: newRecords)
    {    
      newlistTeamMemberRole.add(NLMTeam.TeamMemberRole);
    }  
      
    system.debug('@@@update_trigger_oldlistUserID ' + oldlistUserID);
    system.debug('@@@update_trigger_oldlistTeamMemberRole ' + oldlistTeamMemberRole);
    system.debug('@@@update_trigger_newlistTeamMemberRole ' + newlistTeamMemberRole);
      
    // 2. Retrieve opportunities from the database 
    Opportunity[] parentOpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, NLM_Opportunity_Team_Member_2__c,
      NLM_Opportunity_Team_Member_3__c from Opportunity where ID IN :oldlistOpportunityID order by ID limit 200];

    system.debug('@@@update_trigger_parentOpptyList ' + parentOpptyList);
 
    // 3. Compare old and new. We are only interested in records where old Role changes from NLM Lead Brand Strategy Manager / NLM Operations / 
    //    NLM Creative Services Traffic Manager and where new role changes to NLM Lead Brand Strategy Manager / NLM Operations / NLM Creative Services Traffic Manager
    //    Set fields in opportunity to null if old Role changes from NLM Lead Brand Strategy Manager / NLM Operations / NLM Creative Services Traffic Manager
     
    for (Opportunity oppty : parentOpptyList)
    {
      if (oldlistOpportunityID[index] == oppty.Id && oldlistUserID[index] == oppty.NLM_Opportunity_Team_Member_1__c && 
          oldlistTeamMemberRole[index] == 'NLM Lead Brand Strategy Manager' && newlistTeamMemberRole[index] != 'NLM Lead Brand Strategy Manager')
      {
        oppty.NLM_Opportunity_Team_Member_1__c = NULL;
      }
      else if (oldlistOpportunityID[index] == oppty.Id && oldlistUserID[index] == oppty.NLM_Opportunity_Team_Member_2__c && 
               oldlistTeamMemberRole[index] == 'NLM Operations' && newlistTeamMemberRole[index] != 'NLM Operations')
      {
        oppty.NLM_Opportunity_Team_Member_2__c = NULL;
      }
      else if (oldlistOpportunityID[index] == oppty.Id && oldlistUserID[index] == oppty.NLM_Opportunity_Team_Member_3__c && 
               oldlistTeamMemberRole[index] == 'NLM Creative Services Traffic Manager' && newlistTeamMemberRole[index] != 'NLM Creative Services Traffic Manager')
      {
        oppty.NLM_Opportunity_Team_Member_3__c = NULL;
      }
      else if (oldlistOpportunityID[index] == oppty.Id && oppty.NLM_Opportunity_Team_Member_1__c == NULL && 
               newlistTeamMemberRole[index] == 'NLM Lead Brand Strategy Manager' && oldlistTeamMemberRole[index] != 'NLM Lead Brand Strategy Manager')
      {
        oppty.NLM_Opportunity_Team_Member_1__c = oldlistUserID[index];
      }
      else if (oldlistOpportunityID[index] == oppty.Id && oppty.NLM_Opportunity_Team_Member_2__c == NULL && 
               newlistTeamMemberRole[index] == 'NLM Operations' && oldlistTeamMemberRole[index] != 'NLM Operations')
      {
        oppty.NLM_Opportunity_Team_Member_2__c = oldlistUserID[index];
      }
      else if (oldlistOpportunityID[index] == oppty.Id && oppty.NLM_Opportunity_Team_Member_3__c == NULL && 
               newlistTeamMemberRole[index] == 'NLM Creative Services Traffic Manager' && oldlistTeamMemberRole[index] != 'NLM Creative Services Traffic Manager')
      {
        oppty.NLM_Opportunity_Team_Member_3__c = oldlistUserID[index];
      }
      index++;
      
      system.debug('@@@update_trigger_oppty ' + oppty);
    }
      
    try
    {
      update parentOpptyList;
      
      system.debug('@@@update_trigger_parentOpptyList2 ' + parentOpptyList);
    } 
    catch (Exception e)
    {
      system.debug('The following exception has occurred: ' + e.getMessage());
    }  
      
  }
  
/*---------------------------------------------------------------------------------------------------
* 
* Trigger handler class for after delete event
*
---------------------------------------------------------------------------------------------------*/
    
  public static void onAfterDelete(List<OpportunityTeamMember> oldRecords, Map <Id, OpportunityTeamMember> oldMap)
  {
  	system.debug('@@@delete_trigger_oldRecords ' + oldRecords);
    
    // 1. Get a list of opportunity id's, user id's and roles that have opportunity team members deleted
    List <ID> listOpportunityID = new List<ID>();
    List <ID> listUserID = new List<ID>();
    List <String> listTeamMemberRole = new List<String>(); 
    Integer index = 0;
      
    for (OpportunityTeamMember NLMTeam: oldRecords)
    {    
      listOpportunityID.add(NLMTeam.OpportunityId);  
      listUserID.add(NLMTeam.UserId);
      listTeamMemberRole.add(NLMTeam.TeamMemberRole);
    }  
      
    // 2. Retrieve opportunities from the database 
    Opportunity[] parentOpptyList = [select ID, NLM_Opportunity_Team_Member_1__c, NLM_Opportunity_Team_Member_2__c,
      NLM_Opportunity_Team_Member_3__c from Opportunity where ID IN :listOpportunityID order by ID limit 200];

    system.debug('@@@delete_trigger_parentOpptyList ' + parentOpptyList);
 
    // 3. Set fields in opportunity to null if opportunity team member has been deleted
    for (Opportunity oppty : parentOpptyList)
    {
      if (listOpportunityID[index] == oppty.Id && listUserID[index] == oppty.NLM_Opportunity_Team_Member_1__c && listTeamMemberRole[index] == 'NLM Lead Brand Strategy Manager')
      {
        oppty.NLM_Opportunity_Team_Member_1__c = NULL;
      }
      else if (listOpportunityID[index] == oppty.Id && listUserID[index] == oppty.NLM_Opportunity_Team_Member_2__c && listTeamMemberRole[index] == 'NLM Operations')
      {
        oppty.NLM_Opportunity_Team_Member_2__c = NULL;
      }
      else if (listOpportunityID[index] == oppty.Id && listUserID[index] == oppty.NLM_Opportunity_Team_Member_3__c && listTeamMemberRole[index] == 'NLM Creative Services Traffic Manager')
      {
        oppty.NLM_Opportunity_Team_Member_3__c = NULL;
      }
      index++;
    }
   
    try
    {
      update parentOpptyList;
      
      system.debug('@@@delete_trigger_parentOpptyList2 ' + parentOpptyList);
    } 
    catch (Exception e)
    {
      system.debug('The following exception has occurred: ' + e.getMessage());
    }
      
  }
}