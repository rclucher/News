/*---------------------------------------------------------------------------------------------------
 * Author: Christopher Henschke
 * Company: Salesforce.com
 * Description: This trigger is for the NLM Project to stamp Opportunity Team members to the Opportunity record
 *              for use in the approval workflow
 *
 * History:
 *
 * 15/01/2015  Christopher Henschke  Created
 * 29/01/2015  Christopher Henschke  Updated to consolidate triggers
 ---------------------------------------------------------------------------------------------------*/
 
trigger OpportunityTeamManagement on OpportunityTeamMember ( before insert, before update, before delete, 
  after insert, after update, after delete, after undelete ) 
{    	
  // verify the user has permission to fire the trigger and verify that the trigger has not already executed
  
  NLM_Global_Settings__c Can_Fire_NLM_Trigger = NLM_Global_Settings__c.getInstance(Userinfo.getProfileId());
  
  if (Can_Fire_NLM_Trigger.Fire_NLM_Triggers__c == true)
  {         
      // runs on after insert only
      if (Trigger.isAfter && Trigger.isInsert)    
      {       
        OpportunityTeamManagement.onAfterInsert(Trigger.new, Trigger.newMap);
      }
       
      // runs on after update only
      else if (Trigger.isAfter && Trigger.isUpdate) {    
        OpportunityTeamManagement.onAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);  
      }
      
      // runs on after delete only
      else if (Trigger.isAfter && Trigger.isDelete) {
      	OpportunityTeamManagement.onAfterDelete(Trigger.old, Trigger.oldMap);
      } 
  }   
}