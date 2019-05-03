trigger Answer2Management on Answer2__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update)
{
	Answer2Management process = new Answer2Management();
	process.processLifecycleEvents();
}