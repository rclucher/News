/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_CustomerActivityTriggerHandler
* @description  This is the handler class for customer activity trigger.
*/
public class NXX2_CustomerActivityTriggerHandler extends NXX2_TriggerHandler_Utility implements NXX2_TriggerHandler
{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  Checks to see if the trigger has been disabled either by custom setting or by running code
    * @param        NA
    * @return       Boolean
    */
    public Boolean IsDisabled()
    {
        NXX2_TriggerSettings__c triggerSettings = NXX2_TriggerSettings__c.getInstance();
        if (triggerSettings.CustomerActivityTriggerDisabled__c){
            return true;
        }else{
            return TriggerDisabled;
        }
    }
 
    public void BeforeInsert(List<SObject> newItems){}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 	/**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will initialize two process on new customer activity record insertion:
    * 				1.	Share customer activity with portal user based on configuration in customer role access
    * 				2.	Update proof status or close perticular task based on inserted customer activity type
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void AfterInsert(Map<Id, SObject> newItems) {
        List<Customer_Task__c> customeActivities = [SELECT Campaign_Order__r.Opportunity__c,Product_Order__c,Social_Campaign__r.Product_Order__c,Type__c,Social_Campaign__c,
                                                  Product_Order__r.Order__r.Opportunity__c,
                                                  Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c 
                                                  FROM Customer_Task__c WHERE Id IN :newItems.keySet()];
        Map<Id,Id> customerActivityToOpportunityMap = new Map<Id,Id>();
        for(Customer_Task__c customerActivity : customeActivities){
            if(customerActivity.Campaign_Order__r.Opportunity__c != null){
            	customerActivityToOpportunityMap.put(customerActivity.Id, customerActivity.Campaign_Order__r.Opportunity__c);
            }else if(customerActivity.Product_Order__r.Order__r.Opportunity__c != null){
            	customerActivityToOpportunityMap.put(customerActivity.Id, customerActivity.Product_Order__r.Order__r.Opportunity__c);
            }else if(customerActivity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c != null){
            	customerActivityToOpportunityMap.put(customerActivity.Id, customerActivity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c);
            }
        }
        //Sharing logic for customer ctivity
        customerActivitySharingOnInsertion(customerActivityToOpportunityMap);
        //Update proof and task logic
        markCMSSendingctivitytoCustomerAscompleted(customeActivities);
    }
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share the customer activity with portal user.
    * @param        Map<Id,Id> customerActivityToOpportunityMap
    * @return       void
    */
    private void customerActivitySharingOnInsertion(Map<Id,Id> customerActivityToOpportunityMap){
        try{
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get all related primary and agency account for the opportunities related to proof records.
            populateAccountsToPrimaryAccountsMap(new Set<Id>(customerActivityToOpportunityMap.values()),null);
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get all contact role for the related primary and agency account fetched earlier.
            populateContactRoleDataForTheAccounts(accountsToPrimaryAccountsMap.keySet());
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get customer role access record for the roles related to fetched contact roles.
            populateCustomerRoleAccessMap();
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get existing customer portal user for the related contacts in contact roles.
            populateContactUserMap();
            //Share Customer Activity records with the fetched/created portal users.
            initializeSharing(customerActivityToOpportunityMap.keySet());
            if(customerActivityShareList.size() > 0){
            	insert customerActivityShareList;
            }
        }catch(Exception e){
            system.debug('Class NXX2_ShareRecordUtility, Method recalculateAccountSharing');
            system.debug('Exception: '+ e.getStackTraceString());
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share the customer activity with portal user.
    * @param        Set<Id> customerActivityIds
    * @return       void
    */
    private void initializeSharing(Set<Id> customerActivityIds){
        //This variable belongs to NXX2_TriggerHandler_Utility class
        customerActivityShareList = new List<Customer_Task__Share>();
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                if(customerRoleAccess.Account_Access__c != 'None' && customerRoleAccess.Customer_Activity_Access__c != 'None'){
                    //This method belongs to NXX2_TriggerHandler_Utility Class 
                    //and will create customer activity share record
                    populateCustomerActivityShareList(contactRole.Contact__c,customerActivityIds,customerRoleAccess);
                }
            }
        }
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2019-01-02
    * @description  When user create customer task against Proof record of type 'Upload Creative Assets', 
    * 				the method will look for the task the CM has with subject = 'Send the content plan to client for approval'
    * 				in Product Order and mark that task completed
    * @param        List<Customer_Task__c> customerTaskList
    * @return       void
    */
    private void markCMSSendingctivitytoCustomerAscompleted(List<Customer_Task__c> customerTaskList){
        if(customerTaskList.size()>0){
            List<Id> productIds= new List<Id>();
            for(Customer_Task__c customer_Task : customerTaskList){
                if(customer_Task.Type__c=='Upload Creative Assets' && customer_Task.Social_Campaign__r.Product_Order__c!=null && customer_Task.Social_Campaign__c!=null){
                    productIds.add(customer_Task.Social_Campaign__r.Product_Order__c);
                }
            }
            if(productIds.size()>0){
                List<Task> taskList = [Select Id,subject,Status,CSPOFA__Orchestration_Step__r.Name from Task where Status!='Completed' AND CSPOFA__Orchestration_Step__c!=null AND subject = 'Send the content plan to client for approval' AND WhatId IN:productIds];
                if(taskList.size()>0){
                    for(Task taskRecord : taskList){
                        taskRecord.Status = 'Completed';
                    }
                    update taskList;
                    markProofRecordsWithCustomer(customerTaskList);
                }
            }
        }
    }

    /**
    * @author       Paras Prajapati
    * @date         2019-01-02
    * @description  When user create customer task against Proof with type 'Approve and Review Your Display Ads' 
    * 				or 'Approve and Review Your Facebook Ads' or Approve and Review Your Landing Page' 
    * 				then it will update Proof Status to 'With Customer'
    * @param        List<Customer_Task__c> customerTaskList
    * @return       void
    */
    private void markProofRecordsWithCustomer(List<Customer_Task__c> customerTaskList){
        if(customerTaskList.size()>0){
            List<Id> proofIds= new List<Id>();
            for(Customer_Task__c customer_Task : customerTaskList){
                if((customer_Task.Type__c=='Approve and Review Your Display Ads' || customer_Task.Type__c=='Approve and Review Your Facebook Ads' || customer_Task.Type__c=='Approve and Review Your Landing Page') &&  customer_Task.Social_Campaign__c!=null){
                    proofIds.add(customer_Task.Social_Campaign__c);
                }
            }
            if(proofIds.size()>0){
                List<SocialCampaign__c> listOfProof = [Select Id,Status__c from SocialCampaign__c where Id IN:proofIds];
                if(listOfProof.size()>0){
                    for(SocialCampaign__c social_Campaign:listOfProof){
                        social_Campaign.Status__c = 'With Customer';
                        social_Campaign.Number_of_Email_Sent_For_Approval__c= 0;
                        social_Campaign.Send_Approval_Emails__c = false;
                    }
                    update listOfProof;
                }
            }
        }
    }
}