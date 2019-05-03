/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_ReinstateSalesOrderServiceHelper
* @testClassName    CS_ReinstateSalesOrderServiceTest
* @description      Helper for reinstate sales order 
*/
public with sharing class CS_ReinstateSalesOrderServiceHelper {
	final static String CACHE_DATA_FILE_NAME = 'RetractionCacheData-';
    /**
    * @name         : getAttachmentContent
    * @description  : get attachment content by attachment id
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String attachmentI
    * @return       : String
    */
	public static String getAttachmentContent(String attachmentId){
        Attachment a = [Select Id, Body From Attachment Where Id =: attachmentId];
        return a.Body.toString();
    }

    /**
    * @name         : createAttachment
    * @description  : create an attachment to backup the sales order and all the related records
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String content, String soId
    * @return       : String
    */
    public static String createAttachment(String content, String soId){
        Attachment a    = new Attachment();
        a.ParentId      = soId;
        a.Name          = CACHE_DATA_FILE_NAME + System.now();
        a.ContentType   = 'text/plain';
        a.Body          = Blob.valueOf(content);
        insert a;

        return a.Id;
    }

    /**
    * @name         : createAttachment
    * @description  : create an attachment to backup the sales order and all the related records
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String content, String soId
    * @return       : String
    */
	public static List<cscfga__Attribute__c> getAllAttributes(List<String> pcIds){
        List<cscfga__Attribute__c> attrList = new List<cscfga__Attribute__c>();
        List<String> allfields = CS_HistoryTrackingService.getAllFields('cscfga__Attribute__c');
        String queryString = 'SELECT {{AllFields}} FROM cscfga__Attribute__c WHERE  cscfga__Product_Configuration__c IN ' +  pcIds;
        queryString = queryString.replace('{{AllFields}}', String.join(allfields,','));
        attrList = (List<cscfga__Attribute__c>) Database.query(queryString);
        return attrList;
    }
}