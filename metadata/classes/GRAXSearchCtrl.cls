/*****************************************************************************************
Name              : GRAXRestoreCtrl
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner   	 05/11/2018             David Mackey        
2. N Leiva/N Ralero	 	 05/22/2019				David Mackey		UI Updates (https://app.asana.com/0/326600806074978/1123206281327080/f)
3. Leandro Brunner       05/31/2019             David Mackey        Date Format should be based on user locale (https://app.asana.com/0/326600806074978/1125157851523067/f)
4. Leandro Brunner       05/31/2019             David Mackey        UI Updates (https://app.asana.com/0/326600806074978/1123206281327080/f)
******************************************************************************************/
public with sharing class GRAXSearchCtrl {
    public Boolean isEmbedded {get;set;}

    public String indexToQuery {get;set;}

    public String selectedFields {get;set;}
    public transient List<String> selectedFieldsList {get;set;}
    
    public Boolean isRetrieved {get;set;}

    public String filterSearchTerm {get;set;}
    
    public String fieldJsonString {get; set;}

    public transient String retrievedRecordsJSON {get;set;}
    public Integer totalRecords {get;set;}
    public Integer page {get;set;}
    public Integer pageLimit {get;set;}
    public String pageSort {get;set;}
    public String pageSortOrder {get;set;}

    public transient GRAXRestoreCtrl gr;

    public transient String previewRecordObjName {get;set;}
    public transient String previewRecordId {get;set;}
    public transient String previewRecordOrgId {get;set;}

    public String userLocale {get;set;}
    public String userTimeZone {get;set;}

    public GRAXSearchCtrl() {
        indexToQuery = '';

        retrievedRecordsJSON = '[]';

        pageLimit = 50;
        page = 0;
        pageSort = '';
        pageSortOrder = 'asc';

        isEmbedded = String.isNotBlank(GRAXUtils.getPageParameter('isdtp'));

        userLocale = UserInfo.getLocale();
        userTimeZone = UserInfo.getTimeZone().getID();
    }
    
    public class fieldWrapper {
        String id {get; set;}
        String label {get; set;}
        
        public fieldWrapper(String fieldName) {
            this.id = fieldName;
            this.label = fieldName;
        }
    }
    
    public Pagereference changeIndexToQuery() {
        indexToQuery = GRAXUtils.getPageParameter('indexToQueryValue');
        
        List<fieldWrapper> jsonList = new List<fieldWrapper>();
        
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(getFieldsJSON());
        for(Object s : jsonMap.keySet()) {
            jsonList.add(new fieldWrapper(String.valueOf(s)));
        }
        
        fieldJsonString = JSON.serialize(jsonList);
        
        return null;
    }

    public String getGraxIndexes() {
        GRAXSettings gxcSettings = new GRAXSettings(indexToQuery);

        String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/getDataTypes';
        GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, url, null);

        System.debug(callout);

        if(callout.success) {
            return callout.response;
        }

        return '[]';
    }

    public void retriveTableRecords() {
        retrievedRecordsJSON = '[]';

        GRAXSettings gxcSettings = new GRAXSettings(indexToQuery);

        String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake';

        url += '?action=load';
        url += '&dataIndex=' + EncodingUtil.urlEncode(indexToQuery, 'UTF-8');
        url += '&_select=' + EncodingUtil.urlEncode(selectedFields + ',Id,graxorgid,attributes.type', 'UTF-8');
        url += '&_q=' + EncodingUtil.urlEncode(filterSearchTerm, 'UTF-8');
        url += '&_from=' + (page * pageLimit);
        url += '&_limit=' + (totalRecords <> null ? ((totalRecords == 0 || totalRecords > pageLimit) ? pageLimit : totalRecords) : pageLimit);
        url += '&_sort=' + EncodingUtil.urlEncode((String.isNotBlank(pageSort) ? pageSort + ' ' + pageSortOrder : ''), 'UTF-8');

        System.debug(url);

        GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, url, null);

        System.debug(callout);

        if(callout.success && callout.response != '[]') {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callout.response);
            retrievedRecordsJSON = JSON.serialize(responseMap.get('results'));

            Map<String, Object> extraInfo = (Map<String, Object>)(responseMap.get('extraInfo'));
            this.totalRecords = (Integer)extraInfo.get('total');
        } else {
            retrievedRecordsJSON = '[]';
            this.totalRecords = 0;
        }

        isRetrieved = true;
    }

    public Pagereference updateSearchDataTable() {
        selectedFields = GRAXUtils.getPageParameter('selectedFields');
        selectedFieldsList = (List<String>)JSON.deserialize(selectedFields, List<String>.class);
        selectedFields = String.join(selectedFieldsList, ',');

        filterSearchTerm = GRAXUtils.getPageParameter('filterSearchTerm');
        page = Integer.valueOf(GRAXUtils.getPageParameter('page'));
        pageSort = GRAXUtils.getPageParameter('sort');
        pageSortOrder = GRAXUtils.getPageParameter('sortOrder');

        retriveTableRecords();

        return null;
    }

    public Boolean getHasResults() {
        return this.isRetrieved && this.totalRecords <> null && this.totalRecords > 0;
    }

    public Boolean getIsFieldSelected() {
        return String.isNotBlank(selectedFields);
    }

    public String getFieldsJSON() {
        GRAXSettings gxcSettings = new GRAXSettings(indexToQuery);

        String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/getDataTypeFields/' + indexToQuery;
        GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, url, null);

        System.debug(callout);

        if(callout.success) {
            return callout.response;
        }

        return '{}';
    }

    public Pagereference previewRecord() {
        previewRecordObjName = GRAXUtils.getPageParameter('objName');
        previewRecordId = GRAXUtils.getPageParameter('recordId');
        previewRecordOrgId = GRAXUtils.getPageParameter('orgId');

        return null;
    }
}