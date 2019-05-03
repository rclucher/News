@isTest
private class CS_OrchestrationProcessTriggerDelTest {
    @isTest static void test_insertDay() {
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

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );

        Test.startTest();

        insert process;

        Test.stopTest();
    }

    @isTest static void test_insertHour() {
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

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );

        Test.startTest();

        insert process;

        Test.stopTest();
    }

    @isTest static void test_insertMinute() {
		
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

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );

        Test.startTest();

        insert process;

        Test.stopTest();
    }

    @isTest static void test_update_withOrder() {
        Account acc = TestDataSetupClass.createAccount();
		Contact con = TestDataSetupClass.createContact(acc);
		opportunity opp = TestDataSetupClass.createOpportunity(acc,con);
        Order__c order = TestDataSetupClass.createOrder(opp);
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

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id,
			name = 'Setup',
			
			Order__c = order.Id
			
        );

        Test.startTest();

        insert process;
		

		CSPOFA__Orchestration_Step__c orcStep = new CSPOFA__Orchestration_Step__c();
		orcStep.Name = 'Waiting For Cancellation Date';
		orcStep.CSPOFA__Status__c = 'Complete';
		orcStep.CSPOFA__Milestone__c = true;
		orcStep.CSPOFA__Orchestration_Process__c = process.Id;
		insert orcStep;

		process.CSPOFA__Status__c = 'Complete';
        update process;

        Test.stopTest();
    }

	@isTest static void test_update_withProductOrder() {
        Account acc = TestDataSetupClass.createAccount();
		Contact con = TestDataSetupClass.createContact(acc);
		opportunity opp = TestDataSetupClass.createOpportunity(acc,con);
        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

		Creative__c crOrd = new Creative__c(
			Name = 'Test Creative',
			Product_Order__c = pOrd.Id
		);
		insert crOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
			//name = 'Setup'
			
			//Order__c = order.Id
			
        );

        Test.startTest();

        insert process;
		

		CSPOFA__Orchestration_Step__c orcStep = new CSPOFA__Orchestration_Step__c();
		orcStep.Name = 'Waiting For Cancellation Date';
		orcStep.CSPOFA__Status__c = 'Complete';
		orcStep.CSPOFA__Milestone__c = true;
		orcStep.CSPOFA__Orchestration_Process__c = process.Id;
		insert orcStep;

		process.Order__c = null;
		process.CSPOFA__Status__c = 'Complete';
        update process;

		process.Order__c = null;
		process.Product_Order__c =null;
		process.CSPOFA__Status__c = 'Complete';
        update process;

        Test.stopTest();
    }

	@isTest static void test_update_withCreative() {
        Account acc = TestDataSetupClass.createAccount();
		Contact con = TestDataSetupClass.createContact(acc);
		opportunity opp = TestDataSetupClass.createOpportunity(acc,con);
        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

		Creative__c crOrd = new Creative__c(
			Name = 'Test Creative',
			Product_Order__c = pOrd.Id
		);
		insert crOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup',
            CSPOFA__OLA_Unit__c = 'minute',
            CSPOFA__OLA_Time__c = 1
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
			//name = 'Setup'
			
			//Order__c = order.Id
			
        );

        Test.startTest();

        insert process;
		

		CSPOFA__Orchestration_Step__c orcStep = new CSPOFA__Orchestration_Step__c();
		orcStep.Name = 'Waiting For Cancellation Date';
		orcStep.CSPOFA__Status__c = 'Complete';
		orcStep.CSPOFA__Milestone__c = true;
		orcStep.CSPOFA__Orchestration_Process__c = process.Id;
		insert orcStep;

		process.Order__c = null;
		process.Product_Order__c =null;
		process.CSPOFA__Status__c = 'Complete';
        update process;

        Test.stopTest();
    }
	
	
}