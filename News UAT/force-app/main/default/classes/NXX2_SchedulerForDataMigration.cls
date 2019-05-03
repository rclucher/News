/**
* @author       Kamal Sharma
* @date         2019-02-27
* @className	NXX2_SchedulerForDataMigration
* @description  This class will be used to start data migration asynchronously.
*/
global class NXX2_SchedulerForDataMigration implements Schedulable
{
    /**
    * @author       Kamal Sharma
    * @date         2019-02-27
    * @description  execute method implementation of Schedulable interface
    * @param        SchedulableContext sc
    * @return       void
    */
    global void execute(SchedulableContext sc)
    {
        NXX2_ResetErrorRecordInStagingData b = new NXX2_ResetErrorRecordInStagingData();
        database.executebatch(b,1);
    }
}