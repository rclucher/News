/**
* @author      	Paras Prajapati
* @date         2018-10-26
* @className	NXX2_Contact_TriggerHandler
* @description  This is the handler class for account trigger.
*/
public without sharing class NXX2_Contact_TriggerHandler implements NXX2_TriggerHandler{
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
        if (triggerSettings.ContactTriggerDisabled__c)
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
    * @description  This method will check if there is any change in NewsXtend_My_Account_Access__c field of contact.
    * 				1.	If this is set to true then all share records(Account,Proof and Customer Activity)
    * 					for the portal user related to this contact will be created.
    * 				2.	If this is set to false then all share records(Account,Proof and Customer Activity)
    * 					for the portal user related to this contact will be deleted.
    * @param        Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //This contains the contact whose NewsXtend_My_Account_Access__c is set to true
		Set<Id> newsXtend_My_Account_AccessGivenContacts = new Set<Id>();
        //This contains the contact whose NewsXtend_My_Account_Access__c is set to false
		Set<Id> newsXtend_My_Account_AccessRemoveContacts = new Set<Id>();
        Map<Id, Contact> contactmap=new Map<Id, Contact>();
		Map<Id,Contact> mapOfOldContact = ((Map<Id,Contact>) oldItems);
        Map<String,Id> emailToContactMap = new Map<String,Id>();
        /**
         * The below block of code will execute if NewsXtend_My_Account_Access__c is updated
         * Block Start
         */
		for(Contact contact : ((Map<Id,Contact>)newItems).values()){
			if(contact.NewsXtend_My_Account_Access__c != mapOfOldContact.get(contact.Id).NewsXtend_My_Account_Access__c){
				if(contact.NewsXtend_My_Account_Access__c){
                    emailToContactMap.put(contact.Email, contact.Id);
					newsXtend_My_Account_AccessGivenContacts.add(contact.Id);
                    contactmap.put(contact.Id,contact);
				}else{
					newsXtend_My_Account_AccessRemoveContacts.add(contact.Id);
				}
            }
		}
        if(emailToContactMap.size() > 0){
            List<Contact_Role__c> roles = [SELECT Contact__r.Name FROM Contact_Role__c WHERE Contact__r.Email IN : emailToContactMap.keySet() AND Contact__r.NewsXtend_My_Account_Access__c = true 
                                           AND Contact__c NOT IN : emailToContactMap.values()];
            if(roles.size() > 0){
                newItems.values()[0].addError('Mentioned contact is already active with the same email Id: '+ roles[0].Contact__r.Name);
            }
        }
		if(newsXtend_My_Account_AccessGivenContacts!=null && newsXtend_My_Account_AccessGivenContacts.size()>0){
            List<User> userList = [Select Id,IsActive from User where ContactId IN:newsXtend_My_Account_AccessGivenContacts AND IsActive=false];
            /**
            * If user has given access to contact then NXX2_ProcessMyAccountUser Queueable class 
            * will be called to activate the user and this class will call another Queable class 
            * to start sharing of records to the user linked to contact.
            * We are calling Queueable class as this Trigger will be invoked by updating 
            * 'NewsXtend_My_Account_Access__c' field in Contact, which is a non set up field 
            * and we need to update User which is a Set UP record. This can be done using futur or Queueable.
            * As post updating user, we need to start sharing of records which is again a Non Set Up operation, 
            * so we are again calling one Queable class from NXX2_ProcessMyAccountUser.
            */
            NXX2_ProcessMyAccountUser activateUser = new NXX2_ProcessMyAccountUser(userList,newsXtend_My_Account_AccessGivenContacts,contactmap);   
            System.enqueueJob(activateUser);
		}
		if(newsXtend_My_Account_AccessRemoveContacts!=null && newsXtend_My_Account_AccessRemoveContacts.size()>0){
		   NXX2_ShareRecordUtility.handleNewsXtendMyAccountDiableAccess(newsXtend_My_Account_AccessRemoveContacts);
		}
        /**
         * Block END
         */
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}