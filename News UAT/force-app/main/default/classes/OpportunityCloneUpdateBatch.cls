global class OpportunityCloneUpdateBatch implements Database.Batchable<sObject> {
	
	String query = 'SELECT AccountId,Account.Name,Account_ID_18__c,Acct_Plan__c,Action_Plan__c,'
	+'ADM_ASM_Referral__c,Amount,Amount_GST_Incl__c,Approach_to_Win__c,Approved_Sales_Order_Number__c,'
	+'Background__c,Brand__c,Briefing_Form_Status__c,Briefing_Form__c,BypassContactValidation__c,'
	+'CampaignId,Campaign_Brief_Archived__c,Campaign_Brief_Form_Completed__c,Campaign_End_Date__c,'
	+'Campaign_Progress_Bar__c,Campaign_Progress__c,Campaign_Start_Date__c,Campaign_Status__c,'
	+'Campaign__c,Case_Origin_Id__c,Category_Expertise__c,cirrusadv__Created_by_Cirrus_Insight__c,'
	+'Classification__c,ClientPOReference__c,Client_Brand__c,Client_Feedback__c,Client_Key_Competitors__c,'
	+'CloseDate,CloseMonth__c,Close_Date_Past__c,Close_Date_Variance_Days__c,Closure_Summary__c,'
	+'CNG_Sales_Representitive__c,Commercial__c,Communication_tone__c,Competitor__c,Consumer_Behaviour__c,'
	+'Contact__c,ContractId,Count_Opportunity__c,Count_Sales_Order_Line_Item__c,CreatedById,'
	+'CreatedDate,Created_By_Briefing_Form__c,Created_by_Cirrus_Insight__c,Created_via_Salesforce1__c,'
	+'Creative_Budget__c,Creative_Charge_Cost_Breakdown__c,Creative_Services_Required__c,'
	+'CSCAP__Authoriser_Email_Address__c,CSCAP__PO_Number__c,CSCAP__VAT_Number__c,cscfga__TrackingNumber__c,'
	+'Current_Position__c,Customer_Books_Direct__c,Customer_Feedback__c,Data_Quality_Description__c,'
	+'Data_Quality_Score__c,Days_in_Stage__c,DB_Competitor__c,Description,Digital_Budget__c,'
	+'Digital_Charge_Cost_Breakdown__c,Earned__c,Error_Message__c,Events_Charge_Cost_Breakdown__c,'
	+'Event__c,ExpectedCloseDate__c,ExpectedRevenue,External_ID__c,ForecastCategory,ForecastCategoryName,'
	+'Goto_Action_Plan_Url__c,HasOpenActivity,HasOpportunityLineItem,HasOverdueTask,Has_an_Approved_SO__c,'
	+'Industry_Code__c,Insights_Required__c,Inspiration__c,IsClosed,IsDeleted,IsPrivate,IsWon,Id,'
	+'Is_Campaign_Start_Date_Changed__c,Is_Close_Date_Changed__c,Is_Scheduled_before_Closed__c,Is_Test__c,'
	+'JDE_Publication_Code__c,Joint_Response__c,LastActivityDate,LastModifiedById,LastModifiedDate,'
	+'LastReferencedDate,LastViewedDate,Last_Modified_Datetime__c,Last_Modified_via_Salesforce1__c,'
	+'Last_Updated_Briefing_Form__c,LeadSource,Lead_Conversion__c,Lead_Source_Detail_frml__c,'
	+'Linked_Opportunity__c,Linked_Opty_ID__c,Marketing_Budget__c,Marketing__c,Media_Budget_for_other_divisions__c,'
	+'Media_Budget__c,Mindset__c,mkto_si__MarketoAnalyzer__c,MonthId__c,Name,NextStep,Next_Steps__c,'
	+'NLM_Opportunity_Team_Member_1__c,NLM_Opportunity_Team_Member_2__c,NLM_Opportunity_Team_Member_3__c,'
	+'Non_standard_Client_Requests__c,NRM_Account_Number__c,NRM_Sales_Representative__c,OpportunityGroup__c,'
	+'Opportunity_Age__c,Opportunity_Platform_NewsXtend__c,Opportunity_Revenue_Date_Actual__c,Opportunity_Type__c,'
	+'Opty_Po1__c,Opty_SFDC_ID__c,Our_Brand_Relationship__c,Owned__c,OwnerCurrentRole__c,OwnerExternalId__c,'
	+'OwnerId,OwnerModifiedRecord__c,Owner_Division__c,Paid__c,PartnerAccountId,Partnership_Development__c,'
	+'Payer_Account__c,Pitch_material_due__c,Planner_Account__c,Portfolio_Code__c,Pricebook2Id,'
	+'Printing_Budget__c,Printing_Charge_Cost_Breakdown__c,Probability,Production_Creative_Actual__c,'
	+'Production_Creative_Charge__c,Production_Creative_Mark_up__c,Production_Digital_Actual__c,'
	+'Production_Digital_Charge__c,Production_Digital_Mark_up__c,Production_Events_Charge__c,Production_Events_Mark_up__c,'
	+'Production_Marketing_Actual__c,Production_Printing_Actual__c,Production_Printing_Charge__c,'
	+'Production_Printing_Mark_up__c,Product_Line_Count__c,Progress_Notes__c,Push_Counter__c,'
	+'Reason_Won_Lost__c,RecordTypeId,Referral_Source__c,Reporting_Requirements__c,Respondents__c,'
	+'Response_Due__c,RevenueType__c,Revenue_Close__c,Revenue_Group_L1__c,Revenue_Group__c,'
	+'Revenue_Schedule_Date_Alert__c,Revenue_Status__c,ROI__c,SalesSummary__c,Sales_Stage_L1__c,'
	+'Schedule_Date_before_Close_Date__c,Schedule_Date_Earliest__c,Segment__c,StageName,Stage_Changed__c,'
	+'Status__c,Success_Criteria__c,Success_metrics__c,SyncedQuoteId,SystemModstamp,The_Big_Idea__c,'
	+'TM1_Publication__c,TotalOpportunityQuantity,Total_actuals__c,Total_budget__c,Total_charge__c,'
	+'Total_Creative_Actual_Hours__c,Total_Creative_Estimated_Hours__c,Total_mark_up__c,Type,'
	+'Type_of_Platforms__c,Viewpath__Viewpath_Project_Formula__c,Viewpath__VP_Project__c,'
	+'What_does_the_client_want_to_communicate__c,What_do_we_want_the_audience_to_feel_l__c,'
	+'What_is_the_client_trying_to_achieve__c FROM Opportunity where StageName =\'Closed Won\' and  LastModifiedDate = LAST_N_DAYS:7 and AccountId!=null and (closeDate= last_N_YEARS:3 or closeDate = THIS_YEAR)';
	
	global OpportunityCloneUpdateBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
	
	if (scope.size() > 0) {

	 	List<OpportunityReport__c> opprepList = new List<OpportunityReport__c>();
	 	for(Opportunity  opp: scope) {

	 		OpportunityReport__c opprep = new OpportunityReport__c();
	 		opprep.ADM_ASM_Referral__c = opp.ADM_ASM_Referral__c;
            opprep.Opportunity_Id__c = opp.id;
			opprep.Advertising_Start_Date__c = opp.Campaign_Start_Date__c;
			opprep.Advertising_End_Date__c = opp.Campaign_End_Date__c;
			opprep.Amount__c = opp.Amount;
			opprep.Approach_to_Win__c=opp.Approach_to_Win__c;
			opprep.Approved_Sales_Order_Number__c =opp.Approved_Sales_Order_Number__c;
			opprep.Background__c = opp.Background__c;
			opprep.Client_Brand_Objectives__c  = opp.Brand__c;
			opprep.Bypass_Contact_Validation__c = opp.BypassContactValidation__c;
			opprep.Campaign_Brief_Form_Completed__c = opp.Campaign_Brief_Form_Completed__c;
			opprep.Campaign_Progress__c = opp.Campaign_Progress__c;
			opprep.Campaign_Status__c = opp.Campaign_Status__c;
			opprep.Case_Origin_Id__c = opp.Case_Origin_Id__c;
			opprep.Category_Expertise__c = opp.Category_Expertise__c;
			opprep.Classification__c = opp.Classification__c;
			opprep.Client_PO_Reference__c = opp.ClientPOReference__c;
			opprep.Client_Brand__c = opp.Client_Brand__c;
			opprep.Client_Feedback__c = opp.Client_Feedback__c;
			opprep.Client_Key_Competitors__c = opp.Client_Key_Competitors__c;
			opprep.Close_Date__c = opp.CloseDate;
			opprep.Closure_Summary__c = opp.Closure_Summary__c;		
			opprep.CNG_Sales_Representitive__c = opp.CNG_Sales_Representitive__c;
			opprep.Commercial__c = opp.Commercial__c;
			opprep.Communication_tone__c = opp.Communication_tone__c;
			opprep.Competitor__c = opp.Competitor__c;
			opprep.Consumer_Behaviour__c = opp.Consumer_Behaviour__c;
			opprep.CreatedById = opp.CreatedById;
			opprep.CreatedDate = opp.CreatedDate;
			opprep.Created_by_Cirrus_Insight__c = opp.Created_by_Cirrus_Insight__c;
			opprep.Created_via_Salesforce1__c = opp.Created_via_Salesforce1__c;
			opprep.Creative_Budget__c = opp.Creative_Budget__c;
			opprep.Creative_Charge_Cost_Breakdown__c = opp.Creative_Charge_Cost_Breakdown__c;
			opprep.Creative_Services_Required__c = opp.Creative_Services_Required__c;
			opprep.CS_Authoriser_Email_Address__c = opp.CSCAP__Authoriser_Email_Address__c;
			opprep.cs_PO_Number__c = opp.CSCAP__PO_Number__c;
			opprep.cs_VAT_Number__c = opp.CSCAP__VAT_Number__c;
			opprep.cs_Tracking_Number__c = opp.cscfga__TrackingNumber__c;
			opprep.Current_Position__c = opp.Current_Position__c;
			opprep.Customer_Books_Direct__c = opp.Customer_Books_Direct__c;
			opprep.Customer_Feedback__c = opp.Customer_Feedback__c;
			opprep.DB_Competitor__c = opp.DB_Competitor__c;
			opprep.Description__c = opp.Description;
			opprep.Digital_Budget__c = opp.Digital_Budget__c;
			opprep.Digital_Charge_Cost_Breakdown__c = opp.Digital_Charge_Cost_Breakdown__c;
			opprep.Earned__c = opp.Earned__c;
			opprep.Error_Message__c = opp.Error_Message__c;
			opprep.Events_Charge_Cost_Breakdown__c = opp.Events_Charge_Cost_Breakdown__c;
			opprep.Event__c = opp.Event__c;
			opprep.ExpectedCloseDate__c = opp.ExpectedCloseDate__c; 
			opprep.ExpectedRevenue__c = opp.ExpectedRevenue;
			opprep.Forecast_Category__c = opp.ForecastCategoryName;
			opprep.Has_an_Approved_SO__c = opp.Has_an_Approved_SO__c;
			//opprep.Id = opp.Id;
			opprep.Insights_Required__c = opp.Insights_Required__c;
			opprep.Inspiration__c = opp.Inspiration__c;
			opprep.Is_Campaign_Start_Date_Changed__c = opp.Is_Campaign_Start_Date_Changed__c;
			opprep.Is_Close_Date_Changed__c = opp.Is_Close_Date_Changed__c;
			opprep.Joint_Response__c = opp.Joint_Response__c;
			opprep.LastModifiedById = opp.LastModifiedById;
			opprep.LastModifiedDate = opp.LastModifiedDate;
			opprep.Last_Modified_via_Salesforce1__c = opp.Last_Modified_via_Salesforce1__c;
			opprep.LeadSource__c = opp.LeadSource;
			opprep.Lead_Conversion__c = opp.Lead_Conversion__c;
			opprep.Marketing_Budget__c = opp.Marketing_Budget__c;
			opprep.Marketing__c = opp.Marketing__c;
			opprep.Media_Budget_for_other_divisions__c = opp.Media_Budget_for_other_divisions__c;
			opprep.Media_Budget__c = opp.Media_Budget__c;
			opprep.Mindset__c = opp.Mindset__c;
			opprep.MonthId__c = opp.MonthId__c;
			opprep.Name = opp.Name;
			opprep.Next_Steps__c = opp.Next_Steps__c;
			opprep.Non_standard_Client_Requests__c = opp.Non_standard_Client_Requests__c;
			opprep.NRM_Account_Number__c = opp.NRM_Account_Number__c;
			opprep.NRM_Sales_Representative__c = opp.NRM_Sales_Representative__c;
			opprep.Opportunity_Type__c = opp.Opportunity_Type__c;
			opprep.Our_Brand_Relationship__c = opp.Our_Brand_Relationship__c;
			opprep.Partnership_Development__c = opp.Partnership_Development__c;
			opprep.Pitch_material_due__c = opp.Pitch_material_due__c;
			opprep.Portfolio_Code__c = opp.Portfolio_Code__c;
			opprep.Production_Printing_Budget__c = opp.Printing_Budget__c;
			opprep.Printing_Charge_Cost_Breakdown__c = opp.Printing_Charge_Cost_Breakdown__c;
			opprep.Probability__c = opp.Probability;
			opprep.Production_Creative_Actual__c = opp.Production_Creative_Actual__c; 
			opprep.Production_Creative_Mark_up__c = opp.Production_Creative_Mark_up__c;
			opprep.Production_Digital_Actual__c = opp.Production_Digital_Actual__c;
			opprep.Production_Digital_Mark_up__c = opp.Production_Digital_Mark_up__c;
			opprep.Production_Events_Mark_up__c = opp.Production_Events_Mark_up__c;
			opprep.Production_Printing_Actual__c = opp.Production_Printing_Actual__c;
			opprep.Production_Printing_Mark_up__c = opp.Production_Printing_Mark_up__c; 
			opprep.Progress_Notes__c = opp.Progress_Notes__c;
			opprep.Push_Counter__c = opp.Push_Counter__c;
			opprep.Reason_Won_Lost__c = opp.Reason_Won_Lost__c;
			opprep.Referral_Source__c = opp.Referral_Source__c;
			opprep.Reporting_Requirements__c = opp.Reporting_Requirements__c;
			opprep.Respondents__c = opp.Respondents__c;
			opprep.Response_Due__c = opp.Response_Due__c;
			opprep.Revenue_Group__c = opp.Revenue_Group__c;
			opprep.Opportunity_Platform__c = opp.OpportunityGroup__c;
			opprep.ROI__c = opp.ROI__c;
			opprep.Segment__c = opp.Segment__c;
			opprep.Stage__c = opp.StageName; 
			opprep.Stage_Changed__c = opp.Stage_Changed__c;
			opprep.Success_Criteria__c = opp.Success_Criteria__c;
			opprep.Success_metrics__c = opp.Success_metrics__c;
			opprep.The_Big_Idea__c = opp.The_Big_Idea__c;
			opprep.What_does_the_client_want_to_communica__c = opp.What_does_the_client_want_to_communicate__c;
			opprep.What_do_we_want_the_audience_to_feel__c = opp.What_do_we_want_the_audience_to_feel_l__c; 
	 		opprep.What_is_the_client_trying_to_achieve__c = opp.What_is_the_client_trying_to_achieve__c;
	 		opprep.Account_Id__c = opp.AccountId;
	 		opprep.Account_Name__c = opp.Account.Name;
	 		opprep.Opp_Name__c = opp.Name;
	 		opprepList.add(opprep);
	 		}

	 	   Database.upsertResult[] saveResultList = Database.upsert(opprepList, false);
	 	   for (Database.upsertResult sr : saveResultList) {
    			if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        		//System.debug('Successfully updated Opportunity.' + sr.getId());
   			 }
   			 else {
        // Operation failed, so get all errors                
        	for(Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Opportunity fields that affected this error: ' + err.getFields());
        }
    }
}
	
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		  AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            from AsyncApexJob where Id =:BC.getJobId()];
          
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'shared_salesforce@news.com.au'};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Opportunity Clone Update object Batch to Custom object OpportunityReport__c ' + a.Status);
            mail.setPlainTextBody('Opportunity Clone Update object to OpportunityReport__c,number of records processed ' + a.TotalJobItems +
           'with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

         
         OpportunityCloneDeleteBatch batchJob = new OpportunityCloneDeleteBatch();
        Id batchInstanceId = Database.executeBatch(batchJob, 200);

	}
	
}