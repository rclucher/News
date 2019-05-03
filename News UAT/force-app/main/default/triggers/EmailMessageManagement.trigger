/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This trigger is for 
 *  1. Requirement: R-1275: when custom replies to case, it needs to update case origin back to 'Email - Inbound for Routing'
 *                  so case can fire Genesys trigger. It also needs to update case owner to queue based on suppliedToEmail.
 * History:
 * 20/11/2013  Bohao Chen  Created
 * 25/02/2014  Bohao Chen  Updated 
 * 26/10/2015  Louis Wang  Updated through Case_Helper - SFE-688 - Use Alias email address to fetch Primary email address
 * 2016-01-27  Louis Wang  Refactored and modulised code into EmailMessageTrigger_helper, for ease of maintenance in the future.
 ---------------------------------------------------------*/
trigger EmailMessageManagement on EmailMessage (before insert, after insert) 
{
     //Mohamed Atheek, Daniel garzon 06/07/2015
    //verify if CNN batch job is running
    CCNBatchJobSetting__c batchSetting = CCNBatchJobSetting__c.getInstance();
    if(!batchSetting.Is_EmailMessage_Batch_Running__c)
    {
        // generate the map so both before and after insert can use it
        Map<String, String> primary_By_Alias_Map = EmailMessageTrigger_Helper.fetch_Primary_By_Alias_Map(Trigger.new);
        if(Trigger.isInsert && Trigger.isBefore)
        {
            // Available Trigger Context: new
            EmailMessageTrigger_Helper.parseHtmlContent(Trigger.new);
            // SFE-830 2016-01-27 louis.wang@bluewolf.com - Updates both ToAddress and CcAddress on EmailMessage, 
            //                                                  so Primary (rather than Alias) address is used
            EmailMessageTrigger_Helper.updateEmailMessages(Trigger.new, primary_By_Alias_Map);
        }
        else if(Trigger.isInsert && Trigger.isAfter)
        {
            // Available Trigger Context: new, newMap
            EmailMessageTrigger_Helper.updateCases(Trigger.new, primary_By_Alias_Map);
        }   
    }    
}