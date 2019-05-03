trigger NXX2_ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Static Boolean hasExecuted = false;
    if(!hasExecuted){
        hasExecuted = true;
    	NXX2_TriggerDispatcher.Run(new NXX2_Contact_TriggerHandler()); 
    }
}