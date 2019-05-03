global without sharing class AT_SalesOrderEscalationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	global void execute(SchedulableContext sc){
        AT_SalesOrderEscalationBatch batch = new AT_SalesOrderEscalationBatch(null, null);
        
        Database.executeBatch(batch, 10);
    }

    private static final Map<Id, User> userIdMap = new Map<Id, User>([select Id, IsActive, Username, Name, DelegatedApproverId, Delegation_Start__c, Delegation_End__c from User WHERE IsActive = true]);
    
    global Datetime now;
    
    global class Reminder {
        public Id salesOrderID;
        public String CC;
        
        public Reminder(Id salesOrderID, String CC) {
            this.salesOrderID = salesOrderID;
            this.CC = CC;
        }
    }
    
    global List<Reminder> reminders = new List<Reminder>();
    
    global List<Id> escalations = new List<Id>();
    
    global Map<String, CPQ_Approver__c> approverMap = new Map<String, CPQ_Approver__c>();
    
    global Map<String, CPQ_Escalation_Rule__mdt> ruleMap = new Map<String, CPQ_Escalation_Rule__mdt>();
    
    //global EmailTemplate reminderTemplate;
   // global EmailTemplate escalationTemplate;
    
    global String salesOrderName = null;
    
    private User integrationUser = null;
    
    //private Map<Id, Id> salesOrderApprovers = new Map<Id, Id>();
    
    global static void run(Integer hour, Integer minute, Integer day, Integer month, Integer year, String salesOrderName) {
        DateTime timestamp = DateTime.newInstance(year, month, day, hour, 0, 0);
        
        AT_SalesOrderEscalationBatch batch = new AT_SalesOrderEscalationBatch(timestamp, salesOrderName);
        
        Id batchJobId = Database.executeBatch(batch, 10);
        
        
        System.debug('Batch ID: ' + batchJobId);
    }
    
    global AT_SalesOrderEscalationBatch(Datetime timestamp, String salesOrderName) {
        if (timestamp != null) {
            now = timestamp;
        } else {
            now = At_SalesOrderApprovals.localNow;
        }
        
        this.salesOrderName = salesOrderName;
        
        System.debug('Timestamp: ' + timestamp + ', Now: ' +  now + ' (' + At_SalesOrderApprovals.localNow + ')');
        
        //reminderTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SO_Approver_Reminder'];
        //escalationTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SO_Approver_Notification'];
        
        integrationUser = [SELECT Id FROM User WHERE LastName = 'Integrator' AND FirstName = ''];
        
        for (CPQ_Approver__c app: [SELECT Sales_Rep__c, Platform__c, L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c FROM CPQ_Approver__c]) {
            approverMap.put(app.Sales_Rep__c + '|' + app.Platform__c, app);
        }
        
        for (CPQ_Escalation_Rule__mdt rule: [SELECT DeveloperName, Reminder_1__c, Reminder_2__c, Reminder_3__c, Reminder_4__c, Reminder_5__c, Escalation_1__c, Escalation_2__c, Escalation_3__c FROM CPQ_Escalation_Rule__mdt]) {
            ruleMap.put(rule.DeveloperName, rule);
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String status = 'Sent for Internal Approval';
        
        System.debug('Sales Order: ' + salesOrderName);
        
        //System.debug('Reminder template: ' + reminderTemplate);
        
        System.debug('Timestamp: ' +  now + ' (' + At_SalesOrderApprovals.localNow + ')');
        
        System.debug('SELECT Id FROM csmso__Sales_Order__c WHERE (csmso__Status__c = :status) AND (((Reminder_Time__c != null) AND (Reminder_Time__c <= \'' + now + '\')) OR ((Escalation_Time__c != null) AND (Escalation_Time__c <= \'' + now + '\') AND (Name = \'' + salesOrderName + '\')');
        
        if (salesOrderName != null) {
        	return Database.getQueryLocator([SELECT Id FROM csmso__Sales_Order__c WHERE (csmso__Status__c = :status) AND (((Reminder_Time__c != null) AND (Reminder_Time__c <= :now)) OR ((Escalation_Time__c != null) AND (Escalation_Time__c <= :now))) AND (Approver1_Level__c != null) AND (Name = :salesOrderName)]);
        } else {
            return Database.getQueryLocator([SELECT Id FROM csmso__Sales_Order__c WHERE (csmso__Status__c = :status) AND (((Reminder_Time__c != null) AND (Reminder_Time__c <= :now)) OR ((Escalation_Time__c != null) AND (Escalation_Time__c <= :now))) AND (Approver1_Level__c != null)]);
        }
    }
    
    global void execute(Database.BatchableContext BC, List<csmso__Sales_Order__c> scope) {
        System.debug('Scope: ' + scope);
        
        System.debug('Timestamp: ' +  now + ' (' + At_SalesOrderApprovals.localNow + ')');
        
        List<csmso__Sales_Order__c> orders = [SELECT Id, Name, Approval_Submission_Timestamp__c, Escalation_Rule__c, Reminder_Time__c, Reminder_Step__c, Escalation_Time__c, Escalation_Step__c, Approver1__c, Approver1_Level__c, Approver1_Platform__c, Approver2__c, Approver2_Level__c, Approver2_Platform__c, Approval_Step__c, OwnerId FROM csmso__Sales_Order__c WHERE Id IN :scope FOR UPDATE];
        
        Map<Id, ProcessInstanceWorkItem> workItemMap = new Map<Id, ProcessInstanceWorkItem>();
        
        for (ProcessInstanceWorkItem wi: [SELECT ProcessInstance.TargetObjectId, ActorId FROM ProcessInstanceWorkItem WHERE (ProcessInstance.TargetObjectId IN :scope) AND (ProcessInstance.Status = 'Pending')]) {
            workItemMap.put(wi.ProcessInstance.TargetObjectId, wi);
        }
        
        List<ProcessInstanceWorkItem> escalatedApprovals = new List<ProcessInstanceWorkItem>();
        List<ProcessInstanceWorkItem> reminderApprovals = new List<ProcessInstanceWorkItem>();
        
        for(csmso__Sales_Order__c so: orders) {
            System.debug('Sales Order: ' + so);
            
            CPQ_Escalation_Rule__mdt rule = ruleMap.get(so.Escalation_Rule__c);
            
            if (rule == null) {
                System.debug('No rule found');
                continue;
            }

			System.debug('Rule: ' + rule.DeveloperName);
            
            Integer step = so.Reminder_Step__c.intValue();
            
            System.debug('Reminder Step: ' + so.Reminder_Step__c.intValue() + ', Escalation Step: ' + so.Escalation_Step__c.intValue());
            System.debug('Reminder Time: ' + so.Reminder_Time__c + ', Escalation Time: ' + so.Escalation_Time__c);
            
            try {
                List<String> ruleParts = ((String)rule.get('Reminder_' + step + '__c')).split('\\|');
                
                if (so.Reminder_Time__c <= now) {
                    reminders.add(new Reminder(so.Id, (ruleParts.size() > 2) ? ruleParts[2] : null));
                 
                    System.debug('Adding reminder: ' + new Reminder(so.Id, (ruleParts.size() > 2) ? ruleParts[2] : null));
                    
                    so.Reminder_Step__c += 1;
                    so.Reminder_Time__c = AT_SalesOrderApprovals.nextReminder(rule, so.Approval_Submission_Timestamp__c, so.Reminder_Step__c.intValue());
                    
                    so.Escalation_Note__c = '[REMINDER] ';
                    
                    ProcessInstanceWorkItem workItem = workItemMap.get(so.Id);
                    
                    workItem.ActorId = integrationUser.Id;
                    
                    reminderApprovals.add(workItem);
                    
                    System.debug('Next reminder: ' + so.Reminder_Time__c);
                } else {
                    System.debug('Riminder time hasn\'t passed');
                }
            } catch (System.SObjectException e) {}
            
            step = so.Escalation_Step__c.intValue();
            
            try {
                List<String> ruleParts = ((String)rule.get('Escalation_' + step + '__c')).split('\\|');
                
                System.debug('Approval Step: ' + so.Approval_Step__c);
                
                System.debug('App1: ' + so.Approver1_Level__c +', App2: ' + so.Approver2_Level__c);
                
                Decimal appLevel = ((so.Approval_Step__c == 1) ? so.Approver1_Level__c : so.Approver2_Level__c);
                
                if (appLevel == null) continue;
                
              	Integer level = appLevel.intValue();
                String platform = (so.Approval_Step__c == 1) ? so.Approver1_Platform__c : so.Approver2_Platform__c;
                
                System.debug('Platform: ' + platform + ', Level: ' + level);
                
                if ((level < AT_SalesOrderApprovals.ApproverLevels) && (so.Escalation_Time__c <= now)) {
                    System.debug('Adding reminder: ' + so.Id);
                    
                    CPQ_Approver__c appr = approverMap.get(so.OwnerId + '|' + platform);
                    
                    Id appUserID = (Id)appr.get('L' + (level + 1) + '_Approver__c');
                    
                    if (appUserID != null) appUserID = AT_SalesOrderApprovals.getUser(appUserID, userIdMap).Id;
                 
                    System.debug('Approver User ID: ' + appUserID);
                    
                    Id nextAppID = null;
                    
                    if ((level + 2) < AT_SalesOrderApprovals.ApproverLevels) nextAppID = (Id)appr.get('L' + (level + 2) + '_Approver__c');
                    
                    if (appUserID != null) {
                        escalations.add(so.Id);
                        
                        if (so.Approval_Step__c == 1) {
                            so.Approver1_Level__c = (level + 1);
                            so.Approver1__c = appUserID;
                        } else {
                            so.Approver2_Level__c = (level + 1);
                            so.Approver2__c = appUserID;
                        }
                        
                        so.Escalation_Note__c = '[ESCALATION] ';
                        
                        ProcessInstanceWorkItem workItem = workItemMap.get(so.Id);
                    
                        workItem.ActorId = appUserID;
                        
                        escalatedApprovals.add(workItem);
                        
                        so.Escalation_Step__c += 1;

                        if (nextAppID != null) {
                            so.Escalation_Time__c = AT_SalesOrderApprovals.nextEscalation(rule, so.Approval_Submission_Timestamp__c, so.Escalation_Step__c.intValue());
                            
                            System.debug('Next Escalation: ' + so.Escalation_Time__c);
                        } else {
                        	so.Escalation_Time__c = null;
                            
                            System.debug('No Next Escalation');
                        }
                    } else {
                        so.Escalation_Step__c += 1;
                        so.Escalation_Time__c = null;
                    }
                    
                    
                } else {
                    System.debug('Escalation time hasn\'t passed');
                }
            } catch (System.SObjectException e) {}
        }
        
        update orders;
        
        update reminderApprovals;
        
        update escalatedApprovals;
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('Finished');
        
        Set<Id> orderIDs = new Set<Id>();
        
        //System.debug('Escalations: ' + orderIDs);
        
        //System.debug('Reminders: ' + reminders);
        
        List<ProcessInstanceWorkItem> reminderApprovals = new List<ProcessInstanceWorkItem>();
        
        for (Reminder rem: reminders) orderIDs.add(rem.salesOrderID);
        
        Map<Id, ProcessInstanceWorkItem> workItemMap = new Map<Id, ProcessInstanceWorkItem>();
        
        for (ProcessInstanceWorkItem wi: [SELECT ProcessInstance.TargetObjectId, ActorId FROM ProcessInstanceWorkItem WHERE (ProcessInstance.TargetObjectId IN :orderIDs) AND (ProcessInstance.Status = 'Pending')]) {
            workItemMap.put(wi.ProcessInstance.TargetObjectId, wi);
        }
        
        Map<Id, csmso__Sales_Order__c> orderMap = new Map<Id, csmso__Sales_Order__c>([SELECT Id, Approval_Submission_Timestamp__c, Escalation_Rule__c, Reminder_Time__c, Reminder_Step__c, Escalation_Time__c, Escalation_Step__c, Approver1__c, Approver1_Level__c, Approver1_Platform__c, Approver2__c, Approver2_Level__c, Approver2_Platform__c, Approval_Step__c, OwnerId FROM csmso__Sales_Order__c WHERE Id IN :orderIDs]);
        
		//List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (Reminder rem: reminders) {
            csmso__Sales_Order__c so = orderMap.get(rem.salesOrderID);
            
            Id approverID = (so.Approval_Step__c == 1) ? so.Approver1__c : so.Approver2__c;
            
            ProcessInstanceWorkItem workItem = workItemMap.get(so.Id);

            workItem.ActorId = approverID;
            
            reminderApprovals.add(workItem);
            
            /*Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(reminderTemplate.Id, approverID, so.Id);
                
            if (rem.CC != null) email.setCcAddresses(new List<String>{rem.CC});
            
            email.setSaveAsActivity(false);
            
            emails.add(email);*/
        }
        
        update reminderApprovals;
        
        /*for (Id soID: escalations) {
            csmso__Sales_Order__c so = orderMap.get(soID);
            
            Id approverID = (so.Approval_Step__c == 1) ? so.Approver1__c : so.Approver2__c;
            
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(escalationTemplate.Id, approverID, so.Id);
                
            email.setSaveAsActivity(false);
            
            //emails.add(email);
        }*/
        
        //System.debug('Emails: ' + emails.size());
        
        //Messaging.sendEmail(emails);
    }
}