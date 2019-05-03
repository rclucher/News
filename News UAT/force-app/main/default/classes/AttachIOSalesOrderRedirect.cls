/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is idreictly called by a button press on the CloudSense Sales Order screen
 * It performs the action of selecting a signed IO file to associate withthe Sales Order 
 ---------------------------------------------------------*/

public class AttachIOSalesOrderRedirect {

    public Id recId
    { get;set;}

    public AttachIOSalesOrderRedirect(ApexPages.StandardController ctlr)
    {
        recId = ctlr.getRecord().Id;
        System.debug('AttachIOSalesOrderRedirect' + recID);
    }

    public string fileName 
    { get;set;}

    public Blob fileBody 
    { get;set;}

    public PageReference UploadFile()
    {
        PageReference pr;

        System.debug('UpLoadFile for AttachIOSalesOrderRedirect ' + recID);
        if(fileBody != null && fileName != null)
        {

            System.debug('Creating Upload Approval ' + fileName + ' for SalesOrder ' + recID);

            csmso__Upload_Approval__c myUploadApproval = new csmso__Upload_Approval__c();
            myUploadApproval.Name = 'testName';
            myUploadApproval.Name = fileName;
            // myUploadApproval.csmso__Attachment_Id__c = myAttachment.Id;
            // myUploadApproval.csmso__Filename__c = fileName;
            myUploadApproval.csmso__Sales_Order__c = recId;
            myUploadApproval.csmso__Status__c = 'Approved';
            insert myUploadApproval;
            System.debug('myUploadApproval inserted ' + myUploadApproval);

            System.debug('Attaching file ' + fileName + ' to SalesOrder ' + recID);
            Attachment myAttachment = new Attachment();
            myAttachment.Body = fileBody;
            myAttachment.Name = fileName;
            myAttachment.ParentId = myUploadApproval.Id;
            insert myAttachment;

            System.debug('myAttachement inserted ' + myAttachment + ' with ParentId ' + myAttachment.ParentId);
            
            // Redirect back to the originating Sales Order
            pr = new PageReference('/' + recId);
            pr.setRedirect(true);
            return pr;
        }
        return null;
    }
}