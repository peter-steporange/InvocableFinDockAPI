@isTest
private with sharing class FinDockPaymentAPI_CreateIntent_TEST {
    @TestSetup
    static void prepareTestEnvironment() {
        cpm.TestService.createIbanRegex();
        cpm.TestService.initTestPSPExtension();
        cpm.TestService.initTestSourceExtension();

        cpm__Payment_Method__c[] paymentMethods = [Select Id, cpm__IsActive__c from cpm__Payment_Method__c];
        for ( cpm__Payment_Method__c method : paymentMethods ) {
            method.cpm__IsActive__c = true;
            method.cpm__Method_Default__c = true;
        }
        update paymentMethods;

        cpm.CommonService.upsertDefaultPaymentIntentGMSetup();

        List<cpm__Setup_Record__c> setupRecords = [
            select Name, cpm__IsDefault__c
            from cpm__Setup_Record__c 
            where cpm__Category__c = 'Source'];
        for (cpm__Setup_Record__c setupRecord : setupRecords) {
            setupRecord.cpm__IsDefault__c = true;
            System.debug('Source package ' + setupRecord.Name + ' set to default. ');
        }
        update setupRecords;

    }

    /**
     * Given that the default test psp is active, the response should contain a creditcard payment method.
     */
    @isTest
    static void testPaymentMethodRetrieval() {
        Test.startTest();
        List<List<String>> paymentMethods = new List<List<String>>();
        try {
            paymentMethods = FinDockPaymentAPI_GetPaymentMethods.getPaymentMethods();
            Boolean paymentMethodsContainsCreditCard = false;
            for(List<String> sublist : paymentMethods) {
                for(String subString : subList) {
                    if(subString == 'CreditCard') {
                        paymentMethodsContainsCreditCard = true;
                    }
                }
            }
            System.assert(paymentMethodsContainsCreditCard);
        }
        catch(FinDockPaymentAPI_GetPaymentMethods.InvocableAPIException e) {
            System.assert(false);
        }
        System.debug('## payment methods: '+JSON.serializePretty(paymentMethods));
        Test.stopTest();
    }

    /**
     * when we initiate an api call we should expect to get a redirectURL for the testPSP package.
     */
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
        List<String> responseList = FinDockPaymentAPI_CreateIntent.startPaymentFlow(paramList);
        if(responseList.size() > 0) {
            System.assertNotEquals(null, responseList[0], 'No RedirectURL found.');
        } else {
            System.assert(false);
        }
        Test.stopTest();
    }

    /**
     * when we initiate an api call we should expect to get a redirectURL for the testPSP package.
     * This time there is no contact ID, we insert firstname, lastname and email.
     */
    @isTest
    static void testPaymentIntentCallwithoutContactId() {
        FinDockPaymentAPI_CreateIntent.PaymentAPIRequest requestObject = new FinDockPaymentAPI_CreateIntent.PaymentAPIRequest();
        requestObject.firstName = 'test';
        requestObject.lastName = 'tester';
        requestObject.email = 'test@test.com';
        requestObject.SuccessURL = 'https://success.nl';
        requestObject.FailureURL = 'https://failed.nl';
        requestObject.selectedAmount = 20;
        requestObject.selectedPaymentMethod = 'CreditCard';

        List<FinDockPaymentAPI_CreateIntent.PaymentAPIRequest> paramList = new List<FinDockPaymentAPI_CreateIntent.PaymentAPIRequest>();
        paramList.add(requestObject);

        Test.startTest();
        List<String> responseList = FinDockPaymentAPI_CreateIntent.startPaymentFlow(paramList);
        Test.stopTest();
        
        if(responseList.size() > 0) {
            System.assertNotEquals(null, responseList[0], 'No RedirectURL found.');
        } else {
            System.assert(false);
        }
        
        Contact testContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email = 'test@test.com' LIMIT 1];
        System.assertEquals('tester', testContact.LastName);
    }
}
