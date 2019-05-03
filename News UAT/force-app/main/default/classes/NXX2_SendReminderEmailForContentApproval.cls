/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className    NXX2_SendReminderEmailForContentApproval
* @description  This class exposes a method for process builder 
*               which will be called to send reminder email to the customer for creative approval.
*/
public class NXX2_SendReminderEmailForContentApproval {
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will be invoked by process builder to send reminder email 
    *               to the customer for creative approval.
    * @param        List<Customer_Task__c> activities
    * @return       void
    */
    @InvocableMethod(label='Send Reminder Email To Content Approval' description='This method will send reminder email to the customer to approve creative')
    public static void sendEmailToCustomer(List<SocialCampaign__c> proofs) {
        if(proofs != null){
            List<Id> contacts = new List<Id>();
            SocialCampaign__c proof = [SELECT Proof_Name__c,RecordType.Name,Due_Date_For_Auto_Approval__c,
                                       Product_Order__r.Order__r.Campaign_Customer_Contact__r.Name,
                                       Product_Order__r.Order__r.Campaign_Customer_Contact__r.Email,
                                       (SELECT Type__c FROM Customer_Tasks__r WHERE Status__c = 'With Client' ORDER BY CreatedDate desc)
                                       FROM SocialCampaign__c WHERE Id = :proofs[0].Id];
            if(proof != null){
                Customer_Task__c relatedTask;
                for(Customer_Task__c task : proof.Customer_Tasks__r){
                    if(proof.RecordType.Name == 'Social' && task.Type__c == 'Approve and Review Your Facebook Ads'){
                        relatedTask = task;
                        break;
                    }
                    if(proof.RecordType.Name == 'Display' && task.Type__c == 'Approve and Review Your Display Ads'){
                        relatedTask = task;
                        break;
                    }
                }
                NXX2_Email_Configuration_Detail__mdt emailConfiguration = [SELECT Community_Name__c,
                                                                           Asset_File_Name_For_Logo__c,
                                                                           No_Reply_Email_Display_Name__c,
                                                                           Customer_Activity_Portal_Page_Base_Url__c,
                                                                           Proof_Portal_Page_Base_Url__c
                                                                           FROM NXX2_Email_Configuration_Detail__mdt 
                                                                           WHERE DeveloperName = 'Send_Email_Config'];
                EmailTemplate emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
                                               FROM EmailTemplate 
                                               WHERE DeveloperName = 'NXX2_Reminder_to_approve_proof_content'];
                Network myNetwork = [SELECT Id FROM Network WHERE Name = :emailConfiguration.Community_Name__c];
                ConnectApi.Community  myCommunity;
                if(Test.isRunningTest()){
                    myCommunity = new ConnectApi.Community();
                    myCommunity.siteUrl = 'Test';
                }else{
                    myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
                }
                String customeTaskLink = myCommunity.siteUrl + emailConfiguration.Customer_Activity_Portal_Page_Base_Url__c + (relatedTask != null ? String.valueOf(relatedTask.Id) : '');
                String proofLink = myCommunity.siteUrl + emailConfiguration.Proof_Portal_Page_Base_Url__c + proof.Id;
                OrgWideEmailAddress fromEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DIsplayName = :emailConfiguration.No_Reply_Email_Display_Name__c];
                List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();
                String HTML_Email_Body = emailTemplate.HtmlValue.replace('{!Receiving_User.Name}',proof.Product_Order__r.Order__r.Campaign_Customer_Contact__r.Name);
                HTML_Email_Body = HTML_Email_Body.replace('COMMUNITY_URL',myCommunity.siteUrl);
                HTML_Email_Body = HTML_Email_Body.replace('ORG_ID',UserInfo.getOrganizationId());
                HTML_Email_Body = HTML_Email_Body.replace('LOGO_NAME',emailConfiguration.Asset_File_Name_For_Logo__c);
                HTML_Email_Body = HTML_Email_Body.replace('VIEW_CUSTOMER_TASK_LINK',customeTaskLink);
                HTML_Email_Body = HTML_Email_Body.replace('{!SocialCampaign__c.Name}',proof.Proof_Name__c);
                HTML_Email_Body = HTML_Email_Body.replace('VIEW_PROOF_LINK',proofLink);
                HTML_Email_Body = HTML_Email_Body.replace('{!SocialCampaign__c.Due_Date_For_Auto_Approval__c}',NXX2_AppUtility.formatDateForEmail(proof.Due_Date_For_Auto_Approval__c));
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[] { proof.Product_Order__r.Order__r.Campaign_Customer_Contact__r.Email });
                mail.setOrgWideEmailAddressId(fromEmail.Id);
                mail.setSubject(emailTemplate.Subject);
                mail.setHtmlBody(HTML_Email_Body);
                listSingleEmailMessages.add(mail);
                if(!Test.isRunningTest()){
                    Messaging.sendEmail(listSingleEmailMessages);
                }
            }
        }
    }
}