trigger TaskTrigger_NVM_CaseProcessing on Task (after Insert, after Update) {
       
    Map<String, String> taskToCaseMap = new Map<String, String>();
    Map<String, String> taskToContactMap = new Map<String, String>();
    Map<String, String> taskToCaseNumMap = new Map<String, String>();
    Map<String, String> taskToCaseOriginMap = new Map<String, String>();
    
    Set<String> taskIds = new Set<String>();
    Set<String> caseIds = new Set<String>();
    Set<String> processTaskSet = new Set<String>();
    
    String taskIdTest;
    
    for (Task t: trigger.new){
        taskIdTest = (String)t.WhatId;
        if (taskIdTest == null) taskIdTest = '';
        If (taskIdTest.startswith('500') && t.WhoId == null){
            taskIds.add(t.Id);
            caseIds.add(t.WhatId);
            taskToCaseMap.put(t.Id, t.WhatId);
            }
    } // save off all of the ContactId where contacts may be present
    
    
    system.debug('TaskIds='+taskIds);
    system.debug('caseIds='+caseIds);
    system.debug('taskToCaseMap='+taskToCaseMap);
    
    List<Case> cList = [SELECT Id, ContactId, CaseNumber, Origin FROM Case c WHERE
                        c.Id in :caseIds];
    
    if (cList.size() > 0){    
        for (String t1 : taskIds){
            if (taskToCaseMap.get(t1) != null){
                for (Case cl : cList){
                    if (taskToCaseMap.get(t1) == cl.Id){
                        if (cl.ContactId != null){
                            taskToContactMap.put(t1, cl.ContactId);
                            taskToCaseNumMap.put(t1, cl.CaseNumber);
                            taskToCaseOriginMap.put(t1, cl.Origin);
                            processTaskSet.add(t1);
                            }
                    }
                }    
            }
        } // end for
    }
    
    system.debug('taskToContactMap='+taskToContactMap);
    system.debug('taskToCaseNumMap='+taskToCaseNumMap);
    system.debug('processTaskSet='+processTaskSet);
    
    List<Task> updList = new List<Task>();
    Boolean updated;
    
    for (Task t2 : trigger.new){
        Task nTask = new Task();
        updated = false;
        
        if (processTaskSet.contains(t2.Id) && TaskToContactMap.get(t2.Id) != null && nTask.WhoId == null){
            nTask.Id = t2.Id;
            nTask.WhoId = TaskToContactMap.get(t2.Id);
            updated = true;
        } // ones we know have a contact Id to attach 
        
        if (t2.NVMContactWorld__Customer_Number__c != null && TaskToCaseNumMap.get(t2.Id) != null && t2.Subject.contains('Case Routed') == false){
            if (t2.NVMContactWorld__Customer_Number__c.startswith('500')){
                nTask.Id = t2.Id;
                nTask.Subject = 'Inbound case #'+ TaskToCaseNumMap.get(t2.Id) + ' for ' + taskToCaseOriginMap.get(t2.Id) + ' channel'; 
                nTask.NVMTaskChannel__c = taskToCaseOriginMap.get(t2.Id);
                updated = true;
            } // change the subject of the task - it looks wrong with Inbound Call to object Id
        }
        
        if (updated)
            updList.add(nTask);
    } 
    
    system.debug('updList='+updList);
    
    if (updList.size() > 0)
        update(updList);
}