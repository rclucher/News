/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_OverrideButtonController
* @description  This class will be used by custom components which are used as quick link buttons.
*/
public without sharing class NXX2_OverrideButtonController {
    /**
    * @name         : getProofRecordTypeId
    * @description  : return record type id for proof.
    * @createdby    : Kamal Sharma - 27 Sep 2018
    * @return       : String
    * @param        : String recordType
    */
    @AuraEnabled
    public static String getProofRecordTypeId(String recordType){
        return Schema.SObjectType.SocialCampaign__c.getRecordTypeInfosByName()
                  .get(recordType).getRecordTypeId();
    }
    
    /**
    * @name         : getProductOrder
    * @description  : return record type id for proof.
    * @createdby    : Kamal Sharma - 27 Sep 2018
    * @return       : Product_Order__c
    * @param        : String recordId
    */
    @AuraEnabled
    public static Product_Order__c getProductOrder(String recordId){
        Product_Order__c po;
        List<Product_Order__c> pos = [SELECT Id,Fulfillment_Type__c FROM Product_Order__c WHERE Id =: recordId];
        if(pos.size() > 0){
            po = pos[0];
        }
        return po;
    }
    
    /**
    * @name         : getAllCommentsLinkedToType
    * @description  : return map of comments related to type for customer activity.
    * @createdby    : Kamal Sharma - 20 Dec 2018
    * @return       : Map<String,String>
    */
    @AuraEnabled
    public static Map<String,String> getAllCommentsLinkedToType(){
        return NXX2_AppUtility.getAllCommentsLinkedToType();
    }
    
    /**
    * @name         : getCustomerTaskRecordType
    * @description  : This method will provide record type of customer activity based on object Id.
    * @createdby    : Kamal Sharma - 20 Dec 2018
    * @param        : String recordId
    * @return       : List<String>
    */
    @AuraEnabled
    public static List<String> getCustomerTaskRecordType(String recordId){
        List<String> response = new List<String>();
        String sObjName = ((Id)recordId).getSObjectType().getDescribe().getName();
        response.add(sObjName);
        String recordType = 'Product Order Customer Activity';
        if(sObjName == 'Order__c'){
            recordType = 'Campaign Order Customer Activity';
        }
        response.add(Schema.SObjectType.Customer_Task__c.getRecordTypeInfosByName()
                  .get(recordType).getRecordTypeId());
        return response;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-08-17
    * @description  resendMailForActivity : This method will send the email notofocation again to the customer 
    * 				as reminder for content approval.
    * @param        Customer_Task__c activity
    * @return       void
    */
	@AuraEnabled
    public static void resendMailForActivity(String activityId){
        Customer_Task__c activity = [SELECT Name,Status__c FROM Customer_Task__c WHERE Id = :activityId];
        if(activity != null && activity.Status__c == 'With Client'){
        	NXX2_SendEmailForCustomerActivity.sendAdHocEmailToCustomer(new List<Customer_Task__c>{activity});
        }else{
            AuraHandledException auraException = new AuraHandledException('Invalid status of the activity to share with the customer!');
            auraException.setMessage('Invalid status of the activity to share with the customer!');
            throw auraException;
        }
    }
    
    /**
    * @name         : markActivityAsCompleted
    * @description  : This will be used to mark activity as completed.
    * @createdby    : Kamal Sharma - 16 Nov 2018
    * @return       : Void
    * @param        : String activityId
    */
    @AuraEnabled
    public static void markActivityAsCompleted(String activityId){
        try{
            Customer_Task__c  activity = [SELECT Status__c 
                                  FROM Customer_Task__c  WHERE Id = :activityId];
            activity.Status__c = 'Completed';
            update activity;
        }catch(Exception e){
            AuraHandledException auraException = new AuraHandledException('Server side issue, Please contact to admin.');
            auraException.setMessage('Server side issue, Please contact to admin.');
            throw auraException;
        }
    }
}