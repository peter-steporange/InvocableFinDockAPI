public with sharing class FinDockPaymentAPI_GetPaymentMethods {
	@InvocableMethod(label='FinDock API: Retrieve the active Payment Methods' description='Returns a list of active and usable payment methods')
    public static List<List<String>> getPaymentMethods() {
        System.debug('## get payment methods called!');
        List<List<String>> returnList = new List<List<String>>();
        RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.request = req;
		RestContext.response = res; 
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm()+'/services/apexrest/v2/PaymentMethods';
		req.httpMethod = 'GET';
        cpm.API_PaymentMethod_V2.getPaymentMethods();
        System.debug('## response is in: '+res.responseBody.toString());
        PaymentMethodResponse pmResponse = (PaymentMethodResponse)JSON.deserialize(res.responseBody.toString(), PaymentMethodResponse.class);
        if(pmResponse == null || pmResponse.PaymentMethods == null) {
            throw new InvocableAPIException('No configured payment methods found');
        }
        List<String> pmValues = new List<String>();
        for(PaymentMethod pm : pmResponse.PaymentMethods) {
            pmValues.add(pm.Name);
        }
        returnList.add(pmValues);
        return returnList;
    }
    
    public class PaymentMethodResponse {
        public List<PaymentMethod> PaymentMethods;
    }
    
    public class PaymentMethod {
        public String Name;
        public List<Processor> Processors;
    }
    
    public class Processor {
        public String Name;
        public Boolean RecurringRequiresInitialPayment;
        public Boolean IsDefault;
        public Boolean SupportsRecurring;
    }

    public class InvocableAPIException extends Exception {}
}