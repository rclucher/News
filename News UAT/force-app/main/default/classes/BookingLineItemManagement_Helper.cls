/*---------------------------------------------------------
 * author: Bohao Chen
 * Company: Salesforce.com
 * description: This controller is for trigger BookingLineItemManagement
 *  1.R-0822: Add trigger on Booking Line Item to set Salesforce Product based on Publication & Ad Type.
 *
 * History:
 * 02/09/2013   Bohao Chen  Created
 * 15/08/2016   Peter Charalambous  Modified
 * 25/09/2018   Hari Kundrapu - Added function findEmmaReaderishipbyPubCode
 *
 * Description: Revenue Reporting R1.2 Solution: Added distributeRevenue/deleteDistributedRevenue functions.
---------------------------------------------------------*/
public with sharing class BookingLineItemManagement_Helper
{
    public static Map<String, String> findProductIdByPublicationCodeAndAdType(List<Booking_Line_Item__c> bookingItems,
                                                                          Set<String> publicationAdTypeKeys)
    {
        Map<String, String> productIdByPublicationAndAdType = new Map<String, String>();
        
        for(Publication_Product__c pubProd : [Select p.Product__c, p.Publication_AdType__c
                                            From Publication_Product__c p
                                            Where p.Publication_AdType__c IN: publicationAdTypeKeys])
        {
            productIdByPublicationAndAdType.put(pubProd.Publication_AdType__c, pubProd.Product__c);
        }
        
        return productIdByPublicationAndAdType;
    }
   

    // Updated by Bohao Chen for JIRA SFE-4 on 26/05/2014
    public static List<FiscalYearSettings> fiscalYearSettingByStartDate 
    { 
        get{ return fiscalYearSettingByStartDate = fiscalYearSettingByStartDate == null ? 
              getFiscalYearSetting() : fiscalYearSettingByStartDate; } 
        set; 
    }

    private static List<FiscalYearSettings> getFiscalYearSetting()
    {
        system.debug(logginglevel.Error, '===year setting query===');
        List<FiscalYearSettings> fySettingList = [Select f.WeekStartDay, f.StartDate, f.EndDate 
                                                From FiscalYearSettings f
                                                Where f.IsStandardYear = false];
        
        return fySettingList;
    }
    /* 
     * this function is used by trigger BookingLineItemManagement
     * it checks whether booking line item run date has fiscal calendar in setting.
     * It also generate map collection of week start day for booking line item run date
     * with run date as key so it is easy to find out week start day based on booking line
     * item run date
     * Note that we need to set up weekStartDayByRunDate MAP collection in order for other booking line item with same product to
     * know which week it belongs to according to their run date. 
     */
    public static Boolean isRunDateInFiscalCalendar(Booking_Line_Item__c bookingLineItem)
    {
        // find week start day in current fiscal year for run date
        boolean found = false;
        
        for(FiscalYearSettings fySetting : fiscalYearSettingByStartDate)
        {
            if(fySetting.StartDate <= bookingLineItem.Run_Date__c && fySetting.EndDate >= bookingLineItem.Run_Date__c)
            {
                found = true;
                break;
            }
        }
        
        if(!found)
        {
            bookingLineItem.addError('Could not find fiscal year calendar based on current booking line item run date. <br />Please change the run date or contact your administrator to add fiscal year calendar for current run date', false);
            return true;
        }
        
        return false;
    }
    // Updated Ends

    //wrapper class to build the date calculations
        public class FiscalWrapper{
            public String monthId {get;set;}
            public String monthName {get;set;}
            public Date dateStart {get;set;}
            public Date dateEnd {get;set;}

            public FiscalWrapper(){
                monthId = '';
                dateStart = null;
                dateEnd = null;
                monthName = '';
            }
        }

     /* 
     * This function is used by trigger BookingLineItemManagement.
     * This function calls the 'returnFiscalMonths' function from the NewsCorpFiscalCalendar
     * class and returns a map of fiscal days between the start and end date.
     * The FiscalWrapper class above is placed in a map, using the Month ID as the key.
     * The returned list is then looped through beginning at the start date and is incremented by 1
     * until it equals the end date. The end date in the current record of the wrapper class is populated and a
     * new record in the wrapper class is created. For each record in the map, a 'Booking Line Item Revenue Dist'
     * record is created.
     */    

    public static Void distributeRevenue(){

        Map<String, FiscalWrapper> fiscalRevenueDist = new Map<String, FiscalWrapper>();
        Map<Id, Map<String, FiscalWrapper>> blifrdMap = new Map<Id, Map<String, FiscalWrapper>>();
        Date startDate;
        Date endDate;

        for(Booking_Line_Item__c bli : (List<Booking_Line_Item__c>)Trigger.NEW){
            if(startDate == null || bli.Run_Date__c < startDate){
                startDate = bli.Run_Date__c;
            }
            if(endDate == null || bli.Stop_On_Web_Date__c > endDate){
                endDate = bli.Stop_On_Web_Date__c;
            }
        }

        Map<Date, FiscalCalendar__mdt> fiscalMonths = NewsCorpFiscalCalendar.returnFiscalMonths(startDate, endDate);
        
        //process each booking line item record
        for(Booking_Line_Item__c bli :(List<Booking_Line_Item__c>)Trigger.NEW){
            Date bliStartDate = bli.Run_Date__c;
            Date bliEndDate;
            if(bli.Stop_On_Web_Date__c != null){
                bliEndDate = bli.Stop_On_Web_Date__c;
            }else{
                bliEndDate = bli.Run_Date__c;
            }

            FiscalWrapper fw = new FiscalWrapper();

            for(integer i=0;i<bliStartDate.daysBetween(bliEndDate);i++)
            {
                if(fw.monthId == '' || fw.monthId != fiscalMonths.get(bliStartDate.addDays(i)).FISC_MNTH_ID__c){
                    if(fw.monthId != ''){
                        //populate the end date of the current fiscal calendar record and add it to the Map
                        fw.dateEnd = bliStartDate.addDays(i) - 1;
                        fiscalRevenueDist.put(fw.monthId, fw);
                    }
                    //create a new fiscal wrapper record
                    fw = new FiscalWrapper();
                    fw.monthId = fiscalMonths.get(bliStartDate.addDays(i)).FISC_MNTH_ID__c;
                    fw.dateStart = bliStartDate.addDays(i);
                    fw.monthName = fiscalMonths.get(bliStartDate.addDays(i)).FISC_MNTH_NM__c;
                }

            }
            //close the last open fiscal wrapper record and add to the map
            fw.dateEnd = bliEndDate;
            fiscalRevenueDist.put(fw.monthId, fw);
        
            //put the generated map back into the map containing all Booking Line Item record calculations
            blifrdMap.put(bli.Id, fiscalRevenueDist);

        }

        List<BookingLineItemRevenueDist__c> bliDistList = new List<BookingLineItemRevenueDist__c>();
        for(String bliRcrdKey : blifrdMap.keySet()){
            for(String fiscalRevDistKey : blifrdMap.get(bliRcrdKey).keySet()){
                BookingLineItemRevenueDist__c bliDist = new BookingLineItemRevenueDist__c();
                bliDist.EndDate__c = blifrdMap.get(bliRcrdKey).get(fiscalRevDistKey).dateEnd;
                bliDist.StartDate__c = blifrdMap.get(bliRcrdKey).get(fiscalRevDistKey).dateStart;
                bliDist.FiscalMonthId__c = blifrdMap.get(bliRcrdKey).get(fiscalRevDistKey).monthId;
                bliDist.FiscalMonthName__c = blifrdMap.get(bliRcrdKey).get(fiscalRevDistKey).monthName;
                bliDist.BookingLineItem__c = bliRcrdKey;
                bliDistList.add(bliDist);
            }
        }
        try{
            insert bliDistList;
        }
        catch(Exception e){
            ExLog.log(e, 'config', bliDistList, 'Failed to insert Booking Line Item Distribution records.');
        }

    }
    /*
     * This function is used by trigger BookingLineItemManagement.
     * It queries the Booking Line Item Revenue Dist object and deletes the returned list
    */ 
    public static Void deleteDistributedRevenue(List<Booking_Line_Item__c> bliList){

        List<BookingLineItemRevenueDist__c> bliRevDistList = new List<BookingLineItemRevenueDist__c>([SELECT Id, EndDate__c, FiscalMonthId__c, FiscalMonthName__c, 
            StartDate__c FROM BookingLineItemRevenueDist__c WHERE BookingLineItem__c IN :bliList]);
        try{
            delete bliRevDistList;
        }
        catch(Exception e){
            ExLog.log(e, 'config', bliRevDistList, 'Failed to delete Booking Line Item Revenue Distribution records.');
        }
    }


     /* Added by Hari Kundrapu for Jira NX-853
     * This function(findEmmaReaderishipbyPubCode) will look for Emma Object Records by Publication__c (of BLI) and returns the values to Trigger to Update Readership and Circulation
     * Added to decommission Process Builder and Flow which is touching Too Many SOQL queries limit on Bulk updates.
    */
public static Map<String,EMMA_Readership_and_Circulation_Data__c> findEmmaReaderishipbyPubCode(Set<String> pubCodes)                                                         
    {
        Map<String,EMMA_Readership_and_Circulation_Data__c> emmas = new Map<String,EMMA_Readership_and_Circulation_Data__c>();
        system.debug('PubCodes: '+ pubCodes);
        for(EMMA_Readership_and_Circulation_Data__c pubEmma : [Select Id, Readership_Monday_Friday__c, Readership_Saturday_Sunday__c, Circulation__c, Genera_Publication_Code__c  
                                    From EMMA_Readership_and_Circulation_Data__c
                                    Where Genera_Publication_Code__c IN: pubCodes])
        {
            emmas.put(pubEmma.Genera_Publication_Code__c,pubEmma);
        }
        return emmas;
    }
    
}