public with sharing class MyFax_Helper {

    private wsMyfaxCom myFax;
    private wsMyfaxCom.MyFaxSendingWebServiceSoap ws;
    private wsMyFaxCom.Authentication authentication;
    private wsMyFaxCom.FaxOptions faxOptions;
    private wsMyfaxCom.Tags tags;
    private wsMyFaxCom.CoverPageOptions coverPageOptions;
    private wsMyFaxCom.DeliveryOptions deliveryOptions;
    private wsMyFaxCom.ArrayOfFaxRecipient faxRecipientList;
    private wsMyFaxCom.SendMyFaxRequest_element myFaxRequest;
    private Map<String,SystemParameters__c> systemParameters;
    private Integer totalDocumentListSize = 0;
    
    public wsMyFaxCom.ArrayOfBaseFaxDocument documentList;
    public Task task {get{return task = task!=null?task:new Task();}set;}

    public MyFax_Helper() {

        systemParameters = SystemParameters__c.getAll();                



        myFax = new wsMyfaxCom();
        ws = new wsMyfaxCom.MyFaxSendingWebServiceSoap();


        authentication = new wsMyFaxCom.Authentication();

        authentication.UserID  = Integer.valueOf(this.getSystemParametersValue('FaxUserId'));
        authentication.UserPassword  = this.getSystemParametersValue('FaxUserPassword');

        faxOptions = new wsMyFaxCom.FaxOptions();
        faxOptions.From_x = this.getSystemParametersValue('FaxDefaultFromText'); //String (50). The from text of the fax
        faxOptions.IsFaxableTiffs = false; //boolean. Indicate whether the fax documents are tiff files or not.

        //TODO: Should enum for values set as string in the custom setting for paper format and resolution be implemented?  

        faxOptions.PaperFormat = this.getSystemParametersValue('FaxDefaultPaperFormat'); //String (enum). "Letter", "Legal", "A4", "Default"
        faxOptions.Resolution = this.getSystemParametersValue('FaxDefaultResolution'); //String(enum). "204x98" or "204x196"

        //Cover page status flags
        tags = new wsMyfaxCom.Tags();
        tags.Urgent = false; //boolean. Cover page status flag – Urgent.
        tags.Review = false; //boolean. Cover page status flag – Review.
        tags.Informative = false; //boolean. Cover page status flag – Info.
        tags.Comment = false; //boolean. Cover page status flag – Comment.
        tags.Answer = false; //boolean. Cover page status flag – Answer.


        coverPageOptions = new wsMyFaxCom.CoverPageOptions();
        coverPageOptions.ID  = Integer.valueOf(this.getSystemParametersValue('FaxDefaultCoverPageId')); //Integer. cover page id.
        coverPageOptions.Subject = ''; //String. The subject text of the cover page.
        coverPageOptions.Phone = ''; //String. The phone text of the cover page.
        coverPageOptions.CC =  ''; //String. The CC text of the cover page
        coverPageOptions.Comment = ''; //String. The comment text of the fax cover page
        coverPageOptions.Tags = tags; //wsMyfaxCom.Tags. Cover page status flag


        deliveryOptions = new wsMyFaxCom.DeliveryOptions();
        //deliveryOptions.SendOnlyAfter; //Integer. Schedule the fax for delivery between SendOnlyBefore and SendOnlyAfter.
        // deliveryOptions.SendOnlyBefore; //Integer. Schedule the fax for delivery between SendOnlyBefore and SendOnlyAfter.
        this.confirmationEmail(this.getSystemParametersValue('FaxSendConfirmationTo')); //String. Send a fax confirmation to a specified email address.


        //Receipients
        faxRecipientList = new wsMyFaxCom.ArrayOfFaxRecipient();
        faxRecipientList.FaxRecipient = new list<wsMyfaxCom.FaxRecipient>();
        

        //attached documents
        documentList = new wsMyFaxCom.ArrayOfBaseFaxDocument();
        documentList.FaxDocument = new List<wsMyfaxCom.BaseFaxDocument>();
        

        
    }

    public wsMyfaxCom.SendMyFaxResult_element sendFax()
    {
        return sendFax(false, null, null, null);
    }

    public wsMyfaxCom.SendMyFaxResult_element sendFax(boolean createTask, id sObjectId, id whoId)
    {
        return this.sendFax(createTask,sObjectId,whoId,null);   
    }

    public wsMyfaxCom.SendMyFaxResult_element sendFax(boolean createTask, id sObjectId, id whoId, list<Attachment> attachments)
    {

        wsMyfaxCom.SendMyFaxResult_element myFaxresponse;

        if(faxRecipientList.FaxRecipient.size() <= 0 || faxRecipientList.FaxRecipient.size() > 50)
        {
            throw new MyFaxException('Invalid number of recipients: ' + faxRecipientList.FaxRecipient.size() + ', it must be between 1 and 50');
        }

        system.debug('totalDocumentListSize:' + totalDocumentListSize);
        if(!this.isDocumentListSizeUnderLimit())
        {
            throw new MyFaxException('Request max size limit reached');
        }

            myFaxRequest = new wsMyFaxCom.SendMyFaxRequest_element();
            myFaxRequest.Authentication = authentication;
            myFaxRequest.FaxOptions = faxOptions;
            myFaxRequest.CoverPageOptions = coverPageOptions;
            myFaxRequest.DeliveryOptions = deliveryOptions;
            myFaxRequest.FaxRecipientList = faxRecipientList;
            myFaxRequest.FaxDocumentList = documentList;
            myFaxresponse = ws.SendMyFax(myFaxRequest);

            Id whatId = null;

            if(sObjectId!=null)
            {
                String sObjectIdPrefix = String.valueOf(sObjectId).substring(0,3);          
                if(sObjectIdPrefix == Contact.SObjectType.getDescribe().getKeyPrefix() ||
                    sObjectIdPrefix == Lead.SObjectType.getDescribe().getKeyPrefix())
                {
                    whoId = sObjectId;
                }
                else
                {
                    whatId = sObjectId;
                }
            }

        if(!Test.isRunningTest() && myFaxresponse.Header.ErrorFlag)
        {
            String error = 'Error:' + myFaxresponse.Header.ReturnMessageCode + ' - ' + myFaxresponse.Header.ReturnMessageText;
            if(!createTask)
            {
                throw new MyFaxException(error);
            }
            else
            {
                String description = 'Fax to ' + + ' could not be sent.\nPlease review the following:\n' + error;
                description += '\nRecipients:\n';
                for( wsMyfaxCom.FaxRecipient faxRecipient : myFaxRequest.FaxRecipientList.FaxRecipient)
                {
                    description += 'Name:' + faxRecipient.Name;
                    description += '\nFax:' + faxRecipient.FaxNumber;
                }

                description += '\nComments:\n';
                description += myFaxRequest.coverPageOptions.Comment;               
                this.createTask(whatId, whoId, UserInfo.getUserId(), 'Fax could not be sent', description, system.today(), 'Open');
            }
        }
        else
        {
            if(createTask)
            {
                String description = 'This is a successful confirmation that the fax was sent for processing. On the success or error of processing the fax the \'Assigned To\' person is sent a confirmation of the result.\n\n';
                description += 'Recipients:\n';
                for( wsMyfaxCom.FaxRecipient faxRecipient : myFaxRequest.FaxRecipientList.FaxRecipient)
                {
                    description += 'Name:' + faxRecipient.Name;
                    description += '\nFax:' + faxRecipient.FaxNumber;
                }

                description += '\n\nComments:\n';

                description += '\nFax body:\n';
                description += myFaxRequest.coverPageOptions.Comment;
                
                Task newTask = this.createTask(whatId, whoId, UserInfo.getUserId(), 'Fax sent for processing', description, system.today(), 'Done');
            
                if(attachments!=null)
                {
                    for(Attachment attach : attachments)
                        attach.parentId = newTask.id;

                    insert attachments;
                }
            }
        }

        //system.debug(myFaxresponse);
        return  myFaxresponse;

    }

    public task createTask(Id whatId, Id whoId, Id ownerId, String subject, String description, Date activityDate, String status)
    {

        system.debug('@createTask whatId:' + whatId);
        system.debug('@createTask ownerId:' + ownerId);
        system.debug('@createTask whoId:' + whoId);

        task.ActivityDate = activityDate;
        task.Subject=subject;
        task.OwnerId = ownerId;
        task.WhoId = whoId;     
        task.WhatId = whatId;
        task.Status=status;
        task.Type = 'Fax - Outbound';

        task.Description = description;
        if(task.Status=='Done')
        {
            task.Wrap_Up_Reason__c = 'Other';
        }
        insert task;
        return task;
    }



    public void confirmationEmail(String emailAddress)
    {

        if(Global_Helper.isEmailAddressValid(emailAddress))
        {
            deliveryOptions.SendConfirmationTo = emailAddress;
        }
        else
        {
            throw new MyFaxException('Invalid email address:' + emailAddress + ' cannot be set as confirmation email address');
        }
    }

    public void faxResolution(Resolution res)
    {
        if(res.name() == 'High')
        {
            faxOptions.Resolution = '204x196';
        }
        else if(res.name() == 'Mid')
        {
            faxOptions.Resolution = '204x98';
        }
    }


    public void addFaxRecipient(Contact contact, String billingCode)
    {
        this.addFaxRecipient(contact.name, contact.fax, billingCode);
    }


    //Add a recipient to the recipient list
    public void addFaxRecipient(String name, String faxNumber, String billingCode)
    {
        if(faxRecipientList!=null && faxRecipientList.FaxRecipient.size()<=50)
        {
            wsMyfaxCom.FaxRecipient faxRecipient =  new wsMyfaxCom.FaxRecipient();
            faxRecipient.Name = name;
            faxRecipient.FaxNumber = faxNumber;
            faxRecipient.BillingCode = billingCode;
            faxRecipientList.FaxRecipient.add(faxRecipient);
        }
    }

    public void setCoverPageStatusUrgent(boolean value)
    {   tags.Urgent = value;    }
    
    public boolean getCoverPageStatusUrgent()
    {   return tags.Urgent; }


    public void setCoverPageStatusReview(boolean value)
    {   tags.Review = value;    }

    public boolean getCoverPageStatusReview()
    {   return tags.Review; }


    public void setCoverPageStatusInformative(boolean value)
    {   tags.Informative = value;   }

    public boolean getCoverPageStatusInformative()
    {   return tags.Informative;    }


    public void setCoverPageStatusComment(boolean value)
    {   tags.Comment = value;   }

    public boolean getCoverPageStatusComment()
    {   return tags.Comment;    }


    public void setCoverPageStatusAnswer(boolean value)
    {   tags.Answer = value;    }

    public boolean getCoverPageStatusAnswer()
    {   return tags.Answer; }


    public void setComment(String value)
    {
        coverPageOptions.Comment = value;
    }

    public String getComment()
    {
        return coverPageOptions.Comment;
    }
    
    public void setSubject(String value)
    {
        coverPageOptions.Subject = value;
    }



    /// START - FILE ATTACHMENT (documents or Attachments) ///

    public Integer addFile(id fileId)
    {
        Integer bodyLength = -1;
        String fieldIdPrefix = String.valueOf(fileId).substring(0,3);
        
        if(fieldIdPrefix == ATTACHMENT.SObjectType.getDescribe().getKeyPrefix())
        {
            bodyLength = this.addAttachment(fileId);
        }
        if(fieldIdPrefix == Document.SObjectType.getDescribe().getKeyPrefix())
        {
            bodyLength = this.addDocument(fileId);
        }
        else
        {
            throw new MyFaxException('Invalid Id, the file id must be a Attachment or a Document');
        }

        return bodyLength;
    }

    public Integer addAttachment(ID docId)
    {
        Integer bodyLength = -1;

        Attachment doc = [Select Name, ContentType, BodyLength, body From Attachment where id=:docId limit 1];
        bodyLength = this.addAttachment(doc);
        return bodyLength;
    }



    public Integer addAttachment(Attachment doc)
    {
        Integer bodyLength = -1;
        list<String> docNameParts = doc.name.split('.');
        //breaks the attachement name and use the last part as the extension
        String docType = docNameParts.size()>1?docNameParts[docNameParts.size()-1]:'';
        
        if(!doc.ContentType.startsWithIgnoreCase('text'))
        {
            bodyLength = this.addBinaryFile(EncodingUtil.base64Encode(doc.body), docType, doc.BodyLength);
        }
        else
        {
            bodyLength = this.addTextFile(doc.body.toString(), docType, doc.BodyLength);
        }

        return bodyLength;
    }


    public Integer addDocument(ID docId)
    {
        Integer bodyLength = -1;

        document doc = [select body, type, ContentType, BodyLength from document where id=:docId limit 1];
        
        bodyLength = this.addDocument(doc);

        return bodyLength;
    }

    public Integer addDocument(document doc)
    {

        system.debug('@addDocument doc:' + doc);

        Integer tempBodyLength = doc.BodyLength!=null?doc.BodyLength:doc.body.size();

        Integer bodyLength = -1;
        if(!doc.ContentType.startsWithIgnoreCase('text'))
        {
            bodyLength = this.addBinaryFile(EncodingUtil.base64Encode(doc.body), doc.type, tempBodyLength);
        }
        else
        {
            bodyLength =  this.addTextFile(doc.body.toString(), doc.type, tempBodyLength);
        }

        return bodyLength;
    }   



    private Integer addTextFile(String body, String docType, Integer BodyLength)
    {
        wsMyfaxCom.TextFaxDocument textDoc = new wsMyfaxCom.TextFaxDocument();
        textDoc.FileContent = body;
        textDoc.FileExtension = docType;
        documentList.FaxDocument.add(textDoc);
        totalDocumentListSize += BodyLength;
        return BodyLength;
    }

    private Integer addBinaryFile(String body, String docType, Integer BodyLength)
    {
        wsMyfaxCom.BinaryFaxDocument binDoc = new wsMyfaxCom.BinaryFaxDocument();
        binDoc.FileContent = body;
        binDoc.FileExtension = docType;
        documentList.FaxDocument.add(binDoc);
        totalDocumentListSize += BodyLength;
        return BodyLength;
    }

    /// FINISH - FILE ATTACHMENT (documents or Attachments) ///




    //verifies if attached documents are not over 2900000b (request max size limit of 3000000) 
    private boolean isDocumentListSizeUnderLimit()
    {
        return totalDocumentListSize <= 2900000;
        //throw new MyFaxException('Request max size limit reached');
    }



    private String getSystemParametersValue(String keyName)
    {
        return this.getSystemParametersValue(keyName,'System parameters ' + keyName + ' value has not been set');
    }

    private String getSystemParametersValue(String keyName, String errorMessage)
    {

        system.debug('systemParameters.get(keyName):' + systemParameters.get(keyName));
        system.debug('systemParameters.get(keyName).value__c:' + systemParameters.get(keyName).value__c);

        if(systemParameters.get(keyName) != null && !String.isBlank(systemParameters.get(keyName).value__c))
        {
            return systemParameters.get(keyName).value__c;
        }
        else
        {
            throw new MyFaxException(errorMessage);
        }   
        return null;
    }




    public enum PaperFormat {Letter, Legal, A4}
    public enum Resolution {Mid, High}


    public class MyFaxException extends Exception {}
    

/* for anounymous test
MyFax_Helper mfh = new MyFax_Helper();
mfh.addFaxRecipient('Test Fax news','61292882999','BillingCode-292882999');
mfh.addDocument('015O0000000Hugh');
mfh.sendfax();
*/



}