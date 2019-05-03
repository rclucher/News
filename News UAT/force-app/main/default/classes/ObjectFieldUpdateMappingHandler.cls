/**
 * Handler class that implements core Object Field Update Mapping logic.
 * Important notes:
 * - Logic will reload source records and work with the values from the reloaded instance.
 * 	Be careful if trying to use this logic in before trigger events if mapping defined tries to update the records that
 * 	actually triggered this logic.
 * - Filtering is string based and might not work as expected as it is intended for really basic filtering.
 *
 * @author Antun Bartonicek
 * @since 23-10-2018
 * @company CloudSense
 */
public with sharing class ObjectFieldUpdateMappingHandler {
	//helper static pattern do validate constants (decimal used in calculations), static to cache it for performance
	static Pattern decimalPattern = Pattern.compile('^[-+]?\\d+(\\.\\d*)?$');
	//helper map for "dynamic" type cast i.e. mapping object fields to their types
	private Map<String, Map<String, String>> objectNameToFieldToTypeMap = new Map<String, Map<String, String>>();
	//Handler context
	@testVisible private List<Object_Field_Update_Mapping__mdt> objFieldMappings;
	//object that was changed and that we are "monitoring" for updates
	private String sourceObjectAPIname;
	private List<sObject> sourceObjects;
	//collect all fields used in Object Field Update Mapping as we will need to have them for queries
	private Map<String, Set<String>> objectNameToFieldsMap = new Map<String, Set<String>>();
	//collect all required relationship fields
	private Set<String> relationshipFields = new Set<String>();
	//map to hold all objects loaded for current context
	private Map<Id, sObject> allObjectsMap = new Map<Id, sObject>();
	//similar as allObjectsMap but object map is held for every objectName individually
	private Map<String, Map<Id, sObject>> objectNameToObjectsMap = new Map<String, Map<Id, sObject>>();
	//destination objects to update
	@testVisible private Map<String, sObject> objectsToUpdateMap = new Map<String, sObject>();
	//validation run, used to print out data config/mapping issues, public as we might need to debug
	public Boolean isValidationRun = false;
	//source objects would be reloaded if there is a mapping that uses relationship (example: cscfga__Product_Definition__r.Name)
	//reloading means there is a risk of data loss on sourceObjects if this class is used in before events!
	//do not change this flag without slight logic refactoring, see deletedRecordIds logic and usage!!!
	private Boolean reloadSourceObjects = true;
	//Ids of deleted records (after delete context) for which we only allow aggregate actions
	private Set<Id> deletedRecordIds = new Set<Id>();

	/**
	 * Constructor that sets handler context and loads all needed Object Field Update Mapping records.
	 */
	public ObjectFieldUpdateMappingHandler(List<sObject> sourceObjects) {
		this.sourceObjects = sourceObjects;
		//get source object API name from the first item as object mixing isn't supported
		if (sourceObjects != null && !sourceObjects.isEmpty()) {
			this.sourceObjectAPIname = sourceObjects[0].getSObjectType().getDescribe().getName();
		} else if (Trigger.isExecuting) {
			//sourceObjects not defined, since we are in trigger context we will fallback to automatic context detection
			//context is an overlay of old and new trigger context records
			Map<Id, sObject> autoContextMap = new Map<Id, sObject>();
			if (Trigger.oldMap == null) {
				autoContextMap = new Map<Id, sObject>();
			} else {
				autoContextMap = Trigger.oldMap.clone();
			}
			if (Trigger.newMap != null) {
				//matching Ids will be overwritten by new values
				autoContextMap.putAll(Trigger.newMap.clone());
			}
			//set our execution context
			this.sourceObjects = autoContextMap.values();
			this.sourceObjectAPIname = this.sourceObjects[0].getSObjectType().getDescribe().getName();
			System.debug('ObjectFieldUpdateMappingHandler: execution context auto-detected for object: ' + this.sourceObjectAPIname);
			System.debug('ObjectFieldUpdateMappingHandler: execution context set to: ' + autoContextMap);
		} else {
			isValidationRun = true;
			System.debug('ObjectFieldUpdateMappingHandler: sourceObjects not defined and not in trigger context! Setting isValidationRun to true!');
		}
	}
	/**
	 * Default 0 parm constructor, used for validation run.
	 */
	public ObjectFieldUpdateMappingHandler() {
	}
	/**
	 * Starts the mapping process for current context.
	 */
	public void execute() {
		if (this.sourceObjects == null || this.sourceObjects.isEmpty()) {
			//nothing to do, exit
			return;
		}
		//prepare mapping
		loadMapping();
		//load data
		loadData();
		//no we have everything to load metadata
		loadFieldTypes();
		if (isValidationRun) {
			System.debug('Execution will process ' + objFieldMappings.size() + ' mappings for ' + sourceObjects.size() + 'source objects.');
		}
		for (sObject sourceRecord :sourceObjects) {
			//if we reloaded source objects then we need to use reloaded data from the global map
			if (reloadSourceObjects) {
				//if source record was deleted then use original as there would be no loaded data
				//executeForSourceObjectRecord will allow only aggregate actions for those records
				if (deletedRecordIds.contains(sourceRecord.Id)) {
					executeForSourceObjectRecord(sourceRecord);
				} else {
					executeForSourceObjectRecord(allObjectsMap.get(sourceRecord.Id));
				}
			} else {
				executeForSourceObjectRecord(sourceRecord);
			}
		}
		//validation run does no modifications
		if (isValidationRun) {
			System.debug('Execution result:' + objectsToUpdateMap);
		} else {
			//TODO eventually reload records we would try to modify and remove all those whose
			//fields actually don't have effective change so that we don't perform unnecessary DML
			//i.e. spend additional SOQL and CPU time in order to potentially avoid DML and subsequent trigger runs.
			System.debug('Execution result:' + objectsToUpdateMap);
			if (!objectNameToObjectsMap.isEmpty()) {
				update objectsToUpdateMap.values();
			}
		}
	}

	/**
	 * Used to validate configured mapping records.
	 * It will load all active object field update mapping records and see if there are
	 * possible issues like non-existing object or field API names.
	 */
	public void validateMapping() {
		isValidationRun = true;
		loadMapping();
		loadFieldTypes();
		List<FilterStatement> temp;
		//run through mappings and see what parsing returns
		for (Object_Field_Update_Mapping__mdt mapping :this.objFieldMappings) {
			temp = parseCalculation(mapping.Source_Field_API_Name__c);
			temp = parseFilter(mapping.Filter__c);
		}
	}

	/**
	 * Runs mapping logic for individual source object record.
	 * Maintains global update list that will be committed later.
	 */
	private void executeForSourceObjectRecord(sObject sourceRecord) {
		Object value;
		//loop over all defined mappings (actions)
		for (Object_Field_Update_Mapping__mdt mapping :this.objFieldMappings) {
			if (isValidationRun) {
				System.debug('ObjectFieldUpdateMappingHandler: executing mapping ' + mapping.DeveloperName + ' for record: ' + sourceRecord);
			}
			//first inspect if we can resolve relationship
			String destinationObjectId = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
			if (String.isBlank(destinationObjectId)) {
				//source record doesn't have parent value so not suitable for this mapping scenario, skipping it
				if (isValidationRun) {
					System.debug('ObjectFieldUpdateMappingHandler: mapping (' + mapping.DeveloperName + ') skipped as source record (' + sourceRecord.Id + ') has no value in relationship field');
				}
				continue;
			}
			//important: only aggregate actions are allowed for deleted records
			if (deletedRecordIds.contains(sourceRecord.Id) && (mapping.Action_Type__c == 'CALCULATE' || mapping.Action_Type__c == 'COPY')) {
				if (isValidationRun) {
					System.debug('ObjectFieldUpdateMappingHandler: non-aggregate action mapping (' + mapping.DeveloperName + ') skipped as source record (' + sourceRecord.Id + ') was deleted!');
				}
				continue;
			}
			//each mapping could use different relationship field so aggregate actions will call getFilteredObjects every time
			if (mapping.Action_Type__c == 'CALCULATE') {
				value = getValueCalculate(sourceRecord, mapping);
			} else if (mapping.Action_Type__c == 'COPY') {
				value = getValueCopy(sourceRecord, mapping);
			} else if (mapping.Action_Type__c ==  'COUNT') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueCount(scope, mapping);
			} else if (mapping.Action_Type__c ==  'CONCATENATE') {
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueConcatenate(scope, mapping);
			} else if (mapping.Action_Type__c == 'AND') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueAnd(scope, mapping);
			} else if (mapping.Action_Type__c == 'OR') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueOr(scope, mapping);
			} else if (mapping.Action_Type__c == 'MIN') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueMin(scope, mapping);
			} else if (mapping.Action_Type__c == 'MAX') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueMax(scope, mapping);
			} else if (mapping.Action_Type__c == 'SUM') {
				//get relationship field value from current sourceRecord
				String relationshipFieldValue = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Relationship_field_API_Name__c);
				//get only relevant source object records (relationship field matching our value)
				List<sObject> scope = getFilteredObjects(mapping, relationshipFieldValue);
				value               = getValueSum(scope, mapping);
			} else if (isValidationRun){
				System.debug('ObjectFieldUpdateMappingHandler > unsupported Action Type: ' + mapping.Action_Type__c);
			}
			//put value to destination object
			//ensure map has item
			if (!objectsToUpdateMap.containsKey(destinationObjectId)) {
				Id newObjectId = (Id)destinationObjectId;
				objectsToUpdateMap.put(destinationObjectId, newObjectId.getSObjectType().newSObject(newObjectId));
			}
			//add our field value on top of other changes we have for that destination object
			if (isValidationRun) {
					System.debug('Setting ' + destinationObjectId + ' field ' + mapping.Destination_Field_API_Name__c + ' to value: ' + value);
			}
			objectsToUpdateMap.get(destinationObjectId).put(mapping.Destination_Field_API_Name__c, value);
		}
	}

	/**
	 * Implements logic for CALCULATE action type.
	 * IMPORTANT: Does not support operator precedence so calculation will be executed left to right.
	 */
	private Object getValueCalculate(sObject sourceRecord, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		Decimal calculationResult;
		//Source field holds our calculation
		List<FilterStatement> calculationSteps = parseCalculation(mapping.Source_Field_API_Name__c);
		//if validation printout execution context
		if (isValidationRun) {
			System.debug('Starting calculation for object: ' + sourceRecord);
		}
		for (FilterStatement calculation :calculationSteps) {
			Decimal currentValue = 0;
			String fieldValue    = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, calculation.fieldName);
			if (isValidationRun) {
				System.debug('Field: ' + calculation.fieldName + ', fieldValue:' + fieldValue + ', calculation step: ' + calculation);	
			}
			if (fieldValue == '') {
				//maybe calculation.fieldName wasn't a name of a field but constant so last check before skipping calculation step
				try {
					currentValue = Decimal.valueOf(calculation.fieldName);
				} catch (TypeException ex) {
					if (String.isEmpty(calculation.logicalOperator)) {
						//we failed to get field value for first filter statement (only 1st filter statemnt should have empty operator)
						//and this means calculation will fail in next step as currentValue will be null
						//defaulting currentValue and logging
						calculationResult = 0;
						if (isValidationRun) {
							System.debug('First field in calculation expresion was null, defaulting to 0. Calculated result might not be as expected!');
						}
					}
					//wasn't a valid decimal string so skipping as we do not have a value to use
					continue;
				}
			} else {
				currentValue = Decimal.valueOf(fieldValue);
			}
			//supported: +, -, *, /
			if (calculation.logicalOperator == '+') {
				calculationResult = calculationResult + currentValue;
			} else if (calculation.logicalOperator == '-') {
				calculationResult = calculationResult - currentValue;
			} else if (calculation.logicalOperator == '*') {
				calculationResult = calculationResult * currentValue;
			} else if (calculation.logicalOperator == '/') {
				if (currentValue != 0) {
					calculationResult = calculationResult / currentValue;
				} else if (isValidationRun) {
					System.debug('Calculation step would cause divide by 0 error, skipping step!');
				}
			} else {
				//only first filter statement should have empty logicalOperator so setting
				//return value directly to that value
				calculationResult = currentValue;
			}
		}
		if (calculationResult == null) {
			calculationResult = 0;
			if (isValidationRun) {
				System.debug('Final calculation result was null as none of the fields used in calculation had values (null). Defaulting to 0.');
			}
		}
		//final cast to destination field type
		returnValue = castToFieldType(getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c), calculationResult.toPlainString());
		return returnValue;
	}

	/**
	 * Implements logic for COPY action type.
	 */
	private Object getValueCopy(sObject sourceRecord, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		//copies value if source record matches required criteria (if set)
		if (matchesFilterCriteria(sourceRecord, mapping.Filter__c)) {
			String value = CS_Utils.getFieldValueOfSafeDeep(sourceRecord, mapping.Source_Field_API_Name__c);
			returnValue = castToFieldType(getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c), value);
		}
		return returnValue;
	}

	/**
	 * Implements logic for COUNT action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueCount(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		Integer value = 0;
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				value += 1;
			}
		}
		//always returning destination field in case we need to map it to text field
		returnValue = castToFieldType(getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c), String.valueOf(value));
		return returnValue;
	}

	/**
	 * Implements logic for CONCATENATE action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueConcatenate(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		String returnValue;
		Set<String> valueSet = new Set<String>();
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String value = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				valueSet.add(value);
			}
		}
		//concatenate values by using requested separator, if no values to concatenate leave return as null
		if (!valueSet.isEmpty()) {
			//join works only on lists
			List<String> tempList = new List<String>(valueSet);
			tempList.sort();
			String separator = mapping.Separator__c == null ? '' : mapping.Separator__c;
			returnValue = String.join(tempList, separator.replaceAll('space|SPACE', ' '));
		}
		return returnValue;
	}

	/**
	 * Implements logic for AND action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueAnd(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		Boolean value = true;//neutral value for AND logic
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String fieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				value &= Boolean.valueOf(fieldValue);
			}
			//no point in wasting resources if it already is false (for AND logic)
			if (!value) {
				break;
			}
		}
		//always returning destination field in case we need to map it to text field
		returnValue = castToFieldType(getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c), String.valueOf(value));
		return returnValue;
	}

	/**
	 * Implements logic for OR action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueOr(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		Boolean value = false;//neutral value for OR logic
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String fieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				value |= Boolean.valueOf(fieldValue);
			}
			//no point in wasting resources if it already is true (for OR logic)
			if (value) {
				break;
			}
		}
		//always returning destination field in case we need to map it to text field
		returnValue = castToFieldType(getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c), String.valueOf(value));
		return returnValue;
	}

	/**
	 * Implements logic for MIN action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 * would exclude those records from logic!
	 */
	private Object getValueMin(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		System.Type type = getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c);
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String fieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				//Empty string returned when object or field name are invalid (config issue so should be rare) or when field value is null
				if (fieldValue == '') {
					//useless iteration as we do not have a value to use so skip it
					continue;
				}
				Object currentValue = castToFieldType(type, fieldValue);
				//if not yet set then set it to current value
				returnValue = returnValue == null ? currentValue : returnValue;
				//set it to min value, we need to cast it to be able to compare it
				//TODO: for some reason dynamic cast doesn't work/compile so we need to use this ugly approach
				if (type == Decimal.class) {
					Decimal returnValueDec = (Decimal)returnValue;
					Decimal currentValueDec = (Decimal)currentValue;
					returnValue = currentValueDec < returnValueDec ? currentValueDec : returnValueDec;
				} else if (type == Integer.class) {
					Integer returnValueInt = (Integer)returnValue;
					Integer currentValueInt = (Integer)currentValue;
					returnValue = currentValueInt < returnValueInt ? currentValueInt : returnValueInt;
				} else if (type == Date.class) {
					Date returnValueDate = (Date)returnValue;
					Date currentValueDate = (Date)currentValue;
					returnValue = currentValueDate < returnValueDate ? currentValueDate : returnValueDate;
				} else if (type == Datetime.class) {
					Datetime returnValueDatetime = (Datetime)returnValue;
					Datetime currentValueDatetime = (Datetime)currentValue;
					returnValue = currentValueDatetime < returnValueDatetime ? currentValueDatetime : returnValueDatetime;
				} else {
					//any other type treated as string
					String returnValueString = (String)returnValue;
					String currentValueString = (String)currentValue;
					returnValue = currentValueString < returnValueString ? currentValueString : returnValueString;
				}
			}
		}
		return returnValue;
	}

	/**
	 * Implements logic for MAX action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueMax(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue;
		System.Type type = getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c);
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String fieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				//Empty string returned when object or field name are invalid (config issue so should be rare) or when field value is null
				if (fieldValue == '') {
					//useless iteration as we do not have a value to use so skip it
					continue;
				}
				Object currentValue = castToFieldType(type, fieldValue);
				//if not yet set then set it to current value
				returnValue = returnValue == null ? currentValue : returnValue;
				//set it to min value, we need to cast it to be able to compare it
				//TODO: for some reason dynamic cast doesn't work/compile so we need to use this ugly approach
				if (type == Decimal.class) {
					Decimal returnValueDec = (Decimal)returnValue;
					Decimal currentValueDec = (Decimal)currentValue;
					returnValue = currentValueDec > returnValueDec ? currentValueDec : returnValueDec;
				} else if (type == Integer.class) {
					Integer returnValueInt = (Integer)returnValue;
					Integer currentValueInt = (Integer)currentValue;
					returnValue = currentValueInt > returnValueInt ? currentValueInt : returnValueInt;
				} else if (type == Date.class) {
					Date returnValueDate = (Date)returnValue;
					Date currentValueDate = (Date)currentValue;
					returnValue = currentValueDate > returnValueDate ? currentValueDate : returnValueDate;
				} else if (type == Datetime.class) {
					Datetime returnValueDatetime = (Datetime)returnValue;
					Datetime currentValueDatetime = (Datetime)currentValue;
					returnValue = currentValueDatetime > returnValueDatetime ? currentValueDatetime : returnValueDatetime;
				} else {
					//any other type treated as string
					String returnValueString = (String)returnValue;
					String currentValueString = (String)currentValue;
					returnValue = currentValueString > returnValueString ? currentValueString : returnValueString;
				}
			}
		}
		return returnValue;
	}

	/**
	 * Implements logic for SUM action type.
	 * Loops over all objects and considers only those that meet the filtering criteria
	 */
	private Object getValueSum(List<sObject> objects, Object_Field_Update_Mapping__mdt mapping) {
		Object returnValue = 0;
		System.Type type = getFieldType(mapping.Destination_Object_API_Name__c, mapping.Destination_Field_API_Name__c);
		for (SObject obj :objects) {
			if (matchesFilterCriteria(obj, mapping.Filter__c)) {
				String fieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Source_Field_API_Name__c);
				//Empty string returned when object or field name are invalid (config issue so should be rare) or when field value is null
				if (fieldValue == '') {
					//maybe it was a calculation expression so try that before giving up
					Object calcResult = getValueCalculate(obj, mapping);
					if (calcResult != null) {
						fieldValue = ((Decimal)calcResult).toPlainString();
					} else {
						//useless iteration after all as we do not have a value to use so skip it
						continue;
					}
				}
				if (isValidationRun) {
					System.debug('Adding to sum: ' + fieldValue + ' from object: ' + obj);
				}
				Object currentValue = castToFieldType(type, fieldValue);
				//TODO: for some reason dynamic cast doesn't work/compile so we need to use this ugly approach
				if (type == Decimal.class) {
					Decimal returnValueDec = (Decimal)returnValue;
					Decimal currentValueDec = (Decimal)currentValue;
					returnValue = currentValueDec + returnValueDec;
				} else if (type == Integer.class) {
					Integer returnValueInt = (Integer)returnValue;
					Integer currentValueInt = (Integer)currentValue;
					returnValue = currentValueInt + returnValueInt;
				}
			}
		}
		return returnValue;
	}

	/**
	 * Helper method to extract only relevant record from all loaded source objects.
	 * Used to get scope for aggregation type of actions (SUM, MIN, MAX, AND, OR, COUNT)
	 * Do not try to use sourceObjectAPIname as schema returns lowercase value and our 
	 * objectNameToObjectsMap is case sensitive.
	 */
	private List<sObject> getFilteredObjects(Object_Field_Update_Mapping__mdt mapping, String fieldValue) {
		List<sObject> filteredObjects = new List<sObject>();
		for (sObject obj :objectNameToObjectsMap.get(mapping.Source_Object_API_Name__c).values()) {
			String currObjFieldValue = CS_Utils.getFieldValueOfSafeDeep(obj, mapping.Relationship_field_API_Name__c);
			if (currObjFieldValue == fieldValue) {
				filteredObjects.add(obj);
			}
		}
		return filteredObjects;
	}

	/**
	 * Parses filter string to create filter statements that are ran against the passed in object.
	 * Method returns true if the object matches filter criteria or if there is no filter string.
	 */
	private Boolean matchesFilterCriteria(sObject obj, String filterString) {
		//if no filter string the set to true, other code will effectively run as there will be no filter statements
		Boolean result = String.isBlank(filterString) ? true : false;
		List<FilterStatement> filters = parseFilter(filterString);
		if (isValidationRun) {
			System.debug('Object to check filter on: ' +  obj);
			System.debug('Filter used: ' +  filterString);
		}
		for (FilterStatement filter :filters) {
			Boolean currentResult = false;
			String fieldValue     = CS_Utils.getFieldValueOfSafeDeep(obj, filter.fieldName);
			//parseFilter logic needs to stay correct so we need to convert 'null' to '' as this is what getFieldValueOfSafeDeep will return
			String filterValue    = filter.filterValue.toLowerCase() == 'null' ? '' : filter.filterValue;
			if (isValidationRun) {	
				System.debug('Field: ' + filter.fieldName + ', fieldValue: ' + fieldValue);
			}
			//supported: <=, >=, <, >, !=, =
			if (filter.comparisonOperator == '<=') {
				currentResult = fieldValue <= filterValue ? true : false;
			} else if (filter.comparisonOperator == '>=') {
				currentResult = fieldValue >= filterValue ? true : false;
			} else if (filter.comparisonOperator == '<') {
				currentResult = fieldValue < filterValue ? true : false;
			} else if (filter.comparisonOperator == '>') {
				currentResult = fieldValue > filterValue ? true : false;
			} else if (filter.comparisonOperator == '!=') {
				currentResult = fieldValue != filterValue ? true : false;
			} else if (filter.comparisonOperator == '=') {
				currentResult = fieldValue == filterValue ? true : false;
			}
			//apply current version to global one
			//supported: ||, &&
			if (filter.logicalOperator == '||') {
				result = result || currentResult;
			} else if (filter.logicalOperator == '&&') {
				result = result && currentResult;
			} else {
				//only first filter statement should have empty logicalOperator
				result = currentResult;
			}
		}
		if (isValidationRun) {
			System.debug('Matches filter: ' +  result);
		}
		return result;
	}

	/**
	 * Loads all applicable object field update mapping record for our context.
	 * Maintains context required for loadData() and the rest of the logic.
	 */
	private void loadMapping() {
		//get all Object Field Update Mapping records for this source object, doesn't count against SOQL limits
		String query = 'SELECT Id, DeveloperName, Action_Type__c, Destination_Object_API_Name__c, Destination_Field_API_Name__c,';
		query += 'Source_Object_API_Name__c, Source_Field_API_Name__c, Relationship_field_API_Name__c, Filter__c, Separator__c ';
		query += 'FROM Object_Field_Update_Mapping__mdt	WHERE Active__c = true ';
		//if using isValidationRun when we have sourceObjects defined then we can't load all mapping as it would skew the execution results
		query += isValidationRun && sourceObjectAPIname == null ? '' : ' AND Source_Object_API_Name__c = :sourceObjectAPIname ';
		//if loaded then reuse it, useful for testing as well
		objFieldMappings = objFieldMappings != null ? objFieldMappings : Database.query(query);
		//compile the list of all used fields across all source and destination objects
		for (Object_Field_Update_Mapping__mdt mapping :objFieldMappings) {
			//collect all relationship fields as we need to define the loadData scope later on, using addAll but not expecting more that 1 field!
			relationshipFields.addAll(getFields(mapping.Relationship_field_API_Name__c));
			//create source object key if missing, we always would like to have Id field so add it here
			if (!objectNameToFieldsMap.containsKey(mapping.Source_Object_API_Name__c)) {
				objectNameToFieldsMap.put(mapping.Source_Object_API_Name__c, new Set<String>{'Id'});
			}
			//create destination object key if missing, we always would like to have Id field so add it here
			if (!objectNameToFieldsMap.containsKey(mapping.Destination_Object_API_Name__c)) {
				objectNameToFieldsMap.put(mapping.Destination_Object_API_Name__c, new Set<String>{'Id'});
			}
			//add source fields, we need to expect multiple field names in Source_Field_API_Name__c due to Calculation action type!
			objectNameToFieldsMap.get(mapping.Source_Object_API_Name__c).addAll(getFields(mapping.Source_Field_API_Name__c));
			//relationship field is from the source object so add it as well
			objectNameToFieldsMap.get(mapping.Source_Object_API_Name__c).addAll(getFields(mapping.Relationship_field_API_Name__c));
			//filter string also contains fields from source object so add it as well
			objectNameToFieldsMap.get(mapping.Source_Object_API_Name__c).addAll(getFields(parseFilter(mapping.Filter__c)));
			//now add destination fields
			objectNameToFieldsMap.get(mapping.Destination_Object_API_Name__c).addAll(getFields(mapping.Destination_Field_API_Name__c));
		}
		if (isValidationRun) {
			System.debug('objectNameToFieldsMap:' + objectNameToFieldsMap);
		}
	}

	/**
	 * Method responsible for loading all the data we need for our current context.
	 * Will load data for all mentioned Source and Destination objects.
	 * Query will include only fields mentioned in:
	 * - Source_Field_API_Name__c
	 * - Relationship_field_API_Name__c
	 * - Destination_Field_API_Name__c
	 *
	 * Notes: fields mentioned could also be relationships!
	 * IMPORTANT:
	 * This method can easily consume a lot of SOQLs as it needs to run 1 SOQL for every source/destination object!
	 */
	private void loadData() {
		Set<Id> idSet            = new Set<Id>();
		List<sObject> allObjects = new List<sObject>();
		//temp variable to easily get all Ids we got from trigger context as we don't want to load them
		Set<Id> sourceIds = new Map<Id, sObject>(sourceObjects).keySet();
		//find out what record we will need from each object by collecting all the relationship field values
		//additionally prepare where part of the SOQL
		for (sObject obj :sourceObjects) {
			for (String fieldName :relationshipFields) {
				String value = CS_Utils.getFieldValueOfSafeDeep(obj, fieldName);
				//only valid relationships are used, ignoring possible Id field as it would load object that we have from trigger context.
				if (value != '' && value instanceOf Id && !sourceIds.contains(value)) {
					idSet.add(value);
				}
			}
		}
		String whereClause;
		if (reloadSourceObjects) {
			whereClause = ' WHERE Id IN :sourceIds OR ' + String.join(new List<String>(relationshipFields),' IN :idSet OR ') + ' IN :idSet';
		} else {
			//not reloading so exclude all source object Ids as we will add the original records later
			whereClause = ' WHERE Id NOT IN :sourceIds AND ( ' + String.join(new List<String>(relationshipFields),' IN :idSet OR ') + ' IN :idSet )';
		}
		//now query all objects with all fields and place all of the records in a common map
		//SOQL in a loop by design but right now only one iteration
		for (String objectName :objectNameToFieldsMap.keySet()) {
			//for now just processing source object, we might support other objects later on if we would like to use relationships in config
			if (objectName.toLowerCase() != this.sourceObjectAPIname) {
				continue;
			}
			List<String> fieldList = new List<String>(objectNameToFieldsMap.get(objectName));
			String fieldString = String.join(fieldList, ',');
			String queryString = 'SELECT ' + fieldString + ' FROM ' + objectName + whereClause;
			//add records to context
			List<sObject> queryResults = Database.query(queryString);
			if (isValidationRun) {
				System.debug('Load Data query: ' + queryString);
				System.debug('idSet: ' + idSet);
				System.debug('queryResults: ' + queryResults);
			}
			//add source objects if reload wasn't done
			if (!reloadSourceObjects) {
				queryResults.addAll(sourceObjects);
			} else {
				//if we haven't added sourceObjects then missing ones are missing because they were deleted
				//for those records we will allow only aggregate actions as those need recalculating
				Map<Id, sObject> loadedRecordsMap = new Map<Id, sObject>(queryResults);
				deletedRecordIds = sourceIds.clone();
				deletedRecordIds.removeAll(loadedRecordsMap.keySet());
			}
			this.objectNameToObjectsMap.put(objectName, new Map<Id, sObject>(queryResults));
			allObjects.addAll(queryResults);
		}
		//transform it to map for convenience
		this.allObjectsMap.putAll(allObjects);
	}

	private void loadFieldTypes() {
		Map<String, Schema.SObjectType> globDesc = Schema.getGlobalDescribe();
		for (String objectName :objectNameToFieldsMap.keySet()) {
			String objectNameLC = objectName.ToLowerCase();
			if (globDesc.containsKey(objectNameLC)) {
				Map<String, Schema.SObjectField> fieldMap = globDesc.get(objectNameLC).getDescribe().fields.getMap();
				//capture field types for all required fields
				for (String fieldName :objectNameToFieldsMap.get(objectName)) {
					String fieldNameLC = fieldName.toLowerCase();
					if (fieldMap.containsKey(fieldNameLC)) {
						String fieldType = fieldMap.get(fieldNameLC).getDescribe().getType().name().toLowerCase();
						//add to map by using original case
						if (!objectNameToFieldToTypeMap.containsKey(objectName)) {
							objectNameToFieldToTypeMap.put(objectName, new Map<String, String>());
						}
						objectNameToFieldToTypeMap.get(objectName).put(fieldName, fieldType);
					} else if (isValidationRun){
						//field not found, configuration issue
						System.debug('Field configured in Object_Field_Update_Mapping__mdt not found:' + objectName + '>' + fieldName);
					}
				}
			} else if (isValidationRun) {
				//object not found, configuration issue
				System.debug('Object configured in Object_Field_Update_Mapping__mdt not found:' + objectName);
			}
		}
	}

	/**
	 * Helper method that takes object name and field name and casts string to correct type.
	 * Null or empty value is not considered for casting, it is treated as null!
	 */
	private Object castToFieldType(System.Type type, String valueToCast) {
		Object returnValue;
		if (isValidationRun) {
			System.debug('Casting "' + valueToCast + '" to type: ' + type);
		}
		if (String.isBlank(valueToCast)) {
			//guarding condition, if valueToCast is null or empty then default to null i.e. casting is skipped
			returnValue = null;
		} else if (type == Decimal.class) {
			returnValue = Decimal.valueOf(valueToCast);
		} else if (type == Integer.class) {
			returnValue = Integer.valueOf(valueToCast);
		} else if (type == Boolean.class) {
			returnValue = Boolean.valueOf(valueToCast);
		} else if (type == Date.class) {
			returnValue = DateTime.valueOfGmt(valueToCast).dateGMT();
		} else if (type == Datetime.class) {
			returnValue = DateTime.valueOfGmt(valueToCast);
		} else {
			returnValue = valueToCast;
		}
		return returnValue;
	}
	
	/**
	 * Returns system type that we need for casting to exact type in order to compare objects or save values.
	 */
	private System.Type getFieldType(String objectName, String fieldName) {
		String typeName;
		String fieldType = objectNameToFieldToTypeMap.get(objectName).get(fieldName);
		if (fieldType == 'currency' || fieldType == 'double' || fieldType == 'percent' || fieldType == 'decimal' || fieldType == 'long') {
			typeName = 'Decimal';
		} else if (fieldType == 'integer') {
			typeName = 'Integer';
		} else if (fieldType == 'boolean') {
			typeName = 'Boolean';
		} else if (fieldType == 'date') {
			typeName = 'Date';
		} else if (fieldType == 'datetime') {
			typeName = 'DateTime';
		} else {
			typeName = 'String';
		}
		return System.Type.forName(typeName);
	}

	/**
	 * Helper method that parses Source_Field_API_Name__c or Destination_Field_API_Name__c and returns individual
	 * field API names in a list.
	 */
	private List<String> getFields(String fieldString) {
		List<String> result = new List<String>();
		//splitting by all supported calculation operators (+, -, /, *), only - doesn't have to be regex escaped
		result = fieldString.deleteWhitespace().split('\\+|-|\\/|\\*');
		return removeDecimals(result);
	}

	/**
	 * Helper method that returns a list of field API names from filter statements.
	 */
	private List<String> getFields(List<FilterStatement> filterStatements) {
		List<String> result = new List<String>();
		for (FilterStatement fs :filterStatements) {
			result.add(fs.fieldName);
		}
		return removeDecimals(result);
	}

	/**
	 * Sanitation method that removes valid decimal string from list
	 * as we must not include them (SOQL will fail as it will not be a valid field name).
	 */
	private List<String> removeDecimals(List<String> potentialFields) {
		List<String> result = new List<String>();
		for (String fieldName : potentialFields) {
			//if not a decimal then incule to the list
			if (!decimalPattern.matcher(fieldName).find()) {
				result.add(fieldName);
			}
		}
		return result;
	}

	/**
	 * Helper method to parse calculation string.
	 * Piggybacking on filter statement inner class.
	 */
	private List<FilterStatement> parseCalculation(String calculationExpression) {
		List<FilterStatement> result = new List<FilterStatement>();
		//no need to do anything if no filter string
		if (String.isBlank(calculationExpression)) {
			return result;
		} else {
			//clean it up as there should be no whitespaces
			calculationExpression = calculationExpression.deleteWhitespace();
		}
		if (isValidationRun) {
			System.debug('Parsing calculationExpression: ' + calculationExpression);
		}
		//split string by supported logic operators (|| and &&)
		List<String> fields = calculationExpression.split('\\+|-|\\/|\\*');
		//now parse each statement
		for (Integer i = 0; i < fields.size(); i++) {
			//logicalOperator is what is between this and previous field
			String logicalOperator = '';
			if (i > 0) {
				//assumption is that fields are not going to get repeated in calculation expression
				logicalOperator = calculationExpression.substringBetween(fields[i-1], fields[i]);
				//remove used field and operator so that next iteration wouldn't fail in case expression has repeating fields or values
				//leaving current field as it will be needed in next iteration
				calculationExpression = calculationExpression.removeStart(fields[i-1] + logicalOperator);
			}
			//finally ready to create our FilterStatement
			FilterStatement fs = new FilterStatement(fields[i], null, null, logicalOperator);
			result.add(fs);
			if (isValidationRun) {
				System.debug('Statement: ' + fs);
				if (i > 0 && logicalOperator != '' && fields[i] == '') {
					System.debug('Missing right side of the calculation: ' + fs);
				}
			}
		}
		return result;
	}
	
	/**
	 * Helper method to parse filter string and return list of fields, operators and values that we can
	 * later use in applying the filter criteria.
	 * Filter string looks like:
	 * Impressions_Quantity__c > 0 && Name = Bundle Print || Name = Print
	 * Supported logical operators: ||, &&
	 * Supported comparison operators: <=, >=, <, >, !=, =
	 */
	private List<FilterStatement> parseFilter(String filterString) {
		List<FilterStatement> result = new List<FilterStatement>();
		//no need to do anything if no filter string
		if (String.isBlank(filterString)) {
			return result;
		}
		if (isValidationRun) {
			System.debug('Parsing filterString: ' + filterString);
		}
		//split string by supported logic operators (|| and &&)
		List<String> statements = filterString.split('\\|\\||&&');
		//now parse each statement
		for (Integer i = 0; i < statements.size(); i++) {
			//remove leading and trailing spaces
			statements[i] = statements[i].trim();
			List<String> components = statements[i].split('<=|>=|\\<|\\>|!=|=');
			//0 = field name, 1 = value, what is between is operator
			String operator = statements[i].substringBetween(components[0],components[1]);
			//logical operator is what is between this and previous statement
			String logicalOperator = '';
			if (i > 0) {
				logicalOperator = filterString.substringBetween(statements[i-1], statements[i]);
				//remove used parts so next iteration wouldn't fail in case expression has repeating fields or values
				//leaving current statement as it will be needed in next iteration
				filterString = filterString.removeStart(statements[i-1] + logicalOperator);
			}
			//finally ready to create our FilterStatement, field name and value are only trimmed
			FilterStatement fs = new FilterStatement(components[0].trim(), operator.deleteWhitespace(), components[1].trim(), logicalOperator.deleteWhitespace());
			result.add(fs);
			if (isValidationRun) {
				System.debug('Statement: ' + fs);
			}
		}
		return result;
	}

	/**
	 * Helper class to parse filter string into readable components.
	 */
	private class FilterStatement {
		public String fieldName {get; set;}
		public String comparisonOperator {get; set;}
		public String filterValue {get; set;}
		//operator between this and PREVIOUS filter statement, should be empty only if this statement is first one
		public String logicalOperator {get; set;}

		public FilterStatement(String fieldName, String comparisonOperator, String filterValue, String logicalOperator) {
			this.fieldName          = fieldName;
			this.comparisonOperator = comparisonOperator;
			this.filterValue        = filterValue;
			this.logicalOperator    = logicalOperator;
		}
	}

	//Custom exception class
	public class ObjectFieldUpdateMappingHandlerException extends Exception {}
}