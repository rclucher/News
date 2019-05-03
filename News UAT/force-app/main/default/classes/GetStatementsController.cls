/**
* @description  GetStatementsController used in Lightning component GetStatementsCompController.js
* 
* @author       Paul Kang
* @date         2017-11-08
**/
public with sharing class GetStatementsController {

	@AuraEnabled
	public static String accessComputershare(Id recordId) {

		External_Account__c externalAccount = [SELECT Id, JDE_Account_Number__c FROM External_Account__c WHERE Id = :recordId];

		User user = [SELECT FirstName, LastName, Network_Username__c FROM User WHERE Id = :UserInfo.getUserId()];

		String token = GlobalViewPointGetToken.getAccessToken(externalAccount.JDE_Account_Number__c);

		//String token = GlobalViewPointGetToken.getAccessToken('3423706');
		System.debug('token returned in accessComputershare: ' + token);
		
		return token;
	}
}