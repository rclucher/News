/*---------------------------------------------------------
* Author:  Bohao Chen
* Description: This is scheduler for AccountUpdateTcsTas_Batch and AccountUpdateTgs_Batch
*              12/06/2014 BC: update this scheduler to run tgs batch rather than tcstas batch
* Company: Salesforce.com
*
* Date: 25/07/2013
* History:
* 25/07/2013   Bohao Chen       Created
* 12/06/2014   Bohao Chen       Updated
---------------------------------------------------------*/
global class BookingRevenueRollup_Scheduler implements Schedulable
{
    global void execute(SchedulableContext sc) 
    {
        AccountCalculateTcsTas_Batch b = new AccountCalculateTcsTas_Batch();
        Id batchProcessId = database.executebatch(b);
        System.debug('Account TGS Update Batch batch process ID: ' + batchProcessId);                   
    }
}