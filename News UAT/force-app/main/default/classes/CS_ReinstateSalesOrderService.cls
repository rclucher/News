/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_ReinstateSalesOrderService
* @testClassName    CS_ReinstateSalesOrderServiceTest
* @description      Service class for reinstate sales order 
*/
public with sharing class CS_ReinstateSalesOrderService {
	final static String ERROR_MESSAGE_CANT_REINSTATE = 'Sales Order may only be reinstated when retracting on a Live Campaign, and  before Opportunity is Closed/Won!';
	final static String ERROR_MESSAGE_GENREAL_RETRACT = 'Sales Order can not be retracted';

    /**
    * @name         : validate
    * @description  : validate if the sales order can be reinstated
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c so
    * @return       : n/a
    */
    public static void validate(csmso__Sales_Order__c so){
		// validating the so status
		// validating the opportunity status
		//if( (so.csmso__Status__c != 'Closed Won' && so.csmso__Opportunity__r.StageName != 'Confirmed/Awaiting Bookings') || so.Retracted_Date__c == null){
		if( so.csmso__Opportunity__r.StageName == 'Closed Won' || so.Retracted_Date__c == null){
			throw new ReinstateSalesOrderException(ERROR_MESSAGE_CANT_REINSTATE);
		}

		Order__c co = so.Orders__r[0];
		if( co.Status__c != 'Campaign Live'){
			throw new ReinstateSalesOrderException(ERROR_MESSAGE_CANT_REINSTATE);
		}
	}

    /**
    * @name         : undo
    * @description  : restore the sales order 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String soId, String attachmentId
    * @return       : n/a
    */
    public static void undo(String soId, String attachmentId){
        List<cscfga__Product_Configuration__c> pcUpdateList = new List<cscfga__Product_Configuration__c>();
        //csmso__Sales_Order__c so = [Select Id, Retracted_Product_Configurations__c, Retraction_Cache_Data__c,
        //                                (Select Id From csmso__Product_Baskets__r) 
        //                            From csmso__Sales_Order__c 
        //                            Where Id=:salesOrderId];

        //Id prodBasketId = so.csmso__Product_Baskets__r[0].Id;
        //if(so.Retracted_Product_Configurations__c != null){
        //    List<String> pcIds = so.Retracted_Product_Configurations__c.replace('(','').replace(')','').split(',');

        //    if(!pcIds.isEmpty()){
        //        for(String pcId: pcIds){
        //            cscfga__Product_Configuration__c pc = new cscfga__Product_Configuration__c();
        //            pc.Id=pcId.trim();
        //            pc.cscfga__Product_Basket__c = prodBasketId;
        //            pcUpdateList.add(pc);
        //        }
        //    }
            
        //}

        //String cachedData = CS_ReinstateSalesOrderServiceHelper.getAttachmentContent(so.Retraction_Cache_Data__c);
        String cachedData = CS_ReinstateSalesOrderServiceHelper.getAttachmentContent(attachmentId);

        Map<String, List<SObject>> cacheDataMap = (Map<String, List<SObject>>)JSON.deserialize(cachedData, Map<String, List<SObject>>.class);

        //restore attributes
        List<cscfga__Attribute__c> oldAttrList = (List<cscfga__Attribute__c>)cacheDataMap.get('attr');
        update oldAttrList;

        //restore pc records
        List<cscfga__Product_Configuration__c> oldPcList = (List<cscfga__Product_Configuration__c>)cacheDataMap.get('pc');
        update oldPcList;

        Set<Id> oldPcIdSet = new Set<Id>();
        for(cscfga__Product_Configuration__c oldPc: oldPcList){
            oldPcIdSet.add(oldPc.Id);
        }

        // remove newly added pc
        List<cscfga__Product_Configuration__c> newPcDeleteList = new List<cscfga__Product_Configuration__c>();
        for(cscfga__Product_Configuration__c pc: [Select Id From cscfga__Product_Configuration__c Where cscfga__Product_Basket__r.csmso__Sales_Order__c =: soId ]){
            if(!oldPcIdSet.contains(pc.Id)){
                newPcDeleteList.add(pc);
            }
        }
        delete newPcDeleteList;

        //restore pc records
        List<csmso__Sales_Order__c> oldSO = (List<csmso__Sales_Order__c>)cacheDataMap.get('so');
        clearSalesOrderRetractionFields(oldSO[0]);
        update oldSO;

        // restore opportunity
        Opportunity oldOppy = new Opportunity();
        oldOppy.Id = oldSO[0].csmso__Opportunity__c;
        oldOppy.StageName = 'Closed Won';
        oldOppy.Has_an_Approved_SO__c = true;
        oldOppy.Approved_Sales_Order_Number__c = oldSO[0].Name;
        oldOppy.Campaign_Brief_Form_Completed__c = true;
        update oldOppy;
    }

    /**
    * @name         : clearSalesOrderRetractionFields
    * @description  : method to clear fields populated as part of retraction (used in reinstate and on GO-live (see NX-1618)
    *                 Can go through list of so objects and clear iteratively
    * @createdby    : Petar Mikic
    * @param        : csmso__Sales_Order__c salesOrder
    */
    public static void clearSalesOrderRetractionFields(csmso__Sales_Order__c so) {
        so.Retracted_Date__c = null;
        so.Retracted_Product_Configurations__c = null;
        so.Retraction_Cache_Data__c = null;
        so.Retraction_On__c = null;
        so.Previous_Campaign_End_Date__c = null;
        so.Previous_Campaign_Start_Date__c = null;
    }

    /**
    * @name         : backUpData
    * @description  : back up data including so, pc, attributes in an attachment record
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c salesOrder
    * @return       : String
    */
    public static String backUpData(csmso__Sales_Order__c salesOrder){
        Map<String, Object> cacheData = new Map<String, Object>(); 

        //backup all the pc
        List<cscfga__Product_Configuration__c> pcList = CS_HistoryTrackingService.getProductConfig(salesOrder.Id);
        cacheData.put('pc', pcList);

        
        List<Id> pcIds = new List<Id>();
        List<String> pcIdsForDynamicSOQL = new List<String>();
        for(cscfga__Product_Configuration__c pc: pcList){
            pcIds.add(pc.Id);
            pcIdsForDynamicSOQL.add('\'' + pc.Id + '\'');
        }

        // backup all the attributes
        List<cscfga__Attribute__c> attrList = CS_ReinstateSalesOrderServiceHelper.getAllAttributes(pcIdsForDynamicSOQL);
        cacheData.put('attr', attrList);

        //backup so
        csmso__Sales_Order__c so = CS_HistoryTrackingService.getSalesOrder(salesOrder.Id);
        cacheData.put('so', new List<csmso__Sales_Order__c> {so});

        //write it to an attachment
        salesOrder.Retracted_Product_Configurations__c = String.valueOf(pcIds);
        return CS_ReinstateSalesOrderServiceHelper.createAttachment(JSON.serialize(cacheData), salesOrder.Id);
    }

    public class ReinstateSalesOrderException extends Exception {}
}