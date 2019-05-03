/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-06-05
* @description  This class contains methods that are used for Credit Card Number scrubbing
* 2016-03-17  Darshan G   Updated
*/
public without sharing class CCN_Helper 
{
    public CCN_Helper() {}  
    public class ccnException extends Exception {}

    /*
        This regular expression can detect 4 major brand of credit cards, with specific pattern as below,
            - American Express: 3711-078176-01234  |  371107817601234  |  3711 078176 01234
            - Visa: 4123-5123-6123-7123  |  4123512361237123  |  4123 5123 6123 7123
            - Master Card: 5123-4123-6123-7123  |  5123412361237123  |  5123 4123 6123 7123
            - Discover: 6011-0009-9013-9424  |  6500000000000002  |  6011 0009 9013 9424 
        Note - if it is not spaced in the convention way as above(eg.American Express: 3711-0781-7601-234), then it will not be detected.
    */
    private static final String REG_EX = '\\b((?<!\\=)(?<!\\/))((?:(?:4\\d{3})|(?:5[1-5]\\d{2})|6(?:011|5[0-9]{2}))(?:-?|\\040?)(?:\\d{4}(?:-?|\\040?)){3}|(?:3[4,7]\\d{2})(?:-?|\\040?)\\d{6}(?:-?|\\040?)\\d{5})\\b';
    private static final Pattern PATTERN_COMPILED = Pattern.compile(REG_EX);
    private static final String MASK_SYMBOL = '*';
    private static final Integer MASK_CHAR_NO_LEADING = 4;
    private static final Integer MASK_CHAR_NO_ENDING = 3;
    private static final String LAST_MODIFIED_DAYS = '10';
    private static final String ATTACHMENT_FILE_NAME = 'CCN_Detected_RecordIds.html';
    private static final String ATTACHMENT_CONTENT_TYPE = 'html';
    private static final Integer CASE_CREATED_N_DAYS_RANGE_STARTS = -28;
    private static final Integer CASE_CREATED_N_DAYS_RANGE_ENDS = -7;
    
    public static String LAST_SUCCESS_SETTING;       

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-05 
    * @description This function detects whether Credit Card Number pattern is contained in the string
    * @param string
    * @return boolean
    **/
    public static boolean detectCCN(string inString)
    {
        boolean output = false;
        // validate the passed in variables
        if (inString!=null && inString.length()>0) 
        {          
            Matcher m = PATTERN_COMPILED.matcher(inString);
            if(m.find())
            {
                // if regular expression is matched then mark it as detected, and exit for loop
                output = true;
            }
        }
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-05 
    * @description This function mask Credit Card Number if found the input string
    * @param string
    * @return string
    **/
    public static String maskCCN(String inString)
    {
        String output = inString;
        // validate the passed in variables
        if (inString!=null && inString.length()>0) 
        {          
            Matcher m = PATTERN_COMPILED.matcher(inString);
            // in case there are multiple findings of credit card number
            while(m.find()) 
            {
                // find the start and end indexes of the match
                integer startIdx = m.start();
                integer endIdx = m.end();

                // extract the matched string
                string patternMatch = inString.substring(startIdx, endIdx);

                // mask the string leaving any visible characters
                string partToBeMasked = patternMatch.substring(MASK_CHAR_NO_LEADING, patternMatch.length()-MASK_CHAR_NO_ENDING);
                
                // setup mask string
                string mask = '';                                          
                for(integer i = 0; i < partToBeMasked.length(); i++) 
                {
                    mask += MASK_SYMBOL;
                }    

                // concatenate mask string with the last visible characters               
                string maskedNumber = patternMatch.substring(0, MASK_CHAR_NO_LEADING) 
                                        + mask 
                                        + patternMatch.substring(patternMatch.length()-MASK_CHAR_NO_ENDING);

                // replace the the card number with masked number
                inString = inString.replace(patternMatch, maskedNumber);
            }
            output = inString;
        }
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function checks whether batchType is InitialRun
    * @param string
    * @return boolean
    **/
    public static Boolean convert_BatchType(String batchType)
    {
        boolean output = false;
        if(batchType=='InitialRun')
        {
            output = true;
        }
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function checks whether batchMode is Update
    * @param string
    * @return boolean
    **/
    public static Boolean convert_BatchMode(String batchMode)
    {
        boolean output = false;
        if(batchMode=='Update')
        {
            output = true;
        }
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function converts Month String to SOQL acceptable format
    * @param string eg. 2015-01
    * @param boolean
    * @return string eg. 2015-01-01T00:00:00.000Z or null
    **/
    public static string convert_DateString_Long(String monthString, Boolean isEndMonth)
    {
        string output;
        if(monthString!=null && monthString.Length()==7)
        {
            monthString = calc_DateString_Short(monthString);
            string sDay = '01';
            string sTime = '00:00:00.000Z';
            if(isEndMonth)
            {
                sDay = calc_Last_Day_Short(monthString);
                sTime = '23:59:59.999Z';
            }
            
            
            output = monthString + '-'+sDay+'T'+sTime;
        }
        return output;
    }


    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function converts SOQL format back to simple string (7 char)
    * @param string eg. 2015-01-01T00:00:00.000Z 
    * @return string eg. 2015-01
    **/
    public static string convert_DateString_Short(String dateString)
    {
        string output;
        if(dateString!=null && dateString.length()==24)
        {
            output = dateString.mid(0,7);
        }
        return output;
    }

    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function calculates date short format by minus 1 month
    * @param string eg. 2015-01
    * @return string eg. 2014-12
    **/
    public static string calc_DateString_MinusOneMonth_Short(String monthString)
    {
        string output;
        if(monthString!=null && monthString.length()==7)
        {
    
             Date previousMonth = convert_Date_From_Short(monthString).addMonths(-1);

            output = formatShortDate(previousMonth);
        }
        return output;
    }

    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function calculates date short format 
    * @param string eg. 2015-01
    * @return string eg. 2014-12
    **/
    private static string calc_DateString_Short(String monthString)
    {
        string output;
        if(monthString!=null && monthString.length()==7)
        {
    
            Date currentDate = convert_Date_From_Short(monthString);

            output = formatShortDate(currentDate);
        }
        return output;
    }

    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function calculates the last day of the month from a short format 
    * @param string eg. 2015-01
    * @return string eg. 31
    **/
    private static string calc_Last_Day_Short(String monthString)
    {
        Date d = convert_Date_From_Short(monthString);
        return String.valueOf(Date.daysInMonth(d.year(), d.month()));
    }


    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function convert the date of the month from a short format 
    * @param string eg. 2015-01
    * @return Date eg. 2015-01-01
    **/
    public static Date convert_Date_From_Short(String monthString)
    {
        Integer currentMonth = integer.valueOf(monthString.mid(5,2));
        Integer currentYear = integer.valueOf(monthString.mid(0,4));
        return Date.newInstance(currentYear, currentMonth, 1);
    }    


    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09
    * @description This function gets a date and return a minified string representing year - month
    * @param date eg. 2015-01-31
    * @return string eg. 2015-01
    **/
    private static String formatShortDate(Date d)
    {
        String sMonth =  d.month()>=10?String.valueOf(d.month()):'0'+String.valueOf(d.month());
        return d.year() + '-' + sMonth;    
    }



    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function checks whether all inputs are in valid format
    * @param string
    * @param string
    * @param string
    * @param string 
    * @return boolean
    **/
    public static Boolean check_Inputs(String startMonthString, String endMonthString, String batchType, String batchMode)
    {
        Boolean output = startMonthString!=null &&  endMonthString!=null;//true;
        //NEED TO UPDATE;       
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-09 
    * @description This function generates SOQL
    * @param string
    * @param string
    * @param string
    * @param string 
    * @param string 
    * @param DateTime     
    * @return String
    **/
    public static String convert_SOQL(String startDateString, String endDateString, Boolean isInitialRun, String sObjectType, String sObjectField, DateTime lastRunTime)
    {
        String output;
        String selectString = 'SELECT Id, ' + sObjectField + ' ';
        String fromString = 'FROM ' + sObjectType + ' ';
        String whereString;
        String orderByString;
               
        if(isInitialRun)
        {
            whereString = 'WHERE CreatedDate >= ' + startDateString + ' ' + 'AND CreatedDate <= ' + endDateString + ' '; 
            orderByString = 'ORDER BY CreatedDate DESC ';
        }
        else
        {
            // set lastRunTime to be 1 day earlier, to compensate for any potential missed out records
            lastRunTime = lastRunTime.addDays(-1);
            String lastRunTimeString = convert_DatetimeToString(lastRunTime);
            // Date for 1 week ago
            DateTime weekAgo = System.Now().addDays(CASE_CREATED_N_DAYS_RANGE_ENDS);
            String weekAgoString = convert_DatetimeToString(weekAgo); 
            // Date for 4 week ago
            DateTime fourWeekAgo = System.Now().addDays(CASE_CREATED_N_DAYS_RANGE_STARTS);
            String fourWeekAgoString = convert_DatetimeToString(fourWeekAgo);
                            
            if(sObjectType=='Case')
            {
                // only remove CCN for closed Case or Case older than 7 days
                whereString = 'WHERE (IsClosed = true AND SystemModStamp >= ' + lastRunTimeString + ') '; 
                whereString += 'OR (IsClosed=false AND CreatedDate < ' + weekAgoString + ' AND CreatedDate > ' + fourWeekAgoString + ') ';

                /*
                // sample
                    WHERE (IsClosed = true AND SystemModStamp >= 2015-09-01T00:00:00.000Z)
                    OR (IsClosed = false AND CreatedDate < 2015-09-04T00:00:00.000Z  AND CreatedDate > 2015-08-11T00:00:00.000Z)
                */            
            }
            else if(sObjectType=='EmailMessage'){

                // Item-00031 2016-03-17 darshan.gosar@bluewolfgroup.com 
                    // Updated filter condition for EmailMessage scrubing to process only EmailMessage of closed Case or Case older than 7 days                                 
                string existingBatchUserList = fetch_filterRecrodIds(LAST_SUCCESS_SETTING);
                // only remove CCN for closed Case or Case older than 7 days
                whereString = 'WHERE ((Parent.IsClosed = true AND Parent.SystemModStamp >= ' + lastRunTimeString + ') '; 
                whereString += 'OR (Parent.IsClosed=false AND Parent.CreatedDate < ' + weekAgoString + ' AND Parent.CreatedDate > ' + fourWeekAgoString + ')) ';
                
                if(existingBatchUserList != '')
                    whereString += 'AND CreatedById Not In ' + existingBatchUserList;
                    
                /*
                // sample
                    WHERE ((Parent.IsClosed = true AND Parent.SystemModStamp >= 2016-03-17T16:40:47.000Z)
                     OR (Parent.IsClosed=false AND Parent.CreatedDate < 2016-03-11T21:29:10.000Z AND Parent.CreatedDate > 2016-02-19T21:29:10.000Z))
                     AND CreatedById Not In ('00590000001S9fyAAC','005O00000033rQGIAY') ORDER BY SystemModStamp DESC
                */                     
            }
            else
            {
                // LastModifiedDate greater than last run time
                whereString = 'WHERE SystemModStamp >= ' + lastRunTimeString + ' '; 
            }
            orderByString = ' ORDER BY SystemModStamp DESC ';            
        }
        output = selectString + fromString + whereString + orderByString;
        system.debug('@@convert_SOQL = ' + output);
        return output;
    }

    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function create and insert a log record 
    * @param ...
    **/
    public static General_Batch_Log__c createLogRecord( String startDateLong,
                                                        String endDateLong,
                                                        String batchType,
                                                        String batchMode,
                                                        String inSObject,
                                                        Integer ccnDetected,
                                                        Integer numberOfRecords,
                                                        boolean hasError,
                                                        String errorMessage,
                                                        String batchJobNo
                                                        )
    {
        General_Batch_Log__c gbl;
        try
        {
            Date startDate;
            Date endDate;
            if(batchType=='InitialRun')
            {
                startDate = Date.valueOf(startDateLong);
                endDate = Date.valueOf(endDateLong);
            }

            gbl = new General_Batch_Log__c(    Start_Date__c = startDate,
                                                End_Date__c = endDate,
                                                Batch_Type__c = batchType,
                                                Batch_Mode__c = batchMode,
                                                sObject__c = inSObject,
                                                CCN_Detected__c = ccnDetected,
                                                Number_of_Records__c = numberOfRecords,
                                                Has_Error__c = hasError,
                                                Error_Message__c = errorMessage,
                                                Batch_Job_No__c = batchJobNo    );

            System.debug(String.format('@CCN General_Batch_Log 1 => startDate:{0}, endDate:{1},batchType:{2},batchMode:{3},inSobject:{4},ccnDetected:{5}', 
                                    new LIST<String>{string.valueOf(startDate),string.valueOf(endDate),batchType,batchMode,inSobject,string.valueOf(ccnDetected)}));
            System.debug(String.format('@CCN General_Batch_Log 2 => numberOfRecords:{0},hasError:{1},errorMessage:{2},batchJobNo:{3}', 
                                    new LIST<String>{string.valueOf(numberOfRecords),string.valueOf(hasError),errorMessage,batchJobNo}));

            insert gbl;

        }
        catch(Exception ex)
        {
            // update exception object
            system.debug('@CCN General_Batch_Log save error - ' + ex.getMessage());
        }

        return gbl;
    }  

    /**
    * @author Celso de Souza (celso.desouza@bluewolf.com)
    * @date 2015-06-09 
    * @description This function date an attachment of the type Text against a parent record
    * @param ...
    **/
    public static void saveAttachment(List<Id> idList, ID parentId)
    {
        String sBody = convert_BodyFormat(idList);
        if(sBody!='')
        {
            Attachment attachment = new Attachment();
            attachment.Body = Blob.valueOf(sBody);
            attachment.Name = ATTACHMENT_FILE_NAME;
            attachment.ParentId = parentId; 
            attachment.ContentType = ATTACHMENT_CONTENT_TYPE;
            try
            {
                insert attachment;
            }
            catch(Exception ex)
            {
                // update exception object
                system.debug('@CCN Attachment save error - ' + ex.getMessage());
            }
        }
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-06-16
    * @description This function converts list of Id into a hyperlink format
    * @param list<Id>
    * @return string
    **/
    public static String convert_BodyFormat(List<Id> idList)
    {
        String output = '';
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        if(idList!=null && !idList.IsEmpty())
        {
            integer counter = 1;
            for(Id detectedId : idList)
            {
                // Excel / CSV format
                //output += '=HYPERLINK("' + baseUrl + '/' + detectedId + '")' + '\n';              
                // HTML format
                output += '<a href="' + baseUrl + '/' + detectedId + '">Detection ' + counter + '</a><br/>';
                counter++;
            }
        }
        return output;
    }   


    /**
    * @author   Mohamed Atheek mohamed.atheek@bluewolf.com
    *            Daniel garzon daniel.garzon@bluewolf.com
    * @date 2015-07-06
    * @description Clones a EmailMessage record and adds a message at the top of the body
    * @param EmailMessage
    * @return EmailMessage
    **/
    public Static EmailMessage cloneEMsg(EmailMessage em, String emailMsg)
    {
        EmailMessage clonedEm = em.clone(false, true);

        if(String.isNotBlank(clonedEm.HtmlBody))
        {
            clonedEm.HtmlBody = CCN_Helper.maskCCN(em.HtmlBody);
            
            Integer lenOfModifiedMessage = (clonedEm.HtmlBody + '<p>' + emailMsg + '</p>').length();
            
            if (lenOfModifiedMessage < 32000) { 
                integer strtTag, endTag;
                strtTag = clonedEm.HtmlBody.indexOf('<body');
                if(strtTag<0)
                {
                    strtTag = clonedEm.HtmlBody.indexOf('<p');
                }
    
                endTag = clonedEm.HtmlBody.indexOf('>',strtTag);
                clonedEm.HtmlBody = clonedEm.HtmlBody.substring(0,endTag) + '<p>' + emailMsg + '</p>' + clonedEm.HtmlBody.substring(endTag+1);
            } 
        }

        if(String.isNotBlank(clonedEm.textBody))
        {
            clonedEm.textBody = CCN_Helper.maskCCN(clonedEm.textBody);
            
            Integer lenOfModifiedMessage = (emailMsg + '\n' + clonedEm.textBody).length();
            
            if (lenOfModifiedMessage < 32000) { 
                clonedEm.textBody = emailMsg + '\n' +  clonedEm.textBody;
            }
        }

        return clonedEm;
    }

    /**
    * @author   Daniel garzon daniel.garzon@bluewolf.com
    * @date 2015-07-010
    * @description Update custom setting flag, to by pass trigger and workflow rule
    * @param boolean
    * @param String 
    * @param String
    * @return N/A
    **/
    public Static void update_CustomSetting(boolean isRunning, String externalId, String sObjectType)
    {        
        CCNBatchJobSetting__c batchSetting =  new CCNBatchJobSetting__c();
        if(sObjectType=='Case')
        {
            batchSetting.Is_Case_Batch_Running__c = isRunning;
        }
        else if(sObjectType=='Task')
        {
            batchSetting.Is_Task_Batch_Running__c = isRunning;
        }
        if(sObjectType=='EmailMessage')
        {
            batchSetting.Is_EmailMessage_Batch_Running__c = isRunning;
        }
        batchSetting.SetupOwnerId = UserInfo.getUserId();
        batchSetting.External_Id__c = externalId;
        upsert batchSetting External_Id__c;     
    } 

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-09-10
    * @description This function fetches "Run_Start_Datetime" field from corresponding custom setting
    * @param string
    * @return DateTime
    **/
    public static Datetime fetch_LastUpdatedStamp(String settingName)
    {
        Datetime output = null;
        if(settingName!=null)
        {
            Batch_Run_Start_Datetime__c bat = Batch_Run_Start_Datetime__c.getInstance(settingName);
            if(bat!=null)
            {
                output = bat.Run_Start_Datetime__c;
            }
        }
        return output;
    }

    /**
    * @author Darshan Gosar (darshan.gosar@bluewolfgroup.com)
    * @date 2016-03-17
    * @description This function fetches "Filters__c" field from corresponding custom setting & converts comma sepeated user id's into string. Added as part of Item-00031
    * @param string
    * @return string format ('Record Id 1', 'Record Id 2')
    **/                
    public static string fetch_filterRecrodIds(String settingName)
    {
        string output = '';
        if(settingName!=null)
        {
            Batch_Run_Start_Datetime__c bat = Batch_Run_Start_Datetime__c.getInstance(settingName);
            if(bat!=null)
            {
                String filterString = bat.Filters__c;
                if(filterString != '' && filterString != null)
                {
                    String[] arrTest = filterString.split(',');                                       
                    for(Integer i=0 ; i<arrTest.size(); i++)
                    {
                        if(i == 0)
                            output = '(\'' + arrTest[i] + '\'';
                        else
                            output += ',\'' + arrTest[i] + '\'';                                
                    }
                    
                    if(output != '')
                        output += ')'; 
                }
                
            }
        }
        return output;
    }

    /**
    * @author Darshan Gosar (darshan.gosar@bluewolfgroup.com)
    * @date 2016-03-17
    * @description This function updates Filters__c" field from corresponding custom setting & adds batch running user if its not present. Added as part of Item-00031
    * @param string
    * @return none
    **/
    public static void update_FilterRecordId(String settingName)
    {
        if(settingName!=null)
        {
            Batch_Run_Start_Datetime__c bat = Batch_Run_Start_Datetime__c.getInstance(settingName);
            if(bat!=null)
            {
                String filterString = bat.Filters__c;
                if(!filterString.contains(UserInfo.getUserId()))
                {                   
                    filterString += ',' + UserInfo.getUserId();
                    
                    // Check is added as there is character limit of 255 on custom setting field. If its exceed then previous record id is removed following first in first out approach
                    if(filterString.length() >= 255)                    
                        filterString = filterString.split(',',2)[1];
                                            
                    bat.Filters__c = filterString;
                    update bat;
                }                    
            }
        }
    }
    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-09-10
    * @description This function convert the datetime to SOQL acceptable format
    * @param DateTime
    * @return String
    **/
    public static String convert_DatetimeToString(DateTime toConvert)
    {
        String output = '';
        if(toConvert!=null)
        {
            output = String.valueOf(toConvert);
            // conert "2015-09-10 14:56:00" to "2015-09-10T14:56:00.000Z"
            output = output.mid(0,10) + 'T' + output.mid(11,8) + '.000Z';
        }
        return output;
    }

    /**
    * @author Louis Wang (louis.wang@bluewolf.com)
    * @date 2015-09-14
    * @description This function update "Run_Start_Datetime" field to current time
    * @param string
    * @return N/A
    **/
    public static void update_SuccessTimestamp(String settingName)
    {
        if(settingName!=null)
        {
            Batch_Run_Start_Datetime__c bat = Batch_Run_Start_Datetime__c.getInstance(settingName);
            if(bat!=null)
            {
                bat.Run_Start_Datetime__c = System.Now();
                update bat;
            }
        }
    }
}