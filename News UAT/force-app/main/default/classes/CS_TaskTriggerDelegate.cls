public class CS_TaskTriggerDelegate extends CS_TriggerHandler.DelegateBase{
    Map<Id, Id> newQATaskIds;
    Map<Id, Task> newQATasks;
    Map<Id, String> rtIdandName = new Map<Id, String>();
    Map<task, id> newTasks;
    Map<id, id> updatedChecklistManager;
    Map<Id, sObject> completedTasks;

    //public static Boolean ForceTaskKilling;
    //public static Boolean ForceManualTaskClosure;
    //public static Boolean ForceOrchestrationTaskClosure;
    /*
    static{
        //ForceTaskKilling = false;
        ForceManualTaskClosure = false;
        ForceOrchestrationTaskClosure = false;
    }
    */
    
    public override void prepareBefore() {
        newTasks = new map<task, id>();
        completedTasks = new Map<id, sObject>();
        MapTaskRTIdwithName();
    }
    public override void prepareAfter() {
        newQATaskIds = new Map<Id, Id>();
        newQATasks = new Map<Id, Task>();
        updatedChecklistManager = new map<id, id>();
        MapTaskRTIdwithName();
    }

    public override void beforeInsert(sObject o) {
        Task newTask = (Task) o;
        system.debug(newTask.WhatId);
        newTasks.put(newTask, newTask.WhatId);
    }
    public override void beforeUpdate(sObject old, sObject o) {
        Task newTask = (Task) o;
        Task oldTask = (Task) old;
        
       if (oldTask.Status != 'Completed' && newTask.Status == 'Completed') 
            newTask.Completed_Date_Time__c = system.now();   
        system.debug('IVANA **' + newTask.RecordTypeId);
        system.debug('IVANA **' + rtIdandName.get(newTask.RecordTypeId));
        system.debug('IVANA **' + oldTask.Status != 'Completed' && newTask.Status == 'Completed');
        if (oldTask.Status != 'Completed' && newTask.Status == 'Completed' && 
            (rtIdandName.get(newTask.RecordTypeId) == 'QA Check' || rtIdandName.get(newTask.RecordTypeId) == 'To-Do')) 
            completedTasks.put (newTask.Id, o);
        system.debug(completedTasks);
    }
    public override void beforeDelete(sObject o) {}

    public override void afterInsert(sObject o) {
        Task newTask = (Task) o;
        
        if (rtIdandName.get(newTask.RecordTypeId) == 'QA Check') {
            newQATaskIds.put(newTask.WhatId, newTask.Id);
            newQATasks.put(newTask.Id, newTask);
        }
    }
    public override void afterUpdate(sObject old, sObject o) {
        Task newTask = (Task) o;
        Task oldTask = (Task) old;
        
        if (rtIdandName.get(newTask.RecordTypeId) == 'QA Check' && newTask.OwnerId != oldTask.OwnerId) 
            updatedChecklistManager.put(newTask.QA_Checklist__c, newTask.OwnerId);

    }
    public override void afterDelete(sObject o) {}

    public override void finish() {
        if (trigger.isBefore) {
            if (!newTasks.isEmpty())
                PopulateStateAndItemStartDate();
            if (!completedTasks.isEmpty()  && (!CS_TaskBehaviour.ForceOrchestrationTaskClosure))
                ValidateCompletion();
        }
        if (trigger.isAfter) {
            if (!newQATaskIds.isEmpty()) {
                CreateQAChecklist ();
            }

            if (!updatedChecklistManager.isEmpty())
                UpdateQAManager();

        }
    }
    
    private class ValidateTask
    {
        public Task taskRecord { get; set; }
        public sObject taskObject { get; set; }
        
        public Id tasksObjectId { get; set; }
        public string ValidationFunction { get; set; }
        public Boolean IsValid {get; set; }
        public string ErrorMessage {get; set; }
        
        public ValidateTask(Task task, sObject tmpTaskObject, Id sObjectRecordId, string tmpValidationFunction)
        {
            this.taskRecord = task;
            this.tasksObjectId = sObjectRecordId;
            this.taskObject = tmpTaskObject;
            this.ValidationFunction = tmpValidationFunction;
            this.IsValid=false;
        } 

        public Boolean CreativeSourceValidation(Creative__c tmpCreative)
        {
            Boolean result = false;

            System.debug('****tmpCreative=' + tmpCreative);

            if ((tmpCreative.Creative_Source__c=='Premedia') && (tmpCreative.CM_QA_check__c!=null)  && (tmpCreative.Creative_URL_Draft__c!=null))
                result=true;
            else if (tmpCreative.Creative_Source__c=='Customer')
                result=true;
            
            this.ErrorMessage = 'Creative Source must be Premedia and CM QA check passed? must not be empty and Creative URL Draft must not be empty OR Creative Source must be Customer';
            this.IsValid=result;

            System.debug('***result=' + result);
            return result;
        }

        public Boolean ClientApprovedValidation(Creative__c tmpCreative)
        {
            Boolean result = false;

            System.debug('****tmpCreative=' + tmpCreative);

            if ((tmpCreative.Client_Approved__c=='Yes') && (tmpCreative.Creative_URL__c)!=null)
                result=true;
            else if (tmpCreative.Client_Approved__c=='No')
                result=true;

            this.ErrorMessage = 'Client Approved? must be Yes and Creative URL must not be empty OR Client Approved? must be No';
            this.IsValid=result;

            System.debug('***result=' + result);

            return result;
        }
    }




    public class MandatoryInputTask {
        public Task taskRecord { get; set; }
        public sObject tasksObject { get; set; }
        public Set<String> mandatoryFields { get; set; }
        public Id RecordToQuery { get; set; }
        public String NameOfRecord { get; set; }
        public Boolean IsValid { get; set; }
        public list<String> nullField {get; set;}
        public map<String, String> fieldToButton {get; set;}
        
        public MandatoryInputTask (Task task, sObject sObjectRecord) {
            this.taskRecord = task;
            this.tasksObject = sObjectRecord;
            String mandInputs = task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c;
            if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c != null) {
                List<String> tempList = mandInputs.split(',');
                
                //this.mandatoryFields = new Set<String>();
                //for (String manField : tempList)
                //  mandatoryFields.add(manField.split('#')[0]);
                
                this.mandatoryFields = new Set<String>(tempList);
            }        

            this.RecordToQuery = task.WhatId;
            this.IsValid = true; 
            
            //Set<String> nameOfObjs = UtilMethods.findObjectNamesFromRecordIdPrefix(new Set<Id>{task.WhatId});
            //this.NameOfRecord = nameOfObjs.get(0);
        }
    }
    
    void ValidateCompletion() {
        List<Task> tasks = [SELECT 
                                Id, WhatId, CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c, 
                                CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.ValidationFunction__c
                            FROM
                                Task
                            WHERE 
                                Id IN: completedTasks.keySet()];
                                
        Set<String> orderQueryFields = new Set<String>();
        List<Id> coIds = new List<Id>();
        
        Set<String> prodOrderQueryFields = new Set<String>();
        List<Id> poIds = new List<Id>();

        Set<String> creatQueryFields = new Set<String>();
        List<Id> creatIds = new List<Id>();
        
        Map<Id, MandatoryInputTask> mandatoryInputs = new Map<Id, MandatoryInputTask>();
        Map<Id, ValidateTask> mapTaskIdValidateTask = new Map<Id,ValidateTask>();
        
        for (Task task : tasks) {
            Set<Id> whatIds = new Set<Id>();
            MandatoryInputTask mandatoryInput = new MandatoryInputTask (task, completedTasks.get(task.Id));
            mandatoryInputs.put (task.WhatId, mandatoryInput);
            
            List<String> nameOfObjs = new List<String>();
            nameOfObjs.addAll(UtilMethods.findObjectNamesFromRecordIdPrefix(new Set<Id>{task.WhatId}));
            
            if (nameOfObjs[0] == 'Order__c') {
                if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c!= null) {
                    if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.contains(',')) {
                        for (string temp : task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split(','))
                            orderQueryFields.add(temp.split('#')[0]);
                    }
                    else {
                        orderQueryFields.add(task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split('#')[0]);
                    }
                    coIds.add(task.WhatId); 
                }
            }
            else if (nameOfObjs[0] == 'Product_Order__c') {
                if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c!= null) {
                    if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.contains(',')) {
                        for (string temp : task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split(','))
                            prodOrderQueryFields.add(temp.split('#')[0]);
                    }
                    else {
                        prodOrderQueryFields.add(task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split('#')[0]);
                    }
                    poIds.add(task.WhatId); 
                }
            }
            else if (nameOfObjs[0] == 'Creative__c') {
                if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c!= null) 
                {
                    if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.contains(',')) {
                        for (string temp : task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split(','))
                            creatQueryFields.add(temp.split('#')[0]);
                    }
                    else {
                        creatQueryFields.add(task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Mandatory_Input_Fields__c.split('#')[0]);
                    }
                    creatIds.add(task.WhatId); 
                }
                else if (task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.ValidationFunction__c!=null)
                {
                    sObject tmpTriggerTask = completedTasks.get(task.Id);
                    mapTaskIdValidateTask.put(task.Id,new ValidateTask(task,tmpTriggerTask,task.WhatId,task.CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.ValidationFunction__c));
                    creatIds.add(task.WhatId); 
                }
            }
        }
        
        string allFields = '';
        for (string temp : orderQueryFields) {
            if (allFields == '')    
                allFields = temp;
            else
                allFields += ', '+temp;
        }
        if (allFields != '') {
            String coQuery = 'SELECT ' + allFields + ' FROM Order__c WHERE Id IN: coIds'; 
            system.debug(coQuery);
            List<Order__c> CampaignOrders = Database.query(coQuery);
            
            map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Order__c.fields.getMap();
            
            for (Order__c ord : CampaignOrders) {
                MandatoryInputTask mandatoryInputInfo = mandatoryInputs.get(ord.Id);
                mandatoryInputInfo.IsValid = true;
                mandatoryInputInfo.nullField = new list<String>();
                mandatoryInputInfo.fieldToButton = new map<String, String>();
                
                system.debug('########## mandatoryInputInfo.mandatoryFields ' + mandatoryInputInfo.mandatoryFields);
                                
                Boolean valid = true;
                if (!mandatoryInputInfo.mandatoryFields.isEmpty()) {
                    for (string singleField : mandatoryInputInfo.mandatoryFields) {
                        list<string> fieldParts = singleField.split('#');
                        
                        valid = ord.get(fieldParts[0]) != null ? true : false;
                        if (!valid)
                        {
                            string fieldLabel = fieldMap.get(fieldParts[0]).getDescribe().getLabel();
                            
                            system.debug('########## fieldParts ' + fieldParts);
                            
                            mandatoryInputInfo.IsValid = false;
                            
                            if (fieldParts.size() > 1)
                                mandatoryInputInfo.fieldToButton.put(fieldLabel, fieldParts[1]);      
                            else
                                mandatoryInputInfo.nullField.add(fieldLabel);   
                                
                            system.debug('########## mandatoryInputInfo.fieldToButton ' + mandatoryInputInfo.fieldToButton);    
                            system.debug('########## mandatoryInputInfo.nullField ' + mandatoryInputInfo.nullField);   
                            
                            //break;
                        }
                    }
                }
                //mandatoryInputInfo.IsValid = valid;
                // mandatoryInputInfo.nullField = mandatoryInputInfo.nullField.removeEnd(', ');
            }
        }

        allFields = '';
        for (string temp : prodOrderQueryFields) {
            if (allFields == '')    
                allFields = temp;
            else
                allFields += ', '+temp;
        }
        if (allFields != '') {

            String poQuery = 'SELECT ' + allFields + ' FROM Product_Order__c WHERE Id IN: poIds'; 
            system.debug(poQuery);
            List<Product_Order__c> ProductOrders = Database.query(poQuery);
            
            map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Product_Order__c.fields.getMap();
            
            for (Product_Order__c pord : ProductOrders) {
                MandatoryInputTask mandatoryInputInfo = mandatoryInputs.get(pord.Id);
                mandatoryInputInfo.IsValid = true;
                mandatoryInputInfo.nullField = new list<String>();
                mandatoryInputInfo.fieldToButton = new map<String, String>();
                
                Boolean valid = true;
                if (!mandatoryInputInfo.mandatoryFields.isEmpty()) {
                    for (string singleField : mandatoryInputInfo.mandatoryFields) {
                        list<string> fieldParts = singleField.split('#');
                        
                        valid = pord.get(fieldParts[0]) != null ? true : false;
                        if (!valid)
                        {
                            string fieldLabel = fieldMap.get(fieldParts[0]).getDescribe().getLabel();
                            
                            mandatoryInputInfo.IsValid = false;
                            
                            if (fieldParts.size() > 1)
                                mandatoryInputInfo.fieldToButton.put(fieldLabel, fieldParts[1]);      
                            else
                                mandatoryInputInfo.nullField.add(fieldLabel);       
                            //break;
                        }
                    }
                }
                //mandatoryInputInfo.IsValid = valid;
                //mandatoryInputInfo.nullField = mandatoryInputInfo.nullField.removeEnd(', ');
            }
        }

        allFields = '';
        for (string temp : creatQueryFields) {
            if (allFields == '')    
                allFields = temp;
            else
                allFields += ', '+temp;
        }
        if (allFields != '') {
            String cretQuery = 'SELECT ' + allFields + ' FROM Creative__c WHERE Id IN: creatIds'; 
            system.debug(cretQuery);
            List<Creative__c> Creatives = Database.query(cretQuery);
            
            map<String, Schema.SObjectField> fieldMap = Schema.sObjectType.Creative__c.fields.getMap();
            
            for (Creative__c cret : Creatives) {
                MandatoryInputTask mandatoryInputInfo = mandatoryInputs.get(cret.Id);
                mandatoryInputInfo.IsValid = true;
                mandatoryInputInfo.nullField = new list<String>();
                mandatoryInputInfo.fieldToButton = new map<String, String>();
                
                Boolean valid = true;
                if (!mandatoryInputInfo.mandatoryFields.isEmpty()) {
                    for (string singleField : mandatoryInputInfo.mandatoryFields) {
                        list<string> fieldParts = singleField.split('#');
                        
                        valid = cret.get(fieldParts[0]) != null ? true : false;
                        if (!valid)
                        {
                            string fieldLabel = fieldMap.get(fieldParts[0]).getDescribe().getLabel();
                            
                            mandatoryInputInfo.IsValid = false;
                            
                            if (fieldParts.size() > 1)
                                mandatoryInputInfo.fieldToButton.put(fieldLabel, fieldParts[1]);      
                            else
                                mandatoryInputInfo.nullField.add(fieldLabel);                   
                            //break;
                        }
                    }
                }
                //mandatoryInputInfo.IsValid = valid;
                //mandatoryInputInfo.nullField = mandatoryInputInfo.nullField.removeEnd(', ');
            }
        }
        
        if (mapTaskIdValidateTask.size()>0)
        {
            map<Id,Creative__c> mapCreative = new Map<Id,Creative__c>([select Id, Creative_Source__c, CM_QA_check__c, 
                Creative_URL_Draft__c,Client_Approved__c, Creative_URL__c 
                from Creative__c where Id in : creatIds]);

            for (ValidateTask tmpValidateTask : mapTaskIdValidateTask.values())
            {
                Creative__c tmpCreative = mapCreative.get(tmpValidateTask.tasksObjectId);
                if (tmpValidateTask.ValidationFunction=='CreativeSourceValidation')
                {
                    tmpValidateTask.CreativeSourceValidation(tmpCreative);
                }
                else if(tmpValidateTask.ValidationFunction=='ClientApprovedValidation')
                {
                    tmpValidateTask.ClientApprovedValidation(tmpCreative);
                }
            }
        }
        

        for (MandatoryInputTask mit : mandatoryInputs.values()) {
            if (!mit.IsValid) 
            {
                system.debug('########## mit ' + mit);  
                
                string nullField = '';
                string buttonField = '';
                
                for (string nf : mit.nullField)
                    nullField += (nf + ', ');

                for (String bf : mit.fieldToButton.keySet())
                    buttonField += (mit.fieldToButton.get(bf) + ', ');
                
                if (buttonField != '')
                    buttonField = buttonField.removeEnd(', ');
                
                if (nullField != '')    
                    nullField = nullField.removeEnd(', ');
                    
                string errorMessage = '';
                if (buttonField != '' || nullField != '')
                    errorMessage = 'You cannot complete this task because ';
                    
                if (buttonField != '' && nullField != '')
                    errorMessage += 'you have not populated all required fields [' + nullField + '] and you have not pushed all required buttons [' + buttonField + ']. ';    
                else if (buttonField == '' && nullField != '')    
                     errorMessage += 'you have not populated all required fields [' + nullField + ']. '; 
                else if (buttonField != '' && nullField == '')
                    errorMessage += 'you have not pushed all required buttons [' + buttonField + ']. '; 
                    
                if (errorMessage != '')
                {
                    errorMessage += 'Please review the task description and make sure you have done the expected work.';
                    mit.tasksObject.addError(errorMessage);     
                }
            }
        }
        
        if (mapTaskIdValidateTask.size()>0)
        {
            string errorMessage = '';
            for (ValidateTask tmpValidateTask : mapTaskIdValidateTask.values())
            {
                if (!tmpValidateTask.IsValid)
                {
                    errorMessage = 'You cannot complete this task because ' + tmpValidateTask.ErrorMessage ;
                    tmpValidateTask.taskObject.addError(errorMessage);          
                }
            }
        }
    }
    
    void UpdateQAManager() {
        Map<Id, QA_Checklist__c> checklists = new Map<Id, QA_Checklist__c>([SELECT Id, QA_Manager__c from QA_Checklist__c
                                            WHERE Id IN: updatedChecklistManager.keySet()]);
        for (Id checkId : updatedChecklistManager.keySet())
            checklists.get(checkId).QA_Manager__c = updatedChecklistManager.get(checkId);

        update checklists.values();
    }

    void PopulateStateAndItemStartDate () {
        system.debug(newTasks);
        map<id, String> allObjectTNames = UtilMethods.mapRecordIdWithObjectName (new set<id>(newTasks.values()));
        List<string> queries = new list<string>();
        map<id, product_order__c> prodOrdersForTasks ;
        map<id, creative__c> creativeForTasks ;
        map<id,order__c> orders ;

        Map<String, String> objectNameQueryFields = new Map<String, String> {
            'Product_Order__c' => 'order__r.state__c, Product_Order_start_date__c ',
            'Order__c'         => 'state__c, proposed_start_date__c, actual_start_date__c ',
            'Creative__c'      => 'product_order__r.order__r.state__c, product_order__r.Product_Order_start_date__c '
        };

        for (string objectname : allObjectTNames.values()) {
            system.debug(objectName);
            string q = 'select id ';
            if (objectNameQueryFields.get(objectName) != null) {    
                List<Id> nmaps = newTasks.values();
                q += ', ';
                q += objectNameQueryFields.get(objectname);
            
                q += ' FROM ' + objectname + ' where id IN: nmaps';

                if (objectname=='Product_Order__c') {
                    list <product_order__c> po = Database.query(q);
                    prodOrdersForTasks = new map<id, product_order__c> (po);
                    system.debug(prodOrdersForTasks);
                }
                else if (objectname == 'order__c') {
                    list<order__c> o = Database.query(q);
                    orders = new map<id, order__c>(o);
                    system.debug(orders);
                }
                else if (objectname == 'creative__c') {
                    list<creative__c> c = Database.query(q);
                    creativeForTasks = new map<id, creative__c>(c);
                }
            } 
        }

        for (task rec : newTasks.keySet()) {
            id tId = newTasks.get(rec);
            system.debug(tId);
            if (allObjectTNames.get(tId) == 'product_order__c') {
                rec.state__c = prodOrdersForTasks.get(tId).order__r.state__c;
                rec.Item_Proposed_Start_Date__c = prodOrdersForTasks.get(tId).Product_Order_start_date__c;
            }
            else if (allObjectTNames.get(tId) == 'order__c') {
                rec.state__c = orders.get(tId).state__c;
                if (orders.get(tId).actual_start_date__c == null)
                    rec.Item_Proposed_Start_Date__c = orders.get(tId).proposed_start_date__c;
                else
                    rec.Item_Proposed_Start_Date__c = null;
            }
            else if (allObjectTNames.get(tId) == 'creative__c') {
                rec.state__c = creativeForTasks.get(tId).product_order__r.order__r.state__c;
                rec.Item_Proposed_Start_Date__c = creativeForTasks.get(tId).product_order__r.Product_Order_start_date__c;
            }
            system.debug(rec);
        }

    }

    public void MapTaskRTIdwithName ()
    {
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Task; 
        Map<String, Schema.RecordTypeInfo> TaskRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 

        for (String name : TaskRecordTypeInfo.keySet()) {
            rtIdandName.put(TaskRecordTypeInfo.get(name).getRecordTypeId(), Name);
        }
    }

    private Map<id, List<QA_Item__c>> objectWithLatestQAItems (Set<Id> objectIds) 
    {
        List<QA_Checklist__c> checklists = [select id,(select id, result__c, item__c, note__c from QA_Items__r), product_order__c, Campaign_Order__c from 
            QA_Checklist__c WHERE
            Product_Order__c IN: objectIds OR Campaign_Order__c IN: objectIds ORDER BY CreatedDate DESC];
        system.debug('**'+checklists+'**');
        Map<id, List<QA_Item__c>> resultMap = new map<id, list<QA_Item__c>>();
        if (checklists.isEmpty())
            return null;

        for (QA_Checklist__c qa : checklists) {
            if (resultMap.containsKey(qa.Product_Order__c) || resultMap.containsKey(qa.Campaign_Order__c))
                continue;
            Id objectId = (qa.Product_Order__c!=null) ? qa.Product_Order__c : qa.Campaign_Order__c;
            resultMap.put (objectId, new List<QA_Item__c> (qa.qa_items__r));
        }
            system.debug('**'+resultMap+'**');
        return resultMap;
    }

    public void CreateQAChecklist() 
    {
        Set<String> allObjectTNames = UtilMethods.findObjectNamesFromRecordIdPrefix (newQATaskIds.keySet());
        List<String> processNames = new List<String>();
        Map<Id, String> taskWithProcessName = new Map<Id, String>();

        for (Task singleTask : newQATasks.values()) {
            String taskComment = singleTask.Description;
            if (taskComment.indexOf('Process:') > -1) {
                string n = taskComment.substring (taskComment.indexOf('Process:'), taskComment.length());
                String regex = 'Process:';
                Pattern regexPattern = Pattern.compile(regex);
                Matcher regexMatcher = regexPattern.matcher(n);

                String replacedMessage;

                if(regexMatcher.find()) {
                   replacedMessage = n.replaceAll(regex, '').trim();
                }
                taskWithProcessName.put(singleTask.Id, 
                replacedMessage);
            }
        }

        Map<String, String> objectNameQueryFields = new Map<String, String> {
            'Product_Order__c' => 'Assigned_Fulfilment_Owner_For_QA__c, RecordType.Name, Name, Assigned_Fulfilment_Owner__c, Assigned_Social_Owner_For_QA__c, Assigned_Social_Owner__c ',
            'Order__c' => 'Assigned_Campaign_Manager__c, Name, Assigned_Campaign_Manager_For_QA__c,Assigned_Setup_Coordinator__c ',
            'Creative__c' => 'Assigned_Campaign_Manager__c, Name, Assigned_Campaign_Manager_For_QA__c '
        };
        Map<Id, List<QA_Item__c>> existingItems;
        List<QA_Checklist__c> listOfQA = new List<QA_Checklist__c>();
        Map<id, QA_Checklist__c> taskWithCHecklist = new Map<id, QA_Checklist__c>();

        for (String objectName : allObjectTNames) {
 
            if (objectNameQueryFields.get(objectName) != null) {

                Set<Id> nmaps = newQATaskIds.keySet();

                system.debug(objectNameQueryFields.get(objectName));
                String query = 'SELECT Id, ';
                query += objectNameQueryFields.get(objectName);
                query += 'FROM ' + objectName + ' WHERE Id IN ';
                query += ':nmaps';
                datetime myDateTime = datetime.now();
                string mydtstring = mydatetime.format();
                existingItems = objectWithLatestQAItems (nmaps);

                List<sObject> objects = Database.query(query);
                for (sObject obj : objects) {
                    Id taskId = newQATaskIds.get(obj.Id);
                    String checkTeam = taskWithProcessName.get(taskId);
                    QA_Checklist__c taskChecklist; 
                    Task t = newQATasks.get(taskId);
                    if (objectName == 'Product_Order__c') {
                        if (checkTeam == 'Social' || checkTeam == 'Client Revision') // http://dashboard.news.com.au/browse/NXRIII-146
                        {
                            taskChecklist = new QA_Checklist__c (
                                Name = 'Checklist for ' + checkTeam + ' at ' + mydtstring,
                                Team__c = checkTeam, 
                                QA_Manager__c = (Id)obj.get('Assigned_Social_Owner_For_QA__c') != null && obj.get('Assigned_Social_Owner_For_QA__c') != ''? 
                                    (Id)obj.get('Assigned_Social_Owner_For_QA__c') :
                                    t.OwnerId,
                                QA_Performed_For__c = (Id)obj.get('Assigned_Social_Owner__c'));
                        }
                        else {
                            taskChecklist = new QA_Checklist__c (
                                Name = 'Checklist for ' + checkTeam + ' at ' + mydtstring,
                                Team__c = checkTeam, 
                                QA_Manager__c = (Id)obj.get('Assigned_Fulfilment_Owner_For_QA__c')!= null && obj.get('Assigned_Fulfilment_Owner_For_QA__c') != ''? 
                                    (Id)obj.get('Assigned_Fulfilment_Owner_For_QA__c') :
                                    t.OwnerId,
                                QA_Performed_For__c = (Id)obj.get('Assigned_Fulfilment_Owner__c'));
                        
                        }
                        
                        taskChecklist.product_order__c = t.WhatId;
                        listOfQA.add(taskChecklist);
                    }
                    else if (objectName == 'Order__c') {
                        taskChecklist = new QA_Checklist__c (
                            Name = 'Checklist for ' + String.valueOf(obj.get('Name')),
                            Team__c = checkTeam, 
                            QA_Manager__c = (Id)obj.get('Assigned_Campaign_Manager_For_QA__c') != null && obj.get('Assigned_Campaign_Manager_For_QA__c') != ''? 
                                    (Id)obj.get('Assigned_Campaign_Manager_For_QA__c') :
                                    t.OwnerId,
                            //QA_Performed_For__c = (Id)obj.get('Assigned_Campaign_Manager__c'));  //NXRIII-334
                            QA_Performed_For__c = (Id)obj.get('Assigned_Setup_Coordinator__c'));  //NXRIII-334
                        
                        taskChecklist.Campaign_Order__c = t.WhatId;
                        listOfQA.add(taskChecklist);
                    }
                    
                    taskChecklist.Type__c = (checkTeam == 'Client Revision' ? 'Client Revision' : 'Evaluation'); // http://dashboard.news.com.au/browse/NXRIII-146
                    taskWithCHecklist.put(taskId, taskChecklist);
                    
                }
            }

            
        }
        if (!listOfQA.isEmpty()) {
            system.debug(listOfQA);
            insert listOfQA;
            CreateQAItemsForChecklists(listOfQA, taskWithProcessName.values(), existingItems);
        }

        Map<id, task> updateTasks = new Map<id, task>([select id, QA_Checklist__c from task where id in: newQATasks.keySet()]);

        for (task tempTask : updateTasks.values()) {
            tempTask.QA_Checklist__c = taskWithCHecklist.get(tempTask.id).Id;
        }

        update updateTasks.values();
    }

    void CreateQAItemsForChecklists (List<QA_Checklist__c> checklists, List<String> teamNames, Map<Id, List<QA_Item__c>> mapExisitngItems) 
    {
        Map<Id, Map<string, QA_Item__c>> existingItems = new map<id, map<string, QA_Item__c>>();
        if (mapExisitngItems != null && !mapExisitngItems.isEmpty()){        for (id objectId : mapExisitngItems.keySet()) {
            Map<string, QA_Item__c> exisItem = new map<string, QA_Item__c>();

            for (QA_Item__c item : mapExisitngItems.get(objectId)) {
                exisItem.put(item.Item__c, item);
            }
            existingItems.put(objectId, exisItem);
        }system.debug('**'+existingItems+'**');}

        List<Checklist__mdt> checklistItems = [SELECT Id, MasterLabel, Checklist_Group__c, Item__c FROM Checklist__mdt WHERE
            Checklist_Group__c IN: teamNames ORDER BY MasterLabel];

        Map<String, List<String>> itemsForGroup = new Map<String, List<String>>();
        if (!checklistItems.isEmpty()) {
            for (Checklist__mdt checkItem : checklistItems) {
                List<String> items = itemsForGroup.get(checkItem.Checklist_Group__c);
                if (items == null)
                    items = new List<String>();

                items.add(checkItem.Item__c);
                itemsForGroup.put(checkItem.Checklist_Group__c, items);
            
            } 
            List<QA_Item__c> qaItems = new List<QA_Item__c>();

            for (QA_Checklist__c qaCheck : checklists) {
                //Map<string, QA_Item__c> exisItem = (qaCheck.Product_Order__c != null) ? existingItems.get(qaCheck.Product_Order__c) : existingItems.get(qaCheck.Campaign_Order__c);
				
				Map<string, QA_Item__c> exisItem = (qaCheck.Product_Order__c != null && qaCheck.Product_Order__r.Reset_QA_Items__c == 'No') ?
														existingItems.get(qaCheck.Product_Order__c) : ((qaCheck.Campaign_Order__c != null && qaCheck.Campaign_Order__r.Reset_QA_Items__c == 'No') ? 
																existingItems.get(qaCheck.Campaign_Order__c) : new Map<string, QA_Item__c>());


                List<String> allItems = itemsForGroup.get(qaCheck.Team__c);
                if (allItems != null && !allItems.isEmpty()) {
                    for (String item : allItems) {
                        
                        QA_Item__c singleitem = new QA_Item__c (    
                            Item__c = item,
                            QA_Checklist__c = qaCheck.Id);
                            //system.debug('**'+exisItem.containsKey(item)+'**');
                        if (exisItem != null && exisItem.containsKey(item) && exisItem.get(item).Result__c == 'Pass') {
                            singleitem.Result__c = exisItem.get(item).Result__c;
                            singleitem.Note__c = exisItem.get(item).Note__c;
                            system.debug('**'+singleitem+'**');
                        }
                        qaItems.add(singleitem);
                    }
                }
            }
            if (qaItems != null && !qaItems.isEmpty())
                insert qaItems;
            }
        }
}