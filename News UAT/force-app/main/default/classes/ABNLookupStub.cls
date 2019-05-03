/*---------------------------------------------------------
Author: Celso de Souza
Company: Salesforce.com
description: Stub for ABR ABN lookup web service
History:
20/05/2013  Celso de Souza  Created
---------------------------------------------------------*/
public without sharing class ABNLookupStub {

    //ABR web service address
    static final string  ADDRESS = 'http://abr.business.gov.au/abrxmlsearch/ABRXMLSearch.asmx';

    //GUID is set on the custom setting System Parameters
    //Registration for a new GUID can be done through http://abr.business.gov.au/RegisterAgreement.aspx
    static public string GUID
    {
        get
        {
            String tmpGUID = 'Invalid ABR GUID';
            if(SystemParameters__c.getAll().get('ABR_GUID')!=null)
            {
                tmpGUID = SystemParameters__c.getAll().get('ABR_GUID').value__c;
            }

            return tmpGUID;

        }
    }

    //Makes a HTTP GET callout to ABR webservices
    //@Method = name of the method to be called
    //@parameters = map of querystrings to be appeded to the address
    static public HTTPResponse callOut(String Method, map<String,String> parameters)
    {

        HTTPRequest req = new HttpRequest();

        //appends GUID to request URL
        String URL = ADDRESS + '/' + Method + '?authenticationGUID=' + GUID;

        //Append each parameter passed to URL
        for(String k:parameters.keySet())
        {
            URL+='&' + k + '=' + parameters.get(k);
        }

        //Sets the end point of the HTTP callout with querystring appended
        req.setEndpoint(URL);

        //Sets HTTP request method to GET
        req.setMethod('GET');

        // Updated by Bohao Chen on 13/May/2014 for JIRA SFE-242
        // using try catch to display any callout exception error messages
        try
        {
            //Makes the callout
            HTTP http = new Http();
            HTTPResponse res = http.send(req);
    
            //If the request is successfull return HTTP respose , if not returns null
            Integer statusCode = res.getStatusCode();
            
            if(statusCode == 200)
            {
                return res;
            }
            else
            {
                String msg = 'Unable to get validation result. Status code is ' + statusCode + '. Please contact your administrator.';
                System.debug('@Exception: ' + msg);
                throw new AbnException(msg);
            }
        }
        catch(System.Exception e) {
            System.debug('@Exception ERROR:' + e);
            throw new AbnException(e.getMessage());
        }

        return null;
        // Update ends
    }


    //gets AustralianBusinessNumber passing an ABN number
    //@ABN = ABN number
    static public AustralianBusinessNumber ABRSearchByABN(String ABN)
    {
        //call overloaded mehotd setting history as N (No)
        try
        {
            return ABRSearchByABN(ABN, 'N');
        }
        catch(System.Exception e) {
            System.debug('@Exception:' + e);
            throw new AbnException(e.getMessage());
        }
    }

    //overloaded method to get AustralianBusinessNumber passing an ABN number and if to include Historical Details
    //@ABN = ABN number
    //@history = Y to include Historical Details
    static public AustralianBusinessNumber ABRSearchByABN(String ABN, String history)
    {
        //map of querystring required for call out
        map<String,String> params = new map<String,String>();
        params.put('includeHistoricalDetails', history);
        params.put('searchString', ABN);

        //Get HTTP response
        // Updated by Bohao Chen on 13/May/2014 for JIRA SFE-242
        // using try catch to display any callout exception error messages
        try
        {
            HTTPResponse res = callOut('ABRSearchByABN', params);
            
            //Parses the body if HTTP response is not null, else return null
            return res!=null?parseABNResponse(res.getBody()):null;
        } 
        catch(System.Exception e) {
            System.debug('@Exception:' + e);
            throw new AbnException(e.getMessage());
        }
        
        return null;        
    }

    //XML parser Start
    static private AustralianBusinessNumber parseABNResponse(string strXML)
    {
        system.debug('### strXML:' + strXML);
        Dom.Document doc = new Dom.Document();
        doc.load(strXML);
        Dom.XMLNode root = doc.getRootElement();
        //system.debug('### root:' + root);
        AustralianBusinessNumber ABN = new AustralianBusinessNumber();
        ABN = parserWalkThrough(root,ABN);
        system.debug('### ABN:' + ABN);
        return ABN;
    }

    static private AustralianBusinessNumber parserWalkThrough(DOM.XMLNode node, AustralianBusinessNumber ABN)
    {

        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            //Only processes the nodes that are required for AustralianBusinessNumber object
            if (node.getText().trim() != '')
            {
                if(node.getName() == 'identifierValue')
                {
                    ABN.ABN = node.getText();
                }              
                else if(node.getName() == 'organisationName' && !String.isNotBlank(ABN.name))
                {
    
                    ABN.name = node.getText();

                }
                else if(node.getName() == 'entityStatusCode')
                {
                    ABN.isActive = (node.getText()=='Active');
                    ABN.status = node.getText();
                }
                else if(node.getName() == 'exceptionCode')
                {
                    ABN.isInvalid = true;
                }
            }
            
      		/**
            * SFE-480 - ABN Validation Returning SOLE TRADE as Name for sole traders
            * Modified by: LMancilla
            * May 19 2014
            * BwB
            * Parse <legalName> tag for sole traders in order to get the correct name
            * Legal Name composed of given name and family name elements
            **/
            if(node.getName()=='legalName'){
            	//Given name + Other given Name + Family Name 
            	ABN.name = node.getChildElements()[0].getText()+' '+node.getChildElements()[1].getText()+' '+node.getChildElements()[2].getText();
            }             
			
            for (Dom.XMLNode child: node.getChildElements()) {
              parserWalkThrough(child, ABN);
            }
            
            /**Moved as last step given that we are also parsing the <legalName> for sole traders**/ 
                   
            // to truncate abn organisation name to 255 characters if size of 
            // register name is over 255 characters             
            if(String.isNotBlank(ABN.name) && ABN.name.split('').size() > 256)
            {
                ABN.name = ABN.name.substring(0, 255);
            }   
            /**End CHange LMancilla **/
                  
            return ABN;
        }

        return null;  //should never reach here
    }
    //XML parser END

    //AustralianBusinessNumber is a representation of the required data from the callout response
    public class AustralianBusinessNumber
    {
        public String ABN {get;set;}
        public String name {get;set;} //organisationName
        public Boolean isActive {get;set;}
        public Boolean isInvalid {get;set;}
        public String Status {get;set;}
    }

    // Updated by Bohao Chen on 13/May/2014 for JIRA SFE-242
    public class AbnException extends Exception{}
}