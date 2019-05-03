/**
* @author       Paras Prajapati
* @date         2018-08-17
* @className	NXX2_Batch_Send_Email_Outstanding_Tasks
* @description  This class will be used to send email to contacts if customer activity Status is 'With client'.
*				1. Send an email to campaign Order Contact.
*				2. Send an email to all the user shared with customer activities.
*/
global class NXX2_Batch_Send_Email_Outstanding_Tasks implements Database.Batchable<sObject>,Database.Stateful{
    private ConnectApi.Community  myCommunity;
    private Network myNetwork;
    private NXX2_Email_Configuration_Detail__mdt emailConfiguration;
    private OrgWideEmailAddress fromEmail;
    Map<Id,Id> contactIdToWhoMailAlreadySent;
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  Default constructor
    */
    public NXX2_Batch_Send_Email_Outstanding_Tasks(){
        emailConfiguration = [SELECT Community_Name__c, No_Reply_Email_Display_Name__c,
                              Account_Portal_Page_Base_Url__c 
                              FROM NXX2_Email_Configuration_Detail__mdt 
                              WHERE DeveloperName = 'Send_Email_Config'];
        fromEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress 
                     WHERE DIsplayName = :emailConfiguration.No_Reply_Email_Display_Name__c];
        myNetwork = [SELECT Id FROM Network WHERE Name = :emailConfiguration.Community_Name__c];
        contactIdToWhoMailAlreadySent=new Map<Id,Id>();
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  Start method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       Database.QueryLocator
    */
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Fetch All the contact Roles Recods which are in With Client.
        return Database.getQueryLocator([Select Id,Type__c,Status__c,Account__c,Account__r.Name,
                                         Product_Order__r.Order__r.Campaign_Customer_Contact__c,
                                         Campaign_Order__r.Campaign_Customer_Contact__c,
                                         Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c,
                                         Product_Order__r.Order__r.Campaign_Customer_Contact__r.Email,
                                         Campaign_Order__r.Campaign_Customer_Contact__r.Email,
                                         Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__r.Email
                                         from Customer_Task__c where Status__c ='With Client']);
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  execute method implementation of Batch interface
    * @param        Database.BatchableContext BC, List<sObject> scope
    * @return       void
    */
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Map<Id,Set<Id>> contactIdCustomerTaskMap=new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> sharedUserIdsCustomerTaskIdMap =  new Map<Id,Set<Id>>();
        List<Id> listOfUserIds = new List<Id>();
        List<User> listOfUser = new List<User>();
        Map<Id,List<Id>> contactUserMap = new Map<Id,List<Id>>();
        List<Contact_Role__c> listOfContactRole=new List<Contact_Role__c>();
        Set<Id> listOfContactId = new Set<Id>();
        Map<Id,Customer_Task__c> listOfCustomerTaskMap = new Map<Id,Customer_Task__c>(); 
        if(Test.isRunningTest()){
            myCommunity = new ConnectApi.Community();
            myCommunity.siteUrl = 'Test';
        }else{
            myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
        }
        for(Sobject scopeRecord : scope){
            Customer_Task__c customer_Task = (Customer_Task__c)scopeRecord;
            listOfCustomerTaskMap.put(customer_Task.Id, customer_Task);
        }
        //Fetch all the Shared Records which are shared by Sharing Triggers for My Account, this will help to identify contacts to send emails.
        List<Customer_Task__Share> listOfCustomerTaskShared = [Select Id, UserOrGroupId,ParentId from Customer_Task__Share where RowCause=:Schema.SocialCampaign__Share.RowCause.NewsXtend_My_Account__c AND ParentId IN:listOfCustomerTaskMap.keySet()];
        for(Customer_Task__Share customer_TaskShare:listOfCustomerTaskShared){
            listOfUserIds.add(customer_TaskShare.UserOrGroupId);
            if(!sharedUserIdsCustomerTaskIdMap.containsKey(customer_TaskShare.UserOrGroupId)){
                sharedUserIdsCustomerTaskIdMap.put(customer_TaskShare.UserOrGroupId,new Set<Id>());
            }
            sharedUserIdsCustomerTaskIdMap.get(customer_TaskShare.UserOrGroupId).add(customer_TaskShare.ParentId);
        }
        //Retreive all the contacts linked with shared User,as email will go to those user only.
        if(listOfUserIds.size()>0){
            listOfUser = [Select Id,ContactId from User where Id IN:listOfUserIds AND ContactId!=null];
            for(User user : listOfUser){
                if(!contactUserMap.containsKey(user.ContactId)){
                    contactUserMap.put(user.ContactId, new List<Id>());
                }
                contactUserMap.get(user.ContactId).add(user.Id);
                listOfContactId.add(user.ContactId);
            }
        }
        if(listOfContactId.size()>0){
            //Step 1 - Fetch All the Contacts Role records related to Contacts and having HasOptedOutOfEmail__c is true.
            List<Contact_Role__c> contactRoleList = [Select Id,Account__c,Contact__c,HasOptedInOfEmail__c from Contact_Role__c where HasOptedInOfEmail__c = true AND Contact__c IN:listOfContactId];
            if(contactRoleList.size()>0){
                for(Contact_Role__c contact_Role:contactRoleList){
                    String accountId = contact_Role.Account__c;
                    String contactId = contact_Role.Contact__c;
                    if(contactUserMap.containsKey(contactId)){
                        List<Id> userIdsLinkedToContact = contactUserMap.get(contactId);
                        if(userIdsLinkedToContact.size()>0){
                            for(Id userId : userIdsLinkedToContact){
                                if(sharedUserIdsCustomerTaskIdMap.containsKey(userId)){
                                    Set<Id> customerTaskSet = sharedUserIdsCustomerTaskIdMap.get(userId);
                                    for(Id customerTaskId : customerTaskSet){
                                        if(!contactIdCustomerTaskMap.containsKey(contactId)){
                                            contactIdCustomerTaskMap.put(contactId, new Set<Id>());
                                        }
                                        contactIdCustomerTaskMap.get(contactId).add(customerTaskId);
                                    }
                                }
                            }  
                        }
                    }
                }
            }
        }  
        //Step 2- List all the Contact linked to campaign Order as this contacts are primary contact for campaign order
        for(Id id:listOfCustomerTaskMap.keySet()){
            Customer_Task__c customerTask = listOfCustomerTaskMap.get(id);
            String contactId = null;
            if(customerTask.Product_Order__r.Order__r.Campaign_Customer_Contact__c!=null){
                contactId = customerTask.Product_Order__r.Order__r.Campaign_Customer_Contact__c;
            }else if(customerTask.Campaign_Order__r.Campaign_Customer_Contact__c !=null){
                contactId = customerTask.Campaign_Order__r.Campaign_Customer_Contact__c;
            }else if(customerTask.Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c!=null){
                contactId = customerTask.Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c;
            }
            if(contactId != null){
                if(!contactIdCustomerTaskMap.containsKey(contactId)){
                    contactIdCustomerTaskMap.put(contactId, new Set<Id>());
                }
                contactIdCustomerTaskMap.get(contactId).add(customerTask.Id);
            }
        }
        Map<Id,String> contactIdAndBody = new Map<Id,String>();
        if(contactIdCustomerTaskMap.size()>0){
            // Fetch all the Customer Task Record - 
            List<Customer_Task__c> customerTaskList;
            String body='';
            for(Id contactId : contactIdCustomerTaskMap.keySet()){
                Set<Id> customerTaskIds = contactIdCustomerTaskMap.get(contactId);
                customerTaskList = new List<Customer_Task__c>();
                for(Id customerTaskId : customerTaskIds){
                    customerTaskList.add(listOfCustomerTaskMap.get(customerTaskId));
                }
                if(customerTaskList.size()>0){
                    body = buildmailBody(customerTaskList);
                }
                contactIdAndBody.put(contactId,body);
            }
        }
        if(contactIdAndBody.size()>0){
            List<Contact> listOfContactToUpdateBody = [Select id,NewsXtend_Outstanding_Tasks__c from Contact where id IN:contactIdAndBody.keySet()];
            if(listOfContactToUpdateBody.size()>0){
                for(Contact contact : listOfContactToUpdateBody){
                    contact.NewsXtend_Outstanding_Tasks__c = contactIdAndBody.get(contact.Id);
                }
            }
            update listOfContactToUpdateBody;
        }
        if(contactIdAndBody.size()>0){
            List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();
            for(Id contactId : contactIdAndBody.keySet()){
                //As this is a Batch Application, this variable will hold all the contact ids for which 
                //mail is laready sent and it will validate another batch of record should not send email again 
                //to same contact. 
                if(!contactIdToWhoMailAlreadySent.containsKey(contactId)){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                    mail.setTargetObjectId(contactId); 
                    mail.setOrgWideEmailAddressId(fromEmail.Id);
                    mail.setUseSignature(false); 
                    mail.setBccSender(false); 
                    mail.setSaveAsActivity(false); 
                    EmailTemplate et=[Select id from EmailTemplate where DeveloperName = 'NXX2_Daily_Digest_For_Customer']; 
                    mail.setTemplateId(et.id); 
                    listSingleEmailMessages.add(mail);
                    //Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    contactIdToWhoMailAlreadySent.put(contactId,contactId);
                }
            }
            if(!Test.isRunningTest()){
                Messaging.sendEmail(listSingleEmailMessages);
            }
        }
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  This method will prepare email body for the given customer tasks
    * @param        List<Customer_Task__c> customerTaskList
    * @return       String
    */
    public String buildmailBody(List<Customer_Task__c> customerTaskList){
        String str = '' ;
        for(Customer_Task__c customerTask : customerTaskList){
            string accountLink = myCommunity.siteUrl + emailConfiguration.Account_Portal_Page_Base_Url__c 
                				+ customerTask.Account__c;
            str += '<tr><td style="font-size: .75rem;font-weight: 400;border: 1px solid #dddddd;text-align: left; padding: 8px;letter-spacing: .0625rem;">'+ customerTask.Type__c +'</td>'+'<td style="font-size: .75rem;font-weight: 400;border: 1px solid #dddddd;text-align: left; padding: 8px;letter-spacing: .0625rem;">'+ customerTask.Status__c +'</td>'+'<td style="font-size: .75rem;font-weight: 400;border: 1px solid #dddddd;text-align: left; padding: 8px;letter-spacing: .0625rem;"><a href="'+accountLink+'">'+ customerTask.Account__r.Name +'</a></td>'+'</tr>' ;
        }
        str = str.replace('null' , '') ;
        String finalStr = '' ;
        finalStr = '<table style="line-height:0.5rem;background-color: rgb(255, 255, 255);padding: 0; border-top: 0;border-spacing: 0; border-color: grey;box-sizing: border-box;font-family: arial, sans-serif;border-collapse: collapse;width: 100%;"><tr><th style="font-size: .75rem;color: rgb(81, 79, 77);border: 1px solid #dddddd;text-align: left; padding: 8px;text-transform: uppercase;letter-spacing: .0625rem;background-color: rgb(250, 250, 249)"> Type </th><th style="font-size: .75rem;color: rgb(81, 79, 77);border: 1px solid #dddddd;text-align: left; padding: 8px;text-transform: uppercase;letter-spacing: .0625rem;background-color: rgb(250, 250, 249)"> Status </th> <th style="font-size: .75rem;color: rgb(81, 79, 77);border: 1px solid #dddddd;text-align: left; padding: 8px;text-transform: uppercase;letter-spacing: .0625rem;background-color: rgb(250, 250, 249)"> Account </th></tr>'+ str +'</table>' ;
        return finalStr ;
    }
    
    /**
    * @author       Paras Prajapati
    * @date         2018-08-17
    * @description  finish method implementation of Batch interface
    * @param        Database.BatchableContext BC
    * @return       void
    */
    global void finish(Database.BatchableContext BC){}
}