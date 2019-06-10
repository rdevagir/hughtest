/*****************************************************************************************
Name              : GRAXUtils
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       	07/03/2018             
2. Leandro Brunner       	07/31/2018          David Mackey        Too many fields/too much to query errors (https://app.asana.com/0/326600806074978/763054542504017/f)
3. Leandro Brunner       	08/07/2018          David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
4. Leandro Brunner       	10/05/2018          David Mackey        APEX Governor Limit Warning (https://app.asana.com/0/326600806074978/849081244540524/f)
5. Leandro Brunner       	11/06/2018          David Mackey        Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
6. Ariel Yankelevich     	02/20/2019          David Mackey        GRAX "XF" Fields (https://app.asana.com/0/326600806074978/1110592656396265/f)
7. Leandro Brunner       	03/08/2019          David Mackey        New Issues (https://app.asana.com/0/326600806074978/1112342626420899/f)
8. Ariel Yankelevich     	04/26/2019          David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
9. Ariel Yankelevich	 	05/06/2019			David Mackey		503 Errors (https://app.asana.com/0/326600806074978/1121362448820852/f)
10. Ariel Yankelevich		05/13/2019			David Mackey		Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
11. Ariel Yankelevich		05/20/2019			David Mackey		Tele2 Items (https://app.asana.com/0/326600806074978/1123380863374618/f)
12. Ariel Yankelevich     	05/24/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
13. Leandro Brunner         05/31/2019          David Mackey        Date Format should be based on user locale (https://app.asana.com/0/326600806074978/1125157851523067/f)
14. Ariel Yankelevich     	06/03/2019          David Mackey        Paylocity - Heap Size (https://app.asana.com/0/326600806074978/1125518618824327/f)
******************************************************************************************/
public with sharing class GRAXUtils {
    private static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Schema.DescribeSObjectResult> objectsFullDescribe {get; set;}
    private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldsDescribeByObject;

    public static Boolean sObjectExists( String objName ){
        if(globalDescribe == null){ 
            globalDescribe = Schema.getGlobalDescribe();
        }
        
        return globalDescribe.containsKey( objName );
    }

    private static void loadObjectAndFieldsDescribe(String objName){
        if(fieldsDescribeByObject == null){ 
            globalDescribe                          = Schema.getGlobalDescribe();
            objectsFullDescribe                     = new Map<String, Schema.DescribeSObjectResult>();
            fieldsDescribeByObject                  = new Map<String, Map<String, Schema.DescribeFieldResult>>();
        }
        
        /*System.debug(objName);
        System.debug(fieldsDescribeByObject.containsKey(objName));
        System.debug(sObjectExists(objName));*/
        
        if(!fieldsDescribeByObject.containsKey(objName) && sObjectExists(objName) ){
            Schema.DescribeSObjectResult objDesc = globalDescribe.get(objName).getDescribe();
            objectsFullDescribe.put(objDesc.getName(), objDesc);
            Map<String, Schema.DescribeFieldResult> fieldsDescribe = new Map<String, Schema.DescribeFieldResult>();
            
            // Get the describe of each field of the object
            for(Schema.SObjectField sField: objDesc.fields.getMap().values()){
                Schema.DescribeFieldResult fldDescRes = sField.getDescribe();
                fieldsDescribe.put(fldDescRes.getName(), fldDescRes);                    
            }
            fieldsDescribeByObject.put(objDesc.getName(), fieldsDescribe);
        } 
    }

    public static Schema.DescribeSObjectResult getObjectDescribe(String objName){
        loadObjectAndFieldsDescribe(objName);
        
        return objectsFullDescribe.get(objName);
    }

    public static Map<String, Schema.DescribeFieldResult> getDescribeFieldsResultForObject(String objName){
        loadObjectAndFieldsDescribe(objName);
        
        return fieldsDescribeByObject.get(objName);
    }

    public static Schema.DescribeFieldResult getFieldDescribeFromSObjectField(Schema.SObjectField sObjFld){
        return sObjFld.getDescribe();
    }

    private static Map<String, Schema.DescribeFieldResult> nameFieldDescVsObjectNameMap = new Map<String, Schema.DescribeFieldResult>();

    public static Schema.DescribeFieldResult getNameFieldDescForObject(String objName){             
        if(nameFieldDescVsObjectNameMap.containsKey(objName)) {
            return nameFieldDescVsObjectNameMap.get(objName);
        }

        Schema.DescribeFieldResult result;
        
        if( sObjectExists(objName) ){
            // Get the Name field defined for each object
            for(Schema.DescribeFieldResult fieldDesc : getDescribeFieldsResultForObject(objName).values()){
                if(fieldDesc.isNameField()){
                    result = fieldDesc;
                    break;
                }
            }
        }

        nameFieldDescVsObjectNameMap.put(objName, result);
        
        return result;
    }   

    public static String getObjectNameFromSObjectType(Schema.SObjectType sObjT){
        String objName = '';
        
        if(globalDescribe == null){ 
            globalDescribe = Schema.getGlobalDescribe();
        }
            
        for(Schema.SObjectType objSObjType : globalDescribe.values()){
            if(sObjT == objSObjType){
                objName = sObjT.getDescribe().getName();
                break;
            }
        }
        
        return objName;
    }

    public static SObject createObjectInstance(String objName, Id recordId, Boolean loadDefaultValues){
        if(globalDescribe == null){ 
            globalDescribe = Schema.getGlobalDescribe();
        }
        
        SObject result = globalDescribe.get(objName).newSObject(recordId);
        
        if(loadDefaultValues){
            result = globalDescribe.get(objName).newSObject(recordId, true);
        }
        
        return result;
    }

    public static String CleanFieldLabel(Schema.DescribeFieldResult sField, Boolean escapeForVF){
        String fieldLabel = sField.getLabel();
        
        if(!sField.isCustom() && sField.getType().name() == 'REFERENCE' && fieldLabel.endsWith(' ID')){
            fieldLabel = fieldLabel.removeEnd(' ID');
        } 
        
        if(escapeForVF){
            fieldLabel = fieldLabel.escapeHtml4();
        }
        
        return fieldLabel;
    }

    public static List<String> polymorphicDefaultIncludedObjects = new List<String>{'Task', 'Event', 'Attachment', 'Note'};
    public static List<String> polymorphicDefaultIncludedFields = new List<String>{'OwnerId', 'LastModifiedId', 'CreatedById'};

    public static Boolean isPolymorphicAvailableToGetReference(String objName, Schema.DescribeFieldResult fieldDesc) {
        loadObjectAndFieldsDescribe(objName);

        if(!polymorphicDefaultIncludedObjects.contains(objName) && !polymorphicDefaultIncludedFields.contains(fieldDesc.name)) {
            return false;
        }

        return true;
    }

    public static String getReferenceField(String objName, Schema.DescribeFieldResult fieldDesc) {
        loadObjectAndFieldsDescribe(objName);

        // Check if this field is accessible for the current User
        if(fieldDesc <> null) {
            
            // If the current field is a reference field, get the Name field of the related object to be used in the search
            if(fieldDesc.getType().name().equalsIgnoreCase('REFERENCE')) {

                String nameField = 'Name';

                if(fieldDesc.getReferenceTo().size() == 1) {
                    nameField = '';
            
                    // Get the Name field defined for this related object
                    String relObjName = getObjectNameFromSObjectType(fieldDesc.getReferenceTo()[0]);
                    Schema.DescribeSObjectResult relObjDescribe = getObjectDescribe(relObjName);
            
                    // Get the Name field of the related object
                    Schema.DescribeFieldResult relNameFieldDesc = getNameFieldDescForObject(relObjName);
            
                    if(relObjDescribe <> null && relNameFieldDesc<>null){    
                        nameField = relNameFieldDesc.getName();
                    }
                } else if(!isPolymorphicAvailableToGetReference(objName, fieldDesc)) {
                    nameField = '';
                }

                String relationName = fieldDesc.getRelationshipName();

                if(String.isNotBlank(relationName) && nameField <> '') {
                    return relationName + '.' + nameField;
                }
            }
            
        }

        return null;
    }

    public static List<String> getReferenceFields(String objName) {
        loadObjectAndFieldsDescribe(objName);

        List<String> referenceFields = new List<String>();

        Map<String, Schema.DescribeFieldResult> fieldsDesc = fieldsDescribeByObject.get(objName);

        if(fieldsDesc == null) return referenceFields;

        for(String fieldName : fieldsDesc.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldsDesc.get(fieldName);

            String referenceField = getReferenceField(objName, fieldDesc);

            if(referenceField <> null) {
                referenceFields.add(referenceField);
            }
        }

        return referenceFields;
    }

    public static List<String> getGraxFields(String objName) {
        List<String> graxFields = new List<String>();

        if(objName == null) return graxFields;

        for(String refField: getReferenceFields(objName)) {
            graxFields.add(getGraxFieldFromReference(refField));
        }

        return graxFields;
    }

    public static String getGraxFieldFromReference(String refField) {
        if(refField <> null) {
            return 'grax_' + String.valueOf(refField).replaceAll('\\.', '_');
        }

        return null;
    }
    
    public static Map<String, String> getReferenceFieldsMap(String objName) {
    	Map<String,String> result = new Map<String,String>();

        if(fieldsDescribeByObject <> null && objName <> null) {
            Map<String, Schema.DescribeFieldResult> fieldsDesc = fieldsDescribeByObject.get(objName);

            for(String fieldName : fieldsDesc.keySet()) {
                Schema.DescribeFieldResult fieldDesc = fieldsDesc.get(fieldName);
                
                // If the current field is a reference field add it to the Map
                if(fieldDesc.getType().name().equalsIgnoreCase('REFERENCE')){
                    result.put(fieldDesc.getName(), String.valueOf(fieldDesc.getReferenceTo()).replace('(','').replace(')',''));
                }
            }
        }
        
        return result;
    }

    public static Object parseSObjectFieldValue(SObject sobj, String refField){
        Object fieldValue;

        // Split the field by '.' and traverse the object relationship
        List<String> objFields = refField.split('\\.');
        SObject dynObj = sobj;
        for(Integer i = 0; i < objFields.size() - 1; i++){
            if(dynObj <> null){
                dynObj = dynObj.getSObject(objFields[i]);
            }
        }
        
        // Get the Field Name to retrieve
        String relatedObjField = objFields[objFields.size()-1];
        
        // Retrieve the value of the field
        if(dynObj <> null){
            fieldValue = dynObj.get(relatedObjField);
        }
        
        return fieldValue;
    }

    // Description: Cast the value passing by parameter to the specified Field Type. 
    public static Object castGenericObjectToType(Object objValue, String fieldType){ 
        Object result = objValue;
        
        if(objValue <> null){
            String obj = String.valueOf(objValue);
            
            if(String.isBlank(obj)){
                result = null;
            }else{
                if((new Set<String>{'time', 'datetime', 'date'}).contains(fieldType.toLowerCase())){
                    if(fieldType.equalsIgnoreCase('time')){
                        // The assumption is that TIME values will be in this format '16:45:47.000Z'
                        // Add the time portion to it, so it is treated as a Datetime
                        obj = '2000-01-01T' + obj;
                    }
                    
                    if( obj.length() > 19 && obj.contains('T')){
                        //Bad format 2016-07-29T16:45:47.000Z . Reformat to 2016-07-29 16:45:47
                        obj = obj.replace('T', ' ').subString(0, 19);
                    }
                    
                    if(fieldType.equalsIgnoreCase('datetime') || fieldType.equalsIgnoreCase('time')){
                        if( obj.contains('/') ){
                            //MONTH/DAY/YEAR
                            result = (Object)Datetime.parse(obj);
                        }else{
                            //YEAR-MONTH-DAY
                            result = (Object)Datetime.valueOfGMT(obj);
                        }
                    }else if(fieldType.equalsIgnoreCase('date')){
                        if( obj.contains('/') ){
                            //MONTH/DAY/YEAR
                            result = (Object)Date.parse(obj);
                        }else{
                            //YEAR-MONTH-DAY
                            result = (Object)Date.valueOf(obj);
                        }
                    }
                    
                    if(fieldType.equalsIgnoreCase('time')){
                        // This value was already transformed to a Datetime, extract the Time portion of it
                        result = (Object)(((Datetime)result).timeGMT());
                    }
                }else if(fieldType.equalsIgnoreCase('boolean')){
                    result = (Object)Boolean.valueOf(obj);
                }else if(fieldType.equalsIgnoreCase('integer')){
                    result = (Object)Integer.valueOf(obj);
                }else if(fieldType.equalsIgnoreCase('double') || fieldType.equalsIgnoreCase('currency') || fieldType.equalsIgnoreCase('percent')){
                    result = (Object)Double.valueOf(obj);
                }else if(fieldType.equalsIgnoreCase('decimal')){
                    result = (Object)Decimal.valueOf(obj);
                }else{                      
                    result = obj;
                }
            }
        }
               
        return result;
    }

    private static GRAXSettings__c gs;

    public static GRAXSettings__c getGRAXSettings() {
        if(gs == null) {
            gs = GRAXSettings__c.getOrgDefaults();
        }

        return gs;
    }
    
    public static Integer getMaxNumberOfParentsOnHierarchyBackup(String sobjectName) {
    	Integer result = 50000;
    	
    	//GRAXSettings__c graxSet = getGRAXSettings();
		//if(graxSet <> null && graxSet.MaxNumberOfParentsOnHierarchyBackup__c <> null){
		//	result = (Integer)graxSet.MaxNumberOfParentsOnHierarchyBackup__c;
		//}
		
		// Calculate how much Heap Size can be used to maximize the number of parent Ids to process at once based on the total estimated for the JSON Payload
		Integer numOfRecsPerExecution = getBatchMaxExecutionNumber(sobjectName);
		Decimal totalBytesPerRec = getObjectMaxTotalBytesInJSON(sobjectName);
		Integer maxBytes = 10695475; // 10.2 MB
		
		// Get a factor (2.66666) the number of Total Bytes that the JSON for each record * # Total Batch records, and see how much left bytes there are to get to 10 MB
		// Divide the result by 8 bytes, which is how much is needed to store each Id
		Decimal maxAvailableBytesForParentIds = maxBytes - (totalBytesPerRec * numOfRecsPerExecution * 8/3);
		if(maxAvailableBytesForParentIds > 524288){ // 0.5 MB
			result = (Integer)Math.ceil(maxAvailableBytesForParentIds / 8);
		}
		
		return result;
    }

    public static void setBatchMaxExecutionNumber(Integer newValue) {
        gs.BatchMaxExecutionNumber__c = newValue;

        upsert gs;
    }

    public static Integer getBatchMaxExecutionNumber() {
    	return 500;
    }
    
	
	private static Map<String, Decimal> objectMaxTotalBytesInJSONBySObjectName = new Map<String, Decimal>(); 
	
    public static Decimal getObjectMaxTotalBytesInJSON(String sobjectName) {
        if(!objectMaxTotalBytesInJSONBySObjectName.containsKey(sobjectName)){
	        Map<String, Schema.DescribeFieldResult> fieldsMap = getDescribeFieldsResultForObject(sobjectName);
	        
	        Decimal estimatedPercentageOfDataInARecord = 0.75;
	        
	        if(fieldsMap.size() > 500){
	            estimatedPercentageOfDataInARecord = 0.25;
	        }else if(fieldsMap.size() > 400){
	            estimatedPercentageOfDataInARecord = 0.5;
	        }else if(fieldsMap.size() > 250){
	            estimatedPercentageOfDataInARecord = 0.6;
	        }
	        
	        Set<String> excludedFieldTypes = new Set<String>{'base64'};
	        
	        Decimal defaultFieldTypeUsagePercentage = 1.0; 
	        Map<String, Double> aproxUsagePercentageByFieldType = new Map<String, Double>{
	            'textarea' => 0.3,
	            'string' => 0.8,
	            'email' => 0.8,
	            'phone' => 0.8,
	            'picklist' => 0.8,
	            'multipicklist' => 0.8,
	            'url' => 0.8,
				'currency' => 0.4,
	            'percent' => 0.4,
	            'double' => 0.4,
	            'int' => 0.4
	        };
	        Set<String> numberFieldTypes = new Set<String>{'currency','percent','double','int'};
	        Integer totalNumericFields = 0;
	        
	        Decimal totalBytes = 85 + 2 * sobjectName.length(); // These numbers refer to the JSON keys added to the String when it is serialized from a query result (eg: "attributes":{"url":"/services/data/v43.0/sobjects/ANZ_Market_Share_Aggregate__c/a4r1o000002HxUdAAK","type":"ANZ_Market_Share_Aggregate__c"})
	        
	        for(Schema.DescribeFieldResult dfr: fieldsMap.values()) {
	            String typeName = dfr.getType().name().toLowerCase();
	            
	            if(!excludedFieldTypes.contains(typeName)){
	                Double fieldTypeUsagePercentage = defaultFieldTypeUsagePercentage;
	                if(aproxUsagePercentageByFieldType.containsKey(typeName)){
	                    fieldTypeUsagePercentage = aproxUsagePercentageByFieldType.get(typeName);
	                }
	            
	                Integer byteLength = dfr.getByteLength();
					if(numberFieldTypes.contains(typeName)){
						byteLength = dfr.getPrecision() + dfr.getScale();
					}
	            
	                totalBytes += (byteLength * fieldTypeUsagePercentage) + dfr.getName().length() + 6;
	                
	                // If the field is of type "Reference" add the Bytes corresponding to the "GRAX_Name" field added to the JSON
	                if(typeName == 'reference'){
	                	totalBytes += (30) + dfr.getName().length() + 10 + 6;
	                }
	                
	                // Calculate the total number of Numeric fields
	                if(numberFieldTypes.contains(typeName)){
	                    totalNumericFields += 1;
	                }
	            }
	        }
	        
	        // If the total number of Numeric fields on this object is more than 50% of the total number fields, we are assuming this object is used as aggegation object
	        // We set the total size of the record to be 80% of the total number of bytes
	        Decimal percentageOfNumericFields = totalNumericFields / (Decimal)fieldsMap.size();
	        
	        if(percentageOfNumericFields > 0.5){
	            estimatedPercentageOfDataInARecord = 0.8;
	        }
	        
	        objectMaxTotalBytesInJSONBySObjectName.put(sobjectName, Math.ceil(totalBytes * estimatedPercentageOfDataInARecord));
        }

        return objectMaxTotalBytesInJSONBySObjectName.get(sobjectName);
    }

    public static Integer getBatchMaxExecutionNumber(String sobjectName) {    
        List<Integer> batchExecutionSizeList = new List<Integer>{1, 2, 5, 10, 20, 25, 50, 100, 200, 400, 500, 1000, 2000};
        Integer maxBytes = 5242880;
        Integer maxExecutionNumber = 2000; 
        
        // If there is a value in the field "MaxNumberOfRecordsPerPayload__c" in the GRAX Settings, use it as the maximum number of SFDC Records that will be included in a JSON Payload
        GRAXSettings__c graxSet = getGRAXSettings();
		if(graxSet <> null && graxSet.MaxNumberOfRecordsPerPayload__c <> null){
			maxExecutionNumber = (Integer)graxSet.MaxNumberOfRecordsPerPayload__c;
		}
		
        Integer executionNumber = maxExecutionNumber;

        Decimal totalBytes = getObjectMaxTotalBytesInJSON(sobjectName);

        executionNumber = (Integer)Math.ceil(maxBytes / totalBytes);
        executionNumber = Math.min(executionNumber, maxExecutionNumber);
        
        // Iterate through the list of possible batch execution sizes and return the closest value less than the estimated
        for(Integer i = 1; i < batchExecutionSizeList.size(); i++){
            if(executionNumber < batchExecutionSizeList[i]){
                executionNumber = batchExecutionSizeList[i-1];
                break;
            }
        }
        
        return executionNumber;
    }

    public static void setSelectionJSON(Id gspId, String jsonContent) {
        setSelectionJSON(gspId, jsonContent, 'SelectionJSON.txt');
    }

    public static void setSelectionJSON(Id gspId, String jsonContent, String name) {
        setSelectionJSON(new Attachment(
            ParentId = gspId,
            Name = name
        ), jsonContent);
    }

    public static void setSelectionJSON(Attachment att, String jsonContent) {
        if(att <> null) {
            att.Body = Blob.valueOf(jsonContent);
            
            upsert att;
        }
    }

    public static String getSelectionJSON(Id gspId) {
        return getSelectionJSON(getSelectionAttachment(gspId));
    }

    public static String getSelectionJSON(Attachment att) {
        return getSelectionJSON(att, '{}');
    }

    public static String getSelectionJSON(Attachment att, String defaultValue) {
        String retJSON = defaultValue;

        if(att <> null) {
            try {
                retJSON = att.Body.toString();
            } catch (Exception e) {
                retJSON = EncodingUtil.base64Encode(att.Body);
            }
        }

        return retJSON;
    }

    public static Attachment getSelectionAttachment(Id gspId, String name) {
        Attachment retAtt;

        for(Attachment att : [SELECT Body FROM Attachment WHERE ParentId = :gspId AND Name = :name ORDER BY Id DESC LIMIT 1]) {
            retAtt = att;
        }

        return retAtt;
    }

    public static Attachment getSelectionAttachment(Id gspId) {
        return getSelectionAttachment(gspId, 'SelectionJSON.txt');
    }

    public static Boolean idExist(String sid) {
        try {
            Id recordId = Id.valueOf(sid);
            
            String soql = 'SELECT count() FROM ' + recordId.getSObjectType() + ' WHERE Id = :recordId';
            
            return Database.countQuery(soql) == 1;
        } catch (Exception e) {}

        return false;
    }

    public static Boolean isPersonAccountEnabled() {
        return getDescribeFieldsResultForObject('Account').containsKey('IsPersonAccount');
    }

    public static String getPageParameter(Pagereference page, String paramName) {
        String paramValue;

        try {
            paramValue = page.getParameters().get(paramName);
        } catch(Exception e) {}

        return paramValue;
    }

    public static String getPageParameter(String paramName) {
        return getPageParameter(Apexpages.currentPage(), paramName);
    }

    public static SObject getSObjectById(Id sId) {
        String sObjectName = getSObjectNameById(sId);
        
        return getSObjectById(sId, sObjectName);
    }

    public static SObject getSObjectById(Id sId, String sObjectName) {
        loadObjectAndFieldsDescribe(sObjectName);

        String sObjectFields = String.join(new List<String>(getDescribeFieldsResultForObject(sObjectName).keySet()), ', ');

        return Database.query('SELECT ' + sObjectFields + ' FROM ' + sObjectName + ' WHERE Id = :sId LIMIT 1');
    }

    public static String getSObjectNameById(Id sId) {
        return sId.getSObjectType().getDescribe().getName();
    }

    public static List<List<Object>> splitList(List<Object> listToSplit, Integer chunkMax) {
        List<List<Object>> chunks = new List<List<Object>>();

        Integer lastIndex = listToSplit.size() - 1;

        Integer ci = 0;
        List<Object> chunk = new List<Object>();
        for (Integer f = 0; f <= lastIndex; f++) {
            chunk.add(listToSplit[f]);
            ci++;

            if(ci == chunkMax || f == lastIndex) {
                chunks.add(chunk);
                chunk = new List<Object>();
                ci = 0;
            }
        }

        return chunks;
    }

    public static String generate20UniqueKey() {
        return EncodingUtil.base64Encode(Crypto.generateAesKey(256)).right(20);
    }
    
    public static String generateRandomString(Integer len){
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String randStr = '';
		while (randStr.length() < len){
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			randStr += chars.substring(idx, idx+1);
		}
		
		return randStr;
	}

    private static String namespace;

    private static void loadNamespace() {
        if(namespace == null) {
            try { 
                if(String.valueOf(GRAXUtils.class).contains('.')){
                    namespace = String.valueOf(GRAXUtils.class).split('\\.', 2)[0];
                }
            } catch(Exception e) {
                namespace = '';
            }
        }
    }

    public static String getPureNameSpace(){
        loadNamespace();

        return namespace;
    }

    public static String getNameSpacePrefix() {
        loadNamespace();

        return String.isNotBlank(namespace) ? namespace + '__' : '';
    }

    public static String getPackageVersion() {
        if(getPureNameSpace() <> null) {
            System.Version v = System.requestVersion();
            String versionString = v.major() + '.' + v.minor();

            if (v.patch() <> null) {
                versionString += '.' + v.patch();
            }

            return versionString;
        }

        return null;
    }
    
    public static String getExternalAPIEndpoint(){
    	String result = '';
        
        for(Organization org : [SELECT InstanceName FROM Organization Limit 1]){
            if(org != null && org.InstanceName != null) {
                result = 'https://' + org.InstanceName.toLowerCase() + '.salesforce.com';
                break;
            }   
        }
        
        if(result == ''){
            String uid = UserInfo.getUserId();
            String sid = UserInfo.getSessionId();
            String oid = UserInfo.getOrganizationId();
            String base = Url.getSalesforceBaseUrl().toExternalForm();

            //use getSalesforceBaseUrl within batches and schedules (not Visualforce), and fix inconsistent protocol
            if (sid == null) return base.replaceFirst('http:', 'https:');

            //within test context use url class, else derive from identity response
            PageReference api = new PageReference('/id/' + oid + '/' + uid + '?access_token=' + sid);
            String content = Test.isRunningTest() ? '{"urls":{"profile":"' + base + '"}}' : api.getContent().toString();
            Url profile = new Url(content.substringBetween('"profile":"', '"'));
            result = profile.getProtocol() + '://' + profile.getHost();
        }
        
        return result;
    }


    private static Map<String, Map<String, Object>> recordFieldCache = new Map<String, Map<String, Object>>();
    
    public static void putRecordFieldCache(String sid, String field, Object value) {
        if(!recordFieldCache.containsKey(sid)) {
            recordFieldCache.put(sid, new Map<String, Object>());
        }

        recordFieldCache.get(sid).put(field, value);
    }

    public static Boolean existRecordFieldCache(String sid, String field) {
        return recordFieldCache.containsKey(sid) && recordFieldCache.get(sid).containsKey(field);
    }

    public static Object getRecordFieldCache(String sid, String field) {
        if(existRecordFieldCache(sid, field)) {
            return recordFieldCache.get(sid).get(field);
        }

        return null;
    }


    public static Boolean checkIfScheduleIsAborted(Id spId) {
        if(spId == null) {
            return false;
        }

        return Database.countQuery('SELECT count() FROM GRAX_Schedule_Process__c WHERE Id = \'' + spId + '\' AND Status__c = \'Aborted\' LIMIT 1') > 0;
    }


    /*public static String dateFormat = 'MM/dd/yyyy';
    public static String timeFormat = 'hh:mm a';
    public static String dateTimeFormat = dateFormat + ' ' + timeFormat;*/
    public static String dateFormat = null;
    public static String timeFormat = null;
    public static String dateTimeFormat = null;

    // Create new Date intance from a date string with the format 31/12/2018
    public static Date createDate(String dateStr) {
        List<String> dParts = dateStr.split('/');
        Integer y = Integer.valueOf(dParts.get(2));
        Integer m = Integer.valueOf(dParts.get(0));
        Integer d = Integer.valueOf(dParts.get(1));

        return Date.newInstance(y, m, d);
    }

    // Create new Datetime intance from a date string with the format 31/12/2018 and a time srtring with the format 23:00
    public static Datetime createDateTime(String dateStr, String time24) {
        Date d;

        Boolean isGMT = String.isBlank(time24);

        if(String.isNotBlank(dateStr)) {
            d = createDate(dateStr);
        } else {
            d = Date.today();
        }

        if(isGMT) {
            return DateTime.newInstanceGMT(d.year(), d.month(), d.day(), 12, 0, 0);
        }

        List<String> timeParts =  time24.split(':');
        Integer hh = Integer.valueOf(timeParts.get(0));
        Integer mm = Integer.valueOf(timeParts.get(1));

        return DateTime.newInstance(d.year(), d.month(), d.day(), hh, mm, 0);
    }

    // Format a Date to -> '07/18/2018'
    // or a Datetime -> '07/18/2018 09:52 AM' using the user timezone.
    public static String formatDateTime(Object o, String userTimeZone) {
        return formatDateTime(o, dateTimeFormat, userTimeZone);
    }

    public static String formatDateTime(Object o, String format, String userTimeZone) {
        Datetime dt;

        if(o instanceof DateTime) {
            dt = (Datetime)o;
        }

        if(o instanceof Date) {
            Date d = (Date)o;

            dt = Datetime.newInstance(d.year(), d.month(), d.day());
        }

        if(dt <> null) {
            return format <> null ? dt.format(format, userTimeZone) : dt.format();
        }

        return null;
    }

    public static String formatDate(Object o, String userTimeZone) {
        return formatDateTime(o, dateFormat, userTimeZone);
    }

    // Format a date/datetime from a String '2018-07-18' -> '07/18/2018'
    // or '2018-07-18T12:52:34.000+0000' -> '07/18/2018 ' -> '07/18/2018 09:52 AM' using the user timezone.
    public static String formatDateTimeString(String datetimeString, String userTimeZone) {
        return formatDateTimeString(datetimeString, dateTimeFormat, userTimeZone);
    }
    
    public static String formatDateTimeString(String datetimeString, String format, String userTimeZone) {
        if(datetimeString == null) return null;

        List<String> datetimeParts = datetimeString.split('[-T:.+]');

        if(datetimeParts.size() < 3) {
            return null;
        }

        Integer year = Integer.valueOf(datetimeParts[0]);
        Integer month = Integer.valueOf(datetimeParts[1]);
        Integer day = Integer.valueOf(datetimeParts[2]);

        if(datetimeParts.size() > 3) {
            Integer hour = Integer.valueOf(datetimeParts[3]);
            Integer minute = Integer.valueOf(datetimeParts[4]);
            Integer second = Integer.valueOf(datetimeParts[5]);

            return formatDateTime(Datetime.newInstanceGmt(year, month, day, hour, minute, second), format, userTimeZone);
        } else {
            return formatDateTime(Datetime.newInstance(year, month, day), format, userTimeZone);
        }
    }
    
    
	/*
    * BEGIN Base62 encode / decode code
    * This is used to convert salesforce Ids to Integers and back for chunking
    *
    * This code ported from python here: https://gist.github.com/adyliu/4494223
    */
    
    private static String basedigits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    
	public static Long base62decode(String s) {
		Long ret = 0;
		Long mult = 1;
		
		String[] chars = s.split('');
		
		String[] charsReversed = new List<String>();
		
		for(Integer i = chars.size()-1; i>=0; i--) {
	    	charsReversed.add(chars.get(i));
		}
		
		for (String c: charsReversed) {
			Integer index = basedigits.indexOf(c);
			system.assert(index > -1, 'bad character');
			ret += mult*index;
       		mult *= 62;
		}
		
		return ret;
	}    
    
    
	public static String base62encode(Long num) {
		system.assert(num >= 0, 'expected positive number');
		if (num == 0) {
			return '0';
		}

		List<String> retList = new List<String>();

		String[] basedigitsArr = basedigits.split('');

		while (num != 0) {
			Integer cIndex = (Integer)Math.Mod(num, 62);
			retList.add(basedigitsArr[cIndex]);
			num = (num/62);
		}
		
		List<String> retListReversed = new List<String>();
		for(Integer i = retList.size()-1; i>=0; i--) {
	    	retListReversed.add(retList.get(i));
		}	
			
		return String.join(retListReversed, '');
	}  
	
    /*
    * END Base62 encode / decode code
    */
    
    
    
    
    /*
    * Take a 15 or 18 digit start and ending salesforce Id and break in into chunk ranges of specified size
    * Only works if all the IDs have the same pod identider
    * Be careful of pod splits, sandbox / production data in a sandbox, etc.
    */    
    public static List<Map<String, String>> chunkIdRange(String startId, String endId, Integer chunkSize) {
		
		//grab the beginning of the Id.  we will need to append this back on to the chunked Ids at the end
		String idPrefix = startId.left(6);
		
		String startIdStripped = startId.left(15).right(9);
		String endIdStripped = endId.left(15).right(9);

		//now we have b62 pieces like this: 00006sfef
		//pass them to the method to decode them into Longs
		
		Long startNum = base62decode(startIdStripped); 
		Long endNum = base62decode(endIdStripped); 
	    	
    	//now pass this to the chunkRange method:
    	List<Map<String, String>> numberChunkList = chunkRange(startNum, endNum, 9, chunkSize);
    	
    	//system.debug(numberChunkList);
    	
    	//now loop through the ranges, base62 encode them, and add the id prefix back in
    	List<Map<String, String>> idChunkList = new List<Map<String, String>>();
    	for (Map<String, String> chunkMap: numberChunkList) {
    		Long rangeStart = Long.valueOf(drop_leading_zeros(chunkMap.get('first')));
    		Long rangeEnd 	= Long.valueOf(drop_leading_zeros(chunkMap.get('last')));
    		
    		String rangeStartB62 	= prefixStringWithZeros(base62encode(rangeStart), 9);
    		String rangeEndB62 		= prefixStringWithZeros(base62encode(rangeEnd), 9);
    		
    		idChunkList.add(new Map<String, String>{'first'=> idPrefix+rangeStartB62, 'last'=> idPrefix+rangeEndB62});
    	}
    	
    	return idChunkList;    
    }

    /*
    * This method is used to chunk up a large range of Long Integers into a list of smaller ranges.
    * start number, end number, and size of the chunks is passed in
    */
    public static List<Map<String, String>> chunkRange(Long firstNum, Long lastNum, Integer totalLength, Integer chunkSize) {
   		//get the range between the two numbers passed in. 
   		Long range = (lastNum - firstNum);	
    	
    	List<Map<String, Long>> numChunkList = new List<Map<String, Long>>();
    	
    	
 		if (range < chunkSize) { //range is already smaller than chunk, just add them all
 			numChunkList.add(new Map<String, Long>{'first'=> firstNum, 'last'=> lastNum});	
 		} else {
 			//need to create multiple chunks
 			
	    	//chunk the range up into chunks the size of chunkSize
			Decimal numChunks = (range / chunkSize);	//figure out how many whole and partial chunks we have
			numChunks = numChunks.round(System.RoundingMode.DOWN); 		//discard the partial chunk remainder
			Integer numWholeChunks = numChunks.intValue();
			
			//add the first chunk
			Long firstNumChunk = 	firstNum;
			Long lastNumChunk = 	firstNum + chunkSize - 1;
			numChunkList.add(new Map<String, Long>{'first'=> firstNumChunk, 'last'=> lastNumChunk}); 			
			
			//add any remaining chunks
			for (Integer i=1; i<numWholeChunks; i++) {
				firstNumChunk = (lastNumChunk + 1);
				lastNumChunk = (firstNumChunk + chunkSize - 1);						
				numChunkList.add(new Map<String, Long>{'first'=> firstNumChunk, 'last'=> lastNumChunk});
			}
			
			//add in the any remaining chunk which is < chunkSize
			Long lastlastNumChunk = numChunkList[numChunkList.size()-1].get('last'); //get last number from last row of the chunkList
			if (lastlastNumChunk < lastNum) {
				numChunkList.add(new Map<String, Long>{'first'=> lastlastNumChunk+1, 'last'=> lastNum});	
			}
	 	}    	
    	
    	//convert our integer map to a padded string map with 0's so it matches the salesforce Id format
    	List<Map<String, String>> numChunkListZeroPadded = new List<Map<String, String>>();
    	for (Map<String, Long> rangeMap: numChunkList) {
    		numChunkListZeroPadded.add(new Map<String, String>{	'first'=> prefixLongWithZeros(rangeMap.get('first'), totalLength), 
    															'last' => prefixLongWithZeros(rangeMap.get('last'),  totalLength)	});		
    	}
    	
    	return numChunkListZeroPadded;
    }
    
	/*
	* removes leading zeros from a passed string of numbers or returns NULL when not all numeric characters
	*
	* Source: https://www.interactiveties.com/blog/2011/apex-drop-leading-zeros.php#.VMv5Ml7F9sA
	*/
    public static String drop_leading_zeros(String passedValue) {
        String return_string = null; //return string for passing back
        if (passedValue != null) { //if the passed value is not null
            return_string = passedValue.trim(); //trim the whitespace from the start and end of the value
            Pattern valid_characters = Pattern.compile('([0-9]+)'); //only numbers
            Matcher check_chars = valid_characters.matcher(return_string); //compare the string to the set of valid characters
            if (check_chars.matches()) { //if we have a somewhat valid number
                if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with a 0 and the length is greater than 1
                    boolean keepChecking = true; //create a boolean variable
                    while (keepChecking) { //if boolean is true
                        if (return_string.startsWith('0') && return_string.length() > 1) { //if the string begins with 0 and there is more than 1 character
                            return_string = return_string.substring(1); //drop the first character
                        } else { //either the string doesn't begin with 0 or the length is less than or equal to 1
                            keepChecking = false; //stop the loop
                        }
                    }
                }
                if (return_string == '0') { //if the resulting string is now a single '0'
                    return_string = null; //set the string to null
                }
            } else { //otherwise the value passed was not valid
                return_string = null; //set the string to null
            }
        }
        return return_string; //pass back a value
    }
    
	public static String prefixStringWithZeros(String sInput, Integer totalLength) {
		String sOutput = '';
		
		if (sInput != null) {
			sOutput	= sInput+'';
		}
		
		//prepend with however many zeros we need to get up to total length
		Integer zerosToAdd = (totalLength - sOutput.length());
		if (zerosToAdd > 0) {
			for (Integer i=0; i<zerosToAdd; i++) {
				sOutput = '0'+sOutput;	
			}
		}
		
		return sOutput;
	}
    
	public static String prefixLongWithZeros(Long lngInput, Integer totalLength) {
		String sOutput = '';
		
		if (lngInput != null) {
			sOutput	= lngInput+'';
		}
		
		//prepend with however many zeros we need to get up to total length
		Integer zerosToAdd = (totalLength - sOutput.length());
		if (zerosToAdd > 0) {
			for (Integer i=0; i<zerosToAdd; i++) {
				sOutput = '0'+sOutput;	
			}
		}
		
		return sOutput;
	}
	
	public static long numericDistance(Id firstId, Id secondId) {
        long firstNumericId = numericId(firstId);
        long secondNumericId = numericId(secondId);
        return secondNumericId - firstNumericId;
    }

    public static long numericId(Id input) {
        return numericId((string)input);
    }

    public static long numericId(string input) {

        string idAsString = (string)input;
        if(idAsString.length() > 15) {
            // Drop the case checking suffix for the last 3 characters of an 18 char ID.
            idAsString = idAsString.substring(0, 15);
        }   

        long returnValue = 0;  
        long multiplier = 1;    

        for(integer i = idAsString.length(); i > 1; i--) {
            // The character being converted
            string idChar = idAsString.substring(i-1, i);  
            //System.debug(idChar);
            // The index of the character being converted
            long value = basedigits.indexOf(idChar);

            returnValue = returnValue + ( value * multiplier );  
            multiplier = multiplier * 62;  
        }

        return returnValue;
    }
}