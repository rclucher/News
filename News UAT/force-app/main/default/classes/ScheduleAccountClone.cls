/** 
 *
 * @author      Lakshmi Mohan 
 * @description Schedule the Batch Apex Clone Account Objects 
 * @description Modified 2018-01-17 
 *				
 **/
global class ScheduleAccountClone implements Schedulable {

	global void execute(SchedulableContext sc) {
		AccountCloneUpdateBatch process = new AccountCloneUpdateBatch();
		database.executebatch(process);
	}

}