/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class AgentTimeTest {

    static testMethod void trackTimeTest() {
        // TO DO: implement unit test
        //User usr = new User();
        //insert usr;
        Datetime CurrentTimeOld =  System.now();
        StateValues sv = new StateValues();
        List<SelectOption> soTestList = sv.getStatusOptions();
        sv.save();        
        sv.selectedCountry2='Break';
        sv.UpdateRecord();
        sv.save();
        sv.save();        
        sv.selectedCountry2='Meal';
        sv.UpdateRecord();
        sv.save();
        sv.save();        
        sv.selectedCountry2='Admin';
        sv.UpdateRecord();
        sv.save();
        system.assert(soTestList.size() > 0);
        Datetime CurrentTimeNew =  System.now();
        LiveAgentSession las = new LiveAgentSession(AgentId=UserInfo.GetUserId(),LogoutTime=CurrentTimeNew,LoginTime=CurrentTimeOld,TimeInAwayStatus=1000);
        insert las;
    }
}