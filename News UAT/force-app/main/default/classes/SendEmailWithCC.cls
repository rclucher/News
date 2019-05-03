global without sharing class SendEmailWithCC implements CSPOFA.ExecutionHandler {
    private static final String STEP_STATUS_COMPLETE = 'Complete';
    private static final String STEP_STATUS_COMPLETE_MSSG = 'Email Sent.';
    private List<Contact> contacts;


    private List<String> getEmailAdressesFor (List<String> recepients, CSPOFA__Orchestration_Step__c step, Map<string, string> labelSupportEmails) {
        
        List<string> emailAddresses = new List<String>();

        for (string singleEmail : recepients) {
            String eAddress = '';
            if (singleEmail == 'Campaign Manager') {
                if (step.CSPOFA__Orchestration_Process__r.Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Order__r.Assigned_Campaign_Manager__r.Email;
                else
                    eAddress = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Assigned_Campaign_Manager__r.Email;
            }
            else if (singleEmail == 'Fulfillmet Owner') {
                if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__r.Email;
            }
            else if (singleEmail == 'Social Owner'){
                if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__r.Email;
            }
            else if (singleEmail == 'Customer') {
                if (step.CSPOFA__Orchestration_Process__r.Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Order__r.Customer_Contact__r.Email;
                else if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Customer_Contact__r.Email;
            }
            else if (singleEmail == 'Sales Representative') {
                if (step.CSPOFA__Orchestration_Process__r.Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Order__r.Sales_Representative__r.Email;
                else if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null)
                    eAddress = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Sales_Representative__r.Email;
            }
            else if (singleEmail == 'Pre-Media')
                eAddress = labelSupportEmails.get('Pre-Media');
            else if (singleEmail == 'Spotzer')
                eAddress = labelSupportEmails.get('Spotzer');
            else if (singleEmail == 'Avanser')
                eAddress = labelSupportEmails.get('Avanser');

            if (eAddress != '')
                emailAddresses.add(eAddress);
            system.debug(eAddress);
        }

        system.debug(emailAddresses);
        return emailAddresses;
    }

    private void createContacts (List<String> recepients) {
        contacts = new list<contact>();
        for (string e : recepients) {
            Contact c = new Contact (firstname = 'test', lastname = 'test', email = e);
            contacts.add(c);
        }
        insert contacts;
    }

    public List<sObject> process(List<sObject> data) {
        system.debug('tu');
        List<CSPOFA__Orchestration_Step__c> stepList = (List<CSPOFA__Orchestration_Step__c>) data;
        List<Id> stepIds = new List<id>();
        List<String> emailTemplateNames = new List<string>();
        for (CSPOFA__Orchestration_Step__c step : stepList) {
            stepIds.add(step.id);
        }
          
        List<CSPOFA__Orchestration_Step__c> stepsWithAdditionalInformation = [SELECT Id, 
        To_Recepients__c, 
        CC_Recepients__c, 
        Use_Email_Template_Name__c,
        CSPOFA__Orchestration_Process__c, 
        CSPOFA__Orchestration_Process__r.Product_Order__c,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__r.Email,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__c,
        CSPOFA__Orchestration_Process__r.Order__c, 
        CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Social_Owner__r.Email,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Assigned_Campaign_Manager__r.Email,
        CSPOFA__Orchestration_Process__r.Order__r.Assigned_Campaign_Manager__r.Email,
        CSPOFA__Orchestration_Process__r.Order__r.Assigned_Campaign_Manager__c,
        CSPOFA__Orchestration_Process__r.Creative__c, 
        CSPOFA__Orchestration_Process__r.Order__r.Customer_Contact__r.Email,
        CSPOFA__Orchestration_Process__r.Order__r.Customer_Contact__c,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Customer_Contact__c,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Customer_Contact__r.Email,
        CSPOFA__Orchestration_Process__r.Order__r.Sales_Representative__r.Email,
        CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Sales_Representative__r.Email,

        CSPOFA__Orchestration_Process__r.Creative__r.Creative_Owner__r.Email
        FROM CSPOFA__Orchestration_Step__c WHERE Id = :stepIds];

        List<Messaging.SingleEmailMessage> emailList = new List <Messaging.SingleEmailMessage>();
        for (CSPOFA__Orchestration_Step__c step : stepsWithAdditionalInformation) { 
            
            emailTemplateNames.add(step.Use_Email_Template_Name__c);
        }

        system.debug(emailTemplateNames);
        if (!emailTemplateNames.isEmpty()) {
            try {
            List<EmailTemplate> emailTemplates = [select id, name from EmailTemplate where name in: emailTemplateNames];
            Map<string, EmailTemplate> nameEmailTemplate = new Map<string, EmailTemplate>();
            if (!emailTemplates.isEmpty()) {
                for (EmailTemplate et : emailTemplates)
                    nameEmailTemplate.put (et.name, et);
            }
            system.debug(emailTemplates);
            List<System_Support_Email__mdt> supportEmails = [select id, masterlabel, Email_Address__c from System_Support_Email__mdt];
            Map<string, string> labelEmail = new Map<string, string>();
            for (System_Support_Email__mdt systemEmail : supportEmails)
                labelEmail.put(systemEmail.masterlabel, systemEmail.Email_Address__c);

            for (CSPOFA__Orchestration_Step__c step : stepsWithAdditionalInformation) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                List<String> toReceps = getEmailAdressesFor (step.To_Recepients__c.split(';'), step, labelEmail);
                List<String> ccReceps;

                if (step.CC_Recepients__c != null && step.CC_Recepients__c != '')
                    ccReceps =  getEmailAdressesFor (step.CC_Recepients__c.split(';'), step, labelEmail);
                Id targetUserId;
                Id whatId;
                Id emailTemplateId = nameEmailTemplate.get(step.Use_Email_Template_Name__c).Id;
                if (step.CSPOFA__Orchestration_Process__r.Order__c != null) {
                    whatId = step.CSPOFA__Orchestration_Process__r.Order__c;
                    targetUserId = step.CSPOFA__Orchestration_Process__r.Order__r.Assigned_Campaign_Manager__c;
                }
                else if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null){
                    whatId = step.CSPOFA__Orchestration_Process__r.Product_Order__c;
                    targetUserId = step.CSPOFA__Orchestration_Process__r.Product_Order__r.Assigned_Fulfilment_Owner__c;
                }
                Boolean sendToCustomer = false;
                for (string recep : step.To_Recepients__c.split(';')) {
                    if (recep == 'Customer'){
                        sendToCustomer = true;
                        break;
                    }
                }
                
                if (!sendToCustomer) {
                    createContacts (toReceps);
                }
                email.setToAddresses(toReceps);

                if (ccReceps != null)
                email.setCcAddresses(ccReceps);
                if (sendToCustomer) {
                    if (step.CSPOFA__Orchestration_Process__r.Order__c != null) {
                        email.setTargetObjectId(step.CSPOFA__Orchestration_Process__r.Order__r.Customer_Contact__c);
                        email.setWhatId(step.CSPOFA__Orchestration_Process__r.Order__c);
                    }
                    else if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null){
                        email.setWhatId(step.CSPOFA__Orchestration_Process__r.Product_Order__c);
                        email.setTargetObjectId(step.CSPOFA__Orchestration_Process__r.Product_Order__r.Order__r.Customer_Contact__c);
                    }
                }
                else {
                    email.setTargetObjectId(contacts.get(0).id);
                    if (step.CSPOFA__Orchestration_Process__r.Order__c != null) 
                        email.setWhatId(step.CSPOFA__Orchestration_Process__r.Order__c);
                    else if (step.CSPOFA__Orchestration_Process__r.Product_Order__c != null)
                        email.setWhatId(step.CSPOFA__Orchestration_Process__r.Product_Order__c);
                }

                email.setTemplateId(emailTemplateId);
                email.setSaveAsActivity(true);
                emailList.add(email);   
                system.debug(email);
            }
        }
            
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', stepsWithAdditionalInformation, 'Email creation failed.');
            }
                
            try {
                Messaging.sendEmail(emailList);
            }
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', stepsWithAdditionalInformation, 'Email not sent');
            }
            
            if (contacts != null && !contacts.isEmpty())
            delete contacts;
        }

        for(CSPOFA__Orchestration_Step__c singlestep : stepList)
        {
            singlestep.CSPOFA__Status__c = STEP_STATUS_COMPLETE;
            singlestep.CSPOFA__Completed_Date__c = Date.today();
            singlestep.CSPOFA__Message__c = STEP_STATUS_COMPLETE_MSSG;

        }
        
        List<sObject> result = new List<sObject>();
            
        result.addAll((List<sObject>)stepList);
            
        return result;
    }
}