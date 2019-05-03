/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: Controller for pre-processing address information
 * History:
 * 10/09/2013  Bohao Chen  Created
---------------------------------------------------------*/
global class WalkinForecast_Scheduler implements Schedulable
{
    global void execute(SchedulableContext sc) 
    {
        WalkinForecast_Batch b = new WalkinForecast_Batch(); 
        database.executebatch(b);
    }

}