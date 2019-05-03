/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_HistoryTrackingService
* @testClassName    CS_HistoryTrackingServiceTest
* @description      Service class for history tracking functions
*/
public with sharing class CS_HistoryTrackingService {
	public final static String SALES_ORDER_API_NAME = 'csmso__Sales_Order__c';

	//map of lookup fields for which we neeed to have readable values in audit history for Order__c object
	public final static Map<String,String> orderLookupFields = new Map<String, String>{
			'Opportunity__c' => 'Opportunity__r.Name',
			'Assigned_Campaign_Manager__c' => 'Assigned_Campaign_Manager__r.Name',
			'Customer_Contact__c' => 'Customer_Contact__r.Name',
			'Industry_CodeCO__c' => 'Industry_CodeCO__r.Name',
			'Sales_Order__c' => 'Sales_Order__r.Name',
			'Sales_Representative__c' => 'Sales_Representative__r.Name',
			'Campaign_Customer_Contact__c' => 'Campaign_Customer_Contact__r.Name',
			'Assigned_Setup_Coordinator__c' => 'Assigned_Setup_Coordinator__r.Name'
	};

	public final static Map<String,String> productOrderLookupFields = new Map<String, String>{
			'Order__c' => 'Order__r.Name',
			'Assigned_Fulfilment_Owner__c' => 'Assigned_Fulfilment_Owner__r.Name',
			'Product_Node__c' => 'Product_Node__r.Name'
	};

	public final static Map<String,String> productConfigLookupFields = new Map<String, String>{
			'cscfga__Product_Definition__c' => 'cscfga__Product_Definition__r.Name'
	};


	// Map of all required lookup fields with verbose values where the key is sObject name
	public final static Map<String,Map<String,String>> objReqLookupFieldsMap = new Map<String, Map<String, String>> {
			'Order__c' => orderLookupFields,
			'Product_Order__c' => productOrderLookupFields,
			'cscfga__Product_Configuration__c' => productConfigLookupFields
	};

	/**
    * @name         : updateSnapshotAsyn
    * @description  : create a snapshot in an async way
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : List<History_Tracking__c> historyList
    * @return       : n/a
    */
	@InvocableMethod(label='Create Snapshots' description='Take snapshots for history tracking purposes.')
	public static void updateSnapshotAsyn(List<History_Tracking__c> historyList) {

		List<History_Tracking__c> htListUpdate = new List<History_Tracking__c>();


		for(History_Tracking__c ht: historyList){
			if(ht.Status__c != null && ht.Status__c == 'New'){
				if(ht.Object__c != null && ht.Object__c == 'Sales Order' && ht.Sales_Order__c != null){	
					History_Tracking__c htUpdate = new History_Tracking__c();
					htUpdate.Snapshot_JSON__c = createSnapshot(ht.Sales_Order__c, ht.Description__c, System.now());
					htUpdate.Status__c = 'Complete';
					htUpdate.Id = ht.Id;
					htListUpdate.add(htUpdate);



				}
			}
		}

		if(!htListUpdate.isEmpty()){
			update htListUpdate;
		}


	}

	/**
    * @name         : getHistoryTrackingBySO
    * @description  : get history tracking records by sales order id
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectApiName, String recordId
    * @return       : List<History_Tracking__c>
    */
	public static List<History_Tracking__c> getHistoryTrackingBySO(String objectApiName, String recordId){

		List<History_Tracking__c> htList = new List<History_Tracking__c>();
		
		if(objectApiName == SALES_ORDER_API_NAME){
			htList = [SELECT 	CreatedDate, Object__c, Snapshot_JSON__c 
						FROM 	History_Tracking__c 
						WHERE 	Sales_Order__c =: recordId
						AND		Status__c = 'Complete'	
						Order By CreatedDate];
		}
		return htList;
	}

	/**
    * @name         : createHistoryTracking
    * @description  : create a history tracking record
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectTracked, String salesOrderId, String description, Boolean immediateAction, Boolean needsInsert
    * @return       : History_Tracking__c
    */
	public static History_Tracking__c createHistoryTracking(String objectTracked, String salesOrderId, String description, Boolean immediateAction, Boolean needsInsert){
		History_Tracking__c ht = new History_Tracking__c();
		ht.Description__c = description;
		ht.Immediate_Action__c = immediateAction;
		ht.Object__c = objectTracked;
		ht.Sales_Order__c = salesOrderId;
		ht.Status__c = 'New';

		if(needsInsert) insert ht;
		return ht;
	}

	/**
    * @name         : createSnapshot
    * @description  : create a history tracking record
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String recordId, String description, Datetime timestamp
    * @return       : String
    */
	private static String createSnapshot(String recordId, String description, Datetime timestamp){
		Datetime localTimeStamp = timestamp != null ? timestamp : System.now();
		String createddate = localTimeStamp.year() + '-' + localTimeStamp.month() + '-' + localTimeStamp.day() + ' ' 
							+ localTimeStamp.hour() + ':' + localTimeStamp.minute() + ':' + localTimeStamp.second();

		Map<String, SObjectType> objectToSObjectTypes = Schema.getGlobalDescribe();
		String snapshot;
		if (!String.isBlank(recordId) && objectToSObjectTypes.get('csmso__Sales_Order__c').getDescribe().getKeyPrefix() == recordId.subString(0, 3)){
			csmso__Sales_Order__c soDB 	= getSalesOrder(recordId);
			Order__c coDB 				= getCampaignOrder(recordId);

			List<cscfga__Product_Configuration__c> pcList = getProductConfig(recordId);

			Map<String, Object> histroyTrackingJSON = new Map<String, Object>();
			histroyTrackingJSON.put('createdDate', createddate);
			histroyTrackingJSON.put('description', description);
			histroyTrackingJSON.put('salesOrder', soDB);

			if(coDB != null){
				histroyTrackingJSON.put('campaignOrder', coDB);
			}

			if(coDB != null && coDB.Product_Orders__r != null && coDB.Product_Orders__r.size() > 0){
				histroyTrackingJSON.put('productOrders', coDB.Product_Orders__r);
			}

			if(coDB != null && coDB.Payments__r != null && coDB.Payments__r.size() > 0){
				histroyTrackingJSON.put('payments', coDB.Payments__r);
			}

			if(pcList != null && pcList.size() > 0){
				histroyTrackingJSON.put('productConfigurations', pcList);
			}
			
			snapshot = JSON.serialize(histroyTrackingJSON);
		}
		return snapshot;
	}

	/**
    * @name         : getFieldSetMappings
    * @description  : get field sets across multiple objects
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectApiName
    * @return       : Map<String, List<Schema.FieldSetMember>>
    */
	public static Map<String, List<Schema.FieldSetMember>> getFieldSetMappings(String objectApiName){
		Map<String, List<Schema.FieldSetMember>> fsMemberList = new Map<String, List<Schema.FieldSetMember>>();
		if(objectApiName == SALES_ORDER_API_NAME){
			fsMemberList.put('salesOrder', SObjectType.csmso__Sales_Order__c.FieldSets.History_Tracking.getFields());
			fsMemberList.put('campaignOrder', SObjectType.Order__c.FieldSets.History_Tracking.getFields());
			fsMemberList.put('productOrders', SObjectType.Product_Order__c.FieldSets.History_Tracking.getFields());
			fsMemberList.put('productConfigurations', SObjectType.cscfga__Product_Configuration__c.FieldSets.History_Tracking.getFields());
			fsMemberList.put('payments', SObjectType.Payment__c.FieldSets.History_Tracking.getFields());
		}
		
        return fsMemberList;
	}

	/**
    * @name         : getAllFieldMappings
    * @description  : get all fields 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectApiName
    * @return       : Map<String, List<Object>>
    */
	public static Map<String, List<Object>> getAllFieldMappings(String objectApiName){
		Map<String, List<Object>> fieldsMappings = new Map<String, List<Object>>();
		if(objectApiName == SALES_ORDER_API_NAME){

			fieldsMappings.put('salesOrder', getFieldMapping('csmso__Sales_Order__c'));
			fieldsMappings.put('campaignOrder', getFieldMapping('Order__c'));
			fieldsMappings.put('productOrders', getFieldMapping('Product_Order__c'));
			fieldsMappings.put('productConfigurations', getFieldMapping('cscfga__Product_Configuration__c'));
			fieldsMappings.put('payments', getFieldMapping('Payment__c'));
		}
		
        return fieldsMappings;
	}

	/**
    * @name         : getProductConfig
    * @description  : get all product configuration records under sales order 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Id salesOrderId
    * @return       : List<cscfga__Product_Configuration__c>
    */
	public static List<cscfga__Product_Configuration__c> getProductConfig(Id salesOrderId){
		List<String> pcFields =  getAllFields('cscfga__Product_Configuration__c');
		String queryString = 'SELECT {{ProdConfigFields}} FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c =\'{{SalesOrderId}}\'' ;

		queryString = queryString.replace('{{SalesOrderId}}', salesOrderId);
		// update query with product configuration fields
		if(pcFields.size() == 0){
			queryString = queryString.replace('{{ProdConfigFields}}', 'Id');
		}else{
			queryString = queryString.replace('{{ProdConfigFields}}', String.join(pcFields,','));
		}

		List<cscfga__Product_Configuration__c> pcList =  (List<cscfga__Product_Configuration__c>) Database.query(queryString);
		return pcList;
	}

	/**
    * @name         : getSalesOrder
    * @description  : get sales order record
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Id salesOrderId
    * @return       : csmso__Sales_Order__c
    */
	public static csmso__Sales_Order__c getSalesOrder(Id salesOrderId){
		List<String> fields =  getAllFields('csmso__Sales_Order__c');
		String queryString = 'SELECT {{Fields}} FROM {{ObjectName}} WHERE Id =\'{{RecordId}}\'' ;
		queryString = queryString.replace('{{Fields}}', String.join(fields,',')).replace('{{ObjectName}}', 'csmso__Sales_Order__c').replace('{{RecordId}}', salesOrderId);

		csmso__Sales_Order__c soDB = (csmso__Sales_Order__c) Database.query(queryString);
		return soDB;
	}

	/**
    * @name         : getCampaignOrder
    * @description  : get campaign order record under sales order
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Id salesOrderId
    * @return       : Order__c
    */
	private static Order__c getCampaignOrder(Id salesOrderId){
		List<String> coFields = getAllFields('Order__c');
		List<String> poFields = getAllFields('Product_Order__c');
		List<String> paymentFields = getAllFields('Payment__c');

		//String queryNonNestedString = 'SELECT {{OrderFields}} FROM Order__c WHERE Sales_Order__c =\'{{SalesOrderId}}\'' ;
		String queryTemplate = 'SELECT {{OrderFields}}, (SELECT {{ProductOrderFields}} FROM Product_Orders__r), (SELECT {{PaymentFields}} FROM Payments__r) FROM Order__c WHERE Sales_Order__c =\'{{SalesOrderId}}\'' ;
		
		// update query with so fields
		String queryString = queryTemplate.replace('{{OrderFields}}', String.join(coFields,',')).replace('{{SalesOrderId}}', salesOrderId);
		
		// update query with product order fields
		if(poFields.size() == 0){
			queryString = queryString.replace('{{ProductOrderFields}}', 'Id');
		}else{
			queryString = queryString.replace('{{ProductOrderFields}}', String.join(poFields,','));
		}

		// update query with payment fields
		if(paymentFields.size() == 0){
			queryString = queryString.replace('{{PaymentFields}}', 'Id');
		}else{
			queryString = queryString.replace('{{PaymentFields}}', String.join(paymentFields,','));
		}

		Order__c coDB = (Order__c) Database.query(queryString);
		return coDB;
	}

	/**
    * @name         : getFieldsList
    * @description  : get list of fields by field set given
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : List<Schema.FieldSetMember> fieldsFieldSet
    * @return       : List<String>
    */
	private static List<String> getFieldsList(List<Schema.FieldSetMember> fieldsFieldSet){
		List<String> fields = new List<String>();
		for (Schema.FieldSetMember flm : fieldsFieldSet) {
			fields.add(flm.getFieldPath());
        }
        return fields;
	}

	/**
    * @name         : getAllFields
    * @description  : get all fields by object 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectApiNam
    * @return       : List<String>
    */
	public static List<String> getAllFields(String objectApiName){
		List<String> allFields = new List<String>();
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(objectApiName);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

		for (String fieldApiName: fieldMap.keySet()) {
			allFields.add(fieldMap.get(fieldApiName).getDescribe().getName());
		}

		//add lookup name fields
		if ( objReqLookupFieldsMap.keySet().contains(objectApiName) ) {
				for (String lookupFieldName :objReqLookupFieldsMap.get(objectApiName).values()) {
					//System.debug('From static map:' + lookupFieldName);
					//allFields.add(lookupFieldName);
				}
				allFields.addAll(objReqLookupFieldsMap.get(objectApiName).values());
		}

        return allFields;
	}

	/**
    * @name         : getFieldMapping
    * @description  : generate mapping for fields
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String objectApiName
    * @return       : List<Object>
    */
	private static List<Object> getFieldMapping(String objectApiName){
		List<Object> fieldMapping = new List<Object>();
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Schema.SObjectType leadSchema = schemaMap.get(objectApiName);
		Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();

		for (String fieldApiName: fieldMap.keySet()) {
			Map<String, String> temp = new Map<String, String>();
			temp.put('fieldPath', fieldMap.get(fieldApiName).getDescribe().getName());
			temp.put('label', fieldMap.get(fieldApiName).getDescribe().getLabel());
			fieldMapping.add(temp);
		}

		if (objReqLookupFieldsMap.keySet().contains(objectApiName)) {
			Map<String,String> objLookupsMap = objReqLookupFieldsMap.get(objectApiName);

			for (String lookupFieldName : objLookupsMap.keySet()) {
				Map<String, String> temp = new Map<String, String>();
				temp.put('fieldPath', objLookupsMap.get(lookupFieldName)); // gets the actual relationship full name i.e. Account__r.Name
				temp.put('label', fieldMap.get(lookupFieldName).getDescribe().getLabel() + ' (via lookup) '); // gets the label of the actual field name which is of lookup type i.e. Account__c
				fieldMapping.add(temp);
			}
		}
        return fieldMapping;

	}


	/**
	* @name enqueueHistorySnapshotCreation
	* @description Method to enqueue snapshot creation queueable job
	* @param historyTrackings List of history tracking records to create the snapshot.
	* */
	public static void enqueueHistorySnapshotCreation(List<History_Tracking__c> historyTrackings) {
		System.enqueueJob(new CS_RetractionSnapshotQueueable(historyTrackings));
	}

}