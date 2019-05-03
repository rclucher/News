@isTest
private class RessignWorkloadCtrlTest {
	
	@isTest
	static void test_RecordWrapTask() {
		Test.startTest();

		RessignWorkloadCtrl.RecordWrap rw =
			new RessignWorkloadCtrl.RecordWrap(new Task(), 'Task');

		System.assertNotEquals(null, rw);
		System.assertNotEquals(null, rw.taskrecord);

		Test.stopTest();
	}
	
	@isTest
	static void test_RecordWrapOrder() {
		Test.startTest();

		RessignWorkloadCtrl.RecordWrap rw =
			new RessignWorkloadCtrl.RecordWrap(new Order__c(), 'Order__c');

		System.assertNotEquals(null, rw);
		System.assertNotEquals(null, rw.orderrecord);

		Test.stopTest();
	}

	@isTest
	static void test_RecordWrapProductOrder() {
		Test.startTest();

		RessignWorkloadCtrl.RecordWrap rw =
			new RessignWorkloadCtrl.RecordWrap(new Product_Order__c(), 'Product_Order__c');

		System.assertNotEquals(null, rw);
		System.assertNotEquals(null, rw.productrecord);

		Test.stopTest();
	}

	@isTest
	static void test_getMainUsers() {
		Test.startTest();

		List<User> users = RessignWorkloadCtrl.getMainUsers();

		System.assertNotEquals(null, users);

		Test.stopTest();
	}

	@isTest
	static void test_getItems() {
		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();

		System.assertNotEquals(null, ctrl.getItems());
		System.assertEquals(4, ctrl.getItems().size());

		Test.stopTest();
	}
	
	@isTest
	static void test_callback() {
		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();

		ctrl.testcallback();
		System.assertEquals(null, ctrl.userLabel);
		System.assertEquals(null, ctrl.mainusername);
		System.assertEquals(null, ctrl.dateFrom);
		System.assertEquals(null, ctrl.dateTo);

		Test.stopTest();
	}

	@isTest
	static void test_showRecords() {
		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();

		System.assertEquals(null, ctrl.showRecords());

		Test.stopTest();
	}

	@isTest
	static void test_setRecords_Order() {
		Order__c ord = TestDataSetupClass.createOrder(new Opportunity());
		ord.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert ord;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';
		ctrl.mainUser = UserInfo.getUserId();

		ctrl.setRecords();

		System.assertEquals(1, ctrl.recordWraps.size());

		Test.stopTest();
	}

	@isTest
	static void test_setRecords_ProductOrder() {
		Order__c ord = TestDataSetupClass.createOrder(new Opportunity());
		insert ord;

		Product_Order__c pOrd = new Product_Order__c(
			Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
			Order__c = ord.Id
		);
		insert pOrd;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Product_Order__c';
		ctrl.mainUser = UserInfo.getUserId();

		ctrl.setRecords();

		System.assertEquals(1, ctrl.recordWraps.size());

		Test.stopTest();
	}

	@isTest
	static void test_setRecords_Task() {
		Order__c ord = TestDataSetupClass.createOrder(new Opportunity());
		ord.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert ord;
						
		Task tsk = new Task(WhatId = ord.Id);
		insert tsk;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Task';
		ctrl.mainUser = UserInfo.getUserId();

		ctrl.setRecords();

		System.assertEquals(1, ctrl.recordWraps.size());

		Test.stopTest();
	}

	@isTest
	static void test_reassignRecords_noMainUser() {
		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';

		System.assertEquals(null, ctrl.reassignRecords());
		System.assertEquals(true, ctrl.showWarning);

		Test.stopTest();
	}

	@isTest
	static void test_reassignRecords_SameUser() {
		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';
		ctrl.mainUser = UserInfo.getUserId();
		ctrl.replacementUser = UserInfo.getUserId();

		System.assertEquals(null, ctrl.reassignRecords());
		System.assertEquals(true, ctrl.showWarning);

		Test.stopTest();
	}

	@isTest
	static void test_reassignRecords_noRecords() {
		User usr = TestDataFactory.createUsers(1, 'System Administrator', null, false, false).get(0);
		insert usr;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';
		ctrl.mainUser = UserInfo.getUserId();
		ctrl.replacementUser = usr.Id;

		System.assertEquals(null, ctrl.reassignRecords());
		System.assertEquals(true, ctrl.showWarning);

		Test.stopTest();
	}


	@isTest
	static void test_reassignRecords_NoRecordsSelected() {
		Order__c ord = TestDataSetupClass.createOrder(new Opportunity());
		ord.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert ord;

		User usr = TestDataFactory.createUsers(1, 'System Administrator', null, false, false).get(0);
		insert usr;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';
		ctrl.mainUser = UserInfo.getUserId();
		ctrl.replacementUser = usr.Id;

		ctrl.setRecords();
		System.assertEquals(null, ctrl.reassignRecords());

		Test.stopTest();
	}

	@isTest
	static void test_reassignRecords_Order() {
		Order__c ord = TestDataSetupClass.createOrder(new Opportunity());
		ord.Assigned_Campaign_Manager__c = UserInfo.getUserId();
		insert ord;

		User usr = TestDataFactory.createUsers(1, 'System Administrator', null, false, false).get(0);
		insert usr;

		Test.startTest();

		RessignWorkloadCtrl ctrl = new RessignWorkloadCtrl();
		ctrl.objectLabel = 'Order__c';
		ctrl.mainUser = UserInfo.getUserId();
		ctrl.replacementUser = usr.Id;

		ctrl.setRecords();
		ctrl.recordWraps.get(0).checked = true;
		System.assertEquals(null, ctrl.reassignRecords());

		Test.stopTest();
	}
}