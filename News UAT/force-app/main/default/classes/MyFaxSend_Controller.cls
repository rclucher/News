public with sharing class MyFaxSend_Controller {
    
    //public Document file {get{return file = file!=null?file:new Document();} set;}
    //private list<Document> files;
    
    /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
    private final String faxNumberFormat = 'Fax numbers should follow the phone dailling standard (country code) + (area code) + (phone number)   ie. 61290008111';
    // modified by Tim Fabros 14 / 08 / 2014
    // was private boolean ignoreFaxFormat; now visible to page
    // BEGIN:
    public boolean ignoreFaxFormat {get; private set;}
    public boolean validFax {get; private set;}
    // END:
    private String oldFaxNumber;
    /**** Update Ends ****/
    
    public String faxNumberHelpText
    {
        get{return faxNumberFormat;}
        private set;
    }
    /**** Updated section finished ****/    
    
    public String selectedTemplateId { public get; public set; }
    public String searchString { public get; public set; }
    public list<document> documentList { public get; public set; }
    
    /*
     * Updated by Bohao Chen 
     * Date 6/Jan/2015
     * Update reason: client broke Ad Proofing folder into different sub folders for different states.
     *      Code has to be updated to be able to retrieve all email templates from all these folders.
     */
    public List<SelectOption> getMyPersonalTemplateOptions() 
    {        
        //Grab our folder ID.
        String folderName = 'Ad Proofing%';
        List<Folder> faxFolders = [Select Id from Folder WHERE Name LIKE: folderName];
        List<SelectOption> options = new List<SelectOption>();
        if(!faxFolders.isEmpty()) {
            
            options.add(new SelectOption('', 'Please Select One'));
            
            //String faxFolderId = faxFolder[0].Id;
            
            // Each User has a 'My Personal Templates' folder
            // of EmailTemplates, whose Id is the User's Id
            for (EmailTemplate t : [
                select Id,Name 
                from EmailTemplate
                where FolderId IN: faxFolders
                ORDER BY NAME Asc
                
            ]) {
                options.add(new SelectOption(t.Id,t.Name));
            }
            
        }
        return options;
    }
    
    
    public void setEmailBody() {
        if(selectedTemplateId != null){
            EmailTemplate et = [select Id, Name, Body, Subject from EmailTemplate WHERE Id =:selectedTemplateId];
            if(et!= null) {
                String commentText = et.Body;
                //String commentText = et.textOnly;
                
                
                //Replace email text
                if(Apexpages.CurrentPage().getparameters().get('relatedToId')!=null)
                {
                    relatedToId = Apexpages.CurrentPage().getparameters().get('relatedToId');
                    boolean isPa = false;
                    String relatedToIdPrefix = relatedToId.left(3);
                    DescribeSObjectResult d = Global_Helper.getSObjecDescribetBySObjectPrefix(relatedToIdPrefix);
                    
                    if(d!=null)
                    {
                        
                        
                        if(d.getLabel() == 'Case') {
                            
                            //Grab case
                            Case c = [SELECT Contact.FirstName, Total_Booking_Cost__c, Booking_Run_Schedule__c, Booking_Classification__c, Contact.LastName, Account.Name, Booking__r.Name, CaseNumber FROM Case WHERE ID=:relatedToId];
                            User u = [SELECT FirstName, LastName, Title FROM User WHERE Id=:UserInfo.getUserId()]; //Cant get title without querying
                            
                            
                            
                            if(c!= null && u != null) {
                                
                                faxSubject = et.Subject;
                                if(et.Subject != null)
                                    faxSubject=et.Subject.replace('{!Case.Booking__c}', '' + c.Booking__r.Name).replace('null', '');  
                                commentText = commentText.replace('{!Case.Contact}', c.Contact.FirstName + ' ' + c.Contact.LastName);         
                                commentText = commentText.replace('{!Case.Account}', '' + c.Account.Name);         
                                commentText = commentText.replace('{!Case.Booking__c}', '' + c.Booking__r.Name);  
                                commentText = commentText.replace('{!User.FirstName}', '' + u.FirstName);  
                                commentText = commentText.replace('{!User.LastName}', '' + u.LastName);  
                                commentText = commentText.replace('{!User.Title}', '' + u.Title);  
                                commentText = commentText.replace('{!Case.CaseNumber}', '' + c.CaseNumber); 
                                commentText = commentText.replace('{!Case.Booking_Classification__c}', '' + c.Booking_Classification__c); 
                                commentText = commentText.replace('{!Case.Booking_Run_Schedule__c}', '' + c.Booking_Run_Schedule__c); 
                                commentText = commentText.replace('{!Case.Total_Booking_Cost__c}', '$' + String.valueOf(c.Total_Booking_Cost__c));  
                                commentText = commentText.replace('null', '');  
                                
                                
                            }
                        }
                    }
                }
                comment = commentText;
                
                /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
                ignoreFaxFormat = false;
                /**** Update Ends ****/
                
            }
            
        } else { 
            comment='';
            faxSubject='';
        }
    }
    
    
    public void InitiateDocumentList() {
        if(searchString != null) {
            String searchQuery = '%' + searchString + '%';
            documentList = [SELECT Id, Description, Name, Url, LastModifiedDate from Document where Name like:searchQuery ORDER BY LastModifiedDate Desc Limit 20 ];
            
            if(documentList != null) {}
        }
    }
    
    
    
    
    private ApexPages.StandardController controller;
    
    public list<attachedDoc> fileList {get{return fileList = fileList!=null?fileList:new list<attachedDoc>();} private set;}
    public Integer totalSize {get{return totalSize = totalSize!=null?totalSize:0;} private set;}
    
    public Case caseProxy {get{return caseProxy = caseProxy != null?caseProxy:new Case();}private set;}
    public Contact contact {get;private set;}
    
    public String contactName {get;set;}
    public String faxNumber {get;set;}
    public String faxSubject {get;set;}
    //public String confirmationEmail {get;set;}
    public boolean isUrgent {get;set;}
    public boolean isReview {get;set;}
    public boolean isInformative {get;set;}
    public boolean isComment {get;set;}
    public boolean isAnswer {get;set;}
    public String comment {get;set;}
    
    
    public MyFax_Helper myFax;
    public String relatedTo {get;set;}
    private list<SelectOption> relatedToList;
    public list<SelectOption> getRelatedToList()
    {
        if(relatedToList==null)
        {
            relatedToList = new list<SelectOption>();
            relatedToList.add(new SelectOption('Account', 'Account'));
            relatedToList.add(new SelectOption('Booking', 'Booking__c'));           
            relatedToList.add(new SelectOption('Case', 'Case'));
            relatedToList.add(new SelectOption('Contact', 'Contact'));      
            relatedToList.add(new SelectOption('Lead', 'Lead'));
            relatedToList.add(new SelectOption('Opportunity', 'Opportunity'));
            relatedToList.sort();           
        }
        return relatedToList;
    }
    
    public string relatedToId {get;private set;}
    public string relatedToObject {get;private set;}
    public string relatedToName {get;private set;}
    
    private Id folderId
    {
        get {return folderId = folderId == null ? [Select id From Folder where developerName='Fax_Attachments'].id : folderId;}
        private set;
    }
    
    
    
    public MyFaxSend_Controller() {
        /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
        this.ignoreFaxFormat = false;
        myfax = new MyFax_Helper();
        /**** Update Ends ****/
        /*
        mfh.addFaxRecipient('Test Fax news','61292882999','BillingCode-292882999');
        mfh.addDocument('015O0000000Hugh');
        mfh.sendfax();
        */   
    }
    
    public MyFaxSend_Controller(ApexPages.StandardController controller) {
        /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
        this.ignoreFaxFormat = false;
        /**** Update Ends ****/
        
        myfax = new MyFax_Helper();
        this.controller = controller;
        //folderId = [Select id From Folder where developerName='Fax_Attachments'].id;
        
        if(Apexpages.CurrentPage().getparameters().get('relatedToId')!=null)
        {
            relatedToId = Apexpages.CurrentPage().getparameters().get('relatedToId');
            boolean isPa = false;
            String relatedToIdPrefix = relatedToId.left(3);
            DescribeSObjectResult d = Global_Helper.getSObjecDescribetBySObjectPrefix(relatedToIdPrefix);
            system.debug('@ MyFaxSend_Controller d:'+d);
            if(d!=null)
            {
                
                string contactLookupApiName = null;
                relatedToObject = d.getLabel();
                
                if(relatedToObject == 'Opportunity')
                {
                    contactLookupApiName = 'contact__r.Name';
                }
                
                else if(relatedToObject == 'Case')
                {
                    contactLookupApiName = 'contact.id';
                }
                else if(relatedToObject == 'Booking')
                {
                    contactLookupApiName = 'Placer_contact__r.Name';                                                                 
                }
                else if(relatedToObject == 'Account')
                {
                    isPa = isPrivateAccount(relatedToId);
                }
                
                
                String soql = 'Select ';
                soql += d.getName()!='Case'?'Name':'CaseNumber';
                soql += isPa?', PersonContactId':'';                            
                soql += contactLookupApiName!=null?',' + contactLookupApiName:'';
                soql += ' from ' + d.getName();
                soql += ' where id=\'' + relatedToId + '\'';
                
                
                system.debug('@ MyFaxSend_Controller soql:'+soql);
                
                List<sObject> sObjectList = Database.query(soql);
                
                if(sObjectList.size()>0)
                {
                    relatedToName = String.valueOf(sObjectList[0].get(d.getName()!='Case'?'Name':'CaseNumber'));                                    
                    
                    if(isPa)
                    {
                        string contactId = String.valueOf(sObjectList[0].get('PersonContactId'));
                        contact = [Select name, fax from contact where id = :contactId];
                        caseProxy.contactId = contact.Id;
                        faxNumber = contact.fax;
                        contactName = contact.Name;                                        
                    }
                    else if(contactLookupApiName!=null && contactLookupApiName.contains('.'))
                    {
                        list<String> contactLookupApiNameParts = contactLookupApiName.split('\\.');
                        if(sObjectList[0].getSObject(contactLookupApiNameParts[0])!=null)
                        {
                            string contactId = String.valueOf(sObjectList[0].getSObject(contactLookupApiNameParts[0]).get('id'));
                            contact = [Select id, name, fax from contact where id = :contactId];
                            caseProxy.contactId = contact.Id;
                            faxNumber = contact.fax;
                            contactName = contact.Name;
                        } 
                    }
                    else if (d.getName()=='Contact')
                    {
                        contact = [Select name, fax from contact where id = :relatedToId];
                        caseProxy.contactId = contact.Id;
                        faxNumber = contact.fax;
                        contactName = contact.Name;
                    }
                    
                }
                else
                {
                    ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, 'Invalid related to Id'));
                }
            }
        }
    }
    
    // this function has been updated by Bohao Chen on 12 Auguest 2014 for JIRA SFE-339
    public void onChangeContact()
    {
        contact = null;
        
        if(caseProxy.contactId != null)
        {
            contact = [Select name, fax from contact where id = :caseProxy.contactId];
            faxNumber = contact.fax;
            
            /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
            ignoreFaxFormat = false;
            /**** Update Ends ****/
            
            contactName = contact.Name;
            System.debug('****JM sending name: ' + contactName);
        }        
    }
    
    public PageReference doCancel()
    {
        return new PageReference('/' + relatedToId);
    }
    
    private boolean isPrivateAccount(String accountId)
    {       
        list<Account> accts = [select id, isPersonAccount from account where id = :accountId];
        
        boolean isPa = false;
        
        if(accts.size()>0)
            isPa = accts[0].isPersonAccount;
        
        return isPa;                    
    }
        
    public PageReference doSendFax()
    {        
        PageReference pr = null;
        validFax = true;
        
        /**** Updated by Bohao Chen from Bluewolf for JIRA case SFE-213 on 30/Apr/2014 ***/
        // validate fax number format 
        
        if(this.oldFaxNumber != faxNumber)
        {
            this.ignoreFaxFormat = false;
            this.oldFaxNumber = faxNumber;
        }
        
        if(faxNumber==null || String.isBlank(faxNumber) || !pattern.matches('[0-9]+',faxNumber))
        {
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, 'Fax numbers can only contain numbers. Please check the fax number'));
            validFax = false;
            return pr;
        }
        else if(!Global_Helper.isValidFax(faxNumber) && !this.ignoreFaxFormat)
        {     
            // only show warning message but don't block user from saving it.
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Warning, 'Fax number has invalid format. Please make sure fax number is correct before sending a fax. Otherwise, click "Send Fax" button to send this fax.'));
            this.ignoreFaxFormat = true;
            validFax = false;
            return pr;
        }            
        /**** Update Ends ****/    
        
        /*try
{*/
        
        myFax.addFaxRecipient(contactName,faxNumber, relatedToObject + ':' + relatedToName);
        
        myFax.confirmationEmail(UserInfo.getUserEmail());
        
        myfax.setCoverPageStatusUrgent(isUrgent);
        myfax.setCoverPageStatusReview(isReview);
        myfax.setCoverPageStatusInformative(isInformative);
        myfax.setCoverPageStatusComment(isComment);
        myfax.setCoverPageStatusAnswer(isAnswer);
        myFax.setSubject(faxSubject);
        
        
        myfax.setComment(comment);
        
        system.debug(logginglevel.error, '@myfaxsend_controller myfax: ' + myfax);
        
        list<Attachment> attachments = new list<Attachment>();
        
        if(myFax.documentList!=null && myFax.documentList.FaxDocument!=null)
            myFax.documentList.FaxDocument.clear();
        
        map<String, attachedDoc> attachedDocByIdsMap = this.getAttachedDocByIdsMap();
        
        if(fileList!=null)
        {
            system.debug('@doSendFax getDocumentIds:' + attachedDocByIdsMap.keySet());
            map<id, Document> documentById = new Map<id, Document>([Select id, body From Document where id in :attachedDocByIdsMap.keySet()]);
            for(string s : attachedDocByIdsMap.keySet())
            {
                system.debug('@doSendFax documentById:' + documentById);
                system.debug('@doSendFax d:' + s);
                myfax.addDocument(s);
                
                if(documentById.containsKey(s))
                {
                    Attachment att = new Attachment();
                    att.body = documentById.get(s).body;
                    att.name = attachedDocByIdsMap.get(s).name;
                    attachments.add(att);
                }
            }
            
            
        }
        
        // updated by Bohao Chen on 12 Auguest, 2014 for JIRA SFE-339
        if(contact == null)
            myfax.sendFax(true, relatedToId, null, attachments);
        else
            myfax.sendFax(true, relatedToId, contact.id, attachments);
        
        deleteAttachmentDocumets(attachedDocByIdsMap.keySet());
        
        pr = new PageReference('/' + relatedToId);
        /*}
catch (MyFax_Helper.MyFaxException e)
{
ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, e.getMessage()));
}
catch(Exception e)
{
ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Error, e.getMessage() + ' ' + e.getCause()));
}*/
        
        return pr;
    }
    
    public void attachFile()
    {
        
        Document file = (Document)this.controller.getRecord();
        
        if(file == null || file.name == null)                   
            return;
        
        system.debug('@totalSize: ' + totalSize);
        system.debug('@file: ' + file);
        system.debug('@file.bodyLength: ' + file.bodyLength);
        
        if(totalSize + file.bodyLength > 2900000){
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.Info,'File could not be added. The total size must not be over 2.9MB'));
            file.body = null;
            return;
        }
        
        file.developerName = file.name.left(60) + datetime.now().getTime();
        file.developerName = 'd' + file.developerName.replace(' ','_').replace('.','_').replace(':','_').replace('-','_');
        file.folderid = folderId;
        
        system.debug('@attachFile file.developerName:' + file.developerName);
        
        Insert file;
        
        
        
        fileList.add(new attachedDoc(file.name, file.developerName, file.contentType, file.bodyLength, file.id));
        totalSize += file.bodyLength;
        
        
        file.body = null;
        file.id = null;
    }
    
    
    public void removeAttachedFile()
    {
        String selectedFileToRemove = ApexPages.currentPage().getparameters().get('selectedFileToRemove');
        system.debug('selectedFileToRemove:' + selectedFileToRemove);
        
        Integer indexList = -1;          
        for(Integer i = 0; i < fileList.size(); i++)
        {
            if(fileList[i].devName == selectedFileToRemove)
            {
                indexList = i;
                break;
            }
        }
        
        if(indexList >= 0 && indexList < fileList.size())
        {
            document d = [select id from document where id =: fileList[indexList].id];
            delete d;
            totalSize -= fileList[indexList].bodyLength;
            fileList.remove(indexList);
        }
    }
    
    private map<String, attachedDoc> getAttachedDocByIdsMap()
    {
        map<String, attachedDoc> attDocMap = new map<String, attachedDoc>();        
        for(attachedDoc attDoc : fileList)
        {
            attDocMap.put(attDoc.id, attDoc);
        }
        return attDocMap;
    }
    
    
    @future
    static void deleteAttachmentDocumets(set<string> docIds)
    {
        list<document> docs = [select id from document where id IN :docIds];
        delete docs;
    }
    
    public class attachedDoc {
        public String name {get; private set;}
        public String devName {get; private set;}
        public String type {get; private set;}
        public String size {get; private set;}
        public Integer bodyLength {get; private set;}
        public String id {get; private set;}
        
        public attachedDoc(String inName, String inDevName, String inType, Integer inSize, String inId)
        {
            name = inName;
            devName = inDevName;
            type = inType;
            bodyLength = inSize;
            size = inSize  / 1000 + 'KB';
            id = inId;
        }
        
    }
    
    
}