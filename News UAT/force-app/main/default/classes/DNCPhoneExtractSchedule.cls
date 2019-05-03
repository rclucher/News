/*---------------------------------------------------------
 * Author:  Mathanan Yogaratnam
 * Description: 
 * This is schedule class to run batch DNCPhoneExtract
 * Company: Salesforce.com
 * Date: 23/08/2013
 * History:
 * 23/08/2013   Mathanan Yogaratnam       Created
 ---------------------------------------------------------*/
global class DNCPhoneExtractSchedule implements Schedulable 
{    
    global void execute(SchedulableContext scMain) 
    {
        DNCPhoneExtract extractProcess = new DNCPhoneExtract(DNCPhone_Helper.extractQuery);
        ID idBatch = Database.executeBatch(extractProcess, DNCPhone_Helper.extractScopeSize);
    }
}