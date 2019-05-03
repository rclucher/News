/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	Virtual class used by all triggers
Test Class:		n/a
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing virtual class CS_GenericTriggerHandler
{
	public void processLifecycleEvents()
	{
		if (trigger.isBefore)
		{
			if (trigger.isInsert)
			{
				doBeforeInsert(trigger.new);
			}
			else if (trigger.isUpdate)
			{
				doBeforeUpdate(trigger.oldMap, trigger.newMap);
				
			}
			else if (trigger.isDelete)
			{
				doBeforeDelete(trigger.oldMap);
			}
		}
		else if (trigger.isAfter)
		{
			if (trigger.isInsert)
			{
				doAfterInsert(trigger.newMap);
				
			}
			else if (trigger.isUpdate)
			{
				doAfterUpdate(trigger.oldMap, trigger.newMap);
				
			}
			else if (trigger.isDelete)
			{
				doAfterDelete(trigger.oldMap);
			}
			else if (trigger.isUnDelete)
			{
				doAfterUnDelete(trigger.newMap);
			}
		}
	}
    

	public virtual void doBeforeInsert(list<SObject> newRecords ) {}
  
	public virtual void doAfterInsert(map<id, SObject> map_newRecords ) {}
  
	public virtual void doBeforeUpdate(map<id, SObject> map_oldRecords, map<id, SObject> map_newRecords ) {}
  
	public virtual void doAfterUpdate(map<id, SObject> map_oldRecords, map<id, SObject> map_newRecords ) {}
  
	public virtual void doBeforeDelete(map<id, SObject> map_oldRecords ) {}
  
	public virtual void doAfterDelete(map<id, SObject> map_oldRecords ) {}
  
	public virtual void doAfterUnDelete(map<id, SObject> map_newRecords ) {}

}