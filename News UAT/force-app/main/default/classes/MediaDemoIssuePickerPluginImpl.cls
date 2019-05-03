global with sharing class MediaDemoIssuePickerPluginImpl implements csmso.SalesOrderAPI.IssuePickerPlugin {
        /**
            The return string, formatted as JSON, should take the form of two properties that define the columns (Id is assumed to always be present) the list of items that map to those columns:\n
            {"colDefinition": [
                {"label": "Issue Date", "key": "issueDate"},
                {"label": "Issue Name", "key": "name"},
                {"label": "Close Date", "key": "closeDate"},
                {"label": "Comments", "key": "comments"}
                ],
            "listItems": [
                {"Id": "1", "issueDate": "01/12/2015", "closeDate": "01/12/2015", "name": "New year, new you", "comments": "Exciting discounts inside"},
                {"Id": "2", "issueDate": "01/01/2016", "closeDate": "01/12/2015", "name": "Spring in your step", "comments": "Season's best picks inside"}
                ],
            "attributeMap": {"Id": "Issue_Number_0", "issueDate": "Date_Range_0"}
            }
        **/ 
        global String getIssuesJSON(String productNodeCode) {
            String result = '{"colDefinition": [' + 
                                '{"label": "Issue Date", "key": "issueDate"},' + 
                                '{"label": "Issue Name", "key": "name"},' + 
                                '{"label": "Close Date", "key": "closeDate"}' +
                            '], "listItems": [';

            Boolean first = true;
            /*for (Issue__c issue : [Select Id,
                                          Name,
                                          Close_Date__c,
                                          Publication_Date__c
                                   FROM   Issue__c 
                                    WHERE Product_Node__c = :productNodeCode 
                                      AND Close_Date__c >= :System.today()
                                 ORDER BY Close_Date__c]) {
                if (!first){
                    result += ',';
                }
                result += '{"Id": "' + issue.Id + '", "issueDate": "' + displayDateValue(issue.Publication_Date__c) + '", "name": "' + issue.Name + '", "closeDate": "' + displayDateValue(issue.Close_Date__C) + '"}';
                first = false;
            }*/

            result += '], "attributeMap": {"Id": "Issue_Number_0", "issueDate": "Date_Range_0"} }';
            System.debug('getIssuesJSON().result = \n' + result);

            return result;
        }

    	@testVisible
        private String displayValue(String source){
            return (source == null) ? ' ' : source  ;
        }

    	@testVisible
        private String displayDateValue(Date source){
            String parsedDateString = null;
            if (source != null){
                parsedDateString = source.format();
            }
            return displayValue(parsedDateString);
        }
}