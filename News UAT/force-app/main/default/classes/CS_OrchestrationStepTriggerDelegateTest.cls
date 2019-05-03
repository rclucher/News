@isTest
private class CS_OrchestrationStepTriggerDelegateTest {
    
    @isTest static void test_updateDay() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'day',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'day',
            CSPOFA__OLA_Time__c = 1
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'In Progress';
        update step;

        Test.stopTest();
    }

    @isTest static void test_updateHour() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'hour',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'hour',
            CSPOFA__OLA_Time__c = 1
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'In Progress';
        update step;

        Test.stopTest();
    }

    @isTest static void test_updateMinute() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1,
            CSPOFA__Milestone__c = true
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'In Progress';
        update step;

        Test.stopTest();
    }

    @isTest static void test_updateProductOrderComplete() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Cancelled'
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1,
            CSPOFA__Milestone__c = true
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            Name = 'setup'
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
            CSPOFA__Milestone__c = true
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'Complete';
        update step;

        Test.stopTest();
    }

    @isTest static void test_updateOrderComplete() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1,
            CSPOFA__Milestone__c = true
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Order__c = order.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            Name = 'setup'
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
            CSPOFA__Milestone__c = true
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'Complete';
        update step;

        Test.stopTest();
    }

    @isTest static void test_updateCreative() {
        Creative__c creative = new Creative__c();
        insert creative;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Step_Template__c stepTemplate = new CSPOFA__Orchestration_Step_Template__c(
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1,
            CSPOFA__Milestone__c = true
        );
        insert stepTemplate;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Creative__c = creative.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id,
            Name = 'setup'
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            CSPOFA__Orchestration_Process__c = process.Id,
            CSPOFA__Orchestration_Step_Template__c = stepTemplate.Id,
            CSPOFA__Milestone__c = true
        );

        Test.startTest();

        insert step;

        step.CSPOFA__Status__c = 'Complete';
        update step;

        Test.stopTest();
    }
}