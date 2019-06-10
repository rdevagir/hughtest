/**
 * Created by cpurodriguez on 12/22/17.
 */

public with sharing class GraxRecordViewController {


    @AuraEnabled
    public static Map<String, Object> getRecordValues(Id recordId) {

        Schema.DescribeSObjectResult dsr = recordId.getSObjectType().getDescribe();
        String objectName = dsr.getName();

        Map<String, Grax_Mapping__c> fieldsValues = getObjectValues(objectName);

        String queryFields = String.join(new List<String>(fieldsValues.keySet()), ', ');

        String query = 'SELECT ' + queryFields + ' FROM ' + objectName + ' WHERE Id = :recordId';


        sObject[] records = Database.query(query);

        Map<String, Object> result = new Map<String, Object>();

        if (!records.isEmpty()) {

            sObject record = records[0];

            for (Grax_Mapping__c fieldsValue :fieldsValues.values()) {

                result.put(fieldsValue.Field_Label__c, record.get(fieldsValue.API_Field_Name__c));
            }

        }

        return result;

    }

    private static Map<String, Grax_Mapping__c> getObjectValues(String objectName) {

        Grax_Mapping__c[] values = [SELECT
                                        Order__c,
                                        Field_Label__c,
                                        API_Field_Name__c
                                    FROM Grax_Mapping__c
                                    WHERE Object__c = :objectName
                                    ORDER BY Order__c];


        Map<String, Grax_Mapping__c> result = new Map<String, Grax_Mapping__c>();

        for (Grax_Mapping__c value :values) {
            result.put(value.API_Field_Name__c, value);
        }

        return result;
    }

}