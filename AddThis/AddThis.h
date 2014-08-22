//
//  AddThisSDK.h
//  AddThis
//
//  Created by AddThis on 11/08/10.
//  Copyright 2010 AddThis LLC. All rights reserved.
//

#define ADDTHIS_VERSION @"0.3.0"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

//	Status codes used
typedef enum {
	ATStatusCode_Success = 100,
	ATStatusCode_Error = 400,
	ATStatusCode_NetWorkError = 401,
	ATStatusCode_ImageNotFound = 402,
	ATStatusCode_ImageShareNotSupported = 403,
	ATStatusCode_BlackListedService = 310
}ATStatusCode;

//Facebook authentication type
typedef enum {
	ATFacebookAuthenticationTypeDefault=0, //uses the default authentication method provided by addthis
	ATFacebookAuthenticationTypeFBConnect=1 //uses facebook connect.
}ATFacebookAuthenticationType;


//Twitter authentication type
typedef enum {
	ATTwitterAuthenticationTypeDefault=0, //uses the default authentication method provided by addthis
	ATTwitterAuthenticationTypeOAuth=1 //uses OAuth for twitter. 
}ATTwitterAuthenticationType;


@interface AddThisSDK : NSObject 

#pragma mark -
#pragma mark Developer APIs

#pragma mark URL sharing

//shows an AddThis custom button for share-url |url|
//
//|parentView| -- view in which the button is to be placed
//|buttonframe| -- the size and postion of button in |parentView|
//|url| -- the url to share
//|title| -- the title of the url
//|description| -- the description of the url
//
+ (UIButton *)showAddThisButtonInView:(UIView *)parentView 
							withFrame:(CGRect) buttonFrame
							   forURL:(NSString *)url
							withTitle:(NSString *)title
						  description:(NSString *)description;

//shows an AddThis menu for share-url |url|
//
//|url| -- the url to share
//|title| -- the title of the url
//|description| -- the description of the url
//
+ (void)presentAddThisMenuForURL:(NSString *)url 
					   withTitle:(NSString *)title 
					 description:(NSString *)description;

//shows an AddThis menu for share-url |url| in popover
//This API works only for iPads
//
//|url| -- the url to share
//|rect| -- the rect from where the popover should be shown
//|title| -- the title of the url
//|description| -- the description of the url
//
//
+ (void)presentAddThisMenuInPopoverForURL:(NSString *)url 
								 fromRect:(CGRect)rect 
								withTitle:(NSString *)title 
							  description:(NSString *)description;


//Opens directly to service login page
//
//|url| -- the url to share
//|serviceCode| -- the service to which url is shared
//|title| -- the title of the url
//|description| -- the description of the url
//Returns the status of the method call as NSDictionary
//
+ (NSDictionary *)shareURL:(NSString *)url 
			   withService:(NSString *)serviceCode 
					 title:(NSString *)title 
			   description:(NSString *)description;


#pragma mark Image Sharing

//Shows an AddThis custom button for share-image |image|
//
//|parentView| -- view in which the button is to be placed
//|buttonframe| -- the size and postion of button in |parentView|
//|image| -- the image to share
//|title| -- the title of the image
//|description| -- the description of the image
//
+ (UIButton *)showAddThisButtonInView:(UIView *)parentView 
							withFrame:(CGRect) buttonFrame
							 forImage:(UIImage *)image 
							withTitle:(NSString *)title
						  description:(NSString *)description;

//Shows an AddThis menu for share-image |image|
//
//|image| -- the image to share
//|title| -- the title of the image
//|description| -- the description of the image
//
+ (void)presentAddThisMenuForImage:(UIImage *)image 
						 withTitle:(NSString *)title 
					   description:(NSString *)description;

//Shows an AddThis menu for share-image |image| in popover
//This API works only for iPads
//
//|image| -- the image to share
//|rect| -- the rect from where the popover should be shown
//|title| -- the title of the image
//|description| -- the description of the image
//
+ (void)presentAddThisMenuInPopoverForImage:(UIImage *)image 
								   fromRect:(CGRect)rect 
								  withTitle:(NSString *)title 
								description:(NSString *)description;

//Opens directly to service login page
//
//|image| -- the image to share
//|serviceCode| -- the service to which image is shared
//|title| -- the title of the image
//|description| -- the description of the image
//
+ (NSDictionary *)shareImage:(UIImage *)image 
	 withService:(NSString *)serviceCode 
		   title:(NSString *)title 
	 description:(NSString *)description;


//Returns all the services in an array of dictionary
//The dictionary contains keys : Name, ServiceCode and ImageData
//
+ (NSArray *)getAllServices;

//Updates and synchronize the local database with the server
//
+ (void)updateServiceList;

//Sets automatic updation of icons
//
+ (void)enableAutomaticUpdate:(BOOL)enable;

//Sets the text to be used with 'via' in Twitter posts
//
+ (void)setTwitterViaText:(NSString *)text;

//Set the root view controller from where you wants to 
//present the AddThis menu
+ (void)setRootViewController:(UIViewController *)rootViewController;

#pragma mark -
#pragma mark Advanced UI Settings

//	Set the black list of services. These services will not be shown in share menus and 
//	direct sharing to these services will not be available.
//
+ (void)setBlackListedServices:(NSString *)firstObject, ...;

+ (void)setBlackListedServicesWithArray:(NSArray *)services;

//	Set the favorite menu with the given set of services 
//
+ (void)setFavoriteMenuServices:(NSString *)firstObject, ...;

+ (void)setFavoriteMenuServicesWithArray:(NSArray *)services;

/*------------------------------- Editting Service Menu -----------------------------*/

//Give privilege to user to edit the favourite share menu
//Default value is 'YES'
//
+ (void)canUserEditServiceMenu:(BOOL)canEdit;

//Give privilege to user to move the favourite share menu items
//Default value is 'YES'
//
+ (void)canUserReOrderServiceMenu:(BOOL)canMove;

//Assign the table style
//
+ (void)setTableStyle:(UITableViewStyle)style;

// Give the value to NO if you dont want to show the "More" services
// menu
//
+(void)shouldShowMoreView:(BOOL)show;

/*------------------------------- Configure Menu Cell -----------------------------*/

//Assign the alignment of the text in menu cell. Default is UITextAlignment.
//
+ (void)setMenuCellTextAlignment:(UITextAlignment)alignment;

//Assign the font used in the menu 
//
+ (void)setMenuFont:(UIFont *)font;

//Assign the text color of table contents
//
+ (void)setMenuTextColor:(UIColor *)color;

//Assign color to the cell border in menu
//
+ (void)setMenuCellBorderColor:(UIColor *)color;

//Assign the height of menu cell
+ (void)setMenuCellHeight:(float)height;

/*------------------------------- UI color settings -----------------------------*/

//Assign the navigationbars tint color 
//
+ (void)setNavigationBarColor:(UIColor *)color;

//Assign the search bar color 
//
+ (void)setSearchBarColor:(UIColor *)color;

//Assign the tool bar color 
//
+ (void)setToolBarColor:(UIColor *)color;

//Assign the cell color of table
//
+ (void)setMenuBackground:(UIColor *)color;

/*------------------------------- UI presentation settings -----------------------------*/

//Assign modal presentation style for iPad.
//setting this will have no effect if you are deploying it on iPhone
//
+ (void)setModalPresentationStyle:(UIModalPresentationStyle)presentationStyle;

//Assign modal transition style
+ (void)setModalTransitionStyle:(UIModalTransitionStyle)transitionStyle;

//Give NO if your app does not support autorotate.
//Default value is YES. If you give NO, you should also set the orientation in
//setInterfaceOrientation: method
//
+ (void)shouldAutoRotate:(BOOL)shouldRotate;

//Assign interface orientation if auto rotate is not enabled.
//
+ (void)setInterfaceOrientation:(UIInterfaceOrientation)interface;

#pragma mark -
#pragma mark Advanced Share Settings

//Logout from the particular service 
+ (void)logout:(NSString *)serviceCode;


//Logout all non-OExchange services 
+ (void)logoutAll;

//Defines the type of Facebook Authentication 
//See ATFacebookAuthenticationType for possible values. The default value is ATFacebookAuthenticationTypeDefault.
//
+ (void)setFacebookAuthenticationMode:(ATFacebookAuthenticationType)type;

//Follow the steps located at http://www.facebook.com/developers/createapp.php to get a Facebook API key
//
+ (void)setFacebookAPIKey:(NSString *)APIKey;

//Defines the type of Twitter Authentication 
//See ATTwitterAuthenticationType for possible values. The default value is ATTwitterAuthenticationTypeDefault.
//
+ (void)setTwitterAuthenticationMode:(ATTwitterAuthenticationType)type;

//Follow the steps at http://dev.twitter.com/apps/new to get the keys and to set the callback URL.
//You should select ‘browser’ as the application type when asked. 
//
+ (void)setTwitterConsumerKey:(NSString *)consumerKey;

+ (void)setTwitterConsumerSecret:(NSString *)consumerSecret;

//The callback URL doesn’t need to be an existing URL, but it should be entered.
//
+ (void)setTwitterCallBackURL:(NSString *)callBackURL;

//The api key for twitpic, set this value if you need image sharing through twitter
//Follow the steps at : http://dev.twitpic.com/
//
+ (void)setTwitPicAPIKey:(NSString *)APIKey;

//Set the username for analytics. Create an account at http://www.addthis.com
//
+ (void)setAddThisUserName:(NSString *)username;

//Set the pubid for analytics.
+ (void)setAddThisPubId:(NSString *)pubid;

//To get an AddThis application ID, go to  http://www.addthis.com/settings/applications and
//register each of your applications
+ (void)setAddThisApplicationId:(NSString *)applicationId;

//Set the delegate to get callback
+ (void)setDelegate:(id)delegate;

@end
