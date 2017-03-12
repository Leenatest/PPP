//**************************************************************************/
// (c) 2013 Appirio, Inc.
//
// Description : Test class for AccountManagement.
//                  
// Original August 26, 2013  : KapiL Choudhary(JDC) Created for the Task T-175201
// Updated :
//			August 30, 2013  KapiL Choudhary(JDC): Updated for the Task T-179024
//          Sep    20 2013   Urminder(JDC) Updated with TestMockUp
// ***************************************************************************/

@isTest
global class AccountManagement_Test {
	
	static testMethod void accountManagementUnitTest() {
		//list<Address__c>addressList    = TestClassUtility.createAddress(2, true);
	    list<Account>personAccountList = TestClassUtility.createPersonAccount(1, true);
	    list<contact> lstcontact = [select id from contact where accountid in:personAccountList limit 1];
	    List<Address__c> pesronAddressList = TestClassUtility.createAddress(1, false);
	    Integer indx = 0;
	    for(Address__c add :pesronAddressList){
	    	add.Consumer__c = lstcontact[0].id;
	    }
	    insert pesronAddressList;
	     personAccountList[0].Phone = null;
	     personAccountList[0].Alt_Phone__pc = '666555888';
	     personAccountList[0].Bill_To__pc = pesronAddressList[0].id;
	     personAccountList[0].Ship_To__pc = pesronAddressList[0].id;
	     
		Test.startTest();
    	Test.setMock(WebServiceMock.class, new WebServiceMockUpdateConsumer());
		
	    
	    if(/*(!addressList.isEmpty())&& */(!personAccountList.isEmpty())){
	    	/*personAccountList[0].Bill_To__pc = addressList[0].id;
	    	personAccountList[0].Ship_To__pc = addressList[1].id;*/
	    	personAccountList[0].MDM_ID__pc =  personAccountList[0].MDM_ID__c;
	    	personAccountList[0].PersonEmail = 'Updated@test.com';
	    	update personAccountList;
	    	
	    	//All address fields must copied in to account's address fields.
	    	//system.assertEquals(addressList[0].Postal_Code__c, [select PersonOtherPostalCode from account where id=:personAccountList[0].id].get(0).PersonOtherPostalCode);
	    	
	    	// Must Creates a recod in Staging_Contact__c with MDM_ID__c Id.
        	system.assertEquals(1, [select id from Staging_Contact__c where MDM_Contact_ID__c =: personAccountList[0].MDM_ID__c].size());
        	Test.stopTest();	
	    }
	}
	global class WebServiceMockUpdateConsumer implements WebServiceMock {
	   global void doInvoke(
	           Object stub,
	           Object request,
	           Map<String, Object> response,	
	           String endpoint,
	           String soapAction,
	           String requestName,
	           String responseNS,
	           String responseName,
	           String responseType) {
	      		Sony_MiddlewareUpdateconsumer_Final.PSUpdateConsumer_Output_element responseElm = 
	      		  	new Sony_MiddlewareUpdateconsumer_Final.PSUpdateConsumer_Output_element();
	       		
	       		
				responseElm.Message = 'Updated SucessFully';
			    responseElm.Status = 'Sucess'; 
	       		response.put('response_x', responseElm); 
	   		   }
    }
    
}