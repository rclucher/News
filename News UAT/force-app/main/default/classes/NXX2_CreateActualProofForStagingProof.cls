/**
* @author       Kamal Sharma
* @date         2019-01-14
* @className	NXX2_CreateActualProofForStagingProof
* @description  This class will be used to create actual proof records for staging proofs.  
*/
global class NXX2_CreateActualProofForStagingProof implements Database.Batchable<sObject>,Database.Stateful{
    private string socialProofRecordTypeId;
    private string displayProofRecordTypeId;
    private Map<String,String> stagingToActualProofStatusMap;
    private Map<String,String> taskTypeToProofTypesMap;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-14
    * @description  Default constructor
    */
    public NXX2_CreateActualProofForStagingProof(){
        socialProofRecordTypeId = Schema.SObjectType.SocialCampaign__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
        displayProofRecordTypeId = Schema.SObjectType.SocialCampaign__c.getRecordTypeInfosByName().get('Display').getRecordTypeId();
        stagingToActualProofStatusMap = new Map<String,String>{
            'APPROVED' => 'Approved',
            'IN_REVIEW' => 'In Review',
            'NEW' => 'New',
            'WITH_CLIENT' => 'With Customer',
            'NOT_REQUIRED' => 'New'
        };
        taskTypeToProofTypesMap = new Map<String,String>{
            'DISPLAY_PROOF' => 'Display',
            'SOCIAL_PROOF' => 'Social'
        };
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
        system.debug('*******Proof*******');
        return Database.getQueryLocator([SELECT Name, External_Id__c,Has_Merged__c,
                                         Processing_Status__c,Error_Message__c,Error_Details__c, 
                                         Related_Proof__c,Social_Plan_Focus__c   
                                         FROM NXX2_Proof_Staging__c 
                                         WHERE Has_Merged__c = false 
                                         AND Related_Proof__c = null
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
        system.debug('*******Scope*******'+scope);
        try{
            processTaskRecords((List<NXX2_Proof_Staging__c>)scope);
            update scope;
        }catch(Exception e){
            for(NXX2_Proof_Staging__c proof : (List<NXX2_Proof_Staging__c>)scope){
                proof.Processing_Status__c = 'Error';
                proof.Error_Message__c = 'Exception Occured!';
                proof.Error_Details__c = e.getMessage();
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
    public void processTaskRecords(List<NXX2_Proof_Staging__c> stagingProofs){
        Set<String> campaignIds = new Set<String>();
        for(NXX2_Proof_Staging__c proof : stagingProofs){
            proof.Has_Merged__c = true;
            campaignIds.add(proof.External_Id__c);
        }
        system.debug('*******campaignIds*******'+campaignIds);
        Map<String,List<NXX2_Task_Staging__c>> proofToTasksMap = new Map<String,List<NXX2_Task_Staging__c>>();
        Map<String,String> proofToProductOrderMap = new Map<String,String>();
        for(NXX2_Task_Staging__c task : [SELECT Campaign_Id__c,Status__c,Product_Order__c,Title__c,
                                         Type__c,Related_Proof__c,Has_Merged__c,Link__c 
                                         FROM NXX2_Task_Staging__c 
                                         WHERE Related_Proof__c = null 
                                         AND Campaign_Id__c IN :campaignIds
                                         AND Product_Order__c LIKE '%PO-%' 
                                         AND Product_Order__c LIKE '________'
                                         AND Type__c IN ('DISPLAY_PROOF','SOCIAL_PROOF')
                                        ]){
                                            if(!proofToTasksMap.containsKey(task.Campaign_Id__c)){
                                                proofToTasksMap.put(task.Campaign_Id__c,new List<NXX2_Task_Staging__c>());
                                            }
                                            proofToTasksMap.get(task.Campaign_Id__c).add(task);
                                            if(!proofToProductOrderMap.containsKey(task.Campaign_Id__c)){
                                                proofToProductOrderMap.put(task.Campaign_Id__c,task.Product_Order__c);
                                            }
                                        }
        system.debug('*******proofToTasksMap*******'+proofToTasksMap);
        system.debug('*******proofToProductOrderMap*******'+proofToProductOrderMap);
        Map<String,Product_Order__c> PONameToPOMap = new Map<String,Product_Order__c>();
        for(Product_Order__c po : [SELECT Name,Fulfillment_Type__c,Order__r.Actual_Start_Date__c, Order__r.End_Date__c 
                                   FROM Product_Order__c 
                                   WHERE Name IN : proofToProductOrderMap.values()]){
                                       PONameToPOMap.put(po.Name,po);
                                   }
        system.debug('*******PONameToPOMap*******'+PONameToPOMap);
        Map<String,SocialCampaign__c> stagingProofExternalIdToActualProofMap = new Map<String,SocialCampaign__c>();
        for(NXX2_Proof_Staging__c proof : stagingProofs){
            Product_Order__c po = PONameToPOMap.get(proofToProductOrderMap.get(proof.External_Id__c));
            List<NXX2_Task_Staging__c> tasks = proofToTasksMap.get(proof.External_Id__c);
            NXX2_Task_Staging__c relatedTask;
            if(po == null || tasks == null || tasks.size() == 0){
                proof.Processing_Status__c = 'Error';
                proof.Error_Message__c = 'No valid related staging task';
                proof.Error_Details__c = 'It seems like there is no any task for this campaign id which has valid PO number and type.';
            }else{
                for(NXX2_Task_Staging__c task : tasks){
                    if(po.Fulfillment_Type__c == null || po.Fulfillment_Type__c == taskTypeToProofTypesMap.get(task.Type__c)){
                        relatedTask = task;
                        break;
                    }
                }
                if(relatedTask == null){
                    proof.Processing_Status__c = 'Error';
                    proof.Error_Message__c = 'No valid related staging task';
                    proof.Error_Details__c = 'It seems like there is a task with valid PO number and type but either PO does not exist or type of task is not same as PO fulfillment type.';
                }else{
                    stagingProofExternalIdToActualProofMap.put(proof.External_Id__c,new SocialCampaign__c(
                        Product_Order__c = po.Id,
                        Proof_Name__c = proof.Name,
                        Social_Plan_Focus__c = proof.Social_Plan_Focus__c,
                        Campaign_Start_Date__c = po.Order__r.Actual_Start_Date__c,
                        Campaign_End_Date__c = po.Order__r.End_Date__c,
                        RecordTypeId = relatedTask.type__c == 'DISPLAY_PROOF' ? displayProofRecordTypeId : socialProofRecordTypeId,
                        Status__c = stagingToActualProofStatusMap.get(relatedTask.Status__c),
                        Created_From_Staging__c = true
                    ));
                    proof.Processing_Status__c = 'Success';
                }
            }
        }
        insert stagingProofExternalIdToActualProofMap.values();
        for(NXX2_Proof_Staging__c proof : stagingProofs){
            if(stagingProofExternalIdToActualProofMap.containsKey(proof.External_Id__c)){
            	proof.Related_Proof__c = stagingProofExternalIdToActualProofMap.get(proof.External_Id__c).Id;
            }
        }
        update stagingProofs;
    }
    
    /**
    * @author       Kamal Sharma
	* @date         2019-01-14
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){
        NXX2_CreateActualTaskForStagingTask b = new NXX2_CreateActualTaskForStagingTask();
        database.executebatch(b,1);
    }
}