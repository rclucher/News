/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: Target to Quota batch scheduler
 * Company: Salesforce.com
 * Date: 9/10/2013
 * History:
 * 9/10/2013   Bohao Chen       Created
 * NOTE: The user can manually executed this controller by adding Managers_Divisional_Ops permission set to their profiles
 ---------------------------------------------------------*/
global class TargetToQuota_Scheduler implements Schedulable 
{
    global void execute(SchedulableContext sc) 
    {
        TargetToQuota_Batch targetToQuota = new TargetToQuota_Batch(TargetToQuota_Helper.targetToQuotaQuery);
        ID idBatch = database.executebatch(targetToQuota);
    }
}