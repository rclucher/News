public with sharing class FieldHighlightsController {

	@AuraEnabled
	public static List<String> getFieldSet(String sObjectName, String fieldsetName) {

		System.debug(LoggingLevel.ERROR, '@sObjectName: ' + sObjectName);
		Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe(); 
		Schema.SObjectType sObjectType = globalDescribeMap.get(sObjectName);
		Schema.DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();

		Schema.FieldSet fieldSetObj = describeSObjectResult.FieldSets.getMap().get(fieldSetName);

		List<String> fieldNames = new List<String>();

		for (Schema.FieldSetMember fieldSetMember : fieldSetObj.getFields()) {
			fieldNames.add(fieldSetMember.getFieldPath());
		}

		return fieldNames; 
	}
}