public with sharing class CS_ProductMappingMetadataUtil {
	static List<Map_Orchestrator_Process__mdt> productMappingMetadataList = new List<Map_Orchestrator_Process__mdt>();
	static Map<String, String> productIdentifierToRTMap = new Map<String, String>();
	static Map<String, Set<String>> rtToOrchProcessesMap = new Map<String, Set<String>>();
	static Map<String, Map<String, Set<String>>> rtandTypeToOrchProcessesMap = new Map<String, Map<String, Set<String>>>();

	public CS_ProductMappingMetadataUtil() {
		getAllData();
		mapProductLineToRecordTypeLabel();
		mapRecordTypeLabelToOrchProcesses();
	}

	private static void getAllData() {
		if(productMappingMetadataList == null || productMappingMetadataList.size() == 0){
			productMappingMetadataList = [SELECT 	Id, 
													MasterLabel, 
													Orchestrator_Process_Template_s__c, 
													Key_Process_Identifier__c,
													Product_Type__c
											FROM 	Map_Orchestrator_Process__mdt];
		}
	}

	private static void mapProductLineToRecordTypeLabel () {
		for (Map_Orchestrator_Process__mdt singlerecord : ProductMappingMetadataList)
			productIdentifierToRTMap.put (singlerecord.MasterLabel, singlerecord.Key_Process_Identifier__c);
	}

	private static void mapRecordTypeLabelToOrchProcesses () {
		for (Map_Orchestrator_Process__mdt singlerecord : ProductMappingMetadataList) {
			
			Set<String> orchProcesses = new Set<String>();
			if (singlerecord.Orchestrator_Process_Template_s__c.contains(','))
				orchProcesses.addAll(singlerecord.Orchestrator_Process_Template_s__c.split(','));
			else
				orchProcesses.add(singlerecord.Orchestrator_Process_Template_s__c);
			rtToOrchProcessesMap.put (singlerecord.Key_Process_Identifier__c, orchProcesses);
			Map<String, Set<String>> typeProcessesMap = rtandTypeToOrchProcessesMap.get(singlerecord.Key_Process_Identifier__c);
			if (typeProcessesMap == null) {
				typeProcessesMap = new Map<String, Set<String>>();
			}
			typeProcessesMap.put (singlerecord.Product_Type__c, orchProcesses);
			rtandTypeToOrchProcessesMap.put (singlerecord.Key_Process_Identifier__c, typeProcessesMap);
		}

		system.debug(rtToOrchProcessesMap.get('Campaign Setup'));
	}

	public String getRTForProductIdentifier (String productIdentifier) {
		return productIdentifierToRTMap.get(productIdentifier);
	}

	public Set<String> getOrchProcessesNamesForLabel (String processIdentifier) {
		return rtToOrchProcessesMap.get(processIdentifier);
	}

	public Set<String> getOrchProcessesNamesForLabelAndType (String processIdentifier, String productType) {
		return rtandTypeToOrchProcessesMap.get(processIdentifier).get(productType);
	}


}