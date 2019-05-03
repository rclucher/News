public with sharing class CS_OrchestrationStepTriggerDelegate extends CS_TriggerHandler.DelegateBase 
{
    List<CSPOFA__Orchestration_Step__c> orchestrationStepsToBeUpdated;
    List<Id> orchestrationStepIdsToBeUpdated;
    set<Id> setOrchStepsCompleted;

    Map<Id, CSPOFA__Orchestration_Step__c> calculateTargetDate;

    public override void prepareBefore() 
    {
        calculateTargetDate = new Map<id, CSPOFA__Orchestration_Step__c>();
    }

    public override void prepareAfter() 
    {
        orchestrationStepsToBeUpdated = new List<CSPOFA__Orchestration_Step__c>();
        orchestrationStepIdsToBeUpdated = new List<Id>();
        
        setOrchStepsCompleted = new set<Id>();
        
    }

    public override void beforeInsert(sObject o) 
    {}

    public override void beforeUpdate(sObject old, sObject o) 
    {
        CSPOFA__Orchestration_Step__c newProcessStep = (CSPOFA__Orchestration_Step__c)o;
        CSPOFA__Orchestration_Step__c oldProcessStep = (CSPOFA__Orchestration_Step__c)old;
        
        System.debug('***newProcessStep=' + newProcessStep);
        System.debug('***oldProcessStep=' + oldProcessStep);

        
        if (newProcessStep.CSPOFA__Status__c == 'In Progress' && newProcessStep.CSPOFA__Status__c != oldProcessStep.CSPOFA__Status__c)
            calculateTargetDate.put(newProcessStep.id, newProcessStep);  
    }

    public override void beforeDelete(sObject o) 
    {}

    public override void afterInsert(sObject o) 
    {
        CSPOFA__Orchestration_Step__c newProcessStep = (CSPOFA__Orchestration_Step__c)o;

    }

    public override void afterUpdate(sObject old, sObject o)
    {
        /*CSPOFA__Orchestration_Step__c newProcessStep = (CSPOFA__Orchestration_Step__c)o;
        CSPOFA__Orchestration_Step__c oldProcessStep = (CSPOFA__Orchestration_Step__c)old;
        if (newProcessStep.CSPOFA__Status__c == 'In Progress' && newProcessStep.CSPOFA__Status__c != oldProcessStep.CSPOFA__Status__c)
            calculateTargetDate.put(newProcessStep.id, newProcessStep);          */ 
            
        CSPOFA__Orchestration_Step__c newProcessStep = (CSPOFA__Orchestration_Step__c)o;
        CSPOFA__Orchestration_Step__c oldProcessStep = (CSPOFA__Orchestration_Step__c)old;
        if (newProcessStep.CSPOFA__Status__c == 'Complete' && newProcessStep.CSPOFA__Status__c != oldProcessStep.CSPOFA__Status__c)
           CS_NotificationOnEvent.AddMileStoneEvent(newProcessStep.Id);          
    }

    public override void afterDelete(sObject o) 
    {}

    public override void afterUndelete(sObject o) 
    {}

    public override void finish() 
    {
        System.debug('***finish calculateTargetDate=' + calculateTargetDate);
        
        if (trigger.isBefore) 
        {
            if (!calculateTargetDate.isEmpty()) {
                UpdateTargetDate();
            }
        }

        if (Trigger.isAfter)
        {
            CS_NotificationOnEvent.SendNotificationEmails();    
        }
    }

    void UpdateTargetDate() {
        
    
        
        List<CSPOFA__Orchestration_Step__c> steps = [select id, CSPOFA__ola_remaining_time__c, CSPOFA__target_date__c, CSPOFA__Target_Date_Time__c, CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Time__c, 
            CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Unit__c from CSPOFA__Orchestration_Step__c where 
            id IN: calculateTargetDate.keySet()];
        
        System.debug('***entering UpdateTargetDate steps=' + steps);


        List<businesshours> bhs = CS_Cache.defaultBusinessHours;
        if (!bhs.isEmpty()) {
            businesshours bh = bhs.get(0);
            for (CSPOFA__Orchestration_Step__c step : steps) {
                Long milSecs;
                if (step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Unit__c != null && 
                    step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Time__c != null) {
                    if (step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Unit__c == 'day') {
                        milSecs = (Long) step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Time__c * 8*60*60*1000;
                    }
                    else if (step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Unit__c == 'hour') {
                        milSecs = (Long) step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Time__c *60*60*1000;
                    }
                    else if (step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Unit__c == 'minute') {
                        milSecs = (Long) step.CSPOFA__Orchestration_Step_Template__r.CSPOFA__OLA_Time__c *60*1000;
                    }
                    system.debug(milSecs);

                    Datetime targetDateTime = BusinessHours.add(bh.Id, system.now(), milSecs);
                    system.debug(targetDateTime);
                    system.debug(system.now());
                    Long diff = BusinessHours.diff(bh.Id, system.now(), targetDateTime);
                    system.debug(diff);
                    calculateTargetDate.get(step.id).CSPOFA__ola_remaining_time__c = string.valueOf(diff);
                    calculateTargetDate.get(step.id).CSPOFA__target_date__c = targetDateTime.date();
                    calculateTargetDate.get(step.id).CSPOFA__Target_Date_Time__c = targetDateTime;
                    calculateTargetDate.get(step.id).Target_SLA_Date__c = targetDateTime.date();
                    calculateTargetDate.get(step.id).Target_SLA_DateTime__c = targetDateTime;

                }
            }
        }

    }

}