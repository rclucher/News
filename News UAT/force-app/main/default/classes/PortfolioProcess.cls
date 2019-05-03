//Update PortfolioProcess batch job to copy Portfolio_Staging_c.Portfolio_Segment_c to Portfolio2c.Portfolio_Segment__c

/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Batch Apex to process from Portfolio_Staging__c to Portfolios2__c
 * @description Modified 2018-01-29 Paul Kang changed the Portfolio2__c fields to text to minimise lookups
 *              Modified 2018-10-09	Pratyush Chalasani	NR-1426: User matching is case sensitive
 *              
 **/

global class PortfolioProcess implements Database.Batchable<sObject>, Database.Stateful {
    
    String query = 'SELECT Id, OwnerId, Portfolio_Name__c, CreatedDate, Conformed_Name__c, Conformed_Owner__c, Group_Name__c, Group_Owner__c, Master_Name__c, Master_Owner__c, Portfolio_Code__c, Sub_Master_Name__c, Sub_Master_Owner__c, Portfolio_Name_Owner__c, Portfolio_Segment__c, CreatedById FROM Portfolio_Staging__c';     
    
    global Map<String, Id> adListUsers { get; set;}
    global Map<String, Id> fullNameUsers { get; set;}

    global Boolean deleteStagingOnComplete {get; set;}
    public Boolean sendEmailIfStagingEmpty {get; set;}
    public String primaryEmailAddress {get;set;}
    public String secondaryEmailAddress {get;set;}

    global Integer recordsProcessed = 0; 
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }   


    global PortfolioProcess() {
        LoadUsers();
        LoadMDT();
    }

    // Check the custom meta data settings configuration
    private void LoadMDT() {
        List<Portfolio_Process_Settings__mdt> settings = [SELECT Id, Label, Delete_Staging_on_complete__c, Send_Email_when_staging_is_empty__c, Primary_alert_email_address__c, Secondary_alert_email_address__c FROM Portfolio_Process_Settings__mdt where Label ='Default'];

        System.debug('@settings ' + settings);
        deleteStagingOnComplete = Boolean.valueOf(settings[0].Delete_Staging_on_complete__c);
        sendEmailIfStagingEmpty = Boolean.valueOf(settings[0].Send_Email_when_staging_is_empty__c);
        primaryEmailAddress = settings[0].Primary_alert_email_address__c;
        secondaryEmailAddress = settings[0].Secondary_alert_email_address__c;
    }
    

    private void LoadUsers() {
        adListUsers = new Map<String, Id>();
        fullNameUsers = new Map<String,Id>();

        for (User user : [Select Id, Name, Username, Email, Network_Username__c FROM User WHERE IsActive = true]) {
            // add to each map
            
            // NR-1426: User matching is case sensitive
            // converting names to lower case so that key lookup can be case-insensitive
            if (user.Network_Username__c != null) adListUsers.put(user.Network_Username__c.toLowerCase(), user.Id);
            fullNameUsers.put(user.Name.toLowerCase(), user.Id);
        }
        System.debug('ADListUsers Map size ' + adListUsers.size());
        System.debug('FullNameUsers Map size ' + fullNameUsers.size());
    }


    global void execute(Database.BatchableContext BC, List<Portfolio_Staging__c> scope) {       

        System.debug('@number of records in Staging : ' + scope.size());

        if (scope.size() > 0) {
        
            List<Portfolio2__c> portfolios = new List<Portfolio2__c>();
            
            for(Portfolio_Staging__c port : scope) {
                Portfolio2__c portDest = new Portfolio2__c();
                portDest.Conformed_Name__c = port.Conformed_Name__c;
                portDest.Conformed_Owner__c = port.Conformed_Owner__c;
                portDest.Name = port.Portfolio_Name__c;
                portDest.Portfolio_Code__c = port.Portfolio_Code__c;
                portDest.Group_Name__c = port.Group_Name__c;
                portDest.Group_Owner__c = port.Group_Owner__c;
                portDest.Master_Name__c = port.Master_Name__c;
                portDest.Master_Owner__c = port.Master_Owner__c;
                portDest.Sub_Master_Name__c = port.Sub_Master_Name__c;
                portDest.Sub_Master_Owner__c = port.Sub_Master_Owner__c;
                portDest.Portfolio_Segment__c = port.Portfolio_Segment__c;
              
                portfolios.add(portDest);
                recordsProcessed = recordsProcessed + 1;
            }
            upsert portfolios Portfolio_Code__c;

            AssignPortfolioOwners();
       } else if (scope.size() == 0) {
            if (sendEmailIfStagingEmpty == true) {

                String[] toAddresses = new String[]{ primaryEmailAddress, secondaryEmailAddress };

                Batch_Utility.sendEmail(toAddresses, 'No records loaded from Staging object','PortfolioProcess failed, Portfolio_Staging__c is empty');
            }
       }
    }


    // Upsert the Junction Object for Portfolio_Owner__c between Portfolio2__c and User
    private void AssignPortfolioOwners() {
        List<Portfolio_Owners__c> portOwners = new List<Portfolio_Owners__c>();
        
        Set<Id> deletionIDs = new Set<Id>();
        
        try 
        {
            for(Portfolio2__c savedPorts: [Select Id, Portfolio_Code__c, Conformed_Owner__c, Conformed_Name__c from Portfolio2__c]) {

                Portfolio_Owners__c owner = new Portfolio_Owners__c();
                owner.Name = savedPorts.Portfolio_Code__c + '|' + savedPorts.Conformed_Owner__c.toLowerCase();
                owner.Portfolio2__c = savedPorts.Id;

                Id userId = GetUser(savedPorts.Conformed_Owner__c, true);
                if (userId != null) {
                    owner.Portfolio_Owner__c = userId;
                    // Add to collection
                    portOwners.add(owner);
                    System.debug('@owner added ' + owner.Portfolio_Owner__c);
                } else {
                    // Delete owner records for which user can't be found
                    deletionIDs.add(savedPorts.Id);
                }                 
            }
			
            
			
            //SFE-978 Begins
			//upsert portOwners Name; 
			// just deleting deletionIDs is not required as we are deleting all the records from Portfolio_Owners__c
            //List<Portfolio_Owners__c> deleteOwners = [SELECT Id FROM Portfolio_Owners__c WHERE Portfolio2__c IN :deletionIDs];
            List<Portfolio_Owners__c> deleteOwners = [SELECT Id FROM Portfolio_Owners__c LIMIT 50000];
            if (!deleteOwners.isEmpty()) delete deleteOwners;
			insert portOwners;
			//SFE-978 Ends

        }
        catch(Exception ex) {
            System.debug('@ex' + ex);
        }
    }



    // Get user Id
    @TestVisible
    private Id GetUser(string name, Boolean isNetworkName) {
        Id user;

        if (isNetworkName == true) {
            user = adListUsers.get(name.toLowerCase());
        } else 
        {
            user = fullNameUsers.get(name.toLowerCase());
        }
        
        return user;
    }

    
    global void finish(Database.BatchableContext BC) {
        System.debug(recordsProcessed + ' records processed!');

        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors FROM AsyncApexJob WHERE ID = :BC.getJobId() ];

        System.debug('@jobs processed ' + job);

        if (deleteStagingOnComplete == true) {
            // Delete 
            BatchDeleteProcess deleteProcess = new BatchDeleteProcess();
            Database.executeBatch(deleteProcess,2000);
            BatchDeleteProcess deleteProcessforStaging = new BatchDeleteProcess(true);
            Database.executeBatch(deleteProcessforStaging,2000);
            
        }


        Integer portfoliosCount = [Select count() from Portfolio2__c];
        if (portfoliosCount == 0) { 
            System.debug('@Portfolio2__c is empty'); 
        } else {

                // Once complete start the PortfolioAccountMapping batch
                PortfolioAccountMappingProcess p = new PortfolioAccountMappingProcess();
                Database.executeBatch(p);
            }
        }

        
    
}