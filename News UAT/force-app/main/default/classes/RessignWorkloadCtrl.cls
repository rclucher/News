global with sharing class RessignWorkloadCtrl {

    public class RecordWrap {
        public Boolean checked { get; set; }
        public Task taskrecord { get; set; }
        public Order__c orderrecord { get; set; }
        public Product_Order__c productrecord { get; set; }
        public sObject record { get; set; }
        public Opportunity relatedOpportunity {get; set;}

        public recordWrap (sObject r, String objectLabel) {
            if (objectLabel == 'Task')
                this.taskrecord = (Task)r;
            else if (objectLabel == 'Order__c')
                this.orderrecord = (Order__c)r;
            else if (objectLabel == 'Product_Order__c')
                this.productrecord = (Product_Order__c)r;
            this.checked = false;
            this.record = r;
        }
    }

    public String               objectLabel { get; set; }
    public String               userLabel { get; set; }
    public String               mainUser { get; set; }
    public String               replacementUser { get; set; }
    public Boolean              showWarning { get; set; }
    public Boolean              socialOwner { get; set; }
    public Boolean              reassignMsg { get; set; }
    public String               warningMsg { get; set; }
    public List<SelectOption>   options { get; set; }
    public List<sObject>        records { get; set; }
    public List<RecordWrap>     recordWraps { get; set; }
    public string               mainusername { get; set; }
    public Date                 dateFrom { get; set; }
    public Date                 dateTo { get; set; }

    public void testcallback() {        
        system.debug('callback on controller ');
    }

    @RemoteAction
    global static List<User> getMainUsers() {
        return [select id, Name from user where IsActive=true];
    }

    global RessignWorkloadCtrl () {
        showWarning =   false;
        reassignMsg =   false;
        socialOwner =   false;
/*        dateFrom    =   system.today();
        dateTo      =   system.today();*/
    }

    public List<SelectOption> getItems() {
        options = new List<SelectOption>();
        options.add(new SelectOption('', 'None'));
        options.add(new SelectOption('Order__c', 'Campaign'));
        options.add(new SelectOption('Product_Order__c', 'Product Order'));
        options.add(new SelectOption('Task','Task'));

        return options;
    }

    public PageReference showRecords () {
        showWarning = false;
        reassignMsg = false;

        system.debug('tu' + mainUser + '   ' + objectLabel);
        if (mainUser == null || objectLabel == null || mainUser == '' || objectLabel == '') {
            showWarning = true;
            warningMsg = 'Make sure Object and User are selected';
            return null;
        }

        setRecords();
        return null;
    }

    @TestVisible
    private void setRecords () {
        recordWraps = new List<RecordWrap>();

        if (objectLabel != '') {
            
            String q = 'select id';

            if (objectLabel == 'Order__c')
                q += ',name, account__r.Id, account__r.name, opportunity__r.Id, opportunity__r.Name, Proposed_start_date__c, Assigned_Campaign_Manager__c,  status__c from ' + objectLabel+' where Assigned_Campaign_Manager__c = \'' + mainUser + '\'';
            else if (objectLabel == 'Product_Order__c') {
                q += ',name, order__r.account__r.Id, order__r.opportunity__r.Id, order__r.opportunity__r.Name, order__r.Proposed_start_date__c, Assigned_Social_Owner__c, order__r.account__r.name, Assigned_Fulfilment_Owner__c, status__c from ' + objectLabel +
                ' where Assigned_Fulfilment_Owner__c = \'' + mainUser + '\' '
               +' or assigned_social_owner__c = \'' + mainUser + '\'';
            }
            else if (objectLabel == 'Task')
                q += ',subject, what.name, whatid, OwnerId, ActivityDate, status from ' + objectLabel+' where OwnerId = \'' 
                + mainUser + '\' and status != \'Completed\' and status != \'Done\' ';

            records = database.query(q);

            for (sObject r : records) {
                RecordWrap rw = new RecordWrap (r, objectLabel);
                recordWraps.add(rw);
            }
            
            if (objectLabel == 'Task')
            {
            	map<ID, RecordWrap> mapTaskToRecordWrap = new map<ID, RecordWrap>();
            	map<ID, set<ID>> mapCOPOorCreativeIdToTaskIds = new map<ID, set<ID>>();
            	map<ID, Opportunity> mapCOPOorCreativeIdToOpportunity = new map<ID, Opportunity>();
            	
            	for (RecordWrap rw : recordWraps)
            	{
            		if (rw.taskrecord.WhatId == null) 
            		{
            			rw.relatedOpportunity = new Opportunity();
            			continue;
            		}
            		
            		mapTaskToRecordWrap.put(rw.taskrecord.Id, rw);
            		
            		Schema.SObjectType token = rw.taskrecord.WhatId.getSObjectType();
            		if (token == Schema.Order__c.SObjectType || token == Schema.Product_Order__c.SObjectType || token == Schema.Creative__c.SObjectType)
            		{
            			set<ID> taskIds = mapCOPOorCreativeIdToTaskIds.get(rw.taskrecord.WhatId);
            			if (taskIds == null)
            				taskIds = new set<ID>();
            			
            			taskIds.add(rw.taskrecord.Id);	
            			mapCOPOorCreativeIdToTaskIds.put(rw.taskrecord.WhatId, taskIds);
            		}
            		else
            			rw.relatedOpportunity = new Opportunity();
            			
            	}
            	 
            	for (Order__c co : [select Id, Opportunity__r.Id, Opportunity__r.Name, Opportunity__r.AccountId, Opportunity__r.Account.Name 
            						from Order__c 
            						where Id in :mapCOPOorCreativeIdToTaskIds.keySet()])
            	 	mapCOPOorCreativeIdToOpportunity.put(co.Id, co.Opportunity__r);
            	 	
            	for (Product_Order__c po : [select Id, Order__r.Opportunity__r.Id, Order__r.Opportunity__r.Name, Order__r.Opportunity__r.AccountId,  Order__r.Opportunity__r.Account.Name
            						from Product_Order__c 
            						where Id in :mapCOPOorCreativeIdToTaskIds.keySet()])
            	 	mapCOPOorCreativeIdToOpportunity.put(po.Id, po.Order__r.Opportunity__r);
            	 	
            	for (Creative__c cre : [select Id, Product_Order__r.Order__r.Opportunity__r.Id, Product_Order__r.Order__r.Opportunity__r.Name,
            									Product_Order__r.Order__r.Opportunity__r.AccountId, Product_Order__r.Order__r.Opportunity__r.Account.Name
            						from Creative__c 
            						where Id in :mapCOPOorCreativeIdToTaskIds.keySet()])
            	 	mapCOPOorCreativeIdToOpportunity.put(cre.Id, cre.Product_Order__r.Order__r.Opportunity__r); 
            	 	
            	for (ID recId : mapCOPOorCreativeIdToTaskIds.keySet())     
            	{
            		Opportunity opp = mapCOPOorCreativeIdToOpportunity.get(recId);
            		if (opp == null)
            			opp = new Opportunity();
            		
            		for (ID taskID : mapCOPOorCreativeIdToTaskIds.get(recId))
            		{
            			RecordWrap recWrap = mapTaskToRecordWrap.get(taskID);
            			recWrap.relatedOpportunity = opp;
            		}
            	} 	 	
            	
            }
        }
    }

    public PageReference reassignRecords () {

        reassignMsg  = false;
        showWarning = false;

        if (mainUser == null || objectLabel == null || replacementUser == null || mainUser == '' || objectLabel == '' || replacementUser == '') {
            showWarning = true;
            warningMsg = 'Make sure Object, User and re-assign User are selected';
            return null;
        }
        else if (mainUser == replacementUser) {
            showWarning = true;
            warningMsg = 'You cannot re-assign to the same user.';
            return null;   
        }
        else if  (recordWraps == null || recordWraps.isEmpty()) {
            showWarning = true;
            warningMsg = 'First click Get records button to choose records for re-assignment';
            return null;
        }

        List<Task> checkedTasks = new List<Task>();
        List<Product_Order__c> checkedProducts = new List<Product_Order__c>();
        List<Order__c> checkedOrders = new List<sObject>();

        for (RecordWrap rw : recordWraps) {
            if (rw.checked) {
                reassignMsg = true;      
                if (objectLabel == 'Task') {
                    rw.taskRecord.OwnerId = replacementUser;
                    checkedTasks.add(rw.taskRecord);
                    system.debug(checkedTasks);
                }
                else if (objectLabel == 'Product_Order__c') {
                    if (rw.productRecord.assigned_social_owner__c == mainUser)
                        rw.productRecord.assigned_social_owner__c = replacementUser;
                    else
                        rw.productRecord.Assigned_Fulfilment_Owner__c = replacementUser;
                    checkedProducts.add(rw.productRecord);
                }
                else if (objectLabel == 'Order__c') {
                    rw.orderRecord.Assigned_Campaign_Manager__c = replacementUser;
                    checkedOrders.add(rw.orderRecord);
                }
            }
        }

        if (!checkedTasks.isEmpty())
            update checkedTasks;
        else if (!checkedProducts.isEmpty())
            update checkedProducts;
        else if (!checkedOrders.isEmpty())
            update checkedOrders;
        if (checkedProducts.isEmpty() && checkedOrders.isEmpty() && checkedTasks.isEmpty()) {
            showWarning = true;
            warningMsg = 'You haven\'t selected any record';
            return null;  
        }

        setRecords();
        return null;
    }
    
    public PageReference actionOnSelectObject()
    {
    	recordWraps = null;
    	
    	return null;
    }
}