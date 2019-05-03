/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_CustomerRoleAccessTriggerHandler
* @description  This is the handler class for proof trigger.
*/
public class NXX2_CustomerRoleAccessTriggerHandler extends NXX2_TriggerHandler_Utility implements NXX2_TriggerHandler
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
        if (triggerSettings.CustomerRoleAccessTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will initiate sharing of records with portal users 
    * 				on insertion of new customer role access record.
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void AfterInsert(Map<Id, SObject> newItems) {
        Customer_Role_Access__c newCustomerRoleAccess;
        //This variable is declaired in NXX2_TriggerHandler_Utility class
    	customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        //This variable is declaired in NXX2_TriggerHandler_Utility class
        contactRoleAccessCommunityUserProfiles = new Set<String>();
        for(Id customerRoleAccessId : newItems.keySet()){
            newCustomerRoleAccess = ((Map<Id, Customer_Role_Access__c>)newItems).get(customerRoleAccessId);
            if(newCustomerRoleAccess.Account_Access__c != 'None'){
                customerRoleAccessMap.put(newCustomerRoleAccess.Contact_Role__c,newCustomerRoleAccess);
                contactRoleAccessCommunityUserProfiles.add(newCustomerRoleAccess.Community_User_Profile__c);
            }
        }
        //This method is declaired in NXX2_TriggerHandler_Utility class
        //This method will populate all contact roles with the role related to new customer role access record.
        populateContactRoleDataForTheRoles(customerRoleAccessMap.keySet());
        //This method is declaired in NXX2_TriggerHandler_Utility class
        //This method will populate all users for the contacts related to contact roles fetched earlier.
        populateContactUserMap();
        //This method will start sharing of records for new customer role access.
        accountSharingOnCustomerRoleAccessChange();
    }
    
 	/**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will initiate sharing of records with portal users 
    * 				on updation of customer role access record.
    * @param        Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Customer_Role_Access__c newCustomerRoleAccess;
        Customer_Role_Access__c oldCustomerRoleAccess;
        //This variable is declaired in NXX2_TriggerHandler_Utility class
    	customerRoleAccessMap = new Map<String,Customer_Role_Access__c>();
        //This variable is declaired in NXX2_TriggerHandler_Utility class
        contactRoleAccessCommunityUserProfiles = new Set<String>();
        for(Id customerRoleAccessId : newItems.keySet()){
            newCustomerRoleAccess = ((Map<Id, Customer_Role_Access__c>)newItems).get(customerRoleAccessId);
            oldCustomerRoleAccess = ((Map<Id, Customer_Role_Access__c>)oldItems).get(customerRoleAccessId);
            if(newCustomerRoleAccess.Account_Access__c != newCustomerRoleAccess.Account_Access__c ||
               newCustomerRoleAccess.Proof_Access__c != newCustomerRoleAccess.Proof_Access__c ||
               newCustomerRoleAccess.Customer_Activity_Access__c != newCustomerRoleAccess.Customer_Activity_Access__c){
                customerRoleAccessMap.put(newCustomerRoleAccess.Contact_Role__c,newCustomerRoleAccess);
            	contactRoleAccessCommunityUserProfiles.add(newCustomerRoleAccess.Community_User_Profile__c);
            }
        }
        //This method is declaired in NXX2_TriggerHandler_Utility class
        //This method will populate all contact roles with the role related to new customer role access record.
        populateContactRoleDataForTheRoles(customerRoleAccessMap.keySet());
        //This method is declaired in NXX2_TriggerHandler_Utility class
        //This method will populate all users for the contacts related to contact roles fetched earlier.
        populateContactUserMap();
        //This method will delete all existing share records for the updated customer role access
        deleteExisitngSharing();
        //This method will start sharing of records for new customer role access.
        accountSharingOnCustomerRoleAccessChange();
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share the accounts,proofs and customer activities with related users.
    * @param        NA
    * @return       void
    */
    private void accountSharingOnCustomerRoleAccessChange(){
        try{
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get opportunties related to contact roles
            Set<Id> opportunityIds = populateAccountsToPrimaryAccountsMap(null,accountContactRoleMap.keySet());
            //Remove contacts having active portal user already.
            contactIds.removeAll(contactUserMap.keySet());
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Create portal user for rest of the contacts.
            createCommunityUserForContacts();
            //Populate Account,Proof and Customer Activity share list to insert
            initializeSharing(opportunityIds,true);
            if(accountShareList.size() > 0){
            	insert accountShareList;
            }
            if(proofShareList.size() > 0){
            	insert proofShareList;
            }
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
    * @description  This method will share the accounts,proofs and customer activities with related users.
    * @param        Set<Id> opportunityIds,Boolean updateAll
    * @return       void
    */
    private void initializeSharing(Set<Id> opportunityIds,Boolean updateAll){
        Map<Id,SocialCampaign__c> proofs;
        Map<Id,Customer_Task__c> customerActivities;
        if(updateAll){
            proofs = new Map<Id,SocialCampaign__c>([SELECT Id FROM SocialCampaign__c 
                      WHERE Product_Order__r.Order__r.Opportunity__c IN : opportunityIds AND Visible_To_Customer__c = true]);
            customerActivities = new Map<Id,Customer_Task__c>([SELECT Id FROM Customer_Task__c WHERE Product_Order__r.Order__r.Opportunity__c IN :opportunityIds 
                                  OR Campaign_Order__r.Opportunity__c IN :opportunityIds 
                                  OR Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c IN :opportunityIds]);
        }
        //This variable belongs to NXX2_TriggerHandler_Utility class
        accountShareList = new List<AccountShare>();
        //This variable belongs to NXX2_TriggerHandler_Utility class
        proofShareList = new List<SocialCampaign__Share>();
        //This variable belongs to NXX2_TriggerHandler_Utility class
        customerActivityShareList = new List<Customer_Task__Share>();
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                if(customerRoleAccess.Account_Access__c != 'None'){
                    //This method belongs to NXX2_TriggerHandler_Utility Class and will create account share record
                    populateAccountShareList(contactRole.Contact__c,accountId,customerRoleAccess);
                    if(updateAll && customerRoleAccess.Proof_Access__c != 'None'){
                        //This method belongs to NXX2_TriggerHandler_Utility Class and will create account share record
                        populateProofShareList(contactRole.Contact__c,proofs.keySet(),customerRoleAccess);
                    }
                    if(updateAll && customerRoleAccess.Customer_Activity_Access__c != 'None'){
                    	//This method belongs to NXX2_TriggerHandler_Utility Class 
                        //and will create customer activity share record
                        populateCustomerActivityShareList(contactRole.Contact__c,customerActivities.keySet(),customerRoleAccess);
                    }
                }
            }
        }
    }
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will delete existing share records related portal users
    * @param        NA
    * @return       void
    */
    private void deleteExisitngSharing(){
        List<AccountShare> accountShareList = [SELECT Id FROM AccountShare 
                                               WHERE UserOrGroupId IN :userIds 
                                               AND RowCause = 'Manual'];
        List<SocialCampaign__Share> proofShareList = [SELECT Id FROM SocialCampaign__Share 
                                               WHERE UserOrGroupId IN :userIds 
                                               AND RowCause = 'Manual'];
        List<Customer_Task__Share> customeActivityShareList = [SELECT Id FROM Customer_Task__Share 
                                               WHERE UserOrGroupId IN :userIds 
                                               AND RowCause = 'Manual'];
        delete accountShareList;
        delete proofShareList;
        delete customeActivityShareList;
    }
}