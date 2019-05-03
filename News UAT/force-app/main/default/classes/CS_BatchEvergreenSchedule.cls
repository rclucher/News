/**
 * Schedule Evergreen payment renewal
 */
global class CS_BatchEvergreenSchedule implements Schedulable {
	
	global void execute(SchedulableContext ctx) {
		Database.executeBatch(new CS_BatchEvergreenRenewal());
	}
}