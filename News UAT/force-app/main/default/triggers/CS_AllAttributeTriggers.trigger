trigger CS_AllAttributeTriggers on cscfga__Attribute__c (after insert, 
after update, before insert, before update) {
    /*commented by Davor Dubokovic, as AddAttr is commented out function (it has only body)
	if (Trigger.isAfter) {
        CS_AllAttributeTriggerHelper.AddAttr(Trigger.New);
    }
	*/

	//added by Davor Dubokovic as a part of SFE-860
	if ((Trigger.isAfter) && (Trigger.isUpdate))
	{
		CS_AllAttributeTriggerHelper.afterUpdate(Trigger.newMap, Trigger.oldMap);
	}
	//end of code done by Davor Dubokovic as a part of SFE-860

    if (Trigger.isBefore && Trigger.isUpdate) {
    	CS_AllAttributeTriggerHelper.beforeUpdate(Trigger.newMap, Trigger.oldMap);
    }
    if (Trigger.isBefore && Trigger.isInsert) {
    	CS_AllAttributeTriggerHelper.beforeInsert(Trigger.new);
    }
}