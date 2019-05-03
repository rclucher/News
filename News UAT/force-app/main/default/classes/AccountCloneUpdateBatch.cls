//Update AccountReport batch job to copy(delta) data from Account Object to Clone Object AccountReport

/** 
 *
 * @author      Lakshmi Mohan 
 * @description Batch Apex toto copy(delta) data from Account Object to Clone Object AccountReport
 **/
global class AccountCloneUpdateBatch implements Database.Batchable<sObject> {
	
	String query = 'SELECT 	ABN_Exempt_Reason__c,ABN_Exempt__c,ABN_Link__c,ABN_Status__c,ABN_Validation__c,AccountNumber,AccountSource,Account_AdPoint_Id__pc,Account_Last_Modified__c,'
        			+'Account_Overview__c,Account_Po1__c,Account_Record_Type__c,Account_Synopsis__c,Account_Type__c,Accredited__c,Acct_Alert_Status__c,'
        			+'Acct_SFDC_ID__c,AdPoint_Id__c,AdPoint_Id__pc,AdPoint_User_Id__c,Alert_Status__pc,AnnualRevenue,ANZ_Package__c,ANZ_Package__pc,AssistantPhone_DNC_Contactable__c,'
        			+'AssistantPhone_DNC_Contactable__pc,AssistantPhone_DNC_Status__pc,AssistantPhone_DNC_Washed_Date__pc,AssistantPhone_on_DNC__pc,Become_Primary_Contact__pc,'
        			+'BillingAddress,BillingCity,BillingCountry,BillingGeocodeAccuracy,BillingLatitude,BillingLongitude,BillingPostalCode,BillingState,BillingStreet,Billing_Status__c,'
        			+'Blacklist_Reason_Digital__c,Browse_Industry_List__c,Business_Size__c,Channel_Opt_In_Email__pc,Channel_Opt_In_Phone__pc,'
        			+'Channel_Opt_In_SMS__pc,cirrusadv__Created_by_Cirrus_Insight__c,cirrusadv__Created_by_Cirrus_Insight__pc,Client_Trading_Activity__c,Community_Parent_Account__c,'
        			+'Consortium_Current_FY__c,Consortium_Previous_FY__c,Consortium_Total__c,Consortium__c,Contact_Name__pc,Contact_Status__pc,ConvertedFromLeadTime__c,'
        			+'ConvertedFromLead__c,ConvertedFromLead__pc,ConvertFromLeadABN__c,Count_Account__c,Count_Alerts_Accounts_Contact__c,Count_Alerts_Accounts_Only__c,Count_Contact__pc,'
        			+'Count_Of_Contacts__c,Count_of_Emailable_Contacts__c,CreatedById,CreatedDate,Created_by_Cirrus_Insight__c,Created_by_Cirrus_Insight__pc,Created_via_Salesforce1__c,'
        			+'Created_via_Salesforce1__pc,Creative_Agency_AdPoint_Id__c,Creative_Agency_For_Digital_Customer__c,Credit_Status__c,csb2c__E_Commerce_Customer_Id__c,'
        			+'csb2c__Profile__c,CSCAP__Approval_PIN__pc,cscfga__Active__c,cscfga__SLAExpirationDate__c,cscfga__SLASerialNumber__c,cspmb__Discount_Level__c,Current_FY_Digital__c,'
        			+'Current_FY_Print__c,Current_FY_Xtend__c,Current_FY__c,CustomerDiscount__c,Customer_Books_Direct__c,Customer_Discount_Percent__c,Customer_Is__c,'
        			+'Customer_Lifecycle_Stage__pc,Customer_Segment__c,Data_Quality_Description__c,Data_Quality_Description__pc,Data_Quality_Score__c,Data_Quality_Score__pc,'
        			+'Days_Since_Activity__c,Delay_Digital_Creation__pc,Description,Digital_Customer_Tier__c,Digital_Last_Transaction_Date__c,Digital_Marketing_Monthly_Spend__c,'
        			+'Digital_Status__c,Digital_Status__pc,Division__c,DNC_A_Number_Is_Contactable__pc,DNC_Status_Audit__pc,Dormant_Account__c,DPID_Primary_Address__c,DPID_Primary_Address__pc,'
        			+'DPID_Secondary_Address__c,DPID_Secondary_Address__pc,Emailable__pc,Email_Invalid__pc,Email_Secondary__pc,Email_Status__c,Email_Status__pc,Empty_Core_Fields__c,'
        			+'Engagement_Preferences__c,Enquiry_Comments__pc,Enquiry_Type__pc,Expiry_Date__pc,External_ID__c,External_ID__pc,Fax,FirstName,First_Contact_in_Account__pc,'
        			+'FULL_FIELD__c,Gel_Id__c,GST_Exempt_Check__c,GST_Exempt__c,Has_Agreement__c,Has_Credit_Checked__c,Hierarchy_Level_Test__c,Home_Phone_DNC_Contactable__c,'
        			+'Home_Phone_DNC_Contactable__pc,Home_Phone_DNC_Status__pc,Home_Phone_DNC_Washed_Date__pc,Home_Phone_on_DNC__pc,Id,Inactive_Date__c,Inactive_Date__pc,'
        			+'Industry,IndustryWebform__pc,Industry_Code_1__c,Industry_Code_2__c,Industry_Code_3__c,Industry_Code_4__c,Industry_Code_Name_In_Text__c,Industry_Code__c,'
        			+'Integration_Error__c,Integration_Error__pc,IsCustomerPortal,IsDeleted,IsPartner,IsPersonAccount,Is_Agency__c,Is_Digital__c,Is_NewsXtend_Customer__c,'
        			+'Is_NX_ANZ_customer__c,Is_on_Black_List_Digital_Media__c,Is_Primary_Contact__pc,Jigsaw,JigsawCompanyId,KeyPlayers__c,Key_Contact__pc,Language_Preferences__c,'
        			+'LastActivityDate,LastModifiedById,LastModifiedDate,LastName,LastReferencedDate,LastViewedDate,Last_Booking_Classification__c,Last_Booking_Division__c,'
        			+'Last_Booking_Last_Expiry_Appearance__c,Last_Booking_Line_Item_Classifications__c,Last_Booking_Line_Item_Publication_Divs__c,Last_Booking_Modified_Date__c,'
        			+'Last_Booking_Number__c,Last_Booking_Run_Schedule__c,Last_Booking_Value__c,Last_Case_Modified_Date__c,Last_Client_Engagement__c,Last_Event_Modified_Date__c,'
        			+'Last_Modified_via_Salesforce1__c,Last_Opportunity_Modified_Date__c,Last_Task_Modified_Date__c,Lead_Source_Detail__pc,Lifecycle_Stage__c,'
        			+'Marketing_Channel_NX_ANZ__pc,Marketing_Preferences__pc,MasterRecordId,Master_Digital_Status__c,Media_Agency_AdPoint_Id__c,Media_Agency_For_Digital_Customer__c,'
        			+'Middle_Name__pc,Mobile_DNC_Contactable__c,Mobile_DNC_Contactable__pc,Mobile_DNC_Status__pc,Mobile_DNC_Washed_Date__pc,Mobile_on_DNC__pc,Monthly_Digital_Budget__c,'
     				+'Monthly_Digital_Budget__pc,MQL_First_Date__pc,MQL_Latest_Date__pc,Name,NewsAdds_Contact_ID__pc,NewsAdds_Draft_Account__c,NewsAdds_Draft_Contact__pc,'
        			+'NewsAdds_Registration_ID__pc,NewsXtend_Auto_Approval_Enabled__c,NewsXtend_My_Account_Access__pc,NewsXtend_Outstanding_Tasks__pc,News_Billing_Status__c,'
        			+'News_Corp_Target_Audience__c,NEWS_Segment__c,No_Email__pc,No_Parent_Account__c,NumberOfEmployees,NVMConnect__NextContactTime__pc,Old_Current_FY__c,Old_Previous_FY__c,'
        			+'Other_Phone_DNC_Contactable__c,Other_Phone_DNC_Contactable__pc,Other_Phone_DNC_Status__pc,Other_Phone_DNC_Washed_Date__pc,Other_Phone_on_DNC__pc,OwnerId,Ownership,ParentId,'
        			+'PersonAssistantName,PersonAssistantPhone,PersonBirthdate,PersonContactId,PersonDepartment,PersonDoNotCall,PersonEmail,PersonEmailBouncedDate,PersonEmailBouncedReason,'
        			+'PersonHasOptedOutOfEmail,PersonHasOptedOutOfFax,PersonHomePhone,PersonLastCURequestDate,PersonLastCUUpdateDate,PersonLeadSource,PersonMailingAddress,PersonMailingCity,'
        			+'PersonMailingCountry,PersonMailingGeocodeAccuracy,PersonMailingLatitude,PersonMailingLongitude,PersonMailingPostalCode,PersonMailingState,PersonMailingStreet,'
        			+'PersonMobilePhone,PersonOtherAddress,PersonOtherCity,PersonOtherCountry,PersonOtherGeocodeAccuracy,PersonOtherLatitude,PersonOtherLongitude,PersonOtherPhone,'
        			+'PersonOtherPostalCode,PersonOtherState,PersonOtherStreet,PersonTitle,Phone,Phones_Combined__c,Phones_Combined__pc,Phone_DNC_Contactable__c,Phone_DNC_Contactable__pc,'
        			+'Phone_DNC_Status__pc,Phone_DNC_Washed_Date__pc,Phone_on_DNC__pc,PhotoUrl,Portfolio__c,Previous_FY_Digital__c,Previous_FY_Print__c,Previous_FY_Xtend__c,Previous_FY__c,'
        			+'Pre_Discount_Price__c,Primary_Address__c,Primary_Contact__c,Print_Customer_Tier__c,Print_Last_Transaction_Date__c,Product_Opt_In_Community_Print__pc,'
        			+'Product_Opt_In_Digital_Offerings__pc,Product_Opt_In_Magazines__pc,Product_Opt_In_Metro_Print__pc,Product_Opt_In_Regional_Print__pc,Product_Opt_In_Seminars_Events__pc,'
        			+'Project_Sunday__c,Prospector_Link__c,Rating,RecentLeadSourceDetail__pc,Recent_Lead_Source_Date__pc,RecordTypeId,Referral_Source__c,Referral_Source__pc,Registered_Name__c,'
        			+'Revenue_Group__c,Revenue_Growth_Rate__c,rh2__Currency_Test__pc,rh2__Describe__pc,rh2__Formula_Test__pc,rh2__Integer_Test__pc,RingLead_DMS_Status__pc,'
        			+'Rolling_12_Months_Digital__c,Rolling_12_Months_Print__c,Salutation,SAL_First_Date__pc,SAL_Latest_Date__pc,Share_of_Wallet__c,ShippingAddress,ShippingCity,'
        			+'ShippingCountry,ShippingGeocodeAccuracy,ShippingLatitude,ShippingLongitude,ShippingPostalCode,ShippingState,ShippingStreet,Sic,SicDesc,Site,Status__c,SystemModstamp,'
        			+'TickerSymbol,Tier__c,TotalNewsCorpSpend__c,Total_Agency_Spend__c,Total_Customer_Spend__c,Total_Group_Spend__c,Total_NewsXtend_Spend__c,Type,Ultimate_Parent_Id__c,'
        			+'UniqueEntry__Account_Dupes_Ignored__c,UniqueEntry__Contact_Dupes_Ignored__pc,UniqueEntry__Lead_Dupes_Ignored__pc,UserisOwner__c,UTM_Source__c,UTM_Source__pc,Website,'
        			+'Xtend_Last_Transaction_Date__c FROM Account where Status__c =\'Active\' and Id in (Select AccountId FROM Opportunity WHERE StageName=\'Closed Won\' and (closeDate= last_N_YEARS:3 or closeDate = THIS_YEAR)) ';
	
	global AccountCloneUpdateBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
                System.debug('qurey'+query);

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Account> scope) {
	
    if (scope.size() > 0) {
        
            List<AccountReport__c> accrepList = new List<AccountReport__c>();
               for(Account  acc: scope) {
                AccountReport__c accrep = new AccountReport__c();
                accrep.Account_Id__c = acc.Id;
                accrep.ABN_Exempt__c = acc.ABN_Exempt__c;
                accrep.Name = acc.name;
                accrep.ABN_Exempt_Reason__c = acc.ABN_Exempt_Reason__c;
                accrep.ABN_Status__c = acc.ABN_Status__c;
                accrep.ABN_Validation__c = acc.ABN_Validation__c;
                accrep.Account_Dupes_Ignored__c = acc.UniqueEntry__Account_Dupes_Ignored__c;
                accrep.Account_Last_Modified__c = acc.Account_Last_Modified__c;
                accrep.AccountNumber__c = acc.AccountNumber;
                accrep.Account_Overview__c = acc.Account_Overview__c;
                accrep.cs_Profile__c= acc.csb2c__Profile__c;
                accrep.Site__c= acc.Site;
                accrep.AccountSource__c = acc.AccountSource;
                accrep.account_synopsis__c = acc.Account_Synopsis__c;
                accrep.Account_Type__c = acc.Account_Type__c;
                accrep.Accredited__c = acc.Accredited__c;
                accrep.AdPoint_Id__c = acc.AdPoint_Id__c;
                accrep.AdPoint_User_Id__c = acc.AdPoint_User_Id__c;
                accrep.ANZ_Package__c = acc.ANZ_Package__c;
                accrep.PersonAssistantName__c = acc.PersonAssistantName;
                accrep.PersonAssistantPhone__c = acc.PersonAssistantPhone;
                accrep.Billing_Status__c = acc.Billing_Status__c;
                accrep.PersonBirthdate__c = acc.PersonBirthdate;
                accrep.Blacklist_Reason_Digital__c = acc.Blacklist_Reason_Digital__c;
                accrep.Lifecycle_Stage__c = acc.Lifecycle_Stage__c;
                accrep.Business_Size__c = acc.Business_Size__c;
                accrep.Consortium_Current_FY__c = acc.Consortium_Current_FY__c;
                accrep.Consortium_Previous_FY__c = acc.Consortium_Previous_FY__c;
                accrep.Consortium_Total__c = acc.Consortium_Total__c;
                accrep.ConvertedFromLead__c = acc.ConvertedFromLead__c;
                accrep.ConvertedFromLeadTime__c = acc.ConvertedFromLeadTime__c;
                accrep.Has_Credit_Checked__c = acc.Has_Credit_Checked__c;
                accrep.Credit_Status__c = acc.Credit_Status__c;   
                accrep.Current_FY_Digital__c = acc.Current_FY_Digital__c;
                accrep.Current_FY_Print__c = acc.Current_FY_Print__c;
                accrep.Current_FY_Xtend__c = acc.Current_FY_Xtend__c;
                accrep.Customer_Books_Direct__c = acc.Customer_Books_Direct__c;
                accrep.CustomerDiscount__c  = acc.CustomerDiscount__c;
                accrep.IsCustomerPortal__c = acc.IsCustomerPortal;
                accrep.Customer_Segment__c  = acc.Customer_Segment__c;
                accrep.Jigsaw__c = acc.Jigsaw;
                accrep.PersonDepartment__c= acc.PersonDepartment;
                accrep.Description__c = acc.Description;
                accrep.Digital_Customer_Tier__c = acc.Digital_Customer_Tier__c;
                accrep.Digital_Marketing_Monthly_Spend__c = acc.Digital_Marketing_Monthly_Spend__c;
                accrep.PersonDoNotCall__c = acc.PersonDoNotCall;
                accrep.DPID_Primary_Address__c = acc.DPID_Primary_Address__c;   
                accrep.cs_Commerce_Customer_Id__c = acc.csb2c__E_Commerce_Customer_Id__c;   
                accrep.PersonEmail__c = acc.PersonEmail;
                accrep.Email_Invalid_pc__c= acc.Email_Invalid__pc;
                accrep.PersonHasOptedOutOfEmail__c = acc.PersonHasOptedOutOfEmail;   
                accrep.NumberOfEmployees__c = acc.NumberOfEmployees;
                accrep.Engagement_Preferences__c = acc.Engagement_Preferences__c;  
                accrep.External_ID__c = acc.External_ID__c;
                accrep.Fax__c = acc.Fax;
                accrep.PersonHasOptedOutOfFax__c = acc.PersonHasOptedOutOfFax;
                accrep.First_Name__c = acc.FirstName;   
                accrep.Gel_Id__c = acc.Gel_Id__c; 
                accrep.GST_Exempt__c = acc.GST_Exempt__c;    
                accrep.PersonHomePhone__c = acc.PersonHomePhone;
                accrep.Inactive_Date__c = acc.Inactive_Date__c;
                accrep.Industry__c = acc.Industry;
                accrep.Integration_Error__c = acc.Integration_Error__c;   
                accrep.Is_NX_ANZ_customer__c   = acc.Is_NX_ANZ_customer__c;
               accrep.Is_on_Black_List_Digital_Media__c = acc.Is_on_Black_List_Digital_Media__c;
                    accrep.IsPartner__c = acc.IsPartner;
                    accrep.KeyPlayers__c = acc.KeyPlayers__c;
                    accrep.Language_Preferences__c = acc.Language_Preferences__c;
                    accrep.Last_Booking_Classification__c = acc.Last_Booking_Classification__c;
                    accrep.Last_Booking_Division__c= acc.Last_Booking_Division__c;
                    accrep.Last_Booking_Last_Expiry_Appearance__c =acc.Last_Booking_Last_Expiry_Appearance__c;
                    accrep.Last_Booking_Line_Item_Classifications__c = acc.Last_Booking_Line_Item_Classifications__c;
                    accrep.Last_Booking_Line_Item_Publication_Divs__c = acc.Last_Booking_Line_Item_Publication_Divs__c;
                   accrep.Last_Booking_Modified_Date__c = acc.Last_Booking_Modified_Date__c;
                   accrep.Last_Booking_Number__c   = acc.Last_Booking_Number__c ;
                   accrep.Last_Case_Modified_Date__c = acc.Last_Case_Modified_Date__c;
                   accrep.Last_Client_Engagement__c = acc.Last_Client_Engagement__c;
                   accrep.Last_Event_Modified_Date__c = acc.Last_Event_Modified_Date__c;
                   accrep.Last_Modified_via_Salesforce1__c = acc.Last_Modified_via_Salesforce1__c;
                   accrep.Last_Name__c = acc.lastname;
                   accrep.Last_Opportunity_Modified_Date__c= acc.Last_Opportunity_Modified_Date__c;
                   accrep.Last_Task_Modified_Date__c = acc.Last_Task_Modified_Date__c;
                    accrep.PersonLastCURequestDate__c = acc.PersonLastCURequestDate;
                    accrep.PersonLastCUUpdateDate__c   = acc.PersonLastCUUpdateDate; 
                   //accrep.PersonMailingAddress__c = acc.PersonMailingAddress;
                   //accrep.Master_Digital_Status__c =acc.Master_Digital_Status__c;
                   //accrep.Monthly_Digital_Budget__c=acc.Monthly_Digital_Budget__c;
                   accrep.PersonMobilePhone__c = acc.PersonMobilePhone;
                   accrep.NewsAdds_Draft_Account__c = acc.NewsAdds_Draft_Account__c;
                   accrep.News_Corp_Target_Audience__c = acc.News_Corp_Target_Audience__c;
                   //accrep.News_Billing_Status__c = acc.News_Billing_Status__c;
                   accrep.NEWS_Segment__c = acc.NEWS_Segment__c;
                   accrep.NewsXtend_Auto_Approval_Enabled__c= acc.NewsXtend_Auto_Approval_Enabled__c;
                   accrep.No_Parent_Account__c= acc.No_Parent_Account__c;
                   accrep.Old_Previous_FY__c=acc.Old_Previous_FY__c;
                   accrep.Old_Current_FY__c =acc.Old_Current_FY__c;   
                   //accrep.PersonOtherAddress__c=acc.PersonOtherAddress;
                   accrep.PersonOtherPhone__c=acc.PersonOtherPhone;
                    accrep.Ownership__c=acc.Ownership;
                    accrep.Phone__c=acc.Phone;
                    accrep.Pre_Discount_Price__c=acc.Pre_Discount_Price__c;
                    accrep.Previous_FY_Digital__c=acc.Previous_FY_Digital__c;
                    accrep.Previous_FY_Print__c=acc.Previous_FY_Print__c;
                    accrep.Previous_FY_Xtend__c=acc.Previous_FY_Xtend__c;
                       accrep.Print_Last_Transaction_Date__c=acc.Print_Last_Transaction_Date__c;
                       accrep.Print_Customer_Tier__c=acc.Print_Customer_Tier__c;
                        accrep.Project_Sunday__c=acc.Project_Sunday__c;
                        accrep.Rating__c=acc.Rating;
                        accrep.Referral_Source__c=acc.Referral_Source__c;
                        accrep.Registered_Name__c=acc.Registered_Name__c;
                        accrep.Revenue_Group__c=acc.Revenue_Group__c;
                        accrep.Revenue_Growth_Rate__c=acc.Revenue_Growth_Rate__c;
                        accrep.Rolling_12_Months_Digital__c=acc.Rolling_12_Months_Digital__c;
                        accrep.Rolling_12_Months_Print__c=acc.Rolling_12_Months_Print__c;
                   accrep.Salutation__c=acc.Salutation;
                    accrep.Share_of_Wallet__c=acc.Share_of_Wallet__c;
                     //accrep.ShippingAddress__c=acc.ShippingAddress;
                      accrep.Sic__c=acc.Sic;
                      accrep.SicDesc__c=acc.SicDesc;
                      accrep.cs_SLA_Expiration_Date__c=acc.cscfga__SLAExpirationDate__c;
                      accrep.cs_SLA_Serial_Number__c=acc.cscfga__SLASerialNumber__c;
                      accrep.Status__c=acc.Status__c;
                       accrep.Digital_Status__c=acc.Digital_Status__c;
                   accrep.PersonTitle__c=acc.PersonTitle;
                       accrep.Total_Agency_Spend__c=acc.Total_Agency_Spend__c;
                       accrep.Total_Customer_Spend__c=acc.Total_Customer_Spend__c;
                       accrep.Total_Group_Spend__c=acc.Total_Group_Spend__c;
                       accrep.TotalNewsCorpSpend__c=acc.Total_NewsXtend_Spend__c;
                      accrep.Type__c=acc.Type;
                      accrep.Ultimate_Parent_Id__c=acc.Ultimate_Parent_Id__c;
                      accrep.UserisOwner__c=acc.UserisOwner__c;
                      accrep.UTM_Source__c=acc.UTM_Source__c;
                      accrep.Website__c=acc.Website;
                      accrep.Xtend_Last_Transaction_Date__c=acc.Xtend_Last_Transaction_Date__c;
                      accrep.Tier__c=acc.Tier__c;
                    accrepList.add(accrep);
                    //recordsProcessed = recordsProcessed + 1;
                                  
                 }
             
              //insert accrepList;
              Database.upsertResult[] saveResultList = Database.upsert(accrepList, false);



               for (Database.upsertResult sr : saveResultList) {
                if (sr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated Opportunity.' + sr.getId());
             }
             else {
        // Operation failed, so get all errors                
            for(Database.Error err : sr.getErrors()) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Account fields that affected this error: ' + err.getFields());
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
            mail.setSubject('Account Clone object Batch ' + a.Status);
            mail.setPlainTextBody('Account Clone Update object Batch to object AccountReport,number of records processed ' + a.TotalJobItems +
           'with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

         
         AccountCloneDeleteBatch batchJob = new AccountCloneDeleteBatch();
        Id batchInstanceId = Database.executeBatch(batchJob, 200);
        
    }
		
	
	
}