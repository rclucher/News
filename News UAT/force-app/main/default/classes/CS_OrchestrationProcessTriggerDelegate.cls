public with sharing class CS_OrchestrationProcessTriggerDelegate extends CS_TriggerHandler.DelegateBase 
{
    map<id, CSPOFA__Orchestration_Process__c> calculateTargetDate;
    list<id> updatedProgressProcessIds;
    Set<Id> setProcessesToTerminateId;
    Set<Id> setAllrelatdIds;

    public override void prepareBefore() 
    {

    }

    public override void prepareAfter() 
    {
        calculateTargetDate = new map<id, CSPOFA__Orchestration_Process__c>();
        updatedProgressProcessIds = new List<id>();
        setProcessesToTerminateId = new Set<Id>();
		setAllrelatdIds = new Set<Id>();
    }

    public override void beforeInsert(sObject o) 
    {
        CSPOFA__Orchestration_Process__c newProcess = (CSPOFA__Orchestration_Process__c)o;
        
    }

    public override void beforeUpdate(sObject old, sObject o) 
    {
        CSPOFA__Orchestration_Process__c newProcess = (CSPOFA__Orchestration_Process__c)o;
        CSPOFA__Orchestration_Process__c oldProcess = (CSPOFA__Orchestration_Process__c)old;

    }

    public override void beforeDelete(sObject o) 
    {}

    public override void afterInsert(sObject o) 
    {
        CSPOFA__Orchestration_Process__c newProcess = (CSPOFA__Orchestration_Process__c)o;
        calculateTargetDate.put (newProcess.id, newProcess);
    }

    public override void afterUpdate(sObject old, sObject o)
    {
        CSPOFA__Orchestration_Process__c newProcess = (CSPOFA__Orchestration_Process__c)o;
        CSPOFA__Orchestration_Process__c oldProcess = (CSPOFA__Orchestration_Process__c)old;

        if (newProcess.name.contains('Setup') && !newProcess.name.contains('Recurring') && !newProcess.name.contains('Container') && newProcess.Milestones_Completed__c != oldProcess.Milestones_Completed__c)
            updatedProgressProcessIds.add(newProcess.id);

        if (newProcess.CSPOFA__Status__c != null && newProcess.CSPOFA__Status__c != oldProcess.CSPOFA__Status__c && newProcess.CSPOFA__Status__c == 'Complete')
        {
            if (newProcess.Order__c!=null)
                setAllrelatdIds.add(newProcess.Order__c);
            else if (newProcess.Product_Order__c!=null)
                setAllrelatdIds.add(newProcess.Product_Order__c);
            else if (newProcess.Creative__c!=null)
                setAllrelatdIds.add(newProcess.Creative__c);
            
            setProcessesToTerminateId.add(newProcess.Id);
        }
    }

    public override void afterDelete(sObject o) 
    {}

    public override void afterUndelete(sObject o) 
    {}

    public override void finish() 
    {
        if (trigger.isAfter) 
        {
        
            if (!setProcessesToTerminateId.isEmpty())
                TerminateRelatedTasks();
        
            if (!updatedProgressProcessIds.isEmpty())
                UpdateParentProgress();

           if(!calculateTargetDate.isEmpty()) {
                SetSLATargetDate();
           }
        }
    }

        void UpdateParentProgress() {
        List<CSPOFA__Orchestration_Process__c> processes = [select id, Milestone_Progress__c, 
                            Order__c, Order__r.Progress_Percentage__c, 
                            Product_Order__c, Product_Order__r.Progress_Percentage__c,
                            Creative__c, Creative__r.Progress_Percentage__c
                            from CSPOFA__Orchestration_Process__c where 
                            id IN: updatedProgressProcessIds];


        list<Id> orderIds = new list<Id>();
        list<Id> creativeIds = new list<Id>();
        list<Id> prodOrdIds = new list<Id>();


        for (CSPOFA__Orchestration_Process__c op : processes) {
            if (op.Order__c != null) {
                orderIds.add(op.Order__c);
            }
            else if (op.Product_Order__c != null) {
                prodOrdIds.add(op.Product_Order__c);
            }
            else if (op.Creative__c != null) {
                creativeIds.add(op.Creative__c);
            }
        }

        Map<Id, Order__c> orders = new Map<Id, Order__c>([select id, Progress_Percentage__c from Order__c where id IN: orderIds]);
        Map<Id, Creative__c> creatives = new Map<Id, Creative__c>([ select id, Progress_Percentage__c from Creative__c where id IN: creativeIds]);
        Map<Id, Product_Order__c> prodOrds = new Map<Id, Product_Order__c>([select id, Progress_Percentage__c from Product_Order__c where id IN: prodOrdIds]);
        for (CSPOFA__Orchestration_Process__c op : processes) {
            if (op.Order__c != null) {
                orders.get(op.Order__c).Progress_Percentage__c = op.Milestone_Progress__c;
            }
            else if (op.Product_Order__c != null) {
                prodOrds.get(op.Product_Order__c).Progress_Percentage__c = op.Milestone_Progress__c;
            }
            else if (op.Creative__c != null) {
                creatives.get(op.Creative__c).Progress_Percentage__c = op.Milestone_Progress__c;
            }
        }
        if (!orders.isEmpty())
            update orders.values();
        if (!prodOrds.isEmpty())    
            update prodOrds.values();
        if (!creatives.isEmpty())   
            update creatives.values();

    }

    void SetSLATargetDate() {

        List<CSPOFA__Orchestration_Process__c> processes = [select id, CSPOFA__ola_remaining_time__c, CSPOFA__target_date__c, CSPOFA__Target_Date_Time__c, 
        CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Time__c,
            CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Unit__c from CSPOFA__Orchestration_Process__c where 
            id IN: calculateTargetDate.keySet()];
        
        List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
        if (!bhs.isEmpty()) {
            businesshours bh = bhs.get(0);
            for (CSPOFA__Orchestration_Process__c process : processes) {
                Long milSecs;
                if (process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Unit__c != null && 
                    process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Time__c != null) {
                    if (process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Unit__c == 'day') {
                        milSecs = (Long) process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Time__c * 8*60*60*1000;
                    }
                    else if (process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Unit__c == 'hour') {
                        milSecs = (Long) process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Time__c *60*60*1000;
                    }
                    else if (process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Unit__c == 'minute') {
                        milSecs = (Long) process.CSPOFA__Orchestration_Process_Template__r.CSPOFA__OLA_Time__c *60*1000;
                    }

                    Datetime targetDateTime = BusinessHours.add(bh.Id, system.now(), milSecs);
                    Long diff = BusinessHours.diff(bh.Id, system.now(), targetDateTime);

                    process.CSPOFA__ola_remaining_time__c = string.valueOf(diff);
                    process.CSPOFA__target_date__c = targetDateTime.date();
                    process.CSPOFA__Target_Date_Time__c = targetDateTime;
                    process.Target_SLA_Date__c = targetDateTime.date();
                    process.Target_SLA_DateTime__c = targetDateTime;

                }
            }

            update processes;
        }
    }


    void TerminateRelatedTasks() 
    {
        Set<Id> setOrchTaskId = new Set<Id>();

        List<Task> tasks = [SELECT Id,status,Subject FROM Task WHERE IsClosed=false 
        AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Process__c IN: setProcessesToTerminateId
        AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Do_Not_Kill__c=false];

        for (Task task : tasks) {
            if(task.Subject!='Upcoming Cancellation'){ //NX-343 
                task.Status = 'Cancelled';
                setOrchTaskId.add(task.Id);
            }//NX-343
           
            
        }      
        
        System.debug('***Orchestration Tasks tasks=' + tasks);
        System.debug('***CS_TaskBehaviour.ForceManualTaskClosure=' + CS_TaskBehaviour.ForceManualTaskClosure);
        System.debug('***setOrchTaskId = ' + setOrchTaskId);
		System.debug('***setAllrelatdIds = ' + setAllrelatdIds);




        if (CS_TaskBehaviour.ForceManualTaskClosure)
        {
            List<Task> lstManualTasks = [select Id, WhatId,Status,Subject from Task where 
                IsClosed=false 
                and CSPOFA__Orchestration_Step__c=null
                and WhatId in : setAllrelatdIds];

            for (Task task : lstManualTasks) 
            {
                if (!setOrchTaskId.contains(task.Id))
                {
                    if(task.Subject!='Upcoming Cancellation'){ //NX-343
                        task.Status = 'Cancelled';
                        tasks.add(task);
                    }
                    
                     
                }
            }

            System.debug('***Manual Tasks tasks=' + lstManualTasks);
            System.debug('***All Tasks tasks=' + tasks);


        }

        CS_TaskBehaviour.ForceOrchestrationTaskClosure=true;                          
        update tasks;
        CS_TaskBehaviour.ForceOrchestrationTaskClosure=false;
    }
}