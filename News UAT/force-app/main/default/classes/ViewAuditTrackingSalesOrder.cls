/*---------------------------------------------------------
 * Author: Kevin Wu
 * Company: CloudSense
 * TestClassName: ViewAuditTrackingSalesOrderTest
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of redirecting the user to the Audit Tracking page
 ---------------------------------------------------------*/
global without sharing class ViewAuditTrackingSalesOrder implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {
        System.debug('performAction for View Audit Tracking on Sales Order');
    	return '{"status":"ok", "redirectURL":"/apex/CS_SOHistoryTracking?soId=' + salesOrderId + '", "message": "Redirecting to Audit Tracking ..."}';
    }
}