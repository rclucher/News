global class CCN_EmailMessage_Schedule implements Schedulable
{
    // AUTHOR:     2015-09-14 Louis Wang (Bluewolf)
    // DESC:       CCN Enhancement
    //				This schedule class will run batch CCN_EmailMessage_Batch
    global void execute(SchedulableContext scMain) 
    {
        // Incremental Run - Update Mode
        String jobName = String.valueOf(System.Today()) + ' EmailMsg Incremental Update';
        CCN_EmailMessage_Batch ccn = new CCN_EmailMessage_Batch(null, null, 'IncrementalRun', 'Update', jobName);
        database.executeBatch(ccn);
    }
}