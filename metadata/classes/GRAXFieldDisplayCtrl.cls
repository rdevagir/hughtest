/***************************************************************************************
Name              : GRAXFieldDisplayCtrl
Description       : 
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner 			07/24/2017                                Display Archived Records (https://app.asana.com/0/326600806074978/749901377818173/f)
2. Leandro Brunner          10/05/2018          David Mackey          APEX Governor Limit Warning (https://app.asana.com/0/326600806074978/849081244540524/f)
*****************************************************************************************/
public with sharing class GRAXFieldDisplayCtrl {
    public transient GRAXCustomFieldDisplay cSObj;
    public transient String objName {set;get;}
    public transient String fieldName {get;set;}
    public transient String currentValue {get;set;}
    public transient Boolean isEdit {get;set;}
    
    public GRAXFieldDisplayCtrl() {}

    public GRAXCustomFieldDisplay getcSObj() {
        if(cSObj == null) {
            cSObj = new GRAXCustomFieldDisplay(objName, fieldName, currentValue, isEdit);
        }

        return cSObj;
    }

    public class GRAXCustomFieldDisplay {
        public Schema.Sobjecttype sObjectType {get;set;}
        public String sObjectName {get;set;}
        public String sObjectLabel {get;set;}
        public String sObjectNameField {get;set;}
        public Map<String, CustomSObjectField> cSObjectFields {get;set;}
        public SObject sObjectHelper {get;set;}
        
        private Set<String> lookupFieldNames = new Set<String>();     
        
        public GRAXCustomFieldDisplay(String objName, String currentField, String currentValue, Boolean isEdit) {
            sObjectName = objName;                             
            String allFieldsForQuery = '';
            
            Schema.DescribeSObjectResult objDesc = GRAXUtils.getObjectDescribe(sObjectName);
            Map<String, Schema.DescribeFieldResult> objectFields = GRAXUtils.getDescribeFieldsResultForObject(sObjectName);
                                                            
            sObjectType = objDesc.getSObjectType();
            sObjectLabel = objDesc.getLabel();                                                                 
            SObject sObj = sObjectType.newSObject();                                                         
            cSObjectFields = new Map<String, CustomSObjectField>();
            sObjectHelper = objDesc.getSObjectType().NewSObject();
            
            if(currentField <> null) {              	       
                String currentFieldName = currentField.toLowerCase();          
                Schema.DescribeFieldResult fieldResult;
                SObject auxObject = sObj;
            
                fieldResult = objectFields.get(currentField);
                
                if(fieldResult <> null) {
                    CustomSObjectField cSObjField = new CustomSObjectField();   
                    cSObjField.fLabel = fieldResult.getLabel(); 
                    cSObjField.fName = fieldResult.getName();    
                    cSObjField.fType = String.ValueOf(fieldResult.getType());                            
                    cSObjField.isRequired = false;
                    cSObjField.isEditable = true;                                          
                    
                    cSObjField.fValue = currentValue;
                    
                    try {	                   
                        cSObjField.fValue = String.ValueOf(currentValue);
                        
                        if(currentValue <> null && fieldResult.getType() == Schema.DisplayType.DATE) {
                            cSObjField.fValue = String.valueOf(Date.valueOf(currentValue).format());
                        }
                        
                        if(currentValue <> null && fieldResult.getType() == Schema.DisplayType.DATETIME) {
                            cSObjField.fValue = String.valueOf(Datetime.valueOf(currentValue).format());
                        }
                    } catch(Exception e) {}
                        
                    try {
                        if(fieldResult.getType() == Schema.DisplayType.MultiPicklist) {
                            if(cSObjField.fValue <> null && cSObjField.fValue <> '') {
                                cSObjField.multipicklistSelectedValues = cSObjField.fValue.split(';');
                            }
                        }
                        
                        if(fieldResult.getType() == Schema.DisplayType.REFERENCE) {                                                                        
                            if(!currentFieldName.equalsIgnoreCase('RecordTypeId')) {
                                cSObjField.isPolymorphic = fieldResult.getReferenceTo().size() > 1;

                                // Get the Object Name defined for this related object
                                Schema.SObjectType relObjType;
                                if(cSObjField.isPolymorphic && String.isNotBlank(cSObjField.fValue)) {
                                    relObjType = Id.valueOf(cSObjField.fValue).getSobjectType();
                                } else {
                                    relObjType = fieldResult.getReferenceTo()[0];
                                }

                                String relObjName = GRAXUtils.getObjectNameFromSObjectType(relObjType);

                                Schema.DescribeSObjectResult relObjDesc = GRAXUtils.getObjectDescribe(relObjName);
                                
                                String relName = fieldResult.getRelationshipName();                                              
                                
                                CustomSObjectRefereceField cSObjRefField = new CustomSObjectRefereceField();
                                
                                cSObjRefField.fKeyPrefix = relObjDesc.getKeyPrefix();
                                cSObjRefField.fRelatedObjName = relObjName;

                                if(isEdit && cSObjField.isPolymorphic) {
                                    List<SelectOption> options = new List<SelectOption>();
                                    List<Schema.sObjectType> objectTypes = fieldResult.getReferenceTo();

                                    if(fieldResult.isNillable()) {
                                        options.add(new SelectOption('', '--None--'));
                                        cSObjField.picklistOptions.add(new PicklistOption('', '--None--'));
                                    }

                                    List<String> otNamesSorted = new List<String>();
                                    for(Schema.SObjectType ot : objectTypes) {
                                        otNamesSorted.add(GRAXUtils.getObjectNameFromSObjectType(ot));
                                    }

                                    otNamesSorted.sort();
                                                                    
                                    for(String otName : otNamesSorted) {
                                        Schema.DescribeSObjectResult relObjDescribe = GRAXUtils.getObjectDescribe(otName);
                                        String prefix = relObjDescribe.getKeyPrefix();

                                        options.add(new SelectOption(relObjDescribe.getKeyPrefix(), otName));
                                        cSObjField.picklistOptions.add(new PicklistOption(prefix, otName));	                                
                                    }

                                    cSObjField.picklistValues = options;
                                }
                                
                                // This is a Lookup field, build a dynamic SOQL query to get the current value for the Name field on the related object
                                if(cSObjField.fValue <> null && cSObjField.fValue <> '') {
                                    // Get the name field of the related object
                                    String relObjNameField = GRAXUtils.getNameFieldDescForObject(relObjName).getName();

                                    Object fRecordName;

                                    // Check if exist in cache.
                                    if(!isEdit && GRAXUtils.existRecordFieldCache('_' + cSObjField.fValue, relObjNameField)) { // From grax_fields (read-only mode)
                                        fRecordName = GRAXUtils.getRecordFieldCache('_' + cSObjField.fValue, relObjNameField);
                                    } else if(GRAXUtils.existRecordFieldCache(cSObjField.fValue, relObjNameField)) { // From queries
                                        fRecordName = GRAXUtils.getRecordFieldCache(cSObjField.fValue, relObjNameField);
                                    } else {
                                        // Create the dynamic SOQL query
                                        String dynSOQLStr = 'SELECT Id, ' + relObjNameField;
                                        dynSOQLStr += ' FROM ' + String.escapeSingleQuotes(relObjName);
                                        dynSOQLStr += ' WHERE Id = \'' + cSObjField.fValue + '\'';

                                        if(GRAXUtils.existRecordFieldCache('_' + cSObjField.fValue, relObjNameField)) {
                                            String graxName = String.valueOf(GRAXUtils.getRecordFieldCache('_' + cSObjField.fValue, relObjNameField));

                                            if(String.isNotBlank(graxName)) {
                                                dynSOQLStr += ' OR ' + relObjNameField + ' = \'' + graxName + '\'';
                                                dynSOQLStr += ' LIMIT 1';
                                            }
                                        }

                                        System.debug(dynSOQLStr);

                                        // Execute the SOQL query
                                        List<SObject> soqlQueryResults = Database.query(dynSOQLStr);
                                        
                                        // Only if one record was found, set the default value for this field in the response
                                        if(soqlQueryResults.size() == 1) {
                                            SObject sfdcRec = soqlQueryResults[0];

                                            System.debug(sfdcRec);
                                            
                                            cSObjField.fValue = sfdcRec.Id;
                                            fRecordName = sfdcRec.get(relObjNameField);
                                            
                                            // Save to cache.
                                            GRAXUtils.putRecordFieldCache(cSObjField.fValue, relObjNameField, fRecordName);
                                        }
                                    }

                                    System.debug(String.escapeSingleQuotes(relObjName) + ' ' + cSObjField.fValue + ' (' + fRecordName + ')');

                                    if(fRecordName <> null) {
                                        // Create the necessary response structure for a Lookup field
                                        cSObjRefField.fRecordId = cSObjField.fValue;
                                        cSObjRefField.fRecordName = String.valueOf(fRecordName);
                                        
                                        if(currentFieldName.equalsIgnoreCase('OwnerId')) {
                                            sObjectHelper.put('OwnerId', cSObjField.fValue);
                                        }
                                    }
                                }

                                cSObjField.cSObjRefField = cSObjRefField;	 
                            } else {
                                List<SelectOption> options = new List<SelectOption>();
                                Map<String,Schema.RecordTypeInfo> rectypes = objDesc.getRecordTypeInfosByName();

                                if(fieldResult.isNillable()) {
                                    options.add(new SelectOption('', '--None--'));
                                    cSObjField.picklistOptions.add(new PicklistOption('', '--None--'));
                                }

                                List<String> rtNamesSorted = new List<String>();
                                for(String rtName : rectypes.keySet()) {
                                    rtNamesSorted.add(rtName);
                                }

                                rtNamesSorted.sort();
                                                                
                                for(String rtName : rtNamesSorted) {
                                    options.add(new SelectOption(rectypes.get(rtName).getRecordTypeId(), rtName));
                                    cSObjField.picklistOptions.add(new PicklistOption(rectypes.get(rtName).getRecordTypeId(), rtName));	                                
                                }

                                cSObjField.picklistValues = options;
                                
                                cSObjField.recordtypesNamesById = new Map<Id, String>();
                                Map<Id,Schema.RecordTypeInfo> rectypesId = objDesc.getRecordTypeInfosById();

                                for(Id rtId : rectypesId.keySet()) {
                                    cSObjField.recordtypesNamesById.put(rtId, rectypesId.get(rtId).getName());
                                }   
                            }
                        }                           
                        
                        if(fieldResult.getType() == Schema.DisplayType.MULTIPICKLIST || fieldResult.getType() == Schema.DisplayType.PICKLIST) {
                            List<SelectOption> options = new List<SelectOption>();
                            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                            if(fieldResult.isNillable() && fieldResult.getType() == Schema.DisplayType.PICKLIST) {
                                options.add(new SelectOption('', '--None--'));
                                cSObjField.picklistOptions.add(new PicklistOption('', '--None--'));
                            }
                            
                            for(Schema.PicklistEntry f : ple) {
                                options.add(new SelectOption(f.getLabel(), f.getValue()));
                                cSObjField.picklistOptions.add(new PicklistOption(f.getValue(), f.getLabel(), true));
                            }

                            cSObjField.picklistValues = options; 
                        }
                        
                        if(fieldResult.getType() == Schema.DisplayType.TEXTAREA && fieldResult.isHtmlFormatted()) {
                            cSObjField.isRichText = true;
                        }
                        
                        if(fieldResult.getType() == Schema.DisplayType.ENCRYPTEDSTRING && !isEdit) {
                            cSObjField.fValue = '********';
                        }
                    } catch(Exception e) {}
                
                    cSObjectFields.put(currentField, cSObjField);
                }       
            }
        }
    }

    public class CustomSObjectField {
        public String fName {get;set;}
        public String fLabel {get;set;}
        public String fValue {get;set;}	
        public String fType {get;set;}
        public String errorMsg {get;set;}
        public Boolean isRequired {get;set;}
        public Boolean isRichText {get;set;}
        public Boolean isEditable {get;set;}
        public Boolean isVisibleOnEdit {get;set;}
        public Boolean isPolymorphic {get;set;}
        
        public CustomSObjectRefereceField cSObjRefField {get;set;}	
        public List<SelectOption> picklistValues {get;set;}
        public List<PicklistOption> picklistOptions {get;set;}
        public List<String> multipicklistSelectedValues {get;set;}
        public Map<Id, String> recordtypesNamesById {get;set;}
                
        public CustomSObjectField() {
            isRequired = false;
            isRichText = false;
            isEditable = true;
            isVisibleOnEdit = true;
            isPolymorphic = false;
            cSObjRefField = new CustomSObjectRefereceField();
            picklistOptions = new List<PicklistOption>();
        }	
    }

    public class CustomSObjectRefereceField {
        public String fRecordName {get;set;}
        public String fRecordId {get;set;}
        public String fKeyPrefix {get;set;}
        public String fRelatedObjName {get;set;}

        public CustomSObjectRefereceField() {}
    }

    public class PicklistOption {
        public String label	{get;set;}
        public String val {get;set;} 
        public Boolean isSelected {get;set;}
        
        public PicklistOption(String v, String l) {
            this.label = l;
            this.val = v;
            this.isSelected = false;
        }

        public PicklistOption(String v, String l, Boolean isSelected) {
            this.label = l;
            this.val = v;
            this.isSelected = isSelected;
        }
    }
}