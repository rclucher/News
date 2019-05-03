/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_SendEmailForCustomerActivity
* @description  This class exposes a method for process builder which will be called to send email to the customer.
*/
public class NXX2_SendEmailForCustomerActivity {
    private static boolean sendAdHocMail = false;
    private static List<Id> contacts = new List<Id>();
    private static List<Id> accounts = new List<Id>();
    private static List<Customer_Task__c> elligibleActivities = new List<Customer_Task__c>();
    /**
* @author       Kamal Sharma
* @date         2018-05-23
* @description  This method will be invoked by process builder to send email to the customer.
* @param        List<Customer_Task__c> activities
* @return       void
*/
    @InvocableMethod(label='Send Email To Customer' description='This method will send email to all customer users related to the account.')
    public static void sendEmailToCustomer(List<Customer_Task__c> activities) {
        if(activities != null){
            sendAdHocMail = false;
            List<Id> activityIds = new List<Id>();
            for(Customer_Task__c activity : activities){
                activityIds.add(activity.Id);
            }
            activities = ProcessRequest(activityIds);
            for(Customer_Task__c activity : activities){
                if(elligibleActivities.contains(activity)){
                    activity.Number_of_email_sent__c = activity.Number_of_email_sent__c + 1;
                    activity.Last_Email_Send_Date__c = Datetime.now();
                }
                activity.Eligible_to_send_email__c = false;
            }
            update activities;
        }
    }
    
    public static void sendAdHocEmailToCustomer(List<Customer_Task__c> activities) {
        if(activities != null){
            sendAdHocMail = true;
            List<Id> activityIds = new List<Id>();
            for(Customer_Task__c activity : activities){
                activityIds.add(activity.Id);
            }
            List<Customer_Task__c> processedActivities = ProcessRequest(activityIds);
            sendAdHocMail = false;
        }
    }
    
    public static List<Customer_Task__c> ProcessRequest(List<Id> activityIds) {
        //Fetch related records data for customer activity
        List<Customer_Task__c> activities = [SELECT Social_Campaign__c,Due_Date__c,Type__c,Number_of_email_sent__c,
                                             Campaign_Order__c,Product_Order__c,Last_Email_Send_Date__c,
                                             Campaign_Order__r.Opportunity__c,
                                             Product_Order__r.Order__r.Opportunity__c,
                                             Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c,
                                             Campaign_Order__r.Campaign_Customer_Contact__c,
                                             Product_Order__r.Order__r.Campaign_Customer_Contact__c,
                                             Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c,
                                             Campaign_Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail,
                                             Product_Order__r.Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail,
                                             Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail,
                                             Campaign_Order__r.Opportunity__r.Payer_Account__c,
                                             Product_Order__r.Order__r.Opportunity__r.Payer_Account__c,
                                             Social_Campaign__r.Product_Order__r.Order__r.Opportunity__r.Payer_Account__c,
                                             Campaign_Order__r.Opportunity__r.AccountId,
                                             Product_Order__r.Order__r.Opportunity__r.AccountId,
                                             Social_Campaign__r.Product_Order__r.Order__r.Opportunity__r.AccountId,
                                             Social_Campaign__r.recordType.Name,
                                             Social_Campaign__r.Account__r.NewsXtend_Auto_Approval_Enabled__c,
                                             Social_Campaign__r.Proof_Name__c,
                                             Product_Order__r.Name,
                                             Campaign_Order__r.Name,
                                             Eligible_to_send_email__c
                                             FROM Customer_Task__c WHERE Id IN :activityIds];
        //Populate primary and payer accounts related to the customer activities
        //Populate primary contact to send emails
        elligibleActivities = new List<Customer_Task__c>();
        List<NXX2_Email_Config_For_Customer_Activity__mdt> emailCountConfigs = [SELECT Activity_Type__c,Frequency_In__c,
                                                                                Frequency__c,
                                                                                Total_Number_Of_Emails__c
                                                                                FROM NXX2_Email_Config_For_Customer_Activity__mdt];
        NXX2_Email_Config_For_Customer_Activity__mdt relatedConfigRecord;
        for(Customer_Task__c activity : activities){
            relatedConfigRecord = null;
            if(sendAdHocMail){
                populateAccountAndContact(activity);
                elligibleActivities.add(activity);
            }else{
                for(NXX2_Email_Config_For_Customer_Activity__mdt config : emailCountConfigs){
                    if(config.Activity_Type__c != null && config.Activity_Type__c.contains(activity.Type__c)){
                        relatedConfigRecord = config;
                        break;
                    }
                }
                if(relatedConfigRecord != null){
                    if(activity.Last_Email_Send_Date__c == null){
                        populateAccountAndContact(activity);
                        elligibleActivities.add(activity);
                    }else if(activity.Number_of_email_sent__c < relatedConfigRecord.Total_Number_Of_Emails__c){
                        if((relatedConfigRecord.Frequency_In__c == 'Hours' 
                            && activity.Last_Email_Send_Date__c.addHours(relatedConfigRecord.Frequency__c.intValue()) < Datetime.now()) 
                           || (relatedConfigRecord.Frequency_In__c == 'Days' 
                            && activity.Last_Email_Send_Date__c.addDays(relatedConfigRecord.Frequency__c.intValue()) < Datetime.now())){
                                populateAccountAndContact(activity);
                                elligibleActivities.add(activity);
                            }
                    }
                }
            }
        }
        List<Contact_Role__c> contactRoles = [SELECT Contact__c,Contact__r.HasOptedOutOfEmail FROM Contact_Role__c 
                                              WHERE Account__c IN :accounts 
                                              AND Contact__r.NewsXtend_My_Account_Access__c = true 
                                              AND HasOptedInOfEmail__c = true];
        //Populate all other contacts to send email
        for(Contact_Role__c role : contactRoles){
            if(!role.Contact__r.HasOptedOutOfEmail){
                contacts.add(role.Contact__c);
            }
        }
        if(contacts.size() > 0){
            List<User> users = [SELECT Name,Email  FROM User 
                                WHERE ContactId IN:contacts 
                                AND userType Like 'customer%' 
                                AND IsActive = true];
            NXX2_Email_Configuration_Detail__mdt emailConfiguration = [SELECT Community_Name__c,
                                                                       Asset_File_Name_For_Logo__c,
                                                                       No_Reply_Email_Display_Name__c,
                                                                       Customer_Activity_Portal_Page_Base_Url__c,
                                                                       Proof_Portal_Page_Base_Url__c
                                                                       FROM NXX2_Email_Configuration_Detail__mdt 
                                                                       WHERE DeveloperName = 'Send_Email_Config'];
            Network myNetwork = [SELECT Id FROM Network WHERE Name = :emailConfiguration.Community_Name__c];
            ConnectApi.Community  myCommunity;
            if(Test.isRunningTest()){
                myCommunity = new ConnectApi.Community();
                myCommunity.siteUrl = 'Test';
            }else{
                myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            }
            OrgWideEmailAddress fromEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress 
                                             WHERE DIsplayName = :emailConfiguration.No_Reply_Email_Display_Name__c];
            List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();
            List<EmailTemplate> allTemplates = [SELECT Id, Subject, HtmlValue, Body, DeveloperName 
                                                FROM EmailTemplate 
                                                WHERE DeveloperName LIKE 'NXX2_%Customer_Activity%'];
            Map<String,EmailTemplate> templateNameToTemplateMap = new Map<String,EmailTemplate>();
            for(EmailTemplate template : allTemplates){
                templateNameToTemplateMap.put(template.DeveloperName, template);
            }
            EmailTemplate emailTemplate;
            String customeTaskLink;
            String proofLink;
            for(Customer_Task__c activity : elligibleActivities){
                customeTaskLink = myCommunity.siteUrl + emailConfiguration.Customer_Activity_Portal_Page_Base_Url__c 
                    + activity.Id;
                proofLink = myCommunity.siteUrl + emailConfiguration.Proof_Portal_Page_Base_Url__c 
                    + activity.Social_Campaign__c;
                if(activity.Social_Campaign__c == null){// Activity on CO or PO
                    if(activity.Number_of_email_sent__c < 1){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_New_Customer_Activity_For_CO_and_PO');
                    }else if(activity.Number_of_email_sent__c < 3){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Co_and_PO');
                    }else{
                        emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Co_and_PO');
                    }
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace('#PARENT_NAME#',activity.Campaign_Order__c == null ? activity.Product_Order__r.Name : activity.Campaign_Order__r.Name);
                }else if(!activity.Type__c.contains('Approve and Review')){// Activity which do not require approval
                    if(activity.Number_of_email_sent__c < 1){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_New_Customer_Activity_For_Proof_Non_Auto');
                    }else if(activity.Number_of_email_sent__c < 3){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Proof_Other');
                    }else{
                        emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Proof_Other');
                    }
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace('#PARENT_NAME#',activity.Social_Campaign__r.Proof_Name__c);
                }else if(activity.Social_Campaign__r.Account__r.NewsXtend_Auto_Approval_Enabled__c){// Activity which will be auto approved
                    if(activity.Number_of_email_sent__c < 1){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_New_Customer_Activity_For_Proof_Auto');
                    }else if(activity.Number_of_email_sent__c < 3){
                        if(activity.Social_Campaign__r.recordType.Name == 'Social'){
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Proof_Social_Auto');
                        }else{
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Proof_Display_Auto');
                        }
                    }else{
                        if(activity.Social_Campaign__r.recordType.Name == 'Social'){
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Proof_Social_Auto');
                        }else{
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Proof_Display_Auto');
                        }
                    }
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace('#PARENT_NAME#',activity.Social_Campaign__r.Proof_Name__c);
                }else{// Activity not allowed for auto approval
                    if(activity.Number_of_email_sent__c < 1){
                        emailTemplate = templateNameToTemplateMap.get('NXX2_New_Customer_Activity_For_Proof_Non_Auto');
                    }else if(activity.Number_of_email_sent__c < 3){
                        if(activity.Social_Campaign__r.recordType.Name == 'Social'){
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Proof_Social');
                        }else{
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Reminder_For_Proof_Display');
                        }
                    }else{
                        if(activity.Social_Campaign__r.recordType.Name == 'Social'){
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Proof_Social');
                        }else{
                            emailTemplate = templateNameToTemplateMap.get('NXX2_Customer_Activity_Final_Reminder_For_Proof_Display');
                        }
                    }
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace('#PARENT_NAME#',activity.Social_Campaign__r.Proof_Name__c);
                }
                for(User user : users){
                    emailTemplate.Subject = emailTemplate.Subject.replace('#TYPE#',activity.Type__c);
                    String HTML_Email_Body = emailTemplate.HtmlValue.replace('{!Receiving_User.Name}',user.Name);
                    HTML_Email_Body = HTML_Email_Body.replace('#TYPE#',activity.Type__c);
                    HTML_Email_Body = HTML_Email_Body.replace('COMMUNITY_URL',myCommunity.siteUrl);
                    HTML_Email_Body = HTML_Email_Body.replace('ORG_ID',UserInfo.getOrganizationId());
                    HTML_Email_Body = HTML_Email_Body.replace('LOGO_NAME',emailConfiguration.Asset_File_Name_For_Logo__c);
                    HTML_Email_Body = HTML_Email_Body.replace('VIEW_CUSTOMER_TASK_LINK',customeTaskLink);
                    HTML_Email_Body = HTML_Email_Body.replace('VIEW_PROOF_LINK',proofLink);
                    HTML_Email_Body = HTML_Email_Body.replace('{!Customer_Task__c.Due_Date__c}',NXX2_AppUtility.formatDateForEmail(activity.Due_Date__c));
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new String[] { user.Email });
                    mail.setOrgWideEmailAddressId(fromEmail.Id); 
                    mail.setSubject(emailTemplate.Subject);
                    mail.setHtmlBody(HTML_Email_Body);
                    listSingleEmailMessages.add(mail);
                }
            }
            if(!Test.isRunningTest()){
                Messaging.sendEmail(listSingleEmailMessages);
            }
        }
        return activities;
    }
    
    public static void populateAccountAndContact(Customer_Task__c activity){
        if(activity.Campaign_Order__r.Opportunity__c != null){
            if(activity.Campaign_Order__r.Opportunity__r.Payer_Account__c != null){
                accounts.add(activity.Campaign_Order__r.Opportunity__r.Payer_Account__c);
            }
            accounts.add(activity.Campaign_Order__r.Opportunity__r.AccountId);
            if(activity.Campaign_Order__r.Campaign_Customer_Contact__c != null && !activity.Campaign_Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail){
                contacts.add(activity.Campaign_Order__r.Campaign_Customer_Contact__c);
            }
        }else if(activity.Product_Order__r.Order__r.Opportunity__c != null){
            if(activity.Product_Order__r.Order__r.Opportunity__r.Payer_Account__c != null){
                accounts.add(activity.Product_Order__r.Order__r.Opportunity__r.Payer_Account__c);
            }
            accounts.add(activity.Product_Order__r.Order__r.Opportunity__r.AccountId);
            if(activity.Product_Order__r.Order__r.Campaign_Customer_Contact__c != null && !activity.Product_Order__r.Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail){
                contacts.add(activity.Product_Order__r.Order__r.Campaign_Customer_Contact__c);
            }
        }else if(activity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__c != null){
            if(activity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__r.Payer_Account__c != null){
                accounts.add(activity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__r.Payer_Account__c);
            }
            accounts.add(activity.Social_Campaign__r.Product_Order__r.Order__r.Opportunity__r.AccountId);
            if(activity.Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c != null && !activity.Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__r.HasOptedOutOfEmail){
                contacts.add(activity.Social_Campaign__r.Product_Order__r.Order__r.Campaign_Customer_Contact__c);
            }
        }
    }
}