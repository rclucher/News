/**
* @author       Kamal Sharma
* @date         2018-06-06
* @className	NXX2_TaskReportGenerator
* @description  This class provides task related data to the dashboard custom component which will be used for reporting purpose.
*/
public class NXX2_TaskReportGenerator {
        /**
    * @author       Kamal Sharma
    * @date         2018-06-06
    * @description  This method will be used to fetch tasks assigned to the logged in user.
    * @return       List<TaskForReport>
    */
	@auraEnabled
    public static List<TaskForReport> fetchMyTasks(Integer pageNumber,Boolean isSocial){
        List<TaskForReport> TaskForReportList = new List<TaskForReport>();
        TaskForReport taskForReport;
        List<String> taskExcludedStatus = new List<String>{'Done','Cancelled','Completed'};
        List<String> relatedObjectForTask = new List<String>{'Order__c','Product_Order__c','Creative__c'};
        List<String> campaignExcludedStatus = new List<String>{'Rejected', 'Paused', 'Cancelled', 'Campaign Ended', 'Pending for Cancel', 'Pending for Pause'};
        pageNumber = Integer.valueOf(pageNumber);
        if(pageNumber < 20){
            /**
             * Added By : Paras
             * Date : 25 June 2018
             * Code added to fetch the Default Orchestrator User Id,so that it can be 
             * added as part of filter, to avoid task related to Orchestrator.
             */ 
            List<User> userList = [Select Id, Name from User where Name='Default Orchestrator'];
            String defaultOrchestrotorUserId = '';
            if(userList!=null && userList.size()>0){
                defaultOrchestrotorUserId = userList[0].Id;
            }
            Id recordTypeIdForQATask = Schema.SObjectType.Task.getRecordTypeInfosByName()
            .get('QA Check').getRecordTypeId();
            Integer recordStart = pageNumber * 100;
            Integer recordEnd = (pageNumber+1) * 100;
            List<Task> tasks;
            if(isSocial){
                tasks = [SELECT Subject, Status, What.Name, CreatedDate, WhatId, What.Type FROM Task
                                WHERE OwnerId = :UserInfo.getUserId() 
                                AND RecordTypeId != :recordTypeIdForQATask
                                AND What.Type IN : relatedObjectForTask 
                                AND Status NOT IN :taskExcludedStatus 
                         		ORDER BY CreatedDate
                                LIMIT 4000];
            }else{
                tasks = [SELECT Subject, Status, What.Name, CreatedDate, WhatId, What.Type FROM Task
                                WHERE OwnerId = :UserInfo.getUserId() 
                                AND CSPOFA__Orchestration_Step__c  = null
                                AND RecordTypeId != :recordTypeIdForQATask
                                AND CreatedById !=:defaultOrchestrotorUserId
                                AND What.Type IN : relatedObjectForTask 
                                AND Status NOT IN :taskExcludedStatus 
                         		ORDER BY CreatedDate
                                LIMIT 4000];
            }
            Map<String,Set<Id>> relatedObjectsIds = new Map<String,Set<Id>>{
                'CampaignOrder' => new Set<Id>(),
                'ProductOrder' => new Set<Id>(),
                'Creative' => new Set<Id>()
            };
            for(Task task : tasks){
                if(task.What.Type == 'Order__c'){
                    relatedObjectsIds.get('CampaignOrder').add(task.WhatId);
                }else if(task.What.Type == 'Product_Order__c'){
                    relatedObjectsIds.get('ProductOrder').add(task.WhatId);
                }else if(task.What.Type == 'Creative__c'){
                    relatedObjectsIds.get('Creative').add(task.WhatId);
                }
            }
            Map<Id,Creative__c> creativesMap = new Map<Id,Creative__c>([SELECT Product_Order__r.Account_Name__c,Product_Order__r.Customer_Tier__c,
                                           Product_Order__r.Proposed_Start_Date__c,Product_Order__r.Assigned_Fulfilment_Owner__r.Name,
                                           Product_Order__r.Order__r.Assigned_Campaign_Manager__r.Name,Product_Order__r.Next_Social_Go_Live__c 
                                           FROM Creative__c 
                                           WHERE Id IN:relatedObjectsIds.get('Creative') 
                                           AND Product_Order__r.Order__r.Status__c NOT IN :campaignExcludedStatus 
                                           AND Product_Order__r.Order__r.Opportunity__r.StageName != 'Closed Lost']);
            Map<Id,Product_Order__c> productOrdersMap = new Map<Id,Product_Order__c>([SELECT Account_Name__c,Customer_Tier__c,Proposed_Start_Date__c,
                                                    Assigned_Fulfilment_Owner__r.Name,Order__r.Assigned_Campaign_Manager__r.Name,
                                                    Next_Social_Go_Live__c,Order__c
                                                    FROM Product_Order__c 
                                                    WHERE Order__r.Status__c NOT IN :campaignExcludedStatus 
                                                    AND Order__r.Opportunity__r.StageName != 'Closed Lost' 
                                                    AND (Id IN :relatedObjectsIds.get('ProductOrder') 
                                                         OR Order__c IN :relatedObjectsIds.get('CampaignOrder'))]);
            Map<Id,Product_Order__c> campaignOrdersMap = new Map<Id,Product_Order__c>();
            for(Product_Order__c productOrder : productOrdersMap.values()){
                if(!campaignOrdersMap.containsKey(productOrder.Order__c)){
                    campaignOrdersMap.put(productOrder.Order__c, productOrder);
                }
            }
            Integer count = 0;
            Creative__c creative;
            Product_Order__c productOrder;
            for(Task task : tasks){
                if(task.what.type == 'Order__c' && campaignOrdersMap.containsKey(task.WhatId)){
                    count++;
                    if(count > recordStart && count <= recordEnd){
                        productOrder = campaignOrdersMap.get(task.WhatId);
                        taskForReport = new TaskForReport();
                        taskForReport.taskId = task.Id;
                        taskForReport.relatedToId = productOrder.Id;
                        taskForReport.taskSubject = task.Subject;
                        taskForReport.taskStatus = task.Status;
                        taskForReport.createdDate = task.CreatedDate.date();
                        taskForReport.taskRelatedTo = task.What.Name;
                        taskForReport.accountName = productOrder.Account_Name__c;
                        taskForReport.customerTier = productOrder.Customer_Tier__c;
                        taskForReport.proposedStartDate = productOrder.Proposed_Start_Date__c;
                        taskForReport.assignedFulfillmentOwner = productOrder.Assigned_Fulfilment_Owner__r.Name;
                        taskForReport.assignedCampaignManager = productOrder.Order__r.Assigned_Campaign_Manager__r.Name;
                        taskForReport.nextSocialGoLive = productOrder.Next_Social_Go_Live__c;
                        TaskForReportList.add(taskForReport);
                    }else if(count > recordEnd){
                        break;
                    }
                }else if(task.what.type == 'Product_Order__c' && productOrdersMap.containsKey(task.WhatId)){
                    count++;
                    if(count > recordStart && count <= recordEnd){
                        productOrder = productOrdersMap.get(task.WhatId);
                        taskForReport = new TaskForReport();
                        taskForReport.taskId = task.Id;
                        taskForReport.relatedToId = productOrder.Id;
                        taskForReport.taskSubject = task.Subject;
                        taskForReport.taskStatus = task.Status;
                        taskForReport.createdDate = task.CreatedDate.date();
                        taskForReport.taskRelatedTo = task.What.Name;
                        taskForReport.accountName = productOrder.Account_Name__c;
                        taskForReport.customerTier = productOrder.Customer_Tier__c;
                        taskForReport.proposedStartDate = productOrder.Proposed_Start_Date__c;
                        taskForReport.assignedFulfillmentOwner = productOrder.Assigned_Fulfilment_Owner__r.Name;
                        taskForReport.assignedCampaignManager = productOrder.Order__r.Assigned_Campaign_Manager__r.Name;
                        taskForReport.nextSocialGoLive = productOrder.Next_Social_Go_Live__c;
                        TaskForReportList.add(taskForReport);
                    }else if(count > recordEnd){
                        break;
                    }
                }else if(creativesMap.containsKey(task.WhatId)){
                    count++;
                    if(count > recordStart && count <= recordEnd){
                        creative = creativesMap.get(task.WhatId);
                        taskForReport = new TaskForReport();
                        taskForReport.taskId = task.Id;
                        taskForReport.relatedToId = creative.Id;
                        taskForReport.taskSubject = task.Subject;
                        taskForReport.taskStatus = task.Status;
                        taskForReport.createdDate = task.CreatedDate.date();
                        taskForReport.taskRelatedTo = task.What.Name;
                        taskForReport.accountName = creative.Product_Order__r.Account_Name__c;
                        taskForReport.customerTier = creative.Product_Order__r.Customer_Tier__c;
                        taskForReport.proposedStartDate = creative.Product_Order__r.Proposed_Start_Date__c;
                        taskForReport.assignedFulfillmentOwner = creative.Product_Order__r.Assigned_Fulfilment_Owner__r.Name;
                        taskForReport.assignedCampaignManager = creative.Product_Order__r.Order__r.Assigned_Campaign_Manager__r.Name;
                        taskForReport.nextSocialGoLive = creative.Product_Order__r.Next_Social_Go_Live__c;
                        TaskForReportList.add(taskForReport);
                    }else if(count > recordEnd){
                        break;
                    }
                }
            }
        }
        
        return TaskForReportList;
    }
    
        /**
    * @author       Kamal Sharma
    * @date         2018-06-06
    * @className	TaskForReport
    * @description  This is a wrapper class to provide formatted data for task.
    */
    public class TaskForReport{
        @AuraEnabled public Id taskId;
        @AuraEnabled public Id relatedToId;
        @AuraEnabled public String taskSubject;
        @AuraEnabled public String taskStatus;
        @AuraEnabled public String taskRelatedTo;
        @AuraEnabled public String accountName;
        @AuraEnabled public String customerTier;
        @AuraEnabled public Date createdDate;
        @AuraEnabled public Date proposedStartDate;
        @AuraEnabled public String assignedFulfillmentOwner;
        @AuraEnabled public String assignedCampaignManager;
        @AuraEnabled public Date nextSocialGoLive;
    }
}