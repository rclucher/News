/*---------------------------------------------------------
 * author: David Dawson
 * Company: Bluewolf
 * description: This controller handles all trigger functionality specific to the Sales Summary object
 *
 * History:
 * 20/05/2016   David Dawson  created trigger. Added fiscalMonthId class and the vaidateExternalId class
 * 12/08/2016   David Dawson  removed the fiscalMonthId class and added the populateFiscalInformation class
---------------------------------------------------------*/
public class SalesSummaryTriggerHandler {
	//populate the sales summary record with information regarding it's fiscal month
	public Void populateFiscalInformation(){
		system.debug('SALES SUMMARY RECORDS ' + (List<SalesSummary__c>)Trigger.NEW);
		Set<String> monthIds = new Set<String>();
		for(SalesSummary__c ss:(List<SalesSummary__c>)Trigger.NEW){
			if(!monthIds.contains(ss.MonthId__c)){
				monthIds.add(ss.MonthId__c);
			}
		}

		Map<String, FiscalCalendar__mdt> ncfcMap = new Map<String, FiscalCalendar__mdt>();
		List<FiscalCalendar__mdt> ncfcList = new List<FiscalCalendar__mdt>([SELECT Id, DT_ID__c, Date__c, FISC_MNTH_FIRST_DAY_DT__c, FISC_MNTH_LAST_DAY_DT__c, FISC_MNTH_NM__c, FISC_MNTH_ID__c FROM FiscalCalendar__mdt WHERE FISC_MNTH_ID__c IN :monthIds]);
		for(FiscalCalendar__mdt ncfc :ncfcList){
			if(!ncfcMap.containsKey(ncfc.FISC_MNTH_ID__c)){
				ncfcMap.put(ncfc.FISC_MNTH_ID__c, ncfc);
			}
		}

		if(!ncfcMap.isEmpty()){
			for(SalesSummary__c ss:(List<SalesSummary__c>)Trigger.NEW){
				if(ncfcMap.containsKey(ss.MonthId__c)){
					ss.Month__c = ncfcMap.get(ss.MonthId__c).FISC_MNTH_NM__c;
					ss.FiscalMonthStartDate__c = ncfcMap.get(ss.MonthId__c).FISC_MNTH_FIRST_DAY_DT__c;
					ss.FiscalMonthEndDate__c = ncfcMap.get(ss.MonthId__c).FISC_MNTH_LAST_DAY_DT__c;
				}
			}
		}
	}

	//ensure the external id generated by Salesforce is the same provided via the ESB
	public Void validateExternalId(){
		for(SalesSummary__c ss :(List<SalesSummary__c>)Trigger.NEW){
			String generatedExternalId = '';
			
			//Generate the external id from within salesforce
			generatedExternalId = ExternalIdUtility.SalesSummaryExternalId(ss.UserExternalId__c, ss.Role__c, ss.Type__c, ss.BookingRevenueType__c, ss.MonthId__c);

			//compare the external ids and ensure that the same one is generated
			if(ss.ExternalId__c.toLowerCase() != generatedExternalId.toLowerCase()){
				ss.addError('The external Id on this record does not match the one that Salesforce generates.\nSalesforce: ' + generatedExternalId + '\nCurrent External Id: ' + ss.ExternalId__c);
			}
		}
	}
}