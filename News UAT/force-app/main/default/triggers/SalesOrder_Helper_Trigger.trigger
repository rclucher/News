/**
 * SalesOrder_Helper_Trigger
 *
 * Trigger for the csmso__Sales_Order__c custom object
 *
 * PLEASE PLACE ALL LOGIC IN HANDLER CLASS: SalesOrder_Helper
 *
 * Change history:
 *
 * #16/09/2016
 * @author     Peter Charalambous <peter.charalambous@bluewolf.com>
 * @author     David Dawson <david.dawson@bluewolf.com>
 *             - Created initial version of trigger and handler class
 *             - SalesOrder_Helper functionality added
 * #29/09/2016
 * @author     Calvin Noronha <calvin.noronha@bluewolf.com>
 *             - Bulkified trigger and implemented best coding practises
 * #21/10/2016
 * @author     Kristijan Kosutic <kristijan.kosutic@cloudsense.com>
 *             - Added functionality to mark opportunity as Has Approved SO
 * #27/10/2016
 * @author     David Dawson <david.dawson@bluewolf.com>
 *             - Moved functionality into trigger handler to ensure no logic is in trigger
 * @author     Peter Charalambous <peter.charalambous@bluewolf.com>
 *             - Added archive functionallity
 * @author     Marko Pavicic <marko.pavicic@cloudsense.com>
 *             - Commented out Briefing form code
 * 
 * #02/08/2018
 * @author     Kevin Wu <kevin.wu@cloudsensesolutions.com>
 *             - Added a static trigger switch to avoid indefinite loop
 *
 * #09/11/2018
 * @author     LBK <logabalakrishnan.muthukrishnan@news.com.au>
              - //NR-1908 - Update Email Template fields for the sales orders that are being sent for Internal Approval (BEFORE UPDATE)
 */

trigger SalesOrder_Helper_Trigger on csmso__Sales_Order__c (before insert, before update, after update, after delete) {

   /*
   //CRN: Bulkify the trigger - No for loops. 
   if (trigger.isBefore) {
        SalesOrder_Helper.archiveSOP(Trigger.New);
        SalesOrder_Helper.SalesOrder_Helper(Trigger.new);
   }
    */
    //CloudSense development to identify at Opportunity level whether the opportunity is related to an approved sales order
    //Developer: Kristijan Kosutic
    //21/10/2016
    No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
    if (!notriggers.Flag__c) {
        //moving Update Name and Invoice WF to trigger AB 08-11-2018
        if (Trigger.isBefore) {
            for(csmso__Sales_Order__c item : Trigger.New){
                //for some reason this is current WF criteria, should we set Name_of_Sales_Order__c all the time?
                if (item.csmso__Total_Price__c != 0) {
                    item.Name_of_Sales_Order__c = item.Name;
                }
                //moving Update_Total_Monthly_Price_Text WF to trigger
                item.Total_Monthly_Price_Text__c = item.Total_Monthly_Price__c;
            }
        }
        if (trigger.isAfter && trigger.isUpdate) {
            // exit if the trigger (after update) has been executed in the same transaction
            //if(!CS_TriggerHelper.SalesOrder_Helper_Trigger_AfterUpdate_Active) return;
            /*
            //replaced by syncWithOpportunity
            SalesOrder_Helper.opportunityHasApprovedSO(Trigger.New, Trigger.oldMap);
            SalesOrder_Helper.createOpportunityProducts(Trigger.New,Trigger.oldMap);
            */
            SalesOrder_Helper.syncWithOpportunity(null); //no need to pass in contexts as trigger contexts is available

            //update product configs where campaign length changed on SO level
            if ( !SalesOrder_Helper.soWithCampaignChange.isEmpty()) {

                Set<Id> soTempIDs = SalesOrder_Helper.soWithCampaignChange;

                // need to clear the static set before another update through the flow
                SalesOrder_Helper.soWithCampaignChange = new Set<Id>();

                update [SELECT Id FROM cscfga__Product_Configuration__c
                WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c
                        IN : soTempIDs];
            }
			
            
            // disable this trigger once it has been executed to avoid loop
            //CS_TriggerHelper.SalesOrder_Helper_Trigger_AfterUpdate_Active = false;
        }
        /*
        //replaced by syncWithOpportunity() as SO shouldn't be deleted nor should they be created as approved
        //i.e. they shouldn't affect Has_an_Approved_SO__c field on Opportunity
        if (trigger.isAfter) {
            SalesOrder_Helper.opportunityHasApprovedSOAfter(Trigger.isUpdate, Trigger.isInsert, Trigger.isDelete, Trigger.isUndelete, Trigger.New, Trigger.oldMap);
        }
        */

        // CS Matija ticket NXRIII-203
        if(Trigger.isBefore && Trigger.isUpdate){
               // exit if the trigger (after update) has been executed in the same transaction
           // if(!CS_TriggerHelper.SalesOrder_Helper_Trigger_BeforeUpdate_Active) return;
            
            
            SalesOrder_Helper.soWithCampaignChange = new Set<Id>();

            SalesOrder_Helper.recountDiscountValues(Trigger.newMap,Trigger.oldMap);
            
            /*
            //NR-1908 - Update Email Template fields for the sales orders that are being sent for Internal Approval
            Map<Id, Map<String, String>> mapEmailTemplateContent = SO_EmailTemplateContentPopulationHandler.populateEmailTemplateContent(Trigger.New, Trigger.OldMap);
            */

            for(csmso__Sales_Order__c item : Trigger.New){
                if( (item.Margin__c != Trigger.oldMap.get(item.Id).Margin__c 
                    || (item.Campaign_End_Date2__c != null && Trigger.oldMap.get(item.Id).Campaign_End_Date2__c == null))
                    && item.csmso__Status__c == 'Internally Approved'){
                    
                    item.csmso__Status__c = 'Draft';
                }

                //NR-1908 - START Update Email Template fields for the sales orders that are being sent for Internal Approval                
                /*
                if(mapEmailTemplateContent.containsKey(item.Id)){
                    Map<String, String> mapContent = mapEmailTemplateContent.get(item.Id);
                    item.EmailTemplate_Approval_Reason_Content__c = String.isEmpty(mapContent.get('approvalReason')) ? '' : mapContent.get('approvalReason');
                    item.EmailTemplate_Discount_Table__c = String.isEmpty(mapContent.get('discountTable')) ? '' : mapContent.get('discountTable');
                    item.EmailTemplate_Escalation_Content__c = String.isEmpty(mapContent.get('escalationTime')) ? '' : mapContent.get('escalationTime');
                    item.EmailTemplate_Publication_Table__c = String.isEmpty(mapContent.get('publicationTable')) ? '' : mapContent.get('publicationTable');
                    item.EmailTemplate_Publication_List__c = String.isEmpty(mapContent.get('publicationList')) ? '' : mapContent.get('publicationList');
                }
                */
                //NR-1908 - END Update Email Template fields for the sales orders that are being sent for Internal Approval

                //only if we have products
                //12/06/2018 IG - including the logic of updating Campaign_Products_Type_Text__c and Campaign Start Date & Campaign End Dates & Campaign Lenght 
                if (!String.isBlank(item.Basket_Products__c)) {

                    Boolean bespokePrint = false;
                    Boolean bespokeXtend = false;
                    Boolean bundlePrintLed = false;
                    Boolean bundleXtendLed = false;
                    Boolean bundleXtend = false;
                    Boolean bundlePrint = false;
                    Boolean bundleDigital = false;
                    Boolean seasonal = false;
                    
                    //is there a Bespoke Xtend product?
                    if (item.Basket_Products__c.contains('News Xtend') ) {
                        bespokeXtend = true;
                        //System.debug('xxx gaka bespokeXtend ' + bespokeXtend);
                        
                    } 
                    //is there a Xtend component in side of bundle?
                    if (item.Basket_Products__c.contains('Bundle Xtend') ) {
                        bundleXtend = true;
                        //System.debug('xxx gaka bundleXtend ' + bundleXtend);
                        
                    }
                    //is there a Digital component in side of bundle?
                    if (item.Basket_Products__c.contains('Bundle Digital') ) {
                        bundleDigital = true;
                        //System.debug('xxx gaka bundleDigital ' + bundleDigital);
                        
                    } 
                    //is there a Print component in side of bundle?
                    if (item.Basket_Products__c.contains('Bundle Print') ) {
                        bundlePrint = true;
                        //System.debug('xxx gaka bundlePrint ' + bundlePrint);
                        
                    } 
                    //is there a Print Led Bundle?
                    if ( item.Basket_Products__c.contains('Print Led')) {
                        bundlePrintLed = true;
                        //System.debug('xxx gaka bundlePrintLed ' + bundlePrintLed);
                        
                    } 
                    //is there a Xtend Led Bundle?                    
                    if ( item.Basket_Products__c.contains('Xtend Led')) {
                        bundleXtendLed = true;
                        //System.debug('xxx gaka bundleXtendLed ' + bundleXtendLed);

                    } 
                    
                    if ( item.Basket_Products__c.contains('Print Display')) {
                        bespokePrint = true;
                        //System.debug('xxx gaka bespokePrint ' + bespokePrint);

                    }
                    
                    if (item.Campaign_Length__c!= null && item.Campaign_Length__c >= 1) {
                        seasonal = true;
                        //System.debug('xxx gaka seasonal ' + seasonal);
                        
                    }                 

                        
                    if ( ((bespokeXtend || bundleXtendLed) && (bundlePrintLed || bespokePrint)) || (bundlePrintLed && bespokePrint) ) {

                        item.Campaign_Products_Type_Text__c = 'Invalid';
                        //System.debug('xxx gaka Campaign_Products_Type_Text__c ' + item.Campaign_Products_Type_Text__c);

                    } else if ( bespokeXtend || bundleXtendLed ) {
                        
                        //System.debug('xxx gaka Campaign_End_Date__c 1 ' + item.Campaign_End_Date__c);
                        //System.debug('xxx gaka csmso__To__c 1 ' + item.csmso__To__c);

                        if (seasonal) {
                            item.Campaign_Products_Type_Text__c = 'Seasonal - News Xtend';
                            if ( bespokeXtend ) {
                                item.csmso__From__c = item.Campaign_Start_Date__c;
                                item.csmso__To__c = item.Campaign_End_Date2__c; 
                                item.Campaign_End_Date__c = item.Campaign_End_Date2__c; 
                                //System.debug('xxx gaka bespokeXtend ' + bespokeXtend);
                              
                            } else if ( bundleXtendLed ) {
                                item.Campaign_Start_Date__c = item.csmso__From__c;
                                item.Campaign_End_Date__c = item.csmso__To__c;                               
                                //System.debug('xxx gaka bundleXtendLed ' + bundleXtendLed);

                            }
                        } else {
                            item.Campaign_Products_Type_Text__c = 'Evergreen';
                            item.Campaign_End_Date__c = null;
                            if ( bespokeXtend ) { 
                                item.csmso__From__c = item.Campaign_Start_Date__c;
                            } else if ( bundleXtendLed ) {
                                item.Campaign_Start_Date__c = item.XE_Campaign_Start_Date__c;

                            }
                            
                            item.csmso__To__c = null;
                        }
                        //System.debug('xxx gaka Campaign_Products_Type_Text__c ' + item.Campaign_Products_Type_Text__c);

  
                    } else if (bundlePrintLed || bespokePrint) {

                        item.Campaign_Products_Type_Text__c = 'Seasonal - Print Led';
                        //System.debug('xxx gaka Campaign_Products_Type_Text__c ' + item.Campaign_Products_Type_Text__c);
                        if (bundlePrintLed || bespokePrint){ 
                            item.Campaign_Start_Date__c = item.csmso__From__c;
                            item.Campaign_End_Date__c = item.csmso__To__c;

                            if(item.csmso__From__c!= null && item.csmso__To__c!= null) {
                                item.Campaign_Length__c = Math.round(item.csmso__From__c.monthsBetween(item.csmso__To__c));
                            }
                        }
                    } 
                    

                } else {

                        item.Campaign_Start_Date__c = Test.isRunningTest() ? item.Campaign_Start_Date__c : null;
                        item.Campaign_End_Date__c = Test.isRunningTest() ? item.Campaign_End_Date__c : null;
                        item.csmso__From__c= Test.isRunningTest() ? item.csmso__From__c: null;
                        item.csmso__To__c= Test.isRunningTest() ? item.csmso__To__c: null;
                        item.Campaign_Length__c = Test.isRunningTest() ? item.Campaign_Length__c : null;
                        item.Campaign_Products_Type_Text__c = Test.isRunningTest()  ? item.Campaign_Products_Type_Text__c : null;
                        item.csmso__Process_Message__c = Test.isRunningTest() ? item.csmso__Process_Message__c : null;
                        item.csmso__Process_Message_Type__c = Test.isRunningTest() ? item.csmso__Process_Message_Type__c : null;
                    
                }


                // manual change possible for Bespoke Xtend only
                if ( (item.Campaign_Length__c != Trigger.oldMap.get(item.Id).Campaign_Length__c) &&
                        (item.Basket_Products__c!= null && !item.Basket_Products__c.contains('Bundle')) ) {
                    SalesOrder_Helper.soWithCampaignChange.add(item.Id);
                }


            }
            CS_SalesOrderProcessMessageHelper.updateApprovalMessage(Trigger.NewMap,Trigger.OldMap);

            // disable this trigger once it has been executed to avoid loop
            //CS_TriggerHelper.SalesOrder_Helper_Trigger_BeforeUpdate_Active = false;

            
        }
    }
}