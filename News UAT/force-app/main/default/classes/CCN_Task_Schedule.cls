global class CCN_Task_Schedule implements Schedulable
{
    // AUTHOR:     2015-09-14 Louis Wang (Bluewolf)
    // DESC:       CCN Enhancement
    //				This schedule class will run batch CCN_Task_Batch
    global void execute(SchedulableContext scMain) 
    {
        // Incremental Run - Update Mode
        String jobName = String.valueOf(System.Today()) + ' Task Incremental Update';
        CCN_Task_Batch ccn = new CCN_Task_Batch(null, null, 'IncrementalRun', 'Update', jobName);
        database.executeBatch(ccn);
    }
}