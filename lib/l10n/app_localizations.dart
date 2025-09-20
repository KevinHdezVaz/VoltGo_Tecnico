import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

static final Map<String, Map<String, String>> localizedValues = {
    'en': {
      'appTitle': 'VoltGo',
      'searchingTechnician': 'Searching for technician',
      'technicianArriving': 'Technician arriving in',
      'voltgoTechnician': 'VoltGo Driver',
      'tyc' : 'Terms and Conditions',
    'newRequest': 'NEW REQUEST',
    'earnings': 'EARNINGS',
    'distance': 'DISTANCE',
    'estimatedTime': 'EST. TIME',
    'client': 'Client',
    'verified': 'Verified',
    'serviceLocation': 'Service location',
    'serviceDetails': 'Service Details',
'completed': 'Completed',
'cancelled': 'Cancelled',
'pending': 'Pending',
'inProgress': 'In Progress',
'errorLoadingDetails': 'Error loading details',
'retry': 'Retry',
'additionalDetailsNotAvailable': 'Additional details not available',
'technicalDetailsWillBeAdded': 'Technical details of the service will be added by the technician during or after the service.',
'serviceInformation': 'Service Information',
'date': 'Date',
'time': 'Time',
'status': 'Status',
'serviceId': 'Service ID',
'serviceTimeline': 'Service Timeline',
'started': 'Started',
'batteryInformation': 'Battery Information',
'initialLevel': 'Initial Level',
'chargeTime': 'Charge Time',
'serviceNotes': 'Service Notes',
'servicePhotos': 'Service Photos',
'vehicle': 'Vehicle',
'before': 'Before',
'after': 'After',
'error': 'Error',
'loading': 'Loading',
'errorLoadingImage': 'Error loading image',
'paymentInformation': 'Payment Information',
'totalCost': 'Total Cost:',
    'reject': 'Reject',
    'accept': 'Accept',
    'veryClose': 'Very close',
    'close': 'Close',
    'mediumDistance': 'Medium distance',
    'far': 'Far',
    'minutes': 'min',
    'hours': 'h',
      'newRequest': 'New Request',
      'waitingForRequests': 'Waiting for new requests',
      'reviewingIncomingRequest': 'Reviewing incoming request',
      'headToClientLocation': 'Head to client location',
      'chargingClientVehicle': 'Charging client vehicle',
'navigateToClient': 'Navigate to Client',
      'technician': 'Technician',
      'client': 'Client',
      'navigate': 'Navigate',
      'startCharging': 'Start Charging',
      'charging': 'Charging',
      'batteryLevel': 'Initial Battery Level (%)',
      'chargingTime': 'Charging Time (minutes)',
      'addComment': 'Additional Notes',
      'describeService': 'Describe the service...',
      'serviceCompleted': 'Complete Service',
      'technicianOnSite': 'On-Site Service',
      'chargeServiceRequested': 'Electric Charging Service',
      'onSite': 'ON SITE',
      'serviceProgress': 'Service Progress',
      'serviceInitiatedTitle': 'Start Charging Service',
      'timeElapsed': 'Time elapsed',
      'technicianWillDocumentProgress': 'Photo Documentation',
      'serviceVehicle': 'Vehicle Photo',
      'vehicleNeeded': 'Capture a photo of the client\'s vehicle',
      'initial': 'Before Charging',
      'serviceCompletedTitle': 'After Charging',
      'vehicleRegisteredSuccess': 'Photo saved on server',
      'serviceInformation': 'Service Details',
      'processing': 'Completing...',
      'technicianArrivedMessage': 'Technician arrived at the client\'s site',
      'serviceInitiatedMessage': 'Charging service started',
      'errorChangingStatus': 'Error updating service status',
      'errorLoadingData': 'Error loading photo',
      'serviceCompletedSuccessfully': 'Service completed successfully',
      'serviceCompletedMessage': 'The charging service has been successfully completed.',
      'thankYouForYourRating': 'The client will receive a notification and can rate your service.',
      'continueText': 'Continue',
      'couldNotOpenPhoneApp': 'Could not open the phone app',
      'errorMakingCall': 'Error attempting to call',
      'noPhoneNumberAvailable': 'No phone number available',
      'min': 'minutes',
      // ===== Service Request Panel (FALTANTES) =====
      'newChargeRequest': 'NEW CHARGE REQUEST',
          'questionsContact': 'If you have questions about these terms, contact us at:',

       'estimatedEarnings': 'Estimated earnings',
      'reject': 'Reject',
      'accept': 'Accept',
      'searchingRequests': 'Searching requests',
      'enRouteToClient': 'EN ROUTE TO CLIENT',
      'serviceInProgressPanel': 'Service in progress',
      'loadingEarningsError': 'Error loading earnings data',
      'logout': 'Logout',
      'logoutConfirmationMessage': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'settings': 'Settings',
      'error': 'Error',
      'couldNotLoadProfile': 'Could not load profile',
      'account': 'Account',
      'editProfile': 'Edit Profile',
      'securityAndPassword': 'Security and Password',
      'chatHistory': 'Messages',
      'paymentMethods': 'Payment Methods',
      'vehicle': 'Vehicle',
      'manageVehicles': 'Manage Vehicles',
      'documents': 'Documents',
      'logoutError': 'Error logging out. Please try again.',
      'myEarnings': 'My Earnings',
      'today': 'Today',
      'week': 'Week',
      'history': 'History',
      'withdrawFunds': 'Withdraw Funds',
      'availableBalance': 'Available Balance',
      'withdrawalAmount': 'Withdrawal Amount',
      'minimumWithdrawal': 'Minimum \$10.00',
      'paymentMethod': 'Payment Method',
      'bankTransfer': 'Bank Transfer',
      'debitCard': 'Debit Card',
      'confirmWithdrawal': 'Confirm Withdrawal',
      'minimumWithdrawalError': 'The minimum withdrawal amount is \$10.00',
      'insufficientBalance': 'Insufficient balance',
      'withdrawalSuccess': 'Withdrawal processed successfully',
      'withdrawalError': 'Error processing withdrawal',
      'todaySummary': 'Today Summary',
      'earnings': 'Earnings',
      'services': 'Services',
      'tips': 'Tips',
      'distance': 'Distance',
      'rating': 'Rating',
       'termsAndConditions': 'Terms and Conditions',
"chatWith": "Chat with {name}",
"serviceNumber": "Service #{id}",
"loadingMessages": "Loading messages...",
"errorLoadingChat": "Error loading chat",
"tryAgain": "Try again",
"startConversation": "Start the conversation",
"communicateWithTechnician": "Communicate with your technician to coordinate the service",
"communicateWithClient": "Communicate with the client to coordinate the service",
"writeMessage": "Write a message...",
"sending": "Sending...",
"errorSendingMessage": "Error sending message: {error}",
"updateMessages": "Update messages",

// Service status
"statusPending": "Client assigned",
"statusAccepted": "Client assigned",
"statusEnRoute": "Technician on the way",
"statusOnSite": "Technician on site",
"statusCharging": "Charging vehicle",
"statusCompleted": "Service completed",
"statusCancelled": "Service cancelled",
         'privacyPolicy': 'Privacy Policy',
    'dataCollection': '1. Information We Collect',
    'dataCollectionContent': 'Here will go the text about what personal data VoltGo collects, including profile information, location and app usage.',
    'dataUsage': '2. How We Use Your Information',
    'dataUsageContent': 'Here will go the text about how VoltGo uses collected data to provide services, improve experience and communicate with users.',
    'locationData': '3. Location Data',
    'locationDataContent': 'Here will go the text about how VoltGo collects and uses location data to connect users with nearby technicians.',
    'dataSharing': '4. Information Sharing',
    'dataSharingContent': 'Here will go the text about when and with whom VoltGo may share users\' personal information.',
    'dataSecurity': '5. Data Security',
    'dataSecurityContent': 'Here will go the text about security measures implemented to protect users\' personal information.',
    'userRights': '6. User Rights',
    'userRightsContent': 'Here will go the text about users\' rights regarding their personal data, including access, correction and deletion.',
    'cookies': '7. Cookies and Similar Technologies',
    'cookiesContent': 'Here will go the text about the use of cookies and other tracking technologies in VoltGo app.',
    'thirdPartyServices': '8. Third-Party Services',
    'thirdPartyServicesContent': 'Here will go the text about third-party services integrated in VoltGo and their privacy policies.',
    'dataRetention': '9. Data Retention',
    'dataRetentionContent': 'Here will go the text about how long VoltGo retains users\' personal data.',
    'minorPrivacy': '10. Children\'s Privacy',
    'minorPrivacyContent': 'Here will go the text about special privacy policies for underage users.',
    'privacyQuestions': 'For privacy questions, contact us at:',
    'lastUpdated': 'Last updated: January 2025',
    'acceptance': '1. Acceptance of Terms',
    'acceptanceContent': 'Here will go the text about acceptance of VoltGo app terms and conditions.',
    'serviceDescription': '2. Service Description',
    'serviceDescriptionContent': 'Here will go the text describing VoltGo services, including electric vehicle charging and technical assistance.',
    'userResponsibilities': '3. User Responsibilities',
    'userResponsibilitiesContent': 'Here will go the text about user responsibilities and obligations when using VoltGo platform.',
    'technicianObligations': '4. Technician Obligations',
    'technicianObligationsContent': 'Here will go the text about obligations and responsibilities of registered technicians on the platform.',
    'paymentTerms': '5. Payment Terms',
    'paymentTermsContent': 'Here will go the text about payment terms, billing and refund policies.',
    'limitation': '6. Limitation of Liability',
    'limitationContent': 'Here will go the text about VoltGo liability limitations regarding damages or inconveniences.',
    'modifications': '7. Modifications',
    'modificationsContent': 'Here will go the text about how and when VoltGo can modify these terms and conditions.',
    'contactUs': 'Contact Us',
      'thisWeek': 'This Week',
      'thisMonth': 'This Month',
      'totalEarned': 'Total Earned',
      'pending': 'Pending',
      'noRecentServices': 'No recent services',
      'recentActivity': 'Recent Activity',
      'realTimeTracking': 'REAL-TIME TRACKING',
      'serviceHistory': 'Service History',
      'reviewPreviousServices': 'Review your previous services',
      'all': 'All',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
      'errorLoadingHistory': 'Error loading history',
      'retry': 'Retry',
      'noServiceHistory': 'You have no services in your history.',
      'requestService': 'Request Service',
      // ===== Navigation Texts (FALTANTES) =====
      'navigateToClient': 'Navigate to client',
      'openInMaps': 'Open in Maps',
      'googleMaps': 'Google Maps',
      'navigationWithTraffic': 'Navigation with real-time traffic',
      'waze': 'Waze',
      'optimizedRoutes': 'Optimized routes and community alerts',
      'navigate': 'NAVIGATE',
      'call': 'Call',
'editProfile': 'Edit Profile',
    'save': 'Save',
    'loading': 'Loading...',
    'technician': 'Certified Technician',
    'contactInformation': 'Contact Information',
    'phoneNumber': 'Phone Number',
    'fieldRequired': 'This field is required',
    'phoneMinLength': 'Phone number must have at least 10 digits',
    'professionalInformation': 'Professional Information',
    'baseLocation': 'Base Location',
    'licenseNumber': 'License Number (optional)',
    'servicesOffered': 'Services Offered',
    'selectServices': 'Select the services you offer:',
    'selectAtLeastOneService': 'Select at least one service',
    'identificationDocument': 'Identification Document',
    'documentSelected': 'Document selected',
    'remove': 'Remove',
     'otros': 'Others',
            'politicadeprivacidad': 'Privacy Policy',
    'uploadDocument': 'Upload Document',
    'changeDocument': 'Change Document',
    'documentInfo': 'Supported formats: JPG, PNG (max. 5MB)',
    'saveChanges': 'Save Changes',
    'noChanges': 'No Changes',
    'profileUpdated': 'Profile Updated',
    'profileUpdatedSuccessfully': 'Your profile has been updated successfully.',
    'accept': 'Accept',
    'error': 'Error',
    'unsavedChanges': 'Unsaved Changes',
    'discardChanges': 'Do you want to discard the changes made?',
    'cancel': 'Cancel',
    'discard': 'Discard',
      // ===== Service Panel States (FALTANTES) =====
      'arrivedAtSite': 'I HAVE ARRIVED AT SITE',
      'finishService': 'FINISH SERVICE',
 
      // ===== Success & Error Messages (FALTANTES) =====
      'requestAccepted': 'Request accepted! Head to the client.',
      'errorAcceptingRequest': 'Error accepting request',
      'requestTakenByAnother': 'This request was taken by another technician',
      'noAuthorizationForRequest': 'You have no authorization for this request',
       'pleaseEnableLocation': 'Please enable location service.',
      'locationPermissionRequired':
          'Location permission is required to operate.',
      'noClientInformationAvailable': 'No client information available', 
      'couldNotOpenGoogleMaps': 'Could not open Google Maps',
      'wazeNotInstalled': 'Waze is not installed on your device',
      'couldNotOpenWaze': 'Could not open Waze',
      'noNavigationAppsAvailable': 'No navigation apps available',
      'couldNotOpenNavigationApp': 'Could not open any navigation app',
      'requestNoLongerAvailable': 'This request is no longer available',
      'clientCancelledRequest': 'The client cancelled the request',
      'errorCheckingStatus': 'Error checking status',
      'requestNotAuthorizedAnymore':
          'Request no longer available for this technician',
      'loggingOut': 'Logging Out',
      // ===== Online/Offline Status (FALTANTES) =====
      'online': 'ONLINE',
      'offline': 'OFFLINE',
      'serviceActive': 'SERVICE ACTIVE',
      'disconnected': 'DISCONNECTED',
'loadingInformation': 'Loading information...',
    'errorMessage': 'Error: {error}',
     'basicInformation': 'Basic Information',
    'identification': 'Identification',
    'technicalSpecifications': 'Technical Specifications',
    'brandHint': 'E.g., Tesla, Nissan',
    'modelExampleHint': 'E.g., Model 3, Leaf',
    'yearHint': 'E.g., 2024',
    'plateExampleHint': 'E.g., ABC-123',
    'requiredField': 'This field is required',
    'updateSuccessful': 'Update Successful!',
    'vehicleUpdateSuccessMessage': 'Your vehicle information has been updated successfully.',
    'continueButton': 'Continue',
      // ===== Service Cancellation Dialog (FALTANTES) =====
      'serviceCancelledTitle': 'Service Cancelled',
      'clientCancelledService': 'The client has cancelled the service.',
      'timeCompensation': 'Time compensation',
      'partialCompensationMessage':
          'You will receive partial compensation for the time invested in this service.',
      'willContinueReceivingRequests':
          'You will continue receiving new requests automatically.',
      'serviceCancelledByClient': 'Service cancelled by client',
'myRatings': 'My Ratings',
    'summary': 'Summary',
    'allReviews': 'All Reviews',
    'ratingDistribution': 'Rating Distribution',
    'recentReviews': 'Recent Reviews',
    'viewAll': 'View All',
    'noReviewsYet': 'No reviews yet',
    'completeServices': 'Complete more services to receive ratings from your clients',
    'errorLoadingReviews': 'Error loading reviews: {error}',
    'reviewsCount': '{count} reviews',
      // ===== Service Expiration (FALTANTE) =====
      'serviceAutoCancelledAfterHour':
          'Your service has been automatically cancelled after 1 hour.',
'yourRating': 'Your Rating',
    'averageRating': 'Average of all your ratings',
      'noActiveServiceFound': 'No active service found',
      'serviceTrackingLocation': 'Tracking location every 30 seconds...',
      'locationTrackingStopped': 'Location tracking stopped.',
      'requestListCleaned': 'Unavailable requests list cleaned',
      'minutes': 'minutes',
       'technicianArrivedTitle': 'You have arrived!',
       'contactTechnician': 'Contact the client to coordinate the charging service.',
       'time': 'Time',
       'speed': 'Speed',
       'chat': 'Message',
      'pleaseWaitMoment': 'Setting up navigation...', 
      'errorRefreshingServiceData': 'Error refreshing service data',
      'technicianOnWay': 'You are very close to the client',
      'technicianEnRoute': 'You are approaching the destination',
      'estimated': 'Estimated',
      'arrival': 'Arrival',
      'connector': 'Connector',
      'estimatedTime': 'Estimated time',
      'estimatedCost': 'Estimated cost',
      'cancelSearch': 'Cancel search',
      'technicianConfirmed': 'Technician confirmed',
      'serviceInProgress': 'Service in progress',
      'chargingVehicle': 'Charging your vehicle',
      'requestCharge': 'Request Charge',
      'viewActiveService': 'View Active Service',
      'youHaveActiveService': 'You have an active service',
      'tapToFindTechnician': 'Tap to find a technician',
      'cancelService': 'Cancel Service',
      'followRealTime': 'Follow in real time',
       'howWasExperience': 'How was your experience?',
       'skip': 'Skip',
      'send': 'Send',
      'locationRequired': 'Location Required',
      'locationNeeded':
          'To request a service we need access to your location. Please enable location services.',
      'activate': 'Activate',
      'permissionDenied': 'Permission Denied',
      'cannotContinue':
          'We cannot continue without access to your location. Please grant the necessary permissions in the app settings.',
      'goToSettings': 'Go to Settings',
      'vehicleRegistration': 'Vehicle Registration', 
      'whyNeeded': 'Why is it necessary?',
      'whyNeededDetails': '• Identify the required connector type\n'
          '• Calculate accurate charging times\n'
          '• Assign specialized technicians\n'
          '• Provide the best personalized service',
      'registerVehicle': 'Register Vehicle',
      'activeService': 'Active Service',
      'youHaveActiveServiceDialog': 'You already have an active service:',
      'request': 'Request',
      'status': 'Status',
      'requested': 'Requested',
      'whatToDo': 'What would you like to do?',
      'viewService': 'View Service',
      'timeExpired': 'Time Expired',
      'cannotCancelNow': 'It is no longer possible to cancel this service.',
      'technicianOnWay':
          'The technician is already on the way to your location. Please wait for their arrival.',
      'understood': 'Understood',
      'cancellationFee': 'Cancellation fee',
      'feeApplied':
          'A fee of \${fee} will be applied because the technician was already assigned to the service.',
      'technicianAssigned': 'Technician Assigned!',
      'technicianAccepted':
          'A technician has accepted your request and is on the way.',
      'seeProgress': 'You can see the technician\'s progress on the map.',
      'serviceExpired': 'Service Expired',
      'serviceAutoCancelled': 'Your service has been automatically cancelled.',
      'timeLimitExceeded': 'Time limit exceeded',
      'serviceActiveHour':
          'The service has been active for more than 1 hour without being completed. For your protection, we have automatically cancelled it.',
      'noChargesApplied': 'No charges applied',
      'requestNew': 'Request New',
      'technicianCancelled': 'Technician Cancelled',
      'technicianHasCancelled': 'The technician has cancelled the service.',
      'dontWorry': 'Don\'t worry',
      'technicianCancellationReason':
          'This can happen due to emergencies or technical issues. No charges will be applied to you.',
      'nextStep': 'Next step',
      'requestImmediately':
          'You can request a new service immediately. We will connect you with another available technician.',
      'findAnotherTechnician': 'Find Another Technician',
      'timeWarning': 'Time Warning',
      'serviceWillExpire': 'The service will expire in',
      'viewDetails': 'View Details',
      'finalWarning': 'Final Warning!',
      'serviceExpireMinutes':
          'Your service will expire in {minutes} minutes and will be automatically cancelled.',
       'timeDetails': 'Time Details',
      'timeRemaining': 'Time remaining',
      'systemInfo': 'System information',
      'serviceInfo': '• Services are automatically cancelled after 1 hour\n'
          '• This protects both the customer and the technician\n'
          '• No charges are applied for automatic cancellations\n'
          '• You can request a new service immediately',

      // Additional strings used in PassengerMapScreen
      'chatWithTechnician': 'Chat with technician',
      'cancellationTimeExpired': 'Cancellation time expired',
      'serviceCancelled': 'Service Cancelled',
      'serviceCancelledSuccessfully':
          'Your service has been cancelled successfully.',
      'preparingEquipment': 'Preparing charging equipment',
       'equipmentStatus': 'Equipment status',
      'preparingCharge': 'Preparing charge',
      'notCancellable': 'Not cancellable',
      'timeToCancel': 'Time to cancel:',
      'lastMinute': 'Last minute!',
      'minutesRemaining': 'minutes remaining',
      'findingBestTechnician': 'Finding the best technician for you',
      'thankYouForUsingVoltGo': 'Thank you for using VoltGo',
      'total': 'Total',
      'close': 'Close',
      'technicianWorkingOnVehicle': 'The technician is working on your vehicle',
      'since': 'Since',
      'initial': 'Initial',
      'time': 'Time',
      'technicianPreparingEquipment':
          'The technician is preparing the equipment. The service will start soon.',
      'viewTechnicianOnSite': 'View technician on site',
      'chat': 'Chat',
      'thankYouForRating': 'Thank you for your rating!',
      'processingRequest': 'Processing request...',
      'errorLoadingMap': 'Error loading map',
      'vehicleVerification': 'Vehicle Verification',
      'checkingVehicle': 'Checking your vehicle',
      'welcomeTechnician': 'Welcome Technician.',
      'createTechnicianAccount': 'Create Your Technician Account',
      'completeTechnicianForm': 'Complete the form to get started.',
      'fullName': 'Full Name',
      'yourNameAndSurname': 'Your name and surname',
      'emailAddress': 'Email Address',
      'emailHint': 'youremail@example.com',
      'mobilePhone': 'Mobile Phone',
      'phoneNumber': 'Phone number',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'minimumCharacters': 'Minimum 8 characters',
      'baseLocation': 'Base Location',
      'selectLocationOnMap': 'Select a location on the map',

      // Optional Documentation Section
      'optionalDocumentation': 'Documentation (Optional)',
            'hoy': 'Today',

      'driverLicenseNumber': 'Driver License Number',
      'enterLicenseNumber': 'Enter your license number',
      'idPhotoOrCertification':
          'ID Photo or Certification (NOT WORKING YET, LEAVE THIS FIELD EMPTY)',
      'selectFile': 'Select file (JPG, PNG, PDF)',

      // Services Section
      'servicesOffered': 'Services you offer',
      'jumpStart': 'Jump Start',
      'evCharging': 'EV Charging',
      'tireChange': 'Tire Change',
      'lockout': 'Lockout',
      'fuelDelivery': 'Fuel Delivery',
      'other': 'Other',
      'otherService': 'Other service',
      'describeService': 'Describe the service you offer',

      // Buttons and Actions
      'createAccount': 'Create Account',
      'selectLocation': 'Select Location',
      'uploadFile': 'Upload File',

      // Messages
      'registrationSuccessful': 'Registration successful!',
      'registrationError':
          'Registration could not be completed. Check your data and try again.',
      'fileSelectionError': 'Error selecting file: ',
      'alreadyHaveAccount': 'Already have an account? ',
      'signInHere': 'Sign in here.',
      'signUpWithGoogle': 'Sign up with Google',
      'signUpWithApple': 'Sign up with Apple',
      'or': 'OR',
      'verifyingInformation': 'We are verifying your information...',
      'verificationNeeded': 'Verification Needed',
      'couldNotVerifyVehicle':
          'We could not verify if you have a registered vehicle. Please make sure you have a vehicle registered to continue.',
      'goToRegistration': 'Go to Registration',
      'syncInProgress': 'Synchronization in Progress',
      'vehicleRegisteredCorrectly':
          'Your vehicle was registered correctly, but the system is synchronizing the information.',
      'syncOptions': 'Options:',
      'syncOptionsText':
          '• Wait a few seconds and continue\n• Close and reopen the app\n• If it persists, contact support',
      'continueAnyway': 'Continue Anyway',
       'nearbyTechnicians': 'Looking for nearby technicians',
      'thisCanTakeSeconds': 'This can take a few seconds',
      'searchingDots': 'Searching technicians nearby',
       'unknownStatus': 'Unknown status',
      'fewSecondsAgo': 'A few seconds ago',
      'minutesAgo': 'minutes ago',
      'hoursAgo': 'hours ago',
      'daysAgo': 'days ago',
      'ago': 'ago',
       'notSpecified': 'Not specified',
       'errorCancellingService': 'Error cancelling service',
      'noActiveServiceToCancel': 'No active service to cancel',
      'timeElapsedMinutes': 'minutes elapsed',
      'limitMinutes': 'limit minutes',
      'cannotCancelServiceNow': 'Cannot cancel service now',
      'technicianAlreadyOnWay':
          'The technician is already on the way to your location. Please wait for their arrival.',
      'serviceCancelledWithFee': 'Service cancelled with fee',
      'serviceCancelledSuccessfullyMessage': 'Service cancelled successfully',
      'no': 'No',
      'yes': 'Yes',
      'yesCancel': 'Yes, cancel',
      'areYouSureCancelService': 'Are you sure you want to cancel the service?',
      'cancelRide': 'Cancel Service',
      'blockedFromCancelling': 'Blocked from cancelling',
      'timeForCancellingExpired': 'Time for cancelling expired',
      'serviceHasExceededTimeLimit': 'Service has exceeded the time limit',
      'serviceActiveMinutes':
          'The service has been active for {minutes} minutes. You can cancel it without charges.',
      'cancelExpiredService': 'Cancel Expired Service',
      'forceExpireService': 'Force Expire Service',
      'areYouSureCancelExpiredService':
          'Are you sure you want to cancel this service?', 
      'currentStatus': 'Current status',
      'noChargesForCancellation': 'No charges will be applied for cancellation',
      'canRequestNewServiceImmediately':
          'You can request a new service immediately',
      'yesCancelService': 'Yes, Cancel Service',
      'serviceExpiredAutomatically': 'Service expired automatically',
      'serviceActiveForHourWithoutCompletion':
          'The service has been active for more than 1 hour without being completed. For your protection, we have automatically cancelled it.',
      'noChargesAppliedForExpiredService':
          'No charges applied for expired service',
      'canRequestNewService': 'You can request a new service when you like',
      'requestNewService': 'Request New Service',
      'searchForAnotherTechnician': 'Search for Another Technician',
      'emergenciesOrTechnicalIssues':
          'This can happen due to emergencies or technical issues. No charges will be applied.',
      'canRequestNewServiceNow':
          'You can request a new service immediately. We will connect you with another available technician.',
      'ifTechnicianHasNotArrived':
          'If the technician has not arrived yet, you can contact them or wait for the system to cancel automatically at no cost.',
      'serviceDetailsInfo': 'Service Details Info',
      'serviceDetailsText':
          'Time remaining: {minutes} minutes\n\n📋 System information:\n• Services are automatically cancelled after 1 hour\n• This protects both the customer and the technician\n• No charges are applied for automatic cancellations\n• You can request a new service immediately',
      'technicianHasArrived': 'Technician has arrived!',
      'technicianAtLocationPreparingEquipment':
          'The technician is at your location preparing the charging equipment.',
      'serviceStarted': '⚡ Service Started',
      'technicianStartedChargingVehicle':
          'The technician has started charging your electric vehicle.',
      'vehicleChargedSuccessfully':
          'Your vehicle has been charged successfully! Thank you for using VoltGo.',
      'statusUpdated': 'Status Updated',
      'serviceStatusChanged': 'Your service status has changed.',
      'technicianConfirmedTitle': 'Technician Confirmed!',
      'technicianConfirmedMessage':
          'A professional technician has accepted your request and is getting ready.',
      
      'technicianHeadingToLocation':
          'The technician is heading to your location. You can follow their progress on the map.', 
     
      
       'from': 'From',
       
      'followInRealTime': 'Follow in real time',
      'averageRating': 'Average rating',
      'phoneCall': 'Phone call',
      'sendMessage': 'Send message',
      'message': 'Message',
      'equipmentReady': 'Equipment ready',
      'startingCharge': 'Starting charge',
      'connectingTechnician': 'Connecting to technician',
       'serviceUpdatedCorrectly': 'Service updated correctly',
       'noActiveService': 'No active service',
      'couldNotGetLocation': 'Could not get your location',
      'errorRequestingService': 'Error requesting service',
      'noTechniciansAvailable':
          'No technicians available in your area at this time.',
      'needToRegisterVehicle':
          'You need to register a vehicle to request the service.',
      'authorizationError': 'Authorization error. Please log in again.',
      'sessionExpired': 'Session expired. Please log in again.',

      'pleaseWait': 'Please wait...',
 
      'accepted': 'Accepted',
      'enRoute': 'En Route',
       'yesterday': 'Yesterday',
      'noServicesInHistory': 'You have no services in your history.',

      'completeFormToStart': 'Complete the form to get started.',

      'welcomeSuccessfulRegistration': 'Welcome! Successful registration.',
      'errorOccurred': 'An error occurred',
      // En inglés:
      'registerElectricVehicle': 'Register Your Electric Vehicle',
      'step': 'Step',
      'of': 'of',
      'vehicleInformation': 'Vehicle Information',
      'brand': 'Brand',
      'model': 'Model',
      'year': 'Year',
      'identification': 'Identification',
      'plate': 'Plate',
      'color': 'Color',
      'technicalSpecs': 'Technical Specifications',
      'connectorType': 'Connector Type',
      'white': 'White',
      'black': 'Black',
      'gray': 'Gray',
      'silver': 'Silver',
      'red': 'Red',
      'blue': 'Blue',
      'green': 'Green',
      'writeBrandHint': 'Write a brand if it\'s not in the list',
      'selectOrEnterBrand': 'Please select or enter a brand',
      'modelHint': 'Ex: Model 3, Leaf, ID.4',
      'plateHint': 'ABC-123',
      'specifyColor': 'Specify the color',
      'colorHint': 'Ex: Gold, Purple',
      'enterColor': 'Enter a color',
      'vehicleRegistrationError': 'Error registering vehicle',
      'vehicleRegistered': 'Vehicle Registered!',
       'continueText': 'Continue',
      'selectBrandMessage': 'Please select a brand',
      'enterModelMessage': 'Please enter the model',
      'enterYearMessage': 'Please enter the year',
      'validYearMessage': 'Please enter a valid year',
      'enterPlateMessage': 'Please enter the plate',
      'selectColorMessage': 'Please select a color',
      'specifyColorMessage': 'Please specify the color',
      'selectConnectorMessage': 'Please select the connector type',
      'completeRequiredFields': 'Please complete all required fields',
      'fieldRequired': 'This field is required',
      'numbersOnly': 'Enter numbers only',
      'yearRange': 'Year must be between',
      'and': 'and',
      'plateMinLength': 'Plate must have at least 3 characters',
      'previous': 'Previous',
      'next': 'Next',
      'register': 'Register',
      'welcomeUser': 'Welcome User',
      'email': 'Email',
      'enterEmail': 'Enter your email address.',
      'enterPassword': 'Enter your password',
      'signIn': 'Sign In',
      'incorrectUserPassword': 'Incorrect username or password',
      'serverConnectionError': 'Server connection error',
      'signInWithGoogle': 'Sign in with Google',
      'signInWithApple': 'Sign in with Apple',
      'noAccount': 'Don\'t have an account? ',
      'createHere': 'Create one here.',

      'onboardingTitle1': 'Emergency on the road?',
      'onboardingSubtitle1':
          'Request a technician and follow their journey in real time',
      'onboardingTitle2': 'Trained and verified professionals.',
      'onboardingSubtitle2':
          'We have trained personnel for your type of vehicle and with certifications.',
      'onboardingTitle3': 'Notifications',
      'onboardingSubtitle3':
          'Stay informed about promotions, events and relevant app news.',
    },
    'es': {
      'onboardingTitle2': 'Profesionales capacitados y verificados.',
      'onboardingSubtitle2':
          'Contamos con personal capacitado para tu tipo de vehículo y con certificaciones.',
      'onboardingTitle3': 'Notificaciones',
      'onboardingSubtitle3':
          'Infórmate sobre promociones, eventos y noticias relevantes de la app.',

      'voltgoTechnician': 'Técnico Voltgo',
      'searchingRequests': 'Buscando solicitudes',
      'newRequest': 'Nueva solicitud',
      'enRouteToClient': 'EN RUTA HACIA EL CLIENTE',
      'serviceInProgressPanel': 'Servicio en progreso',
      'loadingEarningsError': 'Error al cargar los datos de ganancias',
      'logout': 'Cerrar Sesión',
      'logoutConfirmationMessage':
          '¿Estás seguro de que quieres cerrar sesión?',
      'cancel': 'Cancelar',
      'settings': 'Ajustes',
      'error': 'Error',
      'couldNotLoadProfile': 'No se pudo cargar el perfil',
      'account': 'Cuenta',
      'editProfile': 'Editar Perfil',
      'securityAndPassword': 'Seguridad y Contraseña',
      'chatHistory': 'Mensajes',
      'paymentMethods': 'Métodos de Pago',
      'vehicle': 'Vehículo',
      'manageVehicles': 'Gestionar Vehículos',
      'documents': 'Documentos',
      'logoutError': 'Error al cerrar sesión. Inténtalo nuevamente.',
      'myEarnings': 'Mis Ganancias',
      'today': 'Hoy',
      'week': 'Semana',
      'history': 'Historial',
      'withdrawFunds': 'Retirar Fondos',
      'availableBalance': 'Balance Disponible',
      'withdrawalAmount': 'Monto a Retirar',
      'minimumWithdrawal': 'Mínimo \$10.00',
      'paymentMethod': 'Método de Pago',
      'bankTransfer': 'Transferencia Bancaria',
      'debitCard': 'Tarjeta de Débito',
      'confirmWithdrawal': 'Confirmar Retiro',
      'minimumWithdrawalError': 'El monto mínimo de retiro es \$10.00',
      'insufficientBalance': 'Saldo insuficiente',
      'withdrawalSuccess': 'Retiro procesado exitosamente',
      'withdrawalError': 'Error al procesar el retiro',
      'todaySummary': 'Resumen de Hoy',
      'earnings': 'Ganancias',
      'services': 'Servicios',
      'tips': 'Propinas',
      'distance': 'Distancia',
      'rating': 'Calificación',
      'thisWeek': 'Esta Semana',
      'thisMonth': 'Este Mes',
      'totalEarned': 'Total Ganado',
      'pending': 'Pendiente',
      'noRecentServices': 'No hay servicios recientes',
      'recentActivity': 'Actividad Reciente',
      'realTimeTracking': 'SEGUIMIENTO EN TIEMPO REAL',

      'appTitle': 'VoltGo',
      'searchingTechnician': 'Buscando técnico',
      'technicianArriving': 'Técnico llegando en',
      'minutes': 'minutos',
      'estimated': 'Estimado',

      'arrival': 'Llegada',
      'connector': 'Conector',
      'estimatedTime': 'Tiempo estimado',
      'estimatedCost': 'Costo estimado',
      'cancelSearch': 'Cancelar búsqueda',
      'technicianConfirmed': 'Técnico confirmado',
      'serviceInProgress': 'Servicio en progreso',
      'chargingVehicle': 'Cargando tu vehículo',
      'requestCharge': 'Solicitar Carga',
      'viewActiveService': 'Ver Servicio Activo',
      'youHaveActiveService': 'Tienes un servicio en curso',
      'tapToFindTechnician': 'Toca para buscar un técnico',
      'cancelService': 'Cancelar Servicio',
      'followRealTime': 'Seguir en tiempo real',
      'serviceCompleted': '¡Servicio Completado!',
      'howWasExperience': '¿Cómo fue tu experiencia?',
      'addComment': 'Agregar comentario (opcional)',
      'skip': 'Omitir',
      'send': 'Enviar',
      'locationRequired': 'Ubicación Necesaria',
      'locationNeeded':
          'Para solicitar un servicio necesitamos acceder a tu ubicación. Por favor, activa los servicios de ubicación.',
      'activate': 'Activar',
      'permissionDenied': 'Permiso Denegado',
      'cannotContinue':
          'No podemos continuar sin acceso a tu ubicación. Por favor, otorga los permisos necesarios en la configuración de la aplicación.',
      'goToSettings': 'Ir a Configuración',
      'vehicleRegistration': 'Registra tu Vehículo',
      'vehicleNeeded':
          'Para utilizar VoltGo necesitas registrar tu vehículo eléctrico.',
      'whyNeeded': '¿Por qué es necesario?',
      'whyNeededDetails': '• Identificar el tipo de conector necesario\n'
          '• Calcular tiempos de carga precisos\n'
          '• Asignar técnicos especializados\n'
          '• Brindar el mejor servicio personalizado',
      'registerVehicle': 'Registrar Vehículo',
      'activeService': 'Servicio Activo',
      'youHaveActiveServiceDialog': 'Ya tienes un servicio en curso:',
      'request': 'Solicitud',
      'status': 'Estado',
      'requested': 'Solicitado',
      'whatToDo': '¿Qué deseas hacer?',
      'viewService': 'Ver Servicio',
      'timeExpired': 'Tiempo Expirado',
      'cannotCancelNow': 'Ya no es posible cancelar este servicio.',
      'technicianOnWay':
          'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
      'understood': 'Entendido',
      'cancellationFee': 'Tarifa de cancelación',
      'feeApplied':
          'Se aplicará una tarifa de \${fee} debido a que el técnico ya estaba asignado al servicio.',
      'technicianAssigned': '¡Técnico asignado!',
      'technicianAccepted':
          'Un técnico ha aceptado tu solicitud y está en camino.',
      'seeProgress': 'Puedes ver el progreso del técnico en el mapa.',
      'serviceExpired': 'Servicio Expirado',
      'serviceAutoCancelled': 'Tu servicio ha sido cancelado automáticamente.',
      'timeLimitExceeded': 'Tiempo límite excedido',
      'serviceActiveHour':
          'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
      'noChargesApplied': 'Sin cargos aplicados',
      'requestNew': 'Solicitar Nuevo',
      'technicianCancelled': 'Técnico Canceló',
      'technicianHasCancelled': 'El técnico ha cancelado el servicio.',
      'dontWorry': 'No te preocupes',
      'technicianCancellationReason':
          'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
      'nextStep': 'Siguiente paso',
      'requestImmediately':
          'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
      'findAnotherTechnician': 'Buscar Otro Técnico',
      'timeWarning': 'Advertencia de Tiempo',
      'serviceWillExpire': 'El servicio expirará en',
      'viewDetails': 'Ver Detalles',
      'finalWarning': '¡Último Aviso!',
      'serviceExpireMinutes':
          'Tu servicio expirará en {minutes} minutos y será cancelado automáticamente.',
      'contactTechnician': 'Contactar Técnico',
      'timeDetails': 'Detalles del Tiempo',
      'timeRemaining': 'Tiempo restante',
      'navigateToClient': 'Continúa hacia el cliente',
      'technician': 'Técnico',
      'client': 'Cliente',
      'chargeServiceRequested': 'Vehículo eléctrico para cargar',
      'technicianArrivedTitle': '¡Has llegado!',
      'technicianArrivedMessage': 'Has llegado a la ubicación del cliente.',
       'arrivedAtSite': 'Iniciar Servicio',
      'time': 'Tiempo',
       'speed': 'Velocidad',
      'call': 'Llamar',
         'editProfile': 'Editar Perfil',
    'save': 'Guardar',
    'loading': 'Cargando...',
    'technician': 'Técnico Certificado',
    'contactInformation': 'Información de contacto',
    'phoneNumber': 'Número de teléfono',
    'fieldRequired': 'Este campo es requerido',
    'phoneMinLength': 'El teléfono debe tener al menos 10 dígitos',
    'professionalInformation': 'Información profesional',
    'baseLocation': 'Ubicación base',
    'licenseNumber': 'Número de licencia (opcional)',
    'servicesOffered': 'Servicios ofrecidos',
    'selectServices': 'Selecciona los servicios que ofreces:',
    'selectAtLeastOneService': 'Selecciona al menos un servicio',
    'identificationDocument': 'Documento de identificación',
    'documentSelected': 'Documento seleccionado',
    'remove': 'Quitar',
    'uploadDocument': 'Subir documento',
    'changeDocument': 'Cambiar documento',
    'documentInfo': 'Formatos soportados: JPG, PNG (máx. 5MB)',
    'saveChanges': 'Guardar cambios',
    'noChanges': 'Sin cambios',
    'profileUpdated': 'Perfil actualizado',
    'profileUpdatedSuccessfully': 'Tu perfil se ha actualizado correctamente.',
    'accept': 'Aceptar',
    'error': 'Error',
          'tyc': 'Terminos y condiciones',

    'unsavedChanges': 'Cambios sin guardar',
    'discardChanges': '¿Deseas descartar los cambios realizados?',
    'cancel': 'Cancelar',
    'discard': 'Descartar',
      'chat': 'Mensaje',
      'pleaseWaitMoment': 'Configurando navegación...',
      'errorLoadingData': 'Error al inicializar seguimiento',
      'noPhoneNumberAvailable': 'No hay número de teléfono disponible',
      'couldNotOpenPhoneApp': 'No se pudo abrir la aplicación de teléfono',
      'errorMakingCall': 'Error al intentar llamar',
      'errorRefreshingServiceData': 'Error al actualizar los datos del servicio',
       'technicianEnRoute': 'Te acercas al destino',
      'systemInfo': 'Información del sistema',
      'serviceInfo':
          '• Los servicios se cancelan automáticamente después de 1 hora\n'
              '• Esto protege tanto al cliente como al técnico\n'
              '• No se aplican cargos por cancelaciones automáticas\n'
              '• Puedes solicitar un nuevo servicio inmediatamente',

      // Additional strings used in PassengerMapScreen
      'chatWithTechnician': 'Chat con técnico',
      'cancellationTimeExpired': 'Tiempo de cancelación agotado',
      'serviceCancelled': 'Servicio Cancelado',
      'serviceCancelledSuccessfully':
          'Tu servicio ha sido cancelado exitosamente.',
      'preparingEquipment': 'Preparando equipo de carga',
      'technicianOnSite': 'Técnico en sitio',
      'equipmentStatus': 'Estado del equipo',
      'preparingCharge': 'Preparando carga',
      'notCancellable': 'No cancelable',
      'timeToCancel': 'Tiempo para cancelar:',
      'lastMinute': '¡Último minuto!',
      'minutesRemaining': 'minutos restantes',
      'findingBestTechnician': 'Buscando el mejor técnico para ti',
      'thankYouForUsingVoltGo': 'Gracias por usar VoltGo',
      'total': 'Total',
      'close': 'Cerrar',
      'technicianWorkingOnVehicle': 'El técnico está trabajando en tu vehículo',
      'since': 'Desde',
      'initial': 'Inicial',
      'waitingForRequests': 'Esperando nuevas solicitudes',
      'reviewingIncomingRequest': 'Revisando solicitud entrante',
      'headToClientLocation': 'Dirígete a la ubicación del cliente',
      'chargingClientVehicle': 'Cargando el vehículo del cliente',

      // Service Request Panel (faltantes)
      'newChargeRequest': 'NUEVA SOLICITUD DE RECARGA',
      'client': 'Cliente',
      'estimatedEarnings': 'Ganancia estimada',
      'reject': 'Rechazar',
      'accept': 'Aceptar',

      // Navigation y Maps (faltantes)
      'navigateToClient': 'Navegar hacia cliente',
      'openInMaps': 'Abrir en Maps',
      'googleMaps': 'Google Maps',
      'navigationWithTraffic': 'Navegación con tráfico en tiempo real',
      'waze': 'Waze',
      'optimizedRoutes': 'Rutas optimizadas y alertas comunitarias',
      'navigate': 'NAVEGAR',
      'call': 'Llamar',
      'realTimeTracking': 'SEGUIMIENTO EN TIEMPO REAL',

      // Service Panel (faltantes)
      'arrivedAtSite': 'HE LLEGADO AL SITIO',
      'finishService': 'FINALIZAR SERVICIO',
      'chargeServiceRequested': 'Servicio de recarga solicitado',

      // Error Messages y Success (faltantes)
      'requestAccepted': '¡Solicitud aceptada! Dirígete al cliente.',
      'errorAcceptingRequest': 'Error al aceptar la solicitud',
      'requestTakenByAnother': 'Esta solicitud fue tomada por otro técnico',
      'noAuthorizationForRequest': 'No tienes autorización para esta solicitud',
      'serviceCompletedSuccessfully': '¡Servicio completado exitosamente!',
      'errorLoadingData': 'Error al cargar datos',
      'pleaseEnableLocation': 'Por favor, activa el servicio de ubicación.',
      'locationPermissionRequired':
          'El permiso de ubicación es necesario para operar.',
      'noClientInformationAvailable':
          'No hay información del cliente disponible',
      'noPhoneNumberAvailable': 'No hay número de teléfono disponible',
      'couldNotOpenPhoneApp': 'No se pudo abrir la aplicación de teléfono',
      'errorMakingCall': 'Error al intentar llamar',
      'errorChangingStatus': 'Error al cambiar de estado',
      'couldNotOpenGoogleMaps': 'No se pudo abrir Google Maps',
      'wazeNotInstalled': 'Waze no está instalado en tu dispositivo',
      'couldNotOpenWaze': 'No se pudo abrir Waze',
      'noNavigationAppsAvailable': 'No hay apps de navegación disponibles',
      'couldNotOpenNavigationApp': 'No se pudo abrir ninguna app de navegación',
      'requestNoLongerAvailable': 'Esta solicitud ya no está disponible',
      'clientCancelledRequest': 'El cliente canceló la solicitud',
      'errorCheckingStatus': 'Error verificando estado',
      'requestNotAuthorizedAnymore':
          'Solicitud ya no está disponible para este técnico',

      // Status Estados (faltantes)
      'online': 'EN LÍNEA',
      'offline': 'DESCONECTADO',
      'serviceActive': 'SERVICIO ACTIVO',
      'disconnected': 'DESCONECTADO',

      // Stats y Earnings (faltantes)
      'earnings': 'Ganancias',

      // Service Cancellation por Cliente (faltantes)
      'serviceCancelledTitle': 'Servicio Cancelado',
      'clientCancelledService': 'El cliente ha cancelado el servicio.',
      'timeCompensation': 'Compensación por tiempo',
      'partialCompensationMessage':
          'Recibirás una compensación parcial por el tiempo invertido en este servicio.',
      'willContinueReceivingRequests':
          'Continuarás recibiendo nuevas solicitudes automáticamente.',
      'serviceCancelledByClient': 'Servicio cancelado por cliente',
'loadingInformation': 'Cargando información...',
    'errorMessage': 'Error: {error}',
    'retry': 'Reintentar',
    'basicInformation': 'Información básica',
    'identification': 'Identificación',
    'technicalSpecifications': 'Especificaciones técnicas',
    'brandHint': 'Ej: Tesla, Nissan',
    'modelExampleHint': 'Ej: Model 3, Leaf',
    'yearHint': 'Ej: 2024',
    'plateExampleHint': 'Ej: ABC-123',
    'requiredField': 'Este campo es requerido',
    'updateSuccessful': '¡Actualización exitosa!',
    'vehicleUpdateSuccessMessage': 'La información de tu vehículo ha sido actualizada correctamente.',
    'continueButton': 'Continuar',
      // Service Expiration específica para técnico (faltante)
      'serviceAutoCancelledAfterHour':
          'Tu servicio ha sido cancelado automáticamente después de 1 hora.',

      // Loading y Processing (faltantes)
      'loadingEarningsError': 'Error cargando ganancias',
      'time': 'Tiempo',
      'technicianPreparingEquipment':
          'El técnico está preparando el equipo. El servicio comenzará pronto.',
      'viewTechnicianOnSite': 'Ver técnico en sitio',
      'chat': 'Chat',
      'thankYouForRating': '¡Gracias por tu calificación!',
      'processingRequest': 'Procesando solicitud...',
      'errorLoadingMap': 'Error al cargar el mapa',
      'vehicleVerification': 'Verificación de Vehículo',
      'checkingVehicle': 'Verificando tu vehículo',
      'verifyingInformation': 'Estamos verificando tu información...',
      'verificationNeeded': 'Verificación Necesaria',
      'welcomeTechnician':
          'Bienvenido Técnico.', // ✅ CORREGIDO: Faltaba la tilde en 'Técnico'

'serviceInitiatedTitle': 'Iniciar Servicio de Carga',
      'timeElapsed': 'Tiempo transcurrido',
      'technicianWillDocumentProgress': 'Documentación Fotográfica',
      'serviceVehicle': 'Foto del Vehículo',
       'serviceCompletedTitle': 'Después de la Carga',
      'vehicleRegisteredSuccess': 'Foto guardada en servidor',
      'serviceInformation': 'Detalles del Servicio',
      'processing': 'Completando...',
       'serviceInitiatedMessage': 'Servicio de carga iniciado',
       'serviceCompletedMessage': 'El servicio de recarga ha sido completado exitosamente.',
      'thankYouForYourRating': 'El cliente recibirá una notificación y podrá calificar tu servicio.',
      'continueText': 'Continuar',
       'min': 'minutos',
      'couldNotVerifyVehicle':
          'No pudimos verificar si tienes un vehículo registrado. Por favor, asegúrate de tener un vehículo registrado para continuar.',
      'goToRegistration': 'Ir a Registro',
      'syncInProgress': 'Sincronización en Proceso',
      'vehicleRegisteredCorrectly':
          'Tu vehículo se registró correctamente, pero el sistema está sincronizando la información.',
      'syncOptions': 'Opciones:',
      'syncOptionsText':
          '• Espera unos segundos y continúa\n• Cierra y vuelve a abrir la app\n• Si persiste, contacta soporte',
      'retry': 'Reintentar',
      'continueAnyway': 'Continuar de Todas Formas',
       'nearbyTechnicians': 'Buscando técnicos cercanos',
      'thisCanTakeSeconds': 'Esto puede tomar unos segundos',
      'searchingDots': 'Buscando técnicos cercanos',
      'onSite': 'En sitio',
      'cancelled': 'Cancelado',
      'unknownStatus': 'Estado desconocido',
      'fewSecondsAgo': 'Hace unos segundos',
      'minutesAgo': 'minutos atrás',
      'hoursAgo': 'horas atrás',
      'daysAgo': 'días atrás',

      'ago': 'hace',
      'serviceVehicle': 'Vehículo de servicio',
      'notSpecified': 'No especificado',
      'technician': 'Técnico',
      'errorCancellingService': 'Error al cancelar el servicio',
      'noActiveServiceToCancel': 'No hay servicio activo para cancelar',
      'timeElapsedMinutes': 'minutos transcurridos',
      'limitMinutes': 'minutos límite',
      'cannotCancelServiceNow': 'No se puede cancelar el servicio ahora',
      'technicianAlreadyOnWay':
          'El técnico ya está en camino hacia tu ubicación. Por favor, espera su llegada.',
      'serviceCancelledWithFee': 'Servicio cancelado con tarifa',
      'serviceCancelledSuccessfullyMessage': 'Servicio cancelado exitosamente',
      'no': 'No',
      'yes': 'Sí',
      'yesCancel': 'Sí, cancelar',
      'termsAndConditions': 'Términos y Condiciones',
    'lastUpdated': 'Última actualización: Enero 2025',
    'acceptance': '1. Aceptación de los Términos',
    'acceptanceContent': 'Aquí irá el texto sobre la aceptación de los términos y condiciones de uso de la aplicación VoltGo.',
    'serviceDescription': '2. Descripción del Servicio',
    'serviceDescriptionContent': 'Aquí irá el texto que describe los servicios ofrecidos por VoltGo, incluyendo carga de vehículos eléctricos y asistencia técnica.',
    'userResponsibilities': '3. Responsabilidades del Usuario',
    'userResponsibilitiesContent': 'Aquí irá el texto sobre las responsabilidades y obligaciones del usuario al utilizar la plataforma VoltGo.',
    'technicianObligations': '4. Obligaciones de los Técnicos',
    'technicianObligationsContent': 'Aquí irá el texto sobre las obligaciones y responsabilidades de los técnicos registrados en la plataforma.',
    'paymentTerms': '5. Términos de Pago',
    'paymentTermsContent': 'Aquí irá el texto sobre los términos de pago, facturación y políticas de reembolso.',
    'limitation': '6. Limitación de Responsabilidad',
    'limitationContent': 'Aquí irá el texto sobre las limitaciones de responsabilidad de VoltGo ante daños o inconvenientes.',
    'modifications': '7. Modificaciones',
    'modificationsContent': 'Aquí irá el texto sobre cómo y cuándo VoltGo puede modificar estos términos y condiciones.',
    'contactUs': 'Contacto',
    'questionsContact': 'Si tienes preguntas sobre estos términos, contáctanos en:',
        'updateVehicle': 'Actualizar Vehículo',
    
     'verified': 'Verificado',
    'serviceLocation': 'Ubicación del servicio',
     
    'veryClose': 'Muy cerca',
     'mediumDistance': 'Distancia media',
    'far': 'Lejos',
     'hours': 'h',
"chatWith": "Chat con {name}",
"serviceNumber": "Servicio #{id}",
"loadingMessages": "Cargando mensajes...",
"errorLoadingChat": "Error al cargar el chat",
"tryAgain": "Intentar nuevamente",
"startConversation": "Inicia la conversación",
"communicateWithTechnician": "Comunícate con tu técnico para coordinar el servicio",
"communicateWithClient": "Comunícate con el cliente para coordinar el servicio",
"writeMessage": "Escribe un mensaje...",
"sending": "Enviando...",
"errorSendingMessage": "Error al enviar mensaje: {error}",
"updateMessages": "Actualizar mensajes",

// Estados del servicio
"statusPending": "Cliente asignado",
"statusAccepted": "Cliente asignado", 
"statusEnRoute": "Técnico en camino",
"statusOnSite": "Técnico en sitio",
"statusCharging": "Cargando vehículo",
"statusCompleted": "Servicio completado",
"statusCancelled": "Servicio cancelado",
    // Política de Privacidad - ESPAÑOL
    'privacyPolicy': 'Política de Privacidad',
    'dataCollection': '1. Información que Recopilamos',
    'dataCollectionContent': 'Aquí irá el texto sobre qué datos personales recopila VoltGo, incluyendo información de perfil, ubicación y uso de la aplicación.',
    'dataUsage': '2. Cómo Usamos tu Información',
    'dataUsageContent': 'Aquí irá el texto sobre cómo VoltGo utiliza los datos recopilados para proporcionar servicios, mejorar la experiencia y comunicarse con los usuarios.',
    'locationData': '3. Datos de Ubicación',
    'locationDataContent': 'Aquí irá el texto sobre cómo VoltGo recopila y utiliza datos de ubicación para conectar usuarios con técnicos cercanos.',
    'dataSharing': '4. Compartir Información',
    'dataSharingContent': 'Aquí irá el texto sobre cuándo y con quién VoltGo puede compartir información personal de los usuarios.',
    'dataSecurity': '5. Seguridad de Datos',
    'dataSecurityContent': 'Aquí irá el texto sobre las medidas de seguridad implementadas para proteger la información personal de los usuarios.',
    'userRights': '6. Derechos del Usuario',
    'userRightsContent': 'Aquí irá el texto sobre los derechos de los usuarios respecto a sus datos personales, incluyendo acceso, corrección y eliminación.',
    'cookies': '7. Cookies y Tecnologías Similares',
    'cookiesContent': 'Aquí irá el texto sobre el uso de cookies y otras tecnologías de seguimiento en la aplicación VoltGo.',
    'thirdPartyServices': '8. Servicios de Terceros',
    'thirdPartyServicesContent': 'Aquí irá el texto sobre los servicios de terceros integrados en VoltGo y sus políticas de privacidad.',
    'dataRetention': '9. Retención de Datos',
    'dataRetentionContent': 'Aquí irá el texto sobre cuánto tiempo VoltGo conserva los datos personales de los usuarios.',
    'minorPrivacy': '10. Privacidad de Menores',
    'minorPrivacyContent': 'Aquí irá el texto sobre las políticas especiales de privacidad para usuarios menores de edad.',
    'privacyQuestions': 'Para preguntas sobre privacidad, contáctanos en:',
      'areYouSureCancelService':
          '¿Estás seguro de que deseas cancelar el servicio?',
      'cancelRide': 'Cancelar Servicio',
      'blockedFromCancelling': 'No cancelable',
      'timeForCancellingExpired': 'Tiempo de cancelación agotado',
      'serviceHasExceededTimeLimit': 'Servicio ha excedido el tiempo límite',
      'serviceActiveMinutes':
          'El servicio lleva {minutes} minutos activo. Puedes cancelarlo sin cargos.',
      'cancelExpiredService': 'Cancelar Servicio Expirado',
      'forceExpireService': 'Forzar Expiración del Servicio',
      'areYouSureCancelExpiredService':
          '¿Estás seguro de que deseas cancelar este servicio?',
      'serviceInformation': 'Información del servicio:',
      'timeElapsed': 'Tiempo transcurrido',
      'currentStatus': 'Estado actual',
      'noChargesForCancellation': 'No se aplicarán cargos por cancelación',
      'canRequestNewServiceImmediately':
          'Podrás solicitar un nuevo servicio inmediatamente',
      'yesCancelService': 'Sí, Cancelar Servicio',
      'serviceExpiredAutomatically': 'Servicio expirado automáticamente',
      'serviceActiveForHourWithoutCompletion':
          'El servicio ha estado activo por más de 1 hora sin ser completado. Para tu protección, lo hemos cancelado automáticamente.',
      'noChargesAppliedForExpiredService':
          'Sin cargos aplicados por servicio expirado',
      'canRequestNewService':
          'Puedes solicitar un nuevo servicio cuando gustes',
      'requestNewService': 'Solicitar Nuevo Servicio',
      'searchForAnotherTechnician': 'Buscar Otro Técnico',
      'emergenciesOrTechnicalIssues':
          'Esto puede suceder por emergencias o problemas técnicos. No se te aplicará ningún cargo.',
      'canRequestNewServiceNow':
          'Puedes solicitar un nuevo servicio inmediatamente. Te conectaremos con otro técnico disponible.',
      'ifTechnicianHasNotArrived':
          'Si el técnico no ha llegado aún, puedes contactarlo o esperar a que el sistema cancele automáticamente sin costo.',
      'serviceDetailsInfo': 'Detalles del Servicio',
      'serviceDetailsText':
          'Tiempo restante: {minutes} minutos\n\n📋 Información del sistema:\n• Los servicios se cancelan automáticamente después de 1 hora\n• Esto protege tanto al cliente como al técnico\n• No se aplican cargos por cancelaciones automáticas\n• Puedes solicitar un nuevo servicio inmediatamente',
      'technicianHasArrived': '¡Técnico ha llegado!',
      'technicianAtLocationPreparingEquipment':
          'El técnico está en tu ubicación preparando el equipo de carga.',
      'serviceStarted': '⚡ Servicio Iniciado',
      'technicianStartedChargingVehicle':
          'El técnico ha comenzado la carga de tu vehículo eléctrico.',
      'vehicleChargedSuccessfully':
          '¡Tu vehículo ha sido cargado exitosamente! Gracias por usar VoltGo.',
      'statusUpdated': 'Estado Actualizado',
      'serviceStatusChanged': 'El estado de tu servicio ha cambiado.',
      'technicianConfirmedTitle': '¡Técnico Confirmado!',
      'technicianConfirmedMessage':
          'Un técnico profesional ha aceptado tu solicitud y se está preparando.',
       'technicianHeadingToLocation':
          'El técnico se dirige hacia tu ubicación. Puedes seguir su progreso en el mapa.',
      'technicianArrivedTitle': '¡Técnico ha Llegado!',
      'technicianArrivedMessage':
          'El técnico está en tu ubicación preparando el equipo de carga.',
      'serviceInitiatedTitle': '⚡ Servicio Iniciado',
      'serviceInitiatedMessage':
          'El técnico ha comenzado la carga de tu vehículo eléctrico.',
      'serviceCompletedTitle': '✅ Servicio Completado',
      'serviceCompletedMessage':
          '¡Tu vehículo ha sido cargado exitosamente! Gracias por usar VoltGo.',
      'technicianWillDocumentProgress':
          'El técnico documentará el progreso durante el servicio',
      'serviceProgress': 'Progreso del Servicio',
      'from': 'Desde',
      'batteryLevel': 'Nivel de batería',
      'chargingTime': 'Tiempo de carga',
      'min': 'min',
      'followInRealTime': 'Seguir en tiempo real',
      'averageRating': 'Calificación promedio',
      'phoneCall': 'Llamada telefónica',
      'sendMessage': 'Enviar mensaje',
      'message': 'Mensaje',
      'equipmentReady': 'Equipo listo',
      'startingCharge': 'Iniciando carga',
      'connectingTechnician': 'Conectando con técnico',
      'thankYouForYourRating': '¡Gracias por tu calificación!',
      'serviceUpdatedCorrectly': 'Servicio actualizado correctamente',
      'errorRefreshingServiceData': 'Error actualizando datos del servicio',
      'noActiveService': 'Sin servicio activo',
      'couldNotGetLocation': 'No se pudo obtener tu ubicación',
      'errorRequestingService': 'Error al solicitar el servicio',
      'noTechniciansAvailable':
          'No hay técnicos disponibles en tu área en este momento.',
      'needToRegisterVehicle':
          'Necesitas registrar un vehículo para solicitar el servicio.',
      'authorizationError':
          'Error de autorización. Por favor, inicia sesión nuevamente.',
      'sessionExpired': 'Sesión expirada. Por favor, inicia sesión nuevamente.',

// En español:

      'loggingOut': 'Cerrando sesión...',
      'pleaseWait': 'Por favor espera...',
      'pleaseWaitMoment': 'Por favor espera un momento',

      'serviceHistory': 'Historial de Servicios',
      'reviewPreviousServices': 'Revisa tus servicios anteriores',
      'all': 'Todo',
      'completed': 'Completado',
      'accepted': 'Aceptado',
      'enRoute': 'En Camino',
      'charging': 'Cargando',
      'yesterday': 'Ayer',
      'errorLoadingHistory': 'Error al cargar el historial',
      'noServicesInHistory': 'No tienes servicios en tu historial.',
      'requestService': 'Solicitar Servicio',
      'createTechnicianAccount': 'Crea tu cuenta de Técnico',
      'completeTechnicianForm': 'Completa el formulario para empezar.',
      'fullName': 'Nombre completo',
      'yourNameAndSurname': 'Tu nombre y apellido',
      'emailAddress': 'Correo electrónico',
      'emailHint': 'tucorreo@ejemplo.com',
      'mobilePhone': 'Teléfono móvil',
      'phoneNumber': 'Número de teléfono',
      'password': 'Contraseña',
      'confirmPassword': 'Confirmar contraseña',
      'minimumCharacters': 'Mínimo 8 caracteres',
      'baseLocation': 'Ubicación de Base',
      'selectLocationOnMap': 'Selecciona una ubicación en el mapa',

      // ===== Service Expiration (FALTANTE) =====

      // ===== Hardcoded Texts Found in Code (FALTANTES) =====
      'noActiveServiceFound': 'No hay servicio activo',
      'serviceTrackingLocation': 'Rastreando ubicación cada 30 segundos...',
      'locationTrackingStopped': 'Rastreo de ubicación detenido.',
      'requestListCleaned': 'Lista de solicitudes no disponibles limpiada',
      // Optional Documentation Section
      'optionalDocumentation': 'Documentación (Opcional)',
      'driverLicenseNumber': 'Número de licencia de conducir',
      'enterLicenseNumber': 'Ingresa tu número de licencia',
      'idPhotoOrCertification':
          'Foto de ID o certificación (AUN NO FUNCIONA, DEJAR ESTE CAMPO VACIO)',
      'selectFile': 'Seleccionar archivo (JPG, PNG, PDF)',

      'noServiceHistory': 'No tienes servicios en tu historial.',
      // Services Section
      'servicesOffered': 'Servicios que ofreces',
      'jumpStart': 'Arranque',
      'evCharging': 'Carga EV',
      'tireChange': 'Cambio de Llanta',
      'lockout': 'Apertura de Vehículo',
      'fuelDelivery': 'Entrega de Combustible',
      'other': 'Otro',
      'otherService': 'Otro servicio',
      'describeService': 'Describe el servicio que ofreces',
            'hoy': 'Hoy',

      // Buttons and Actions
      'createAccount': 'Crear cuenta',
      'selectLocation': 'Seleccionar ubicación',
      'uploadFile': 'Subir archivo',

      // Messages
      'registrationSuccessful': '¡Registro exitoso!',
      'registrationError':
          'No se pudo completar el registro. Verifica tus datos e inténtalo de nuevo.',
      'fileSelectionError': 'Error al seleccionar el archivo: ',
      'alreadyHaveAccount': '¿Ya tienes una cuenta? ',
      'signInHere': 'Inicia sesión.',
      'signUpWithGoogle': 'Registrarse con Google',
      'signUpWithApple': 'Registrarse con Apple',
      'or': 'O',
// En español:

      'registerElectricVehicle': 'Registra tu Vehículo Eléctrico',
      'step': 'Paso',
      'of': 'de',
            'step': 'Paso',

      'vehicleInformation': 'Información del Vehículo',
      'brand': 'Marca',
      'model': 'Modelo',
      'year': 'Año',
      'identification': 'Identificación',
      'plate': 'Placa',
      'color': 'Color',
      'technicalSpecs': 'Especificaciones Técnicas',
      'connectorType': 'Tipo de Conector',
      'white': 'Blanco',
      'black': 'Negro',
      'gray': 'Gris',
      'silver': 'Plata',
      'red': 'Rojo',

'serviceDetails': 'Detalles del Servicio',
'completed': 'Completado',
'cancelled': 'Cancelado',
'pending': 'Pendiente',
'inProgress': 'En Progreso',
'errorLoadingDetails': 'Error al cargar los detalles',
'retry': 'Reintentar',
'additionalDetailsNotAvailable': 'Detalles adicionales no disponibles',
'technicalDetailsWillBeAdded': 'Los detalles técnicos del servicio serán agregados por el técnico durante o después del servicio.',
'serviceInformation': 'Información del Servicio',
'date': 'Fecha',
'time': 'Hora',
'status': 'Estado',
'serviceId': 'ID del Servicio',
'serviceTimeline': 'Cronología del Servicio',
'started': 'Iniciado',
'batteryInformation': 'Información de Batería',
'initialLevel': 'Nivel Inicial',
'chargeTime': 'Tiempo de Carga',
'serviceNotes': 'Notas del Servicio',
'servicePhotos': 'Fotos del Servicio',
'vehicle': 'Vehículo',
'before': 'Antes',
'after': 'Después',
'error': 'Error',
'myRatings': 'Mis Calificaciones',
    'summary': 'Resumen',
    'allReviews': 'Todas las Reseñas',
    'ratingDistribution': 'Distribución de Calificaciones',
    'recentReviews': 'Reseñas Recientes',
    'viewAll': 'Ver todas',
    'noReviewsYet': 'Sin reseñas aún',
    'completeServices': 'Completa más servicios para recibir calificaciones de tus clientes',
    'errorLoadingReviews': 'Error al cargar las reseñas: {error}',
    'reviewsCount': '{count} reseñas',
'loading': 'Cargando',
'errorLoadingImage': 'Error al cargar la imagen',
'paymentInformation': 'Información de Pago',
'totalCost': 'Costo Total:',
                        'otros': 'Otros',
'yourRating': 'Tu Calificación',
    'averageRating': 'Promedio de todas tus calificaciones',
      'blue': 'Azul',
      'green': 'Verde',
      'writeBrandHint': 'Escribe una marca si no está en la lista',
      'selectOrEnterBrand': 'Por favor, selecciona o ingresa una marca',
      'modelHint': 'Ej: Model 3, Leaf, ID.4',
      'plateHint': 'ABC-123',
      'specifyColor': 'Especifica el color',
      'colorHint': 'Ej: Dorado, Morado',
      'enterColor': 'Ingresa un color',
      'vehicleRegistrationError': 'Error al registrar el vehículo',
      'vehicleRegistered': '¡Vehículo Registrado!', 
      'continueText': 'Continuar',
            'politicadeprivacidad': 'Política de privacidad',

      'selectBrandMessage': 'Por favor selecciona una marca',
      'enterModelMessage': 'Por favor ingresa el modelo',
      'enterYearMessage': 'Por favor ingresa el año',
      'validYearMessage': 'Por favor ingresa un año válido',
      'enterPlateMessage': 'Por favor ingresa la placa',
      'selectColorMessage': 'Por favor selecciona un color',
      'specifyColorMessage': 'Por favor especifica el color',
      'selectConnectorMessage': 'Por favor selecciona el tipo de conector',
      'completeRequiredFields':
          'Por favor completa todos los campos requeridos',
      'fieldRequired': 'Este campo es requerido',
      'numbersOnly': 'Ingresa solo números',
      'yearRange': 'El año debe estar entre',
      'and': 'y',
      'plateMinLength': 'La placa debe tener al menos 3 caracteres',
      'previous': 'Anterior',
      'next': 'Siguiente',
      'welcomeUser': 'Bienvenido Usuario',
      'email': 'Correo electrónico',
      'enterEmail': 'Ingresa tu correo electrónico.',
      'enterPassword': 'Ingresa tu contraseña',
      'signIn': 'Iniciar sesión',
      'incorrectUserPassword': 'Usuario o contraseña incorrectos',
      'serverConnectionError': 'Error de conexión con el servidor',
      'signInWithGoogle': 'Iniciar sesión con Google',
      'signInWithApple': 'Iniciar sesión con Apple',
      'noAccount': '¿No tienes una cuenta? ',
      'createHere': 'Créala aquí.',
      'completeFormToStart': 'Completa el formulario para empezar.',

      'welcomeSuccessfulRegistration': '¡Bienvenido! Registro exitoso.',
      'errorOccurred': 'Ocurrió un error',

      'register': 'Registrar',
      'onboardingTitle1': '¿Emergencia en el camino?',
      'onboardingSubtitle1':
          'Solicita un técnico y sigue su trayecto en tiempo real',
    }
  };

  String get onboardingTitle2 =>
      localizedValues[locale.languageCode]!['onboardingTitle2']!;
  String get onboardingSubtitle2 =>
      localizedValues[locale.languageCode]!['onboardingSubtitle2']!;
  String get onboardingTitle3 =>
      localizedValues[locale.languageCode]!['onboardingTitle3']!;
  String get onboardingSubtitle3 =>
      localizedValues[locale.languageCode]!['onboardingSubtitle3']!;

  String get voltgoTechnician =>
      localizedValues[locale.languageCode]!['voltgoTechnician']!;
  String get searchingRequestsText =>
      localizedValues[locale.languageCode]!['searchingRequests']!;
  String get newRequest =>
      localizedValues[locale.languageCode]!['newRequest']!;
  String get enRouteToClientPanel =>
      localizedValues[locale.languageCode]!['enRouteToClient']!;
  String get serviceInProgressPanel =>
      localizedValues[locale.languageCode]!['serviceInProgressPanel']!;
  String get loadingEarningsError =>
      localizedValues[locale.languageCode]!['loadingEarningsError']!;
  String get logout => localizedValues[locale.languageCode]!['logout']!;
  String get logoutConfirmationMessage =>
      localizedValues[locale.languageCode]!['logoutConfirmationMessage']!;
  String get cancel => localizedValues[locale.languageCode]!['cancel']!;
  String get settings => localizedValues[locale.languageCode]!['settings']!;
  String get error => localizedValues[locale.languageCode]!['error']!;
  String get couldNotLoadProfile =>
      localizedValues[locale.languageCode]!['couldNotLoadProfile']!;
  String get account => localizedValues[locale.languageCode]!['account']!;
  String get editProfile =>
      localizedValues[locale.languageCode]!['editProfile']!;
  String get securityAndPassword =>
      localizedValues[locale.languageCode]!['securityAndPassword']!;
  String get chatHistory =>
      localizedValues[locale.languageCode]!['chatHistory']!;
  String get paymentMethods =>
      localizedValues[locale.languageCode]!['paymentMethods']!;
  String get vehicle => localizedValues[locale.languageCode]!['vehicle']!;
  String get manageVehicles =>
      localizedValues[locale.languageCode]!['manageVehicles']!;
  String get documents => localizedValues[locale.languageCode]!['documents']!;
  String get logoutError =>
      localizedValues[locale.languageCode]!['logoutError']!;
  String get myEarnings =>
      localizedValues[locale.languageCode]!['myEarnings']!;
  String get today => localizedValues[locale.languageCode]!['today']!;
  String get week => localizedValues[locale.languageCode]!['week']!;
  String get history => localizedValues[locale.languageCode]!['history']!;
  String get withdrawFunds =>
      localizedValues[locale.languageCode]!['withdrawFunds']!;
  String get availableBalance =>
      localizedValues[locale.languageCode]!['availableBalance']!;
  String get withdrawalAmount =>
      localizedValues[locale.languageCode]!['withdrawalAmount']!;
  String get minimumWithdrawal =>
      localizedValues[locale.languageCode]!['minimumWithdrawal']!;
  String get paymentMethod =>
      localizedValues[locale.languageCode]!['paymentMethod']!;
  String get bankTransfer =>
      localizedValues[locale.languageCode]!['bankTransfer']!;
  String get debitCard => localizedValues[locale.languageCode]!['debitCard']!;
  String get confirmWithdrawal =>
      localizedValues[locale.languageCode]!['confirmWithdrawal']!;
  String get minimumWithdrawalError =>
      localizedValues[locale.languageCode]!['minimumWithdrawalError']!;
  String get insufficientBalance =>
      localizedValues[locale.languageCode]!['insufficientBalance']!;
  String get withdrawalSuccess =>
      localizedValues[locale.languageCode]!['withdrawalSuccess']!;
  String get withdrawalError =>
      localizedValues[locale.languageCode]!['withdrawalError']!;
  String get todaySummary =>
      localizedValues[locale.languageCode]!['todaySummary']!;
  String get earnings => localizedValues[locale.languageCode]!['earnings']!;
  String get services => localizedValues[locale.languageCode]!['services']!;
  String get tips => localizedValues[locale.languageCode]!['tips']!;
  String get distance => localizedValues[locale.languageCode]!['distance']!;
  String get rating => localizedValues[locale.languageCode]!['rating']!;
  String get thisWeek => localizedValues[locale.languageCode]!['thisWeek']!;
  String get thisMonth => localizedValues[locale.languageCode]!['thisMonth']!;
  String get totalEarned =>
      localizedValues[locale.languageCode]!['totalEarned']!;
  String get pending => localizedValues[locale.languageCode]!['pending']!;
  String get noRecentServices =>
      localizedValues[locale.languageCode]!['noRecentServices']!;
  String get recentActivity =>
      localizedValues[locale.languageCode]!['recentActivity']!;
  String get realTimeTracking =>
      localizedValues[locale.languageCode]!['realTimeTracking']!;

// GETTERS NECESARIOS PARA AppLocalizations:
  String get createAccount =>
      localizedValues[locale.languageCode]!['createAccount']!;
  String get completeFormToStart =>
      localizedValues[locale.languageCode]!['completeFormToStart']!;
  String get fullName => localizedValues[locale.languageCode]!['fullName']!;
  String get yourNameAndSurname =>
      localizedValues[locale.languageCode]!['yourNameAndSurname']!;
  String get emailHint => localizedValues[locale.languageCode]!['emailHint']!;
  String get mobilePhone =>
      localizedValues[locale.languageCode]!['mobilePhone']!;
  String get phoneNumber =>
      localizedValues[locale.languageCode]!['phoneNumber']!;
  String get confirmPassword =>
      localizedValues[locale.languageCode]!['confirmPassword']!;
  String get minimumCharacters =>
      localizedValues[locale.languageCode]!['minimumCharacters']!;
  String get signUpWithGoogle =>
      localizedValues[locale.languageCode]!['signUpWithGoogle']!;
  String get signUpWithApple =>
      localizedValues[locale.languageCode]!['signUpWithApple']!;
  String get welcomeSuccessfulRegistration =>
      localizedValues[locale.languageCode]!['welcomeSuccessfulRegistration']!;
  String get errorOccurred =>
      localizedValues[locale.languageCode]!['errorOccurred']!;
  String get alreadyHaveAccount =>
      localizedValues[locale.languageCode]!['alreadyHaveAccount']!;
  String get signInHere =>
      localizedValues[locale.languageCode]!['signInHere']!;
  String get welcomeUser =>
      localizedValues[locale.languageCode]!['welcomeUser']!;
  String get email => localizedValues[locale.languageCode]!['email']!;
  String get enterEmail =>
      localizedValues[locale.languageCode]!['enterEmail']!;
  String get password => localizedValues[locale.languageCode]!['password']!;
  String get enterPassword =>
      localizedValues[locale.languageCode]!['enterPassword']!;
  String get signIn => localizedValues[locale.languageCode]!['signIn']!;
  String get incorrectUserPassword =>
      localizedValues[locale.languageCode]!['incorrectUserPassword']!;
  String get serverConnectionError =>
      localizedValues[locale.languageCode]!['serverConnectionError']!;
  String get or => localizedValues[locale.languageCode]!['or']!;
  String get signInWithGoogle =>
      localizedValues[locale.languageCode]!['signInWithGoogle']!;
  String get signInWithApple =>
      localizedValues[locale.languageCode]!['signInWithApple']!;
  String get noAccount => localizedValues[locale.languageCode]!['noAccount']!;
  String get createHere =>
      localizedValues[locale.languageCode]!['createHere']!;

  String get onboardingTitle1 =>
      localizedValues[locale.languageCode]!['onboardingTitle1']!;
  String get onboardingSubtitle1 =>
      localizedValues[locale.languageCode]!['onboardingSubtitle1']!;

  String get appTitle => localizedValues[locale.languageCode]!['appTitle']!;
  String get searchingTechnician =>
      localizedValues[locale.languageCode]!['searchingTechnician']!;
  String get technicianArriving =>
      localizedValues[locale.languageCode]!['technicianArriving']!;
  String get minutes => localizedValues[locale.languageCode]!['minutes']!;
  String get estimated => localizedValues[locale.languageCode]!['estimated']!;
  String get arrival => localizedValues[locale.languageCode]!['arrival']!;
  String get connector => localizedValues[locale.languageCode]!['connector']!;
  String get estimatedTime =>
      localizedValues[locale.languageCode]!['estimatedTime']!;
  String get estimatedCost =>
      localizedValues[locale.languageCode]!['estimatedCost']!;
  String get cancelSearch =>
      localizedValues[locale.languageCode]!['cancelSearch']!;

// Technician Registration getters
  String get createTechnicianAccount =>
      localizedValues[locale.languageCode]!['createTechnicianAccount']!;
  String get completeTechnicianForm =>
      localizedValues[locale.languageCode]!['completeTechnicianForm']!;
  String get emailAddress =>
      localizedValues[locale.languageCode]!['emailAddress']!;
  String get baseLocation =>
      localizedValues[locale.languageCode]!['baseLocation']!;
  String get selectLocationOnMap =>
      localizedValues[locale.languageCode]!['selectLocationOnMap']!;

// Optional Documentation
  String get optionalDocumentation =>
      localizedValues[locale.languageCode]!['optionalDocumentation']!;
  String get driverLicenseNumber =>
      localizedValues[locale.languageCode]!['driverLicenseNumber']!;
  String get enterLicenseNumber =>
      localizedValues[locale.languageCode]!['enterLicenseNumber']!;
  String get idPhotoOrCertification =>
      localizedValues[locale.languageCode]!['idPhotoOrCertification']!;
  String get selectFile =>
      localizedValues[locale.languageCode]!['selectFile']!;

// Services
  String get servicesOffered =>
      localizedValues[locale.languageCode]!['servicesOffered']!;
  String get jumpStart => localizedValues[locale.languageCode]!['jumpStart']!;
  String get evCharging =>
      localizedValues[locale.languageCode]!['evCharging']!;
  String get tireChange =>
      localizedValues[locale.languageCode]!['tireChange']!;
  String get lockout => localizedValues[locale.languageCode]!['lockout']!;
  String get fuelDelivery =>
      localizedValues[locale.languageCode]!['fuelDelivery']!;
  String get other => localizedValues[locale.languageCode]!['other']!;
  String get otherService =>
      localizedValues[locale.languageCode]!['otherService']!;
  String get describeService =>
      localizedValues[locale.languageCode]!['describeService']!;


// Agregar estos getters a tu clase AppLocalizations:

// Loading and error states
String get loadingInformation => localizedValues[locale.languageCode]?['loadingInformation'] ?? 'Loading information...';

String errorMessage(String error) => 
    (localizedValues[locale.languageCode]?['errorMessage'] ?? 'Error: {error}')
    .replaceAll('{error}', error);

String get retry => localizedValues[locale.languageCode]?['retry'] ?? 'Retry';

// Form sections
String get basicInformation => localizedValues[locale.languageCode]?['basicInformation'] ?? 'Basic Information';
String get identification => localizedValues[locale.languageCode]?['identification'] ?? 'Identification';
String get technicalSpecifications => localizedValues[locale.languageCode]?['technicalSpecifications'] ?? 'Technical Specifications';

// Form hints
String get brandHint => localizedValues[locale.languageCode]?['brandHint'] ?? 'E.g., Tesla, Nissan';
String get modelExampleHint => localizedValues[locale.languageCode]?['modelExampleHint'] ?? 'E.g., Model 3, Leaf';
String get yearHint => localizedValues[locale.languageCode]?['yearHint'] ?? 'E.g., 2024';
String get plateExampleHint => localizedValues[locale.languageCode]?['plateExampleHint'] ?? 'E.g., ABC-123';

// Validation
String get requiredField => localizedValues[locale.languageCode]?['requiredField'] ?? 'This field is required';

// Success messages
String get updateSuccessful => localizedValues[locale.languageCode]?['updateSuccessful'] ?? 'Update Successful!';
String get vehicleUpdateSuccessMessage => localizedValues[locale.languageCode]?['vehicleUpdateSuccessMessage'] ?? 'Your vehicle information has been updated successfully.';
String get continueButton => localizedValues[locale.languageCode]?['continueButton'] ?? 'Continue';

// Agregar también los campos básicos del formulario que necesitarás:
String get vehicleInformation => localizedValues[locale.languageCode]?['vehicleInformation'] ?? 'Vehicle Information';
String get make => localizedValues[locale.languageCode]?['make'] ?? 'Make';
String get model => localizedValues[locale.languageCode]?['model'] ?? 'Model';
String get year => localizedValues[locale.languageCode]?['year'] ?? 'Year';
String get plate => localizedValues[locale.languageCode]?['plate'] ?? 'License Plate';
String get color => localizedValues[locale.languageCode]?['color'] ?? 'Color';
String get connectorType => localizedValues[locale.languageCode]?['connectorType'] ?? 'Connector Type';
String get selectConnectorType => localizedValues[locale.languageCode]?['selectConnectorType'] ?? 'Select connector type';
String get validYearRequired => localizedValues[locale.languageCode]?['validYearRequired'] ?? 'Enter a valid year';
String get selectConnectorRequired => localizedValues[locale.languageCode]?['selectConnectorRequired'] ?? 'Select a connector type';
String get saveChanges => localizedValues[locale.languageCode]?['saveChanges'] ?? 'Save Changes';
String get errorLoadingData => localizedValues[locale.languageCode]?['errorLoadingData'] ?? 'Error loading data';

// Colores
String get white => localizedValues[locale.languageCode]?['white'] ?? 'White';
String get black => localizedValues[locale.languageCode]?['black'] ?? 'Black';
String get gray => localizedValues[locale.languageCode]?['gray'] ?? 'Gray';
String get silver => localizedValues[locale.languageCode]?['silver'] ?? 'Silver';
String get red => localizedValues[locale.languageCode]?['red'] ?? 'Red';
String get blue => localizedValues[locale.languageCode]?['blue'] ?? 'Blue';
String get green => localizedValues[locale.languageCode]?['green'] ?? 'Green';
String get yellow => localizedValues[locale.languageCode]?['yellow'] ?? 'Yellow';
 
// Actions
  String get selectLocation =>
      localizedValues[locale.languageCode]!['selectLocation']!;
  String get uploadFile =>
      localizedValues[locale.languageCode]!['uploadFile']!;

// Messages
  String get registrationSuccessful =>
      localizedValues[locale.languageCode]!['registrationSuccessful']!;
  String get registrationError =>
      localizedValues[locale.languageCode]!['registrationError']!;
  String get fileSelectionError =>
      localizedValues[locale.languageCode]!['fileSelectionError']!;

  String get technicianConfirmed =>
      localizedValues[locale.languageCode]!['technicianConfirmed']!;
  String get serviceInProgress =>
      localizedValues[locale.languageCode]!['serviceInProgress']!;
  String get chargingVehicle =>
      localizedValues[locale.languageCode]!['chargingVehicle']!;
  String get requestCharge =>
      localizedValues[locale.languageCode]!['requestCharge']!;
  String get viewActiveService =>
      localizedValues[locale.languageCode]!['viewActiveService']!;
  String get youHaveActiveService =>
      localizedValues[locale.languageCode]!['youHaveActiveService']!;
  String get tapToFindTechnician =>
      localizedValues[locale.languageCode]!['tapToFindTechnician']!;
  String get cancelService =>
      localizedValues[locale.languageCode]!['cancelService']!;
  String get followRealTime =>
      localizedValues[locale.languageCode]!['followRealTime']!;
  String get serviceCompleted =>
      localizedValues[locale.languageCode]!['serviceCompleted']!;
  String get howWasExperience =>
      localizedValues[locale.languageCode]!['howWasExperience']!;
  String get addComment =>
      localizedValues[locale.languageCode]!['addComment']!;
  String get skip => localizedValues[locale.languageCode]!['skip']!;
  String get send => localizedValues[locale.languageCode]!['send']!;
  String get locationRequired =>
      localizedValues[locale.languageCode]!['locationRequired']!;
  String get locationNeeded =>
      localizedValues[locale.languageCode]!['locationNeeded']!;
  String get activate => localizedValues[locale.languageCode]!['activate']!;
  String get permissionDenied =>
      localizedValues[locale.languageCode]!['permissionDenied']!;
  String get cannotContinue =>
      localizedValues[locale.languageCode]!['cannotContinue']!;
  String get goToSettings =>
      localizedValues[locale.languageCode]!['goToSettings']!;
  String get vehicleRegistration =>
      localizedValues[locale.languageCode]!['vehicleRegistration']!;
  String get vehicleNeeded =>
      localizedValues[locale.languageCode]!['vehicleNeeded']!;
  String get whyNeeded => localizedValues[locale.languageCode]!['whyNeeded']!;
  String get whyNeededDetails =>
      localizedValues[locale.languageCode]!['whyNeededDetails']!;
  String get registerVehicle =>
      localizedValues[locale.languageCode]!['registerVehicle']!;
  String get activeService =>
      localizedValues[locale.languageCode]!['activeService']!;
  String get youHaveActiveServiceDialog =>
      localizedValues[locale.languageCode]!['youHaveActiveServiceDialog']!;
  String get request => localizedValues[locale.languageCode]!['request']!;
  String get status => localizedValues[locale.languageCode]!['status']!;
  String get requested => localizedValues[locale.languageCode]!['requested']!;
  String get whatToDo => localizedValues[locale.languageCode]!['whatToDo']!;
  String get viewService =>
      localizedValues[locale.languageCode]!['viewService']!;
  String get timeExpired =>
      localizedValues[locale.languageCode]!['timeExpired']!;
  String get cannotCancelNow =>
      localizedValues[locale.languageCode]!['cannotCancelNow']!;
  String get technicianOnWay =>
      localizedValues[locale.languageCode]!['technicianOnWay']!;
  String get understood =>
      localizedValues[locale.languageCode]!['understood']!;
  String cancellationFee(String fee) =>
      localizedValues[locale.languageCode]!['cancellationFee']!
          .replaceAll('{fee}', fee);
  String feeApplied(String fee) =>
      localizedValues[locale.languageCode]!['feeApplied']!
          .replaceAll('{fee}', fee);
  String get technicianAssigned =>
      localizedValues[locale.languageCode]!['technicianAssigned']!;
  String get technicianAccepted =>
      localizedValues[locale.languageCode]!['technicianAccepted']!;
  String get seeProgress =>
      localizedValues[locale.languageCode]!['seeProgress']!;
  String get serviceExpired =>
      localizedValues[locale.languageCode]!['serviceExpired']!;
  String get serviceAutoCancelled =>
      localizedValues[locale.languageCode]!['serviceAutoCancelled']!;
  String get timeLimitExceeded =>
      localizedValues[locale.languageCode]!['timeLimitExceeded']!;
  String get serviceActiveHour =>
      localizedValues[locale.languageCode]!['serviceActiveHour']!;
  String get noChargesApplied =>
      localizedValues[locale.languageCode]!['noChargesApplied']!;
  String get requestNew =>
      localizedValues[locale.languageCode]!['requestNew']!;
  String get technicianCancelled =>
      localizedValues[locale.languageCode]!['technicianCancelled']!;
  String get technicianHasCancelled =>
      localizedValues[locale.languageCode]!['technicianHasCancelled']!;
  String get dontWorry => localizedValues[locale.languageCode]!['dontWorry']!;
  String get technicianCancellationReason =>
      localizedValues[locale.languageCode]!['technicianCancellationReason']!;
  String get nextStep => localizedValues[locale.languageCode]!['nextStep']!;
  String get requestImmediately =>
      localizedValues[locale.languageCode]!['requestImmediately']!;
  String get findAnotherTechnician =>
      localizedValues[locale.languageCode]!['findAnotherTechnician']!;
  String get timeWarning =>
      localizedValues[locale.languageCode]!['timeWarning']!;
  String get serviceWillExpire =>
      localizedValues[locale.languageCode]!['serviceWillExpire']!;
  String get viewDetails =>
      localizedValues[locale.languageCode]!['viewDetails']!;
  String get finalWarning =>
      localizedValues[locale.languageCode]!['finalWarning']!;
  String serviceExpireMinutes(String minutes) =>
      localizedValues[locale.languageCode]!['serviceExpireMinutes']!
          .replaceAll('{minutes}', minutes);
  String get contactTechnician =>
      localizedValues[locale.languageCode]!['contactTechnician']!;
  String get timeDetails =>
      localizedValues[locale.languageCode]!['timeDetails']!;
  String get timeRemaining =>
      localizedValues[locale.languageCode]!['timeRemaining']!;
  String get systemInfo =>
      localizedValues[locale.languageCode]!['systemInfo']!;
  String get serviceInfo =>
      localizedValues[locale.languageCode]!['serviceInfo']!;
      String get myRatings => localizedValues[locale.languageCode]!['myRatings']!;
String get summary => localizedValues[locale.languageCode]!['summary']!;
String get allReviews => localizedValues[locale.languageCode]!['allReviews']!;
String get ratingDistribution => localizedValues[locale.languageCode]!['ratingDistribution']!;
String get recentReviews => localizedValues[locale.languageCode]!['recentReviews']!;
String get viewAll => localizedValues[locale.languageCode]!['viewAll']!;
String get noReviewsYet => localizedValues[locale.languageCode]!['noReviewsYet']!;
String get completeServices => localizedValues[locale.languageCode]!['completeServices']!;
String errorLoadingReviews(String error) => 
    localizedValues[locale.languageCode]!['errorLoadingReviews']!.replaceAll('{error}', error);
String reviewsCount(String count) => 
    localizedValues[locale.languageCode]!['reviewsCount']!.replaceAll('{count}', count);

  // Additional getters for new strings
  String get chatWithTechnician =>
      localizedValues[locale.languageCode]!['chatWithTechnician']!;
  String get cancellationTimeExpired =>
      localizedValues[locale.languageCode]!['cancellationTimeExpired']!;
  String get serviceCancelled =>
      localizedValues[locale.languageCode]!['serviceCancelled']!;
  String get serviceCancelledSuccessfully =>
      localizedValues[locale.languageCode]!['serviceCancelledSuccessfully']!;
  String get preparingEquipment =>
      localizedValues[locale.languageCode]!['preparingEquipment']!;
  String get technicianOnSite =>
      localizedValues[locale.languageCode]!['technicianOnSite']!;
  String get equipmentStatus =>
      localizedValues[locale.languageCode]!['equipmentStatus']!;
  String get preparingCharge =>
      localizedValues[locale.languageCode]!['preparingCharge']!;
  String get notCancellable =>
      localizedValues[locale.languageCode]!['notCancellable']!;
  String get timeToCancel =>
      localizedValues[locale.languageCode]!['timeToCancel']!;
  String get lastMinute =>
      localizedValues[locale.languageCode]!['lastMinute']!;
  String get minutesRemaining =>
      localizedValues[locale.languageCode]!['minutesRemaining']!;
  String get findingBestTechnician =>
      localizedValues[locale.languageCode]!['findingBestTechnician']!;
  String get thankYouForUsingVoltGo =>
      localizedValues[locale.languageCode]!['thankYouForUsingVoltGo']!;
  String get total => localizedValues[locale.languageCode]!['total']!;
  String get close => localizedValues[locale.languageCode]!['close']!;
  String get technicianWorkingOnVehicle =>
      localizedValues[locale.languageCode]!['technicianWorkingOnVehicle']!;
  String get since => localizedValues[locale.languageCode]!['since']!;
  String get initial => localizedValues[locale.languageCode]!['initial']!;
  String get time => localizedValues[locale.languageCode]!['time']!;
  String get technicianPreparingEquipment =>
      localizedValues[locale.languageCode]!['technicianPreparingEquipment']!;
  String get viewTechnicianOnSite =>
      localizedValues[locale.languageCode]!['viewTechnicianOnSite']!;
  String get chat => localizedValues[locale.languageCode]!['chat']!;
  String get thankYouForRating =>
      localizedValues[locale.languageCode]!['thankYouForRating']!;
// Add these getter methods to your AppLocalizations class after the existing ones:

// Processing and loading
  String get processingRequest =>
      localizedValues[locale.languageCode]!['processingRequest']!;
  String get errorLoadingMap =>
      localizedValues[locale.languageCode]!['errorLoadingMap']!;
  String get processing =>
      localizedValues[locale.languageCode]!['processing']!;

// Vehicle verification
  String get vehicleVerification =>
      localizedValues[locale.languageCode]!['vehicleVerification']!;
  String get checkingVehicle =>
      localizedValues[locale.languageCode]!['checkingVehicle']!;
  String get verifyingInformation =>
      localizedValues[locale.languageCode]!['verifyingInformation']!;
  String get verificationNeeded =>
      localizedValues[locale.languageCode]!['verificationNeeded']!;
  String get couldNotVerifyVehicle =>
      localizedValues[locale.languageCode]!['couldNotVerifyVehicle']!;
  String get goToRegistration =>
      localizedValues[locale.languageCode]!['goToRegistration']!;

// ▼▼▼ AGREGAR ESTOS GETTERS AL FINAL DE TU CLASE ▼▼▼
 
// Getters para agregar a la clase AppLocalizations:
String get serviceDetails => localizedValues[locale.languageCode]!['serviceDetails']!;
String get completed => localizedValues[locale.languageCode]!['completed']!;
String get cancelled => localizedValues[locale.languageCode]!['cancelled']!;
 String get inProgress => localizedValues[locale.languageCode]!['inProgress']!;
String get errorLoadingDetails => localizedValues[locale.languageCode]!['errorLoadingDetails']!;
 String get additionalDetailsNotAvailable => localizedValues[locale.languageCode]!['additionalDetailsNotAvailable']!;
String get technicalDetailsWillBeAdded => localizedValues[locale.languageCode]!['technicalDetailsWillBeAdded']!;
String get serviceInformation => localizedValues[locale.languageCode]!['serviceInformation']!;
String get date => localizedValues[locale.languageCode]!['date']!;
  String get serviceId => localizedValues[locale.languageCode]!['serviceId']!;
String get serviceTimeline => localizedValues[locale.languageCode]!['serviceTimeline']!;
String get started => localizedValues[locale.languageCode]!['started']!;
String get batteryInformation => localizedValues[locale.languageCode]!['batteryInformation']!;
String get initialLevel => localizedValues[locale.languageCode]!['initialLevel']!;
String get chargeTime => localizedValues[locale.languageCode]!['chargeTime']!;
String get serviceNotes => localizedValues[locale.languageCode]!['serviceNotes']!;
String get servicePhotos => localizedValues[locale.languageCode]!['servicePhotos']!;
 String get before => localizedValues[locale.languageCode]!['before']!;
String get after => localizedValues[locale.languageCode]!['after']!;
 String get loading => localizedValues[locale.languageCode]!['loading']!;
String get errorLoadingImage => localizedValues[locale.languageCode]!['errorLoadingImage']!;
String get paymentInformation => localizedValues[locale.languageCode]!['paymentInformation']!;
String get totalCost => localizedValues[locale.languageCode]!['totalCost']!;

 String get yourRating => localizedValues[locale.languageCode]!['yourRating']!;
String get averageRating => localizedValues[locale.languageCode]!['averageRating']!;

// TÉRMINOS Y CONDICIONES - GETTERS
String get termsAndConditions => 
    localizedValues[locale.languageCode]!['termsAndConditions']!;
String get lastUpdated => 
    localizedValues[locale.languageCode]!['lastUpdated']!;
String get acceptance => 
    localizedValues[locale.languageCode]!['acceptance']!;
String get acceptanceContent => 
    localizedValues[locale.languageCode]!['acceptanceContent']!;
String get serviceDescription => 
    localizedValues[locale.languageCode]!['serviceDescription']!;
String get serviceDescriptionContent => 
    localizedValues[locale.languageCode]!['serviceDescriptionContent']!;
String get userResponsibilities => 
    localizedValues[locale.languageCode]!['userResponsibilities']!;
String get userResponsibilitiesContent => 
    localizedValues[locale.languageCode]!['userResponsibilitiesContent']!;
String get technicianObligations => 
    localizedValues[locale.languageCode]!['technicianObligations']!;
String get technicianObligationsContent => 
    localizedValues[locale.languageCode]!['technicianObligationsContent']!;
String get paymentTerms => 
    localizedValues[locale.languageCode]!['paymentTerms']!;
String get paymentTermsContent => 
    localizedValues[locale.languageCode]!['paymentTermsContent']!;
String get limitation => 
    localizedValues[locale.languageCode]!['limitation']!;
String get limitationContent => 
    localizedValues[locale.languageCode]!['limitationContent']!;
String get modifications => 
    localizedValues[locale.languageCode]!['modifications']!;
String get modificationsContent => 
    localizedValues[locale.languageCode]!['modificationsContent']!;
String get contactUs => 
    localizedValues[locale.languageCode]!['contactUs']!;
String get questionsContact => 
    localizedValues[locale.languageCode]!['questionsContact']!;

String chatWithName(String name) => 
  localizedValues[locale.languageCode]!['chatWith']!.replaceAll('{name}', name);

String serviceNumberId(String id) => 
  localizedValues[locale.languageCode]!['serviceNumber']!.replaceAll('{id}', id);

String errorSendingMessageText(String error) => 
  localizedValues[locale.languageCode]!['errorSendingMessage']!.replaceAll('{error}', error);

String chatWith(String name) => 
  localizedValues[locale.languageCode]!['chatWith']!.replaceAll('{name}', name);
String serviceNumber(String id) => 
  localizedValues[locale.languageCode]!['serviceNumber']!.replaceAll('{id}', id);
String get loadingMessages => localizedValues[locale.languageCode]!['loadingMessages']!;
String get errorLoadingChat => localizedValues[locale.languageCode]!['errorLoadingChat']!;
String get tryAgain => localizedValues[locale.languageCode]!['tryAgain']!;
String get startConversation => localizedValues[locale.languageCode]!['startConversation']!;
String get communicateWithTechnician => localizedValues[locale.languageCode]!['communicateWithTechnician']!;
String get communicateWithClient => localizedValues[locale.languageCode]!['communicateWithClient']!;
String get writeMessage => localizedValues[locale.languageCode]!['writeMessage']!;
String get sending => localizedValues[locale.languageCode]!['sending']!;
String errorSendingMessage(String error) => 
  localizedValues[locale.languageCode]!['errorSendingMessage']!.replaceAll('{error}', error);
String get updateMessages => localizedValues[locale.languageCode]!['updateMessages']!;
String get statusPending => localizedValues[locale.languageCode]!['statusPending']!;
String get statusAccepted => localizedValues[locale.languageCode]!['statusAccepted']!;
String get statusEnRoute => localizedValues[locale.languageCode]!['statusEnRoute']!;
String get statusOnSite => localizedValues[locale.languageCode]!['statusOnSite']!;
String get statusCharging => localizedValues[locale.languageCode]!['statusCharging']!;
String get statusCompleted => localizedValues[locale.languageCode]!['statusCompleted']!;
String get statusCancelled => localizedValues[locale.languageCode]!['statusCancelled']!;

// POLÍTICA DE PRIVACIDAD - GETTERS
String get privacyPolicy => 
    localizedValues[locale.languageCode]!['privacyPolicy']!;
String get dataCollection => 
    localizedValues[locale.languageCode]!['dataCollection']!;
String get dataCollectionContent => 
    localizedValues[locale.languageCode]!['dataCollectionContent']!;
String get dataUsage => 
    localizedValues[locale.languageCode]!['dataUsage']!;
String get dataUsageContent => 
    localizedValues[locale.languageCode]!['dataUsageContent']!;
String get locationData => 
    localizedValues[locale.languageCode]!['locationData']!;
String get locationDataContent => 
    localizedValues[locale.languageCode]!['locationDataContent']!;
String get dataSharing => 
    localizedValues[locale.languageCode]!['dataSharing']!;
String get dataSharingContent => 
    localizedValues[locale.languageCode]!['dataSharingContent']!;
String get dataSecurity => 
    localizedValues[locale.languageCode]!['dataSecurity']!;
String get dataSecurityContent => 
    localizedValues[locale.languageCode]!['dataSecurityContent']!;
String get userRights => 
    localizedValues[locale.languageCode]!['userRights']!;
String get userRightsContent => 
    localizedValues[locale.languageCode]!['userRightsContent']!;
String get cookies => 
    localizedValues[locale.languageCode]!['cookies']!;
String get cookiesContent => 
    localizedValues[locale.languageCode]!['cookiesContent']!;
String get thirdPartyServices => 
    localizedValues[locale.languageCode]!['thirdPartyServices']!;
String get thirdPartyServicesContent => 
    localizedValues[locale.languageCode]!['thirdPartyServicesContent']!;
String get dataRetention => 
    localizedValues[locale.languageCode]!['dataRetention']!;
String get dataRetentionContent => 
    localizedValues[locale.languageCode]!['dataRetentionContent']!;
String get minorPrivacy => 
    localizedValues[locale.languageCode]!['minorPrivacy']!;
String get minorPrivacyContent => 
    localizedValues[locale.languageCode]!['minorPrivacyContent']!;
String get privacyQuestions => 
    localizedValues[locale.languageCode]!['privacyQuestions']!;

 


String get save => 
    localizedValues[locale.languageCode]!['save']!; 
String get technician => 
    localizedValues[locale.languageCode]!['technician']!;
String get contactInformation => 
    localizedValues[locale.languageCode]!['contactInformation']!; 
String get fieldRequired => 
    localizedValues[locale.languageCode]!['fieldRequired']!;
String get phoneMinLength => 
    localizedValues[locale.languageCode]!['phoneMinLength']!;
String get professionalInformation => 
    localizedValues[locale.languageCode]!['professionalInformation']!;
 
String get licenseNumber => 
    localizedValues[locale.languageCode]!['licenseNumber']!; 
String get selectServices => 
    localizedValues[locale.languageCode]!['selectServices']!;
String get selectAtLeastOneService => 
    localizedValues[locale.languageCode]!['selectAtLeastOneService']!;
String get identificationDocument => 
    localizedValues[locale.languageCode]!['identificationDocument']!;
String get documentSelected => 
    localizedValues[locale.languageCode]!['documentSelected']!;
String get remove => 
    localizedValues[locale.languageCode]!['remove']!;
String get uploadDocument => 
    localizedValues[locale.languageCode]!['uploadDocument']!;
String get changeDocument => 
    localizedValues[locale.languageCode]!['changeDocument']!;
String get documentInfo => 
    localizedValues[locale.languageCode]!['documentInfo']!; 
String get noChanges => 
    localizedValues[locale.languageCode]!['noChanges']!;
String get profileUpdated => 
    localizedValues[locale.languageCode]!['profileUpdated']!;
String get profileUpdatedSuccessfully => 
    localizedValues[locale.languageCode]!['profileUpdatedSuccessfully']!;
String get accept => 
    localizedValues[locale.languageCode]!['accept']!; 
String get unsavedChanges => 
    localizedValues[locale.languageCode]!['unsavedChanges']!;
    
String get hoy => 
    localizedValues[locale.languageCode]!['hoy']!;
String get discardChanges => 
    localizedValues[locale.languageCode]!['discardChanges']!;
String get discard => 
    localizedValues[locale.languageCode]!['discard']!;

  String get syncInProgress =>
      localizedValues[locale.languageCode]!['syncInProgress']!;
  String get vehicleRegisteredCorrectly =>
      localizedValues[locale.languageCode]!['vehicleRegisteredCorrectly']!;
  String get syncOptions =>
      localizedValues[locale.languageCode]!['syncOptions']!;
  String get syncOptionsText =>
      localizedValues[locale.languageCode]!['syncOptionsText']!;
   String get continueAnyway =>
      localizedValues[locale.languageCode]!['continueAnyway']!;

  String get couldNotGetLocation =>
      localizedValues[locale.languageCode]!['couldNotGetLocation']!;
  String get errorRequestingService =>
      localizedValues[locale.languageCode]!['errorRequestingService']!;
  String get noTechniciansAvailable =>
      localizedValues[locale.languageCode]!['noTechniciansAvailable']!;
  String get needToRegisterVehicle =>
      localizedValues[locale.languageCode]!['needToRegisterVehicle']!;
  String get authorizationError =>
      localizedValues[locale.languageCode]!['authorizationError']!;
  String get sessionExpired =>
      localizedValues[locale.languageCode]!['sessionExpired']!;
  String get serviceUpdatedCorrectly =>
      localizedValues[locale.languageCode]!['serviceUpdatedCorrectly']!;

  String get pleaseWait =>
      localizedValues[locale.languageCode]!['pleaseWait']!;
  String get pleaseWaitMoment =>
      localizedValues[locale.languageCode]!['pleaseWaitMoment']!;

// Searching
  String get nearbyTechnicians =>
      localizedValues[locale.languageCode]!['nearbyTechnicians']!;
  String get thisCanTakeSeconds =>
      localizedValues[locale.languageCode]!['thisCanTakeSeconds']!;
  String get searchingDots =>
      localizedValues[locale.languageCode]!['searchingDots']!;

// Status strings
  String get onSite => localizedValues[locale.languageCode]!['onSite']!;
   String get unknownStatus =>
      localizedValues[locale.languageCode]!['unknownStatus']!;

// Time-related
  String get fewSecondsAgo =>
      localizedValues[locale.languageCode]!['fewSecondsAgo']!;
  String get minutesAgo =>
      localizedValues[locale.languageCode]!['minutesAgo']!;
  String get hoursAgo => localizedValues[locale.languageCode]!['hoursAgo']!;
  String get daysAgo => localizedValues[locale.languageCode]!['daysAgo']!;
  String get ago => localizedValues[locale.languageCode]!['ago']!;

// Vehicle and technician info
  String get serviceVehicle =>
      localizedValues[locale.languageCode]!['serviceVehicle']!;
  String get notSpecified =>
      localizedValues[locale.languageCode]!['notSpecified']!; 



    String get otros => localizedValues[locale.languageCode]!['otros']!;
    String get tyc => localizedValues[locale.languageCode]!['tyc']!;
    String get politicadeprivacidad => localizedValues[locale.languageCode]!['politicadeprivacidad']!;

// Cancellation errors and messages
  String get errorCancellingService =>
      localizedValues[locale.languageCode]!['errorCancellingService']!;
  String get noActiveServiceToCancel =>
      localizedValues[locale.languageCode]!['noActiveServiceToCancel']!;
  String get timeElapsedMinutes =>
      localizedValues[locale.languageCode]!['timeElapsedMinutes']!;
  String get limitMinutes =>
      localizedValues[locale.languageCode]!['limitMinutes']!;
  String get cannotCancelServiceNow =>
      localizedValues[locale.languageCode]!['cannotCancelServiceNow']!;
  String get technicianAlreadyOnWay =>
      localizedValues[locale.languageCode]!['technicianAlreadyOnWay']!;
  String get serviceCancelledWithFee =>
      localizedValues[locale.languageCode]!['serviceCancelledWithFee']!;
  String get serviceCancelledSuccessfullyMessage => localizedValues[
      locale.languageCode]!['serviceCancelledSuccessfullyMessage']!;

// Basic responses
  String get no => localizedValues[locale.languageCode]!['no']!;
  String get yes => localizedValues[locale.languageCode]!['yes']!;
  String get yesCancel => localizedValues[locale.languageCode]!['yesCancel']!;
  String get areYouSureCancelService =>
      localizedValues[locale.languageCode]!['areYouSureCancelService']!;
  String get cancelRide =>
      localizedValues[locale.languageCode]!['cancelRide']!;

// Cancellation time and expiration
  String get blockedFromCancelling =>
      localizedValues[locale.languageCode]!['blockedFromCancelling']!;
  String get timeForCancellingExpired =>
      localizedValues[locale.languageCode]!['timeForCancellingExpired']!;
  String get serviceHasExceededTimeLimit =>
      localizedValues[locale.languageCode]!['serviceHasExceededTimeLimit']!;
  String serviceActiveMinutes(String minutes) =>
      localizedValues[locale.languageCode]!['serviceActiveMinutes']!
          .replaceAll('{minutes}', minutes);
  String get cancelExpiredService =>
      localizedValues[locale.languageCode]!['cancelExpiredService']!;
  String get forceExpireService =>
      localizedValues[locale.languageCode]!['forceExpireService']!;
  String get areYouSureCancelExpiredService =>
      localizedValues[locale.languageCode]!['areYouSureCancelExpiredService']!;

// Service information
   
  String get timeElapsed =>
      localizedValues[locale.languageCode]!['timeElapsed']!;
  String get currentStatus =>
      localizedValues[locale.languageCode]!['currentStatus']!;
  String get noChargesForCancellation =>
      localizedValues[locale.languageCode]!['noChargesForCancellation']!;
  String get canRequestNewServiceImmediately => localizedValues[
      locale.languageCode]!['canRequestNewServiceImmediately']!;
  String get yesCancelService =>
      localizedValues[locale.languageCode]!['yesCancelService']!;

// Service expiration
  String get serviceExpiredAutomatically =>
      localizedValues[locale.languageCode]!['serviceExpiredAutomatically']!;
  String get serviceActiveForHourWithoutCompletion => localizedValues[
      locale.languageCode]!['serviceActiveForHourWithoutCompletion']!;
  String get noChargesAppliedForExpiredService => localizedValues[
      locale.languageCode]!['noChargesAppliedForExpiredService']!;
  String get canRequestNewService =>
      localizedValues[locale.languageCode]!['canRequestNewService']!;
  String get requestNewService =>
      localizedValues[locale.languageCode]!['requestNewService']!;
  String get searchForAnotherTechnician =>
      localizedValues[locale.languageCode]!['searchForAnotherTechnician']!;

// Cancellation reasons
  String get emergenciesOrTechnicalIssues =>
      localizedValues[locale.languageCode]!['emergenciesOrTechnicalIssues']!;
  String get canRequestNewServiceNow =>
      localizedValues[locale.languageCode]!['canRequestNewServiceNow']!;
  String get ifTechnicianHasNotArrived =>
      localizedValues[locale.languageCode]!['ifTechnicianHasNotArrived']!;

// Service details
  String get serviceDetailsInfo =>
      localizedValues[locale.languageCode]!['serviceDetailsInfo']!;
  String serviceDetailsText(String minutes) =>
      localizedValues[locale.languageCode]!['serviceDetailsText']!
          .replaceAll('{minutes}', minutes);

// Status change notifications
  String get technicianHasArrived =>
      localizedValues[locale.languageCode]!['technicianHasArrived']!;
  String get technicianAtLocationPreparingEquipment => localizedValues[
      locale.languageCode]!['technicianAtLocationPreparingEquipment']!;
  String get serviceStarted =>
      localizedValues[locale.languageCode]!['serviceStarted']!;
  String get technicianStartedChargingVehicle => localizedValues[
      locale.languageCode]!['technicianStartedChargingVehicle']!;
  String get serviceCompletedSuccessfully =>
      localizedValues[locale.languageCode]!['serviceCompletedSuccessfully']!;
  String get vehicleChargedSuccessfully =>
      localizedValues[locale.languageCode]!['vehicleChargedSuccessfully']!;
  String get statusUpdated =>
      localizedValues[locale.languageCode]!['statusUpdated']!;
  String get serviceStatusChanged =>
      localizedValues[locale.languageCode]!['serviceStatusChanged']!;

// Status change titles and messages
  String get technicianConfirmedTitle =>
      localizedValues[locale.languageCode]!['technicianConfirmedTitle']!;
  String get technicianConfirmedMessage =>
      localizedValues[locale.languageCode]!['technicianConfirmedMessage']!;
  String get technicianEnRoute =>
      localizedValues[locale.languageCode]!['technicianEnRoute']!;
  String get technicianHeadingToLocation =>
      localizedValues[locale.languageCode]!['technicianHeadingToLocation']!;
  String get technicianArrivedTitle =>
      localizedValues[locale.languageCode]!['technicianArrivedTitle']!;
  String get technicianArrivedMessage =>
      localizedValues[locale.languageCode]!['technicianArrivedMessage']!;
  String get serviceInitiatedTitle =>
      localizedValues[locale.languageCode]!['serviceInitiatedTitle']!;
  String get serviceInitiatedMessage =>
      localizedValues[locale.languageCode]!['serviceInitiatedMessage']!;
  String get serviceCompletedTitle =>
      localizedValues[locale.languageCode]!['serviceCompletedTitle']!;
  String get serviceCompletedMessage =>
      localizedValues[locale.languageCode]!['serviceCompletedMessage']!;

// Service progress
  String get technicianWillDocumentProgress =>
      localizedValues[locale.languageCode]!['technicianWillDocumentProgress']!;
  String get serviceProgress =>
      localizedValues[locale.languageCode]!['serviceProgress']!;
  String get from => localizedValues[locale.languageCode]!['from']!;
  String get batteryLevel =>
      localizedValues[locale.languageCode]!['batteryLevel']!;
  String get chargingTime =>
      localizedValues[locale.languageCode]!['chargingTime']!;
  String get min => localizedValues[locale.languageCode]!['min']!;
  String get waitingForRequests =>
      localizedValues[locale.languageCode]!['waitingForRequests']!;
  String get reviewingIncomingRequest =>
      localizedValues[locale.languageCode]!['reviewingIncomingRequest']!;
  String get headToClientLocation =>
      localizedValues[locale.languageCode]!['headToClientLocation']!;
  String get chargingClientVehicle =>
      localizedValues[locale.languageCode]!['chargingClientVehicle']!;

// Service Request Panel getters
  String get newChargeRequest =>
      localizedValues[locale.languageCode]!['newChargeRequest']!;
  String get client => localizedValues[locale.languageCode]!['client']!;
  String get estimatedEarnings =>
      localizedValues[locale.languageCode]!['estimatedEarnings']!;
  String get reject => localizedValues[locale.languageCode]!['reject']!;
 
// Navigation getters
  String get navigateToClient =>
      localizedValues[locale.languageCode]!['navigateToClient']!;
  String get openInMaps =>
      localizedValues[locale.languageCode]!['openInMaps']!;
  String get googleMaps =>
      localizedValues[locale.languageCode]!['googleMaps']!;
  String get navigationWithTraffic =>
      localizedValues[locale.languageCode]!['navigationWithTraffic']!;
  String get waze => localizedValues[locale.languageCode]!['waze']!;
  String get optimizedRoutes =>
      localizedValues[locale.languageCode]!['optimizedRoutes']!;
  String get navigate => localizedValues[locale.languageCode]!['navigate']!;
  String get call => localizedValues[locale.languageCode]!['call']!;

  String get arrivedAtSite =>
      localizedValues[locale.languageCode]!['arrivedAtSite']!;
  String get finishService =>
      localizedValues[locale.languageCode]!['finishService']!;
  String get chargeServiceRequested =>
      localizedValues[locale.languageCode]!['chargeServiceRequested']!;

 
  String get speed => localizedValues[locale.languageCode]!['speed']!; 
   String get noPhoneNumberAvailable => localizedValues[locale.languageCode]!['noPhoneNumberAvailable']!;
  String get couldNotOpenPhoneApp => localizedValues[locale.languageCode]!['couldNotOpenPhoneApp']!;
  String get errorMakingCall => localizedValues[locale.languageCode]!['errorMakingCall']!;
  String get errorRefreshingServiceData => localizedValues[locale.languageCode]!['errorRefreshingServiceData']!; 

// Success & Error Messages getters
  String get requestAccepted =>
      localizedValues[locale.languageCode]!['requestAccepted']!;
  String get errorAcceptingRequest =>
      localizedValues[locale.languageCode]!['errorAcceptingRequest']!;
  String get requestTakenByAnother =>
      localizedValues[locale.languageCode]!['requestTakenByAnother']!;
  String get noAuthorizationForRequest =>
      localizedValues[locale.languageCode]!['noAuthorizationForRequest']!; 
  String get pleaseEnableLocation =>
      localizedValues[locale.languageCode]!['pleaseEnableLocation']!;
  String get locationPermissionRequired =>
      localizedValues[locale.languageCode]!['locationPermissionRequired']!;
  String get noClientInformationAvailable =>
      localizedValues[locale.languageCode]!['noClientInformationAvailable']!;  
  String get errorChangingStatus =>
      localizedValues[locale.languageCode]!['errorChangingStatus']!;
  String get couldNotOpenGoogleMaps =>
      localizedValues[locale.languageCode]!['couldNotOpenGoogleMaps']!;
  String get wazeNotInstalled =>
      localizedValues[locale.languageCode]!['wazeNotInstalled']!;
  String get couldNotOpenWaze =>
      localizedValues[locale.languageCode]!['couldNotOpenWaze']!;
  String get noNavigationAppsAvailable =>
      localizedValues[locale.languageCode]!['noNavigationAppsAvailable']!;
  String get couldNotOpenNavigationApp =>
      localizedValues[locale.languageCode]!['couldNotOpenNavigationApp']!;
  String get requestNoLongerAvailable =>
      localizedValues[locale.languageCode]!['requestNoLongerAvailable']!;
  String get clientCancelledRequest =>
      localizedValues[locale.languageCode]!['clientCancelledRequest']!;
  String get errorCheckingStatus =>
      localizedValues[locale.languageCode]!['errorCheckingStatus']!;
  String get requestNotAuthorizedAnymore =>
      localizedValues[locale.languageCode]!['requestNotAuthorizedAnymore']!;


 
String get verified => 
    localizedValues[locale.languageCode]!['verified']!;
String get serviceLocation => 
    localizedValues[locale.languageCode]!['serviceLocation']!; 
String get veryClose => 
    localizedValues[locale.languageCode]!['veryClose']!; 
String get mediumDistance => 
    localizedValues[locale.languageCode]!['mediumDistance']!;
String get far => 
    localizedValues[locale.languageCode]!['far']!; 
String get hours => 
    localizedValues[locale.languageCode]!['hours']!;

// Online/Offline Status getters
  String get online => localizedValues[locale.languageCode]!['online']!;
  String get offline => localizedValues[locale.languageCode]!['offline']!;
  String get serviceActive =>
      localizedValues[locale.languageCode]!['serviceActive']!;
  String get disconnected =>
      localizedValues[locale.languageCode]!['disconnected']!;

// Service Cancellation getters
  String get serviceCancelledTitle =>
      localizedValues[locale.languageCode]!['serviceCancelledTitle']!;
  String get clientCancelledService =>
      localizedValues[locale.languageCode]!['clientCancelledService']!;
  String get timeCompensation =>
      localizedValues[locale.languageCode]!['timeCompensation']!;
  String get partialCompensationMessage =>
      localizedValues[locale.languageCode]!['partialCompensationMessage']!;
  String get willContinueReceivingRequests =>
      localizedValues[locale.languageCode]!['willContinueReceivingRequests']!;
  String get serviceCancelledByClient =>
      localizedValues[locale.languageCode]!['serviceCancelledByClient']!;

// Service Expiration getter
  String get serviceAutoCancelledAfterHour =>
      localizedValues[locale.languageCode]!['serviceAutoCancelledAfterHour']!;

  String get noActiveServiceFound =>
      localizedValues[locale.languageCode]!['noActiveServiceFound']!;
  String get serviceTrackingLocation =>
      localizedValues[locale.languageCode]!['serviceTrackingLocation']!;
  String get locationTrackingStopped =>
      localizedValues[locale.languageCode]!['locationTrackingStopped']!;
  String get requestListCleaned =>
      localizedValues[locale.languageCode]!['requestListCleaned']!;

// UI elements
  String get followInRealTime =>
      localizedValues[locale.languageCode]!['followInRealTime']!;
   
  String get phoneCall => localizedValues[locale.languageCode]!['phoneCall']!;
  String get sendMessage =>
      localizedValues[locale.languageCode]!['sendMessage']!;
  String get message => localizedValues[locale.languageCode]!['message']!;
  String get equipmentReady =>
      localizedValues[locale.languageCode]!['equipmentReady']!;
  String get startingCharge =>
      localizedValues[locale.languageCode]!['startingCharge']!;
  String get connectingTechnician =>
      localizedValues[locale.languageCode]!['connectingTechnician']!;

  String get serviceHistory =>
      localizedValues[locale.languageCode]!['serviceHistory']!;
  String get reviewPreviousServices =>
      localizedValues[locale.languageCode]!['reviewPreviousServices']!;
  String get all => localizedValues[locale.languageCode]!['all']!;
   String get accepted => localizedValues[locale.languageCode]!['accepted']!;
  String get enRoute => localizedValues[locale.languageCode]!['enRoute']!;
  String get charging => localizedValues[locale.languageCode]!['charging']!;
  String get yesterday => localizedValues[locale.languageCode]!['yesterday']!;
  String get errorLoadingHistory =>
      localizedValues[locale.languageCode]!['errorLoadingHistory']!;
  String get noServicesInHistory =>
      localizedValues[locale.languageCode]!['noServicesInHistory']!;
  String get requestService =>
      localizedValues[locale.languageCode]!['requestService']!;



      
  String get startCharging =>
      localizedValues[locale.languageCode]!['startCharging']!; 
  String get vehicleRegisteredSuccess =>
      localizedValues[locale.languageCode]!['vehicleRegisteredSuccess']!; 
  String get thankYouForYourRating =>
      localizedValues[locale.languageCode]!['thankYouForYourRating']!;
  String get continueText =>
      localizedValues[locale.languageCode]!['continueText']!;
 


// Títulos y navegación
  String get registerElectricVehicle =>
      localizedValues[locale.languageCode]!['registerElectricVehicle']!;
  String get step => localizedValues[locale.languageCode]!['step']!;
  String get off => localizedValues[locale.languageCode]!['of']!;
 
  String get technicalSpecs =>
      localizedValues[locale.languageCode]!['technicalSpecs']!;

// Labels de campos
  String get brand => localizedValues[locale.languageCode]!['brand']!; 

// Opciones generales
 
// Hints y placeholders
  String get writeBrandHint =>
      localizedValues[locale.languageCode]!['writeBrandHint']!;
  String get selectOrEnterBrand =>
      localizedValues[locale.languageCode]!['selectOrEnterBrand']!;
  String get modelHint => localizedValues[locale.languageCode]!['modelHint']!;
  String get plateHint => localizedValues[locale.languageCode]!['plateHint']!;
  String get specifyColor =>
      localizedValues[locale.languageCode]!['specifyColor']!;
  String get colorHint => localizedValues[locale.languageCode]!['colorHint']!;
  String get enterColor =>
      localizedValues[locale.languageCode]!['enterColor']!;

String getColorName(String colorKey) {
  return localizedValues[locale.languageCode]?[colorKey] ?? colorKey;
}


// Mensajes de éxito y error
  String get vehicleRegistrationError =>
      localizedValues[locale.languageCode]!['vehicleRegistrationError']!;
  String get vehicleRegistered =>
      localizedValues[locale.languageCode]!['vehicleRegistered']!; 

  String get loggingOut =>
      localizedValues[locale.languageCode]!['loggingOut']!;
// Mensajes de validación específicos
  String get selectBrandMessage =>
      localizedValues[locale.languageCode]!['selectBrandMessage']!;
  String get enterModelMessage =>
      localizedValues[locale.languageCode]!['enterModelMessage']!;
  String get enterYearMessage =>
      localizedValues[locale.languageCode]!['enterYearMessage']!;
  String get validYearMessage =>
      localizedValues[locale.languageCode]!['validYearMessage']!;
  String get enterPlateMessage =>
      localizedValues[locale.languageCode]!['enterPlateMessage']!;
  String get selectColorMessage =>
      localizedValues[locale.languageCode]!['selectColorMessage']!;
  String get specifyColorMessage =>
      localizedValues[locale.languageCode]!['specifyColorMessage']!;
  String get selectConnectorMessage =>
      localizedValues[locale.languageCode]!['selectConnectorMessage']!;
  String get completeRequiredFields =>
      localizedValues[locale.languageCode]!['completeRequiredFields']!;
  String get welcomeTechnician =>
      localizedValues[locale.languageCode]!['welcomeTechnician']!;

  String get noServiceHistory =>
      localizedValues[locale.languageCode]!['noServiceHistory']!;
 
  String get numbersOnly =>
      localizedValues[locale.languageCode]!['numbersOnly']!;
  String get yearRange => localizedValues[locale.languageCode]!['yearRange']!;
  String get and => localizedValues[locale.languageCode]!['and']!;
  String get plateMinLength =>
      localizedValues[locale.languageCode]!['plateMinLength']!;

// Botones de navegación
  String get previous => localizedValues[locale.languageCode]!['previous']!;
  String get next => localizedValues[locale.languageCode]!['next']!;
  String get register => localizedValues[locale.languageCode]!['register']!;
  String get searchingRequests => localizedValues[locale.languageCode]!['searchingRequests']!;

// Stats getters (faltantes) 
 
  String get noActiveService =>
      localizedValues[locale.languageCode]!['noActiveService']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
