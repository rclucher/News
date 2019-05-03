public with sharing class CS_OrchestratorUtil 
{
    private Map<String, CSPOFA__Orchestration_Process_Template__c> orchLabelToProcessMap;
    public List<String> orchLabels;
    private Map<String, CSPOFA__Orchestration_Process_Template__c> procNameToProcessMap;
        
    public CS_OrchestratorUtil() {
        getOrchestratorMetadata();
        getOrchestratorData();
        mapProcessToLabel();
    }

    private void getOrchestratorMetadata(){
        List<Map_Orchestrator_Process__mdt> procTemplatesList = [SELECT Orchestrator_Process_Template_s__c, MasterLabel, DeveloperName FROM 
                                                                            Map_Orchestrator_Process__mdt];
        
        if(!procTemplatesList.isEmpty()){
            orchLabels = new List<String>();
            for(Map_Orchestrator_Process__mdt procTemplate : procTemplatesList){
                List<String> allProcesses;
                system.debug(procTemplate.Orchestrator_Process_Template_s__c);
                if (procTemplate.Orchestrator_Process_Template_s__c.contains(',')) {
                    allProcesses = procTemplate.Orchestrator_Process_Template_s__c.split(',');
                    system.debug(allProcesses);
                }
                else {
                    allProcesses = new List<String>{procTemplate.Orchestrator_Process_Template_s__c};
                }
                for (String process : allProcesses) {
                   orchLabels.add(process);
                }
            }
        }
    }

    private void getOrchestratorData(){
        List<cspofa__orchestration_process_template__c> orchProcList = [SELECT Name, Id FROM cspofa__orchestration_process_template__c];
        
        if(!orchProcList.isEmpty()){
                procNameToProcessMap = new Map<String, CSPOFA__Orchestration_Process_Template__c>();
                for(CSPOFA__Orchestration_Process_Template__c orchProcess : orchProcList){
                    if(!procNameToProcessMap.containsKey(orchProcess.Name))
                        procNameToProcessMap.put(orchProcess.Name, orchProcess);
                }
        }
    }

    private void mapProcessToLabel()
    {
        orchLabelToProcessMap = new Map<String, CSPOFA__Orchestration_Process_Template__c>();
        for (String orchLabel : orchLabels)
        {
            if (procNameToProcessMap == null) {
                continue;
            }
            if (procNameToProcessMap.containsKey(orchLabel)) {

                orchLabelToProcessMap.put(orchLabel, procNameToProcessMap.get(orchLabel));
            }
        }
    }
    
    public CSPOFA__Orchestration_Process_Template__c GetProcessTemplateForLabel(String label)
    {
        for (string s : orchLabels)
            system.debug(s);
        for (string s : orchLabelToProcessMap.keySet())
            system.debug(s + ' ' + orchLabelToProcessMap.get(s));
        return orchLabelToProcessMap.get(label);
    }
}