/**
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 */
global without sharing class SyncSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction {
	global String performAction(String salesOrderId) {
		String resyncResult = '';
		//get needed SO fields
		List<csmso__Sales_Order__c> salesOrder = [SELECT Id, Name, csmso__Status__c, Invalid_Config_Count__c, Is_Synched__c,
												  csmso__Opportunity__c, csmso__Opportunity__r.Name, csmso__Opportunity__r.Has_an_Approved_SO__c
												  FROM csmso__Sales_Order__c
												  WHERE Id = :salesOrderId];
		//Request sync, if SO doesn't pass validation inform user about it
		try {
			resyncResult = SalesOrder_Helper.syncWithOpportunity(salesOrder);
			//resyncResult will be either 'OK' or actual validation message
			if (resyncResult != 'OK') {
				throw new SyncSalesOrderException(resyncResult);
			} else {
				String successMessage = 'Sales Order successfully synced!';
				resyncResult = '{"status":"ok", "message":"' + successMessage +'"}';
			}

		} catch (Exception e) {
			return '{"status":"error", "message":"'+ e.getmessage().escapejava() +'"}';
		}

		//resyncResult will be either 'OK' or actual validation message
		/*if (resyncResult == 'OK') {
			resyncResult = '{"status":"ok", "message":"Sales Order successfully synced!"}';
		} else {
			resyncResult = '{"status":"error", "message":"'+ resyncResult +'"}';
		}*/

		return resyncResult;
	}

	public class SyncSalesOrderException extends Exception{
				//intentionally left blank
	}
}