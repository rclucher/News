/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_GoogleDriveFileBrowserController
* @description  Controller class, will be used by the NXX2_CustomerActivitiesListController Component
*/
public without sharing class NXX2_CustomerActivitiesListController {
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getIconName : This method will provide icon name for the given sObject
    * @param        String sObjectName
    * @return       String
    */
    @AuraEnabled
    public static String getIconName(String sObjectName){
          return NXX2_AppUtility.getIconName(sObjectName);
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  resendMailForActivity : This method will send the email notofocation again to the customer 
    * 				as reminder for content approval.
    * @param        Customer_Task__c activity
    * @return       void
    */
	@AuraEnabled
    public static void resendMailForActivity(Customer_Task__c activity){
        NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(new List<Customer_Task__c>{activity});
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  fetchLoggedInUsersDetails : This method will provide logged in user details
    * @param        NA
    * @return       User
    */
    @AuraEnabled
    public static User fetchLoggedInUsersDetails(){
      User loggedInUser = NXX2_SalesforceDataService.fetchLoggedInUsersDetails();
      return loggedInUser;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  fetchCustomerTask : This method will provide all customer activity for the given parent record ID.
    * @param        String parentRecordId,String ParentObjectName,Boolean isExternalUser
    * @return       NXX2_LightningReqRespModel.customerTaskResponse
    */
    @AuraEnabled
    public static NXX2_LightningReqRespModel.customerTaskResponse fetchCustomerTask(String parentRecordId,String ParentObjectName,Boolean isExternalUser){
        String accountIds = '';
        NXX2_LightningReqRespModel.customerTaskResponse customerTaskResponse = new NXX2_LightningReqRespModel.customerTaskResponse();
        List<Customer_Task__c> customerTaskList = NXX2_SalesforceDataService.getCustomerTaskLists(parentRecordId,ParentObjectName,isExternalUser);
        customerTaskResponse = NXX2_AppUtility.getCustomerTaskListDTO(customerTaskList);  
        return customerTaskResponse;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  updateCustomerTaskStatus : This method will provide update status of customer activity.
    * @param        String customerTaskId
    * @return       String
    */
    @AuraEnabled
    public static String updateCustomerTaskStatus(String customerTaskId){ 
       String updateStatus = NXX2_SalesforceDataService.updateCustomerTask(customerTaskId);
       return updateStatus;

    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getCustomerActivityRecordTypeForProof : This method will provide record type of 
    * 				customer activity related to proof object.
    * @param        NA
    * @return       String
    */
    @AuraEnabled
    public static String getCustomerActivityRecordTypeForProof(){
        String recordTypeId='';
        List<RecordType> recordTypeList= [Select Id, Name,developerName,SobjectType  From RecordType where SobjectType ='Customer_Task__c'];
        if(recordTypeList!=null && recordTypeList.size()>0){
            for(RecordType recordType : recordTypeList){
                if(recordType.developerName=='Proof_Customer_Activity'){
                    recordTypeId = recordType.id;
                }
                
            }
        }
        return recordTypeId;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getAllAccessibleAccountCustomerTask : This method will provide customer activities 
    * 				for all accessible accounts to the logged in user
    * @param        String contactId
    * @return       NXX2_LightningReqRespModel.customerTaskResponse
    */
    @AuraEnabled
    public static NXX2_LightningReqRespModel.customerTaskResponse getAllAccessibleAccountCustomerTask(String contactId){  
        List<Account> listOfAccounts = new List<Account>();
        NXX2_LightningReqRespModel.customerTaskResponse customerTaskResponse = new NXX2_LightningReqRespModel.customerTaskResponse();
        System.debug('contactId' + contactId);
        if(contactId!=null && contactId.length()>0){
            //Fetch the User which is related the Contact Id
            List<User> userDetails = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name FROM User WHERE ContactId = :contactId];
            if(userDetails!=null && userDetails.size()>0){
                User contactUser = userDetails.get(0);
                List<String> accessibleAccountIdsList=NXX2_SalesforceDataService.getMyAccounts(String.valueOf(contactUser.Id));
                
                if(accessibleAccountIdsList!=null && accessibleAccountIdsList.size()>0){
                    List<Customer_Task__c> customerTaskList = [Select id,Name,Type__c,Due_Date__c,CreatedDate,Status__c,Product_Order__c,Social_Campaign__c,Campaign_Order__c from Customer_Task__c where Account__c IN :accessibleAccountIdsList];
                    customerTaskResponse = NXX2_AppUtility.getCustomerTaskListDTO(customerTaskList);  
                }
            }
        }
        return customerTaskResponse;
    }

    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  getAllCommentsLinkedToType : This method will provide all comments related to customer activity type.
    * 				These comments will be used to pre-populate when user selects a perticular type for a customer activity.
    * @param        NA
    * @return       Map<String,String>
    */
    @AuraEnabled
	public static Map<String,String> getAllCommentsLinkedToType(){  
        Map<String,String> mapOfTypeAndComments = new Map<String,String>();
        List<NXX2_CustomerActivityComments__mdt> listOfCustomerActivityComments = [Select Type__c,Comments__c from NXX2_CustomerActivityComments__mdt];
        if(listOfCustomerActivityComments.size()>0){
            for(NXX2_CustomerActivityComments__mdt nxx2CustomerActivityComments :listOfCustomerActivityComments){
                mapOfTypeAndComments.put(nxx2CustomerActivityComments.Type__c,nxx2CustomerActivityComments.Comments__c); 
            }
        }
        return mapOfTypeAndComments;
    }
}