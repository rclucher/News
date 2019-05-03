/**
* @author       Kamal Sharma
* @date         2018-11-01
* @className    NXX2_OpportunityTriggerHandler
* @description  This is the handler class for opportunity trigger.
*/
public class NXX2_OpportunityTriggerHandler extends NXX2_TriggerHandler_Utility implements NXX2_TriggerHandler
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
        if (triggerSettings.OpportunityTriggerDisabled__c){
            return true;
        }else{
            return TriggerDisabled;
        }
    }
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will initialize sharing of records with portal user on new opportunity insertion.
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void AfterInsert(Map<Id, SObject> newItems) {
        doSharingOnOpportunityChange(newItems.keySet(),false);
    }
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will delete sharing of records with portal user on new opportunity updation 
    *               based on below mentioned critaria:
    *               1.  Check if there is only one opportunity related to the payer account 
    *                   than delete sharing with that payer account.
    *               2.  If there are multiple opportunity and the payer account is not related to any other opportunity 
    *                   except the one which is under process than delete sharing for that payer account.
    * @param        Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Set<Id> opportunitiesWithChange = new Set<Id>();
        //This map will contain the payer account which should nat have access to primary account 
        //and all other related objects.
        Map<Id,Set<Id>> oldAccountsMapToDeleteAll = new Map<Id,Set<Id>>();
        //This map will contain the payer account which should have the access to primary account 
        //but access for all other related objects of the updated opportunities should be removed.
        Map<Id,Set<Id>> oldAccountsMapToDeleteRelatedData = new Map<Id,Set<Id>>();
        Map<Id,Opportunity> accountOpportunityMap = new Map<Id,Opportunity>();
        Set<Id> accountIds = new Set<Id>();
        Opportunity oldOpp;
        //Get opportunities whose payer account has been changed
        for(Opportunity opp:((Map<Id, Opportunity>)newItems).values()){
            oldOpp = ((Map<Id, Opportunity>)oldItems).get(opp.Id);
            if(opp.Payer_Account__c != oldOpp.Payer_Account__c){
                opportunitiesWithChange.add(opp.Id);
                accountIds.add(opp.AccountId);
                accountOpportunityMap.put(opp.AccountId,oldOpp);
            }
        }
        if(opportunitiesWithChange.size() > 0){
            // Get all opportunities related to the payer accounts of the updated opportunities.
            List<Account> accounts = [SELECT (SELECT Payer_Account__c FROM Opportunities) FROM Account WHERE Id IN :accountIds];
            for(Account account : accounts){
                //If there is only one opportunity related to the old payer account of the updated opportunities 
                //than add it for removing sharing.
                if(account.Opportunities.size() == 1){
                    if(accountOpportunityMap.get(account.Id).Payer_Account__c != null){
                        if(!oldAccountsMapToDeleteAll.containsKey(accountOpportunityMap.get(account.Id).Payer_Account__c)){
                            oldAccountsMapToDeleteAll.put(accountOpportunityMap.get(account.Id).Payer_Account__c,new Set<Id>());
                        }
                        oldAccountsMapToDeleteAll.get(accountOpportunityMap.get(account.Id).Payer_Account__c).add(account.Id);
                    }
                }else{
                    //If there is more than one opportunity related to the old payer account of the updated opportunities 
                    //than check that this old payer account should not be related to any other opportunity.
                    //If this is related to any other opportunity 
                    //than this old payer account user should have access of the primary account of this opportunity
                    //and sharing should not be removed
                    Integer count = 0;
                    for(Opportunity opp : account.Opportunities){
                        if(opp.Payer_Account__c == accountOpportunityMap.get(account.Id).Payer_Account__c){
                            count++;
                        }
                    }
                    if(count > 0){
                        if(!oldAccountsMapToDeleteRelatedData.containsKey(account.Id)){
                            oldAccountsMapToDeleteRelatedData.put(account.Id,new Set<Id>());
                        }
                        oldAccountsMapToDeleteRelatedData.get(account.Id).add(accountOpportunityMap.get(account.Id).Id);
                    }
                }
            }
            //This method is in the NXX2_TriggerHandler_Utility class
            //This will delete the existing sharing for the old payer account which was related to the opportunity previously.
            deleteExistingSharingOnOpportunityChange(oldAccountsMapToDeleteAll,oldAccountsMapToDeleteRelatedData);
            //This method is in the NXX2_TriggerHandler_Utility class
            //This will share the records with the new payer account of the updated opportunities.
            doSharingOnOpportunityChange(opportunitiesWithChange,true);
        }
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share the primary account and all related proof and customer activities
    *               with new payer account related to the updated opportunity.
    * @param        Set<Id> opportunityIds,Boolean isUpdate
    * @return       void
    */
    private void doSharingOnOpportunityChange(Set<Id> opportunityIds,Boolean isUpdate){
        try{
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get all related primary and agency account for the opportunities related to proof records.
            populateAccountsToPrimaryAccountsMap(opportunityIds,null);
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get all contact role for the related primary and agency account fetched earlier.
            populateContactRoleDataForTheAccounts(accountsToPrimaryAccountsMap.keySet());
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get customer role access record for the roles related to fetched contact roles.
            populateCustomerRoleAccessMap();
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Get existing customer portal user for the related contacts in contact roles.
            populateContactUserMap();
            //Remove contacts having active portal user already.
            contactIds.removeAll(contactUserMap.keySet());
            //This method is declaired in NXX2_TriggerHandler_Utility class
            //Create portal user for rest of the contacts.
            createCommunityUserForContacts();
            //Share Account, Proof and Customer Activity records with the fetched/created portal users.
            initializeSharing(opportunityIds,isUpdate);
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
    * @description  This method will do two task as mentioned below:
    *               1.  Remove all share records(Primary Account,Proof,Customer Activity) of those payer accounts 
    *                   which are no more related to primary account of the changed opportunity 
    *                   through any other opportunity for the same primary account
    *               2.  Remove share records(proof and customer activity only) related to changed opportunity
    *                   (Since old payer account still in use by some other opportunity for same pimary account)
    * @param        Set<Id> opportunityIds,Boolean isUpdate
    * @return       void
    */
    private void deleteExistingSharingOnOpportunityChange(Map<Id,Set<Id>> oldAccountsMapToDeleteAll,
                                                         Map<Id,Set<Id>> opportunitiesToDeleteSharing){
        try{
            Set<Id> allAccounts = oldAccountsMapToDeleteAll.keySet().clone();
            allAccounts.addAll(opportunitiesToDeleteSharing.keySet());
            //Get all contact roles related to old payer accounts.
            List<Contact_Role__c> conntactRoles = [SELECT Contact__c FROM Contact_Role__c 
                                                   WHERE Account__c IN:allAccounts];
            Set<Id> contactIdsTemp = new Set<Id>();
            for(Contact_Role__c contactRole : conntactRoles){
                contactIdsTemp.add(contactRole.Contact__c);
            } 
            //Get Users related to contacts linked with contact roles fetched earlier.
            Map<Id,User> Users = new Map<Id,User>([SELECT ContactId FROM User WHERE ContactId IN:contactIdsTemp]);
            Set<Id> primaryAccounts = new Set<Id>();
            for(Set<Id> accounts : oldAccountsMapToDeleteAll.values()){
                primaryAccounts.addAll(accounts);
            }
            Set<Id> opportunitiesIds = new Set<Id>();
            for(Set<Id> opportunites : opportunitiesToDeleteSharing.values()){
                opportunitiesIds.addAll(opportunites);
            }
            //fetch and delete shared account,proof and customer activity records -- Start
            List<AccountShare> accountShareListToDelete = [SELECT Id FROM AccountShare 
                                                           WHERE AccountId IN :primaryAccounts 
                                                           AND UserOrGroupId IN :Users.keySet() 
                                                           AND RowCause = 'Manual'];
            delete accountShareListToDelete;
            Map<Id,SocialCampaign__c> proofs = new Map<Id,SocialCampaign__c>([SELECT Account__c FROM SocialCampaign__c 
                                                                              WHERE Account__c IN:primaryAccounts 
                                                                              OR Product_Order__r.Order__r.Opportunity__c IN : opportunitiesIds]);
            Map<Id,Customer_Task__c> customerActivities = new Map<Id,Customer_Task__c>([SELECT Id FROM Customer_Task__c 
                                                                                        WHERE Account__c IN : primaryAccounts
                                                                                        OR Product_Order__r.Order__r.Opportunity__c IN :opportunitiesIds 
                                                                                        OR Campaign_Order__r.Opportunity__c IN :opportunitiesIds 
                                                                                        OR Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c IN :opportunitiesIds]);
            List<SocialCampaign__Share> proofShareListToDelete = [SELECT Id FROM SocialCampaign__Share 
                                                                  WHERE ParentId IN :proofs.keySet() 
                                                                  AND UserOrGroupId IN :Users.keySet() 
                                                                  AND RowCause = 'Manual'];
            delete proofShareListToDelete;
            List<Customer_Task__Share> customerActivityShareListToDelete = [SELECT Id FROM Customer_Task__Share 
                                                                            WHERE ParentId IN :customerActivities.keySet() 
                                                                            AND UserOrGroupId IN :Users.keySet() 
                                                                            AND RowCause = 'Manual'];
            delete customerActivityShareListToDelete;
            ////fetch shared account,proof and customer activity records -- End
        }catch(Exception e){
            system.debug('Class NXX2_ShareRecordUtility, Method deleteExistingSharingUnderAccount');
            system.debug('Exception: '+ e.getStackTraceString());
        }
    }
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share the account,proof and customer activity with the new payer account users.
    * @param        Set<Id> opportunityIds,Boolean isUpdate
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
}