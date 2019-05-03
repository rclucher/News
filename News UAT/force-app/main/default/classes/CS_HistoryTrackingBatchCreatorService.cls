global class CS_HistoryTrackingBatchCreatorService implements Database.Batchable<sObject> {
    global String historyTrackingQuery; 
    global Datetime processStartedAt;
    global Datetime processCompletedIn;
    private List<History_Tracking__c> inProcessRecords = new List<History_Tracking__c>();
    
    public CS_HistoryTrackingBatchCreatorService(){
        processStartedAt = Datetime.now();
        System.debug('Batch process startes at: '+processStartedAt);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        
        historyTrackingQuery  = 'select Id, Name, Object__c, Sales_Order__c, Status__c, Description__c,Snapshot_JSON__c from History_Tracking__c where Object__c = \'Sales Order\' and Sales_Order__c != null and Status__c = \'New\'';        	
        return Database.getQueryLocator(historyTrackingQuery);
    }
    
    global void execute(Database.BatchableContext bc, List<History_Tracking__c> hTRecords){
        
        CS_HistoryTrackingService.updateSnapshotAsyn(hTRecords);
        inProcessRecords.addAll(hTRecords);
    }
    
    global void finish(Database.BatchableContext bc){
        List<Id> liveCampaignSuccess = new List<Id>();
        List<Id> liveCampaignError = new List<Id>();
        List<Id> nonliveCampaignSuccess = new List<Id>();
        List<Id> nonliveCampaignError = new List<Id>();
        boolean liveCampaignProcessed = false;
        boolean nonLiveCampaignProcessed = false;
        
        List<History_Tracking__c> processedRecords = [Select Id, Name, Object__c, Sales_Order__c, Status__c, Description__c
                                                     	from History_Tracking__c where LastModifiedDate > :processStartedAt];
        for(History_Tracking__c htR : processedRecords){
            if(htR.Status__c.equals('Complete')&& htR.Description__c.contains('Legacy')){
                if(htR.Description__c.contains('Opportunity')){
                    nonliveCampaignSuccess.add(htR.Sales_Order__c);
                    if(!nonLiveCampaignProcessed) nonLiveCampaignProcessed = true;
                }else{
                    liveCampaignSuccess.add(htR.Sales_Order__c);
                    if(!liveCampaignProcessed) liveCampaignProcessed = true;
                }
                
            }
            if(htR.Status__c.equals('New')&& htR.Description__c.contains('Legacy')){
                if(htR.Description__c.contains('Opportunity')){
                    nonliveCampaignError.add(htR.Sales_Order__c);
                    if(!nonLiveCampaignProcessed) nonLiveCampaignProcessed = true;
                }else{
                    liveCampaignError.add(htR.Sales_Order__c);
                    if(!liveCampaignProcessed) liveCampaignProcessed = true;
                }
            }
        }
        
        
        List<CS_LegacyAuditHistoryRunLogEntries__c> auditHistoryList = [Select 
                                                                  Id
                                                                  ,Name
                                                                  ,Last_Run_Date_Time__c
                                                                  ,Process_Status__c
                                                                  from 
                                                                  CS_LegacyAuditHistoryRunLogEntries__c];
        for(CS_LegacyAuditHistoryRunLogEntries__c record : auditHistoryList){
            if(liveCampaignProcessed){
                if(record.Name.equals('Campaign Live')){
                    record.Last_Run_Date_Time__c = Datetime.now();
                    
                    String processStatus = 'Successful Records :' + liveCampaignSuccess;
                    processStatus = processStatus + '\\n Errorred Records :'+liveCampaignError;
                    record.Process_Status__c =  processStatus;
                    
                    update record;
                }
            }if(nonLiveCampaignProcessed)
                if(record.Name.contains('Opportunity')){
                    record.Last_Run_Date_Time__c = Datetime.now();
                    String processStatus = 'Successful Records :' + nonliveCampaignSuccess;
                    processStatus = processStatus + '\\n Errorred Records :'+nonliveCampaignError;
                    record.Process_Status__c =  processStatus;
                    
                    update record;
                }
        }
    }
}