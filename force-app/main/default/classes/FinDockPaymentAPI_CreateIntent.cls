public with sharing class FinDockPaymentAPI_CreateIntent {
    /**
     * This is the front end method, invocable so it can be called from Flow, chatbot etc.
     */
    @InvocableMethod(label='FinDock API: Initiate Payment Intent Call' description='Starts a FinDock Payment API Payment Intent call')
	public static List<String> startPaymentFlow(List<PaymentAPIRequest> data) {
        System.debug('## payment call started');
        List<String> returnlist = new List<String>();
        for(PaymentAPIRequest req : data) {
			String result = FinDockPaymentAPI_CreateIntent.callAPI(req);
            returnlist.add(result);
        }
		return returnlist;
	}

    /**
     * This is what really creates the request and communicates with the FinDock Payment API
     */
    public static String callAPI(PaymentAPIRequest reqObject) {
        System.debug('## callAPI method called');
        String requestString = generateJSON(reqObject);
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.request = req;
		RestContext.response = res; 
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/v2/PaymentIntent';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(requestString);
		req.headers.put('verbose', 'true'); //enables more debug info in case of an error.
		cpm.API_PaymentIntent_V2.postPaymentIntent();
		Map<String, Object> resultSet = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
        System.debug('## api called, result: '+res.responseBody.toString());
		return String.valueOf(resultSet.get('RedirectURL'));
	}
    
    /**
     * This method creates a JSON request from the request object.
     */
    public static String generateJSON(PaymentAPIRequest reqObject) {
        reqObject = fixRequest(reqObject);
        String s = '';
		s += '{';
		s += '    "SuccessURL":"'+reqObject.SuccessURL+'",';
        s += '    "FailureURL":"'+reqObject.FailureURL+'",';
        if(reqObject.installmentID == null) { //we don't need to include payer info if there is an installment id.
            s += '    "Payer":{';
            s += '        "Contact":{';
            if(reqObject.contactId != null) { //if we have a contact ID, lets use that.
                s += '"Id":"'+reqObject.contactId+'"';
            } else { //if we don't have a contact id, lets use the lastname and email 
                s += '"SalesforceFields": {';
                s += '"LastName":"'+reqObject.lastName+'",'; 
                s += '"Email":"'+reqObject.email+'"';
                if(reqObject.firstName != null) { //and firstname if we have it.
                    s += ',"FirstName":"'+reqObject.firstName+'"';
                }
                s += '        }'; //close contact SalesforceFields block
            }
            s += '        }'; //close contact block
            s += '    },'; //close payer block
        }
		s += '    "OneTime":{';
        if(reqObject.installmentID != null) {
            s += '        "Id":"'+reqObject.installmentID+'"';
        } else {
            s += '        "Amount":'+reqObject.selectedAmount+'';
        }
		s += '    },';
		s += '    "PaymentMethod":{';
		s += '        "Name":"'+reqObject.selectedPaymentMethod+'"';
        s += '    }';
        if(reqObject.installmentID == null && (reqObject.campaignId != null || reqObject.campaign != null)) { //only include campaign id if installment id isn't set, and campaign or id is.
            if(reqObject.campaignId == null) {
                reqObject.campaignId = reqObject.campaign.Id;
            }
            s += ',"SalesforceFields": {';
            s += '"cpm__campaign__c": "'+reqObject.campaignId+'"';
            s += '}';
        }
        s += '}';
        System.debug('## JSON constructed: '+s);
        return s;
    }

    private static PaymentAPIRequest fixRequest(PaymentAPIRequest req) {
        if(req.selectedAmount == null && req.textAmount != null) {
            req.selectedAmount = Double.valueOf(req.textAmount);
        }
        return req;
    }

    /**
     * The parameter class used to pass data to the startPaymentFlow method. 
     */
    public class PaymentAPIRequest {
        @InvocableVariable(label='Installment ID' description='To initiate a payment for an existing installment, provide the id here' required=false)
        public Id installmentID;

        @InvocableVariable(label='Contact ID' description='The SF Record ID for the contact making the donation' required=false)
        public Id contactId;
        
        @InvocableVariable(label='Success URL' description='After a successful donation, the donor will be redirected to this page' required=false)
        public String SuccessURL;
        
        @InvocableVariable(label='Failure URL' description='If the transaction fails, the donor will be redirected to this page' required=false)
        public String FailureURL;
        
        @InvocableVariable(label='FirstName' description='If no ID is provided, this is the FirstName for the donor record' required=false)
        public String firstName;
        
        @InvocableVariable(label='LastNAme' description='If no ID is provided, this is the LastNAme for the donor record' required=false)
        public String lastName;
        
        @InvocableVariable(label='Email' description='If no ID is provided, this is the Email for the donor record' required=false)
        public String email;

        @InvocableVariable(label='CampaignId' description='Campaign Record Id to link the donation to' required=false)
        public Id campaignId;

        @InvocableVariable(label='Campaign Object' description='Campaign Record to link the donation to' required=false)
        public Campaign campaign;
        
        @InvocableVariable(label='Amount' description='The Amount of the donation' required=false)
        public Double selectedAmount;

        @InvocableVariable(label='StringAmount' description='String for amount if the stupid system needs it.' required=false)
        public String textAmount;
        
        @InvocableVariable(label='Payment Method' description='The payment method to be used in this transaction' required=false)
        public String selectedPaymentMethod;
        
        @InvocableVariable(label='Inbound Report' description='Allows the passing of custom values to the inbound report' required=false)
        public cpm__Inbound_Report__c inboundReportRecord;
    }
}