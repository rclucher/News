/**---------------------------------------------------------
 * Author: Kristijan Kosutic & Alistair Borley
 * Company: CloudSense
 * Description:
 * Trigger to roll up key attributes from the Product Configuration to the Basket level
 * Utalises a Field Set on the Product Configuration Object to determine what Fields to total and update on the Basket
 * Field names must match on the two objects
   ---------------------------------------------------------*/
trigger CS_AllProductBasketTriggers on cscfga__Product_Basket__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	//Code that used Configuration_to_Basket_mapping field set has been removed as it is replaced by
	//ObjectFieldUpdateMappingHandler call in CS_ProductConfigurationTrigger

	//NR-1930 Margin process replaced by object field mapping approach, focusing only on after events
	if (Trigger.isAfter) {
		ObjectFieldUpdateMappingHandler mappingHandler = new ObjectFieldUpdateMappingHandler(null);
		//execute all active mapping configurations for our source object
		mappingHandler.execute();
	}
}