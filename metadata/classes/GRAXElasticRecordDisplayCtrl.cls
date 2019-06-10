public with sharing class GRAXElasticRecordDisplayCtrl {
    public transient String objName {set;get;}
    public transient String recordId {get;set;}
    public transient String orgId {get;set;}

    public transient Map<String, Schema.DescribeFieldResult> fieldsDescribe {get;set;}

    public Boolean isAdmin;

    public static GRAXPermissions gp {
        get {
            return new GRAXPermissions(UserInfo.getUserId());
        }
    }

    public GRAXElasticRecordDisplayCtrl() {
        isAdmin = gp.getIsAdmin();
    }

    public class ElasticField {
        public String name {get;set;}
        public String value {get;set;}
        public Boolean hasSField {get;set;}
        public String type {get;set;}

        public ElasticField(String name, Boolean hasSField) {
            this.name = name;
            this.hasSField = hasSField;
            this.value = null;
            this.type = 'text';
        }
    }

    public List<ElasticField> getElasticFields() {
        List<ElasticField> elasticFields = new List<ElasticField>();

        String recordJSON = getRecordJSON();

        if(String.isBlank(recordJSON)) {
            return elasticFields;
        }

        Map<String, Object> record = (Map<String, Object>)JSON.deserializeUntyped(recordJSON);

        if(GRAXUtils.sObjectExists(objName)) {
            fieldsDescribe = GRAXUtils.getDescribeFieldsResultForObject(objName);
        } else {
            return elasticFields;
        }

        for(String fieldName : record.keySet()) {
            ElasticField elasticField;

            if(fieldsDescribe.containsKey(fieldName)) {
                elasticField = new ElasticField(fieldName, true);

                if(GRAXSecurityUtils.checkAccess(objName, fieldName, GRAXSecurityUtils.FLSEnums.READ)) {
                    Object val = record.get(fieldName);

                    elasticField.type = getType(val);
                    elasticField.value = String.valueOf(val);
                }

            } else if(isAdmin) {
                elasticField = new ElasticField(fieldName, false);
                
                Object val = record.get(fieldName);

                elasticField.type = getType(val);
                elasticField.value = String.valueOf(val);
            }

            if(elasticField <> null) {
                elasticFields.add(elasticField);
            }
        }

        return elasticFields;
    }

    public String getType(Object o) {
        if(o == null) return 'text';

        if(o instanceof Boolean) return 'boolean';
        if(o instanceof String) return 'text';
        if(o instanceof Date) return 'date';
        if(o instanceof Datetime) return 'date';
        if(o instanceof Integer) return 'number';
        if(o instanceof Long) return 'number';
        if(o instanceof Decimal) return 'number';
        if(o instanceof Double) return 'number';
        
        return 'text';
    }

    public String getRecordJSON() {
        String recordJSON = '{}';

        GRAXSettings gxcSettings = new GRAXSettings(objName);

        if(String.isNotBlank(objName) && String.isNotBlank(recordId) && String.isNotBlank(orgId)) {
            String content = '';
            content = '{' +
                '"s3audit":"true",' + 
                '"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
                '"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
                '"s3region":"' + gxcSettings.graxConfig.s3region__c + '",' + 
                '"orgid": "'+ orgId + '",' +
                '"filterfield": "'+ 'Id' + '",' +
                '"filtervalue": "'+ recordId + '",' +
                '"objecttype": "'+ objName + '",' +
                '"fields": ""' + 
            '}';

            System.debug(content);
            
            String url = gxcSettings.ApiURL + '/audittrail/query';
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
                for(Object o : (List<Object>)(responseMap.get('data'))) {
                    recordJSON = JSON.serializePretty(o);
                }
            }
        }

        return recordJSON;
    }
}