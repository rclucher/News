global class BookingUpdate_Schedule implements Schedulable
{
    // AUTHOR:     2015-09-07 Louis Wang (Bluewolf)
    // DESC:       SFE-412
    //				This schedule class will run batch BookingUpdate_Batch
    global void execute(SchedulableContext scMain) 
    {
        BookingUpdate_Batch updateProcess = new BookingUpdate_Batch();
        ID idBatch = Database.executeBatch(updateProcess);
    }
}