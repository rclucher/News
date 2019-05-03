global without sharing class CS_CloseTaskFromOrchestrationProcess implements CSPOFA.ExecutionHandler {
	private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_COMPLETE_MSSG = 'All Tasks and Processes terminated.';

	public List<SObject> process(List<SObject> data) {
		List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>) data;
		List<CSPOFA__Orchestration_Step__c> orchestationStepListToComplete=new List<CSPOFA__Orchestration_Step__c>();

		List<Id> stepIds = new List<Id>();
		Set<String> stepsToCompleteNameSet=new Set<String>();
		Set<Id> orchestrationProcessIds=new Set<Id>();
		Set<Id> tasksToBeClosedIdSet=new Set<Id>();
		Set<Id> setOrchTaskId =new Set<Id>();

        for (CSPOFA__Orchestration_Step__c step : stepList)
            stepIds.add(step.Id);

        List<CSPOFA__Orchestration_Step__c> closeTaskSteps= [SELECT Id, CSPOFA__Orchestration_Process__c, 
        															CSPOFA__Status__c,CSPOFA__Completed_Date__c,CSPOFA__Message__c,
        															CSPOFA__Orchestration_Process__r.Product_Order__c,
        															CSPOFA__Orchestration_Process__r.Order__c,
        															CSPOFA__Orchestration_Step_Template__r.Close_Task_Step__c
    															FROM CSPOFA__Orchestration_Step__c WHERE Id = :stepIds];
		
		for(CSPOFA__Orchestration_Step__c closeTaskStep:closeTaskSteps){
			stepsToCompleteNameSet.add(closeTaskStep.CSPOFA__Orchestration_Step_Template__r.Close_Task_Step__c);
			orchestrationProcessIds.add(closeTaskStep.CSPOFA__Orchestration_Process__c);
			closeTaskStep.CSPOFA__Status__c = STEP_STATUS_COMPLETE;
            closeTaskStep.CSPOFA__Completed_Date__c = Date.today();
            closeTaskStep.CSPOFA__Message__c = STEP_STATUS_COMPLETE_MSSG;
			orchestationStepListToComplete.add(closeTaskStep);
		}

        List<CSPOFA__Orchestration_Step__c> stepsToComplete = [SELECT Id, CSPOFA__Orchestration_Process__c, CSPOFA__Related_Object_ID__c,
        															CSPOFA__Status__c,CSPOFA__Completed_Date__c,CSPOFA__Message__c
    															FROM CSPOFA__Orchestration_Step__c
    															WHERE Name IN :stepsToCompleteNameSet
    															AND CSPOFA__Orchestration_Process__c IN:orchestrationProcessIds];


		for(CSPOFA__Orchestration_Step__c step : stepsToComplete)
        {
            step.CSPOFA__Status__c = STEP_STATUS_COMPLETE;
            step.CSPOFA__Completed_Date__c = Date.today();
            step.CSPOFA__Message__c = STEP_STATUS_COMPLETE_MSSG;
            orchestationStepListToComplete.add(step);
            tasksToBeClosedIdSet.add(step.CSPOFA__Related_Object_ID__c);
        }

        List<Task> tasks = [SELECT Id,Status 
        					FROM Task 
        					WHERE IsClosed=false 
        					AND Id IN:tasksToBeClosedIdSet];

        for (Task task : tasks) {
            task.Status = 'Cancelled';
            setOrchTaskId.add(task.Id);
        }     

        if(!setOrchTaskId.isEmpty()){
        	update tasks;
        }
        if(!orchestationStepListToComplete.isEmpty()){
        	update orchestationStepListToComplete;
        }

        List<sObject> result = new List<sObject>();
		result.addAll((List<sObject>)closeTaskSteps);
            
        return result;
	}
}