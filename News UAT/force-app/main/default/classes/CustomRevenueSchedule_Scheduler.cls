/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This is scheduler for Crs_Opportunity_Batch and Crs_OpportunityLineItem_Batch
 * Company: Salesforce.com
 * Date: 02/10/2013
 * History:
 * 02/10/2013   Bohao Chen       Created
 ---------------------------------------------------------*/
global class CustomRevenueSchedule_Scheduler implements Schedulable
{
   global void execute(SchedulableContext sc) 
   {
      Crs_Opportunity_Batch b = new Crs_Opportunity_Batch(); 
      database.executebatch(b);
   }
}