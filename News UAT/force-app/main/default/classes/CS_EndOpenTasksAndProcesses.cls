global without sharing class CS_EndOpenTasksAndProcesses implements CSPOFA.ExecutionHandler {
    private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_COMPLETE_MSSG = 'All Tasks and Processes terminated.';

    public List<sObject> process(List<sObject> data) {
        List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>) data;

        list<Id> cancelledOrders = new List<Id>();
        List<Id> cancelledProdOrders = new List<Id>();
        List<Id> cancelledCreative = new List<Id>();

        List<Id> stepIds = new List<Id>();

        for (CSPOFA__Orchestration_Step__c step : stepList)
            stepIds.add(step.Id);

        List<CSPOFA__Orchestration_Step__c> stepsWithAdditionalInformation = [SELECT Id, CSPOFA__Orchestration_Process__c, 
        CSPOFA__Orchestration_Process__r.Product_Order__c,
        CSPOFA__Orchestration_Process__r.Order__c,CSPOFA__Orchestration_Process__r.Creative__c  
        FROM CSPOFA__Orchestration_Step__c WHERE Id = :stepIds];

        list<Task> openTasks;
        Map<Id, CSPOFA__Orchestration_Step__c> openSteps;
        List<CSPOFA__Orchestration_Process__c> openProcesses;
        Set<id> currentProcesses = new Set<Id>();

        system.debug(stepsWithAdditionalInformation);
        for (CSPOFA__Orchestration_Step__c step : stepsWithAdditionalInformation) 
        {
            currentProcesses.add(step.CSPOFA__Orchestration_Process__c);
            system.debug(step);
            if (step.CSPOFA__Orchestration_Process__r.order__c != null) {
                system.debug(step.CSPOFA__Orchestration_Process__r.order__c);
                cancelledOrders.add(step.CSPOFA__Orchestration_Process__r.order__c);
            }
            else if (step.CSPOFA__Orchestration_Process__r.product_order__c != null) {
                cancelledProdOrders.add(step.CSPOFA__Orchestration_Process__r.product_order__c);
            }
            else if (step.CSPOFA__Orchestration_Process__r.Creative__c!=null)
            {
                cancelledCreative.add(step.CSPOFA__Orchestration_Process__r.Creative__c);
            }
            system.debug('****** OrchDebug ** cancelledOrders: '+cancelledOrders);
        }
        system.debug('****** OrchDebug ** cancelledOrders: '+cancelledOrders);
        List<product_order__c> prodOrders = [select id, Cancellation_Reason__c, order__r.Cancellation_Reason__c 
            from Product_Order__c where order__c IN: cancelledOrders];
        for (Product_Order__c prodOrder : prodOrders)
            prodOrder.Cancellation_Reason__c = prodOrder.Order__r.Cancellation_Reason__c;

        update prodOrders;
        system.debug('****** OrchDebug ** prodOrders: '+prodOrders);

        openSteps = new Map<Id, CSPOFA__Orchestration_Step__c> ([select id, CSPOFA__Orchestration_Process__c, 
            CSPOFA__Related_Object_ID__c from CSPOFA__Orchestration_Step__c where 
            (CSPOFA__Orchestration_Process__r.order__c IN: cancelledOrders OR 
            CSPOFA__Orchestration_Process__r.Product_Order__r.order__c IN: cancelledOrders OR
            CSPOFA__Orchestration_Process__r.Product_Order__c IN: cancelledProdOrders OR
            CSPOFA__Orchestration_Process__r.Creative__c IN: cancelledCreative)
            and CSPOFA__Orchestration_Process__c not in: currentProcesses 
            AND CSPOFA__Status__c != 'Complete' AND CSPOFA__Status__c != 'Initializing' 
            AND CSPOFA__Status__c != 'Blocked'
            AND CSPOFA__Orchestration_Process__r.CSPOFA__Status__c!='Complete'
            AND CSPOFA__Orchestration_Process__r.CSPOFA__Status__c!='Error']);
        system.debug('****** OrchDebug ** openSteps: '+openSteps);
        system.debug(openSteps.size());
        List<Id> taskIds = new List<Id>();
        list<Id> processIds = new List <Id>();
        system.debug('****** OrchDebug ** openStepsCurrent1: '+openSteps);
        for (CSPOFA__Orchestration_Step__c step : openSteps.values()) {
            if (step.CSPOFA__Related_Object_ID__c != null)
                taskIds.add(step.CSPOFA__Related_Object_ID__c);
            processIds.add(step.CSPOFA__Orchestration_Process__c);
            step.CSPOFA__Status__c = 'Complete';
            step.CSPOFA__Completed_Date__c = Date.today();
            step.CSPOFA__Message__c = 'Process Cancelled';
            //06-04-2018 - David Scullion - Line commented out on advice from Cloudsense to stop APEX CPU time limit exceeded errors.
            //system.debug('****** OrchDebug ** openStepsCurrent2: '+openSteps);
        }
        system.debug('****** OrchDebug ** beforeOpentstep Upd1: '+openSteps);
        
        update openSteps.values();
        
        system.debug('****** OrchDebug ** AfterOpentstep Upd2: '+openSteps);

        /*NX-249 - commented by DD, once when processes are completed, it would force tasks to be closed as well
        Set<Id> setAllrelatdIds = new Set<Id>();
        if (cancelledOrders.size()>0)
            setAllrelatdIds.addAll(cancelledOrders);
        if (cancelledProdOrders.size()>0)
            setAllrelatdIds.addAll(cancelledProdOrders);
        if (cancelledCreative.size()>0)
            setAllrelatdIds.addAll(cancelledCreative);

        openTasks = [select id, Status from task where id IN: taskIds AND Status NOT IN ('Completed','Done','Cancelled')
        AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Do_Not_Kill__c=false];
        system.debug(openTasks);
        system.debug(openSteps.size());
        for (Task t : openTasks) {
            t.Status = 'Cancelled';
        }

        List<Task> lstManualTasks = [select Id, WhatId,Status from Task where WhatId in : setAllrelatdIds];
        for (Task tmpTask : lstManualTasks)
        {
            if (!taskIds.contains(tmpTask.Id))
            {
                 tmpTask.Status = 'Cancelled';
                 openTasks.add(tmpTask);
            }
        }


        CS_TaskTriggerDelegate.ForceTaskKilling=true;
        update openTasks;
        CS_TaskTriggerDelegate.ForceTaskKilling=false;
        */

        openProcesses = [select id, CSPOFA__State__c, CSPOFA__Status__c from CSPOFA__Orchestration_Process__c where id IN: processIds and 
        CSPOFA__Status__c != 'Completed'];
        for (CSPOFA__Orchestration_Process__c process : openProcesses) {
            process.CSPOFA__State__c = 'TERMINATED';
            process.CSPOFA__Status__c = 'Complete';
        }
system.debug('****** OrchDebug ** processIds: '+processIds);
system.debug('****** OrchDebug ** openProcesses: '+openProcesses);
       
        CS_TaskBehaviour.ForceManualTaskClosure=true;
        update openProcesses;
        CS_TaskBehaviour.ForceManualTaskClosure=false;
        

        for(CSPOFA__Orchestration_Step__c step : stepList)
        {
            step.CSPOFA__Status__c = STEP_STATUS_COMPLETE;
            step.CSPOFA__Completed_Date__c = Date.today();
            step.CSPOFA__Message__c = STEP_STATUS_COMPLETE_MSSG;

        }
        List<sObject> result = new List<sObject>();
            
        result.addAll((List<sObject>)stepList);
            
        return result;

    }
}