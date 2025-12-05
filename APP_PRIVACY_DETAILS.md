# App Privacy Details for App Store Connect

This document provides information to help you complete the App Privacy questionnaire in App Store Connect.

## Data Collection Summary

### Data Collected and Linked to User Identity

#### 1. Contact Information
- **Email Address**: Collected via Google Sign-In
- **Name**: Collected via Google Sign-In
- **Purpose**: 
  - App Functionality (user authentication)
  - Product Personalization (personalized experience)
- **Linked to User**: Yes
- **Used for Tracking**: No

### Data Collected but NOT Linked to User Identity

#### 2. Identifiers
- **Device ID**: Collected by Google Mobile Ads SDK
- **Purpose**: 
  - Analytics
  - Advertising
- **Linked to User**: No
- **Used for Tracking**: Yes (for personalized ads)

#### 3. Usage Data
- **Product Interaction**: App usage data (which features are used)
- **Purpose**: 
  - Analytics
  - App Functionality
- **Linked to User**: No
- **Used for Tracking**: No

#### 4. Advertising Data
- **Advertising Data**: Ad interaction data
- **Purpose**: Advertising
- **Linked to User**: No
- **Used for Tracking**: Yes

## Third-Party SDKs and Their Data Practices

### 1. Google Mobile Ads SDK
- **Purpose**: Display advertisements
- **Data Collected**: Device identifiers, ad interaction data
- **Privacy Policy**: https://policies.google.com/privacy

### 2. Firebase SDK (Auth, Core)
- **Purpose**: User authentication, app analytics
- **Data Collected**: Email, name, app usage data
- **Privacy Policy**: https://firebase.google.com/support/privacy

### 3. Google Sign-In SDK
- **Purpose**: User authentication
- **Data Collected**: Email address, name, profile picture
- **Privacy Policy**: https://policies.google.com/privacy

## App Store Connect Privacy Questionnaire Answers

### Does your app collect data?
**Answer**: Yes

### Data Types Collected

#### Contact Info
- [x] Email Address
  - Linked to user: Yes
  - Used for tracking: No
  - Purposes: App Functionality, Product Personalization

- [x] Name
  - Linked to user: Yes
  - Used for tracking: No
  - Purposes: App Functionality

#### Identifiers
- [x] Device ID
  - Linked to user: No
  - Used for tracking: Yes
  - Purposes: Analytics, Advertising

#### Usage Data
- [x] Product Interaction
  - Linked to user: No
  - Used for tracking: No
  - Purposes: Analytics, App Functionality

#### Other Data
- [x] Advertising Data
  - Linked to user: No
  - Used for tracking: Yes
  - Purposes: Advertising

### Do you or your third-party partners use data for tracking purposes?
**Answer**: Yes

**Explanation**: The app uses Google Mobile Ads SDK which may use device identifiers for personalized advertising purposes.

### Privacy Policy URL
**Required**: You must provide a privacy policy URL in App Store Connect.

**Recommended Content**:
- What data is collected
- How data is used
- How data is shared with third parties (Google)
- User rights and choices
- Contact information

## Additional Notes

### App Tracking Transparency (ATT)
The app includes `NSUserTrackingUsageDescription` in Info.plist and will request user permission before tracking (required for iOS 14.5+).

### Privacy Manifest
The app includes a Privacy Manifest file (`PrivacyInfo.xcprivacy`) as required by Apple for apps using third-party SDKs.

### Data Retention
- User authentication data: Retained while user account is active
- Analytics data: Retained according to Google's data retention policies
- Advertising data: Retained according to Google's advertising policies

### User Control
Users can:
- Sign out to disconnect their account
- Disable personalized ads through iOS Settings > Privacy > Tracking
- Request data deletion by contacting app support

## Before Submission Checklist

- [ ] Create and host a privacy policy webpage
- [ ] Add privacy policy URL to App Store Connect
- [ ] Complete privacy questionnaire in App Store Connect using this document
- [ ] Verify all privacy labels are accurate
- [ ] Test App Tracking Transparency prompt on iOS 14.5+
- [ ] Replace test AdMob ID with production ID
- [ ] Ensure Privacy Manifest is included in build
