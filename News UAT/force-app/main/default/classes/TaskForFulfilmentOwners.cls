global without sharing class TaskForFulfilmentOwners implements CSPOFA.ExecutionHandler {
    private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_COMPLETE_MSSG = 'Tasks Created.';

    public List<sObject> process(List<sObject> data) {
        List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>) data;
        List<Id> stepIds = new List<Id>();
        system.debug('tu'+stepList);
        for (CSPOFA__Orchestration_Step__c step : stepList)
            stepIds.add(step.Id);
        Id taskrecordType = UtilMethods.getRecordTypeId('Task.To-Do');

        List<CSPOFA__Orchestration_Step__c> stepsWithAdditionalInformation = [SELECT Id, Task_Comments__c, 
        CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__c, 
        CSPOFA__Orchestration_Process__r.Order__c,Task_Subject2__c FROM CSPOFA__Orchestration_Step__c WHERE Id = :stepIds];

        List<Id> orderIds = new List<Id>();
        Map<Id, String> taskCommentForOrder = new Map<Id, String>();
        Map<Id, String> taskSubjectForOrder = new Map<Id, String>();
        system.debug(stepsWithAdditionalInformation);
        for (CSPOFA__Orchestration_Step__c os : stepsWithAdditionalInformation) {
            if (os.CSPOFA__Orchestration_Process__r.Order__c != null) {
                taskCommentForOrder.put (os.CSPOFA__Orchestration_Process__r.Order__c, os.Task_Comments__c);
                taskSubjectForOrder.put (os.CSPOFA__Orchestration_Process__r.Order__c, os.Task_Subject2__c);
            }
        }

        List<Product_Order__c> prodOrders = [select id, Assigned_Social_Owner__c, Assigned_Fulfilment_Owner__c, Order__c from Product_Order__c where Assigned_Fulfilment_Owner__c!= null AND
            status__c != 'Cancelled' AND Order__c IN: taskCommentForOrder.keySet()];
        system.debug(prodOrders);
        List<Task> tasksForInsert = new List<Task>();
        String strDefaultSubject='';
        if (!prodOrders.isEmpty()) {
            for (Product_Order__c po: prodOrders) {
                strDefaultSubject = taskSubjectForOrder.get(po.Order__c);
                if(String.isBlank(strDefaultSubject))
                   strDefaultSubject='Cancel/pause actions required';
                Task newTask = new Task (
                        OwnerID = po.Assigned_Fulfilment_Owner__c, 
                        Description = taskCommentForOrder.get(po.Order__c),
                        WhatId = po.Id,
                        Status = 'Not Started',
                        ActivityDate = system.today().addDays(1),
                        RecordTypeId = taskrecordType,
                        Subject = strDefaultSubject);
                tasksForInsert.add(newTask);
                if (po.Assigned_Social_Owner__c != null) {
                    Task newSocialTask = new Task (
                        OwnerID = po.Assigned_Social_Owner__c, 
                        Description = taskCommentForOrder.get(po.Order__c),
                        WhatId = po.Id,
                        Status = 'Not Started',
                        RecordTypeId = taskrecordType,
                        ActivityDate = system.today().addDays(1),
                        Subject = strDefaultSubject);
                    tasksForInsert.add(newSocialTask);
                }
                system.debug(tasksForInsert);
            }
            insert tasksForInsert;
        }

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