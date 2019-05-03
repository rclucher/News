//<!--
//	This is the one of many controllers to provide the Campaign Execution functionality in Lightning Sales Console.

//	Author: LBK
//	Date: 	2018-10-24
//-->
public class CampaignExecutionSearchWrapper{
    	@AuraEnabled public String 	searchLead_Contact_Name {set;get;}
    	@AuraEnabled public String 	searchCompanyOrAccount {set;get;}
    	@AuraEnabled public String 	searchExecution_Status {set;get;}
    	@AuraEnabled public String 	searchLast_Booking_Line_Item_Publication_Divs {set;get;}
    	@AuraEnabled public String 	searchStatus {set;get;}
    	@AuraEnabled public String 	filterCall_Count {set;get;}
		@AuraEnabled public String 	searchCall_Count {set;get;}
		@AuraEnabled public String 	filterAge_In_List {set;get;}
		@AuraEnabled public String 	searchAge_In_List {set;get;}
		@AuraEnabled public String 	filterLast_Booking_Value {set;get;}
		@AuraEnabled public String 	searchLast_Booking_Value {set;get;}	
		@AuraEnabled public String 	filterResponse_DateTime {set;get;}
		@AuraEnabled public String 	filterCall_Back_Date {set;get;}
		@AuraEnabled public Date 	searchResponse_DateTime {set;get;}
		@AuraEnabled public Date 	searchCall_Back_Date {set;get;}

		@AuraEnabled public Boolean includeFilterOptions {set;get;}
    }