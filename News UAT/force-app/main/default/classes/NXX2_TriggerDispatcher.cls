/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_TriggerDispatcher
* @description  This class is the part of framwork used for trigger. 
*				All trigger will call this class only.
*/
public class NXX2_TriggerDispatcher 
{
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  All trigger having functionality related to MyAccount will call this method only.
    * 				This method will check whether the trigger should run or not based on the custom setting.
    * 				If custome setting allows to run the trigger than this method will identify the appropriate method 
    * 				to run based on the action performed on the record.
    * @param        NXX2_TriggerHandler handler
    * @return       void
    */
    public static void Run(NXX2_TriggerHandler handler)
    {
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.IsDisabled()){
           return;
        }
             
        // Detect the current trigger context and fire the relevant methods on the trigger handler:
 
        // Before trigger logic
        if (Trigger.IsBefore )
        {
            if (Trigger.IsInsert)
                handler.BeforeInsert(trigger.new);
 
            if (Trigger.IsUpdate)
                handler.BeforeUpdate(trigger.newMap, trigger.oldMap);
 
            if (Trigger.IsDelete)
                handler.BeforeDelete(trigger.oldMap);
        }
         
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert)
                handler.AfterInsert(Trigger.newMap);
 
            if (Trigger.IsUpdate)
                handler.AfterUpdate(trigger.newMap, trigger.oldMap);
 
            if (trigger.IsDelete)
                handler.AfterDelete(trigger.oldMap);
 
            if (trigger.isUndelete)
                handler.AfterUndelete(trigger.oldMap);
        }
    }
}