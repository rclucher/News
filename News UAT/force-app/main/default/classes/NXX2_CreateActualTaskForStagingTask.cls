/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className	NXX2_CreateActualTaskForStagingTask
* @description  This class will be used to create actual proof records for staging proofs.  
*/
global class NXX2_CreateActualTaskForStagingTask implements Database.Batchable<sObject>,Database.Stateful{
    private string proofCustomerActivityRecordTypeId;
    private Map<String,String> stagingToActualTaskStatusMap;
    private Map<String,String> stagingToActualTaskTypesMap;
    private Map<String,String> customerActivityCommentsLinkedToTypeMap;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Default constructor
    */
    public NXX2_CreateActualTaskForStagingTask(){
        proofCustomerActivityRecordTypeId = Schema.SObjectType.Customer_Task__c.getRecordTypeInfosByName().get('Proof Customer Activity').getRecordTypeId();
        stagingToActualTaskStatusMap = new Map<String,String>{
            'APPROVED' => 'Completed',
            'IN_REVIEW' => 'New',
            'NEW' => 'New',
            'WITH_CLIENT' => 'With Client',
            'NOT_REQUIRED' => 'New'
        };
        stagingToActualTaskTypesMap = new Map<String,String>{
            'UPLOAD_CREATIVE_ASSETS' => 'Upload Creative Assets',
            'DISPLAY_PROOF' => 'Approve and Review Your Display Ads',
            'SOCIAL_PROOF' => 'Approve and Review Your Facebook Ads',
            'GTM' => 'Place GTM on Website'
        };
        customerActivityCommentsLinkedToTypeMap = NXX2_AppUtility.getAllCommentsLinkedToType();
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the staging task Recods which are related to product order.
        return Database.getQueryLocator([SELECT Campaign_Id__c,Status__c,Product_Order__c,Title__c,
                                         Type__c,Related_Proof__c,Has_Merged__c,Link__c,Due_Date__c,
                                         Processing_Status__c,Error_Message__c,Error_Details__c 
                                         FROM NXX2_Task_Staging__c 
                                         WHERE Has_Merged__c = false 
                                        ]);
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  execute method implementation of Batch interface
    * @param        Database.BatchableContext BC, List<sObject> scope
    * @return       void
    */
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
            processTaskRecords((List<NXX2_Task_Staging__c>)scope);
            for(NXX2_Task_Staging__c task : (List<NXX2_Task_Staging__c>)scope){
                task.Has_Merged__c = true;
                task.Processing_Status__c = 'Success';
            }
            update scope;
        }catch(Exception e){
            for(NXX2_Task_Staging__c task : (List<NXX2_Task_Staging__c>)scope){
                task.Processing_Status__c = 'Error';
                task.Error_Message__c = 'Exception Occured!';
                task.Error_Details__c = e.getMessage();
            }
            update scope;
        }
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  This method will process all staging task records to create proof records.
    * @param        List<NXX2_Task_Staging__c> stagingTasks
    * @return       void
    */
    public void processTaskRecords(List<NXX2_Task_Staging__c> stagingTasks){
        system.debug('*******stagingTasks********'+stagingTasks);
        Map<String,List<NXX2_Task_Staging__c>> proofIdToTasksMap = new Map<String,List<NXX2_Task_Staging__c>>();
        for(NXX2_Task_Staging__c task : stagingTasks){
            task.Has_Merged__c = true;
            if(!proofIdToTasksMap.containsKey(task.Campaign_Id__c)){
                proofIdToTasksMap.put(task.Campaign_Id__c, new List<NXX2_Task_Staging__c>());
            }
            proofIdToTasksMap.get(task.Campaign_Id__c).add(task);
        }
        List<NXX2_Proof_Staging__c> stagingProofs = [SELECT Name, External_Id__c, Related_Proof__c 
                                                     FROM NXX2_Proof_Staging__c 
                                                     WHERE Related_Proof__c != null 
                                                     AND External_Id__c IN :proofIdToTasksMap.keySet()];
        system.debug('*******stagingProofs********'+stagingProofs);
        List<Customer_Task__c> customerActivities = new List<Customer_Task__c>();
        for(NXX2_Proof_Staging__c proof : stagingProofs){
            for(NXX2_Task_Staging__c task : proofIdToTasksMap.get(proof.External_Id__c)){
                task.Related_Proof__c = proof.Related_Proof__c;
                if(stagingToActualTaskTypesMap.containsKey(task.Type__c)){
                    String ActualTaskType = stagingToActualTaskTypesMap.get(task.Type__c);
                    customerActivities.add(new Customer_Task__c(
                        Title__c = task.Title__c,
                        Type__c = ActualTaskType,
                        Comments__c = customerActivityCommentsLinkedToTypeMap.get(ActualTaskType),
                        Status__c = task.Status__c == null ? 'New' : stagingToActualTaskStatusMap.get(task.Status__c),
                        Social_Campaign__c = proof.Related_Proof__c,
                        recordTypeId = proofCustomerActivityRecordTypeId,
                        Link__c = task.Link__c,
                        Due_Date__c = task.Due_Date__c == null ? Date.today() : NXX2_AppUtility.getDateFromString(task.Due_Date__c),
                        Created_From_Staging__c = true
                    ));
                }
            }
        }
        system.debug('******Customer Activity******'+customerActivities);
        insert customerActivities;
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateProofAdFromStagingData b = new NXX2_CreateProofAdFromStagingData();
        database.executebatch(b,1);
    }
}