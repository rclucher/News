@IsTest
public with sharing class NXX2_LightningLoginFormControllerTest {
    
    @IsTest
    static void testLoginWithInvalidCredentials() {
        System.assertEquals('There is no any portal user related to this email address!', NXX2_LightningLoginFormController.login('testUser', 'fakepwd', null));
    }
    
    @IsTest
    static void LightningLoginFormControllerInstantiation() {
        NXX2_LightningLoginFormController controller = new NXX2_LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }
    
    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, NXX2_LightningLoginFormController.getIsUsernamePasswordEnabled());
    }
    
    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, NXX2_LightningLoginFormController.getIsSelfRegistrationEnabled());
    }
    
    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, NXX2_LightningLoginFormController.getSelfRegistrationUrl());
    }
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = NXX2_LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
    @IsTest
    static void remainingMethodsTest() {
        String url = NXX2_LightningLoginFormController.getForgotPasswordUrl();
        System.assertNotEquals(null, url);
        NXX2_LightningLoginFormController.setExperienceId(null);
        NXX2_LightningLoginFormController.setExperienceId('test');
    }
}