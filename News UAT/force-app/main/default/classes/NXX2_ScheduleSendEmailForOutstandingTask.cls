global class NXX2_ScheduleSendEmailForOutstandingTask implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        NXX2_Batch_Send_Email_Outstanding_Tasks b = new NXX2_Batch_Send_Email_Outstanding_Tasks ();
        database.executebatch(b,200);
    }
   
}