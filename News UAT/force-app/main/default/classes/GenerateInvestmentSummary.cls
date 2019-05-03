/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of generating a Investment Summary and attaching it to the current Sales Order
 ---------------------------------------------------------*/

 global without sharing class GenerateInvestmentSummary implements csmso.SalesOrderSupport.SalesOrderCustomAction{

    global String performAction(String salesOrderId) {

        System.debug('performAction for Generate IO from Sales Order ' + salesOrderId);

        csmso__Sales_Order__c salesOrder = [select Id, csmso__Status__c, Margin_Flag__c, csmso__Total_Price__c, Campaign_Length__c, csmso__Advertiser__c, csmso__Booking_Contact__c, Total_Impressions__c from csmso__Sales_Order__c where Id = :salesOrderId];

        if (salesOrder.Total_Impressions__c  == null) {
            System.debug('Can not Generate Investment Summary, Impressions are null');
            return '{"status":"error", "message":"Can not Generate Investment Summary, Sales Order not complete"}';
        }

        if (salesOrder.Campaign_Length__c == null) {
            System.debug('Can not Manually Approve Sales Order, Campain Length null');
            return '{"status":"error", "message":"Can not Generate Investment Summary, Campaign Length unknown"}';
        }
		System.debug('Can not generate Investment, Margin to low and not approved:' + salesOrder.Margin_Flag__c );
        // Check that the Sales Order is actually in a valid state
        If (((salesOrder.csmso__Status__c == 'Draft') || (salesOrder.csmso__Status__c == 'Externally Rejected') || (salesOrder.csmso__Status__c == 'Internally Rejected')) && (salesOrder.Margin_Flag__c  == 'Margin TOO LOW'))  {
            System.debug('Can not generate Investment, Margin to low and not approved:' + salesOrder.Margin_Flag__c );
            return '{"status":"error", "message":"Can not Generate Investment Summary, Margin to low and not approved"}';
        }

        PageReference pdf = new Pagereference('/apex/InvestmentSummary?id='+salesOrderID);

        // the contents of the attachment from the pdf
        Blob bodyPdf;
   
        // returns the output of the page as a PDF
        try {
            if (Test.IsRunningTest()) {
                bodyPdf=Blob.valueOf('UNIT.TEST');
            }
            else {
                bodyPdf = pdf.getContentAsPdf();
            }
         } catch (DMLException e) {
                return '{"status":"error", "message":"'+ e.getmessage().escapejava() +'"}';
         }

         String fileName = 'InvestmentSummary_'+System.Now()+'.pdf';

         csmso__Upload_Approval__c myUploadApproval = new csmso__Upload_Approval__c();
         myUploadApproval.Name = fileName;
         myUploadApproval.csmso__Sales_Order__c = salesOrderId;
         myUploadApproval.csmso__Status__c = 'Approved';
         insert myUploadApproval;
         System.debug('myUploadApproval inserted ' + myUploadApproval);

         System.debug('Attaching file ' + fileName + ' to SalesOrder ' + salesOrderId);
         Attachment myAttachment = new Attachment();
         myAttachment.Body = bodyPdf;
         myAttachment.Name = fileName;
         myAttachment.ParentId = myUploadApproval.Id;
         insert myAttachment;

         System.debug('myAttachement inserted ' + myAttachment + ' with ParentId ' + myAttachment.ParentId);

         return '{"status":"ok", "message":"You have generated an Investment Summary for this Sales Order"}';  
    }
}