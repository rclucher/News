@isTest
private class SendEmailWithCCTest {
    @isTest
    static void test_process_order() {
        EmailTemplate eTemplate;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            eTemplate = new EmailTemplate(
                isActive = true,
                Name = 'TestTemplate',
                DeveloperName = 'unique_TestTemplate',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId()
            );
            insert eTemplate;
        }

        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Customer_Contact__c = con.Id;
        order.Sales_Representative__c = UserInfo.getUserId();
        insert order;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'testTemplate'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Order__c = order.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            Use_Email_Template_Name__c = eTemplate.Name,
            To_Recepients__c = 'Customer;Campaign Manager',
            CC_Recepients__c = 'Sales Representative',
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        SendEmailWithCC sendEmail = new SendEmailWithCC();
        List<sObject> result = sendEmail.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }
/*
    @isTest
    static void test_process_orderNoCustomer() {
        EmailTemplate eTemplate;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            eTemplate = new EmailTemplate(
                isActive = true,
                Name = 'TestTemplate',
                DeveloperName = 'unique_TestTemplate',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId()
            );
            insert eTemplate;
        }

        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Customer_Contact__c = con.Id;
        order.Sales_Representative__c = UserInfo.getUserId();
        insert order;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'testTemplate'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Order__c = order.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            Use_Email_Template_Name__c = eTemplate.Name,
            To_Recepients__c = 'Campaign Manager',
            CC_Recepients__c = 'Sales Representative',
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        SendEmailWithCC sendEmail = new SendEmailWithCC();
        List<sObject> result = sendEmail.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }
*/
    @isTest
    static void test_process_productOrder() {
        EmailTemplate eTemplate;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            eTemplate = new EmailTemplate(
                isActive = true,
                Name = 'TestTemplate',
                DeveloperName = 'unique_TestTemplate',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId()
            );
            insert eTemplate;
        }

        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Customer_Contact__c = con.Id;
        order.Sales_Representative__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'testTemplate'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            Use_Email_Template_Name__c = eTemplate.Name,
            To_Recepients__c = 'Customer;Campaign Manager;Fulfillmet Owner;Social Owner',
            CC_Recepients__c = 'Sales Representative',
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        SendEmailWithCC sendEmail = new SendEmailWithCC();
        List<sObject> result = sendEmail.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }
/*
@isTest
    static void test_process_productOrderNoCustomer() {
        EmailTemplate eTemplate;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            eTemplate = new EmailTemplate(
                isActive = true,
                Name = 'TestTemplate',
                DeveloperName = 'unique_TestTemplate',
                TemplateType = 'text',
                FolderId = UserInfo.getUserId()
            );
            insert eTemplate;
        }

        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Customer_Contact__c = con.Id;
        order.Sales_Representative__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'testTemplate'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            Use_Email_Template_Name__c = eTemplate.Name,
            To_Recepients__c = 'Campaign Manager;Fulfillmet Owner;Social Owner',
            CC_Recepients__c = 'Sales Representative',
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        SendEmailWithCC sendEmail = new SendEmailWithCC();
        List<sObject> result = sendEmail.process(new List<SObject>{step});

        Test.stopTest();

        System.assertEquals('Complete', result.get(0).get('CSPOFA__Status__c'));
    }  */ 
}