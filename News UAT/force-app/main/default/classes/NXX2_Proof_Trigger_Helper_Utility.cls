/**
* @author       Kamal Sharma
* @date         2018-11-01
* @className	NXX2_Proof_Trigger_Helper_Utility
* @description  This class is an implimentation of Trigger-Go-Live functionality.
*				This class will be used to handle the Auto Approval of Product Order and also to update Product Order Task.
*               This class will be triggerred by Trigger Handler
*/
public without sharing class NXX2_Proof_Trigger_Helper_Utility {
    //Contants used in this class
	private static final String PONAME_PREFIX_TO_CHECK_IN_MAIL_SUBJECT = 'PO-';
    private static final String METADATA_API_NAME_FOR_SOCIAL_PO = 'Config_For_Social_PO';
    private static final String METADATA_API_NAME_FOR_DISPLAY_PO = 'Config_For_Display_PO';
    private static final String PO_FULFILLMENT_TYPE_SOCIAL = 'Social';
    private static final String PO_FULFILLMENT_TYPE_DISPLAY = 'Display';
    private static final String APPROVED_BY_CLIENT_TRUE = 'Yes';
    private static final String APPROVED_BY_CLIENT_FALSE = 'No';
    private static final String TASK_STATUS_TO_CLOSE = 'Completed';
    private static final String CREATIVE_SOURCE_FOR_DISPLAY = 'Premedia';

	/**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will identify the product order and customer activity to update 
    * 				which are related to approved proof.	
    * @param        Map<Id, SocialCampaign__c> updateProofs, Map<Id, SocialCampaign__c> oldProofs
    * @return       void
    */
    public static void AfterUpdate(Map<Id, SocialCampaign__c> updateProofs, Map<Id, SocialCampaign__c> oldProofs){
        List<Id> allProofsProductIds = new List<Id>();
        List<Id> allProofsIds = new List<Id>();
        Map<String,String> productIdStatusMap = new Map<String,String>();
       
        for(SocialCampaign__c proof : updateProofs.values()) {
            if((proof.Status__c != oldProofs.get(proof.Id).Status__c) && (proof.Status__c == 'Approved' || proof.Status__c == 'In Review')){ 
                allProofsProductIds.add(proof.Product_Order__c);
                allProofsIds.add(proof.Id);
                productIdStatusMap.put(proof.Product_Order__c,proof.Status__c);
            }
        }   
        if(allProofsProductIds!=null && allProofsProductIds.size()>0){ 
            List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Social = new List<Product_Order__c>();
            List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Display = new List<Product_Order__c>();
            List<String>  listOfProductOrderIdsOf_FulfillmentType_Display = new List<String>();
            /**
            * fetch product orders associated to Proofs
            */
            List<Product_Order__c> listOfProductOrder = [Select id,Approved_By_Client__c,Fulfillment_Type__c,(Select Id,Creative_Source__c,Client_Approved__c from Creatives__r) from Product_Order__c where id IN: allProofsProductIds];
            if(listOfProductOrder!=null && listOfProductOrder.size()>0){
                for(Product_Order__c productOrder : listOfProductOrder){ 
                    if(productOrder.Fulfillment_Type__c == PO_FULFILLMENT_TYPE_SOCIAL){
                        listOfProductOrderOf_FulfillmentType_Social.add(productOrder);
                    }else if(productOrder.Fulfillment_Type__c == PO_FULFILLMENT_TYPE_DISPLAY){
                            listOfProductOrderOf_FulfillmentType_Display.add(productOrder);
                    }
                }
            }
            //Update product order if fulfillment type is social
            if(listOfProductOrderOf_FulfillmentType_Social!=null && listOfProductOrderOf_FulfillmentType_Social.size()>0){
                ProcessFulfillmentType_Social(listOfProductOrderOf_FulfillmentType_Social,productIdStatusMap);
            }
            //Update creative if fulfillment type is display
            if(listOfProductOrderOf_FulfillmentType_Display!=null && listOfProductOrderOf_FulfillmentType_Display.size()>0){
                ProcessFulfillmentType_Display(listOfProductOrderOf_FulfillmentType_Display,productIdStatusMap);
            }
            //Close customer activity related to proof
            if(allProofsIds!=null && allProofsIds.size()>0){
                processCustomerActivity(allProofsIds);
            }
        }
    }

    /**
    * @author       Paras Prajapati 
    * @date         2018-09-24
    * @description  This method will process product order with fulfillment type 'Social'.
    * 				Update Approved_By_Client__c field of product order as per proof status 
    * 				and close related orchestrator task.
    * @param        List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Social,
                    Map<String,String> productIdStatusMap
    * @return       Void
    */
    public static void ProcessFulfillmentType_Social(List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Social,
                                                     Map<String,String> productIdStatusMap){
        boolean updateTask = false;
        List<String> productIdsList = new List<String>();
        List<NXX2_Proof_Setting__mdt> triggerConfig = [Select Approval_Status__c,Request_Change_Status__c,Task_Record_Type__c,TaskSubject__c from NXX2_Proof_Setting__mdt WHERE QualifiedApiName =: METADATA_API_NAME_FOR_SOCIAL_PO];
        //Update product order -- Start
        for(Product_Order__c productOrder : listOfProductOrderOf_FulfillmentType_Social){
             if(productIdStatusMap.get(productOrder.id) == triggerConfig[0].Approval_Status__c.toLowerCase()){
                productOrder.Approved_By_Client__c = APPROVED_BY_CLIENT_TRUE; 
                productIdsList.add(productOrder.id);
             }else if(productIdStatusMap.get(productOrder.id) == triggerConfig[0].Request_Change_Status__c.toLowerCase()){
                productOrder.Approved_By_Client__c = APPROVED_BY_CLIENT_FALSE;
                productIdsList.add(productOrder.id);
            }
        } 
        update listOfProductOrderOf_FulfillmentType_Social; 
        //Update product order -- End
        
        //Close orchestrator task -- Start
        if(productIdsList!=null && productIdsList.size()>0){
            //Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(triggerConfig[0].Task_Record_Type__c).getRecordTypeId();
            List<Task> tasks = [SELECT Subject,Status,RecordTypeId,IsVisibleInSelfService FROM Task WHERE subject =: triggerConfig[0].TaskSubject__c /*AND RecordTypeId =: taskRecordTypeId*/ AND WhatId IN: productIdsList];
            if(tasks != null && tasks.size() > 0){
                for(Task task : tasks){
                    task.status = TASK_STATUS_TO_CLOSE;
                	task.IsVisibleInSelfService = true; //KAMAL CHECK
                }
                update tasks;
            }
        }
        //Close orchestrator task -- End
    }
	

	/**
    * @author       Paras Prajapati
    * @date         2018-09-24
    * @description  This method will process product order with fulfillment type 'Display'.
    * 				Update Client_Approved__c field of Creative as per proof status
    * 				and close related orchestrator task.
    * @param        List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Social,
                    Map<String,String> productIdStatusMap
    * @return       Void
    */
    public static void ProcessFulfillmentType_Display(List<Product_Order__c>  listOfProductOrderOf_FulfillmentType_Display,
                                                      Map<String,String> productIdStatusMap){
        List<Creative__c> creatives = new List<Creative__c>();
        List<String> creativeIds = new List<String>();
        List<NXX2_Proof_Setting__mdt> triggerConfig = [Select Approval_Status__c,Request_Change_Status__c,Task_Record_Type__c,TaskSubject__c from NXX2_Proof_Setting__mdt WHERE QualifiedApiName =: METADATA_API_NAME_FOR_DISPLAY_PO];
		//Update creative -- Start
        for(Product_Order__c productOrder : listOfProductOrderOf_FulfillmentType_Display){
            if(productOrder.Creatives__r!=null){
          		if(productIdStatusMap.get(productOrder.id) == triggerConfig[0].Approval_Status__c.toLowerCase()){
                    for(Creative__c creative : productOrder.Creatives__r){ 
                        if(creative.Creative_Source__c == CREATIVE_SOURCE_FOR_DISPLAY){
                            creative.Client_Approved__c = APPROVED_BY_CLIENT_TRUE; 
                            creatives.add(creative);
                            creativeIds.add(creative.Id);
                        }
                    }
                }else if(productIdStatusMap.get(productOrder.id)== triggerConfig[0].Request_Change_Status__c.toLowerCase()){
                        for(Creative__c creative : productOrder.Creatives__r){
                            if(creative.Creative_Source__c == CREATIVE_SOURCE_FOR_DISPLAY){
                                creative.Client_Approved__c = APPROVED_BY_CLIENT_FALSE;
                                creatives.add(creative);
                                creativeIds.add(creative.Id);
                            }
                        }
                    }
             }
        }
        //Update creative -- End
                                                           
        //Close orchestrator task -- Start
        if(creatives!=null && creatives.size()>0){
            update creatives;
            //Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(triggerConfig[0].Task_Record_Type__c).getRecordTypeId();
            List<Task> tasks = [SELECT Id,Subject,Status,RecordTypeId,IsVisibleInSelfService FROM Task WHERE subject =: triggerConfig[0].TaskSubject__c /*AND RecordTypeId =: taskRecordTypeId*/  AND WhatId IN: creativeIds];
            for(Task task : tasks){
                task.status = TASK_STATUS_TO_CLOSE;
                task.IsVisibleInSelfService = true; //KAMAL CHECK
            }
            update tasks;
        }
        //Close orchestrator task -- End
    }

	/**
    * @author       Paras Prajapati
    * @date         2018-09-24
    * @description  This method will close customer activity related to approved/rejected proof.
    * @param        List<String> listOfProofIds
    * @return       Void
    */
    public static void processCustomerActivity(List<String> listOfProofIds){
        boolean updateRecord = false;
        List<Customer_Task__c> customerTaskList = [Select Id from Customer_Task__c where Social_Campaign__c IN:listOfProofIds];
		if(customerTaskList!=null && customerTaskList.size()>0){
			for(Customer_Task__c customerTask : customerTaskList){
				customerTask.Status__c = TASK_STATUS_TO_CLOSE;
			}
		 update	customerTaskList;
		}
    }
}