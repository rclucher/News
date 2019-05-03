global class CCN_Task_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    // AUTHOR:     2015-06-10 Louis Wang (Bluewolf)
    // DESC:       This batch job will loop through 2.4 million Task records to detect / update CCN string

    /*
        // Intial Run - Detect Mode
        CCN_Task_Batch ccn = new CCN_Task_Batch('2010-01', '2015-06', 'InitialRun', 'Detect', '2010-01 2015-06 Detect Take 1');
        database.executeBatch(ccn);

        // Incremental Run - Detect Mode
        CCN_Task_Batch ccn = new CCN_Task_Batch(null, null, 'IncrementalRun', 'Detect', 'Incremental Detect Take 1');
        database.executeBatch(ccn);

        // Intial Run - Update Mode
        CCN_Task_Batch ccn = new CCN_Task_Batch('2010-01', '2015-06', 'InitialRun', 'Update', '2010-01 2015-06 Update Take 1');
        database.executeBatch(ccn);

        // Incremental Run - Update Mode
        CCN_Task_Batch ccn = new CCN_Task_Batch(null, null, 'IncrementalRun', 'Update', 'Incremental Update Take 1');
        database.executeBatch(ccn);
    */
    global static final string SOBJECT_TYPE = 'Task';
    global static final string SOBJECT_FIELD = 'Description';
    global static final string LAST_RUN_ERROR_MSG = 'Last Run timestamp not available from custom setting ';
    global static final string LAST_SUCCESS_SETTING = 'Last Success Update CCN_Task';    

    global integer detectRecordNo;
    global integer totalRecordNo;
    global boolean isInitialRun = false;
    global boolean isUpdate = false;

    global string global_batchType;
    global string global_batchMode;

    private string query;

    global string global_StartMonth_Short;
    global string global_EndMonth_Short;

    private string local_StartMonth_Long;
    private string local_EndMonth_Long;

    global boolean isValidInput = false;
    
    global list<id> detectedRecordIds = new list<id>();

    global string batchJobNo;

    private string errorMessage;    

    // startMonthString - start month, eg. 2015-01
    // endMonthString - end month, eg. 2015-06
    // batchType - type of run, either InitialRun or IncrementalRun
    // batchMode - mode of run, either Detect or Update
    // batchJobDesc - description for the batch (to group batch )
    global CCN_Task_Batch(String startMonthString, String endMonthString, String batchType, String batchMode, String batchJobDesc)
    {
        // overloads constructor.
        this(startMonthString, endMonthString, batchType, batchMode, null, batchJobDesc);
    }

    global CCN_Task_Batch(String startMonthString, String endMonthString, String batchType, String batchMode, String globalStartMonthString, String batchJobDesc)
    {

        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 1 prameters => startMonthString:{0}, endMonthString:{1}, batchType:{2}, batchMode:{3}', 
                                    new LIST<String>{startMonthString,endMonthString,batchType,batchMode}));


        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 2 before set => global_StartMonth_Short:{0}, local_StartMonth_Long:{1}, global_EndMonth_Short:{2}, local_EndMonth_Long:{3}', 
                                    new LIST<String>{global_StartMonth_Short,local_StartMonth_Long,global_EndMonth_Short,local_EndMonth_Long}));

        // this is the function that will be used by the user
        isValidInput = CCN_Helper.check_inputs(startMonthString, endMonthString, batchType, batchMode);

        totalRecordNo=0;
        detectRecordNo=0;

        batchJobNo = batchJobDesc;

        if(startMonthString!=null)
        {
            if(startMonthString.length()==7)
            {
                // this is initiated from execute anonymous
                global_StartMonth_Short = startMonthString;
            }
            else
            {
                global_StartMonth_Short = globalStartMonthString;
                // this is initated from cascading batch jobs
                local_StartMonth_Long = startMonthString;
            }
        }

        if(endMonthString!=null)
        {
            if(endMonthString.length()==7)
            {
                // this is initiated from execute anonymous
                global_EndMonth_Short = endMonthString;

                // focus one month at a time from the ending month
                local_StartMonth_Long = CCN_Helper.convert_DateString_Long(endMonthString, false);
                local_EndMonth_Long = CCN_Helper.convert_DateString_Long(endMonthString, true);                 
            }
            else
            {
                // this is initated from cascading batch jobs
                local_EndMonth_Long = endMonthString;
            }
        }        

        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 3 set => global_StartMonth_Short:{0}, local_StartMonth_Long:{1}, global_EndMonth_Short:{2}, local_EndMonth_Long:{3}', 
                                    new LIST<String>{global_StartMonth_Short,local_StartMonth_Long,global_EndMonth_Short,local_EndMonth_Long}));


        global_batchType = batchType;
        global_batchMode = batchMode;
        isInitialRun = CCN_Helper.convert_BatchType(batchType);
        isUpdate = CCN_Helper.convert_BatchMode(batchMode);
        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 4 set => global_batchType:{0}, global_batchMode:{1}, isInitialRun:{2}, isUpdate:{3}', 
                                    new LIST<String>{global_batchType,global_batchMode,String.valueOf(isInitialRun),String.valueOf(isUpdate)}));

        // if incremental, then check custom setting for the last run time
        DateTime lastRunTime = null;
        if(!isInitialRun)
        {
            // get the last run timestamp from custom setting
            lastRunTime = CCN_Helper.fetch_LastUpdatedStamp(LAST_SUCCESS_SETTING);
            if(lastRunTime==null)
            {                
                // if custom setting not exist or the last run field is blank, exit the batch
                errorMessage = LAST_RUN_ERROR_MSG + '"' + LAST_SUCCESS_SETTING + '"' ;
                // use custom exception to exit batch
                throw new CCN_Helper.ccnException(errorMessage);                
            }
        }

        // this function is used for cascading the batch job
        query = CCN_Helper.convert_Soql(local_StartMonth_Long, local_EndMonth_Long, isInitialRun, SOBJECT_TYPE, SOBJECT_FIELD, lastRunTime);
        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 5 set => query:{0}', 
                                    new LIST<String>{query}));



    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch start => query:{0}', 
                                    new LIST<String>{query}));

        // set running mode in custom setting to true
        CCN_Helper.update_CustomSetting(true, 'CCN', 'Task');
        
        // passing the query string to the Database object    
        Database.QueryLocator ql;
        try
        {
            ql =  Database.getQueryLocator(query);
        }
        catch(Exception ex)
        {
            // set running mode in custom setting to false
            CCN_Helper.update_CustomSetting(false, 'CCN', 'Task');

            errorMessage = 'ERROR when START - "' + ex.getMessage() + '"';
            // use custom exception to exit batch
            throw new CCN_Helper.ccnException(errorMessage);
        }
        return ql;
    }

    global void execute(Database.BatchableContext BC, List<Task> scope)
    {
        list<Task> recordsToUpdate = new list<Task>();
        

        for(Task evt : scope)
        {
            if(evt.Description!=null)
            {
                if(CCN_Helper.detectCCN(evt.Description))
                {
                    detectRecordNo++;
                    detectedRecordIds.add(evt.id);
                    
                    if(isUpdate)
                    {
                        evt.Description = CCN_Helper.maskCCN(evt.Description);
                        recordsToUpdate.add(evt);
                    }
                }
            }
            totalRecordNo++;
        }

        // by default, only 200 records are looped, and hence, number of detection will only be less than 200, per list.
        if(isUpdate)
        {
            try
            {
                update recordsToUpdate;
            }
            catch(Exception ex)
            {
                // update exception object
                errorMessage = 'ERROR when updating record(s) - "' + ex.getMessage() + '"';
            }                   
        }
    }   
    
    global void finish(Database.BatchableContext BC)
    {
        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 1 finish => detectRecordNo:{0}, totalRecordNo:{1}', 
                                    new LIST<String>{String.valueOf(detectRecordNo),String.valueOf(totalRecordNo)}));

        // set running mode in custom setting to false
        CCN_Helper.update_CustomSetting(false, 'CCN', 'Task');

        // if it is InitialRun, and startDate is not the endDate, then continues
        String local_EndMonth_Short = CCN_Helper.convert_DateString_Short(local_EndMonth_Long);
        String local_StartMonth_Short = CCN_Helper.convert_DateString_Short(local_StartMonth_Long);

        System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 2 finish => isInitialRun:{0}, global_StartMonth_Short:{1},local_StartMonth_Short:{2},local_EndMonth_Short:{3}', 
                                    new LIST<String>{String.valueOf(isInitialRun),global_StartMonth_Short,local_StartMonth_Short,local_EndMonth_Short}));

        if(errorMessage!=null && errorMessage!='')
        {
            createLog(true, errorMessage);
        }
        else
        {
            createLog(false, '');
        }   
        
        if(isInitialRun && global_StartMonth_Short!=local_StartMonth_Short)
        {
            // minus end date by one month, and process it as another batch job
            String local_EndMonth_MinusOneMonth_Short = CCN_Helper.calc_DateString_MinusOneMonth_Short(local_EndMonth_Short);
            String startDate = CCN_Helper.convert_DateString_Long(local_EndMonth_MinusOneMonth_Short, false);
            String endDate = CCN_Helper.convert_DateString_Long(local_EndMonth_MinusOneMonth_Short, true);

            System.debug(String.format('@CCN_' + SOBJECT_TYPE + '_Batch 3 finish => startDate:{0}, endDate:{1},global_batchType:{2},global_batchMode{3}', 
                                    new LIST<String>{startDate,endDate,global_batchType,global_batchMode}));

            // may need to check if there is already 5 batch running on the server
            CCN_Task_Batch ccnBatch = new CCN_Task_Batch(startDate, endDate, global_batchType, global_batchMode, global_StartMonth_Short, batchJobNo);    
            Database.executeBatch(ccnBatch); 
        }
        else
        {
            // do something for batch completion

        }


        if(!isInitialRun && isUpdate && errorMessage==null)
        {
            // if it is incremental update, and there is no error, then update the custom setting to have now as the new success timestamp
            CCN_Helper.update_SuccessTimestamp(LAST_SUCCESS_SETTING);
        }        
    }

    private void createLog(Boolean hasError, String errorMessage)
    {

            General_Batch_Log__c gbl = CCN_Helper.createLogRecord(  local_StartMonth_Long,
                                                                    local_EndMonth_Long,
                                                                    global_batchType,
                                                                    global_batchMode,
                                                                    SOBJECT_TYPE,
                                                                    detectRecordNo,
                                                                    totalRecordNo,
                                                                    hasError,
                                                                    errorMessage,
                                                                    batchJobNo );        

            if (detectedRecordIds.size()>0 && gbl!=null && gbl.id!=null)
            {                
                CCN_Helper.saveAttachment(detectedRecordIds, gbl.id);
            }
        
    }


}