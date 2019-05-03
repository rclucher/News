/*---------------------------------------------------------
* Author: IBM Dev
* Company: Bluewolf
* Date: Feb 2018
* Description: Added the below method for backlog#00891
* History:
---------------------------------------------------------*/
public without sharing class BookingLineItemRevenueDist_Helper
{  
    public static void setFiscalMonthId(List <BookingLineItemRevenueDist__c> lstBookingLineItem)
    { 
        Set <Date> StartDate_Set = new Set <Date>();  
        for(BookingLineItemRevenueDist__c blird :lstBookingLineItem){
            if(blird.StartDate__c!=null)
            {
                StartDate_Set.add(blird.StartDate__c);
            }
        }              
        Map <Date,String> returnValue_Map= new Map <Date,String>();
        List<FiscalCalendar__mdt> ncfcList = new List<FiscalCalendar__mdt>([SELECT Id, Date__c, FISC_MNTH_ID__c FROM FiscalCalendar__mdt WHERE Date__c in:StartDate_Set]);
        if(!ncfcList.isEmpty())
        {
            for (FiscalCalendar__mdt FCmonth : ncfcList)
            {
                returnValue_Map.put(FCmonth.Date__c,FCmonth.FISC_MNTH_ID__c);
            }
        }
        if (!returnValue_Map.isEmpty()){
            for(BookingLineItemRevenueDist__c blird :lstBookingLineItem){
                if(blird.StartDate__c!=null)
                {
                    blird.FiscalMonthId__c=returnValue_Map.get(blird.StartDate__c);
                }
            }
        }
    }
}