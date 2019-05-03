/*------------------------------------------------------------------------------
author: David Dawson
company: Bluewolf

description: 
This class facilitates accessing of the NewsCorp fiscal calendar
programatically through the custom metadata type object (__mdt)

history:
* 06/05/2016 Class created
* 08/05/2016 monthId functionality created to accept dates and return their month ids
* 11/05/2016 DT ID functionality created to accept dates and return their DT ID
------------------------------------------------------------------------------*/

public class NewsCorpFiscalCalendar {

	//provides the month id for all dates provided in a list. Return type is Map<Provided Date, Month Id>.
	public Static Map<Date, String> monthID(List<Date> dateList){

		Map<String, Date> idMap = fiscDTID(dateList);
		Set<String> idSet = idMap.keySet();
		Map<Date, String> refMap = new Map<Date, String>();

		List<FiscalCalendar__mdt> fiscList = new List<FiscalCalendar__mdt>([SELECT Id, DT_ID__c, FISC_MNTH_ID__c FROM FiscalCalendar__mdt WHERE DT_ID__c IN :idSet]);

		for(FiscalCalendar__mdt fisc :fiscList){
			refMap.put(idMap.get(fisc.DT_ID__c), fisc.FISC_MNTH_ID__c);
		}

		return refMap;

	}

	//provides the DT ID for all dates provided in a list. Return type is Map<Provided Date, DT ID>.
	public Static Map<String, Date> fiscDTID(List<Date> dateList){

		Map<String, Date> fiscList = new Map<String, Date>();

		for(Date d :dateList){
			String day = String.valueOf(d.day());
			String month = String.valueOf(d.month());
			String year = String.valueOf(d.year());

			if(day.length() < 2){
				day = '0' + day;
			}
			if(month.length() < 2){
				month = '0' + month;
			}

			String concat = year + month + day;
			fiscList.put(concat, d);		

		}

		return fiscList;
	}

	public Static Map<Date, FiscalCalendar__mdt> returnFiscalMonths (Date startDate, Date endDate){

		List<FiscalCalendar__mdt> fiscList = new List<FiscalCalendar__mdt>([SELECT Id, DT_ID__c, FISC_MNTH_ID__c , Date__c, FISC_DOY_NR__c, FISC_HFYR_NM__c, 
			FISC_HFYR_NR__c, FISC_HFYR_SNAM__c, FISC_MNTH_FIRST_DAY_DT__c, FISC_MNTH_LAST_DAY_DT__c, FISC_MNTH_NM__c, FISC_MNTH_NR__c, FISC_MNTH_SNAM__c,
			FISC_QRTR_NM__c, FISC_QRTR_NR__c, FISC_QRTR_SNAM__c, FISC_WEEK_FIRST_DAY_DT__c, FISC_WEEK_ID__c, FISC_WEEK_LAST_DAY_DT__c, FISC_WEEK_NR__c,
			FISC_YEAR_FIRST_DAY_DT__c, FISC_YEAR_ID__c, FISC_YEAR_LAST_DAY_DT__c, FISC_YEAR_MNTH_DS__c, FISC_YEAR_NR__c, FISC_YEAR_QRTR_DS__c
			FROM FiscalCalendar__mdt WHERE Date__c >= :startDate AND Date__c <= :endDate ORDER BY FISC_MNTH_ID__c]);

		Map<Date, FiscalCalendar__mdt> fiscalMap = new Map<Date, FiscalCalendar__mdt>();
		for(FiscalCalendar__mdt f : fiscList){

			fiscalMap.put(f.Date__c, f);
		}

		return fiscalMap;


	}

}