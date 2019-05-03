@isTest
private class HomePageController_Test {
    public static Id TempUserId = UserInfo.getUserId();
    public static Task tempTask;
    public static String selectedOrderWrapIden;
    public static Order__c order;
    
    @isTest static void test_getOrders() {
        setdata();
        Test.startTest();
        HomePageController home = new HomePageController();

        List<HomePageController.ObjectWithPendingOrchStatus> tlist = home.getOrders();

        System.assertEquals(tlist.size(), 1);

        Test.stopTest();
    }

    @isTest static void test_getTaskList() {
        setdata();
        Test.startTest();
        HomePageController home = new HomePageController();
        home.stateView = 'NSW';
        home.taskView = 'Due Today';
        List<task> tlist = home.getTaskList();
        System.assertNotEquals(tlist, null);
        home.taskView = 'New today';
        tlist = home.getTaskList();
        home.taskView = 'In Progress Tasks';
        tlist = home.getTaskList();
        home.taskView = 'Due in 7 days';
        tlist = home.getTaskList();
        home.taskView = 'All';
        tlist = home.getTaskList();
        home.taskView = '';
        tlist = home.getTaskList();
        home.selectedTask = tempTask;
        pagereference pr = home.loadSelectedTaskDetails();
        home.selectedOrderWrapIden = order.Id;
        home.selectedTaskId  = tempTask.Id;
        pr = home.changeTask();

        pr = home.setInProgress();
        //pr = home.loadSelectedOrderDetails();

        string testTemp = home.getTaskView();
        home.setTaskView('');
        testTemp = home.getStateView();
        home.setStateView('');

        Test.stopTest();
    }

    @isTest static void test_getItems() {

        Test.startTest();
        HomePageController home = new HomePageController();

        List<SelectOption> tlist = home.getItems();
        System.assertNotEquals(tlist, null);
        tlist = home.getStates();
        System.assertNotEquals(tlist, null);
        tlist = home.getAssignOptions();

        System.assertNotEquals(tlist, null);

        Test.stopTest();
    }

	@isTest static void test_TaskWithAdditionalDetails_order() {
	    setdata();
		Test.startTest();
	    task t = [select id, whatid from task  limit 1];
		if(t!=null){
        HomePageController.TaskWithAdditionalDetails ht = new HomePageController.TaskWithAdditionalDetails(t.id, t.whatid);
		}
		Test.stopTest();
	}
	@isTest static void test_TaskWithAdditionalDetails_Prod_order() {
	    setdata();
		Test.startTest();
		Product_Order__c po = [select id from Product_Order__c LIMIT 1]; 
	    task t = [select id, whatid from task WHERE whatid =:po.id];
		if(t!=null){
        HomePageController.TaskWithAdditionalDetails ht = new HomePageController.TaskWithAdditionalDetails(t.id, t.whatid);
		}
		Test.stopTest();
	}
	@isTest static void test_TaskWithAdditionalDetails_Creative() {
	    setdata();
		Test.startTest();
		Creative__c cr = [select id from Creative__c LIMIT 1]; 
	    task t = [select id, whatid from task WHERE whatid =:cr.id];
		if(t!=null){
        HomePageController.TaskWithAdditionalDetails ht = new HomePageController.TaskWithAdditionalDetails(t.id, t.whatid);
		}
		Test.stopTest();
	}

    @isTest static void test_getProdOrders() {
        setdata();
        Test.startTest();
        HomePageController home = new HomePageController();

        List<HomePageController.ObjectWithPendingOrchStatus> tlist = home.getProdOrders();
        System.assertEquals(tlist.size(), 1);

        Test.stopTest();
    }

	

    public static void setdata () {
    
        order = new Order__c();
        order.Status__c = 'In Progress';
        order.Assigned_Campaign_Manager__c = TempUserId;
        insert order;

        Product_Order__c prodorder = new Product_Order__c();
        prodorder.Status__c = 'In Progress';
        prodorder.Assigned_Fulfilment_Owner__c = TempUserId;
        prodorder.Order__c = order.id;
        insert prodorder;

		Creative__c cr = new Creative__c();
		cr.Client_Approved__c='Yes';
		cr.CM_QA_check__c='Yes';
		cr.Creative_Source__c='Customer';
		cr.Creative_URL__c='www.google.com';
		cr.Creative_URL_Draft__c='www.google.com';
		cr.Name='Test Name';
		cr.Product_Order__c = prodorder.id;
		insert cr;

		List<Task> taskList = new List<Task>();

        tempTask = new task (subject= 'test subject', state__c = 'nsw', ActivityDate = date.today(), status = 'In Progress', 
            Priority = 'High', whatid = order.id);
			taskList.add(tempTask);
        Task t1 = new task (subject= 'test subject 1', ActivityDate = date.today()-1, status = 'In Progress', 
            Priority = 'High', whatid = order.id);
			taskList.add(t1);
        
		
		Task t2 = new task (subject= 'test subject 1', ActivityDate = date.today()-1, status = 'In Progress', 
            Priority = 'High', whatid = prodorder.id);
        taskList.add(t2);

		Task t3 = new task (subject= 'test subject 1', ActivityDate = date.today()-1, status = 'In Progress', 
            Priority = 'High', whatid = cr.id);
        taskList.add(t3);
        insert taskList;

			
        cspofa__orchestration_process_template__c newcampaignprocessTemplate = new cspofa__orchestration_process_template__c();
        newcampaignprocessTemplate.Name = 'Campaign Setup';
        insert newcampaignprocessTemplate;

        CSPOFA__Orchestration_Process__c orchProcess = new CSPOFA__Orchestration_Process__c (name ='test', CSPOFA__jeopardy_created_flag__c =true, Order__c = order.id, CSPOFA__Orchestration_Process_Template__c = newcampaignprocessTemplate.Id);
        insert orchProcess;

        CSPOFA__Orchestration_Step__c orchStep = new CSPOFA__Orchestration_Step__c (
            CSPOFA__Type__c = 'Monitor Field', CSPOFA__Jeopardy_Created_Flag__c = true, CSPOFA__Field_Name__c = 'order__r.Status__c',
            CSPOFA__Orchestration_Process__c = orchProcess.Id, name = 'name', CSPOFA__Status__c = 'In Progress');
        insert orchStep;
        CSPOFA__Orchestration_Step__c orchStep2 = new CSPOFA__Orchestration_Step__c (
            CSPOFA__Type__c = 'Monitor Field', CSPOFA__Field_Name__c = 'order__r.opportunity__r.StageName',
            CSPOFA__Orchestration_Process__c = orchProcess.Id, name = 'name', CSPOFA__Status__c = 'In Progress');
        insert orchStep2;

        CSPOFA__Orchestration_Process__c orchProcessProd = new CSPOFA__Orchestration_Process__c (name ='test', CSPOFA__jeopardy_created_flag__c =true, Product_Order__c = prodorder.id, CSPOFA__Orchestration_Process_Template__c = newcampaignprocessTemplate.Id);
        insert orchProcessProd;

        CSPOFA__Orchestration_Step__c orchStepProd = new CSPOFA__Orchestration_Step__c (
            CSPOFA__Type__c = 'Create Task', CSPOFA__Jeopardy_Created_Flag__c = true, CSPOFA__Status__c = 'Waiting For Feedback',
            CSPOFA__Orchestration_Process__c = orchProcessProd.Id, name = 'name');
        insert orchStepProd;


        CSPOFA__Orchestration_Step__c orchStepProd2 = new CSPOFA__Orchestration_Step__c (
            CSPOFA__Type__c = 'Monitor Field', CSPOFA__Field_Name__c = 'Product_Order__r.Status__c', CSPOFA__Jeopardy_Created_Flag__c = true, CSPOFA__Status__c = 'Waiting For Feedback',
            CSPOFA__Orchestration_Process__c = orchProcessProd.Id, name = 'name');
        insert orchStepProd2;


    }
    
}