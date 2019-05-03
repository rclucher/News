/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	Service Methods for the GeoNames web service
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Sep 18		Mike Jupp			Created
------------------------------------------------------------*/
public class CS_GeoNames_Utilities implements CS_Questionnaire_Interface
{
	/***********************************************************************************************************
		Request and response
	***********************************************************************************************************/
	// Make the request and response visible to test classes
	@testVisible private HttpRequest HttpRequest;
	@testVisible private HttpResponse HttpResponse;

	/***********************************************************************************************************
		Internal classes
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Interface wrapper classes
	@testVisible private class postalCodeWrapper
	{
		@testVisible private list<postalCodeData>		postalcodes;
		
		@testVisible private postalCodeWrapper()
		{
			postalcodes = new list<postalCodeData>();
		}
	}
	
	@testVisible private class postalCodeData
	{
		private string		countryCode;
		@testVisible private string		postalCode;
		private string		adminName1;
		private string		adminName2;
		private string		adminCode1;
		@testVisible private string		placeName;
		private string		distance;
		private string		lat;
		private string		lng;
	}

	/***********************************************************************************************************
		Interface method
	***********************************************************************************************************/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Interface method
    ------------------------------------------------------------*/
	public CS_Interface_Utilities.Response process(CS_Interface_Utilities.Request req)
	{
		if (req == null)
			return CS_Interface_Utilities.returnError('Missing Request');

		if (string.isBlank(req.methodName))
			return CS_Interface_Utilities.returnError('No method name provided');

		// Convert method name to lowercase
		string methodName = req.methodName.toLowerCase();

		CS_Interface_Utilities.Response res = new CS_Interface_Utilities.Response();

		try
		{
			if (methodName == 'findnearbypostalcodes')
			{
				res = findNearbyPostalCodes(req);
			}
			else
			{
				res.success = false;
				res.messages.add('Method ' + methodName + ' not found');
			}
		}
		catch (exception e)
		{
			// Return an error back to the caller
			res.success = false;
			res.messages.add(e.getMessage());
		}

		return res;
	}


	/***********************************************************************************************************
		Service Methods
	***********************************************************************************************************/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Return postal codes within a specified radius of a given postcode
	Inputs:			postcode	- string		- required
					radius		- integer		- required
					country		- string		- optional. One of AU or NZ
	Outputs:		postcodes	- long text
					placeNames	- long text
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	Oct 18		Mike Jupp			Added the optional country parameter
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private CS_Interface_Utilities.Response findNearbyPostalCodes(CS_Interface_Utilities.Request req)
	{
		CS_Interface_Utilities.Response res = new CS_Interface_Utilities.Response();
		
		if (req.map_Values == null || req.map_Values.isEmpty())
			return CS_Interface_Utilities.returnError('No input parameters provided');

		if (!req.map_Values.containsKey('postcode') || !req.map_Values.containsKey('radius'))
			return CS_Interface_Utilities.returnError('One or more of these required parameters is missing: postcode, radius');

		string postcode = req.map_Values.get('postcode');
		string radius = req.map_Values.get('radius');

		// Check we have values
		if (string.isBlank(postcode))
			return CS_Interface_Utilities.returnError('No value provided for postcode');

		if (string.isBlank(radius))
			return CS_Interface_Utilities.returnError('No value provided for radius');

		if (radius == '0')
			return CS_Interface_Utilities.returnError('No value provided for radius');

		// We now have everything we need to make the webservice call
		
		// Get custom metadata
		CS_Integration_Settings__mdt mdtCSIntegrationSettings =	[	select	QualifiedApiName,
																			Country_Code__c,
																			Endpoint__c,
																			MaxRows__c,
																			Method_Name__c,
																			UserId__c
																	from	CS_Integration_Settings__mdt
																	where	QualifiedApiName = 'GeoNames_findNearbyPostalCodes'
																];

		// Look for a Country Code, if not provided use the default from metadata
		string countryCode = mdtCSIntegrationSettings.Country_Code__c;
		
		if (req.map_Values.containsKey('country') && !string.isBlank(req.map_Values.get('country')))
		{
			countryCode = req.map_Values.get('country');
		}

		HttpRequest = new HttpRequest();
		string strURL = mdtCSIntegrationSettings.Endpoint__c +
						mdtCSIntegrationSettings.Method_Name__c +
						'?postalcode=' +
						postcode + 
						'&country=' +
						countryCode +
						'&radius=' +
						radius + 
						'&maxRows=' +
						mdtCSIntegrationSettings.MaxRows__c +
						'&username=' +
						mdtCSIntegrationSettings.UserId__c;
		
		HttpRequest.setMethod('GET');
		HttpRequest.setEndpoint(strURL);

		Http http = new Http();
		HttpResponse = http.send(HttpRequest);
		
		// Check all good
		if (HttpResponse.getStatusCode() != 200)
		{
			return CS_Interface_Utilities.returnError('Callout error: code ' + HttpResponse.getStatusCode() + ' Error message: ' + HttpResponse.getStatus());
        }
		
		// Unpack the response
		try
		{
			postalCodeWrapper postalCodeWrapper = (postalCodeWrapper)JSON.deserialize(HttpResponse.getBody(), postalCodeWrapper.class);
			
			set<string> set_Postcodes = new set<string>();
			string postCodes;

			set<string> set_PlaceNames = new set<string>();
			string placeNames;
			
			for (postalCodeData postalCodeData : postalCodeWrapper.postalcodes)
			{
				system.debug('*** postalCodeWrapper ***' + postalCodeWrapper);
				
				// Apply a filter to exclude private bags / post bags
				/*
				State/Territory	Abbreviation	LVRs and PO Box Postcode range
				New South Wales					1000—1999
				Australian Capital Territory	0200—0299
				Victoria						8000—8999
				Queensland						9000—9999
				South Australia					5800—5999
				Western Australia				6800—6999
				Tasmania						7800—7999
				Northern Territory				0900—0999
				*/
				if (countryCode == 'AU')
				{
					integer iPostalCode = integer.valueOf(postalCodeData.postalCode);
					
					if (postalCodeData.postalCode.startsWith('1') ||	// NSW
						(iPostalCode > 199 && iPostalCode < 300) ||		// ACT
						postalCodeData.postalCode.startsWith('8') ||	// VIC
						postalCodeData.postalCode.startsWith('9') ||	// QLD
						(iPostalCode > 5799 && iPostalCode < 6000) ||	// SA
						(iPostalCode > 6799 && iPostalCode < 7000) ||	// WA
						(iPostalCode > 7799 && iPostalCode < 8000) ||	// TAS
						(iPostalCode > 899 && iPostalCode < 1000))		// NT
						continue;
				}
				
				set_Postcodes.add(postalCodeData.postalCode);
				set_PlaceNames.add(postalCodeData.placeName);
			}
			
			// Postal codes
			list<string> li_Postcodes = new list<string>(set_Postcodes);
			li_Postcodes.sort();
	
			for (string postalcode : li_Postcodes)
			{
				// List of post code, one per line
				postCodes	= postCodes == null
							? postalcode
							: postCodes + '\n' + postalcode;
			}

			// Place names
			list<string> li_Placenames = new list<string>(set_PlaceNames);
			li_Placenames.sort();
	
			for (string placename : li_Placenames)
			{
				// List of post code, one per line
				placeNames	= placeNames == null
							? placename
							: placeNames + '\n' + placename;
			}
			
			// Prepare the response
			res.map_Values.put('postcodes', postCodes);
			res.map_Values.put('placenames', placeNames);
		}
		catch(exception e)
		{
			// We didn't get any postcodes back
			return CS_Interface_Utilities.returnError('No postcodes returned. Message from GeoNames is: ' + HttpResponse.getBody());
		}

		return res;
	}

}