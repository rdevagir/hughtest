public with sharing class GRAXSecurityUtils {
    public enum FLSEnums {READ, MODIFY, CREATE, REMOVE, UPSRT}

    public static Boolean checkAccess(String strSObjectName, String [] strfieldset, FLSEnums action){
        boolean bIsCustom = False;
        string sobjectName = null;
        string strFieldName = null;
        List<String> fieldset = new List<String>();
        integer intCounter = 0;

        String namespace = GRAXUtils.getPureNameSpace();
        
        if((strSObjectName != null && strSObjectName != '') && (strfieldset != null && strfieldset.size() > 0) && (action != null)){
            /*
            //
            // These lines should only be used when running the code on the package environment and the fields from GRAX Custom Objects don't include the namespace prefix
            //
            if(strSObjectName.endsWithIgnoreCase('__c'))
                sobjectName = (String.isNotBlank(namespace) ? namespace + '__' : '') + strSObjectName;
            else 
                sobjectName = strSObjectName;
            for(intCounter = 0; intCounter < strfieldset.size(); intCounter++){
                strFieldName = strfieldset[intCounter];
                if(strFieldName.endsWithIgnoreCase('__c'))
                    fieldset.add((String.isNotBlank(namespace) ? namespace + '__' : '') + strfieldset[intCounter]);
                else
                    fieldset.add(strfieldset[intCounter]);
            }
            */
            sobjectName = strSObjectName;
            fieldset.addAll(strfieldset);

            if(GRAXUtils.sObjectExists(sobjectName)) {
                // Get the sObject describe result
                Schema.DescribeSObjectResult descResult = GRAXUtils.getObjectDescribe(sobjectName);
                if(descResult != null){
                    // Returns all the field of sObject
                    Map<String,Schema.DescribeFieldResult> fieldMap = GRAXUtils.getDescribeFieldsResultForObject(sobjectName);
                    if(fieldMap != null){
                        //Checking for Upsert command
                        if(action == FLSEnums.UPSRT) {
                            if(!descResult.isCreateable() && !descResult.isUpdateable()){
                                return false;
                            } 
                            else {
                                for(String field : fieldset){
                                    if(!fieldMap.get(field).isCreateable() && !fieldMap.get(field).isUpdateable()){
                                        return false;
                                    }
                                }
                                return true;
                            }
                        }
                        //Checking for Select command
                        else if(action == FLSEnums.READ){
                            if(!descResult.isAccessible()){
                                return false;
                            } 
                            else{
                                for(String strfield : fieldset){
                                    if(!bIsCustom ){
                                        if(!fieldMap.containsKey(strfield) || !fieldMap.get(strfield).isAccessible()){
                                            return false;
                                        }
                                    }
                                }
                                return true;
                            }
                        }
                        else if(action == FLSEnums.MODIFY) {
                            if(!descResult.isUpdateable()) 
                            {
                                return false;
                            } 
                            else 
                            {
                                for(String field : fieldset) 
                                {
                                    if(!fieldMap.get(field).isUpdateable())
                                    {
                                        return false;
                                    }
                                }
                                return true;
                            }
                        }
                        else if(action == FLSEnums.CREATE) {
                            if(!descResult.isCreateable()) 
                            {
                                return false;
                            } 
                            else 
                            {
                                for(String field : fieldset) 
                                {
                                    if(!fieldMap.get(field).isCreateable())
                                    {
                                        return false;
                                    }
                                }
                                return true;
                            }
                        }
                        else if(action == FLSEnums.REMOVE) {
                            if(!descResult.isDeletable()) 
                                return false;
                            else
                                return true;
                        }
                    }
                }
            }
        }
        return false;        
    }

    public static Boolean checkAccess(String strSObjectName, String fieldName, FLSEnums action){
        return checkAccess(strSObjectName, new List<String>{fieldName}, action);
    }

}