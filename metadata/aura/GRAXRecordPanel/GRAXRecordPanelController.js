/**
 * Created by cpurodriguez on 12/27/17.
 */
({

    doInit: function(component, event, helper) {

        helper.initListener(component);

        helper.loadRecord(component, component.get('v.recordId'));
    },

    handleLoadRecordvalues: function(component, event, helper) {

        var newRecordId = event.getParam("newRecordId");

        helper.loadRecord(component, newRecordId);
    }

})