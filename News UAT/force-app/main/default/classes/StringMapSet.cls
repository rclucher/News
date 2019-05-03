/*
* 07-09-2018: Mohsin Ali
* Description: Commenting Method public Set<String> get(String key) after discussion with Sandhaya. This method didn't had any code coverage and was not used anywhere.
*/
public class StringMapSet {
	public Map<String, Set<String>> keySetMap = new Map<String, Set<String>>();
    
    public void add(String key, String value) {
        Set<String> values = keySetMap.get(key);
        
        if (values == null) {
            values = new Set<String>();
            
            keySetMap.put(key, values);
        }
        
        values.add(value);
    }
    
/*    public Set<String> get(String key) {
        Set<String> values = keySetMap.get(key);
        
        if (values == null) return new Set<String>();
        
        return values;
    }
*/
    
    public Set<String> keySet() {
        return keySetMap.keySet();
    }
}