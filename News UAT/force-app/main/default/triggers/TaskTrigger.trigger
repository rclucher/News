/*
 * Authour: Peter Charalambous
 * Company: Bluewolf
 * Date: 16/08/2016
 * Description: Fire functions on TaskTrigger_Helper
 *
 */
 
trigger TaskTrigger on Task (before insert, after insert, after update)
{
    //execute the Designate Task Record function from the helper class
    if(Trigger.isBefore && Trigger.isInsert)
    {
        TaskTrigger_Helper.designateTaskRecordType();

    }
    
    //execute the routing function from the helper class
    if(Trigger.isAfter && Trigger.isInsert)
    {
        TaskTrigger_Helper.NVMCaseRouting(Trigger.New);
    }


/*Commenting this code that I have written to get more details before doing testing
We are commenting this method until the requirements are approved by Business for Tasks & Events.
*/

if(Trigger.isAfter && Trigger.isUpdate){
        //Execute this if to update the last client engagement date if the created status of a Task = Completed / Done or the Task is updated after creation
        TaskTrigger_Helper.UpdateLastClientEngagement(Trigger.New, Trigger.oldMap);    
    }
}