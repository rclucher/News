@isTest (seeAllData=false)
private class ExLog_Test 
{
    // 2015-09-17 louis.wang@bluewolf.com
    //    This class provides test coverage for 
    //      - ExLog         94%

    private static final String THIS_CLASS_NAME = 'ExLog_Test';
    private static final String CLASS_QUAL_NAME = 'Class.' + THIS_CLASS_NAME;
    
    private static final String NULL_EX_TYPE =  'System.NullPointerException';
    private static final String DML_EX_TYPE =   'System.DmlException';

    /////////////////////////////////////////////////////////////////
    //              Unit Tests
    /////////////////////////////////////////////////////////////////



    /////////////////////////////////////////////////////////////////
    //              "End to End" Tests
    /////////////////////////////////////////////////////////////////
    
    
    private static testMethod void testClassResolutionOnLowLevel() 
    {       
        setup();        

        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {           
            Test.startTest();
            
                try 
                {                   
                    nullPointerException();
                
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, 'configlow', (sObject)null, null );
                }               

                try 
                {
                    dmlException();             
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, 'config', (sObject)null, null );
                }               
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id, Type__c, Class_Name__c, Class_Id__c FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            Id thisClassesId = [ SELECT Id FROM ApexClass WHERE Name = :THIS_CLASS_NAME ].Id;
            
            System.assertEquals( 2, resolvedExceptions.size(), 'Logged Exception not properly created.' );

            Boolean foundClasslessDml = false;

            for ( Exception_Log__c aLoggedEx : resolvedExceptions ) 
            {
                
                if ( aLoggedEx.Type__c == DML_EX_TYPE ) 
                {
                    
                    foundClasslessDml = true;
                    System.assertEquals( CLASS_QUAL_NAME, aLoggedEx.Class_Name__c, 'Class Name should be populated when Exception Log Level is set to High' );
                    System.assertEquals( thisClassesId, aLoggedEx.Class_Id__c, 'Class ID should be populated when Exception Log Level is set to High' );
                } 
                else 
                {
                    System.assertEquals( null, aLoggedEx.Class_Name__c, 'Class Name should not be populated when Exception Log Level is set lower than High' );
                    System.assertEquals( null, aLoggedEx.Class_Id__c, 'Class ID should not be populated when Exception Log Level is set lower than High' );                 
                }
                
            }
            System.assert( foundClasslessDml, 'Logged DML Exception with Class info not found' );
        }
        
    }

    private static testMethod void testSingleDmlException() 
    {
        setup();                
        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {
            Test.startTest();
                Account acct = new Account();
                try 
                {
                    insert acct;
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, 'config', acct, 'check if account is valid.' );
                }
                    
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id, Type__c FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            System.assertEquals( 1, resolvedExceptions.size(), 'Logged Exception not properly created.' );
            System.assertEquals( DML_EX_TYPE, resolvedExceptions[0].Type__c, 'Logged Exception of incorrect type.' );           
        }
    }

    private static testMethod void testDmlException_inList() 
    {
        setup();                
        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {
            Test.startTest();
                List<Account> aList = new List<Account>();
                Account acct = new Account();
                aList.add(acct);

                try 
                {
                    insert aList;
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, 'config', aList, 'check if list of account is valid.' );
                }
                    
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id, Type__c FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            System.assertEquals( 1, resolvedExceptions.size(), 'Logged Exception not properly created.' );
            System.assertEquals( DML_EX_TYPE, resolvedExceptions[0].Type__c, 'Logged Exception of incorrect type.' );           
        }
    }   
    private static testMethod void testSingleNullException() 
    {
        setup();                
        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {
            Test.startTest();
            
                try 
                {
                    nullPointerException();
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, 'config', (sObject)null, null );
                }
                    
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id, Type__c FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            System.assertEquals( 1, resolvedExceptions.size(), 'Logged Exception not properly created.' );
            System.assertEquals( NULL_EX_TYPE, resolvedExceptions[0].Type__c, 'Logged Exception of incorrect type.' );
        }
    }
    
    private static testMethod void testFlushableNullExceptionLogs() 
    {
        setup();  
        list<Ex_Log_Config__c> configList = [SELECT ID FROM Ex_Log_Config__c];       
        System.assertEquals(3, configList.size());

        Integer numOfExceptions = 10;
        
        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {           
            Test.startTest();
            
                for ( Integer cnt = 0; cnt < numOfExceptions; cnt++ ) 
                {
                    try 
                    {
                        nullPointerException();
                    } 
                    catch( System.Exception ex ) 
                    {
                        ExLog.log( ex, 'configflush', (sObject)null, null   );
                    }
                }   
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            System.assertEquals( 0, resolvedExceptions.size(), 'Logged Exceptions incorrectly committed to database before calling the flushLogCache method' );
            
            ExLog.flushLogCache();
            
            resolvedExceptions = [ SELECT Id FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];

            System.assertEquals( numOfExceptions, resolvedExceptions.size(), 'Incorrect number of Logged Exceptions found after calling the flushLogCache method' );
            
        }
    }

    private static testMethod void defaultCustomSettingTest() 
    {
        setup();                
        System.runAs( createUser( 't3ts', getSystemAdministratorProfileId(), true ) ) 
        {
            Test.startTest();
            
                try 
                {
                    nullPointerException();
                } 
                catch( System.Exception ex ) 
                {
                    ExLog.log( ex, null, (sObject)null, null );
                }
                    
            Test.stopTest();
            
            List<Exception_Log__c> resolvedExceptions = [ SELECT Id, Type__c FROM Exception_Log__c WHERE CreatedById = :UserInfo.getUserId() ];
            
            System.assertEquals( 1, resolvedExceptions.size(), 'Logged Exception not properly created.' );
            System.assertEquals( NULL_EX_TYPE, resolvedExceptions[0].Type__c, 'Logged Exception of incorrect type.' );
        }
    }    

    /////////////////////////////////////////////////////////////////
    //              Error-generating helper methods
    /////////////////////////////////////////////////////////////////
    
    private static void nullPointerException() 
    {
        String testString;
        Boolean testBool = testString.startsWith( 'text' );
    }
    
    private static void dmlException() 
    {
        update new Account();
    }
    
    /////////////////////////////////////////////////////////////////
    //              test data helper methods
    /////////////////////////////////////////////////////////////////
    
    private static User ADMIN_USER 
    {
        get 
        {
            if ( ADMIN_USER == null )
            {
                ADMIN_USER = [SELECT Id FROM User WHERE Profile.Name ='System Administrator' AND isActive = true LIMIT 1];
            }
            return ADMIN_USER;
        }
    }
    
    private static Id getSystemAdministratorProfileId() 
    {
        return [SELECT Id FROM Profile WHERE Name ='System Administrator' LIMIT 1].Id;
    } 
    
    private static User createUser ( String uname, Id profileId,  Boolean willInsert ) 
    {
            User testUser = new User();
            testUser.LastName = uname ;
            testUser.Alias = uname;
            testUser.Email = uname +'@test.com';
            testUser.Username = uname +'@test.com';
            testUser.CommunityNickname = 'atest'+ uname;
            testUser.TimeZoneSidKey = 'America/New_York';
            testUser.LocaleSidKey = 'en_US';
            testUser.EmailEncodingKey = 'ISO-8859-1';
            testUser.ProfileId = profileId;
            testUser.LanguageLocaleKey = 'en_US';
            testUser.IsActive = true;

            if ( willInsert ) {
                System.runAs( ADMIN_USER ){
                    insert testUser;
                }
            }
        return testUser;
    }
    
    private static void setup()
    {
        Ex_Log_Config__c config = new Ex_Log_Config__c();
        config.Name = 'config';
        config.Flushable__c = false;
        config.Logging_Level__c = string.valueOf(ExLog.Level.HIGH);
        config.Owner_Id__c = '00590000002BFcD'; // Integrator user, exists in all environment
        config.Key_Person_to_Notify__c = 'test@test.com';
        insert config;

        Ex_Log_Config__c configLow = new Ex_Log_Config__c();
        configLow.Name = 'configlow';
        configLow.Flushable__c = false;
        configLow.Logging_Level__c = string.valueOf(ExLog.Level.LOW);
        configLow.Owner_Id__c = '00590000002BFcD'; // Integrator user, exists in all environment
        configLow.Key_Person_to_Notify__c = 'test@test.com';
        insert configLow;       

        Ex_Log_Config__c configFlush = new Ex_Log_Config__c();
        configFlush.Name = 'configflush';
        configFlush.Flushable__c = true;
        configFlush.Logging_Level__c = string.valueOf(ExLog.Level.HIGH);
        configFlush.Owner_Id__c = '00590000002BFcD'; // Integrator user, exists in all environment
        configFlush.Key_Person_to_Notify__c = 'test@test.com';
        insert configFlush;     

    }
    
}