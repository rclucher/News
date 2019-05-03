//
// Home Page component controller
// 
public with sharing class HomePageController 
{
    // theMsg is the getter/setter used for the message ribbon used in the home page 
    public Integer duration {get; set;} 
    public boolean isTrue { get { return true; } set; }
    public boolean isFalse { get { return false; } set; }
    public List<Task> taskListNoDup { get; set; }
    Public String taskView {get;set;}
    Public string stateView {get;set;}
    Public string assignedTo {get;set;}
    public Task selectedTask {get; set;}
    public string errorMessage { get; set; }
    public Boolean error { get; set; }

    public Id selectedTaskId { get; set; }
    public boolean selectedTaskCompleted { get; set; }
    public set<String> groupNames { get; set; }

    public list <ObjectWithPendingOrchStatus> listwrap { get; set; }
    public map <id, ObjectWithPendingOrchStatus> mapwrap { get; set; }
    public ObjectWithPendingOrchStatus selectedOrderWrap { get; set; }
    public Order__c selectedOrder { get; set; }
    public string selectedOrderWrapIden { get; set; }
    public Id userid {get; set; }
    public List<task> userOpenTasks { get; set; }
    public map<id, task> mapUserOpenTasks { get; set; }
    public map<id, task> mapUserAllTasks { get; set; }

    public list <ObjectWithPendingOrchStatus> listprodwrap { get; set; }
    public map <id,ObjectWithPendingOrchStatus> mapprodwrap { get; set; }
    public ObjectWithPendingOrchStatus selectedProdOrderWrap { get; set; }
    public product_order__c selectedProdOrder { get; set; }
    public string selectedProdOrderWrapIden { get; set; }

    public map<id, taskWithAdditionalDetails> maptaskWithDetails { get; set;}

    public map<id, id> taskWithWhatIds { get; set; }

    Map<String, String> objectNameQueryFields = new Map<String, String> {
            'Task'                          => 'id, Subject,Item_Proposed_Start_Date__c,state__c, Priority, What.Name, LastModifiedById, CS_GT__Associated_Group__c, LastModifiedDate, CreatedById, Description, WhatId, WhoID, OwnerId, CreatedDate, ActivityDate, IsClosed, Status ',
            'Order__c'                      => 'id, name, CreatedDate, proposed_start_date__c, overall_status__c, actual_start_date__c, account__c,assigned_campaign_manager__c, Status__c, account__r.name ',
            'Product_Order__c'              => 'id, Product_Node__r.name, name, CreatedDate, Product_Order_Start_Date__c, Status__c, order__r.account__c,Assigned_Fulfilment_Owner__c, Assigned_Social_Owner__c,order__r.account__r.name ',
            'CSPOFA__Orchestration_Step__c' => 'id , CSPOFA__Target_Date_Time__c ,CSPOFA__Orchestration_Process__r.CSPOFA__Target_Date_Time__c , Target_SLA_DateTime__c , Target_SLA_Date__c, CSPOFA__Orchestration_Process__r.Target_SLA_DateTime__c, CSPOFA__Orchestration_Process__r.Target_SLA_Date__c,  CSPOFA__Field_Monitor_Operator__c, CSPOFA__Field_Value__c, CSPOFA__target_date__c,CSPOFA__Orchestration_Process__r.CSPOFA__target_date__c, '+
                                            'CSPOFA__Orchestration_Process__r.name, CSPOFA__Orchestration_Process__r.CSPOFA__jeopardy_created_flag__c, CSPOFA__Jeopardy_Created_Flag__c, '+
                                            'CSPOFA__Task_Subject__c, CSPOFA__Field_Name__c, name, CSPOFA__Type__c, CSPOFA__Orchestration_Process__r.order__c, CSPOFA__Orchestration_Process__r.product_order__c'
        }; 

    public homePageController() 
    {
        init();
    }
 
    void init()
    {
        taskView = 'My Open Tasks';
        selectedTaskCompleted = false;
        getAllGroupNames();
        String userid = UserInfo.getUserId();
        getAllUserOpenTasks();
            error = false;
    }

    // TODO - Add option to show Tasks as central object
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('My Open Tasks','My Open Tasks'));
        options.add(new SelectOption('New Today','New Today'));
        options.add(new SelectOption('Due Today','Due Today'));
        options.add(new SelectOption('Due in 7 days','Due in 7 days'));       
        options.add(new SelectOption('All Overdue','All Overdue'));
        options.add(new SelectOption('In Progress Tasks','In Progress Tasks'));
        options.add(new SelectOption('Completed','Completed'));
        options.add(new SelectOption('All','All'));

        return options;
    }

    public List<SelectOption> getStates() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        options.add(new SelectOption('NSW','NSW'));
        options.add(new SelectOption('VIC','VIC'));
        options.add(new SelectOption('QLD','QLD'));
        options.add(new SelectOption('SA','SA'));       
        options.add(new SelectOption('TAS','TAS'));
        options.add(new SelectOption('WA','WA'));
        options.add(new SelectOption('NT','NT'));

        return options;
    }

    public List<SelectOption> getAssignOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        options.add(new SelectOption('Me','Me'));
        options.add(new SelectOption('My Groups','My Groups'));
        

        return options;
    }

    @TestVisible
    private void getMaps () {

        maptaskWithDetails  = new Map<id, TaskWithAdditionalDetails>();
            
        map<id, Order__c> orders = new map<id, Order__c>([select id, opportunity__r.name, opportunity__c, account__r.name, account__c, Proposed_Start_Date__c from 
            order__c where id IN: taskWithWhatIds.values()]);
        map<id, product_order__c> prodorders = new map<id, product_order__c>([select id, 
            Product_Node__r.name, Order__r.opportunity__r.name, Order__r.opportunity__c, Order__r.Proposed_Start_Date__c,
            Order__r.account__r.name, Order__r.account__c from 
            product_order__c where id IN: taskWithWhatIds.values()]);
        map<id, creative__c> creatives = new map<id, creative__c>([select id, 
            product_order__r.Product_Node__r.name, product_order__r.Order__r.opportunity__r.name, product_order__r.Order__r.Proposed_Start_Date__c,
            product_order__r.Order__r.opportunity__c, 
            product_order__r.Order__r.account__r.name, product_order__r.Order__r.account__c from 
            creative__c where id IN: taskWithWhatIds.values()]);

        for (task singleTask : userOpenTasks) {
            Order__c order = orders.get(singleTask.WhatId);
            product_order__c prodorder = prodorders.get(singleTask.WhatId);
            Creative__c creative = creatives.get(singleTask.WhatId);
            TaskWithAdditionalDetails taskWithDetail = new TaskWithAdditionalDetails (singleTask.id, singleTask.WhatId, order, prodorder, creative);

            maptaskWithDetails.put(singleTask.id, taskWithDetail);
            getTaskList();
        }
    }

    @TestVisible
    private void getAllUserOpenTasks() {
        String uid = UserInfo.getUserId();
        string query = 'select '+ objectNameQueryFields.get('Task') + 
        ' FROM Task where (CS_GT__Associated_Group__c IN: groupNames OR OwnerId = :uid) AND IsClosed = false Order BY ActivityDate ASC';
        userOpenTasks = database.query(query);
        query = 'select '+ objectNameQueryFields.get('Task') + 
        ' FROM Task where (CS_GT__Associated_Group__c IN: groupNames OR OwnerId = :uid) AND IsClosed = true Order BY ActivityDate ASC LIMIT 200';
        List<task> closedTasks = database.query(query);

        userOpenTasks.addAll(closedTasks);
        taskWithWhatIds = new map<id, id>();

        mapUserOpenTasks = new map<id, task> (userOpenTasks);

        for (task temptask : userOpenTasks) {
            taskWithWhatIds.put(temptask.id, temptask.WhatId);
            if (maptaskWithDetails != null && !maptaskWithDetails.keySet().contains(temptask.id)) {
                TaskWithAdditionalDetails taskWithDetail = new TaskWithAdditionalDetails (temptask.id, temptask.WhatId);
                maptaskWithDetails.put(temptask.id, taskWithDetail);
            }
        }

        if (maptaskWithDetails == null && !userOpenTasks.isEmpty())
            getMaps();
    }

    public ObjectWithPendingOrchStatus[] getOrders() {
        String uid = UserInfo.getUserId();
        listwrap = new List<ObjectWithPendingOrchStatus>();
        mapwrap = new map<id, ObjectWithPendingOrchStatus>();

        string query = 'select ' + objectNameQueryFields.get('Order__c') + ' from order__c where assigned_campaign_manager__c =: uid';
        List<Order__c> orders = database.query(query);
        system.debug(orders);
        Map<id, order__c> idOrders = new map<id, order__c>(orders);
        Set<id> ordIds = idOrders.keySet();
        system.debug(ordIds);
        query = 'select ' + objectNameQueryFields.get('CSPOFA__Orchestration_Step__c') + ' from CSPOFA__Orchestration_Step__c'+
            ' where (CSPOFA__Status__c = \'In Progress\' OR CSPOFA__Status__c = \'Waiting For Feedback\') AND CSPOFA__Orchestration_Process__r.order__c IN: ordIds';
        List<CSPOFA__Orchestration_Step__c> openSteps = database.query(query);

        Map<id, list<CSPOFA__Orchestration_Step__c>> openStepsForItem = new map <id, list<CSPOFA__Orchestration_Step__c>>();
        system.debug(openSteps);
        for (CSPOFA__Orchestration_Step__c step : openSteps) {
            list<CSPOFA__Orchestration_Step__c> steps = openStepsForItem.get(step.CSPOFA__Orchestration_Process__r.order__c);
            if (steps == null)
                steps = new list<CSPOFA__Orchestration_Step__c>();
            steps.add(step);
            system.debug(steps);
            openStepsForItem.put(step.CSPOFA__Orchestration_Process__r.order__c, steps);
            system.debug(openStepsForItem);
        }
        
        map<ID, list<Task>> mapOrdToTasks = new  map<ID, list<Task>>();
        for (Task tsk : [select id, whatId, subject from task where IsClosed = false and whatId in :(new map<ID,Order__c>(orders)).keySet()])
        {
            list<Task> ordTasks = mapOrdToTasks.get(tsk.whatId);
            if (ordTasks == null)
                ordTasks = new list<Task>();
                
            ordTasks.add(tsk);
            mapOrdToTasks.put(tsk.whatId, ordTasks);
        }        
        
        List<ObjectWithPendingOrchStatus> listOfObj = new List <ObjectWithPendingOrchStatus>();
        for (order__c ord : orders) {
            system.debug(openStepsForItem.get(ord.id));
            ObjectWithPendingOrchStatus obj;
            if (openStepsForItem.get(ord.id) == null)
                obj = new ObjectWithPendingOrchStatus (ord, mapOrdToTasks.get(ord.Id), new list<CSPOFA__Orchestration_Step__c>());
            else
                obj = new ObjectWithPendingOrchStatus (ord, mapOrdToTasks.get(ord.Id), openStepsForItem.get(ord.id));
            listOfObj.add(obj);

            listwrap.add(obj);
            mapwrap.put (ord.id, obj);
            system.debug(openStepsForItem.get(ord.id));
        }
        if (!listwrap.isEmpty() && selectedOrderWrap == null)
            selectedOrderWrap = listwrap[0];
        return listOfObj;
    }

    public ObjectWithPendingOrchStatus[] getProdOrders() {
        String uid = UserInfo.getUserId();
        listprodwrap = new List<ObjectWithPendingOrchStatus>();
        mapprodwrap = new map<id, ObjectWithPendingOrchStatus>();
        string query = 'select ' + objectNameQueryFields.get('Product_Order__c') + ' from Product_Order__c where Assigned_Fulfilment_Owner__c =: uid OR Assigned_Social_Owner__c =: uid';

        List<Product_Order__c> prodords = database.query(query);

        Map<id, Product_Order__c> idProdOrders = new map<id, product_order__c>(prodords); 
        Set<id> pordIds = idProdOrders.keySet();

        query = 'select ' + objectNameQueryFields.get('CSPOFA__Orchestration_Step__c') + ' from CSPOFA__Orchestration_Step__c '+
            'where (CSPOFA__Status__c = \'In Progress\' OR CSPOFA__Status__c = \'Waiting For Feedback\') AND CSPOFA__Orchestration_Process__r.product_order__c IN: pordIds';
        List<CSPOFA__Orchestration_Step__c> openSteps = database.query(query);

        Map<id, list<CSPOFA__Orchestration_Step__c>> openStepsForItem = new map <id, list<CSPOFA__Orchestration_Step__c>>();

        for (CSPOFA__Orchestration_Step__c step : openSteps) {
            list<CSPOFA__Orchestration_Step__c> steps = openStepsForItem.get(step.CSPOFA__Orchestration_Process__r.product_order__c);
            if (steps == null)
                steps = new list<CSPOFA__Orchestration_Step__c>();
            steps.add(step);

            openStepsForItem.put(step.CSPOFA__Orchestration_Process__r.product_order__c, steps);
        }
        
        map<ID, list<Task>> mapProdOrdToTasks = new  map<ID, list<Task>>();
        for (Task tsk : [select id, whatId, subject from task where IsClosed = false and whatId in :(new map<ID,Product_Order__c>(prodords)).keySet() limit 100])
        {
            list<Task> prodOrdTasks = mapProdOrdToTasks.get(tsk.whatId);
            if (prodOrdTasks == null)
                prodOrdTasks = new list<Task>();
                
            prodOrdTasks.add(tsk);
            mapProdOrdToTasks.put(tsk.whatId, prodOrdTasks);
        } 
               
        
        List<ObjectWithPendingOrchStatus> listOfObj = new List <ObjectWithPendingOrchStatus>();
        for (Product_Order__c prodord : prodords) {
            ObjectWithPendingOrchStatus obj;
            if (openStepsForItem.get(prodord.id) == null) 
                obj = new ObjectWithPendingOrchStatus (prodord, mapProdOrdToTasks.get(prodord.id), new list<CSPOFA__Orchestration_Step__c>());
            else
                obj = new ObjectWithPendingOrchStatus (prodord, mapProdOrdToTasks.get(prodord.id), openStepsForItem.get(prodord.id));
            listOfObj.add(obj);
            listprodwrap.add(obj);
            mapprodwrap.put (prodord.id, obj);
        }
        if (!listprodwrap.isEmpty() && selectedProdOrderWrap == null)
            selectedProdOrderWrap = listprodwrap[0];
        return listOfObj;
    }
    
    public String getTaskView() {
        return taskView;
    }
    
    public void setTaskView(String taskView) {
        this.taskView = taskView;
    }

    public String getStateView() {
        return stateView;
    }
    
    public void setStateView(String stateView) {
        this.stateView = stateView;
    }

    public Task[] getTaskList() 
    {   
        taskListNoDup = new List<Task>();
        String uid = UserInfo.getUserId();
        List<Task> taskList  = new List<Task>();

        if(taskView == 'Due in 7 days') {
            taskList = new list<task>();
            for (task t : userOpenTasks) {
                if (t.ActivityDate <= date.today().addDays(7) &&
                 (t.state__c == stateView || stateView =='All' || stateView == null) ){
                if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else if(taskView == 'My Open Tasks') {
            taskList = new list<task>();
            for (task t : userOpenTasks) {

                if (t.IsClosed == false && (t.state__c == stateView || stateView =='All' || stateView == null)) {
                    if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }

        else if(taskView == 'Completed') {
            taskList = new list<task>();
            for (task t : userOpenTasks) {

                if (t.IsClosed == true && (t.state__c == stateView || stateView =='All' || stateView == null)) {
                    if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else if(taskView == 'All') {
            taskList = new list<task>();
            for (task t : userOpenTasks) {

                if ((t.state__c == stateView || stateView =='All' || stateView == null)) {
                    if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else if (taskView == 'New Today' ) {
            taskList = new list<task>();
            for (task t : userOpenTasks) {
                date cd = date.newinstance(t.createddate.year(), t.createddate.month(), t.createddate.day());
                DateTime dT = System.now();
                Date todayDate = date.newinstance(dT.year(), dT.month(), dT.day());
                if (cd == todayDate && (t.state__c == stateView || stateView =='All' || stateView == null)) {
                    if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else if (taskView == 'Due Today' ) {
            taskList = new list<task>();
            for (task t : userOpenTasks) {
                if (t.ActivityDate == date.today() && (t.state__c == stateView || stateView =='All' 
                    || stateView == null)) {
                if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }     
            }  
        }
        else if (taskView == 'All Overdue' ) {
            taskList = new list<task>();
            for (task t : userOpenTasks) {
                if (t.ActivityDate < date.today() && t.IsClosed == false && (t.state__c == stateView || stateView =='All' || 
                    stateView == null))
                     {
                if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else if (taskView == 'In Progress Tasks') {
            taskList = new list<task>();
            for (task t : userOpenTasks) {
                if (t.Status=='In Progress'  && (t.state__c == stateView || stateView =='All' || 
                    stateView == null)) {
                if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        else {
            taskList = new list<task>();
            for (task t : userOpenTasks) {

                if (t.state__c == stateView || stateView =='All' || stateView == null)  {
                if (assignedTo == 'All' || assignedTo == null || (assignedTo == 'Me' && t.OwnerId == uid)
                    || (assignedTo == 'My Groups' && groupNames.contains(t.CS_GT__Associated_Group__c)))
                    taskList.add(t);
                }
            }
        }
        if(!taskList.isEmpty() && selectedTask == null)
        {
            selectedTaskId = taskList[0].Id;
            loadSelectedTaskDetails();
        }
        Set<Task> taskSet = new Set<Task>();
        List<Task> taskListNoDup = new List<Task>();
        for (Task s : taskList) {
          if (taskSet.add(s)) {
            taskListNoDup.add(s);
          }
        }

        return taskListNoDup;
    }

    private void getAllGroupNames () 
    {
        groupNames = new set<String>();
        List<Group> groupList = 
            new List<Group>([Select Id from Group where RelatedId = :Userinfo.getUserRoleId()]);
        List<GroupMember> groupMemberList = 
            new List<GroupMember>([Select GroupId, Group.Name from GroupMember where UserOrGroupId = :Userinfo.getUserId() or UserOrGroupId in :groupList]);
        for (Integer i = 0; i < groupMemberList.size(); i++) {
            groupNames.add(groupMemberList[i].Group.Name);
        }
    }

    public pageReference loadSelectedOrderDetails()
    {
        selectedOrderWrap = mapwrap.get(selectedOrderWrapIden);

        return null;
    }

    public pageReference loadSelectedProdOrderDetails()
    {
        selectedProdOrderWrap = mapprodwrap.get(selectedProdOrderWrapIden);

        return null;
    }
    
    public pageReference loadSelectedTaskDetails()
    {
    error = false;
        Id taskId = selectedTaskId;
        Pattern myPattern = Pattern.compile('<Associated Group>(.*?)</Associated Group>');

        string query = 'select '+ objectNameQueryFields.get('Task') + ' FROM Task where id =:taskId';
        list<task> tempuserOpenTasks = database.query(query);
        map<id, task> tempmapUserOpenTasks = new map<id, task>(tempuserOpenTasks);
        selectedTask = tempmapUserOpenTasks.get(taskId);

        if (selectedTask != null && selectedTask.Description != null) {
            Matcher m = myPattern.matcher(selectedTask.Description);
            while (m.find() == true) {
            selectedTask.Description = selectedTask.Description.replace(m.group(),'');
            }
        }
        
        return null;
    }
    
    public pageReference changeTask()
    {

    errorMessage = '';
        if (selectedTaskId != null) {
            Task updateTask = new Task(Id = selectedTaskId);
            if(selectedTaskCompleted)
                updateTask.Status = 'Completed';
            else
                updateTask.Status = 'In Progress';
            try {
                upsert updateTask;
                getAllUserOpenTasks();
                loadSelectedTaskDetails();
            }
            catch (Exception e) {
            error = true;

                if (e.getTypeName() == 'System.DmlException' && !String.isEmpty(((DMLException)e).getDmlMessage(0)))
                    errorMessage = ((DMLException)e).getDmlMessage(0);//'You cannot complete this task cause you have not populated all required fields. Please review the task description and make sure you have done the expected work.';
                else
                    errorMessage = 'Task could not be completed. Please contact your system administrator.';

                System.debug(e.getMessage());
            }
        }
        
        return null;
    }

    public pageReference setInProgress()
    {
        if (selectedTaskId != null) {
            String uid = UserInfo.getUserId();
            Task updateTask = new Task(Id = selectedTaskId, OwnerId = uid);

            updateTask.Status = 'In Progress';

            upsert updateTask;
            getAllUserOpenTasks();
            loadSelectedTaskDetails();
        }
        return null;
    }

    public class TaskWithAdditionalDetails
    {
        public Id accId             { get; set; }
        public String accName       { get; set; }
        public Id oppId             { get; set; }
        public String oppName       { get; set; }
        public String productName   { get; set; }
        public Boolean HasDetails   { get; set; }
        public Date campaignStartDate {get; set;}
        public TaskWithAdditionalDetails (Id taskId, Id taskWhatId) {
            HasDetails = true;
            if (taskWhatId.getSObjectType() == Order__c.sObjectType) {
                order__c order = [select id, account__r.name, account__c, opportunity__r.name, Proposed_Start_Date__c, opportunity__c
                                from order__c where id =: taskWhatId];
                this.accName = order.account__r.name;
                this.accId = order.account__c;
                this.oppName = order.opportunity__r.name;
                this.oppId =  order.opportunity__c;
                this.productName = '';
                this.campaignStartDate = order.Proposed_Start_Date__c;

            }
            else if (taskWhatId.getSObjectType() == product_order__c.sObjectType) {
                product_order__c prodorder = [select id, order__r.account__r.name, order__r.account__c,order__r.opportunity__r.name,order__r.Proposed_Start_Date__c,
                                            order__r.opportunity__c, Product_Node__r.Name
                                            from product_order__c where id=:taskWhatId];
                this.accName = prodorder.order__r.account__r.name;
                this.accId = prodorder.order__r.account__c;
                this.oppName = prodorder.order__r.opportunity__r.name;
                this.oppId = prodorder.order__r.opportunity__c;
                this.productName = prodorder.Product_Node__r.Name;
                this.campaignStartDate = prodorder.order__r.Proposed_Start_Date__c;
            }
            else if (taskWhatId.getSObjectType() == Creative__c.sObjectType) {
                creative__c creative = [select id, product_order__r.Order__r.account__r.name, product_order__r.Order__r.account__c, product_order__r.Order__r.Proposed_Start_Date__c,
                                       product_order__r.Order__r.opportunity__r.name,  product_order__r.Order__r.opportunity__c,
                                       Product_Order__r.Product_Node__r.Name from Creative__c where id=: taskWhatId];
                this.accName = creative.product_order__r.Order__r.account__r.name;
               this.accId = creative.product_order__r.Order__r.account__c;
               this.oppName = creative.product_order__r.Order__r.opportunity__r.name;
               this.oppId = creative.product_order__r.Order__r.opportunity__c;
               this.productName = creative.Product_Order__r.Product_Node__r.Name;
               this.campaignStartDate = creative.Product_Order__r.order__r.Proposed_Start_Date__c;
            }
            else {
                HasDetails = false;
            }

        }

        public TaskWithAdditionalDetails (Id taskId, Id taskWhatId, Order__c order, Product_Order__c prodOrder, Creative__c creative) {
            HasDetails = true;
            if (taskWhatId != null) {
            if (taskWhatId.getSObjectType() == Order__c.sObjectType) {
                this.accName = order.account__r.name;
                this.accId = order.account__c;
                this.oppName = order.opportunity__r.name;
                this.oppId =  order.opportunity__c;
                this.productName = '';
                this.campaignStartDate = order.Proposed_Start_Date__c;

            }
            else if (taskWhatId.getSObjectType() == product_order__c.sObjectType) {
                
                this.accName = prodorder.order__r.account__r.name;
                this.accId = prodorder.order__r.account__c;
                this.oppName = prodorder.order__r.opportunity__r.name;
                this.oppId = prodorder.order__r.opportunity__c;
                this.productName = prodorder.Product_Node__r.Name;
                this.campaignStartDate = prodorder.order__r.Proposed_Start_Date__c;

            }
            else if (taskWhatId.getSObjectType() == Creative__c.sObjectType) {
                
               this.accName = creative.product_order__r.Order__r.account__r.name;
               this.accId = creative.product_order__r.Order__r.account__c;
               this.oppName = creative.product_order__r.Order__r.opportunity__r.name;
               this.oppId = creative.product_order__r.Order__r.opportunity__c;
               this.productName = creative.Product_Order__r.Product_Node__r.Name;
               this.campaignStartDate = creative.Product_Order__r.order__r.Proposed_Start_Date__c;
            }
            else {
                HasDetails = false;
            }
        }
        else
            HasDetails = false;

        }
    } 

    public class ObjectWithPendingOrchStatus 
    {
        public order__c order {get;set;}
        public string iden { get; set; }
        public product_order__c prodOrder {get; set;}
        public string[] status {get; set;}
        public Boolean jeopardy { get; set; }
        public string jeopardyStatus { get; set; }

        public ObjectWithPendingOrchStatus (order__c ord, list<Task> ordTasks, List<CSPOFA__Orchestration_Step__c> openSteps) {
            this.order = ord;
            this.iden = ord.Id;
            this.status = new list<string>();

            List<task> openTasks = ordTasks;

            if (!openSteps.isEmpty()) {
                Boolean tasksOpen = false;
                for (CSPOFA__Orchestration_Step__c step : openSteps){
                   
                    if (step.Target_SLA_DateTime__c < system.now() || step.CSPOFA__target_date_time__c < system.now()) {
                        this.jeopardy = true;
                        this.jeopardyStatus = 'Step ' + step.name + ' is in jeopardy. Targeted completion date was ' + 
                        step.CSPOFA__target_date__c+'.';
                    }
                    if (step.CSPOFA__Orchestration_Process__r.Target_SLA_DateTime__c < system.now() || 
                        step.CSPOFA__Orchestration_Process__r.CSPOFA__target_date_time__c < system.now()) {
                        this.jeopardy = true;
                        this.jeopardyStatus = 'Process ' + step.CSPOFA__Orchestration_Process__r.name + ' is in jeopardy. Targeted completion date was '+
                        step.CSPOFA__Orchestration_Process__r.CSPOFA__target_date__c.format()+'.';
                    }
                    if (!step.name.contains(' SLA')) {
                        if (step.CSPOFA__Type__c == 'Create Task') {
                            if (!tasksOpen) {
                                this.status = new List<String>();
                                this.status.add('Open tasks: ');
                                tasksOpen = true;
                            }

                            this.status.add(step.CSPOFA__Task_Subject__c);

                        }
                        else if (step.CSPOFA__Type__c == 'Monitor Field' && !tasksOpen) {
                             if (this.status == null  || this.status.isEmpty())
                                this.status.add('Expecting one or more of the following fields to be populated: ');
                            this.status.add(getMonitorLabel(step));
                        }
                    }
                }
            }
             else if (openTasks != null && !openTasks.isEmpty()) {
                for (task t : openTasks) {
                    if (this.status == null || this.status.isEmpty())
                        this.status.add('Open tasks: ');
                    this.status.add(t.subject);
                }
            }
            else {
                this.status.add('Nothing to do at the time');
            }
        }

        private string translateAPItoLabel (string apiname) {
            String objectname = '';
            String tempname = ''; 
             if (apiname.contains('.')) {
                integer i= apiname.indexOf ('.');
                tempname = apiname.substring(i+1, apiname.length());

                if (tempname.contains('.')) {
                    integer j= tempname.indexOf ('.');
                    objectname = tempname.substring(0, j);

                }
                i = apiname.lastIndexOf ('.');
                apiname = apiname.substring(i+1, apiname.length());
            }
             if (objectname.contains('_')) {
                String regex = '__r';
                Pattern regexPattern = Pattern.compile(regex);
                Matcher regexMatcher = regexPattern.matcher(objectname);

                if(regexMatcher.find()) {
                   objectname = objectname.replaceAll(regex, '');
                }
                regex = '\\_';
                regexPattern = Pattern.compile(regex);
                regexMatcher = regexPattern.matcher(objectname);

                if(regexMatcher.find()) {
                   objectname = objectname.replaceAll(regex, ' ');
                }
                objectname += '-';
            }

            if (apiname.contains('_')) {

                String regex = '__c';
                Pattern regexPattern = Pattern.compile(regex);
                Matcher regexMatcher = regexPattern.matcher(apiname);

                String replacedMessage;

                if(regexMatcher.find()) {
                   replacedMessage = apiname.replaceAll(regex, '');
                }
                regex = '\\_';
                regexPattern = Pattern.compile(regex);
                regexMatcher = regexPattern.matcher(replacedMessage);

                if(regexMatcher.find()) {
                   replacedMessage = replacedMessage.replaceAll(regex, ' ');
                }

                return objectname + replacedMessage;
            }
            else {

                return objectname + apiname;
            }
        }

        private string getMonitorLabel (CSPOFA__Orchestration_Step__c step) {
            string apiname = translateAPItoLabel(step.CSPOFA__Field_Name__c);
            string result = '';
            if (step.CSPOFA__Field_Monitor_Operator__c == 'equals')
                result = apiname + ' = ' + step.CSPOFA__Field_Value__c;
            else if (step.CSPOFA__Field_Monitor_Operator__c == 'is not') {
               result = apiname;
            }
            return result;
        }

        public ObjectWithPendingOrchStatus (Product_Order__c prodord, list<Task> prodOrdTasks, list<CSPOFA__Orchestration_Step__c> openSteps) {
            this.prodOrder = prodord;
            this.iden = prodord.Id;
            this.status = new list<string>();

            List<task> openTasks = prodOrdTasks;//[select id, subject from task where IsClosed = false and whatId =: iden LIMIT 100];
            if (!openSteps.isEmpty()) {
                boolean tasksOpen = false;
                for (CSPOFA__Orchestration_Step__c step : openSteps){

                    if (step.Target_SLA_DateTime__c < system.now() || step.CSPOFA__target_date_time__c < system.now()) {
                        this.jeopardy = true;
                        this.jeopardyStatus = 'Step ' + step.name + ' is in jeopardy. Targeted completion date was ' + 
                        step.CSPOFA__target_date__c+'.';
                    }

                    if (step.CSPOFA__Orchestration_Process__r.Target_SLA_DateTime__c < system.now() || 
                        step.CSPOFA__Orchestration_Process__r.CSPOFA__target_date_time__c < system.now()) {
                        this.jeopardy = true;
                        this.jeopardyStatus = 'Process ' + step.CSPOFA__Orchestration_Process__r.name + ' is in jeopardy. Targeted completion date was '+
                        step.CSPOFA__Orchestration_Process__r.CSPOFA__target_date__c.format()+'.';
                    }

                    if (!step.name.contains(' SLA')) {
                        if (step.CSPOFA__Type__c == 'Create Task') {
                            if (!tasksOpen) {
                                this.status = new List<String>();
                                this.status.add('Open tasks: ');
                                tasksOpen = true;
                            }

                            this.status.add(step.CSPOFA__Task_Subject__c);

                        }
                        
                        else if (step.CSPOFA__Type__c == 'Monitor Field' && !tasksOpen) {
                             if (this.status == null  || this.status.isEmpty())
                                this.status.add('Expecting one or more of the following fields to be populated: ');
                            this.status.add(getMonitorLabel(step)) ;
                        }

                    }
                }
            }
             else if (openTasks != null && !openTasks.isEmpty()) {
                for (task t : openTasks) {
                    if (this.status == null || this.status.isEmpty())
                        this.status.add('Open tasks: ');
                    this.status.add(t.subject);
                }
            }
            else {
                this.status.add('Nothing to do at the time');
            }
        }
    }
    
// end of controller code
}