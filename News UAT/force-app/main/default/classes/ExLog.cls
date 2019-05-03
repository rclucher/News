/** 
 *
 * @author      Will Saunders, Bluewolf 
 * @description ExLog is a utility for logging exceptions in a robust manner.
 * @description Modified 2015-09-16 louis.wang@bluewolf.com
 *				- to improve the usablitiy
 **/

public class ExLog {

    ///////////////////////////////////////////////////////
    //////          Constants
    ///////////////////////////////////////////////////////
    public static final Boolean UNPACK_EXCEPTIONS = true;
    public static final Boolean DONT_UNPACK_EXCEPTIONS = !UNPACK_EXCEPTIONS;

    private static final String TRACE_PREFACE = 'EXCEPTION!!! - ';
    private static final String SINGLE_LINE_DELIM = '\n';
    private static final String DESC_LINE_DELIM = SINGLE_LINE_DELIM + SINGLE_LINE_DELIM;
    private static final String SINGLE_TAB_DELIM = '\t';
    
    private static final Boolean WILL_INSERT = true;
    private static final Boolean WONT_INSERT = !WILL_INSERT;

    private static final String ATTACHMENT_FILE_NAME = 'Additinal Detail.txt';
    private static final String ATTACHMENT_CONTENT_TYPE = 'txt';

	private static Ex_Log_Config__c config;

    private static Map<String, Id> apexClassName2Id = new Map<String, Id>();
    private static List<Exception_Log__c> logsToFlush = new List<Exception_Log__c>();
    private static Exception_Log__c PARENTLESS_LOG_KEY = new Exception_Log__c();
    
    public Enum Level { HIGH, MEDIUM, LOW }

    private ExLog() { }

	/**
    * @date 	2015-09-17
    * @author 	louis.wang@bluewolf.com
    * @description  Log with sObject info (to object Exception_Log__c)
    * @param System.Exception
    * @param String
    * @param sObject
    * @param String
    * @return N/A
    **/       
    public static void log( System.Exception exceptionToLog, 
                            String exLogConfigParam, 
                            sObject sobj, 
                            String additionalInfo ) 
    {
        // put single sobject into the list as a parameter
        if(sobj!=null)
        {
            List<sObject> sobjList = new List<sObject>();
            sobjList.add(sobj);
            log( exceptionToLog, exLogConfigParam, sobjList, additionalInfo );
        }
        else
        {
            log( exceptionToLog, exLogConfigParam, (List<sObject>)null, additionalInfo );
        }
    }

	/**
    * @date 	2015-09-17
    * @author 	louis.wang@bluewolf.com
    * @description  Log with List<sObject> info (to object Exception_Log__c)
    * @param System.Exception
    * @param String
    * @param List<sObject>
    * @param String
    * @return N/A
    **/   
    public static void log( System.Exception exceptionToLog, 
                            String exLogConfigParam, 
                            List<sObject> sobjList, 
                            String additionalInfo ) 
    {
        config = fetch_Config(exLogConfigParam);
        log( exceptionToLog, sobjList, additionalInfo );
    }

    public static void log( System.Exception exceptionToLog, 
                            List<sObject> sobjList, 
                            String additionalInfo ) 
    {
        // 2015-09-15 louis.wang@bluewolf.com 
        //  - Added try-catch so it can fail silently
        try         
        {
            List<Exception_Log__c> exLogsToSave = loggedExceptionFactory( new List<System.Exception>{ exceptionToLog }, 
                                                                                UserInfo.getUserId(),
                                                                                additionalInfo );
            saveLogs( exLogsToSave );

            // 2015-09-15 louis.wang@bluewolf.com 
            //  - Save attachment against the 1st record in the list
            //  - due to private sharing model, need to update OwnerIds after record creation
            Attachment att;
            String sobjListString;          
            if(sobjList!=null)
            {
                // serialize the list to a string
                sobjListString = JSON.serialize(sobjList);
                att = saveAttachment(sobjListString, exLogsToSave[0].Id);
            }
            // update OwnerIds
            update_OwnerIds(att, exLogsToSave);            
        }
        catch(Exception ex)
        {
            system.debug('@@ExLog.log error = ' + ex.getMessage());
        }
    }

    private static List<Exception_Log__c> loggedExceptionFactory( List<System.Exception> exceptionsToLog, 
                                                                    Id whoCausedId,
                                                                    String additionalInfo ) 
    {
        List<Exception_Log__c> logs = new List<Exception_Log__c>();
        
        for ( System.Exception anExToLog : exceptionsToLog ) 
        {
            String exType = anExToLog.getTypeName();
            String exDesc = createExDescription( anExToLog );
            if(exType=='System.DmlException')
            {
            	exDesc += createDmlExDescription( (System.DmlException)anExToLog );
            }

            Exception_Log__c exLog = new Exception_Log__c( Who__c = whoCausedId,
                                                                 Type__c = exType,
                                                                 Line_Number__c = anExToLog.getLineNumber(),
                                                                 Session_Id__c = UserInfo.getSessionId(),
                                                                 Organization_Id__c = UserInfo.getOrganizationId(),
                                                                 Organization_Name__c = UserInfo.getOrganizationName(),
                                                                 Exception_Description__c = exDesc,
                                                                 Additional_Info__c = additionalInfo,
                                                                 Key_Person_to_Notify__c = config.Key_Person_to_Notify__c);
            
            if ( config.Logging_Level__c==string.valueOf(Level.HIGH) )
            {
	            String className = extractClassName( anExToLog.getStackTraceString() );
	            exLog.Class_Name__c = className;
                exLog.Class_Id__c = resolveClassId( className );
            }
            
            logs.add( exLog );
        
        }
        
        return logs;
        
    }

    private static String createExDescription( System.Exception anExToLog ) 
    {
        String exDescription = anExToLog.getMessage() + DESC_LINE_DELIM + anExToLog.getStackTraceString();
        
        if ( anExToLog.getCause() != null )
            exDescription += DESC_LINE_DELIM + createExDescription( anExToLog.getCause() );
        
        return exDescription;
        
    }

    private static String extractClassName( String stackTrace ) {

        String output = '';     
        String className = '';
        
        List<String> stackPieces = stackTrace.split( ':' );

        if ( !stackPieces.isEmpty() )
        {
            className = stackPieces[0];

            // 2015-09-15 louis.wang@bluewolf.com 
            //  - Not every exception to contain classname, so check before process it.
            if(className.contains( '.' ))
            {
                List<String> classNamePieces = className.split( '\\.' ); // split uses regular expression, so a bit differ to contains.
                // className = classNamePieces[1];                  
                output = classNamePieces[0] + '.' + classNamePieces[1];
            }
        }
        return output;
    }
    
    private static Id resolveClassId( String className ) {
        
        if ( apexClassName2Id.containsKey( className ) )
            return apexClassName2Id.get( className );
        
        Id classId;
        
        // 2015-09-15 louis.wang@bluewolf.com 
        //  - Not every exception contains classname, so check before process it.
        if(className.contains('.'))
        {
            List<String> namePieces = className.split('\\.'); // split uses regular expression, so a bit differ to contains.
            String codeType = namePieces[0];
            String name = namePieces[1];
            
            try {
                
                if ( codeType == 'Class' ) {
                    
                    classId = [ SELECT Id FROM ApexClass WHERE Name LIKE :name+'%' ].Id;
                    
                } else if ( codeType == 'Trigger' ) {
                    
                    classId = [ SELECT Id FROM ApexTrigger WHERE Name LIKE :name+'%' ].Id;
                }
                    
                apexClassName2Id.put( className, classId );
                    
                return classId;
                
            } catch( System.Exception ex ) { }
        }
        return null;
            
    }
    
    private static String createDmlExDescription( System.DmlException aDmlExToLog ) 
    {
        String output = DESC_LINE_DELIM;
        	  output += aDmlExToLog.getNumDml() + ' DML lines involved in this Exception: ' + SINGLE_LINE_DELIM;
        
        for ( Integer dmlErrIndex = 0; dmlErrIndex < aDmlExToLog.getNumDml(); dmlErrIndex++ )
            output += createDmlExDescription_detail( aDmlExToLog, dmlErrIndex ) + SINGLE_LINE_DELIM;
        
        return output;        
    }
    
    private static String createDmlExDescription_detail( System.Dmlexception aDmlExToLog, Integer dmlErrIndex ) {
        
        String dmlErrorDescription = SINGLE_TAB_DELIM + 'Message: ' + aDmlExToLog.getDmlMessage( dmlErrIndex ) + SINGLE_LINE_DELIM;
        dmlErrorDescription += 		 SINGLE_TAB_DELIM + 'Status Code: ' + aDmlExToLog.getDmlStatusCode( dmlErrIndex ) + SINGLE_LINE_DELIM;
        dmlErrorDescription += 		 SINGLE_TAB_DELIM + 'Type: ' + aDmlExToLog.getDmlType( dmlErrIndex ) + SINGLE_LINE_DELIM;
        dmlErrorDescription += 		 SINGLE_TAB_DELIM + 'Id: ' + aDmlExToLog.getDmlId( dmlErrIndex ) + SINGLE_LINE_DELIM;
        dmlErrorDescription += 		 SINGLE_TAB_DELIM + 'FieldName: ' + aDmlExToLog.getDmlFieldNames( dmlErrIndex ) + SINGLE_LINE_DELIM;
        dmlErrorDescription += 		 SINGLE_TAB_DELIM + 'Index: ' + aDmlExToLog.getDmlIndex( dmlErrIndex ) + SINGLE_LINE_DELIM;

        return dmlErrorDescription;
    }

    private static void saveLogs( List<Exception_Log__c> logsToSave ) 
    {
        if ( config.Flushable__c )
            logsToFlush.addAll( logsToSave );
        else
            insert logsToSave;
    }
    
    public static void flushLogCache() {
        
        if ( !logsToFlush.isEmpty() ) 
        {
            insert logsToFlush;
            logsToFlush.clear();
        }
    }
        
    public class ExLogException extends System.Exception { }

    /**
    * @author louis.wang@bluewolf.com
    * @date 2015-09-16
    * @description This function saves attachment of the type Text against a parent record
    * @param string
    * @param Id
    * @return Attachment
    **/
    private static Attachment saveAttachment(String inputBody, ID parentId)
    {        
        Attachment att;
        if(inputBody!=null && parentId!=null)
        {
            att = new Attachment();
            att.Body = Blob.valueOf(inputBody);
            att.Name = ATTACHMENT_FILE_NAME;
            att.ParentId = parentId; 
            att.ContentType = ATTACHMENT_CONTENT_TYPE;

            try
            {
                insert att;
            }
            catch(Exception ex)
            {
                // error out silently
                system.debug('@ExLog.saveAttachment error - ' + ex.getMessage());
                att = null;
            }
        }
        return att;
    }   

    /**
    * @description  Fetch custom setting based on custom setting name
    * @param string
    * @return Ex_Log_Config__c
    * @author louis.wang@bluewolf.com
    * @date 2015-09-17
    **/
    public static Ex_Log_Config__c fetch_Config(String configName)
    {
        Ex_Log_Config__c output;
        if(configName!=null)
        {
        	// custom setting is case sensitive, so use only lower case
        	configName = configName.toLowerCase();
        	output = Ex_Log_Config__c.getInstance(configName); // ensure custom setting is lower case
        }
        if(output==null)
        {
        	// default a generic config, if it does not exist
        	output = new Ex_Log_Config__c();
        	output.Flushable__c = false;
        	output.Logging_Level__c = string.valueOf(Level.LOW);
        	output.Owner_Id__c = '00590000002BFcD'; // Integrator user, exists in all environment
        }

        return output;
    } 

	/**
    * @description  Check if UserId exists
    * @param string
    * @return boolean
    * @author louis.wang@bluewolf.com
    * @date 2015-09-17
    **/
    private static boolean isUserValid(String userId)
    {
     	boolean output = false;
     	if(userId!=null)
     	{
     		list<User> userList = [SELECT Id FROM User WHERE Id =: userId];
     		if(userList.size()==1)
     		{
     			output = true;
     		}
     	}         
     	return output;
    }

    /**
    * @author louis.wang@bluewolf.com
    * @date 2015-09-16
    * @description This function update attachment and Exception_Log__c with OwnerId from custom setting
    * @param Attachment
    * @param List<Exception_Log__c>
    * @return n/a
    **/
    private static void update_OwnerIds(Attachment att, List<Exception_Log__c> exLogList)
    {
        if(isUserValid(config.Owner_Id__c))
        {
            try
            {
                if(att!=null)
                {
                    // set owner to the config one, as Logged_Exception is in private sharing model
                    att.OwnerId = config.Owner_Id__c;
                    update att;
                }

                for(Exception_Log__c elog : exLogList)
                {
                    // set owner to the config one, as Logged_Exception is in private sharing model
                    elog.OwnerId = config.Owner_Id__c;
                }
                update exLogList;
            }
            catch(Exception ex)
            {
                // error out silently
                system.debug('@ExLog.update_OwnerIds error - ' + ex.getMessage());
            }
        }
    }
}