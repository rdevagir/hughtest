/*****************************************************************************************
Name              : GRAXRestoreCtrl
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       05/11/2018             David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
2. Leandro Brunner       08/14/2018             David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
3. Leandro Brunner       10/05/2018             David Mackey        APEX Governor Limit Warning (https://app.asana.com/0/326600806074978/849081244540524/f)
4. Leandro Brunner       10/29/2018             David Mackey        Toppan Error (https://app.asana.com/0/326600806074978/884911061736571/f)
5. Leandro Brunner       11/06/2018             David Mackey        Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
6. Leandro Brunner       02/19/2018             David Mackey        Minor Items (https://app.asana.com/0/326600806074978/1109694460332953/f)
7. Leandro Brunner       02/19/2018             David Mackey        Too many SOQL Queries (https://app.asana.com/0/326600806074978/1109887667389111/f)
8. Leandro Brunner       03/07/2019             David Mackey        New Issues (https://app.asana.com/0/326600806074978/1112342626420899/f)
9. Leandro Brunner       03/08/2019             David Mackey        New Issues (https://app.asana.com/0/326600806074978/1112342626420899/f)
10. Leandro Brunner      05/10/2019             David Mackey        Merge "Search" and "Data Management" tabs (https://app.asana.com/0/326600806074978/1118868231502184/f)
11. N Leiva/N Ralero	 05/22/2019				David Mackey		UI Updates (https://app.asana.com/0/326600806074978/1123206281327080/f)
12. Leandro Brunner      05/28/2019             David Mackey        Restore Button on External Object (https://app.asana.com/0/326600806074978/1124474865343484/f)
******************************************************************************************/
public with sharing class GRAXRestoreCtrl {
    public Id parentId {get; set;}
    public String parentType;
    public String fieldsJsonString {get; set;}
    
    public transient List<String> selectedFieldsList {get;set;}
    public transient Map<String, Map<String, KeyVal>> objectMap {get;set;}
    public transient List<String> sortedIds {get;set;}
    public transient Map<String, KeyVal> sobjectToRestore {get;set;}
    public transient Boolean isSobjectToRestoreSelected;

    public transient Map<String, ChildRelatedItem> childRelatedMap {get;set;}

    public transient Map<String, Field> fieldMap {get;set;}
    public Set<String> fieldSetToExclude = new Set<String>{'Id', 'SystemModstamp'};
    public Map<String, Set<String>> fieldsToExcludeByObject = new Map<String, Set<String>>{
        'Case' => new Set<String>{'Comments'}
    };

    public transient List<Object> tableRecords {get;set;}
    private transient Map<String, Set<Id>> objectRefIdsMap;
    public String selectedFields {get;set;}
    public Set<String> queriedFieldSet {get;set;}

    public String objToQuery {get;set;}
    public String relToQuery {get;set;}

    public Boolean isMasterRestore {get;set;}
    public Boolean isRelatedRestore {get;set;}
    public String filterSearchTerm {get;set;}

    public Boolean isPersonAccountEnabled = false;
    public Boolean isPersonAccount {get;set;}

    public Set<String> contactFields;
    public Set<String> accountContactCommonFields = new Set<String>{
        'Id', 'IsDeleted', 'MasterRecordId', 'Phone', 'Name',
        'Fax', 'PhotoUrl', 'Description', 'OwnerId', 'CreatedDate',
        'CreatedById', 'LastModifiedDate', 'LastModifiedById',
        'SystemModstamp', 'LastActivityDate', 'LastViewedDate',
        'LastReferencedDate', 'Jigsaw', 'CleanStatus'
    };

    public String idToGetRelated {get;set;}
    
    public Boolean isReadOnlyMode {get;set;}

    public Object noVisibleValue = '***';

    public class Field {
        public Schema.DescribeFieldResult fd {get;set;}
        public String sObjectName {get;set;}

        public String name {get;set;}
        public String label {get;set;}
        public String type {get;set;}

        public Boolean isCreateable {get;set;}
        public Boolean isReference {get;set;}

        public Boolean isEditable {get;set;}
        public Boolean isNameField {get;set;}
        public Boolean isCustom {get;set;}

        private Set<String> sortableFieldTypes = new Set<String>{
            'address', 'combobox', 'currency', 'datacategorygroupreference',
            'id', 'integer', 'percent', 'picklist', 'reference', 'string',
            'textarea', 'time', 'email', 'date', 'datetime', 'double'
        };

        /*private Map<String, Set<String>> fieldsToExcludeSortingByObject = new Map<String, Set<String>>{
            
        };*/

        private Set<String> fieldSetToExcludeInModal = new Set<String>{'CreatedDate', 'LastModifiedDate', 'CreatedById', 'LastModifiedById'};

        public Field(Schema.DescribeFieldResult fd, String sObjectName) {
            this.fd = fd;
            this.sObjectName = sObjectName;

            this.name = fd.getName();
            this.label = GRAXUtils.CleanFieldLabel(fd, true);
            this.type = fd.getType().name();

            this.isCreateable = fd.isCreateable();
            this.isReference = fd.getReferenceTo().size() > 0;

            this.isNameField = fd.isNameField();
            this.isCustom = fd.isCustom();

            this.isEditable = true;
        }

        public String getCleanName() {
            if(!this.isCustom && this.name.endsWith('Id')) {
                return this.name.removeEnd('Id');
            }

            return this.name;
        }

        public Boolean getIsSortable() {
            Boolean isSortable = sortableFieldTypes.contains(this.type.toLowerCase());
            // isSortable &= (!fieldsToExcludeSortingByObject.containsKey(this.sObjectName) || !fieldsToExcludeSortingByObject.get(this.sObjectName).contains(this.name));

            isSortable &= !this.isReference;

            return isSortable;
        }

        public Boolean getIsAttachmentLink() {
            return this.isNameField && this.sObjectName == 'Attachment';
        }

        public Boolean getIsContentVersionLink() {
            return this.isNameField && this.sObjectName == 'ContentVersion';
        }

        public Boolean getIsModalExluded() {
            return fieldSetToExcludeInModal.contains(this.name);
        }
    }

    public class KeyVal {
        public String key {get;set;}
        public String val {get;set;}

        public KeyVal(String key, String val) {
            this.key = key;
            this.val = val;
        }
    }

    public static GRAXPermissions gp {
        get {
            return new GRAXPermissions(UserInfo.getUserId());
        }
    }

    public Integer totalRecords {get;set;}
    public Integer page {get;set;}
    public Integer pageLimit {get;set;}
    public String pageSort {get;set;}
    public String pageSortOrder {get;set;}
    public String pageSortType {get;set;}

    public Boolean restoreAttachments {get;set;}
    public String sobjectToRestoreId {get;set;}
    public String sobjectToRestoreGraxOrgId {get;set;}
    public String sobjectToRestoreGraxId {get;set;}
    public Boolean isRestoredSuccess {get;set;}
    public String restoredId {get;set;}
    public SObject soRestored {get;set;}

    public String archiveFilter {get;set;}
    public Boolean isAllOrgRecords {get;set;}

    public transient String restoreAttachmentsMessage {get;set;}
    public transient String restoreSObjectMessage {get;set;}

    public transient String previewAttGraxOrgId {get;set;}
    public transient String previewAttObjectType {get;set;}
    public transient String previewAttRecordId {get;set;}
    public transient String previewAttName {get;set;}
    public transient String previewAttMimeType {get;set;}
    public transient String previewAttSize {get;set;}

    public String userTimeZone {get;set;}

    public Boolean isEmbeddedRelatedList {get;set;}

    public GRAXRestoreCtrl() {
        try{
            objToQuery = GRAXUtils.getPageParameter('objToQuery');

            isEmbeddedRelatedList = GRAXUtils.getPageParameter('isEmbeddedRelatedList') == '1';
            
            if(isEmbeddedRelatedList) {
                selectedFields = GRAXUtils.getPageParameter('selectedFields');
            }
            
            if(objToQuery == null) {
                objToQuery = '';
            }

            fieldMap = new Map<String, Field>();
            objectMap = new Map<String, Map<String, KeyVal>>();
            sortedIds = new List<String>();
            tableRecords = new List<Object>();

            pageLimit = 50;
            page = 0;
            pageSort = '';
            pageSortOrder = 'asc';
            pageSortType = '';

            restoreAttachments = false;

            String strParentId;
            try {
                strParentId = GRAXUtils.getPageParameter('Id');
            } catch(Exception e) {}
            

            if(String.isNotBlank(strParentId)) {
                parentId = Id.valueOf(strParentId);
                parentType = parentId.getSObjectType().getDescribe().getName();
                isMasterRestore = false;
            } else {
                isMasterRestore = true;
            }

            isPersonAccountEnabled = GRAXUtils.isPersonAccountEnabled();
            if(isPersonAccountEnabled) {
                isPersonAccount = GRAXUtils.getPageParameter('isPA') == '1';
                contactFields = GRAXUtils.getDescribeFieldsResultForObject('Contact').keySet();
            }

            isRelatedRestore = GRAXUtils.getPageParameter('isRR') == '1';

            userTimeZone = UserInfo.getTimeZone().getID();

            archiveFilter = 'BOTH';
            isAllOrgRecords = isMasterRestore ? false : true;

            if(isEmbeddedRelatedList) {
                //retriveTableRecords();
                //updateSObjectMap();
            }
        } catch(Exception e) {
            System.debug(e.getMessage());
        }
    }

    public void retriveTableRecords() {
        tableRecords = new List<Object>();
        queriedFieldSet = new Set<String>();

        if(page == 0) {
            totalRecords = 0;
        }

        GRAXSettings gxcSettings = new GRAXSettings(objToQuery);

        String content = '';
        content = '{' +
            '"s3audit":"true",' + 
            '"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
            '"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
            '"s3region":"' + gxcSettings.graxConfig.s3region__c + '",' + 
            '"orgid": "'+ UserInfo.getOrganizationId() + '",' +
            '"objecttype": "'+ objToQuery + '",' +
            '"from": ' + (page * pageLimit) + ',' +
            '"limit": '+ (totalRecords <> null ? ((totalRecords == 0 || totalRecords > pageLimit) ? pageLimit : totalRecords) : pageLimit) + ',' +
            '"sort": "' + (String.isNotBlank(pageSort) ? pageSort + ' ' + pageSortOrder : '') + '",' +
            '"sortType": "' + (String.isNotBlank(pageSortType) ? pageSortType : '') + '",';

        if(isMasterRestore) {

            if(isPersonAccountEnabled && objToQuery == 'Account') {
                if(!String.isEmpty(filterSearchTerm)) {
                    filterSearchTerm += ' AND ';
                }

                filterSearchTerm += '(';

                if(!isPersonAccount) {
                    filterSearchTerm += 'NOT ';
                }

                filterSearchTerm += 'doc.IsPersonAccount: true';
                filterSearchTerm += ')';
            }

            content += '"esendpoint":"https://search-grax-sales-demo-2vurmmexs6c444alo45eyyzwea.us-east-2.es.amazonaws.com",';
        } else {
            String sourceId = getSourceId(parentId);

            filterSearchTerm = 'doc.' + relToQuery + ':(';
            filterSearchTerm += parentId;
            if(String.isNotBlank(sourceId)) {
                filterSearchTerm += ' OR ' + sourceId;
            }
            filterSearchTerm += ')';
        }

        String archiveFilterQuery;

        if(archiveFilter == 'BOTH') {
            archiveFilterQuery = null;
        }

        if(archiveFilter == 'BACKEDUP') {
            archiveFilterQuery = '(NOT doc.IsDeleted:true)';
        }

        if(archiveFilter == 'ARCHIVED') {
            archiveFilterQuery = '(doc.IsDeleted:true)';
        }

        if(archiveFilterQuery <> null) {
            if(!String.isEmpty(filterSearchTerm)) {
                filterSearchTerm += ' AND ';
            }

            filterSearchTerm += archiveFilterQuery;
        }

        if(!isAllOrgRecords) {
            if(!String.isEmpty(filterSearchTerm)) {
                filterSearchTerm += ' AND ';
            }

            filterSearchTerm += 'doc.graxorgid.keyword: "' + UserInfo.getOrganizationId() + '"';
        }

        System.debug(filterSearchTerm);

        if(String.isNotBlank(filterSearchTerm)) {
            content += '"query": ' + JSON.serialize(filterSearchTerm) + ',';
        }

        queriedFieldSet.addAll(new Set<String>{'Id', 'graxorgid', 'graxid'});

        if(objToQuery == 'Attachment') {
            queriedFieldSet.addAll(new Set<String>{'ContentType', 'BodyLength', 'graxfilename'});
        }

        if(objToQuery == 'ContentVersion') {
            queriedFieldSet.addAll(new Set<String>{'FileType', 'ContentSize', 'graxfilename'});
        }

        List<String> graxFields = GRAXUtils.getGraxFields(objToQuery);
        if(graxFields.size() > 0) {
            queriedFieldSet.addAll(graxFields);
        }

        if(selectedFieldsList <> null) {
            queriedFieldSet.addAll(selectedFieldsList);
        }

        System.debug(queriedFieldSet);

        content += '"fields": "';
        content += String.join(new List<String>(queriedFieldSet), ',');
        content += '"';

        content += '}';
        
        System.debug(content);

        String url = gxcSettings.ApiURL + '/audittrail/query';
        GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

        System.debug(callOutRes);

        if(callOutRes.success) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
            tableRecords = (List<Object>)(responseMap.get('data'));

            if(page == 0) {
                Map<String, Object> extraInfo = (Map<String, Object>)(responseMap.get('extraInfo'));
                this.totalRecords = (Integer)extraInfo.get('total');
            }
        }
    }


    public SObject createSObject(String typeName, Map<String, Object> mo) {
        updateSObjectFields();

        SObject so = GRAXUtils.createObjectInstance(typeName, null, true);

        for(Field f : fieldMap.values()) {
            try {
                if(f.isCreateable) {
                    if(f.name == 'ownerId') {
                        so.put(f.name, UserInfo.getUserId());
                    }

                    Object val = GRAXUtils.castGenericObjectToType(mo.get(f.name), f.type);
                    
                    /*if(f.isReference && !GRAXUtils.idExist((String)val)) {
                        continue;
                    }*/

                    if(f.name == 'RecordTypeId' && !GRAXUtils.idExist((String)val)) {
                        continue;
                    }

                    if(typeName == 'Account' && isPersonAccountEnabled && isPersonAccount && f.name == 'RecordTypeId') {
                        so.put('isPersonAccount', true);
                        
                        continue;
                    }

                    if(f.isEditable) {
                        so.put(f.name, val);
                    }
                }
            } catch(Exception e) {
                GRAXLogs.addLogException(e);

                if(typeName == 'Account' && isPersonAccountEnabled && isPersonAccount && f.name == 'RecordTypeId') {
                   continue; 
                }
                
                String eMsg = e.getMessage() + ' on field ' + f.label;

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, eMsg));
                System.debug(LoggingLevel.WARN, eMsg);
            }
        }

        return so;
    }

    private Map<String, Map<String, String>> objectFieldReferenceTo = new Map<String, Map<String, String>>();

    public Map<String, KeyVal> createObjectMap(Map<String, Object> mo, Boolean includeAllFields) {
        if(!objectFieldReferenceTo.containsKey(objToQuery)) {
            objectFieldReferenceTo.put(objToQuery, new Map<String, String>());
        }

        updateSObjectFields();

        Map<String, KeyVal> m = new Map<String, KeyVal>();

        if(queriedFieldSet <> null) {
            // Fill all queried fields with the retrieved value or blank.
            for(String qf : queriedFieldSet) {
                m.put(qf, new KeyVal(qf, String.valueOf(mo.get(qf))));
            }
        }

        for(Field f : fieldMap.values()) {

            if(includeAllFields || f.isCreateable) {
                Object val;

                if(mo.containsKey(f.name)) {
                    val = GRAXUtils.castGenericObjectToType(mo.get(f.name), f.type);

                    if(val <> null && f.type.toLowerCase() == 'date') {
                        val = GRAXUtils.formatDate(val, userTimeZone);
                    }

                    if(val <> null && f.type.toLowerCase() == 'datetime') {
                        val = GRAXUtils.formatDateTime(val, userTimeZone);
                    }

                    // Try to get the reference value from grax_fields and save it to cache.
                    if(f.isReference && val <> null) {
                        if(!objectFieldReferenceTo.get(objToQuery).containsKey(f.name)) {
                            objectFieldReferenceTo.get(objToQuery).put(f.name, GRAXUtils.getReferenceField(objToQuery, f.fd));
                        }

                        String refField = objectFieldReferenceTo.get(objToQuery).get(f.name);

                        Id rId = (Id)val;

                        if(refField <> null) {
                            String nameField = refField.split('\\.')[1];

                            if(!GRAXUtils.existRecordFieldCache('_' + rId, nameField) && !GRAXUtils.existRecordFieldCache(rId, nameField)) {
                                String graxField = GRAXUtils.getGraxFieldFromReference(refField);

                                if(mo.containsKey(graxField)) {
                                    GRAXUtils.putRecordFieldCache('_' + rId, nameField, mo.get(graxField));
                                } else {
                                    SObjectType rObjectType;

                                    try {
                                        rObjectType = rId.getSobjectType();
                                    } catch(Exception e) {}

                                    if(rObjectType <> null) {
                                        String sObjectType = String.valueOf(rObjectType);
                                        
                                        if(!this.objectRefIdsMap.containsKey(sObjectType)) {
                                            this.objectRefIdsMap.put(sObjectType, new Set<Id>());
                                        }

                                        GRAXUtils.putRecordFieldCache(rId, nameField, null);
                                        this.objectRefIdsMap.get(sObjectType).add(rId);
                                    }
                                }
                            }
                        }

                    }
                }

                if(!GRAXSecurityUtils.checkAccess(this.objToQuery, f.name, GRAXSecurityUtils.FLSEnums.READ)) {
                    val = noVisibleValue;
                }

                m.put(f.name, new KeyVal(f.name, String.valueOf(val)));
            }

        }

        return m;
    }

    public void updateSObjectMap() {
        objectMap = new Map<String, Map<String, KeyVal>>();
        objectRefIdsMap = new Map<String, Set<Id>>();
        sortedIds = new List<String>();

        if(String.isNotBlank(objToQuery)) {
            for(Object o : tableRecords) {
                Map<String, Object> mo = (Map<String, Object>)o;

                String sId = (String)mo.get('Id');

                sortedIds.add(sId);
                objectMap.put(sId, createObjectMap(mo, true));
            }
        }

        this.addReferencesNamesToCache();
    }
    
    public void addReferencesNamesToCache() {
        System.debug(this.objectRefIdsMap);

        for(String sObjectType : this.objectRefIdsMap.keySet()) {
            Schema.DescribeFieldResult fd = GRAXUtils.getNameFieldDescForObject(sObjectType);
            
            if(fd <> null) {
                String nameField = fd.getName();
                Set<Id> ids = this.objectRefIdsMap.get(sObjectType);

                String query = 'SELECT Id, ' + nameField + ' FROM ' + sObjectType;
                query += ' WHERE Id IN :ids';

                for(SObject ref : Database.query(query)) {
                    GRAXUtils.putRecordFieldCache(ref.Id, nameField, ref.get(nameField));
                }
            }
        }

        this.objectRefIdsMap.clear();
    }

    public void updateSObjectFields(String objToQuery){
        if(String.isNotBlank(objToQuery) && fieldMap == null) {
            fieldMap = new Map<String, Field>();

            Boolean addField = false;
            
            for(Schema.DescribeFieldResult fd : GRAXUtils.getDescribeFieldsResultForObject(objToQuery).values()) {
                Field f = new Field(fd, objToQuery);

                addField = !fieldSetToExclude.contains(f.name) && (!fieldsToExcludeByObject.containsKey(objToQuery) || !fieldsToExcludeByObject.get(objToQuery).contains(f.name));

                if(objToQuery == 'Account' && isPersonAccountEnabled && !isPersonAccount) {
                    addField &= accountContactCommonFields.contains(f.name) || !contactFields.contains(f.name);
                    addField &= !f.name.endsWith('__pc');
                }

                if(objToQuery == 'Account' && isPersonAccountEnabled && isPersonAccount && (f.name == 'Name' || f.name == 'RecordTypeId')) {
                    f.isEditable = false;
                }

                if(addField || f.name == 'Id') {
                    fieldMap.put(f.name, f);
                }
            }
        }
    }

    public void updateSObjectFields(){
        updateSObjectFields(this.objToQuery);
    }

    public List<Field> getSObjectFields() {
        updateSObjectFields();

        return fieldMap.values();
    }

    public Boolean getIsFieldSelected() {
        return String.isNotBlank(selectedFields);
    }

    public Boolean getIsTableRecordsEmpty() {
        return tableRecords == null || tableRecords.isEmpty();
    }

    public Pagereference changeObjToQuery() {
        String objToQueryValue = GRAXUtils.getPageParameter('objToQueryValue');

        if(objToQueryValue == 'Account2') {
            objToQueryValue = 'Account';
            isPersonAccount = true;
        }
        
        if(String.isNotBlank(objToQueryValue)) {
            if(isMasterRestore) {
                objToQuery = objToQueryValue;
            } else {
                getChildRelatedMap();

                objToQuery = childRelatedMap.get(objToQueryValue).name;
                relToQuery = childRelatedMap.get(objToQueryValue).value;
            }

            fieldMap = null;

            updateSObjectFields();
        }
        selectedFields = null;
        fieldsJsonString = getFieldsJSON(objToQuery);
        
        return null;
    }

    public Pagereference updateDataTable() {
        selectedFields = GRAXUtils.getPageParameter('selectedFields');
        
        if(isEmbeddedRelatedList) {
            selectedFieldsList = selectedFields.split(',');
        }else {
            selectedFieldsList = (List<String>)JSON.deserialize(selectedFields, List<String>.class);
        }

        filterSearchTerm = GRAXUtils.getPageParameter('filterSearchTerm');
        page = Integer.valueOf(GRAXUtils.getPageParameter('page'));
        pageSort = GRAXUtils.getPageParameter('sort');

        pageSortOrder = GRAXUtils.getPageParameter('sortOrder');

        pageSortType = GRAXUtils.getPageParameter('sortType');

        archiveFilter = GRAXUtils.getPageParameter('archiveFilter');
        isAllOrgRecords = GRAXUtils.getPageParameter('isAllOrgRecords') == 'true';

        retriveTableRecords();
        updateSObjectMap();
        
        return null;
    }

    public Pagereference changeSObjectToRestore() {
        isRestoredSuccess = false;
        restoredId = null;

        String soToRestore = GRAXUtils.getPageParameter('soToRestore');
        isReadOnlyMode = Boolean.valueOf(GRAXUtils.getPageParameter('isReadOnlyMode'));

        objectRefIdsMap = new Map<String, Set<Id>>();

        GRAXSettings gxcSettings = new GRAXSettings(objToQuery);

        if(String.isNotBlank(soToRestore)) {
            String content = '';
            content = '{' +
                '"s3audit":"true",' + 
                '"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
                '"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
                '"s3region":"' + gxcSettings.graxConfig.s3region__c + '",' + 
                '"orgid": "'+ UserInfo.getOrganizationId() + '",' +
                '"filterfield": "'+ 'Id' + '",' +
                '"filtervalue": "'+ soToRestore + '",' +
                '"objecttype": "'+ objToQuery + '",' +
                '"fields": ""' + 
            '}';

            System.debug(content);
            
            String url = gxcSettings.ApiURL + '/audittrail/query';
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
                for(Object o : (List<Object>)(responseMap.get('data'))) {
                    Map<String, Object> mo = (Map<String, Object>)o;

                    sobjectToRestore = createObjectMap(mo, true);

                    sobjectToRestoreId = String.valueOf(mo.get('Id'));
                    sobjectToRestoreGraxOrgId = String.valueOf(mo.get('graxorgid'));
                    sobjectToRestoreGraxId = String.valueOf(mo.get('graxid'));
                }
            }

            System.debug(JSON.serializePretty(sobjectToRestore));
        }

        this.addReferencesNamesToCache();

        return null;
    }

    public Boolean getisSobjectToRestoreSelected() {
        return sobjectToRestore != null;
    }

    public Pagereference saveSObjectToRestore() {
        updateSObjectFields();

        Map<String, Object> mo = new Map<String, Object>();

        System.PageReference formPageReference = ApexPages.currentPage();

        String serializedForm = GRAXUtils.getPageParameter('serializedForm');
        restoreAttachments = GRAXUtils.getPageParameter('restoreAttachments') == 'true';

        if(String.isNotBlank(serializedForm)) {
            formPageReference = new System.PageReference('/?' + serializedForm);
        }

        Map<String, String> formMap = formPageReference.getParameters();

        soRestored = null;

        if(objToQuery == 'Attachment' && formMap.containsKey('GRAXRestore_ParentId')) {
            restoredId = formMap.get('GRAXRestore_ParentId');

            if(String.isNotBlank(restoredId)) {
                isRestoredSuccess = true;
                restoreAttachments = true;
            } else {
                isRestoredSuccess = false;
                restoreAttachments = false;
                restoredId = null;
            }

            return null;
        }

        for(Field f : fieldMap.values()) {

            if(f.isCreateable) {
                Object val = formMap.get('GRAXRestore_' + f.name);

                if(f.isReference && !GRAXUtils.idExist((String)val)) {
                    continue;
                }

                if(val <> null) {
                    mo.put(f.name, val);
                }
            }
            
        }

        /*for(KeyVal kv : sobjectToRestore.values()) {
            if(fieldMap.get(kv.key).isCreateable) {
                kv.val = GRAXUtils.getPageParameter('GRAXRestore_' + kv.key);

                if(fieldMap.get(kv.key).isReference && !GRAXUtils.idExist((String)kv.val)) {
                    continue;
                }
            }

            if(kv.val <> null) {
                mo.put(kv.key, kv.val);
            }
        }*/

        System.debug(JSON.serializePretty(mo));

        if(ApexPages.getMessages().size() == 0) {
            try {
                SObject so = createSObject(objToQuery, mo);
                //if(!Test.isRunningTest()) {
                    insert so;

                    restoredId = so.Id;
                    soRestored = so;
                    isRestoredSuccess = true;
                //}
            } catch (System.FinalException f){
                GRAXLogs.addLogException(f);

                ApexPages.addMessages(f);
            } catch(Exception e) {
                GRAXLogs.addLogException(e);
                
                ApexPages.addMessages(e);
            }
        } else {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'System.FinalException: SObject row does not allow errors.'));
        }

        System.debug(ApexPages.getMessages());

        return null;
    }

    public void saveHistory() {
        if(soRestored <> null) {
            String source = '';
            source += '{';
            source += '"Id":"' + sobjectToRestoreId + '",';
            source += '"graxorgid":"' + sobjectToRestoreGraxOrgId + '",';
            source += '"graxid":"' + sobjectToRestoreGraxId + '"';
            source += '}';

            String destination = JSON.serialize(soRestored);

            String content = '';
            content += '{';
            content += '"orgid":"' + UserInfo.getOrganizationId() + '",';
            content += '"objecttype":"' + objToQuery + '",';
            content += '"source":' + source + ',';
            content += '"destination":' + destination;
            content += '}';

            System.debug(content);

            GRAXSettings gxs = new GRAXSettings();

            String url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/historyTracking';
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);
        }
    }

    public String getSourceId(String destinationId) {
        String sourceId;
        
        if(String.isNotBlank(destinationId)) {
            GRAXSettings gxs = new GRAXSettings();

            String url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/historyTracking';
            url += '?objecttype=' + objToQuery;
            url += '&destination_id=' + destinationId;
            url += '&destination_orgid=' + UserInfo.getOrganizationId();

            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.doHTTP('GET', null, url, null);

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);                
                List<Object> graxHistoryeRecords = (List<Object>)(responseMap.get('graxhistory'));
                
                if(graxHistoryeRecords <> null && graxHistoryeRecords.size() > 0) {
                    Map<String, Object> graxHistoryMap = (Map<String, Object>)graxHistoryeRecords.get(0);
                    
                    sourceId = String.valueOf(graxHistoryMap.get('source_Id'));
                }
            }
        }
        
        return sourceId;
    }

    public Pagereference restoreAttachmentsCallout() {
        restoreAttachmentsMessage = null;

        if(isRestoredSuccess && restoreAttachments && restoredId <> null) {
            GRAXSettings gxcSettings = new GRAXSettings();

            String url = gxcSettings.graxConfig.GRAX_Flow_URL__c;
            // url = 'https://7e47b5ea.ngrok.io;
            
            url += '/grax-app/grax-data-lake/';

            if(objToQuery == 'Attachment') {
                url += 'restoreAttachment';
            } else {
                url += 'restoreAttachments';
            }

            String content = '';
            content = '{' +
                '"orgid": "'+ UserInfo.getOrganizationId() + '",' +
                '"sessionid": "'+ UserInfo.getSessionId() + '",' +
                '"userId": "'+ UserInfo.getUserId() + '",' +
                '"endpoint": "' + EncodingUtil.urlencode(System.URL.getSalesforceBaseUrl().toExternalForm(),'utf-8') + '",' +
                '"graxorgid": "'+ sobjectToRestoreGraxOrgId + '",' +
                '"ParentId": "'+ sobjectToRestoreId + '",' +
                '"objecttype": "'+ objToQuery + '",' +
                '"Id": "'+ restoredId + '"' +
            '}';

            System.debug(content);
            
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);

                restoreAttachmentsMessage = String.valueOf(responseMap.get('state'));
            } else {
                restoreAttachmentsMessage = JSON.serialize(callOutRes.response);
            }
        }

        return null;
    }

    public static GRAXCloud.CallOutResponse restoreSObject(String objToQuery, String recordId, String graxorgid) {
        GRAXCloud.CallOutResponse callOutRes;

        if(String.isNotBlank(objToQuery) && String.isNotBlank(recordId) && String.isNotBlank(graxorgid)) {
            GRAXSettings gxcSettings = new GRAXSettings();

            String url = gxcSettings.graxConfig.GRAX_Flow_URL__c;
            // url = 'https://7e47b5ea.ngrok.io;
            
            url += '/grax-app/grax-data-lake?action=restore';
            url += '&orgid=' + UserInfo.getOrganizationId();
            url += '&userid=' + UserInfo.getUserId();
            url += '&sessionid=' + UserInfo.getSessionId();

            // Restore configurations
            url += '&restoreChildrens=false';
            url += '&sfRequestsDisabled=true';
            url += '&checkIsUserActive=true';
            url += '&useGRAXHistoryOnly=false';
            url += '&updateRecordIfExist=false';
            url += '&sendNotification=false';

            String content = '';
            content += '[{';
            content += '"attributes":{"type":"' + objToQuery + '"},';
            content += '"Id":"' + recordId + '",';
            content += '"graxorgid":"' + graxorgid + '"';
            content += '}]';

            System.debug(content);
            
            callOutRes = GRAXCloud.calloutnow(url, content);
        }

        return callOutRes;
    }

    public Pagereference restoreSObjectCallout() {
        restoreSObjectMessage = null;

        String recordId = GRAXUtils.getPageParameter('recordId');
        String graxorgid = GRAXUtils.getPageParameter('graxorgid');

        GRAXCloud.CallOutResponse callOutRes = restoreSObject(objToQuery, recordId, graxorgid);

        System.debug(callOutRes);

        if(callOutRes <> null && callOutRes.success) {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);

            restoreSObjectMessage = String.valueOf(responseMap.get('state'));
        } else {
            restoreSObjectMessage = JSON.serialize(callOutRes.response);
        }

        return null;
    }

    public class ChildRelatedItem {
        public String name {get;set;}
        public String label {get;set;}
        public String relation {get;set;}
        public String value {get;set;}
        public String index {get;set;}

        public ChildRelatedItem(Schema.ChildRelationship childRel, String index) {
            Schema.DescribeSObjectResult childSObjectDescribe = childRel.getChildSObject().getDescribe();

            this.name = childSObjectDescribe.getName();
            this.label = childSObjectDescribe.getLabel();
            this.relation = childRel.getRelationshipName();
            this.value = String.valueOf(childRel.getField());
            this.index = index;
        }
    }

    public void getChildRelatedMap() {
        if(childRelatedMap == null) {
            childRelatedMap = new Map<String, ChildRelatedItem>();

            Integer index = 0;
            for(Schema.ChildRelationship childRel : GRAXUtils.getObjectDescribe(parentType).getChildRelationships()) {
                if(String.isNotBlank(childRel.getRelationshipName())) {
                    ChildRelatedItem cri = new ChildRelatedItem(childRel, String.valueOf(index));
                    childRelatedMap.put(cri.index, cri);
                    index++;
                }
            }
        }
    }

    public String getRelatedJSON() {   
        getChildRelatedMap();
        
        return JSON.serialize(childRelatedMap.values());
    }

    public List<SelectOption> getItems() {
        List<SelectOption> options = GRAXBackupCtrl.getItems(null);

        if(isPersonAccountEnabled) {
            options.add(new SelectOption('Account2', 'Account (Person)'));
        }

        options.sort();
        
        return options;
    }

    public String getRestoreItemsJSON() {
        List<Map<String, String>> objs = new List<Map<String, String>>();
        Map<String, String> obj;

        for(SelectOption op : getItems()) {
            if(!op.getDisabled()) {
                String index = op.getValue();

                obj = new Map<String, String>();
                obj.put('label', op.getLabel());
                obj.put('index', index);
                
                if(isRelatedRestore) {
                    getChildRelatedMap();
                    
                    obj.put('name',  childRelatedMap.get(index).name);
                }

                objs.add(obj);
            }
        }

        return JSON.serialize(objs);
    }

    public String getFieldsJSON(String objToQuery) {
        updateSObjectFields(objToQuery);

        List<Object> fList = new List<Object>();
        Map<String, Object> fMap;
        
        if(String.isNotBlank(objToQuery)) {
            for (Field f : fieldMap.values())
            {
                if(f.type.equalsIgnoreCase('base64')) continue;

                if(f.isReference && f.fd.getReferenceTo().size() > 1 && !GRAXUtils.isPolymorphicAvailableToGetReference(objToQuery, f.fd)) {
                    continue;
                }

                if(!GRAXSecurityUtils.checkAccess(objToQuery, f.name, GRAXSecurityUtils.FLSEnums.READ)) {
                    continue;
                }

                fMap = new Map<String, Object>();
                fMap.put('id', f.name);
                fMap.put('label', f.label);
                fMap.put('isSelected', f.isNameField || f.name == 'CreatedDate' || f.name == 'Id');
                fMap.put('type', f.type);

                fList.add(fMap);
            }
        }
        
        return JSON.serialize(fList);
    }

    public String getFieldsJSON() {
        return getFieldsJSON(this.objToQuery);
    }
    
    public Pagereference changeIdToGetRelated() {
        idToGetRelated = GRAXUtils.getPageParameter('idToGetRelated');

        return null;
    }

    public String getRelatedIframeUrl() {
        String restoreURL = 'javascript:void(0);';

        if(String.isNotBlank(idToGetRelated)) {
            restoreURL = '/apex/GRAXRestore?Id=' + idToGetRelated + '&isRR=1';

            if(isPersonAccountEnabled && objToQuery == 'Account') {
                restoreURL += '&isPA=' + (isPersonAccount ? '1' : '0');
            }
        }

        return restoreURL;
    }

    /*public String getFieldVsTypeJSON() {
        if(fieldMap == null) {
            return '{}';
        }

        Map<String, String> fieldVsTypeMap = new Map<String, String>();

        for(Field f : fieldMap.values()) {
            fieldVsTypeMap.put(f.name, f.type);
        }

        return JSON.serialize(fieldVsTypeMap);
    }*/

    public Pagereference previewAttachment() {
        previewAttGraxOrgId = GRAXUtils.getPageParameter('graxorgid');
        previewAttObjectType = GRAXUtils.getPageParameter('objectType');
        previewAttRecordId = GRAXUtils.getPageParameter('recordId');
        previewAttName = GRAXUtils.getPageParameter('name');
        previewAttMimeType = GRAXUtils.getPageParameter('mimeType');
        previewAttSize = GRAXUtils.getPageParameter('size');

        return null;
    }

    private String exportToCsvUrl;

    public String getExportToCsvUrl() {
        if(String.isBlank(exportToCsvUrl)) {
            GRAXPermissions gp = new GRAXPermissions(UserInfo.getUserId());
            GRAXSettings gxs = new GRAXSettings();

            exportToCsvUrl = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/export/elastic/csv';

            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(
                gxs.graxConfig.GRAX_Flow_URL__c + '/jwt', '{"url": "' + exportToCsvUrl + '"}');

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);

                String token = (String)responseMap.get('token');

                System.debug('Token: ' + token);

                exportToCsvUrl += '?action=export';
                exportToCsvUrl += '&token=' + token;
            }
        }
        
        return exportToCsvUrl;
    }

    private transient String elasticFieldsMapping;

    public String getElasticFieldsMapping() {
        if(String.isBlank(objToQuery)) {
            return '{}';
        }
        
        if(String.isBlank(elasticFieldsMapping)) {
            GRAXSettings gxs = new GRAXSettings();

            String url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/getDataTypeFields/grax' + objToQuery.toLowerCase() + 'index';

            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.doHTTP('GET', null, url, null);

            System.debug(callOutRes);

            if(callOutRes.success) {
                elasticFieldsMapping = callOutRes.response;
            }
        }
        
        return elasticFieldsMapping;
    }
}