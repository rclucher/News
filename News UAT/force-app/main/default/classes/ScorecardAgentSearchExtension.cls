public class ScorecardAgentSearchExtension {
    @TestVisible public Integer TASKLIMIT {get {return TASKLIMIT == NULL ? 500 : TASKLIMIT; } private set;}
    public List<Task> tasks {get;set;}
    public Map<Id, NVMStatsSF__NVM_Call_Summary__c> callData {get;set;}
    public List<Id> selectedAgents {get;set;}
    public Id selectedGroup {get;set;}
    public Boolean tooManyTasks {get;set;}
    public String selectedState {get;set;}

    public Case dummyCase {get;set;}
    public NVMStatsSF__NVM_Call_Summary__c dummyCallSummary {get;set;}

    public String noTasksFound {get;set;}

    public List<SelectOption> getStates() {

        List<SelectOption> states = new List<SelectOption>();
            states.add(new SelectOption('', '--None--'));
            states.add(new SelectOption('NSW', 'NSW'));
            states.add(new SelectOption('VIC', 'VIC'));
            states.add(new SelectOption('QLD', 'QLD'));
            states.add(new SelectOption('ACT', 'ACT'));
            states.add(new SelectOption('SA', 'SA'));
            states.add(new SelectOption('WA', 'WA'));
            states.add(new SelectOption('NT', 'NT'));
        return states;
    }

    public List<SelectOption> getAgentSelect() {

        List<SelectOption> agents = new List<SelectOption>();
        Set<Id> agentProfiles = new Set<Id>();

        try {
            for (Profile p : [SELECT Id FROM Profile WHERE Name LIKE '%NVM' OR Name = 'System Administrator']) {
                agentProfiles.add(p.Id);
            }
        } catch (Exception e) {
            System.debug('No users of CSR or CSR Admin profiles found');
        }

        for (User agent : [SELECT Id, Name FROM User WHERE ProfileId IN: agentProfiles AND isActive = true ORDER BY Name]) {
            agents.add(new SelectOption(agent.Id, agent.Name));
        }
        return agents;
    }

    public List<SelectOption> getGroups() {
        List<SelectOption> ops = new List<SelectOption>();
        
        ops.add(new SelectOption('', '--None--'));
        // NCS-00555  2016-08-22 darshan.gosar@bluewolfgroup.com 
            // Added Type != Queue filter in query                    
        for (Group g : [SELECT Id, Name FROM Group where Type != 'Queue']) {
            if (g.Name != null) {
                ops.add(new SelectOption(g.Id, g.Name));
            }
        }
        return ops;
    }

    public ScorecardAgentSearchExtension() {
        dummyCase = new Case();
        dummyCase.NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedIn__c = null;
        
        dummyCallSummary = new NVMStatsSF__NVM_Call_Summary__c();
        dummyCallSummary.NVMStatsSF__Total_Call_Duration__c = null;
        dummyCallSummary.NVMStatsSF__Agent_Ring_Duration__c = null;
        dummyCallSummary.NVMStatsSF__CallTime__c = null;
        dummyCallSummary.NVMStatsSF__CallEndTime__c = null;
        
        tasks = new List<Task>();
        callData = new Map<Id, NVMStatsSF__NVM_Call_Summary__c>();
        tooManyTasks = false;
        selectedAgents = new List<Id>();
    }

    public pageReference clear() {
        return null;
    }

    // NCS-00574  2016-11-29 darshan.gosar@bluewolfgroup.com 
        // Added below method to find subgroup users till 5 level
    public Set<Id> getGroupMembers(Set<Id> subGroupIds, Integer i){
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> subGroupIdSet = new Set<Id>();
        
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId in :subGroupIds]){
            if(String.valueOf(gm.UserOrGroupId).startsWith('005'))
                userIdSet.add(gm.UserOrGroupId);
            else
                subGroupIdSet.add(gm.UserOrGroupId);         
        }
        
        if(i <= 5 && subGroupIdSet.size() > 0){
            i++;
            userIdSet.addall(getGroupMembers(subGroupIdSet, i));
        }                
        return userIdSet;
    }
    public static Datetime getTimeZoneOffsetDateTimeString( DateTime startDateTime ){       
        /*system.debug('startdatetime '+startDateTime);
        TimeZone tz = UserInfo.getTimeZone();
        Integer offsetToUserTimeZone = tz.getOffset(startDateTime);
        System.debug('GMT Offset: ' + offsetToUserTimeZone + ' (milliseconds) to NZDT');
        startDateTime = startDateTime.addSeconds(-offsetToUserTimeZone/1000);
        system.debug('formated with offset '+startDateTime);*/
        return startDateTime;//.formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
    }
    public void search() {
        //set limit of 500
        //String query = 'SELECT Id, OwnerId, Subject, ActivityDate, Status, Call_Answered__c FROM Task WHERE';
        
        String dateFormat;
        Set<Id> calls = new Set<Id>();
        List<NVMStatsSF__NVM_Call_Summary__c> callSummaries = new List<NVMStatsSF__NVM_Call_Summary__c>();
        Datetime d;

        try {
            
            // NCS-00556  2016-08-23 darshan.gosar@bluewolfgroup.com 
                // Below code was commented so uncommented same & added group members into selectedAgents list in order to filter data            
            //TODO: Need to check what this wil be later
            if (selectedGroup != null) {
                System.debug(selectedGroup);
                Set<Id> subGroupIds = new Set<Id>();
                
                for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: selectedGroup]) {
                    //System.debug(gm);
                    // Only adding users of group, if group contains subgroups then those needs to be handeled seperately
                    if(String.valueOf(gm.UserOrGroupId).startsWith('005')){
                        selectedAgents.add(gm.UserOrGroupId);
                    }else{
                        subGroupIds.add(gm.UserOrGroupId);
                    }                        
                }
                // NCS-00574  2016-11-29 darshan.gosar@bluewolfgroup.com 
                    // Added below method call to add subgroup users till 5 level                
                if(subGroupIds.size() > 0){
                    selectedAgents.addall(getGroupMembers(subGroupIds, 1));
                }
            }

            String query = 'SELECT NVMStatsSF__CallTime__c, News_Talk_Time__c, NVMStatsSF__Total_Call_Duration__c, NVMStatsSF__TaskID__c,'+
                ' NVMStatsSF__Related_Case__r.Origin, NVMStatsSF__Related_Case__r.State__c,'+
                ' NVMStatsSF__Related_Case__r.Type,' +
                //' CallTransferred__c, '+
                'NVMStatsSF__Related_Case__r.NVMContactWorld__Skills__c, NVMStatsSF__Agent2__c, NVMStatsSF__Agent__r.Name, NVMStatsSF__Agent2__r.Name   '+
                ' FROM NVMStatsSF__NVM_Call_Summary__c WHERE NVMStatsSF__TaskExists__c = true';
        
            //need to verify where we are searching agent 
            if (!selectedAgents.isEmpty()) {
                query += ' AND NVMStatsSF__Agent__c IN (';
                    for (Id a : selectedAgents) {
                        query += '\'' + a + '\',';
                    }
                    query = query.removeEnd(',');
                    query += ')';
            }

            if (dummyCallSummary.NVMStatsSF__CallTime__c != null) {
                Datetime startTime = getTimeZoneOffsetDateTimeString(dummyCallSummary.NVMStatsSF__CallTime__c);
                query += ' AND NVMStatsSF__CallTime__c >=: startTime';
            }
            if (dummyCallSummary.NVMStatsSF__CallEndTime__c != null) {
                 Datetime endTime = getTimeZoneOffsetDateTimeString(dummyCallSummary.NVMStatsSF__CallEndTime__c);
                 query += ' AND NVMStatsSF__CallTime__c <=: endTime';
            }
            if(dummyCase.NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedIn__c != null) {
                query += ' AND NVMStatsSF__CallEndTime__c = LAST_N_DAYS: ' + dummyCase.NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedIn__c;
            }

            if(dummyCallSummary.NVMStatsSF__Total_Call_Duration__c != null) {
                query += ' AND News_Talk_Time__c >= ' + dummyCallSummary.NVMStatsSF__Total_Call_Duration__c;
            }

            if(dummyCallSummary.NVMStatsSF__Agent_Ring_Duration__c != null) {
                query += ' AND News_Talk_Time__c <= ' + dummyCallSummary.NVMStatsSF__Agent_Ring_Duration__c;
            }

            if(dummyCase.Origin != null) {
                query += ' AND NVMStatsSF__Related_Case__r.Origin = \'' + dummyCase.Origin + '\'';
            }

            if(selectedState != null) {
                query += ' AND NVMStatsSF__Related_Case__r.State__c = \'' + selectedState + '\'';
            }

            if(dummyCase.Type != null) {
                query += ' AND NVMStatsSF__Related_Case__r.Type = \'' + dummyCase.Type + '\'';
            }

            query += ' ORDER BY CreatedDate DESC LIMIT ' + (TASKLIMIT+1);
            
            System.debug(query);
            for (NVMStatsSF__NVM_Call_Summary__c call : Database.query(query)) {
                calls.add(call.NVMStatsSF__TaskID__c);
                callSummaries.add(call);
            }
            System.debug('calls: ' + calls);
        } catch (Exception e) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            System.debug(e);
        }

        tasks = new List<Task>([SELECT Id, Owner.Name, OwnerId, Subject, ActivityDate, Status, Call_Answered__c, Reviewed__c FROM Task WHERE Id IN: calls LIMIT :(TASKLIMIT+1)]);
        
        for (NVMStatsSF__NVM_Call_Summary__c call : callSummaries) {
            callData.put(call.NVMStatsSF__TaskID__c, call);
        }

        getTaskMessage();
        System.debug('tasks.size(): ' + tasks.size());
        System.debug('tasksEmpty: '+ tasks.isEmpty());
    }

    public void getTaskMessage() {
        if (tasks.isEmpty()) {
            noTasksFound = 'No tasks found.';
        }
        else {
            noTasksFound = null;
            tooManyTasks = false;
            if (tasks.size() > TASKLIMIT) {
                tooManyTasks = true;
            }
        }
    }
}