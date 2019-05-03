/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_SOHistoryTrackingController
* @testClassName    CS_SOHistoryTrackingControllerTest
* @description      Controller for SO History Tracking component
*/
public with sharing class CS_SOHistoryTrackingController {
	
	/**
    * @name         : getSoHistory
    * @description  : get all history tracking information by sales order id
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String salesOrderId
    * @return       : String
    */
    @AuraEnabled
	public static String getSoHistory(String salesOrderId) {
		CS_LightningResponse res = new CS_LightningResponse(); 

    	try{
    		List<History_Tracking__c> soHistory = CS_HistoryTrackingService.getHistoryTrackingBySO(CS_HistoryTrackingService.SALES_ORDER_API_NAME, salesOrderId);
    		List<String> allSnapshots;
    		Map<String, List<Schema.FieldSetMember>> fieldSetMappings;
            Map<String, List<Object>> allFieldMappings;
    		if(!soHistory.isEmpty()){
    			allSnapshots = new List<String>();
    			for(History_Tracking__c ht: soHistory){
	    			allSnapshots.add(ht.Snapshot_JSON__c);
	    		}
    			fieldSetMappings = CS_HistoryTrackingService.getFieldSetMappings(CS_HistoryTrackingService.SALES_ORDER_API_NAME);
                allFieldMappings = CS_HistoryTrackingService.getAllFieldMappings(CS_HistoryTrackingService.SALES_ORDER_API_NAME);
    		}
    		Map<String, Object> results = new Map<String, Object>();
    		results.put('salesOrderHistory',allSnapshots);
    		results.put('fieldSetMappings',fieldSetMappings);
            results.put('fieldMappings',allFieldMappings);

            res.code = 2000;
            res.message = 'Success';
            res.details = JSON.serialize(results);

		}catch(Exception ex){
			res.code = 5000;
			res.message = 'System error.';
			res.details = ex.getMessage();
		}
        
        return JSON.serialize(res);
	}


	/**
	* @name         : getSoHistory
	* @description  : Get the
	* @createdby    : Petar Mikic - 2019-03-11
	* @param        : String salesOrderId
	* @return       : String
	*/
	@AuraEnabled
	public static String getCampaignInfo(String salesOrderId) {
		CS_LightningResponse res = new CS_LightningResponse();

		try {
			Order__c CO = [SELECT ID,Name, Sales_Order__r.Name From Order__c WHERE Sales_order__r.Id =: salesOrderId];

			Map<String,String> results = new Map<String, String>();
			results.put('auditCO_Name', CO.Name);
			results.put('auditSO_Name', CO.Sales_Order__r.Name);

			res.code = 2000;
			res.message = 'Success';
			res.details = JSON.serialize(results);
			
		} catch(Exception ex) {
			res.code = 5000;
			res.message = 'System error.';
			res.details = ex.getMessage();
		}

		return JSON.serialize(res);
	}
}