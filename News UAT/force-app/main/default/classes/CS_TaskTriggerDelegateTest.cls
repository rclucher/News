@isTest
private class CS_TaskTriggerDelegateTest {
	
	@isTest static void test_insertProductOrder() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Cancelled'
        );
        insert pOrd;

        QA_Checklist__c checklist = new QA_Checklist__c(Product_Order__c = pOrd.Id);
        insert checklist;

		Id QATaskRecordTypeId =  Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('QA Check').getRecordTypeId();

		Task t = new Task(RecordTypeId = QATaskRecordTypeId,
							WhatId = pOrd.Id,
							Description = 'Process:Social');

		Test.startTest();

		insert t;

		Test.stopTest();
	}

	@isTest static void test_insertOrder() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        QA_Checklist__c checklist = new QA_Checklist__c(Campaign_Order__c = order.Id);
        insert checklist;

		Id QATaskRecordTypeId =  Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('QA Check').getRecordTypeId();
		Task t = new Task(RecordTypeId = QATaskRecordTypeId,
							WhatId = order.Id,
							Description = 'Process:');

		Test.startTest();

		insert t;

		Test.stopTest();
	}
	
	@isTest static void test_insertProductOrder_ClientRevision() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Cancelled'
        );
        insert pOrd;

		 Id QATaskRecordTypeId =  Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('QA Check').getRecordTypeId();
		Task t = new Task(RecordTypeId = QATaskRecordTypeId,
							WhatId = pOrd.Id,
							Description = 'Process:Client Revision');

		Test.startTest();

		insert t;

		Test.stopTest();
		
		QA_Checklist__c qaCheckList = [select Name, Type__c, (select Id from QA_Items__r) from QA_Checklist__c where Product_Order__c = :pOrd.id];
		
		system.assertEquals('Client Revision', qaCheckList.Type__c);
		system.assertEquals(6, qaCheckList.QA_Items__r.size());
	}

	@isTest static void test_insertProductOrderWithValidation() {
		Order__c order = TestDataSetupClass.createOrder(new Opportunity());
		order.Assigned_Campaign_Manager__c = UserInfo.getUserId(); //mandatory field for testing
		insert order;

		Product_Order__c pOrd = new Product_Order__c(
				Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
				Order__c = order.Id,
				Status__c = 'Cancelled',
				QA_Check_Passed__c ='Yes' //mand field for testing
		);
		insert pOrd;

		Creative__c creative = new Creative__c(Name = 'Test Creative',
				Product_Order__c = pOrd.Id,
				Creative_Source__c = 'Premedia',
				Client_Approved__c = 'Yes',
				Creative_URL__c = 'www.dummywebsite.com/mycreative',
				CM_QA_check__c = 'Yes',
				Creative_URL_Draft__c  = 'www.dummywebsite.com/mycreativedraft'
		);

		Creative__c creative2 = new Creative__c(Name = 'Test Creative2',
				Product_Order__c = pOrd.Id,
				Creative_Source__c = 'Premedia',
				CM_QA_check__c = 'Yes',
				Creative_URL_Draft__c  = 'www.dummywebsite.com/mycreativedraft'
		);
		List<Creative__c> creatives = new List<Creative__c>{creative,creative2};

		insert creatives;

		QA_Checklist__c checklist = new QA_Checklist__c(Product_Order__c = pOrd.Id);
		insert checklist;


		Id QATaskRecordTypeId =  Task.getSObjectType().getDescribe().getRecordTypeInfosByName().get('To-Do').getRecordTypeId();



		CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
				Name = 'Campaign Setup',
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1
		);
		insert template;



		CSPOFA__Orchestration_Step_Template__c stepTemplateMandFields = new CSPOFA__Orchestration_Step_Template__c(
				CSPOFA__Orchestration_Process_Template__c = template.Id,
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1,
				Mandatory_Input_Fields__c = 'Client_Approved__c,Creative_URL__c'
		);


		/* orchestrator step templates */
		CSPOFA__Orchestration_Step_Template__c stepTemplateValidate = new CSPOFA__Orchestration_Step_Template__c(
				CSPOFA__Orchestration_Process_Template__c = template.Id,
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1,
				ValidationFunction__c = 'ClientApprovedValidation'
		);

		CSPOFA__Orchestration_Step_Template__c stepTemplateValidate2 = new CSPOFA__Orchestration_Step_Template__c(
				CSPOFA__Orchestration_Process_Template__c = template.Id,
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1,
				ValidationFunction__c = 'CreativeSourceValidation'
		);

		CSPOFA__Orchestration_Step_Template__c stepTemplateMandFieldsforPO = new CSPOFA__Orchestration_Step_Template__c(
				CSPOFA__Orchestration_Process_Template__c = template.Id,
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1,
				Mandatory_Input_Fields__c = 'QA_Check_Passed__c'
		);

		CSPOFA__Orchestration_Step_Template__c stepTemplateMandFieldsforCO = new CSPOFA__Orchestration_Step_Template__c(
				CSPOFA__Orchestration_Process_Template__c = template.Id,
				CSPOFA__OLA_Unit__c = 'day',
				CSPOFA__OLA_Time__c = 1,
				Mandatory_Input_Fields__c = 'Assigned_Campaign_Manager__c'
		);


		List<CSPOFA__Orchestration_Step_Template__c> stepTemplates = new List<CSPOFA__Orchestration_Step_Template__c>{
				stepTemplateMandFields,
				stepTemplateValidate,
				stepTemplateValidate2,
				stepTemplateMandFieldsforPO,
				stepTemplateMandFieldsforCO
		};

		insert stepTemplates;



		CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
				Product_Order__c = pOrd.Id,
				CSPOFA__Orchestration_Process_Template__c = template.Id
		);
		insert process;



		CSPOFA__Orchestration_Step__c manFieldsStep = new CSPOFA__Orchestration_Step__c(
				CSPOFA__Orchestration_Process__c = process.Id,
				CSPOFA__Orchestration_Step_Template__c = stepTemplates[0].Id
		);


		CSPOFA__Orchestration_Step__c validationStep = new CSPOFA__Orchestration_Step__c(
				CSPOFA__Orchestration_Process__c = process.Id,
				CSPOFA__Orchestration_Step_Template__c = stepTemplates[1].Id
		);

		CSPOFA__Orchestration_Step__c validationStep2 = new CSPOFA__Orchestration_Step__c(
				CSPOFA__Orchestration_Process__c = process.Id,
				CSPOFA__Orchestration_Step_Template__c = stepTemplates[2].Id
		);

		CSPOFA__Orchestration_Step__c validationStepPO = new CSPOFA__Orchestration_Step__c(
				CSPOFA__Orchestration_Process__c = process.Id,
				CSPOFA__Orchestration_Step_Template__c = stepTemplates[3].Id
		);

		CSPOFA__Orchestration_Step__c validationStepCO = new CSPOFA__Orchestration_Step__c(
				CSPOFA__Orchestration_Process__c = process.Id,
				CSPOFA__Orchestration_Step_Template__c = stepTemplates[4].Id
		);



		List<CSPOFA__Orchestration_Step__c> orchsteps = new List<CSPOFA__Orchestration_Step__c>{
				manFieldsStep,
				validationStep,
				validationStep2,
				validationStepPO,
				validationStepCO
		};

		insert orchsteps;


		/* creating tasks */
		Task t1 = new Task(RecordTypeId = QATaskRecordTypeId,
				WhatId = creatives[0].Id,
				Description = 'Process:Social',
				CSPOFA__Orchestration_Step__c = orchsteps[0].Id
		);

		Task t2 = new Task(RecordTypeId = QATaskRecordTypeId,
				WhatId = creatives[0].Id,
				Description = 'Process:Social',
				CSPOFA__Orchestration_Step__c = orchsteps[1].Id
		);

		Task t3 = new Task(RecordTypeId = QATaskRecordTypeId,
				WhatId = creatives[0].Id,
				Description = 'Process:Social',
				CSPOFA__Orchestration_Step__c = orchsteps[2].Id
		);

		Task t4 = new Task(RecordTypeId = QATaskRecordTypeId,
				WhatId = pOrd.Id,
				Description = 'Process:Social',
				CSPOFA__Orchestration_Step__c = orchsteps[3].Id
		);

		Task t5 = new Task(RecordTypeId = QATaskRecordTypeId,
				WhatId = order.Id,
				Description = 'Process:Social',
				CSPOFA__Orchestration_Step__c = orchsteps[4].Id
		);



		List<Task> testTasks = new List<Task>{t1,t2,t3,t4,t5 };


		Test.startTest();

		insert testTasks;

		for (Task t: testTasks) {
			t.Status = 'Completed';
			update t;
			// even though this is not best practice (i.e. DML within a for loop) the TaskTrigger needs refactoring to support bulk update
			// since updating mulitple type Tasks will invoke methods which will fail for different type tasks... i.e. mandatory fields will be expected on a validation task
		}

		//update testTasks;

		Test.stopTest();
	}
}