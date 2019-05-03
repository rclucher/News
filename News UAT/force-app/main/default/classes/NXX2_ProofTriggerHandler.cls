/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_ProofTriggerHandler
* @description  This is the handler class for proof trigger.
*/
public class NXX2_ProofTriggerHandler extends NXX2_TriggerHandler_Utility implements NXX2_TriggerHandler
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
        if (triggerSettings.ProofTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
 
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 	 /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will initiate two process on proof record update:
    * 				1.	Trigger-go-live(Update product order and task as per requirement on proof approval or request change)
    * 				2.	Share proof record with customer if Visible_To_Customer__c is set to true 
    * @param        Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //Trigger-go-live Functionality
        NXX2_Proof_Trigger_Helper_Utility.AfterUpdate((Map<Id,SocialCampaign__c>)newItems, (Map<Id,SocialCampaign__c>)oldItems);
        
        //Share proof with customer functionality
        List<Id> proofIdsToShareWithCustomer = new List<Id>();
        for(SocialCampaign__c proof : ((Map<Id,SocialCampaign__c>)newItems).values()) {
            if(proof.Visible_To_Customer__c){
                proofIdsToShareWithCustomer.add(proof.Id);
            }
        }
        List<SocialCampaign__c> proofs = [SELECT Visible_To_Customer__c,Product_Order__r.Order__r.Opportunity__c 
                                          FROM SocialCampaign__c WHERE Id IN :proofIdsToShareWithCustomer];
        //This class is extending NXX2_TriggerHandler_Utility and 
        //proofToOpportunityMap has been defined in NXX2_TriggerHandler_Utility
        //This map will contain opportunities related to the proof record.
        Map<Id,Id> proofToOpportunityMap = new Map<Id,Id>();
        for(SocialCampaign__c proof : proofs){
            proofToOpportunityMap.put(proof.Id, proof.Product_Order__r.Order__r.Opportunity__c);
        }
        proofSharingOnInsertion(proofToOpportunityMap);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will do the data setup to initialize sharing.
    * 				All required variables in NXX2_TriggerHandler_Utility
    * 				to share proof will be populate by calling related methods in this method.
    * @param        Map<Id,Id> proofToOpportunityMap
    * @return       void
    */
    private void proofSharingOnInsertion(Map<Id,Id> proofToOpportunityMap){
        try{
            //Get all related primary and agency account for the opportunities related to proof records.
            populateAccountsToPrimaryAccountsMap(new Set<Id>(proofToOpportunityMap.values()),null);
            //Get all contact role for the related primary and agency account fetched earlier.
            populateContactRoleDataForTheAccounts(accountsToPrimaryAccountsMap.keySet());
            //Get customer role access record for the roles related to fetched contact roles.
            populateCustomerRoleAccessMap();
            //Get existing customer portal user for the related contacts in contact roles.
            populateContactUserMap();
            //Share the proof record with the fetched portal users.
            initializeSharing(proofToOpportunityMap.keySet());
            if(proofShareList.size() > 0){
            	insert proofShareList;
            }
        }catch(Exception e){
            system.debug('Class NXX2_ShareRecordUtility, Method recalculateAccountSharing');
            system.debug('Exception: '+ e.getStackTraceString());
        }
    }
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share proof records with relavent portal users 
    * 				based on configuration provided in customer role access records.
    * @param        Set<Id> proofIds
    * @return       void
    */
    private void initializeSharing(Set<Id> proofIds){
        proofShareList = new List<SocialCampaign__Share>();
        for(Id accountId : accountContactRoleMap.keySet()){
            List<Contact_Role__c> contactRoles = accountContactRoleMap.get(accountId);
            for(Contact_Role__c contactRole : contactRoles){
                Customer_Role_Access__c customerRoleAccess = customerRoleAccessMap.get(contactRole.Role__c);
                if(customerRoleAccess.Account_Access__c != 'None' && customerRoleAccess.Proof_Access__c != 'None'){
                    populateProofShareList(contactRole.Contact__c,proofIds,customerRoleAccess);
                }
            }
        }
    }
}