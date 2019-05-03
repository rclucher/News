/** 
 *
 * @author      Lakshmi Mohan 
 * @description Schedule the Batch Apex Clone Account Objects 
 * @description Modified 2018-01-17 
 *				
 **/
 
global class ScheduleOpportunityClone implements Schedulable {
	global void execute(SchedulableContext sc) {
		OpportunityCloneUpdateBatch process = new OpportunityCloneUpdateBatch();
		database.executebatch(process);
	}

}