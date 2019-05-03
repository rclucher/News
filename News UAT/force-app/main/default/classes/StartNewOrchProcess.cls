global without sharing class StartNewOrchProcess implements CSPOFA.ExecutionHandler {
    private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_COMPLETE_MSSG = 'New process created.';

    public List<sObject> process(List<sObject> data) {
        List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>) data;
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();
        List<Id> stepIds = new List<Id>();
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();

        for (CSPOFA__Orchestration_Step__c step : stepList)
            stepIds.add(step.Id);

        List<CSPOFA__Orchestration_Step__c> stepsWithAdditionalInformation = [SELECT Id, CSPOFA__Orchestration_Process__r.Product_Order__c,
        CSPOFA__Orchestration_Process__r.Order__c, New_Orch_Process__c FROM CSPOFA__Orchestration_Step__c WHERE Id = :stepIds and New_Orch_Process__c != null];

        for (CSPOFA__Orchestration_Step__c step : stepsWithAdditionalInformation) {
            system.debug('######### step.New_Orch_Process__c: ' + step.New_Orch_Process__c);
            CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (step.New_Orch_Process__c);
            if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null) {           
                system.debug('######### template: ' + template + ' step: ' + step);
                CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id,
                                                                                                                Name = step.New_Orch_Process__c, 
                                                                                                                Product_Order__c = step.CSPOFA__Orchestration_Process__r.Product_Order__c);           
                processesToInsert.add(process); 
            }

            else if (step.CSPOFA__Orchestration_Process__r.Order__c != null) {          
                CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                                Name = step.New_Orch_Process__c, 
                                                                                                                Order__c = step.CSPOFA__Orchestration_Process__r.Order__c = step.CSPOFA__Orchestration_Process__r.Order__c);           
                processesToInsert.add(process); 
            }
        }

        new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
        
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