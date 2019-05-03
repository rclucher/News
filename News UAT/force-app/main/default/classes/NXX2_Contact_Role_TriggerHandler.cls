/**
* @author       Paras Prajapati
* @date         2018-11-01
* @className	NXX2_Contact_Role_TriggerHandler
* @description  This is the handler class for contact role trigger.
*/
public without sharing class NXX2_Contact_Role_TriggerHandler implements NXX2_TriggerHandler{
    /**
     * Allows unit tests (or other code) to disable this trigger for the transaction
     */
    public static Boolean TriggerDisabled = false;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  Checks to see if the trigger has been disabled either by custom setting or by running code
    * @param        NA
    * @return       Boolean
    */
    public Boolean IsDisabled(){
        NXX2_TriggerSettings__c triggerSettings = NXX2_TriggerSettings__c.getInstance();
        if (triggerSettings.CustomerActivityTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
     /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will do two task on contact role record insertion:
    * 				1.	Check that the email id of the contact related to contact role is not in use by any other contact.
    * 				2.	Check that the combination of account and contact should not be used in any existing contact role. 
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void BeforeInsert(List<SObject> newItems){
        List<Id> contactIds = new List<Id>();
        List<Id> accounts = new List<Id>();
        List<String> emails = new List<String>();
        for(Contact_Role__c role : (List<Contact_Role__c>)newItems){
            contactIds.add(role.Contact__c);
            accounts.add(role.Account__c);
        }
        if(contactIds.size() != 0){
            List<Contact> contacts = [SELECT Email FROM Contact WHERE Id IN : contactIds];
            for(Contact con : contacts){
                emails.add(con.Email);
            }
            //Get existing contact roles which have contact with the same emailId used for the new contact role's contact. 
            List<Contact_Role__c> existingContactRolesForEmails = [SELECT Contact__r.Name FROM Contact_Role__c 
                                                                   WHERE Contact__r.Email IN :emails 
                                                                   AND Contact__r.NewsXtend_My_Account_Access__c = true 
                                                                   AND Contact__c NOT IN :contactIds];
            if(existingContactRolesForEmails.size() > 0){
                newItems[0].addError('This email is already in use for contact: '+existingContactRolesForEmails[0].Contact__r.Name);
            }else{
                List<Contact_Role__c> existingContactRoles = [SELECT Contact__c,Account__c FROM Contact_Role__c 
                                                              WHERE Contact__c IN : contactIds AND Account__c IN :accounts];
                Map<Id,Set<Id>> contactAccountMap = new Map<Id,Set<Id>>();
                for(Contact_Role__c role : existingContactRoles){
                    if(!contactAccountMap.containsKey(role.Contact__c)){
                        contactAccountMap.put(role.Contact__c,new Set<Id>());
                    }
                    contactAccountMap.get(role.Contact__c).add(role.Account__c);
                }
                for(Contact_Role__c role : (List<Contact_Role__c>)newItems){
                    if(contactAccountMap.containsKey(role.Contact__c) && contactAccountMap.get(role.Contact__c).contains(role.Account__c)){
                        role.addError('A record already exist for the same contact and account!');
                    }
                }
            }
        }
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
     /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will share records with portal user based on contact role. 
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void AfterInsert(Map<Id, SObject> newItems) {
        //This line of code will handle Sharing of records on the contact role records insertion.
        new NXX2_ShareRecordUtility().handleContactRoleAfterInsert(newItems); 
    }
     /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will update sharing of records with the portal user as per changes in contact role.
    * @param        Map<Id, SObject> oldItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //This line of code will handle Sharing of records on the contact role records updation.
        new NXX2_ShareRecordUtility().HandleContactRoleAfterUpdate(newItems, oldItems); 
    }
     /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will remove records shared with the portal user on contact role deletion.
    * @param        Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterDelete(Map<Id, SObject> oldItems) {
        //This line of code will handle Sharing of records on the contact role deletion.
        new NXX2_ShareRecordUtility().HandleContactRoleAfterDelete(oldItems);  
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}