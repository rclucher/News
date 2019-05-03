/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * State Manager for the Sales Order UI
 ---------------------------------------------------------*/

global with sharing class NewsXtendSalesOrderStateManager implements csmso.SalesOrderAPI.SalesOrderStateManager {

    // Define transition status of Sales Order
    static final Map<String, Set<String>> stateTransitions = new Map<String, Set<String>>{
            'Draft' => new Set<String>{'Sent For Internal Approval','Sent For External Approval', 'Manually Approved', 'Killed', 'Completed'},
            'Retracted' => new Set<String>{'Sent For Internal Approval','Sent For External Approval', 'Manually Approved', 'Killed', 'Completed'},

            'Sent For Internal Approval' => new Set<String>{'Internally Approved','Internally Rejected'},
            'Sent For External Approval' => new Set<String>{'Externally Approved','Externally Rejected','Internally Approved'}, // CSP 2016-06-15

            'Internally Approved' => new Set<String>{'Sent For External Approval'},
            'Externally Approved' => new Set<String>{'Completed'},

            'Internally Rejected' => new Set<String>{'Killed','Draft','Retracted'},
            'Externally Rejected' => new Set<String>{'Killed','Draft','Retracted'}

    };

    // Define fields or buttons as mandatory, enabled or disabled (ex. set the Finish_Sales_Order button to disabled:'Finish_Sales_Order' => 'D')
    // Define field attributes as mandatory or disabled, buttons as hidden
    // When in certain states - "M" = mandatory, "D" = disabled, “E” = enabled, "H" = hidden
    // Method updated as part of NR-45 and NR-73. 17/07/2018
    // All the buttons are hidden and selectively activated based on condition suggested by Business as part of the two JIRAs.
    static final Map<String, Map<String, String>> fieldAttributes = new Map<String, Map<String, String>> {
            'Draft' => new Map<String, String> {
                    'Advertiser__c' => 'E',
                    'Opportunity__c' => 'E',
                    'Booking_Contact__c' => 'M',
                    'Campaign_Start_Date__c' => 'M',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Margin__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    'Booking_Contact_For_Digital__c' => 'E',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'E',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'Payment_Method__c' => 'E',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'M',
                    'Digital_Material_Contact__c' => 'M',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Sync_SO' => 'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H'    // kw: order amendment
            }, //When status is set to draft field Advertiser is set as mandatory, button Finish Sales Orderis disabled, Sales Order Status as disabled

            'Sent For Internal Approval' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',                       
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'M',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },

            'Sent For External Approval' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',                                           
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    // T-26257 - Override a Status of "Sent for External Approval' with "Manually Approved" - Edo Safranko 14/06/2016
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                     'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Retract_SO'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
        },

            'Internally Approved' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',                     
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'M',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
          },

            'Internally Rejected' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',                                               
                    'Booking_Contact__c' => 'M',
                    'Campaign_Start_Date__c' => 'M',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'E',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'E',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'M',
                    'Digital_Material_Contact__c' => 'M',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },

            'Externally Approved' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Booking_Contact__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'E',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
        },

            'Externally Rejected' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'M',
                    'Campaign_Start_Date__c' => 'M',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },

            'Manually Approved' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'E',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },

            'Completed' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },

            'Killed' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'H',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },
            //introducing Retraction now:
            'Retracted' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'M',
                    'Campaign_Start_Date__c' => 'E',
                    'Campaign_Start_Date_Formatted__c' => 'E',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'M',
                    'Digital_Material_Contact__c' => 'M',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons
                    'Undo' => 'H',
                    'KillSalesOrderAction' => 'H',
                    'multiEdit' => 'H',
                    'Request_Approval' => 'H',
                    'Approve_SO' => 'H',
                    'Reject_SO' => 'H',
                    'Manual_Approval' => 'E',
                    'Get_PDF' => 'H',
                    'CloneSalesOrderAction'=> 'H',
                    'Save_Exit'=>'H',
                    'Recall_SO'=>'H',
                    'Generate_IO'=>'H',
                    'Retract_SO'=>'H',  // kw: order amendment
                    'Audit_History'=>'H',   // kw: order amendment
                    'Sync_SO' => 'H'
            },
            //introducing Retraction Blocked now,all disabled
            'Retraction Blocked' => new Map<String, String> {
                    'Advertiser__c' => 'D',
                    'Opportunity__c' => 'D',
                    'Booking_Contact__c' => 'D',
                    'Campaign_Start_Date__c' => 'D',
                    'Campaign_Start_Date_Formatted__c' => 'D',
                    'Campaign_End_Date_Formatted__c' => 'D',
                    'Attach_IO' => 'D',
                    'Status__c' => 'D',
                    'Booking_Contact_For_Digital__c' => 'D',
                    'Total_Digital_Price__c' => 'D',
                    'Total_Digital_Price_GST_Inclusive__c' => 'D',
                    'Booking_Contact_For_Print__c' => 'D',
                    'Target_Print_Price__c' => 'D',
                    'Total_Xtend_Price__c' => 'D',
                    'Total_Xtend_GST__c' => 'D',
                    'Payment_Method__c' => 'D',
                    'Bundle_Name__c'=> 'D',
                    //below fields added as part of NR-788
                    'Customer_Segment__c' => 'D',
                    'Client_Value_Score__c' =>'D',
                    'Print_Status__c' =>'D',
                    'Target_Discount__c' => 'D',
                    'Client_Current_Discount_FY__c' => 'D',
                    'Print_Customer_Tier__c' => 'D',
                    'Total_Print_Duration_Price__c' => 'D',
                    'Proposed_Print_Discount__c' => 'D',
                    'Proposed_Print_Price__c' => 'D',
                    'Max_Discount_Threshold__c'=>'D',
                    //below fields added as part of NR-138
                    'Total_Duration_GST__c'=>'D',
                    'Total_Print_GST__c' => 'D',
                    'Print_Impressions_Count__c' => 'D',
                    'Campaign_Length_Weeks__c' => 'D',
                    'Total_Duration_Price__c' => 'D',
                    'Print_Material_Contact__c' => 'D',
                    'Digital_Material_Contact__c' => 'D',
                    'Total_Insertions__c' => 'D',
                    'Total_Digital_Impressions__c' => 'D',
                    //Buttons need to be enforced in getAttributesFiedl... as Xtend wants to see all the buttons

                    //Xtend fields to disable
                    'Margin__c' => 'D',
                    'Margin_Flag__c' => 'D',
                    'Total_Impressions__c' => 'D',
                    'Notes__c' => 'D',
                    'Social_URL__c' => 'D',
                    'Dashboard__c' => 'D',
                    'Creative_Services__c' => 'D',
                    'Package_Name__c' => 'D',
                    'Campaign_Name__c' => 'D',
                    'Total_Xtend_Price_GST_Inclusive__c' => 'D',
                    'One_Off_Price__c' => 'D',
                    'Recurring_Price__c' => 'D',
                    'Campaign_Length__c' => 'D',
                    'Campaign_End_Date2__c' => 'D',
                    'Conversion_Tracking__c' => 'D',
                    'Call_Tracking__c' => 'D',
                    'Retracted_Date__c' => 'D',
                    'Previous_Campaign_Start_Date__c' => 'D',
                    'Previous_Campaign_End_Date__c' => 'D',
                    // remaining main section fields
                    'Payer_Account__c' => 'D',
                    'Planner_Account__c' => 'D',
                    'Total_Monthly_Price__c' => 'D',
                    'Total_Duration_Price_Display__c' => 'D',
                    'Billing_Contact__c' => 'D',
                    'Creative_Contact__c' => 'D',
                    'Additional_Notes__c' => 'D'
            }

    };

    public void validateChange(csmso__Sales_Order__c so) { //public method validateChange must be defined
        csmso__Sales_Order__c previousSo = [SELECT csmso__Status__c,Previous_Campaign_End_Date__c,Proposed_Print_Discount__c FROM csmso__Sales_Order__c WHERE Id = :so.Id];

        // kw: xtend order amendment
        // Stopping user from changing an evergreen so to a seasonal one
        if(so.csmso__Status__c == 'Retracted' 
                && previousSo.Previous_Campaign_End_Date__c == null 
                && so.Campaign_Length__c != null){
            throw new StateException('You can\'t change an evergreen Sales Order to a seasonal Sales Order after retraction.');
        }

        // kw: xtend order amendment
        // if new end date is closer than the old end date, stop the modification
       if(so.csmso__Status__c == 'Retracted' 
                && so.Campaign_Start_Date__c != null 
                && so.Campaign_Length__c != null
                && previousSo.Previous_Campaign_End_Date__c != null){
               Date newEndDate = so.Campaign_Start_Date__c.addMonths(Integer.valueOf(so.Campaign_Length__c));
               if(newEndDate<previousSo.Previous_Campaign_End_Date__c){
                    throw new StateException('You cannot reduce campaign duration via Retraction. Please initiate Cancellation as necessary.');
               }
            
        }

        System.debug('validateChange ' + previousSo + ' and ' + so.csmso__Status__c);

        if (so.Proposed_Print_Discount__c < 0 || so.Proposed_Print_Discount__c > 100) {
            //to prevent dirty write we need to create new SO instance for insert!
            csmso__Sales_Order__c soForUpdate = new csmso__Sales_Order__c(
                Id = so.Id,
                csmso__Process_Message__c = 'Proposed Discount (%) needs to be in range of 0-100',
                csmso__Process_Message_Type__c = 'error',
                Proposed_Print_Discount__c = previousSo.Proposed_Print_Discount__c);
            update soForUpdate;
        }

        if (previousSo.csmso__Status__c == so.csmso__Status__c) {
            System.debug('No state change');
            return;
        }

        Set<String> legalStates = stateTransitions.get(previousSo.csmso__Status__c);

        if (legalStates != null && !legalStates.contains(so.csmso__Status__c)) {
            throw new StateException('You cannot change the sales order status from ' + previousSo.csmso__Status__c + ' to ' + so.csmso__Status__c);
        }

        /*
        System.debug('IGOR DEBUG 1 ----------------------------');
        // T_0149 - User should not be able to complete Manual or External Approval while PC in status "BI Not Complete"
        // commented due to bug: validateChange not working as per T-34951
        if (so.csmso__Status__c == 'Manually Approved' || so.csmso__Status__c == 'Externally Approved') {
            List<cscfga__Product_Configuration__c> PCs = [SELECT Id
                                                            FROM cscfga__Product_Configuration__c
                                                            WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :so.Id AND
                                                                  Booking_Instructions__c = 'Not Completed'];
            System.debug('IGOR DEBUG 2 ----------------------------');
            if (PCs.size() > 0) {

                System.debug('IGOR DEBUG 3 ----------------------------');
                throw new StateException('You cannot change the sales order status from ' +
                                            previousSo.csmso__Status__c + ' to ' +
                                            so.csmso__Status__c + '. Booking Instructions are not complete.');
            }

            return;
        }
        */
    }

    public Map<String, String> getFieldAttributesForSalesOrder(csmso__Sales_Order__c so) { //public method getFieldAttributesForSalesOrder must be defined

        system.debug('getFieldAttributesForSalesOrder ' + so.csmso__Status__c);
        Boolean userHasAccess = false;

        Map<String, String> attribs = fieldAttributes.get(so.csmso__Status__c);
        
        //05/10 IG: Advertised has to be populated when creating SO thus commenting the below:
        
        /*if (so.csmso__Advertiser__c == null) {
            attribs.put('AddLineItemButton', 'D');
        }*/

        //section to disable buttons for product modification
        //if ((so.csmso__Status__c != 'Draft') && (so.csmso__Status__c != 'Externally Rejected') && (so.csmso__Status__c != 'Internally Rejected'))
        //if (so.FLAG_Lock_Product_Configuration__c=='Locked') - SFE-860 - this is how it should be based on 'FLAG_Lock_Product_Configuration__c' formula field

        if ((so.csmso__Status__c=='Killed') || (so.csmso__Status__c=='Pending Approval') || (so.csmso__Status__c=='Manually Approved')
            || (so.csmso__Status__c=='Sent For Internal Approval') || (so.csmso__Status__c=='Sent For External Approval') 
            || (so.csmso__Status__c=='Externally Approved'))
        //modified by Davor Dubokovic as a part of SFE-860 - added condition based on value of the Status field
        {
            system.debug('Status means disable buttons that can change Sales Order');

            attribs.put('AddProductButton', 'D');
            attribs.put('AddPackageButton', 'D');
            attribs.put('AddLineItemButton', 'D');
            attribs.put('Undo', 'H');
            attribs.put('LineItem:CloneButton', 'D');
            attribs.put('LineItem:DeleteButton', 'D');
            attribs.put('Package:DeleteButton', 'D');
        }

        // kw: order amendment
        // show the 'Reinstate SO' button only when the so has been retracted
        // hide the fields if it is not a retraction scenario
        attribs.put('Retracted_Date__c', 'D');
        attribs.put('Previous_Campaign_Start_Date__c', 'D');
        attribs.put('Previous_Campaign_End_Date__c', 'D');
        if(so.Retracted_Date__c == null ){
            attribs.put('Reinstate_SO', 'H');
        }
        if(so.Origin__c == 'Campaign Track' ){    
          attribs.put('Retract_SO', 'H');
        }
        /*
        //TODO:Remove as part of NX-1505
         if(so.Audit_History_Available__c){
          attribs.put('Audit_History', 'E');
        }*/

        if (so.Campaign_Products_Type__c == 'Seasonal - Print Led' || (so.Basket_Products__c != null && so.Basket_Products__c.contains('Xtend Led'))) //12/06/2018 IG updated so Campaign_Length__c is disabled for Bundle Xtend Led
        {
            attribs.put('Campaign_Start_Date__c', 'D');
            attribs.put('Campaign_Length__c', 'D');
        }
        //enable fields only if bundle NR-138
        if (so.Basket_Products__c != null && so.Basket_Products__c.contains('Led')) {
            if (so.Basket_Products__c.contains('Bundle Print')) {
                attribs.put('Print_Material_Contact__c', 'M');
            }
            if (so.Basket_Products__c.contains('Bundle Digital')) {
                attribs.put('Digital_Material_Contact__c', 'M');
            }
        }

        // Always 'D' = disable these items (make them Read only) on the Sales Order screen
        attribs.put('Campaign_End_Date__c', 'D');
        attribs.put('Status__c', 'D');
        attribs.put('Package_Name__c', 'D');
        attribs.put('Margin__c', 'D');
        attribs.put('Margin_Flag__c', 'D');
        attribs.put('Total_Impressions__c', 'D');
        // attribs.put('csmso__Total_Price__c', 'D');
        attribs.put('Total_Monthly_Price__c', 'D');
        attribs.put('GST__c', 'D');
        attribs.put('Total_GST_inclusive__c', 'D');
        attribs.put('Recurring_Price__c', 'D');
        attribs.put('Campaign_Duration__c', 'D');
        attribs.put('Campaign_End_Date2__c', 'D');

        attribs.put('Total_Duration_Price_Display__c', 'D');
        attribs.put('Total_Duration_GST_Display__c', 'D');
        attribs.put('Total_Duration_Price_GST_Inc_Display__c', 'D');

        //disable print discount related stuff
        attribs.put('Print_Customer_Tier__c', 'D');
        attribs.put('Client_Current_Discount_FY__c', 'D');
        attribs.put('Target_Discount__c', 'D');
        attribs.put('Proposed_Print_Discount__c', 'D');
        attribs.put('Print_Status__c', 'D');
        attribs.put('Total_Print_Price__c', 'D');
        attribs.put('Proposed_Print_Price__c', 'D');
        attribs.put('Target_Print_Price__c', 'D');
        //below fields added for NR-788
        attribs.put('Customer_Segment__c', 'D');
        attribs.put('Client_Value_Score__c','D');
        attribs.put('Total_Print_Duration_Price__c', 'D');
        attribs.put('Created_By_Name__c','D');
        attribs.put('Last_Modified_Name__c','D');

        /*if(so.csmso__Status__c == 'Draft')
        {
            //attribs.put('Proposed_Print_Price__c', 'E');
            //attribs.put('Target_Print_Price__c', 'E');
            
            // if the logged in user is a Sales User whose profile ends with "Sales", "Digital Sales", "Sales Support" then CD, Client Print Tier, MDT, and CVS should not be displayed)
            List<Profile> profileNameList = [Select Name from Profile where Id = :UserInfo.getProfileId()];
            String profileName = profileNameList[0].name;
            if(profileName.contains('Sales') || profileName.contains('Direct Sales') || profileName.contains('Sales Support')){
                attribs.put('Client_Current_Discount_FY__c', 'D');
                attribs.put('Print_Customer_Tier__c', 'D');
                attribs.put('Client_Value_Score__c','D');
                attribs.put('Max_Discount_Threshold__c','D');
            }
            
        }*/
        /*if (so.csmso__Status__c == 'Draft' && !String.isEmpty(so.Platform_Set__c) && so.Platform_Set__c.contains('Print')) {
        }*/

        // section to enable / disable buttons
        userHasAccess = confirmUserAccessToSO(so,UserInfo.getUserId()); 
        
        if(String.isNotEmpty(so.Basket_Products__c)){
            if(!(so.Basket_Products__c.contains('Xtend'))){
        //if(so.OwnerId == UserInfo.getUserId()){
        if(userHasAccess){
            switch on so.csmso__Status__c{
                when 'Draft'{
                    attribs.put('KillSalesOrderAction','E');
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                    attribs.put('Request_Approval','E');
                    attribs.put('Generate_IO','E');
                    attribs.put('Sync_SO','E');
                    attribs.put('Audit_History', 'E'); // force enable due to NX-1505
                    //removing this since Button Calculator is out of picture. - Change by PD : 18/07/2018

                    /*if (!String.isEmpty(so.Platform_Set__c) && so.Basket_Products__c.contains('[Print Display]')) {
                        attribs.put('ButtonSOCalculator', 'E');
                    }*/
                    //NR-73 : Approval button to not be displayed when the Margin is good and the SO does not need any internal approval.
                    if(//so.Basket_Products__c.equals('[Print Display]')
                        //&&
                        (String.isNotEmpty(so.csmso__Process_Message__c) && so.csmso__Process_Message__c == Label.SO_does_not_require_approval) ){
                            System.debug('Margin OK. No additional approvals required! Approval Button will be deactivated');
                            attribs.put('Request_Approval','D');
                            attribs.put('Manual_Approval','E');
                    }

                    if (so.Invalid_Config_Count__c>0) {
                        attribs.put('Request_Approval','H');
                    }

                }
                when 'Retracted'{
                    attribs.put('Save_Exit','E');
                    attribs.put('Request_Approval','E');
                }
                when 'Sent For Internal Approval','Pending Approval'{
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                    attribs.put('Recall_SO','E'); // PetarM OA: requested for Recall to be available for Xtend too
                    attribs.put('Generate_IO','D');
                    attribs.put('Sync_SO','E');
                }
                when 'Sent For External Approval'{ //added as part of NR-964
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                    attribs.put('Manual_Approval','E');
                    attribs.put('Generate_IO','H');
                    attribs.put('Sync_SO','E');
                }
                when 'Internally Rejected','Rejected','Killed','Externally Rejected'{//externally rejected added as part of NR-964
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                }
                when 'Manually Approved','Externally Approved'{ //externally approved added as part of NR-964
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                    //attribs.put('Generate_IO','E'); // Hide the button if the SO is Customer approved. 
                    //attribs.put('Retract_SO','E'); // feature will be provided later
                    if(so.Basket_Products__c.contains('News Xtend') || so.Basket_Products__c.contains('Xtend Led')){
                        attribs.put('Get_PDF','E');
                    }
                }
                when 'Internally Approved'{
                    attribs.put('CloneSalesOrderAction','E');
                    attribs.put('Save_Exit','E');
                    attribs.put('Manual_Approval','E');
                    attribs.put('Generate_IO','E');
                    if(so.Basket_Products__c.contains('News Xtend') || so.Basket_Products__c.contains('Xtend Led')){
                        attribs.put('Get_PDF','E');
                    }
                }
                when else {
                    attribs.put('Save_Exit','E');
                }
            }
                }
            }else{
                attribs.put('KillSalesOrderAction','E');
                attribs.put('CloneSalesOrderAction','E');
                attribs.put('Save_Exit','E');
                attribs.put('Request_Approval','E');
                attribs.put('Manual_Approval','D');
                attribs.put('Sync_SO','E');
                attribs.put('Generate_IO','E');
                attribs.put('Get_PDF','E');
                if((String.isNotEmpty(so.csmso__Process_Message__c) && so.csmso__Process_Message__c == Label.SO_does_not_require_approval)){
                   System.debug('Margin OK. No additional approvals required! Approval Button will be deactivated');
                   attribs.put('Request_Approval','D');
                   attribs.put('Manual_Approval','E');
                }
                if(so.csmso__Status__c.equals('Sent For Internal Approval')|| so.csmso__Status__c.equals('Pending Approval') 
                    ||so.csmso__Status__c.equals('Externally Approved') ||so.csmso__Status__c.equals('Manually Approved')){ 
                    attribs.put('Request_Approval','D');
                }
                if(so.csmso__Status__c.equals('Internally Approved')|| so.csmso__Status__c.equals('Sent For External Approval')){
                   attribs.put('Request_Approval','D');
                   attribs.put('Manual_Approval','E');
                }
                if(so.csmso__Status__c.equals('Killed')){
                    attribs.put('Request_Approval','D');
                    attribs.put('Manual_Approval','D');
                    attribs.put('Sync_SO','D');
                    attribs.put('Generate_IO','D');
                    attribs.put('Get_PDF','D');
                }
                if(so.csmso__Status__c.equals('Externally Approved')){
                    attribs.put('Request_Approval','D');
                    attribs.put('Manual_Approval','D');
                }
                
        }
        //approval and reject button logic should depend only on status so no longer else part of the previous if(userHasAccess) statement NR-1771
        switch on so.csmso__Status__c{
            when 'Sent For Internal Approval'{
                //for Xtend check for User id Stored in a Group. The name of the group is 'News NextGen Approvers'
                List<GroupMember> XtendGroupMembers = [SELECT UserOrGroupId
                                                    FROM GroupMember
                                                    WHERE GroupId in (SELECT Id
                                                    FROM Group
                                                    WHERE NAME =: 'News Xtend Approvers')
                                                    AND UserOrGroupId =: UserInfo.getUserId()];

                if (AT_SalesOrderApprovals.isApprover(so.Id) || XtendGroupMembers.size() != 0 ) {
                    System.debug('One of the Next Gen/Xtend approvers is on the record');
                    attribs.put('Approve_SO','E');
                    attribs.put('Reject_SO','E');
                    attribs.put('Save_Exit','E');
                }
            }
            when else {
                attribs.put('Save_Exit','E');
            }
        }
    }

            if (so.csmso__Status__c=='Retraction Blocked') {
                    attribs.put('Undo','H');
                    attribs.put('KillSalesOrderAction','H');
                    attribs.put('multiEdit','H');
                    attribs.put('Request_Approval','H');
                    attribs.put('Approve_SO','H');
                    attribs.put('Reject_SO','H');
                    attribs.put('Manual_Approval','H');
                    attribs.put('Get_PDF','H');
                    attribs.put('CloneSalesOrderAction','H');
                    attribs.put('Save_Exit','H');
                    attribs.put('Recall_SO','H');
                    attribs.put('Generate_IO','H');
                    attribs.put('Retract_SO','H');  // kw: order amendment
                    attribs.put('Audit_History','H');   // kw: order amendment
                    attribs.put('Sync_SO','H');
                    attribs.put('Save_Exit','E');

                    attribs.put('AddLineItemButton','D');
                    attribs.put('AddPackageButton','D');
                    attribs.put('Package:Edit','D');
                    attribs.put('Package:DeleteButton','E');
                    attribs.put('LineItem:FlightButton','D');
                    attribs.put('LineItem:CloneButton','D');
                    attribs.put('LineItem:DeleteButton','E');
                    attribs.put('LineItem:Edit','D');
                    attribs.put('AttachmentsButton','D');
            }
        attribs.put('Save_Exit','E'); // button should always be enabled to navigate out of the Sales Order. 
        attribs.put('createInsertionOrder','D'); // hiding the CreatePDF button from the UI all together.
        system.debug('getFieldAttributesForSalesOrder ' + so.csmso__Status__c + ' complete');

        return attribs;


        // Define different access to Sales Order fields for different profiles
        /*
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProfileName = PROFILE[0].Name;
        if (MyProfileName == 'System Administrator' ){
            attribs.put('Status__c', 'E');
        }*/
    }
    
    //check if the person on the Sales Order is allowed to work on the buttons
    //the person on the SO should either be the owner or a member of OpportunityTeam or AccountTeam. 
    private Boolean confirmUserAccessToSO(csmso__Sales_Order__c salesOrder, Id currentUserId){
        system.debug('Entered confirmUserAccessToSO:');
        
        Boolean foundOnOpportunityTeam = false;
        Boolean foundOnAccountTeam = false;
        
        if(salesOrder.OwnerId == currentUserId){
            system.debug('Current User is Sales Order owner.');
            return true;
        }else{
            // check if current user is either on OpportunityTeam or AccountTeam
            try{
                Integer recordCount = [Select count() from OpportunityTeamMember
                                        where 
                                            OpportunityId =: salesOrder.csmso__Opportunity__c
                                        AND
                                            UserId =: currentUserId ];
                if(recordCount > 0){
                    foundOnOpportunityTeam = true;
                    return foundOnOpportunityTeam;
                }
                    
            }catch(DMLException ex){
                system.debug('Exception caught in OpportunityTeamMember Query:' +ex);
            }
            
            if(!foundOnOpportunityTeam){
                try{
                    Integer recordCount = [Select count() from AccountTeamMember
                                        where 
                                            AccountId =: salesOrder.csmso__Advertiser__c
                                        AND
                                            UserId =: currentUserId ];
                    if(recordCount > 0){
                        foundOnAccountTeam = true;
                        return foundOnAccountTeam;
                    }
                }catch(DMLException ex){
                    system.debug('Exception caught in AccountTeamMember Query:' +ex);
                }
            }
        }
        
        return false;
    }

    public class StateException extends Exception { }
}