global class CCN_Case_Schedule implements Schedulable
{
    // AUTHOR:     2015-09-14 Louis Wang (Bluewolf)
    // DESC:       CCN Enhancement
    //				This schedule class will run batch CCN_Case_Batch
    global void execute(SchedulableContext scMain) 
    {
        // Incremental Run - Update Mode
        String jobName = String.valueOf(System.Today()) + ' Case Incremental Update';
        CCN_Case_Batch ccn = new CCN_Case_Batch(null, null, 'IncrementalRun', 'Update', jobName);
        database.executeBatch(ccn);
    }
}