/*------------------------------------------------------------  
Author:        Paras Prajapati
Company:       Salesforce.com
Description:   This class will update User and call start sharing records. 
Test Class:    ...
History
<Date>      <Authors Name>     <Brief Description of Change>
01/Nov/2018  Paras Prajapati
------------------------------------------------------------*/
public class NXX2_ProcessMyAccountUser implements Queueable {
	private List<User> users;
	private Set<Id> newsXtend_My_Account_AccessGivenContacts;
	private  Map<Id, Contact> newItems;
	public NXX2_ProcessMyAccountUser(List<User> users,Set<Id> newsXtend_My_Account_AccessGivenContacts,Map<Id,Contact> newItems) {
		this.users = users;
		this.newsXtend_My_Account_AccessGivenContacts = newsXtend_My_Account_AccessGivenContacts;
		this.newItems = newItems;
	}
	public void execute(QueueableContext context) {
                /**
        * If user has given access to contact then NXX2_ProcessMyAccountUser Queueable class will be called to activate the user, and this class will call another Queable class
        * to start sharing of records to the user linked to contact.
        * We are calling Queueable class as this Trigger will be invoked by updating 'NewsXtend_My_Account_Access__c' field in Contact, which is a non set up field, and we need to update User
        * which is a Set UP record, this can be done using futur or Queueable, as post updating user, we need to start sharing of records which is again a Non Set Up operation, so we are again 
        * call one Queable class from NXX2_ProcessMyAccountUser 
        */
        if(Users.size()>0){ 
            for(User user : Users){
                user.IsActive = true;
            } 
            System.debug('NXX2_ProcessMyAccountUser' + Users);
            update Users;
        }
        NXX2_ShareRecordUtility nXX2_ShareRecordUtility =  new NXX2_ShareRecordUtility(newsXtend_My_Account_AccessGivenContacts,newItems);
        if(!Test.isRunningTest()){
            System.enqueueJob(nXX2_ShareRecordUtility); 
        }
	}
}