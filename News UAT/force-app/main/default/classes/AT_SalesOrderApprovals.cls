/*
    Utility class for CloudSense to call from the Sales Order custom VF page.
*/
public without sharing class AT_SalesOrderApprovals {
    public final static DateTime localNow = convertToLocalTZ(System.now());
    
    public static final Integer ApproverLevels = 4;
    
    public enum Platform {Print, Digital, Xtend, Threshold}
    
    public enum Status {Pending, Accepted, Rejected}
    
    public enum ApproverType {Found, NotFound, SameLevel}
    
    public enum AllowedAction {Recall, Approve, Reject}
    
    /*
        Generic result class.

        Returns:
        - success: set to true if the operation completed without any failures.
        - message: contains either an error message if the operation failed, or informational message if it was successful.
     */ 
    public virtual class Result {
        public Boolean success;
        
        public String message;
    }
    
    /*
        Return value after submitting for approval.

        As well as the general success and message values, it also returns the approvers assigned to the sales order for each platform and level of approval.
    */ 
    public class SubmissionResult extends Result {
        // The approvers for each product platform
        public List<PlatformApprover> approvers;
    }
    
    /*
        Pair of product platform and approval level for finding an appropriate approver
    */
    public class PlatformLevel {
        public Platform platform{get;set;}
        public Integer level{get;set;}
        
        public PlatformLevel() {}
        
        public PlatformLevel(Platform platform, Integer level) {
            this.platform = platform;
            this.level = level;
        }
    }
    
    /*
        Return value when trying to find an approver for a given product platform and level.
    */
    public class PlatformApprover implements Comparable {
        public Platform platform{get;set;}
        public Integer level{get;set;}
        public ApproverType type{get;set;}
        public User approver{get;set;}
        
        public Integer compareTo(Object obj) {
            PlatformApprover that = (PlatformApprover)obj;
            
            if (this.level < that.level)
                return -1;
            else if (this.level > that.level)
                return 1;
            else
                return 0;
        }
    }
    
    /*
        Return value for status of sales order in the approval pipeline.
    */
    public class PlatformApproval {
        public Platform platform;
        public User approver;
        public Status status;
        
        
    }
    
    
    public class SalesOrderStatus {
        // True if the sales order has been submitted for approval
        public boolean isSubmitted;
        
        // Approval status for each product platform in this order
        public Map<Platform, ApprovalStatus> platformStatus;
    }
    
    public class ApprovalStatus {
        // Submitted, Approved, or Rejected
        public Status status;
        
        // Comments entered by the user when actioning an approval step
        public String comments;
    }

    public String salesOrderRecordID {get; set;}
    
    public AT_SalesOrderApprovals() {}
    
    ////////////////////////////////////////
    
    /*
     * Check the approvers matrix to see if there is an assigned user for the required approval level.
     * 
     * If this returns false, then no approval is needed (don't show message and request approval button)
     */
    public static boolean requiresApproval(Id salesOrderId) {
        csmso__Sales_Order__c sOrder = [Select Id, Platform_Set__c, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c 
                                        from csmso__Sales_Order__c where Id=: salesOrderId];
        List<String> platforms = new List<String>();
        String platform = sOrder.Platform_Set__c.replace('{}','');
        platforms = platform.split(',');
        
        List<PlatformLevel> platformLevels = new List<PlatformLevel>();
        
        
        for (String pl: platforms) {
            
            if(sOrder.Print_Display_MAX_PPT_Level__c > 0){
                platformLevels.add(new PlatformLevel(AT_SalesOrderApprovals.Platform.Threshold, sOrder.Print_Display_MAX_PPT_Level__c.intValue()));
            }
            if(sOrder.Print_Display_Approval_Level__c > 0){
                platformLevels.add(new PlatformLevel(AT_SalesOrderApprovals.Platform.Print, sOrder.Print_Display_Approval_Level__c.intValue()));
            }
        }
        
        
        System.debug('PL: ' + platformLevels);
        
        List<PlatformApprover> approvers = findApprovers(platformLevels, salesOrderId);

        System.debug('Approvers: ' + approvers);
        
        if (approvers == null) return true;
        
        if (approvers.isEmpty()) return false;
        
        return true;
    }
    
    
    // CloudSense to use this function to get the URL to redirect to in order to request approval of sales order
    public static PageReference requestApproval(Id salesOrderId) {
        System.debug('Requesting approval from SO Page');
        
        csmso__Sales_Order__c sOrder = [Select Id, Platform_Set__c, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c from csmso__Sales_Order__c where Id=: salesOrderId];
        List<String> platforms = new List<String>();
        String platform = sOrder.Platform_Set__c.replace('{}','');
        platforms = platform.split(',');
        System.debug('---' +platforms);
        System.debug('***' +platform);
        
        PageReference ref = new PageReference('/apex/AT_SalesOrderApprovals');
        
        ref.setRedirect(true);
        
        Map<String, String> params = ref.getParameters();
        
        // pass the sales order ID to the new screen
        params.put('id', salesOrderId);
        
        // include each platform and level pair in the parameter list as well
        for (String pl: platforms) {
            //pl == 'Print' && 
            if(sOrder.Print_Display_MAX_PPT_Level__c > 0){
                params.put('platform-Threshold', String.valueOf(sOrder.Print_Display_MAX_PPT_Level__c.intValue()));
            }
            //pl == 'Print' && 
            if(sOrder.Print_Display_Approval_Level__c > 0){
                params.put('platform-Print', String.valueOf(sOrder.Print_Display_Approval_Level__c.intValue()));
            }
        }
        System.debug('++Print Reference' + ref);
        
        /* for example, the resulting URL reference should look something like this:
            /apex/AT_SalesOrderApproval?id=a0xxxxxxxxxxxxx&platform-Print=1&platform-Digital=2

            The VisualForce controller should then read these parameters to pass the right data into the functions below
        */
        return ref;
    }
    
    /*
        Retrieve the approval status for a sales order, to display on screen.
    */
    public static SalesOrderStatus getApprovalStatus(Id salesOrderID) {
        SalesOrderStatus sos = new SalesOrderStatus();
        
        return null;
    }
    
    /*
        Find the users who will be assigned as approvers for each product platform for a sales order

        Use this to display the approvers/queue on screen after requesting approval
    */
    public static List<PlatformApprover> findApprovers(List<PlatformLevel> platformLevels, Id SalesOrderId) {
        List<PlatformApprover> platformApprovers = new List<PlatformApprover>();
        
        Set<String> platforms = new Set<String>();
        
        csmso__Sales_Order__c sOrder = [Select Id, OwnerId, csmso__Opportunity__r.OwnerId, Opportunity_Owner_Email__c from csmso__Sales_Order__c where Id =: salesOrderId];
        
        System.debug('Sales Order: ' + sOrder);
        
        User salesRep = [SELECT Id, Email, Name FROM User WHERE Id = :sOrder.OwnerId];
        
        for (PlatformLevel pl: platformLevels) {
            //platforms.put(pl.platform.name(), pl.level);
            platforms.add(pl.platform.name());
        }
        
        // Query CPQ_Approver__c for each platform-level record
        Map<String, CPQ_Approver__c> platformApproverMap = new Map<String, CPQ_Approver__c>();
        
        for (CPQ_Approver__c approver : [SELECT Id, Platform__c, L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c, Sales_Rep__c
                                        FROM CPQ_Approver__c
                                        WHERE Platform__c IN :platforms and Sales_Rep__c =: salesRep.Id]) {
       		platformApproverMap.put(approver.Platform__c, approver);
		}
        
        System.debug('CPQ Approvers:');
        System.debug(platformApproverMap);

        if (platformApproverMap.keySet().isEmpty()) return null;
       
        Map<Id, User> userIdMap = new Map<Id, User>([select Id, IsActive, Username, Name, DelegatedApproverId, Delegation_Start__c, Delegation_End__c from User WHERE IsActive = true]);
       
        Set<Id> approverIDs = new Set<Id>();
        
        Integer ppaLevel = 0, pptLevel = 0;
        
        for(PlatformLevel pl: platformLevels){
            CPQ_Approver__c appr = platformApproverMap.get(pl.platform.name());
            
            if (appr == null) continue;
            
            PlatformApprover pa = new PlatformApprover();
            
            if (appr.Platform__c == 'Print') {
              	pa.platform = Platform.Print;
                
                ppaLevel = pl.level;
            } else if(appr.Platform__c == 'Threshold'){
                pa.platform = Platform.Threshold;
                
                pptLevel = pl.level;
            }
            
            pa.level = pl.level;

            String appUser = ((String)appr.get('L' + pa.level + '_Approver__c'));
            
            if (appUser == null) {
                pa.type = ApproverType.NotFound;
            } else if (appUser == salesRep.Id) {
                pa.type = ApproverType.SameLevel;
            } else {
                pa.type = ApproverType.Found;
                pa.approver = getUser(appUser, userIdMap);
            }
            
            //if ((pa.approver != null) && !approverIDs.contains(pa.approver.Id)) {
                platformApprovers.add(pa);
                
            	if (pa.approver != null) approverIDs.add(pa.approver.Id);
            //}
        }
        

        if (ppaLevel >= pptLevel) {
            for (Integer i = 0; i < platformApprovers.size(); i++) {
                if (platformApprovers[i].platform == Platform.Threshold) {
                    platformApprovers.remove(i);
                }
            }
        }         
        
        System.debug('Approvers: ' + platformApprovers.size());
        System.debug(platformApprovers);
        
        return platformApprovers;
    }
    
    public static Set<Id> findApproversBelow(List<PlatformLevel> platformLevels, Id SalesOrderId) {
        Set<Id> approvers = new Set<Id>();
        
        
        
        ////Map<String, Integer> platforms = new Map<String, Integer>();
        Set<String> platforms = new Set<String>();
        
        csmso__Sales_Order__c sOrder = [Select Id, OwnerId, csmso__Opportunity__r.OwnerId, Opportunity_Owner_Email__c from csmso__Sales_Order__c where Id =: salesOrderId];
        
        System.debug('Sales Order: ' + sOrder);
        System.debug('Platform Levels: ' + platformLevels);
        
        User salesRep = [SELECT Id, Email, Name FROM User WHERE Id = :sOrder.OwnerId];
        
        for (PlatformLevel pl: platformLevels) {
            platforms.add(pl.platform.name());
        } 
        
        Map<String, CPQ_Approver__c> platformApproverMap = new Map<String, CPQ_Approver__c>();
        
        for (CPQ_Approver__c approver : [SELECT Id, Platform__c, L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c, Sales_Rep__c
                                        FROM CPQ_Approver__c
                                        WHERE Platform__c IN :platforms and Sales_Rep__c =: salesRep.Id]) {
       		platformApproverMap.put(approver.Platform__c, approver);
		}
        
        System.debug('CPQ Approvers:');
        System.debug(platformApproverMap);
        
        if (platformApproverMap.isEmpty()) return null;                             
       
        Map<Id, User> userIdMap = new Map<Id, User>([select Id, IsActive, Username, Name, DelegatedApproverId, Delegation_Start__c, Delegation_End__c from User WHERE IsActive = true]);
       
        for(PlatformLevel pl: platformLevels){
            CPQ_Approver__c appr = platformApproverMap.get(pl.platform.name());

			System.debug(pl.platform.name() + ' -> ' + appr);
            
            if (appr == null) continue;
            
            for (Integer level = (pl.level - 1); level > 0; level--) {
                String appUser = ((String)appr.get('L' + level + '_Approver__c'));
                
                if (appUser != null) appUser = getUser(appUser, userIdMap).Id;
                
                if ((appUser != null) && (appUser != salesRep.Id)) approvers.add(appUser);
            }
        }
                
        return approvers;
    }
    
    /*
     * Return the user record of either the mapped approver, or the user to which they have delegated to
     */ 
    public static User getUser(Id userID, Map<Id, User> userMap) {
        User u = userMap.get(userID);
        
        //System.debug('Finding approver for: ' + u.Name);
        
        if ((u.DelegatedApproverId != null) && // Is there a delegated approver for this user?
            (u.Delegation_Start__c != null) && // Is there a defined start date?
            (u.Delegation_End__c != null) &&  // Is there a defined end date? (both start and end dates are required)
            (u.Delegation_Start__c <= System.Today()) && // Is the start date earlier or equal to today?
            (u.Delegation_End__c >= System.Today())) // Is the end date after or equal to today?
        {
            User delegatedApprover = userMap.get(u.DelegatedApproverId);
            
            //System.debug('Found delegated approver: ' + delegatedApprover.Name);
            
            // If all the above conditions are met and and the delegated approver user record is active
            // then return the delegated approver
            if (delegatedApprover.IsActive) return delegatedApprover;
       	}
        
        // otherwise return the original mapped approver
        return u;
    }
    
    /*
        Submit the sales order for approval, and return the users assigned as approvers for each product platform.

        CloudSense need to have their own logic for determining wether a Sales Order is valid for submissions.
        This function will assume that any sales order ID passed to it can be approved.

        If the "success" field is set to false that means that an appropriate approver could not be found for one of the product platforms.
        Loop through each of the "approvers" items and find the ones where "ApproverType" is set to "NotFound" to display which platform could not be assigned.
    */
    public static PageReference submitForApproval(Id salesOrderId, List<PlatformLevel> platformLevels, String reason, String comments) {
        
        // Has the sales order been successfuly submitted for approval
        Boolean success;
        
        // call findApprovers
        // if any one of the approver types is NotFound, set success to false, and return
        
        // The approvers for each product platform
        List<PlatformApprover> approvers = findApprovers(platformLevels, salesOrderId);
        system.debug('--Approvers in SUbmit for Approval' +approvers);
        csmso__Sales_Order__c sOrder = [Select Id, Opportunity_Owner_Email__c, OwnerId, csmso__Opportunity__r.OwnerId, Platform_Set__c, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c,Approver1__c, Approver2__c, Approver2_Platform__c,Approver1_Platform__c, Approval_Submission_Reason__c, Approval_Submission_Comments__c from csmso__Sales_Order__c where Id=: salesOrderId];
        
        User salesRep = [SELECT Id, Email, Name FROM User WHERE Id = :sOrder.csmso__Opportunity__r.OwnerId];
        
        List<csmso__Sales_Order__c> sOrderList = new List<csmso__Sales_Order__c>();
        
        List<PlatformApprover> approverUsers = new List<PlatformApprover>();
        
        System.debug('Approvers: ' + approvers);
        
        for (PlatformLevel pl:  platformLevels) {
            PlatformApprover appr = getApproverForPlatformAndLevel(approvers, pl.Platform, pl.Level);
            
            if ((appr != null) && (appr.type == ApproverType.Found)) approverUsers.add(appr);
        }
        
        System.debug('Approver Users: ' + approverUsers);
        
        for (Integer i = 0; i < approverUsers.size(); i++) {
            sOrder.put('Approver' + (i + 1) + '_Platform__c', approverUsers[i].Platform.name());
            sOrder.put('Approver' + (i + 1) + '__c', approverUsers[i].approver.Id);
            sOrder.put('Approver' + (i + 1) + '_Level__c', approverUsers[i].level);
            
            //System.debug('Approver' + (i + 1) + '_Platform__c: ' + approverUsers[i].Platform.name());
            //System.debug('Approver' + (i + 1) + '__c: ' + approverUsers[i].approver.Id);
        }
        
        if (approverUsers.isEmpty()) return null;

		sOrder.Approval_Submission_Timestamp__c = System.Now();
        
        sOrder.Approval_Submission_Reason__c = reason;
        sOrder.Approval_Submission_Comments__c = comments;
        
        sOrder.Approval_Steps__c = platformLevels.size();
        sOrder.Approval_Step__c = 1;
        
        sOrder.Reminder_Step__c = 1;
        sOrder.Escalation_Step__c = 1;
        
        CPQ_Escalation_Rule__mdt escRule = findEscalationRule(localNow);
        
        System.debug(escRule);
        
        Id nextApproverID = nextApprover(sOrder.OwnerId, sOrder.Approver1_Platform__c, sOrder.Approver1_Level__c.intValue() + 1);
        
        if (escRule != null) {
            sOrder.Escalation_Rule__c = escRule.DeveloperName;
            sOrder.Reminder_Time__c = nextReminder(escRule, System.now(), 1);
            
            if (nextApproverID != null) {
                sOrder.Escalation_Time__c = nextEscalation(escRule, System.now(), 1);
            } else {
                sOrder.Escalation_Time__c = null;
            }
        }
        
        update sOrder;

        
        // Create an approval request for the account
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments(comments);
        request.setObjectId(salesOrderID);

        // Submit on behalf of a specific submitter - Sales rep from CPQ approver object
        request.setSubmitterId(salesRep.Id);

        
        if (platformLevels.size() == 1) {
            request.setProcessDefinitionNameOrId('SO_Approvals');
        } else {
            request.setProcessDefinitionNameOrId('SO_Approvals_Multistep');
        }
        
        request.setSkipEntryCriteria(true);
            
            
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(request, true);
        PageReference pg = redirectSO(result, salesOrderId);
        System.debug(result);
        
        String instanceId = result.getInstanceId();
        System.debug('--InstanceId' + instanceId);

        List<ProcessInstanceWorkitem> workItems = [Select Id, ActorID FROM ProcessInstanceWorkitem WHERE ProcessInstanceId = :instanceId];
        
        if (!workItems.isEmpty()) sOrder.Approval_Process_Id__c = workItems[0].Id;

        Set<Id> otherApprovers = findApproversBelow(platformLevels, sOrder.Id);
        
        for (PlatformApprover pa: approverUsers) {
            if (pa.approver != null) otherApprovers.remove(pa.approver.Id);
        }
        
        if (!otherApprovers.isEmpty()) {
            EmailTemplate template = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SO_Approver_FYI'];
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            for (Id approverID: otherApprovers) {
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(template.Id, approverID, sOrder.Id);
                
                email.setSaveAsActivity(false);
                
            	emails.add(email);
            }
            
            Messaging.sendEmail(emails);
        }
        
        
        update sOrder;
       
        return pg;
    }
    
    public static DateTime convertToLocalTZ(DateTime dt) {
        Integer offset = UserInfo.getTimezone().getOffset(dt);
        Datetime local = dt.addSeconds(offset/1000);
        
        return local;
    }
    
    public static DateTime convertToGMT(DateTime dt) {
        Integer offset = UserInfo.getTimezone().getOffset(dt);
        Datetime gmt = dt.addSeconds(-(offset/1000));
        
        return gmt;
    }
    
    public static DateTime addDays(DateTime dt, Integer days) {
        DateTime newDT = dt.addDays(0);
        
        for (Integer day = 1; day <= days; day++) {
            newDT = newDT.addDays(1);
                
            String dayOfWeek = newDT.format('E');
            
            if ((dayOfWeek == 'Sat') || (dayOfWeek == 'Sun')) newDT = newDT.addDays(2);
        }
        
        return newDT;
    }

    public static Id nextApprover(Id salesRepId, String platform, Integer level) {
        if (level > ApproverLevels) return null;
        
        List<CPQ_Approver__c> approvers = [SELECT L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c FROM CPQ_Approver__c WHERE (Sales_Rep__c = :salesRepId) AND (Platform__c = :platform)];
        
        if (approvers.isEmpty()) return null;
        
        Id approverID = (Id)approvers[0].get('L' + level + '_Approver__c');
        
        return approverID;
    }
    
    public static DateTime nextEscalation(CPQ_Escalation_Rule__mdt escRule, DateTime submission, Integer step) {
        System.debug('Escalation rule: ' + escRule);
        
        DateTime submitLocalTZ = convertToLocalTZ(submission);
        
        System.debug('Submission: ' + submission + ', Local TZ: ' + submitLocalTZ);
        
        try {
            String rule = (String)escRule.get('Escalation_' + step + '__c');
            
            if (rule != null) {
                List<String> parts = rule.split('\\|');
                
                System.debug(parts);
                
                Integer days = Integer.valueOf(parts[0]);
                Time escTime = parseTime(parts[1]);
                
                System.debug('Escalation time: ' + escTime);
                
                DateTime escDay = addDays(submission, days);
                
                /*String dayOfWeek = escDay.format('E');
                
                System.debug('Day of week: ' + dayOfWeek);
                
                if ((dayOfWeek == 'Sat') || (dayOfWeek == 'Sun')) escDay = escDay.addDays(2);*/
                
                System.debug('Next escalation: ' + DateTime.newInstanceGMT(escDay.date(), escTime));
                
                System.debug('Next escalation GMT: ' + convertToGMT(DateTime.newInstanceGMT(escDay.date(), escTime)));
                
                return convertToGMT(DateTime.newInstanceGMT(escDay.date(), escTime));
            }
        } catch (System.SObjectException e) {}
        
        return  null;
    }
    
    public static DateTime nextReminder(CPQ_Escalation_Rule__mdt escRule, DateTime submission, Integer step) {
        DateTime submitLocalTZ = convertToLocalTZ(submission);
        
        try {
            String rule = (String)escRule.get('Reminder_' + step + '__c');
            
            if (rule != null) {
                List<String> parts = rule.split('\\|');
                
                System.debug(parts);
                
                Integer days = Integer.valueOf(parts[0]);
                Time escTime = parseTime(parts[1]);
                
                DateTime escDay = addDays(submission, days);
                
                /*String dayOfWeek = escDay.format('E');
                
                if ((dayOfWeek == 'Sat') || (dayOfWeek == 'Sun')) escDay = escDay.addDays(2);*/
                
                return convertToGMT(DateTime.newInstanceGMT(escDay.date(), escTime));
            }
        } catch (System.SObjectException e) {}
        
        return  null;
    }
    
    public static CPQ_Escalation_Rule__mdt findEscalationRule(DateTime dt) {        
        System.debug('Finding rule: ' + dt.timeGMT());
        
        for (CPQ_Escalation_Rule__mdt rule: [SELECT CutOff__c, DeveloperName, Escalation_1__c, Escalation_2__c, Escalation_3__c, Reminder_1__c, Reminder_2__c, Reminder_3__c, Reminder_4__c, Reminder_5__c  FROM CPQ_Escalation_Rule__mdt]) {
            System.debug('Rule: ' + rule);
            
            if (rule.CutOff__c.startsWith('<')) {
                Time cutoff = parseTime(rule.CutOff__c.substring(1));
                System.debug('Cutoff: '  + cutoff);
                if (dt.timeGMT() < cutOff) return rule;
            } else {
                Time cutoff = parseTime(rule.CutOff__c.substring(2));
                System.debug('Cutoff: '  + cutoff);
                if (dt.timeGMT() >= cutOff) return rule;
            }
        }
        
        return null;
    }
    
    public static Time parseTime(String timeText) {
        return Time.newInstance(Integer.valueOf(timeText.substring(0, 2)), Integer.valueOf(timeText.substring(2, 4)), 0, 0);
    }
    
    public static PlatformApprover getApproverForPlatformAndLevel(List<PlatformApprover> approvers, Platform platform, Integer level) {
        PlatformApprover approver = null;
        
        for (PlatformApprover app: approvers) {
            if ((app.Platform == platform) && (app.Level ==level)) approver = app;
        }
            
        return approver;
    }
    
    public static pageReference redirectSO(Approval.ProcessResult result, Id salesOrderId) {
         PageReference page = new PageReference('/'+salesOrderId);
         system.debug('---Result' +result);
         system.debug('---SalesOrderId' +salesOrderId);
         if(result.isSuccess() == true){
             page.setRedirect(true);
         }
         system.debug('---Pageref' +page);
        return page;
    }
    
    /*
    	Check if the current logged in user is the assigned approver for the given Sales Order
    
		Returns true if the user is a valid approver (in which case, show the Approve/Reject buttons).
		If false is returned, then don't show any approval buttons.
    */
    public static Boolean isApprover(Id salesOrderID) {
        csmso__Sales_Order__c sOrder = [Select csmso__Status__c, Approver1__c, Approver2__c, Approval_Step__c from csmso__Sales_Order__c where Id =: salesOrderId];
        
        // Check if the Sales Order has been submitted for approval
        if (sOrder != null && sOrder.csmso__Status__c == 'Sent for Internal Approval') {
            // Check if this is the first approval step and the current user is Approver1
            if (sOrder.Approval_Step__c == 1 && sOrder.Approver1__c == UserInfo.getUserId()) return true;

            // Check if this is the second approval step and the current user is Approver2
            if (sOrder.Approval_Step__c == 2 && sOrder.Approver2__c == UserInfo.getUserId()) return true;
        }
        
        // In all other cases, the current user is not the assigned approver for the Sales Order
        return false;
    }
    
    /*
        Determines wether the current logged in user can recall, approve or reject a given sales order.

        Use this to show or hide the Recall, Accept and Reject buttons.

        If current logged in user can't action this sales order, then an empty list will be returned.
    */
    public static List<AllowedAction> allowedUserActions(Id salesOrderID) {
        // did the current logged in user submit the approval?
        // if so they can recall
        
        // is the current logged in user an assigned approver?
        // if so they can approve or reject

        csmso__Sales_Order__c sOrder = [Select csmso__Status__c, OwnerId, Approver1__c, Approver2__c, Approval_Step__c from csmso__Sales_Order__c where Id =: salesOrderId];
        
        List<AllowedAction> actions = new List<AllowedAction>();
        
        if (sOrder != null && sOrder.csmso__Status__c == 'Sent for Interal Approval') {
            if (sOrder.OwnerId == UserInfo.getUserId()) actions.add(AllowedAction.Recall);
            if (sOrder.Approval_Step__c == 1 && sOrder.Approver1__c == UserInfo.getUserId()) {
                actions.add(AllowedAction.Approve);
                actions.add(AllowedAction.Reject);
            }
            if (sOrder.Approval_Step__c == 2 && sOrder.Approver2__c == UserInfo.getUserId()) {
                actions.add(AllowedAction.Approve);
                actions.add(AllowedAction.Reject);
            }
        }
        
        
        return actions;
    }
    
    public static Result recall(Id salesOrderID) { //Print_Approver__c, Digital_Approver__c
        csmso__Sales_Order__c sOrder = [Select csmso__Status__c  from csmso__Sales_Order__c where Id =: salesOrderId];

        Result ar = new Result();
        Approval.ProcessWorkitemRequest PWR = new Approval.ProcessWorkitemRequest();
        List<ProcessInstanceWorkitem> piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId= :sOrder.Id];
        PWR.setAction('Removed');
        PWR.setWorkitemId(piw[0].id);
        Approval.ProcessResult result =  Approval.process(PWR);
                
        if(result.isSuccess()){
            ar.success = true;
            sOrder.csmso__Status__c = 'Draft';
            update sOrder;
        }
        else{
            Database.Error[] errors = result.getErrors();
            ar.message = 'Error in recalling Sales Order.';
        }
        return ar ;
        
        
    }
    
    /*
        Approve a sales order with optional comments.
    */
    public static Result approve(Id salesOrderID, String comments) { //Print_Approver__c, Digital_Approver__c 
        csmso__Sales_Order__c sOrder = [Select csmso__Status__c from csmso__Sales_Order__c where Id =: salesOrderId];

        Result ar = new Result();
        Approval.ProcessWorkitemRequest PWR = new Approval.ProcessWorkitemRequest();
        List<ProcessInstanceWorkitem> piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId= :sOrder.Id];
        System.debug('---piw' +piw);
        //PWR.setComments(comments);
        PWR.setAction('Approve');
        System.debug('--Process Instance' +piw);
        PWR.setWorkitemId(piw[0].Id);
        Approval.ProcessResult result =  Approval.process(PWR);
                
        if(result.isSuccess()){
            ar.success = true;
            //sOrder.csmso__Status__c = 'Internally Approved';
            //update sOrder;
        }
        else{
            Database.Error[] errors = result.getErrors();
            ar.message = 'Error in submitting Sales Order for approval-approve.';
        }
        return ar ;
    }
    
    public static PageReference rejectSO(Id salesOrderID){
        PageReference page = Page.AT_RejectSalesOrder;
        
        page.setRedirect(true);
        
        Map<String, String> params = page.getParameters();
        
        params.put('id', salesOrderID);
        
        return page;    
    }
    
    public String salesOrderID {get; set;}
    public String comments {get; set;}
    
    public AT_SalesOrderApprovals(ApexPages.StandardController controller){ //Platform__c, , Print_Approver__c
        salesOrderID = Apexpages.currentPage().getParameters().get('id');
    }
    
    public PageReference cancel(){
        PageReference page;
        page = new PageReference('/'+salesOrderID);
        page.setRedirect(true);
        return page;
    }
    
    public String errorMessage {get; set;}
    
    public Boolean getCanEscalate() {
        List<csmso__Sales_Order__c> salesOrders = [SELECT csmso__Status__c, Name, Approval_Step__c, Approver1_Level__c, Approver1_Platform__c, Approver2_Level__c, Approver2_Platform__c, Approval_Process_Id__c, OwnerId, Escalation_Time__c FROM csmso__Sales_Order__c WHERE Id = :salesOrderID];
        
        if (salesOrders.isEmpty()) return false;
        
        if (salesOrders[0].Escalation_Time__c == null) return false;
        
        Integer step = salesOrders[0].Approval_Step__c.intValue();
        Integer level = (step == 1) ? salesOrders[0].Approver1_Level__c.intValue() : salesOrders[0].Approver2_Level__c.intValue();
        String  platform = (step == 1) ? salesOrders[0].Approver1_Platform__c : salesOrders[0].Approver2_Platform__c;
        Id      salesRep = salesOrders[0].OwnerId;
        
        CPQ_Approver__c approvers = null;
        
        for (CPQ_Approver__c app: [SELECT L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c FROM CPQ_Approver__c WHERE (Sales_Rep__c = :salesRep) AND (Platform__c = :platform)]) {
            approvers = app;
        }
        
        Integer nextLevel = level + 1;
        
        if (approvers == null) return false;
        
        return ((nextLevel <= ApproverLevels) && (approvers.get('L' + nextLevel + '_Approver__c') != null));
    }
    
    public String getEscalationTime() {
        List<csmso__Sales_Order__c> salesOrders = [SELECT Escalation_Time__c, OwnerId FROM csmso__Sales_Order__c WHERE Id = :salesOrderID];
        
        if (salesOrders.isEmpty()) return null;
        
        return salesOrders[0].Escalation_Time__c.format('h:mm a \'on\' dd MMM yyyy');
    }
    
    public PageReference redirectToApproval(){
        List<csmso__Sales_Order__c> salesOrders = [SELECT csmso__Status__c, Name, Approval_Step__c, Approver1__c, Approver2__c, Approval_Process_Id__c FROM csmso__Sales_Order__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
        
        errorMessage = null;
        
        if (!salesOrders.isEmpty() && (salesOrders[0].Approval_Process_Id__c != null)) {
			csmso__Sales_Order__c so = salesOrders[0];
            
            if (so.csmso__Status__c != 'Sent for Internal Approval') {
                errorMessage = 'The sales order ' + so.Name + ' does not require approval';
                return null;
            } else if ((so.Approval_Step__c == 1) && (so.Approver1__c != UserInfo.getUserId())) {
                errorMessage = 'You are not the designated approver for ' + so.Name;
                return null;
            } else if ((so.Approval_Step__c == 2) && (so.Approver2__c != UserInfo.getUserId())) {
                errorMessage = 'You are not the designated approver for ' + so.Name;
                return null;
            } else {
                PageReference page;
                page = new PageReference('/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + so.Approval_Process_Id__c);
                page.setRedirect(true);
                return page;
            }
        } else {
            errorMessage = 'Could not find Sales Order or Approval Process';
            
            return null;
        }
    }
    
    
    /*
        Reject a sales order with optional comments.
    */
    public PageReference reject() {
        PageReference ref = new PageReference('/' + salesOrderID);
        
        csmso__Sales_Order__c sOrder = [Select csmso__Status__c, Reject_Comments__c from csmso__Sales_Order__c where Id =: salesOrderId FOR UPDATE];

        Result ar = new Result();
        Approval.ProcessWorkitemRequest PWR = new Approval.ProcessWorkitemRequest();
        List<ProcessInstanceWorkitem> piw = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId= :sOrder.Id];
        PWR.setComments(comments);
        PWR.setAction('Reject');
        PWR.setWorkitemId(piw[0].id);
        Approval.ProcessResult result =  Approval.process(PWR);
                
        if(result.isSuccess()){
            ar.success = true;
            sOrder.Reject_Comments__c = comments;
            sOrder.csmso__Status__c = 'Internally Rejected';
            update sOrder;
        }
        else{
            Database.Error[] errors = result.getErrors();
            ar.message = 'Error in submitting Sales Order for approval - Reject.';
            
            return null;
        }
        
        return ref;
    }
    
    public String getRejectComments() {
        System.debug('Getting reject comments for: ' + salesOrderRecordID);
        
        String comments = null;
        
        for (ProcessInstanceStep step: [Select StepStatus, Comments FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :salesOrderRecordID ORDER BY CreatedDate DESC]) {
            if (step.StepStatus == 'Rejected') {
                comments = step.Comments;
                break;
            }
        }

        return comments;
    }
}