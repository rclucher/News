public class CS_HistoryTrackingBatchService {
    
    // this class creates the history for records in one shot.
    // based on the statistics run, the data is found to be under 2000 records in Production
    // hence a batch approach is not utilized. 
	
	public Date lastRunDate;
    public Map<String, List<String>> campaignStatus = new Map<String, List<String>>{
        'Live Campaign' => new List<String> {'Campaign Live', 'Pending for Cancel','Pending for Pause','Paused'},
            'Ended Live Campaign' => new List<String>{'Cancelled', 'Campaign Ended', 'Rejected'}
    };
    public string objectTracked;
    public string campaignLive;
    public string campaignNonLive;
    public string snapshotTextForLiveCampaign;
    public string snapshotTextForNonLiveCampaign;
    public boolean immediateAction;
    public boolean needsInsert;
    public Datetime campaignLiveLastRunDate;
    public Datetime campaignNonLiveLastRunDate;
    public List<Id> successRecords;
    public List<Id> skippedRecords;
    public Map<Id, String> historyTrackingErroredRecords;
    public Map<Id, String> historySnapshotErroredRecords;
    public List<CS_LegacyAuditHistoryRunLogEntries__c> auditHistoryRunList;
    
    public CS_HistoryTrackingBatchService(){
        
       	this.objectTracked = 'Sales Order';
    	this.campaignLive = 'Live Campaign';
        this.campaignNonLive = 'Ended Live Campaign';
        this.snapshotTextForLiveCampaign = 'Legacy History Record - Campaign Live';
        this.snapshotTextForNonLiveCampaign = 'Legacy History Record - Opportunity Closed/Won';
        this.immediateAction = true;
    	this.needsInsert = false;
        
        auditHistoryRunList = [Select 
                               	Id
                               	,Name
                               	,Last_Run_Date_Time__c
                               	,Process_Status__c
                               from 
                               	CS_LegacyAuditHistoryRunLogEntries__c];
        for(CS_LegacyAuditHistoryRunLogEntries__c record : auditHistoryRunList){
            if(record.Name.equals(campaignLive)){
                campaignLiveLastRunDate = record.Last_Run_Date_Time__c;
            }
            if(record.Name.equals(campaignNonLive)){
                campaignNonLiveLastRunDate = record.Last_Run_Date_Time__c;
            }
        }
    }    
    
    public void createLegacyHistoryRecords(){
        
        createLiveCampaignHistoryRecords();
        
        createInProgressCampaignHistoryRecords();
    }
    

    public void createLiveCampaignHistoryRecords(){
        createCampaignHistoryRecords(campaignLive,null,campaignLiveLastRunDate,snapshotTextForLiveCampaign);
    }
    
    
    public void createInProgressCampaignHistoryRecords(){
        createCampaignHistoryRecords(campaignLive,campaignNonLive,campaignNonLiveLastRunDate,snapshotTextForNonLiveCampaign);
    }
    
    private void createCampaignHistoryRecords(String liveCampaignStatusIdentifier, String nonLiveCampaignStatusIdentifier, Datetime historyRunDate, String textForSnapShot){
        //create history records
        boolean liveCampaignProcess = true;
        Exception_Log__c exceptionRecord;
        List<Exception_Log__c> exceptionRecordList = new List<Exception_Log__c>();
        List<History_Tracking__c> historyRecordsList = new List<History_Tracking__c>();
        
        List<String> liveStatusValues = campaignStatus.get(liveCampaignStatusIdentifier); 
        List<String> nonLiveStatusValues;
        if(!String.isBlank(nonLiveCampaignStatusIdentifier)){
            nonLiveStatusValues = campaignStatus.get(nonLiveCampaignStatusIdentifier);
            liveCampaignProcess = false;
        }
        System.debug('liveStatusValues : ' +liveStatusValues);
        List<Order__c> liveCampaignsList = getRecords(liveStatusValues, nonLiveStatusValues, historyRunDate, liveCampaignProcess);
        
        skippedRecords = new List<Id>();
        for(Order__c campaign : liveCampaignsList){
            if(campaign.Sales_Order__c != null){
                History_Tracking__c ht = CS_HistoryTrackingService.createHistoryTracking(objectTracked, campaign.Sales_Order__c, textForSnapShot, immediateAction, needsInsert);
                historyRecordsList.add(ht);    
            }else{
                skippedRecords.add(campaign.Id);
            }
        }
        
        Database.SaveResult[] saveResults = Database.insert(historyRecordsList); // history records are inserted now. But the snapshot is not updated
        
        //skip the error records while making the updateSnapshot call.
        historyTrackingErroredRecords = new Map<Id, String>();
        List<Id> recordIdsForSnapShot = new List<Id>();
        for(Database.SaveResult saveResult : saveResults){
            if(saveResult.isSuccess()){
                recordIdsForSnapShot.add(saveResult.getId());
            }
            else{
                List<Database.Error> errorList = saveResult.getErrors();
                historyTrackingErroredRecords.put(saveResult.getId(), errorList[0].getMessage()); // stores the Sales Orders for which History Tracking record could not be created.
            }
        }
        
        //Database.executeBatch(new CS_HistoryTrackingBatchCreatorService(), 1500);
        
        /*List<History_Tracking__c> snapShotRecordsList = new List<History_Tracking__c>();
        for(History_Tracking__c historyRecord : historyRecordsList){
            if(recordIdsForSnapShot.contains(historyRecord.Id)){
                snapShotRecordsList.add(historyRecord);
            }
        }*/
        
        
        //updateSnapShots for identified Campaign Order Records
        //CS_HistoryTrackingService.updateSnapshotAsyn(snapShotRecordsList);
        //CS_HistoryTrackingService.enqueueHistorySnapshotCreation(snapShotRecordsList);
        
        /*for(CS_LegacyAuditHistoryRunLogEntries__c record : auditHistoryRunList){
            if(liveCampaignProcess){
                if(record.Name.equals('Campaign Live')){
                    record.Last_Run_Date_Time__c = Datetime.now();
                    String processStatus = 'Successful Records :' + snapShotRecordsList;
                    if(skippedRecords.size()>0){
                        processStatus = processStatus + '\\n Skipped Records :'+ skippedRecords;
                    }else{
                        processStatus = processStatus + '\\n Skipped Records :'+ skippedRecords.size();
                    }
                    if(historyTrackingErroredRecords.size()>0){
                        processStatus = processStatus + '\\n Errorred Records :'+historyTrackingErroredRecords;
                    }else{
                        processStatus = processStatus + '\\n Errorred Records :'+historyTrackingErroredRecords.size();
                    }
                    record.Process_Status__c =  processStatus;
                    
                    update record;
                }
            }else{
                if(record.Name.contains('Opportunity')){
                    record.Last_Run_Date_Time__c = Datetime.now();
                    String processStatus = 'Successful Records :' + snapShotRecordsList;
                    if(skippedRecords.size()>0){
                        processStatus = processStatus + '\\n Skipped Records :'+ skippedRecords;
                    }else{
                        processStatus = processStatus + '\\n Skipped Records :'+ skippedRecords.size();
                    }
                    if(historyTrackingErroredRecords.size()>0){
                        processStatus = processStatus + '\\n Errorred Records :'+historyTrackingErroredRecords;
                    }else{
                        processStatus = processStatus + '\\n Errorred Records :'+historyTrackingErroredRecords.size();
                    }
                    record.Process_Status__c =  processStatus;
                    
                    update record;
                }
            }
        }*/
	}
    
    private List<Order__c> getRecords(List<String> liveStatuses, List<String> nonLiveStatuses, Datetime lastRunDate, boolean campaignLive){
        
        String query;
        
        if(campaignLive){
        	query = 'Select Id, Sales_Order__c, Status__c from Order__c where Status__c in :liveStatuses and Origin__c != \'Campaign Track\'';    
        }else{
            query = 'Select Id, Sales_Order__c, Status__c from Order__c where (status__c not in :liveStatuses and status__c not in :nonLiveStatuses) and Origin__c != \'Campaign Track\'';
        }
        
        if(lastRunDate != null){
            query = query + ' and LastModifiedDate > :lastRunDate';
        }
        
        List<Order__c> campaignOrderList = Database.query(query); 
        return campaignOrderList;
    }
    
    
    
    
    
   
}