/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_InboundEmailTriggerTest
* @description  This is a test class for NXX2_InboundEmailTrigger.
*/
@isTest(seeAllData=true)
public class NXX2_InboundEmailTriggerTest {
        /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will test the handleInboundEmail method of NXX2_InboundEmailTrigger class for negative and positive scenario.
    * @param        NA
    * @return       void
    */
    static testMethod void testInboundEmailTrigger() {
        List<NXX2_InboundEmailConfig__mdt> inboundMailConfig = [SELECT QualifiedApiName,EmailBodyTextForApproval__c,EmailBodyTextForRequestChange__c, TaskSubject__c, TaskRecordType__c FROM NXX2_InboundEmailConfig__mdt];
        Map<String,NXX2_InboundEmailConfig__mdt> mailValidationConfig = new Map<String,NXX2_InboundEmailConfig__mdt>();
        for(NXX2_InboundEmailConfig__mdt config : inboundMailConfig){
            mailValidationConfig.put(config.QualifiedApiName, config);
        }
        Integer recordsToValidate = 4;
        User user = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
        System.runAs(user){
            Test.startTest();
            Messaging.InboundEmail email;
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            List<Product_Order__c> orders = NXX2_TestUtility.createProductOrder(recordsToValidate);
            List<Creative__c> creatives = NXX2_TestUtility.createCreative(orders);
            Product_Order__c productOrder;
            Task task;
            NXX2_InboundEmailTrigger emailTrigger = new NXX2_InboundEmailTrigger();
            List<Task> tasks = new List<Task>();
            List<Messaging.InboundEmail> emails = new List<Messaging.InboundEmail>();
            for(Integer i = 0; i < recordsToValidate; i++){
                email = new Messaging.InboundEmail();
            	email.fromAddress = 'kamal.sharma@crmit.com';
                productOrder = orders[i];
                if(Math.mod(i, 2) == 0){
                    task = NXX2_TestUtility.createTasks(mailValidationConfig.get('Inbound_Mail_Config_For_Social_PO').TaskSubject__c,mailValidationConfig.get('Inbound_Mail_Config_For_Social_PO').TaskRecordType__c,productOrder.Id);
                }else{
                    task = NXX2_TestUtility.createTasks(mailValidationConfig.get('Inbound_Mail_Config_For_Display_PO').TaskSubject__c,mailValidationConfig.get('Inbound_Mail_Config_For_Display_PO').TaskRecordType__c,creatives[i].Id);
                }
                tasks.add(task);
                emails.add(email);
            }
            insert tasks;
            List<Id> productIds = new List<Id>();
            List<Id> creativeIds = new List<Id>();
            for(Integer i = 0; i < recordsToValidate; i++){
                productIds.add(orders[i].Id);
                creativeIds.add(creatives[i].Id);
            }
            orders = [SELECT Name,(SELECT status FROM Tasks) FROM Product_Order__c WHERE Id IN :productIds];
            for(Integer i = 0; i < recordsToValidate; i++){
                emails[i].subject = orders[i].Name;
            }
        	Test.stopTest();
            
            //Validation for fulfillment type = social
            emails[0].plainTextBody = mailValidationConfig.get('Inbound_Mail_Config_For_Social_PO').EmailBodyTextForApproval__c;
            emailTrigger.handleInboundEmail(emails[0],env);
            emails[2].plainTextBody = mailValidationConfig.get('Inbound_Mail_Config_For_Social_PO').EmailBodyTextForRequestChange__c;
            emailTrigger.handleInboundEmail(emails[2],env);
            orders = [SELECT Approved_By_Client__c,(SELECT status FROM Tasks) FROM Product_Order__c WHERE Id IN :productIds];
            System.assertEquals(orders[0].tasks[0].status,'Completed');
            System.assertEquals(orders[0].Approved_By_Client__c,'Yes');
            System.assertEquals(orders[2].tasks[0].status,'Completed');
            System.assertEquals(orders[2].Approved_By_Client__c,'No');
            
            //Validation for fulfillment type = display
            emails[1].plainTextBody = mailValidationConfig.get('Inbound_Mail_Config_For_Display_PO').EmailBodyTextForApproval__c;
            emailTrigger.handleInboundEmail(emails[1],env);
            emails[3].plainTextBody = mailValidationConfig.get('Inbound_Mail_Config_For_Display_PO').EmailBodyTextForRequestChange__c;
            emailTrigger.handleInboundEmail(emails[3],env);
            creatives = [SELECT Client_Approved__c,(SELECT status FROM Tasks) FROM Creative__c WHERE Id IN :creativeIds];
            System.assertEquals(creatives[1].tasks[0].status,'Completed');
            System.assertEquals(creatives[1].Client_Approved__c,'Yes');
            System.assertEquals(creatives[3].tasks[0].status,'Completed');
            System.assertEquals(creatives[3].Client_Approved__c,'No');
        }
    }
}