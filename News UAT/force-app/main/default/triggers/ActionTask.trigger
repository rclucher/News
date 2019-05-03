/**
 * @description  Trigger on Action Task
 *
 * @company      Bluewolf
 * @author       Timothy Fabros (timothy.fabros@bluewolf.com)
 * @date         2015-10-14
 */
trigger ActionTask on Action_Task__c (before update) {
	
	// BEGIN: Trigger Killers
	if (!Global_Helper.canTrigger('ActionTask')) {
		return;
	}
	
	if (NewsXtend_ActionPlan_Helper.skipActionTaskTrigger) {
		NewsXtend_ActionPlan_Helper.skipActionTaskTrigger = false;
		return;
	}
	// END: Trigger Killers
	
	if (trigger.isUpdate) {

		Map<Id, Action_Task__c> map_id_actionTask = new Map<Id, Action_Task__c>();

		// automation for due date && assigned task date
		// BEGIN:
		List<Action_Task__c> actionTasks = new List<Action_Task__c>();
		
		for (Action_Task__c actionTask : trigger.new) {
			
			Action_Task__c actionTaskOld = trigger.oldMap.get(actionTask.Id);

			if (actionTask != actionTaskOld) {
				
				actionTask = NewsXtend_ActionPlan_Helper.update_AutomationLogic(actionTask, actionTaskOld);

				if (actionTask.First_Task__c == null && actionTask.OwnerId != actionTaskOld.OwnerId) {
					map_id_actionTask.put(actionTask.Id, actionTask);
					System.debug(LoggingLevel.ERROR, '@ActionTaskTrigger map_id_actionTask: ' + map_id_actionTask);
				}
			}
		}

		List<Action_Task__c> actionTasksToUpdate = new List<Action_Task__c>();
		List<Action_Task__c> childActionTasks = [SELECT Due_Date__c, First_Task__c FROM Action_Task__c WHERE First_Task__c IN :map_id_actionTask.keySet()];

		System.debug(LoggingLevel.ERROR, '@ActionTaskTrigger childActionTasks: ' + childActionTasks);
		System.debug(LoggingLevel.ERROR, '@ActionTaskTrigger childActionTasks.size(): ' + childActionTasks.size());
		// update child action tasks if due date have been populated.
		if (!map_id_actionTask.isEmpty()) {
			for (Action_Task__c actionTask : childActionTasks) {

				if (actionTask.First_Task__c != null && map_id_actionTask.containsKey(actionTask.First_Task__c)) {
					if (trigger.newMap.containsKey(actionTask.Id)) {

						actionTask = trigger.newMap.get(actionTask.Id);
						actionTask.Due_Date__c = map_id_actionTask.get(actionTask.First_Task__c).Due_Date__c;
					}
					else {

						actionTask.Due_Date__c = map_id_actionTask.get(actionTask.First_Task__c).Due_Date__c;
						actionTasksToUpdate.add(actionTask);	
					}
				}
			}
		}

		if (!actionTasksToUpdate.isEmpty()) {
			NewsXtend_ActionPlan_Helper.skipActionTaskTrigger = true;
			update actionTasksToUpdate;
		}
		// END:
	}
}