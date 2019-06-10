/**
 * Created by cpurodriguez on 12/27/17.
 */
({

    loadRecord: function(component, recordId) {

        var action = component.get("c.getRecordValues");
        action.setParams({ recordId : recordId });

        // Create a callback that is executed after
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {

                // You would typically fire a event here to trigger
                // client-side notification that the server-side
                // action is complete

                this.loadTable(component, response);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        // A client-side action could cause multiple events,
        // which could trigger other events and
        // other server-side action calls.
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);

    },

    loadTable: function(component, response) {

        var fieldValues = [];

        var result = response.getReturnValue();

        component.set("v.selectedRecordName", result["Name"]);
        component.set("v.selectedRecordId", result["Id"]);

        var keys = Object.keys(result);

        keys.forEach(function(element) {

            fieldValues.push({label: element, value: result[element]});

        });

        component.set("v.fieldValues", fieldValues);

        console.log(fieldValues[0]);
        console.log(JSON.stringify(component.get("v.fieldValues")));
    },

    initListener: function(component) {

        var that = this;

        function listenMessage(message) {

            console.log("post message received ");
            console.log(message.data);

            that.loadRecord(component, message.data);
        }

        if (window.addEventListener) {
            window.addEventListener("message", listenMessage, false);
        }
        else {
            window.attachEvent("onmessage", listenMessage);
        }
    }


})