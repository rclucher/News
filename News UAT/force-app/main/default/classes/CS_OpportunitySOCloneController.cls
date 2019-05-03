/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_OpportunitySOCloneController
* @testClassName    CS_OpportunitySOCloneControllerTest
* @description      Controller for Opportunity re-order functionality
*/
public with sharing class CS_OpportunitySOCloneController {
	final static String ERROR_CANT_NOT_REORDER = 'Please check the status of the Campaign. Re-Order is only possible on Ended Campaigns.';
	final static String ERROR_CAMPAIGN_STILL_LIVE = 'This campaign is still Live. You cannot re-order at this time.';

	/**
    * @name         : clone
    * @description  : deep clone opportunity with so, so lines and all the related records
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String sourceOppyId, String cloneOppyName
    * @return       : String
    */
	@AuraEnabled
	public static String clone(String sourceOppyId, String cloneOppyName){
		CS_LightningResponse res = new CS_LightningResponse();

		
		try{
			csmso__Sales_Order__c so = getApprovedSalesOrder(sourceOppyId);
			
			if(so!=null){
				Opportunity clonedOppy = cloneOpportunity(sourceOppyId, cloneOppyName);
				cloneCampaignBriefAnswers(sourceOppyId, clonedOppy.Id);
				cloneOpportunityProducts(sourceOppyId, clonedOppy.Id);
				String result = csmso.SalesOrderSupport.cloneSalesOrderForOpportunity(so.Id, clonedOppy.Id);

				res.code = 2000;
				res.message = 'success';
				res.details = clonedOppy.Id;
			}else{
				res.code = 2100;
				res.message = 'error';
				res.details = ERROR_CANT_NOT_REORDER;
			}
			
		}catch(Exception ex){
			res.code = 2900;
			res.message = 'error';
			res.details = ex.getMessage();
		}
	
		return JSON.serialize(res);
	}

	/**
    * @name         : cloneOpportunity
    * @description  : clone an opportunity
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String sourceOppyId, String cloneOppyName
    * @return       : Opportunity
    */
	public static Opportunity cloneOpportunity(String sourceOppyId, String cloneOppyName){

		Set<String> fields = Schema.getGlobalDescribe().get('Opportunity').getDescribe().fields.getMap().keySet();

		Opportunity optySource = Database.query('SELECT ' + String.join(new List<String>(fields), ',') + ' from Opportunity where Id = \'' +  sourceOppyId + '\'');

		Opportunity optyClone = optySource.clone(false,false,false,false);
		optyClone.Revenue_Group__c 			= optySource.Revenue_Group__c;
		optyClone.StageName 				= 'Develop/Present Solution';
		optyClone.Probability 				= 30;
		optyClone.Has_an_Approved_SO__c 	= false;
		optyClone.Approved_Sales_Order_Number__c 	= '';
		optyClone.Campaign_Brief_Form_Completed__c 	= false;
		optyClone.Is_Campaign_Start_Date_Changed__c = false;
		optyClone.Is_Close_Date_Changed__c 			= false;
		optyClone.Campaign_Start_Date__c 			= null;
		optyClone.Campaign_End_Date__c 				= null;
		optyClone.CloseDate 				= System.today() + 10;
		optyClone.Campaign_Progress__c 		= null;
		optyClone.ExpectedCloseDate__c 		= null;
		optyClone.Pitch_material_due__c 	= null;
		optyClone.Response_Due__c 			= null;
		optyClone.Stage_Changed__c 			= null;
		optyClone.Name 						= cloneOppyName != null ? cloneOppyName : optySource.Name + ' Reorder - ' + String.valueOf(Date.today()).substring(0,10);
		

		insert optyClone;
		system.debug('****** optyClone='+optyClone);
		return optyClone;
	}

	/**
    * @name         : getApprovedSalesOrder
    * @description  : retrieved sales order record that meets the criteria under opportunity
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String oppyId
    * @return       : csmso__Sales_Order__c
    */
	public static csmso__Sales_Order__c getApprovedSalesOrder(String oppyId){
		List<csmso__Sales_Order__c> soList = [Select Id, (Select Id, Overall_Status__c, Status__c From Orders__r)
												From csmso__Sales_Order__c 
												Where 	csmso__Opportunity__c =: oppyId
														And csmso__Opportunity__r.StageName = 'Closed Won'
														And (csmso__Status__c = 'Manually Approved' 
														Or csmso__Status__c = 'Externally Approved') 
												Limit 1];
		csmso__Sales_Order__c so = (!soList.isEmpty()) ? soList.get(0) : null;
		if(so != null && so.Orders__r != null){
			Order__c co = so.Orders__r[0];
			if(co.Status__c != 'Campaign Ended'){
				String errorMessage = (co.Status__c == 'Campaign Live') ? ERROR_CAMPAIGN_STILL_LIVE : ERROR_CANT_NOT_REORDER;
				throw new OpportunitySOCloneException(errorMessage);
			}
		}

		return so;
	}

	/**
    * @name         : cloneOpportunityProducts
    * @description  : clone opportunity products under opportunity
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String sourceOppyId, String cloneOppyId
    * @return       : n/a
    */
	public static void cloneOpportunityProducts(String sourceOppyId, String cloneOppyId){
		Set<String> fields = Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().keySet();
		List<OpportunityLineItem> oppyProducts = Database.query('SELECT ' + String.join(new List<String>(fields), ',') + ' from OpportunityLineItem where OpportunityId = \'' +  sourceOppyId + '\'');

		List<OpportunityLineItem> oppyProductsClone = new List<OpportunityLineItem>();
		for(OpportunityLineItem prod: oppyProducts){
			OpportunityLineItem prodClone = prod.clone(true, false, false, false);
			prodClone.Id = null;
			prodClone.OpportunityId = cloneOppyId;
			prodClone.UnitPrice = null;
			oppyProductsClone.add(prodClone);
		}
		if(!oppyProductsClone.isEmpty()){
			insert oppyProductsClone;
		}
	}

	/**
    * @name         : cloneCampaignBriefAnswers
    * @description  : clone all campaign brief answers 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String sourceOppyId, String cloneOppyId
    * @return       : n/a
    */
	public static void cloneCampaignBriefAnswers(String sourceOppyId, String cloneOppyId){
		Set<String> fields = Schema.getGlobalDescribe().get('Answer_to_Rule__c').getDescribe().fields.getMap().keySet();

		List<Answer_to_Rule__c> answerRules = Database.query('SELECT ' + String.join(new List<String>(fields), ',') + ' from Answer_to_Rule__c where Opportunity__c = \'' +  sourceOppyId + '\'');

		List<Answer_to_Rule__c> answerRulesClone = new List<Answer_to_Rule__c>();
		for(Answer_to_Rule__c ar: answerRules){
			Answer_to_Rule__c arClone = ar.clone(true, false, false, false);
			arClone.Opportunity__c = cloneOppyId;
			arClone.Id = null;
			answerRulesClone.add(arClone);
		}

		if(!answerRulesClone.isEmpty()){
			insert answerRulesClone;
		}
		
	}

	public class OpportunitySOCloneException extends Exception {}
}