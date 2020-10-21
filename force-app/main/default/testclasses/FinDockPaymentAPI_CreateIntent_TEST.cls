@isTest
private with sharing class FinDockPaymentAPI_CreateIntent_TEST {
    @TestSetup
    static void prepareTestEnvironment() {
        cpm.TestService.createIbanRegex();
        cpm.TestService.initTestPSPExtension();
        cpm.TestService.initTestSourceExtension();
    }

    @isTest
    static void testPaymentMethodRetrieval() {
        Test.startTest();
        List<List<String>> paymentMethods = new List<List<String>>();
        try {
            paymentMethods = FinDockPaymentAPI_GetPaymentMethods.getPaymentMethods();
        }
        catch(FinDockPaymentAPI_GetPaymentMethods.InvocableAPIException e) {}
        System.debug('## payment methods: '+JSON.serializePretty(paymentMethods));
        Test.stopTest();
    }

    @isTest
    static void testPaymentIntentCall() {
        Account a = new Account(Name = 'TestAccount');
        insert a;
        Contact c = new Contact(LastName='Tester', AccountId = a.Id);
        insert c;
        FinDockPaymentAPI_CreateIntent.PaymentAPIRequest requestObject = new FinDockPaymentAPI_CreateIntent.PaymentAPIRequest();
        requestObject.contactId = c.Id;
        requestObject.SuccessURL = 'https://success.nl';
        requestObject.FailureURL = 'https://failed.nl';
        requestObject.selectedAmount = 20;
        requestObject.selectedPaymentMethod = 'CreditCard';

        List<FinDockPaymentAPI_CreateIntent.PaymentAPIRequest> paramList = new List<FinDockPaymentAPI_CreateIntent.PaymentAPIRequest>();
        paramList.add(requestObject);

        Test.startTest();
        FinDockPaymentAPI_CreateIntent.startPaymentFlow(paramList);
        Test.stopTest();
    }
}
