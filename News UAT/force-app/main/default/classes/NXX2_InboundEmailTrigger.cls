/**
* @author       Kamal Sharma
* @date         2018-05-23
* @className	NXX2_InboundEmailTrigger
* @description  This class handles emails received from X2 platform for client response.
*/
global class NXX2_InboundEmailTrigger implements Messaging.InboundEmailHandler{
    
    //Constants to be used by this class
    private static final String PONAME_PREFIX_TO_CHECK_IN_MAIL_SUBJECT = 'PO-';
    private static final String METADATA_API_NAME_FOR_SOCIAL_PO = 'Inbound_Mail_Config_For_Social_PO';
    private static final String METADATA_API_NAME_FOR_DISPLAY_PO = 'Inbound_Mail_Config_For_Display_PO';
    private static final String PO_FULFILLMENT_TYPE_SOCIAL = 'Social';
    private static final String PO_FULFILLMENT_TYPE_DISPLAY = 'Display';
    private static final String APPROVED_BY_CLIENT_TRUE = 'Yes';
    private static final String APPROVED_BY_CLIENT_FALSE = 'No';
    private static final String TASK_STATUS_TO_CLOSE = 'Completed';
    private static final String CREATIVE_SOURCE_FOR_DISPLAY = 'Premedia';

        /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will process the inbound email and will update ProductOrder and related task.
    * @param        Messaging.inboundEmail email, Messaging.InboundEnvelope envelope
    * @return       Messaging.InboundEmailResult
    */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try{
            system.debug('****** Subject : '+email.subject);
            system.debug('****** Body : '+email.plainTextBody);
            if(email.subject != '' && email.subject != null  && email.plainTextBody != '' && email.plainTextBody != null && email.subject.contains(PONAME_PREFIX_TO_CHECK_IN_MAIL_SUBJECT)){
                List<Product_Order__c> productOrder = [SELECT Approved_By_Client__c,Fulfillment_Type__c,(SELECT Creative_Source__c FROM Creatives__r WHERE Creative_Source__c =: CREATIVE_SOURCE_FOR_DISPLAY) FROM Product_Order__c WHERE Name =: email.subject];
                if(productOrder != null && productOrder.size() > 0 && productOrder[0].Fulfillment_Type__c != null){
                    if(productOrder[0].Fulfillment_Type__c.toLowerCase() == PO_FULFILLMENT_TYPE_SOCIAL.toLowerCase()){
                        ProcessMailForFulfillmentType_Social(productOrder[0],email);
                    }else if(productOrder[0].Fulfillment_Type__c.toLowerCase() == PO_FULFILLMENT_TYPE_DISPLAY.toLowerCase() && productOrder[0].creatives__r.size() > 0){
                        ProcessMailForFulfillmentType_Display(productOrder[0],email);
                    }
                }
            }
            result.success = true;
        }catch(Exception e){
            result.success = false;
            result.message = e.getMessage();
        }
        return result;
    }
       /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @description  This method will process the inbound email for product order with fulfillment type 'Social'.
    * @param        Product_Order__c productOrder,Messaging.inboundEmail email,NXX2_InboundEmailConfig__mdt config
    * @return       Void
    */
    private void ProcessMailForFulfillmentType_Social(Product_Order__c productOrder,Messaging.inboundEmail email){
        boolean updateTask = false;
        List<NXX2_InboundEmailConfig__mdt> inboundMailConfig = [SELECT EmailBodyTextForApproval__c, EmailBodyTextForRequestChange__c, TaskSubject__c, TaskRecordType__c FROM NXX2_InboundEmailConfig__mdt WHERE QualifiedApiName =: METADATA_API_NAME_FOR_SOCIAL_PO];
        if(email.plainTextBody.trim().toLowerCase() == inboundMailConfig[0].EmailBodyTextForApproval__c.toLowerCase()){
            productOrder.Approved_By_Client__c = APPROVED_BY_CLIENT_TRUE;
            updateTask = true;
        }else if(email.plainTextBody.trim().toLowerCase() == inboundMailConfig[0].EmailBodyTextForRequestChange__c.toLowerCase()){
            productOrder.Approved_By_Client__c = APPROVED_BY_CLIENT_FALSE;
            updateTask = true;
        }
        update productOrder;
        if(updateTask){
            Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName()
                .get(inboundMailConfig[0].TaskRecordType__c).getRecordTypeId();
            List<Task> tasks = [SELECT Subject,Status,RecordTypeId FROM Task WHERE subject =: inboundMailConfig[0].TaskSubject__c AND RecordTypeId =: taskRecordTypeId AND WhatId =: productOrder.Id];
            if(tasks != null && tasks.size() > 0){
                for(Task task : tasks){
                    task.status = TASK_STATUS_TO_CLOSE;
                }
                update tasks;
            }
        }
    }
       /**
    * @author       Kamal Sharma
    * @date         2018-05-29
    * @description  This method will process the inbound email for product order with fulfillment type 'Display'.
    * @param        Product_Order__c productOrder,Messaging.inboundEmail email,NXX2_InboundEmailConfig__mdt config
    * @return       Void
    */
    private void ProcessMailForFulfillmentType_Display(Product_Order__c productOrder,Messaging.inboundEmail email){
        boolean updateRecord = false;
        List<Creative__c> creatives = new List<Creative__c>();
        List<NXX2_InboundEmailConfig__mdt> inboundMailConfig = [SELECT EmailBodyTextForApproval__c, EmailBodyTextForRequestChange__c, TaskSubject__c, TaskRecordType__c FROM NXX2_InboundEmailConfig__mdt WHERE QualifiedApiName =: METADATA_API_NAME_FOR_DISPLAY_PO];
        if(email.plainTextBody.trim().toLowerCase() == inboundMailConfig[0].EmailBodyTextForApproval__c.toLowerCase()){
            for(Creative__c creative : productOrder.Creatives__r){
                if(creative.Creative_Source__c == CREATIVE_SOURCE_FOR_DISPLAY){
                    creative.Client_Approved__c = APPROVED_BY_CLIENT_TRUE;
                    creatives.add(creative);
                    updateRecord = true;
                }
            }
        }else if(email.plainTextBody.trim().toLowerCase() == inboundMailConfig[0].EmailBodyTextForRequestChange__c.toLowerCase()){
            for(Creative__c creative : productOrder.Creatives__r){
                if(creative.Creative_Source__c == CREATIVE_SOURCE_FOR_DISPLAY){
                    creative.Client_Approved__c = APPROVED_BY_CLIENT_FALSE;
                    creatives.add(creative);
                    updateRecord = true;
                }
            }
        }
        if(updateRecord){
            update creatives;
            Id taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName()
                .get(inboundMailConfig[0].TaskRecordType__c).getRecordTypeId();
            List<Task> tasks = [SELECT Subject,Status,RecordTypeId FROM Task WHERE subject =: inboundMailConfig[0].TaskSubject__c AND RecordTypeId =: taskRecordTypeId AND WhatId IN (SELECT Id FROM Creative__c WHERE Product_Order__c =: productOrder.Id AND Creative_Source__c =: CREATIVE_SOURCE_FOR_DISPLAY)];
            for(Task task : tasks){
                task.status = TASK_STATUS_TO_CLOSE;
            }
            update tasks;
        }
    }
}