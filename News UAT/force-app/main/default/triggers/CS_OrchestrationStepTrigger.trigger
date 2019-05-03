trigger CS_OrchestrationStepTrigger on CSPOFA__Orchestration_Step__c (
    before insert, 
    before update, 
    before delete, 
    after insert, 
    after update, 
    after delete, 
    after undelete) { CS_TriggerHandler.execute(new CS_OrchestrationStepTriggerDelegate()); }