/*---------------------------------------------------------
* Author: Jamie Cooper (New Voice Media)
* Date: May 2016
* Description: Trigger for the NVM Call Summary object
* Changelog:
    - 12/05/2016 | Jamie Cooper | created and wrote the extract skill functionality to 
      "search and extract values for a long text string (ChkStr field on the NVM Call Summary object) and 
      places them into a custom field on the object. This allows in depth reporting on the call routing."
    - 10/06/2016 | David Dawson | seperated the functionality and took the logic out of the trigger and 
      placed it in a handler class (NVMCallSummary_Helper). Also implemented commenting and formatting.
 ---------------------------------------------------------*/

trigger NVMCallSummary_Trigger on NVMStatsSF__NVM_Call_Summary__c (before insert, before update) {
    
    NVMCallSummary_Helper helper = new NVMCallSummary_Helper();

    //if trigger is before
    if(Trigger.isBefore){
        //if trigger is insert or is update
        if(Trigger.isInsert || Trigger.isUpdate){
            helper.ExtractSkill();
        }
    }

}//end trigger