global class CCN_Event_Schedule implements Schedulable
{
    // AUTHOR:     2015-09-14 Louis Wang (Bluewolf)
    // DESC:       CCN Enhancement
    //				This schedule class will run batch CCN_Event_Batch
    global void execute(SchedulableContext scMain) 
    {
        // Incremental Run - Update Mode
        String jobName = String.valueOf(System.Today()) + ' Event Incremental Update';
        CCN_Event_Batch ccn = new CCN_Event_Batch(null, null, 'IncrementalRun', 'Update', jobName);
        database.executeBatch(ccn);
    }
}