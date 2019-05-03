/**
 * Utility class
 */
public with sharing class CS_Utils {

	/**
	 * Returns the list of all fields to be used in dynamic SOQL
	 * excludes non custom fields
	 *
	 * @param so sObject name
	 * @return String csv list of all object fields
	 */
	public static String geCustomtSobjectFields(String so) {
		String fieldString;

		SObjectType sot = Schema.getGlobalDescribe().get(so);
		if (sot == null) {
			return null;
		}

		List<Schema.SObjectField> fields = sot.getDescribe().fields.getMap().values();

		fieldString = fields[0].getDescribe().LocalName;
		for (Integer i = 1; i < fields.size(); i++) {
			if (fields[i].getDescribe().LocalName != 'ContractId' && fields[i].getDescribe().custom) {
				fieldString += ',' + fields[i].getDescribe().LocalName;
			}
		}
		return fieldString;
	}

	/**
	 * Returns the list of all fields to be used in dynamic SOQL
	 *
	 * @param so sObject name
	 * @return String csv list of all object fields
	 */
	public static String getSobjectFields(String so) {
		String fieldString;

		SObjectType sot = Schema.getGlobalDescribe().get(so);
		if (sot == null) {
			return null;
		}

		List<Schema.SObjectField> fields = sot.getDescribe().fields.getMap().values();

		fieldString = fields[0].getDescribe().LocalName;
		for (Integer i = 1; i < fields.size(); i++) {
			if (fields[i].getDescribe().LocalName != 'ContractId')
				fieldString += ',' + fields[i].getDescribe().LocalName;
		}
		return fieldString;
	}

	/**
	 * Converts list of objects to CSV list to use in dynamic SOQL
	 *
	 * @param List<sObject>
	 * @return String
	 */
	public static String convertListToString(List<sObject> vList) {
		String listString = '(\'\')';
		if (vList.size() > 0) {
			listString = '(\''+vList[0].Id+'\'';
			for (Integer i = 1; i < vList.size(); i++) {
				listString += ',\'' + vList[i].Id+'\'';
			}
			listString += ')';
		}
		return listString;
	}

	/**
	 * Loads static resource
	 * @param String resourceName
	 * @return resource body
	 */
	public static Blob loadStaticResource(String resourceName) {
		List<StaticResource> sr = new List<StaticResource>();
		if (resourceName != null && resourceName != '') {
			sr = [
				select Body
				from
				StaticResource
				where Name = :resourceName
			];
		}
		return sr != null && sr.size() > 0 ? sr[0].Body : null;
	}

	/**
	 * Increments string by selecting last numeric part of the string and increasing it by 1.
	 * If input string does not end with number 1 will be appended.
	 * If input is null it will not throw an error nor it will be incremented!
	 * Example:
	 * input = B-0125 > B-0126
	 * input = B-0125-01 > B-0125-02
	 * input = B-0125- > B-0125-1
	 * input = SomeString > SomeString1
	 * input = null > null
	 */
	public static String incrementString(String input) {
		String result = input;
		if (input != null) {
			//getting only ending numeric part of the string, not depending on format or separators used
			Pattern myPattern = Pattern.compile('[0-9]+$');
			Matcher matcher   = myPattern.matcher(input);
			if (matcher.find()) {
				//Group 0 has full expression match
				String lastNumericPart = matcher.group(0);
				//maintain numeric part length i.e. 001 should be incremented to 002 not 2
				String newNumericPart = String.valueOf((Integer.valueOf(lastNumericPart) + 1)).leftPad(lastNumericPart.length(),'0');
				//cant use replace as B-0001-001 would be incremented to B-0002-002
				result = input.removeEnd(lastNumericPart) + newNumericPart;
			} else {
				//make it unique by appending 1, we could use 0001 but we don't know the length of the field
				result = input + '1';
			}
		}
		return result;
	}

	/**
	 * Returns field value from sObject as a string.
	 * Note: Field name representing relationship must have relationship name as you would write it in a Query
	 * i.e. Account.Payer_Account__r.Name
	 * @param     sObject  obj           Object to get the value from
	 * @param     String   fieldName     Field api name, can use relationship
	 * @return    String   Value of the field, if obj or key null or not valid returns empty string.
	 */
	public static String getFieldValueOfSafeDeep(sObject obj, String fieldName) {
		String value;
		if (obj != null && fieldName != null) {
			try {
				List<string> objectField = fieldName.split('\\.');     //splitting key by '.' will give us object and field name
				if (objectField.size() == 1) {
					// no '.' so we are working with the field from object, just get the value
					value = String.valueOf(obj.get(objectField[0]));
				} else if (objectField.size() == 2) {
					//we have '.' so 0 = Object, 1 = fieldName
					value = String.valueOf(obj.getSObject(objectField[0]).get(objectField[1]));
				} else if (objectField.size() == 3) {
					//we have '.' so 0 = Object, 1 = Object, 2 = fieldName
					value = String.valueOf(obj.getSObject(objectField[0]).getSObject(objectField[1]).get(objectField[2]));
				} else {
					//we have '.' so 0 = Object, 1 = Object, 2 = Object, 3 = fieldName
					value = String.valueOf(obj.getSObject(objectField[0]).getSObject(objectField[1]).getSObject(objectField[2]).get(objectField[3]));
				}
			} catch(Exception ex) {
				//catching all exceptions as both object name and field name can be invalid
				value = null;
			}
		}
		//sanitize the output in case we had invalid object/field
		return value == null ? '' : value;
	}
}