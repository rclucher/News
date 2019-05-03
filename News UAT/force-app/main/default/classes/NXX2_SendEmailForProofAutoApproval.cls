/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className    NXX2_SendEmailForProofAutoApproval
* @description  This class exposes a method for process builder 
*               which will be called to send reminder email to the customer for creative approval.
*/
public class NXX2_SendEmailForProofAutoApproval {
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will be invoked by process builder to send reminder email 
    *               to the customer for creative approval.
    * @param        List<Customer_Task__c> activities
    * @return       void
    */
    @InvocableMethod(label='Send Email for auto approval' description='This method will send email to the customer when a proof is approved automatically')
    public static void sendEmailToCustomer(List<SocialCampaign__c> proofs) {
        if(proofs != null){
            List<Id> contacts = new List<Id>();
            SocialCampaign__c proof = [SELECT Proof_Name__c,RecordType.Name,
                                       Product_Order__r.Order__r.Campaign_Customer_Contact__r.Name,
                                       Product_Order__r.Order__r.Campaign_Customer_Contact__r.Email
                                       FROM SocialCampaign__c WHERE Id = :proofs[0].Id];
            if(proof != null){
                NXX2_Email_Configuration_Detail__mdt emailConfiguration = [SELECT Community_Name__c,
                                                                           Asset_File_Name_For_Logo__c,
                                                                           No_Reply_Email_Display_Name__c,
                                                                           Proof_Portal_Page_Base_Url__c
                                                                           FROM NXX2_Email_Configuration_Detail__mdt 
                                                                           WHERE DeveloperName = 'Send_Email_Config'];
                EmailTemplate emailTemplate;
                if(proof.RecordType.Name == 'Social'){
                    emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
                                     FROM EmailTemplate 
                                     WHERE DeveloperName = 'NXX2_Notification_For_Social_Content_Auto_Approval'];
                }else{
                    emailTemplate = [SELECT Id, Subject, HtmlValue, Body 
                                     FROM EmailTemplate 
                                     WHERE DeveloperName = 'NXX2_Notification_For_Display_Content_Auto_Approval'];
                }
                Network myNetwork = [SELECT Id FROM Network WHERE Name = :emailConfiguration.Community_Name__c];
                ConnectApi.Community  myCommunity;
                if(Test.isRunningTest()){
                    myCommunity = new ConnectApi.Community();
                    myCommunity.siteUrl = 'Test';
                }else{
                    myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
                }
                String proofLink = myCommunity.siteUrl + emailConfiguration.Proof_Portal_Page_Base_Url__c + proof.Id;
                OrgWideEmailAddress fromEmail = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DIsplayName = :emailConfiguration.No_Reply_Email_Display_Name__c];
                List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();
                String HTML_Email_Body = emailTemplate.HtmlValue.replace('{!Receiving_User.Name}',proof.Product_Order__r.Order__r.Campaign_Customer_Contact__r.Name);
                HTML_Email_Body = HTML_Email_Body.replace('COMMUNITY_URL',myCommunity.siteUrl);
                HTML_Email_Body = HTML_Email_Body.replace('ORG_ID',UserInfo.getOrganizationId());
                HTML_Email_Body = HTML_Email_Body.replace('LOGO_NAME',emailConfiguration.Asset_File_Name_For_Logo__c);
                HTML_Email_Body = HTML_Email_Body.replace('{!SocialCampaign__c.Name}',proof.Proof_Name__c);
                HTML_Email_Body = HTML_Email_Body.replace('VIEW_PROOF_LINK',proofLink);
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