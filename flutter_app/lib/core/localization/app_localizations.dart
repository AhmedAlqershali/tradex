import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  bool get isArabic => locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  String get appName => _value('appName');
  String get welcomeBack => _value('welcomeBack');
  String get welcomeBackMerchant => _value('welcomeBackMerchant');
  String get welcomeBackClient => _value('welcomeBackClient');
  String get login => _value('login');
  String get email => _value('email');
  String get password => _value('password');
  String get rememberMe => _value('rememberMe');
  String get forgotPassword => _value('forgotPassword');
  String get resetPassword => _value('resetPassword');
  String get sendResetLink => _value('sendResetLink');
  String get noAccount => _value('noAccount');
  String get createAccount => _value('createAccount');
  String get enterEmailPassword => _value('enterEmailPassword');
  String get enterValidEmail => _value('enterValidEmail');
  String get enterEmailPlease => _value('enterEmailPlease');
  String get otpSent => _value('otpSent');
  String get loginLoading => _value('loginLoading');
  String get verificationCode => _value('verificationCode');
  String get verificationCodeHelp => _value('verificationCodeHelp');
  String get codeRequired => _value('codeRequired');
  String get resendCode => _value('resendCode');
  String get codeResent => _value('codeResent');
  String get resendFailed => _value('resendFailed');
  String get invalidCode => _value('invalidCode');
  String get networkCheck => _value('networkCheck');
  String get pleaseChooseYourRegion => _value('pleaseChooseYourRegion');
  String get selectRegionFirst => _value('selectRegionFirst');
  String get regionSelected => _value('regionSelected');
  String get unableToGetLocation => _value('unableToGetLocation');
  String get useMyLocation => _value('useMyLocation');
  String get searchRegion => _value('searchRegion');
  String get chooseImageSource => _value('chooseImageSource');
  String get gallery => _value('gallery');
  String get camera => _value('camera');
  String get imagePickerError => _value('imagePickerError');
  String get saveChanges => _value('saveChanges');
  String get changesSaved => _value('changesSaved');
  String get unableSaveChanges => _value('unableSaveChanges');
  String get personalInfo => _value('personalInfo');
  String get fullName => _value('fullName');
  String get enterFullName => _value('enterFullName');
  String get completeProfileClient => _value('completeProfileClient');
  String get selectYourRegion => _value('selectYourRegion');
  String get regionDescription => _value('regionDescription');
  String get retry => _value('retry');
  String get continueText => _value('continueText');
  String get cancel => _value('cancel');
  String get submit => _value('submit');
  String get done => _value('done');
  String get success => _value('success');
  String get yes => _value('yes');
  String get no => _value('no');
  String get delete => _value('delete');
  String get edit => _value('edit');
  String get close => _value('close');
  String get back => _value('back');
  String get next => _value('next');
  String get registerNewAccount => _value('registerNewAccount');
  String get registerClientSubtitle => _value('registerClientSubtitle');
  String get registerMerchantSubtitle => _value('registerMerchantSubtitle');
  String get agreeTermsAndPrivacy => _value('agreeTermsAndPrivacy');
  String get alreadyHaveAccount => _value('alreadyHaveAccount');
  String get createAccountAction => _value('createAccountAction');
  String get creatingAccount => _value('creatingAccount');
  String get fieldRequired => _value('fieldRequired');
  String get completeMerchantProfile => _value('completeMerchantProfile');
  String get merchantProfileStep => _value('merchantProfileStep');
  String get merchantStoreName => _value('merchantStoreName');
  String get merchantStoreNameHint => _value('merchantStoreNameHint');
  String get merchantStoreCategory => _value('merchantStoreCategory');
  String get merchantChooseCategory => _value('merchantChooseCategory');
  String get merchantRegion => _value('merchantRegion');
  String get merchantAddressDetail => _value('merchantAddressDetail');
  String get merchantAddressHint => _value('merchantAddressHint');
  String get merchantDescription => _value('merchantDescription');
  String get merchantDescriptionHint => _value('merchantDescriptionHint');
  String get merchantWhatsApp => _value('merchantWhatsApp');
  String get merchantWorkHours => _value('merchantWorkHours');
  String get merchantWorkHoursHint => _value('merchantWorkHoursHint');
  String get merchantStoreNameRequired => _value('merchantStoreNameRequired');
  String get restaurantCategory => _value('restaurantCategory');
  String get cafesCategory => _value('cafesCategory');
  String get fashionCategory => _value('fashionCategory');
  String get workspacesCategory => _value('workspacesCategory');
  String get giftsCategory => _value('giftsCategory');
  String get shoesCategory => _value('shoesCategory');
  String get carsCategory => _value('carsCategory');
  String get jewelryCategory => _value('jewelryCategory');
  String get cosmeticsCategory => _value('cosmeticsCategory');
  String get supermarketCategory => _value('supermarketCategory');
  String get mallCategory => _value('mallCategory');
  String get storeCategoryDefault => _value('storeCategoryDefault');
  String get marketCategory => _value('marketCategory');
  String get electronicsCategory => _value('electronicsCategory');
  String get medicalSuppliesCategory => _value('medicalSuppliesCategory');
  String get opticsCategory => _value('opticsCategory');
  String get storeSettingsTitle => _value('storeSettingsTitle');
  String get storeNameLabel => _value('storeNameLabel');
  String get storeDescriptionLabel => _value('storeDescriptionLabel');
  String get storeNameHint => _value('storeNameHint');
  String get storeDescriptionHint => _value('storeDescriptionHint');
  String get savingChanges => _value('savingChanges');
  String get storeSavedSuccessfully => _value('storeSavedSuccessfully');
  String get storeNameRequiredError => _value('storeNameRequiredError');
  String get userWelcomeTitle => _value('userWelcomeTitle');
  String get userSelectionSubtitle => _value('userSelectionSubtitle');
  String get shopperCardTitle => _value('shopperCardTitle');
  String get shopperCardDescription => _value('shopperCardDescription');
  String get merchantCardTitle => _value('merchantCardTitle');
  String get merchantCardDescription => _value('merchantCardDescription');
  String get termsAgreementText => _value('termsAgreementText');
  String get onboardingAiTag => _value('onboardingAiTag');
  String get onboardingMainHeading => _value('onboardingMainHeading');
  String get onboardingDescription => _value('onboardingDescription');
  String get onboardingDataAnalysis => _value('onboardingDataAnalysis');
  String get onboardingExpectedGrowth => _value('onboardingExpectedGrowth');
  String get skipToFinalStep => _value('skipToFinalStep');
  String get chooseImageSourceTitle => _value('chooseImageSourceTitle');
  String get galleryLabel => _value('galleryLabel');
  String get cameraLabel => _value('cameraLabel');
  String get photoUploadFailed => _value('photoUploadFailed');
  String get fullNameExample => _value('fullNameExample');
  String get phoneNumberExample => _value('phoneNumberExample');
  String get cityExample => _value('cityExample');
  String get deliveryNoteHint => _value('deliveryNoteHint');
  String get requiredFieldMessage => _value('requiredFieldMessage');
  String get chooseCategory => _value('chooseCategory');
  String get accountAlreadyExists => _value('accountAlreadyExists');
  String get emailAlreadyRegistered => _value('emailAlreadyRegistered');
  String get loginNow => _value('loginNow');
  String get chooseStoreCategoryLabel => _value('chooseStoreCategoryLabel');
  String get defaultUser => _value('defaultUser');
  String get settings => _value('settings');
  String get editProfile => _value('editProfile');
  String get changePassword => _value('changePassword');
  String get notifications => _value('notifications');
  String get language => _value('language');
  String get languageArabic => _value('languageArabic');
  String get languageEnglish => _value('languageEnglish');
  String get favorites => _value('favorites');
  String get noFavorites => _value('noFavorites');
  String get logout => _value('logout');
  String get loggingOut => _value('loggingOut');
  String get deleteAccount => _value('deleteAccount');
  String get deletingAccount => _value('deletingAccount');
  String get deleteAccountConfirm => _value('deleteAccountConfirm');
  String get deleteAccountMessage => _value('deleteAccountMessage');
  String get passwordCurrent => _value('passwordCurrent');
  String get passwordNew => _value('passwordNew');
  String get passwordConfirm => _value('passwordConfirm');
  String get passwordDescription => _value('passwordDescription');
  String get showPassword => _value('showPassword');
  String get hidePassword => _value('hidePassword');
  String get passwordSave => _value('passwordSave');
  String get passwordCancel => _value('passwordCancel');
  String get passwordChanged => _value('passwordChanged');
  String get passwordSuccessDescription => _value('passwordSuccessDescription');
  String get passwordBackToProfile => _value('passwordBackToProfile');
  String get passwordRequired => _value('passwordRequired');
  String get passwordMinLength => _value('passwordMinLength');
  String get passwordMismatch => _value('passwordMismatch');
  String get phoneNumber => _value('phoneNumber');
  String get chooseStoreCategory => _value('chooseStoreCategory');
  String get confirmCode => _value('confirmCode');
  String get didNotReceiveCode => _value('didNotReceiveCode');
  String get profilePhotoTitle => _value('profilePhotoTitle');
  String get profilePhotoSubtitle => _value('profilePhotoSubtitle');
  String get storeSelectionRequired => _value('storeSelectionRequired');
  String get storeProducts => _value('storeProducts');
  String get unableLoadStoreData => _value('unableLoadStoreData');
  String get merchantAccessExpiredMessage => _value('merchantAccessExpiredMessage');
  String get orderApprovedMessage => _value('orderApprovedMessage');
  String get orderNotFound => _value('orderNotFound');
  String get unableLoadOrderDetails => _value('unableLoadOrderDetails');
  String get confirmDelivery => _value('confirmDelivery');
  String get subscriptionRequestTitle => _value('subscriptionRequestTitle');
  String get discoverLocalStores => _value('discoverLocalStores');
  String get bestLocalDeals => _value('bestLocalDeals');
  String get dealsUpTo40 => _value('dealsUpTo40');
  String get weekendDeals => _value('weekendDeals');
  String get discoverNow => _value('discoverNow');
  String get startNow => _value('startNow');
  String get watchGuide => _value('watchGuide');
  String get aiHeroTitle => _value('aiHeroTitle');
  String get aiHeroSubtitle => _value('aiHeroSubtitle');
  String get aiAccuracy => _value('aiAccuracy');
  String get aiGeneratedAccuracy => _value('aiGeneratedAccuracy');
  String get aiGeneratedVolume => _value('aiGeneratedVolume');
  String get error => _value('error');
  String get sessionExpired => _value('sessionExpired');
  String get forbidden => _value('forbidden');
  String get serverError => _value('serverError');
  String get networkError => _value('networkError');
  String get timeoutError => _value('timeoutError');
  String get unexpectedError => _value('unexpectedError');
  String get home => _value('home');
  String get search => _value('search');
  String get categories => _value('categories');
  String get account => _value('account');
  String get orders => _value('orders');
  String get aiTools => _value('aiTools');
  String get myProducts => _value('myProducts');
  String get noScreensAvailable => _value('noScreensAvailable');
  String get markAllRead => _value('markAllRead');
  String get noNotifications => _value('noNotifications');
  String get filterStatus => _value('filterStatus');
  String get allProducts => _value('allProducts');
  String get active => _value('active');
  String get inactive => _value('inactive');
  String get outOfStock => _value('outOfStock');
  String get visible => _value('visible');
  String get hidden => _value('hidden');
  String get stock => _value('stock');
  String get deleteProduct => _value('deleteProduct');
  String get deleteProductConfirm => _value('deleteProductConfirm');
  String get noProductsYet => _value('noProductsYet');
  String get publishFirstProduct => _value('publishFirstProduct');
  String get addNewProduct => _value('addNewProduct');
  String get productDeleted => _value('productDeleted');
  String get uploadPhoto => _value('uploadPhoto');
  String get skip => _value('skip');
  String get chooseYourRegion => _value('chooseYourRegion');
  String get useCurrentLocation => _value('useCurrentLocation');
  String get aiImagePrompt => _value('aiImagePrompt');
  String get aiImagePromptHint => _value('aiImagePromptHint');
  String get writeImageDescriptionFirst => _value('writeImageDescriptionFirst');
  String get aiFeatureInProgress => _value('aiFeatureInProgress');
  String get generateImage => _value('generateImage');
  String get merchantOrders => _value('merchantOrders');
  String get allOrders => _value('allOrders');
  String get pendingReview => _value('pendingReview');
  String get confirmed => _value('confirmed');
  String get completed => _value('completed');
  String get cancelled => _value('cancelled');
  String get itemCount => _value('itemCount');
  String get orderDetails => _value('orderDetails');
  String get shipmentInfo => _value('shipmentInfo');
  String get customerPhone => _value('customerPhone');
  String get orderNumber => _value('orderNumber');
  String get store => _value('store');
  String get orderDate => _value('orderDate');
  String get productCount => _value('productCount');
  String get orderTimeline => _value('orderTimeline');
  String get products => _value('products');
  String get contactCustomer => _value('contactCustomer');
  String get confirmOrder => _value('confirmOrder');
  String get cancelOrder => _value('cancelOrder');
  String get invalidOrderId => _value('invalidOrderId');
  String get invalidCustomerPhone => _value('invalidCustomerPhone');
  String get customerChatOpened => _value('customerChatOpened');
  String get unableOpenCustomerWhatsApp => _value('unableOpenCustomerWhatsApp');
  String get subscriptionStatus => _value('subscriptionStatus');
  String get availablePlans => _value('availablePlans');
  String get subscriptionRequests => _value('subscriptionRequests');
  String get newRequest => _value('newRequest');
  String get noSubscriptionPlans => _value('noSubscriptionPlans');
  String get noPreviousSubscriptionRequests => _value('noPreviousSubscriptionRequests');
  String get sendSubscriptionRequest => _value('sendSubscriptionRequest');
  String get noActiveSubscription => _value('noActiveSubscription');
  String get continueWithPlan => _value('continueWithPlan');
  String get choosePlanFirst => _value('choosePlanFirst');
  String get subscriptionRequestDetails => _value('subscriptionRequestDetails');
  String get planId => _value('planId');
  String get billingCycle => _value('billingCycle');
  String get paymentMethod => _value('paymentMethod');
  String get notesOptional => _value('notesOptional');
  String get chooseProofImageFirst => _value('chooseProofImageFirst');
  String get selectImageSource => _value('selectImageSource');
  String get noPhotoPrompt => _value('noPhotoPrompt');
  String get generateAiImage => _value('generateAiImage');
  String get aiPromptHint => _value('aiPromptHint');
  String get tellMeWhatToDo => _value('tellMeWhatToDo');
  String get generatedResult => _value('generatedResult');
  String get copyResult => _value('copyResult');
  String get regenerate => _value('regenerate');
  String get resultSavedLater => _value('resultSavedLater');
  String get noSavedOperations => _value('noSavedOperations');
  String get newOrders => _value('newOrders');
  String get completedSales => _value('completedSales');
  String get lowStock => _value('lowStock');
  String get addProductAction => _value('addProductAction');
  String get ordersAction => _value('ordersAction');
  String get profileAction => _value('profileAction');
  String get storeSettingsAction => _value('storeSettingsAction');
  String get noOrdersYet => _value('noOrdersYet');
  String get ordersWillAppear => _value('ordersWillAppear');
  String get updatePassword => _value('updatePassword');
  String get statusLabel => _value('statusLabel');
  String get typeLabel => _value('typeLabel');
  String get planType => _value('planType');
  String get paymentProofRequired => _value('paymentProofRequired');
  String get productOrTopic => _value('productOrTopic');
  String get customerMessageLabel => _value('customerMessageLabel');
  String get optionalCategory => _value('optionalCategory');
  String get optionalDetails => _value('optionalDetails');
  String get exampleWirelessHeadphones => _value('exampleWirelessHeadphones');
  String get examplePerfume => _value('examplePerfume');
  String get exampleCosmetics => _value('exampleCosmetics');
  String get exampleWinterFashion => _value('exampleWinterFashion');
  String get exampleCustomerMessage => _value('exampleCustomerMessage');
  String get minutesAgo => _value('minutesAgo');
  String get hoursAgo => _value('hoursAgo');
  String get daysAgo => _value('daysAgo');
  String get resultText => _value('resultText');
  String get copyText => _value('copyText');
  String get generateAiText => _value('generateAiText');
  String get before => _value('before');
  String get profileInfo => _value('profileInfo');
  String get currentLocation => _value('currentLocation');
  String get locationSelected => _value('locationSelected');
  String get locationSelectionRequired => _value('locationSelectionRequired');
  String get currentLocationAutoMatchHint => _value('currentLocationAutoMatchHint');
  String get unableGetCurrentLocation => _value('unableGetCurrentLocation');
  String get shoppingCart => _value('shoppingCart');
  String get clearAll => _value('clearAll');
  String get itemsInCart => _value('itemsInCart');
  String get emptyCart => _value('emptyCart');
  String get total => _value('total');
  String get continueOrder => _value('continueOrder');
  String get noStoresFound => _value('noStoresFound');
  String get storeListTitle => _value('storeListTitle');
  String get storesForRegion => _value('storesForRegion');
  String get orderTrackingTitle => _value('orderTrackingTitle');
  String get productCountLabel => _value('productCountLabel');
  String get productUnavailable => _value('productUnavailable');
  String get quantityLabel => _value('quantityLabel');
  String get noProductsInStore => _value('noProductsInStore');
  String get productName => _value('productName');
  String get productPrice => _value('productPrice');
  String get nextStep => _value('nextStep');
  String get locationAutoMatchError => _value('locationAutoMatchError');
  String get locationCurrent => _value('locationCurrent');
  String get locationLoading => _value('locationLoading');
  String get locationSelectPrompt => _value('locationSelectPrompt');
  String get updatePasswordAction => _value('updatePasswordAction');
  String get orderSubmitted => _value('orderSubmitted');
  String get orderSubmittedMessage => _value('orderSubmittedMessage');
  String get backToHome => _value('backToHome');
  String get viewMyOrders => _value('viewMyOrders');
  String get orderReference => _value('orderReference');
  String get myOrders => _value('myOrders');
  String get noOrdersDescription => _value('noOrdersDescription');
  String get categoryLoadError => _value('categoryLoadError');
  String get featuredBadge => _value('featuredBadge');
  String get bestMallDeals => _value('bestMallDeals');
  String get seeOffers => _value('seeOffers');
  String get cartAdded => _value('cartAdded');
  String get addToCart => _value('addToCart');
  String get nearbyStoresTitle => _value('nearbyStoresTitle');
  String get selectedForYou => _value('selectedForYou');
  String get smartMarketplace => _value('smartMarketplace');
  String get smartMarketplaceSubtitle => _value('smartMarketplaceSubtitle');
  String get currentLocationTitle => _value('currentLocationTitle');
  String get quantityAvailable => _value('quantityAvailable');
  String get category => _value('category');
  String get description => _value('description');
  String get productPublished => _value('productPublished');
  String get productUpdated => _value('productUpdated');
  String get addNewProductTitle => _value('addNewProductTitle');
  String get editProductTitle => _value('editProductTitle');
  String get publishProduct => _value('publishProduct');
  String get saveProductChanges => _value('saveProductChanges');
  String get productImagesCount => _value('productImagesCount');
  String get deleteCurrentImages => _value('deleteCurrentImages');
  String get showProduct => _value('showProduct');
  String get featuredProduct => _value('featuredProduct');
  String get availableProducts => _value('availableProducts');
  String get newArrivals => _value('newArrivals');
  String get featured => _value('featured');
  String get noRecentProducts => _value('noRecentProducts');
  String get noProductsFound => _value('noProductsFound');
  String get noResultsForQuery => _value('noResultsForQuery');
  String get selectStoreCategory => _value('selectStoreCategory');
  String get checkout => _value('checkout');
  String get deliveryInfo => _value('deliveryInfo');
  String get address => _value('address');
  String get city => _value('city');
  String get additionalNotes => _value('additionalNotes');
  String get notes => _value('notes');
  String get orderTotal => _value('orderTotal');
  String get confirmRequest => _value('confirmRequest');
  String get verificationCodeInputMessage => _value('verificationCodeInputMessage');
  String get otpNetworkRetry => _value('otpNetworkRetry');
  String get otpInvalid => _value('otpInvalid');
  String get genericRetryMessage => _value('genericRetryMessage');
  String get otpResendSuccess => _value('otpResendSuccess');
  String get otpResendFailed => _value('otpResendFailed');
  String get verificationTitle => _value('verificationTitle');
  String get verificationIntro => _value('verificationIntro');
  String get passwordResetTitle => _value('passwordResetTitle');
  String get passwordResetDescription => _value('passwordResetDescription');
  String get passwordNewHint => _value('passwordNewHint');
  String get passwordConfirmHint => _value('passwordConfirmHint');
  String get passwordRuleHint => _value('passwordRuleHint');
  String get passwordResetRequired => _value('passwordResetRequired');
  String get resetLinkInvalidOrExpired => _value('resetLinkInvalidOrExpired');
  String get productNameRequired => _value('productNameRequired');
  String get productPriceRequired => _value('productPriceRequired');
  String get quantityRequired => _value('quantityRequired');
  String get generalCategory => _value('generalCategory');
  String get addProductNew => _value('addProductNew');
  String get editProduct => _value('editProduct');
  String get productNameLabel => _value('productNameLabel');
  String get productPriceLabel => _value('productPriceLabel');
  String get productQuantityLabel => _value('productQuantityLabel');
  String get categoryLabel => _value('categoryLabel');
  String get descriptionLabel => _value('descriptionLabel');
  String get productExample => _value('productExample');
  String get priceExample => _value('priceExample');
  String get quantityExample => _value('quantityExample');
  String get categoryExample => _value('categoryExample');
  String get productDescriptionExample => _value('productDescriptionExample');
  String get subscriptionTitle => _value('subscriptionTitle');
  String get plansAvailable => _value('plansAvailable');
  String get noPlansAvailable => _value('noPlansAvailable');
  String get continueWithPlanLabel => _value('continueWithPlanLabel');
  String get productLimitLabel => _value('productLimitLabel');
  String get storeLimitLabel => _value('storeLimitLabel');
  String get requestNew => _value('requestNew');
  String get requestSubscription => _value('requestSubscription');
  String get requestSubscriptionDescription => _value('requestSubscriptionDescription');
  String get planIdLabel => _value('planIdLabel');
  String get billingCycleLabel => _value('billingCycleLabel');
  String get paymentMethodLabel => _value('paymentMethodLabel');
  String get notesLabel => _value('notesLabel');
  String get selectPaymentProof => _value('selectPaymentProof');
  String get paymentProofHint => _value('paymentProofHint');
  String get sendRequestLabel => _value('sendRequestLabel');
  String get trialLabel => _value('trialLabel');
  String get paidSubscription => _value('paidSubscription');
  String get startedAt => _value('startedAt');
  String get endsAt => _value('endsAt');
  String get daysRemaining => _value('daysRemaining');
  String get supportViaWhatsApp => _value('supportViaWhatsApp');
  String get supportContact => _value('supportContact');
  String get noSubscriptions => _value('noSubscriptions');
  String get aiToolsSmart => _value('aiToolsSmart');
  String get aiStoreSpace => _value('aiStoreSpace');
  String get whatDoYouWantToday => _value('whatDoYouWantToday');
  String get chooseToolOrStartIdea => _value('chooseToolOrStartIdea');
  String get howCanIHelp => _value('howCanIHelp');
  String get generateResult => _value('generateResult');
  String get generating => _value('generating');
  String get resultCopied => _value('resultCopied');
  String get copy => _value('copy');
  String get closeButton => _value('closeButton');
  String get regenerateResult => _value('regenerateResult');
  String get recentActivity => _value('recentActivity');
  String get savedInThisSession => _value('savedInThisSession');
  String get noSavedOperationsYet => _value('noSavedOperationsYet');
  String get now => _value('now');
  String get productDescriptionTool => _value('productDescriptionTool');
  String get marketingContentTool => _value('marketingContentTool');
  String get hashtagsTool => _value('hashtagsTool');
  String get customerReplyTool => _value('customerReplyTool');
  String get aiPromptPlaceholder => _value('aiPromptPlaceholder');
  String get aiGenerateButton => _value('aiGenerateButton');
  String get aiGenerateButtonLoading => _value('aiGenerateButtonLoading');
  String get aiWhatToDoPrompt => _value('aiWhatToDoPrompt');
  String get aiChooseToolPrompt => _value('aiChooseToolPrompt');
  String get aiSmartWorkspaceTitle => _value('aiSmartWorkspaceTitle');
  String get aiSmartWorkspaceSubtitle => _value('aiSmartWorkspaceSubtitle');
  String get aiContextPrompt1 => _value('aiContextPrompt1');
  String get aiContextPrompt2 => _value('aiContextPrompt2');
  String get aiContextPrompt3 => _value('aiContextPrompt3');
  String get aiRecentActivity => _value('aiRecentActivity');
  String get aiSavedInSession => _value('aiSavedInSession');
  String get aiResultOutputHint => _value('aiResultOutputHint');
  String get aiNoHistory => _value('aiNoHistory');
  String get aiGenerateSheetTitleProduct => _value('aiGenerateSheetTitleProduct');
  String get aiGenerateSheetTitleInstagram => _value('aiGenerateSheetTitleInstagram');
  String get aiGenerateSheetTitleHashtags => _value('aiGenerateSheetTitleHashtags');
  String get aiGenerateSheetTitleCustomerReply => _value('aiGenerateSheetTitleCustomerReply');
  String get aiStageLabel => _value('aiStageLabel');
  String get aiStageUnknown => _value('aiStageUnknown');
  String get aiCopiedToClipboard => _value('aiCopiedToClipboard');
  String get aiNoOperationsAfter => _value('aiNoOperationsAfter');
  String get aiOverviewTitle => _value('aiOverviewTitle');
  String get aiOverviewSubtitle => _value('aiOverviewSubtitle');
  String get aiViewHistory => _value('aiViewHistory');
  String get subscriptionRequestFormTitle => _value('subscriptionRequestFormTitle');
  String get subscriptionRequestFormSubtitle => _value('subscriptionRequestFormSubtitle');
  String get selectPaymentProofLabel => _value('selectPaymentProofLabel');
  String get paymentProofRequirements => _value('paymentProofRequirements');
  String get planIdRequired => _value('planIdRequired');
  String get fullNameRequired => _value('fullNameRequired');
  String get phoneRequired => _value('phoneRequired');
  String get monthly => _value('monthly');
  String get yearly => _value('yearly');
  String get bankTransfer => _value('bank_transfer');
  String get cash => _value('cash');
  String get activeStatus => _value('activeStatus');
  String get expiredStatus => _value('expiredStatus');
  String get cancelledStatus => _value('cancelledStatus');
  String get unknownStatus => _value('unknownStatus');
  String get approvedStatus => _value('approvedStatus');
  String get rejectedStatus => _value('rejectedStatus');
  String get pendingStatus => _value('pendingStatus');
  String get requestStatusLabel => _value('requestStatusLabel');
  String get productCategoryDefault => _value('productCategoryDefault');

  static List<String> get allKeys => _translations['en']!.keys.toList()..sort();

  static bool hasCompleteTranslations() {
    final englishKeys = _translations['en']!.keys.toSet();
    final arabicKeys = _translations['ar']!.keys.toSet();
    if (englishKeys.length != arabicKeys.length) return false;
    if (!englishKeys.containsAll(arabicKeys)) return false;
    if (!arabicKeys.containsAll(englishKeys)) return false;
    for (final locale in _translations.keys) {
      for (final value in _translations[locale]!.values) {
        if (value.trim().isEmpty) return false;
      }
    }
    return true;
  }

  String _value(String key) =>
      _translations[locale.languageCode]?[key] ?? _translations['ar']?[key] ?? key;

    static const _translations = <String, Map<String, String>>{
    'ar': {
      'appName': 'Tradex',
      'welcomeBack': 'مرحباً بعودتك 👋',
      'welcomeBackMerchant': 'سجل دخولك لإدارة متجرك',
      'welcomeBackClient': 'سجل دخولك للتسوق الذكي',
      'login': 'تسجيل الدخول',
      'loginLoading': 'جارٍ تسجيل الدخول...',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'rememberMe': 'تذكرني',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'resetPassword': 'استعادة كلمة المرور',
      'sendResetLink': 'إرسال رابط إعادة التعيين',
      'noAccount': 'ليس لديك حساب؟',
      'createAccount': 'أنشئ حساباً جديداً',
      'enterEmailPassword': 'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      'enterEmailPlease': 'يرجى إدخال البريد الإلكتروني.',
      'enterValidEmail': 'يرجى إدخال بريد إلكتروني صحيح.',
      'otpSent': 'إذا كان هناك حساب مرتبط بهذا البريد الإلكتروني، فقد تم إرسال رابط إعادة تعيين كلمة المرور.',
      'verificationCode': 'كود التحقق',
      'verificationCodeHelp': 'لقد أرسلنا رمزاً مكوناً من 4 أرقام إلى هاتفك',
      'codeRequired': 'يرجى إدخال رمز التحقق المكوّن من 4 أرقام',
      'resendCode': 'إعادة إرسال الرمز',
      'codeResent': 'تم إعادة إرسال الرمز إلى',
      'resendFailed': 'فشل إعادة الإرسال. حاول مرة أخرى.',
      'invalidCode': 'رمز التحقق غير صحيح. حاول مرة أخرى.',
      'networkCheck': 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
      'pleaseChooseYourRegion': 'اختر منطقتك أولاً.',
      'selectRegionFirst': 'اختر منطقتك أولاً.',
      'regionSelected': 'تم تحديد الموقع: ',
      'unableToGetLocation': 'تعذر الحصول على موقعك الحالي.',
      'useMyLocation': 'استخدام موقعي الحالي',
      'searchRegion': 'ابحث عن منطقتك...',
      'chooseImageSource': 'اختر مصدر الصورة',
      'gallery': 'المعرض',
      'camera': 'الكاميرا',
      'imagePickerError': 'تعذر اختيار الصورة',
      'personalInfo': 'المعلومات الشخصية',
      'enterFullName': 'أدخل اسمك الكامل',
      'completeProfileClient': 'إكمال الملف للمتسوق',
      'selectYourRegion': 'حدد منطقتك',
      'regionDescription': 'اختر المنطقة التي تتواجد بها لتخصيص تجربتك.',
      'retry': 'إعادة المحاولة',
      'continueText': 'متابعة',
      'cancel': 'إلغاء',
      'submit': 'إرسال',
      'done': 'تم',
      'success': 'نجاح',
      'yes': 'نعم',
      'no': 'لا',
      'delete': 'حذف',
      'edit': 'تعديل',
      'close': 'إغلاق',
      'back': 'رجوع',
      'next': 'التالي',
      'registerNewAccount': 'إنشاء حساب جديد',
      'registerClientSubtitle': 'انضم إلى سوق Tradex الذكي',
      'registerMerchantSubtitle': 'أنشئ حسابك التجاري الآن',
      'agreeTermsAndPrivacy': 'أوافق على شروط الخدمة وسياسة الخصوصية',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'createAccountAction': 'إنشاء الحساب',
      'creatingAccount': 'جارٍ إنشاء الحساب...',
      'fieldRequired': 'هذا الحقل مطلوب',
      'completeMerchantProfile': 'إكمال بروفايل التاجر',
      'merchantProfileStep': 'الخطوة الأخيرة: إكمال البيانات',
      'merchantStoreName': 'اسم المتجر',
      'merchantStoreNameHint': 'مثال: متجر التقنية الحديثة',
      'merchantStoreCategory': 'فئة المتجر',
      'merchantChooseCategory': 'اختر الفئة',
      'merchantRegion': 'المنطقة',
      'merchantAddressDetail': 'العنوان بالتفصيل',
      'merchantAddressHint': 'الشارع، رقم المبنى...',
      'merchantDescription': 'وصف المتجر',
      'merchantDescriptionHint': 'تحدث عن ما يميز متجرك...',
      'merchantWhatsApp': 'رقم الواتساب',
      'merchantWorkHours': 'مواعيد العمل',
      'merchantWorkHoursHint': 'مثلاً: 10 صباحاً - 8 مساءً',
      'merchantStoreNameRequired': 'يرجى إدخال اسم المتجر',
      'restaurantCategory': 'مطاعم',
      'cafesCategory': 'كافيهات',
      'fashionCategory': 'ملابس',
      'workspacesCategory': 'مساحات عمل',
      'giftsCategory': 'هدايا',
      'shoesCategory': 'أحذية',
      'carsCategory': 'سيارات',
      'jewelryCategory': 'مجوهرات',
      'cosmeticsCategory': 'كوزمتكس',
      'supermarketCategory': 'سوبرماركت',
      'mallCategory': 'مول',
      'storeCategoryDefault': 'متجر',
      'marketCategory': 'متجر',
      'electronicsCategory': 'إلكترونيات',
      'medicalSuppliesCategory': 'مستلزمات طبية',
      'opticsCategory': 'بصريات',
      'chooseStoreCategory': 'اختر فئة المتجر',
      'defaultUser': 'مستخدم Tradex',
      'storeSettingsTitle': 'إعدادات المتجر',
      'storeNameLabel': 'اسم المتجر',
      'storeDescriptionLabel': 'وصف المتجر',
      'storeNameHint': 'اسم المتجر',
      'storeDescriptionHint': 'اكتب وصفاً مختصراً لمتجرك',
      'savingChanges': 'جاري الحفظ...',
      'storeSavedSuccessfully': 'تم حفظ إعدادات المتجر ✅',
      'storeNameRequiredError': 'يرجى إدخال اسم المتجر',
      'userWelcomeTitle': 'مرحباً بك في Tradex',
      'userSelectionSubtitle': 'اختر نوع الحساب للمتابعة',
      'shopperCardTitle': 'متسوق',
      'shopperCardDescription': 'ابحث عن المنتجات، قارن الأسعار، وتسوق بسهولة ذكية.',
      'merchantCardTitle': 'تاجر',
      'merchantCardDescription': 'قم ببيع منتجاتك، تتبع أرباحك، ووسع تجارتك باستخدام الذكاء الاصطناعي.',
      'termsAgreementText': 'بالتنقر على متابعة، فإنك توافق على شروط الخدمة',
      'onboardingAiTag': 'الذكاء الاصطناعي',
      'onboardingMainHeading': 'سوّق باستخدام',
      'onboardingDescription': 'حوّل أفكارك إلى حملات تسويقية احترافية في ثوانٍ معدودة. دع مساعدنا الذكي يتولى كتابة المحتوى وتصميم العروض.',
      'onboardingDataAnalysis': 'تحليل البيانات',
      'onboardingExpectedGrowth': 'الزيادة المتوقعة',
      'skipToFinalStep': 'تخطي للمرحلة النهائية',
      'fullNameExample': 'أحمد محمد',
      'phoneNumberExample': '05XXXXXXXX',
      'cityExample': 'غزة',
      'deliveryNoteHint': 'أي تعليمات خاصة للتوصيل...',
      'requiredFieldMessage': 'هذا الحقل مطلوب',
      'chooseCategory': 'اختر الفئة',
      'accountAlreadyExists': 'لديك حساب بالفعل؟',
      'emailAlreadyRegistered': 'هذا البريد الإلكتروني مسجل بالفعل.',
      'loginNow': 'سجل الدخول',
      'chooseStoreCategoryLabel': 'اختر الفئة',
      'settings': 'الإعدادات',
      'editProfile': 'تعديل الملف الشخصي',
      'changePassword': 'تغيير كلمة المرور',
      'notifications': 'الإشعارات',
      'language': 'اللغة',
      'languageArabic': 'العربية',
      'languageEnglish': 'الإنجليزية',
      'favorites': 'المفضلة',
      'noFavorites': 'لا توجد منتجات مفضلة',
      'logout': 'تسجيل الخروج',
      'loggingOut': 'جارٍ تسجيل الخروج...',
      'deleteAccount': 'حذف الحساب',
      'deletingAccount': 'جارٍ حذف الحساب...',
      'deleteAccountConfirm': 'حذف الحساب بشكل دائم؟',
      'deleteAccountMessage': 'سيتم حذف حسابك بشكل دائم، وسيتم إلغاء جميع الجلسات والبيانات الشخصية المرتبطة به. لا يمكن التراجع عن هذا الإجراء.',
      'passwordCurrent': 'كلمة المرور الحالية',
      'passwordNew': 'كلمة المرور الجديدة',
      'passwordConfirm': 'تأكيد كلمة المرور الجديدة',
      'passwordDescription': 'أنشئ كلمة مرور جديدة لحماية حسابك.',
      'showPassword': 'إظهار كلمة المرور',
      'hidePassword': 'إخفاء كلمة المرور',
      'passwordSave': 'حفظ كلمة المرور',
      'passwordCancel': 'إلغاء',
      'passwordChanged': 'تم تغيير كلمة المرور بنجاح',
      'passwordSuccessDescription': 'تم تحديث كلمة المرور مع الحفاظ على جلستك الحالية.',
      'passwordBackToProfile': 'العودة إلى الملف الشخصي',
      'passwordRequired': 'هذا الحقل مطلوب.',
      'passwordMinLength': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
      'passwordMismatch': 'كلمتا المرور غير متطابقتين.',
      'sessionExpired': 'انتهت جلستك. يرجى تسجيل الدخول مجدداً.',
      'forbidden': 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
      'serverError': 'حدث خطأ في الخادم. حاول مجدداً.',
      'networkError': 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مجدداً.',
      'timeoutError': 'انتهت مهلة الطلب. حاول مجدداً.',
      'unexpectedError': 'حدث خطأ غير متوقع. حاول مجدداً.',
      'home': 'الرئيسية',
      'search': 'بحث',
      'categories': 'التصنيفات',
      'account': 'حسابي',
      'orders': 'الطلبات',
      'aiTools': 'أدوات AI',
      'myProducts': 'منتجاتي',
      'noScreensAvailable': 'لا توجد شاشات متاحة',
      'markAllRead': 'تحديد الكل كمقروء',
      'noNotifications': 'لا توجد إشعارات جديدة.',
      'filterStatus': 'تصفية الحالة',
      'allProducts': 'كل المنتجات',
      'active': 'نشط',
      'inactive': 'مخفي',
      'outOfStock': 'نفد المخزون',
      'visible': 'ظاهر',
      'hidden': 'مخفي',
      'stock': 'المخزون',
      'deleteProduct': 'حذف المنتج',
      'deleteProductConfirm': 'هل أنت متأكد من حذف "{name}"؟\\nلا يمكن التراجع عن هذا الإجراء.',
      'noProductsYet': 'لا توجد منتجات بعد',
      'publishFirstProduct': 'انشر منتجك الأول وابدأ البيع الآن',
      'addNewProduct': 'إضافة منتج جديد',
      'productDeleted': 'تم حذف المنتج',
      'uploadPhoto': 'رفع صورة',
      'skip': 'تخطي',
      'chooseYourRegion': 'حدد منطقتك',
      'useCurrentLocation': 'استخدام موقعي الحالي',
      'aiImagePrompt': 'لا تملك صورة؟ اصنع واحدة تشبهك',
      'aiImagePromptHint': 'كيف تود أن تبدو صورتك؟',
      'writeImageDescriptionFirst': 'اكتب وصفاً للصورة أولاً',
      'aiFeatureInProgress': 'ميزة إنشاء الصورة بالذكاء الاصطناعي قيد التجهيز',
      'generateImage': 'إنشاء',
      'merchantOrders': 'الطلبات الواردة',
      'allOrders': 'كل الطلبات',
      'pendingReview': 'قيد المراجعة',
      'confirmed': 'تم تأكيد الطلب',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'itemCount': '{count} منتج',
      'orderDetails': 'تفاصيل الطلب',
      'shipmentInfo': 'معلومات التوصيل',
      'customerPhone': 'رقم الهاتف',
      'orderNumber': 'رقم الطلب',
      'store': 'المتجر',
      'orderDate': 'تاريخ الطلب',
      'productCount': 'عدد المنتجات',
      'orderTimeline': 'مسار الطلب',
      'products': 'المنتجات',
      'contactCustomer': 'محادثة العميل',
      'confirmOrder': 'تأكيد الطلب',
      'cancelOrder': 'إلغاء الطلب',
      'invalidOrderId': 'معرف الطلب غير صالح',
      'invalidCustomerPhone': 'رقم هاتف العميل غير متوفر أو غير صالح',
      'customerChatOpened': 'تم فتح محادثة العميل',
      'unableOpenCustomerWhatsApp': 'تعذر فتح واتساب للعميل',
      'subscriptionStatus': 'حالة الاشتراك',
      'availablePlans': 'الباقات المتاحة',
      'subscriptionRequests': 'طلبات الاشتراك',
      'newRequest': 'طلب جديد',
      'noSubscriptionPlans': 'لا توجد باقات متاحة حالياً.',
      'noActiveSubscription': 'لا يوجد اشتراك أو فترة تجريبية حالية.',
      'continueWithPlan': 'متابعة مع {plan}',
      'choosePlanFirst': 'يرجى اختيار باقة أولاً.',
      'subscriptionRequestDetails': 'تفاصيل طلب الاشتراك',
      'planId': 'معرّف الخطة',
      'billingCycle': 'دورة الفوترة',
      'paymentMethod': 'طريقة الدفع',
      'fullName': 'الاسم الكامل',
      'phoneNumber': 'رقم الهاتف',
      'confirmCode': 'تأكيد الرمز',
      'didNotReceiveCode': 'لم تستلم الرمز؟',
      'profilePhotoTitle': 'الصورة الشخصية',
      'profilePhotoSubtitle': 'أضف صورة واضحة حتى يتعرف عليك العملاء بسهولة.',
      'storeSelectionRequired': 'يرجى اختيار متجر أولاً.',
      'storeProducts': 'منتجات المتجر',
      'unableLoadStoreData': 'تعذر تحميل بيانات المتجر.',
      'merchantAccessExpiredMessage': 'انتهت صلاحية الوصول إلى متجرك. يرجى تجديد الاشتراك أو التواصل مع الدعم.',
      'orderApprovedMessage': 'تمت الموافقة على طلبك بنجاح.',
      'orderNotFound': 'لم يتم العثور على الطلب.',
      'unableLoadOrderDetails': 'تعذر تحميل تفاصيل الطلب.',
      'confirmDelivery': 'تأكيد التوصيل',
      'subscriptionRequestTitle': 'طلب الاشتراك',
      'discoverLocalStores': 'اكتشف المتاجر القريبة',
      'bestLocalDeals': 'أفضل العروض المحلية',
      'dealsUpTo40': 'عروض تصل إلى 40%',
      'weekendDeals': 'عروض نهاية الأسبوع',
      'discoverNow': 'اكتشف الآن',
      'startNow': 'ابدأ الآن',
      'watchGuide': 'شاهد الدليل',
      'aiHeroTitle': 'منصة AI ذكية',
      'aiHeroSubtitle': 'أنشئ محتوى تسويقي وإعلانات ومنشورات بشكل أسرع.',
      'aiAccuracy': 'الدقة',
      'aiGeneratedAccuracy': 'الدقة الناتجة',
      'aiGeneratedVolume': 'الحجم الناتج',
      'error': 'خطأ',
      'notesOptional': 'ملاحظات (اختياري)',
      'chooseProofImageFirst': 'يرجى اختيار صورة إثبات الدفع أولاً.',
      'selectImageSource': 'اختر مصدر الصورة',
      'galleryLabel': 'المعرض',
      'cameraLabel': 'الكاميرا',
      'photoUploadFailed': 'فشل رفع الصورة. يمكنك المتابعة والتغيير لاحقاً.',
      'noPhotoPrompt': 'لا تملك صورة؟ اصنع واحدة تشبهك',
      'generateAiImage': 'إنشاء',
      'aiPromptHint': 'كيف يمكنني مساعدتك؟',
      'tellMeWhatToDo': 'ما الذي تريد إنجازه اليوم؟',
      'generatedResult': 'تم نسخ النتيجة',
      'copyResult': 'نسخ',
      'regenerate': 'إعادة التوليد',
      'resultSavedLater': 'ستظهر نتائجك هنا بعد أول استخدام لأدوات Tradex AI.',
      'noSavedOperations': 'لا توجد عمليات محفوظة بعد.',
      'newOrders': 'طلبات جديدة',
      'completedSales': 'المبيعات المكتملة',
      'lowStock': 'مخزون منخفض',
      'addProductAction': 'إضافة منتج',
      'ordersAction': 'الطلبات',
      'profileAction': 'الملف الشخصي',
      'storeSettingsAction': 'إعدادات المتجر',
      'ordersWillAppear': 'ستظهر هنا طلبات العملاء فور وصولها',
      'updatePassword': 'تحديث كلمة المرور',
      'statusLabel': 'الحالة',
      'typeLabel': 'النوع',
      'planType': 'نوع الخطة',
      'paymentProofRequired': 'يرجى اختيار صورة إثبات الدفع أولاً.',
      'productOrTopic': 'اسم المنتج / الموضوع *',
      'customerMessageLabel': 'رسالة العميل *',
      'optionalCategory': 'الفئة (اختياري)',
      'optionalDetails': 'معلومات إضافية (اختياري)',
      'exampleWirelessHeadphones': 'مثال: سماعات لاسلكية بلوتوث',
      'examplePerfume': 'مثال: عطر ليلة الياسمين',
      'exampleCosmetics': 'مثال: كوزمتكس',
      'exampleWinterFashion': 'مثال: ملابس نسائية شتوية',
      'exampleCustomerMessage': 'الصق رسالة العميل هنا...',
      'minutesAgo': 'قبل',
      'hoursAgo': 'قبل',
      'daysAgo': 'قبل',
      'resultText': 'النتيجة',
      'copyText': 'نسخ النص',
      'generateAiText': 'توليد بالذكاء الاصطناعي',
      'before': 'قبل',
      'profileInfo': 'المعلومات الشخصية',
      'currentLocation': 'الموقع الحالي',
      'saveChanges': 'حفظ التغييرات',
      'changesSaved': 'تم حفظ التغييرات',
      'unableSaveChanges': 'تعذر حفظ التغييرات. حاول مرة أخرى.',
      'locationSelected': 'تم تحديد الموقع: {region}',
      'locationSelectionRequired': 'اختر منطقتك أولاً.',
      'currentLocationAutoMatchHint': 'تم تحديد موقعك، لكن تعذر مطابقة المنطقة تلقائياً. اخترها من القائمة.',
      'unableGetCurrentLocation': 'تعذر الحصول على موقعك الحالي.',
      'shoppingCart': 'سلة التسوق',
      'clearAll': 'مسح الكل',
      'itemsInCart': '{count} منتجات في السلة',
      'emptyCart': 'سلتك فارغة',
      'total': 'المجموع',
      'continueOrder': 'متابعة الطلب',
      'noStoresFound': 'لا توجد متاجر',
      'storeListTitle': 'المتاجر',
      'storesForRegion': 'متاجر {region}',
      'orderTrackingTitle': 'تتبع الطلب',
      'productCountLabel': 'عدد المنتجات',
      'productUnavailable': 'غير متوفر حالياً',
      'quantityLabel': 'الكمية',
      'noProductsInStore': 'لا توجد منتجات في هذا المتجر',
      'productName': 'اسم المنتج',
      'productPrice': 'السعر (₪)',
      'nextStep': 'التالي',
      'locationAutoMatchError': 'تعذر مطابقة موقعك مع منطقة متاحة. اختر المنطقة يدوياً.',
      'locationCurrent': 'الموقع الحالي',
      'locationLoading': 'جارٍ تحديد موقعك...',
      'locationSelectPrompt': 'حدد موقعك',
      'updatePasswordAction': 'تحديث كلمة المرور',
      'orderSubmitted': 'تم إرسال الطلب',
      'orderSubmittedMessage': 'تم إرسال طلبك بنجاح!',
      'backToHome': 'العودة للرئيسية',
      'viewMyOrders': 'عرض طلباتي',
      'orderReference': 'رقم الطلب: #{ref}',
      'myOrders': 'طلباتي',
      'noOrdersYet': 'لا توجد طلبات بعد',
      'noOrdersDescription': 'ستظهر هنا طلباتك بعد إتمام أول عملية شراء',
      'categoryLoadError': 'تعذر تحميل التصنيفات',
      'featuredBadge': 'متميز',
      'bestMallDeals': 'أفضل عروض المولات',
      'seeOffers': 'استكشف خصومات تصل إلى ٥٠٪',
      'cartAdded': 'تمت الإضافة إلى السلة',
      'addToCart': 'أضف إلى السلة',
      'nearbyStoresTitle': 'متاجر المنطقة',
      'selectedForYou': 'منتجات مختارة لك',
      'smartMarketplace': 'سوقك الذكي مدعوماً بالذكاء الاصطناعي',
      'smartMarketplaceSubtitle': 'التجارة الإلكترونية المعززة بالذكاء الاصطناعي في متناول يدك',
      'currentLocationTitle': 'الموقع الحالي',
      'quantityAvailable': 'الكمية المتوفرة',
      'category': 'التصنيف',
      'description': 'الوصف',
      'productPublished': 'تم نشر المنتج بنجاح ✅',
      'productUpdated': 'تم تحديث المنتج بنجاح ✅',
      'addNewProductTitle': 'إضافة منتج جديد',
      'editProductTitle': 'تعديل المنتج',
      'publishProduct': 'نشر المنتج',
      'saveProductChanges': 'حفظ التعديلات',
      'productImagesCount': 'صور المنتج ({count}/{max})',
      'showProduct': 'إظهار المنتج',
      'featuredProduct': 'منتج مميز',
      'availableProducts': 'منتجات المتجر',
      'newArrivals': 'وصل حديثاً',
      'featured': 'مميز',
      'noRecentProducts': 'لا توجد منتجات حديثة',
      'noProductsFound': 'لا توجد منتجات',
      'noResultsForQuery': 'لا توجد نتائج لـ "{query}"',
      'selectStoreCategory': 'اختر فئة المتجر',
      'checkout': 'إتمام الطلب',
      'deliveryInfo': 'معلومات التوصيل',
      'address': 'العنوان',
      'city': 'المدينة',
      'additionalNotes': 'ملاحظات إضافية',
      'notes': 'ملاحظات',
      'orderTotal': 'الإجمالي',
      'confirmRequest': 'تأكيد الطلب',
      'verificationCodeInputMessage': 'يرجى إدخال رمز التحقق المكوّن من 4 أرقام',
      'otpNetworkRetry': 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
      'otpInvalid': 'رمز التحقق غير صحيح. حاول مرة أخرى.',
      'genericRetryMessage': 'حدث خطأ غير متوقع. حاول مرة أخرى.',
      'otpResendSuccess': 'تم إعادة إرسال الرمز إلى',
      'otpResendFailed': 'فشل إعادة الإرسال. حاول مرة أخرى.',
      'verificationTitle': 'كود التحقق',
      'verificationIntro': 'لقد أرسلنا رمزاً مكوناً من 4 أرقام إلى هاتفك',
      'passwordResetTitle': 'تعيين كلمة مرور جديدة',
      'passwordResetDescription': 'الرجاء إدخال كلمة المرور الجديدة وتأكيدها للمتابعة.',
      'passwordNewHint': 'كلمة المرور الجديدة',
      'passwordConfirmHint': 'تأكيد كلمة المرور الجديدة',
      'passwordRuleHint': 'كلمة السر يجب أن تكون 6 أحرف أو أرقام على الأقل',
      'passwordResetRequired': 'يرجى إدخال كلمة المرور الجديدة وتأكيدها.',
      'resetLinkInvalidOrExpired': 'رابط إعادة التعيين غير صالح أو منتهي الصلاحية.',
      'productNameRequired': 'يرجى إدخال اسم المنتج',
      'productPriceRequired': 'يرجى إدخال سعر صحيح',
      'quantityRequired': 'يرجى إدخال كمية مخزون صحيحة',
      'generalCategory': 'عام',
      'chooseImageSourceTitle': 'اختر مصدر الصورة',
      'addProductNew': 'إضافة منتج جديد',
      'editProduct': 'تعديل المنتج',
      'productNameLabel': 'اسم المنتج',
      'productPriceLabel': 'السعر (₪)',
      'productQuantityLabel': 'الكمية المتوفرة',
      'categoryLabel': 'التصنيف',
      'descriptionLabel': 'الوصف',
      'productExample': 'مثال: حذاء رياضي نايك',
      'priceExample': 'مثال: 150',
      'quantityExample': 'مثال: 25',
      'categoryExample': 'مثال: ملابس، إلكترونيات...',
      'productDescriptionExample': 'اكتب وصفاً للمنتج...',
      'deleteCurrentImages': 'حذف الصور الحالية',
      'subscriptionTitle': 'حالة الاشتراك',
      'plansAvailable': 'الباقات المتاحة',
      'noPlansAvailable': 'لا توجد باقات متاحة حالياً.',
      'continueWithPlanLabel': 'متابعة مع',
      'productLimitLabel': 'المنتجات',
      'storeLimitLabel': 'المتاجر',
      'requestNew': 'طلب جديد',
      'requestSubscription': 'إرسال طلب اشتراك',
      'requestSubscriptionDescription': 'أدخل بيانات الخطة وارفع صورة إثبات الدفع لمراجعة الإدارة.',
      'planIdLabel': 'معرّف الخطة',
      'billingCycleLabel': 'دورة الفوترة',
      'paymentMethodLabel': 'طريقة الدفع',
      'notesLabel': 'ملاحظات (اختياري)',
      'selectPaymentProof': 'اختيار إثبات الدفع',
      'paymentProofHint': 'صورة JPEG أو PNG أو WebP، بحد أقصى 4 ميجابايت',
      'sendRequestLabel': 'إرسال الطلب',
      'trialLabel': 'فترة تجريبية',
      'paidSubscription': 'اشتراك مدفوع',
      'startedAt': 'بدأ في',
      'endsAt': 'ينتهي في',
      'daysRemaining': 'يوم متبقٍ',
      'supportViaWhatsApp': 'تعذر فتح واتساب. تواصل مع الدعم على +972597668446.',
      'noPreviousSubscriptionRequests': 'لا توجد طلبات اشتراك سابقة',
      'sendSubscriptionRequest': 'إرسال طلب اشتراك',
      'supportContact': 'تواصل مع الدعم',
      'noSubscriptions': 'لا يوجد اشتراك أو فترة تجريبية حالية.',
      'aiToolsSmart': 'أدواتك الذكية',
      'aiStoreSpace': 'كل ما تحتاجه لمتجرك',
      'whatDoYouWantToday': 'ما الذي تريد إنجازه اليوم؟',
      'chooseToolOrStartIdea': 'اختر أداة أو ابدأ من فكرة منتجك.',
      'howCanIHelp': 'كيف يمكنني مساعدتك؟',
      'generateResult': 'توليد النتيجة',
      'generating': 'جارٍ التوليد...',
      'resultCopied': 'تم نسخ النتيجة',
      'copy': 'نسخ',
      'closeButton': 'إغلاق',
      'regenerateResult': 'إعادة التوليد',
      'recentActivity': 'النشاط الأخير',
      'savedInThisSession': 'محفوظ في هذه الجلسة',
      'noSavedOperationsYet': 'لا توجد عمليات محفوظة بعد.',
      'now': 'الآن',
      'productDescriptionTool': 'وصف المنتج',
      'marketingContentTool': 'محتوى تسويقي',
      'hashtagsTool': 'هاشتاقات',
      'customerReplyTool': 'رد العميل',
      'aiPromptPlaceholder': 'كيف يمكنني مساعدتك؟',
      'aiGenerateButton': 'توليد باستخدام Tradex AI',
      'aiGenerateButtonLoading': 'جارٍ التوليد...',
      'aiWhatToDoPrompt': 'ما الذي تريد إنجازه اليوم؟',
      'aiChooseToolPrompt': 'اختر أداة أو ابدأ من فكرة منتجك.',
      'aiSmartWorkspaceTitle': 'أدواتك الذكية',
      'aiSmartWorkspaceSubtitle': 'كل ما تحتاجه لمتجرك',
      'aiContextPrompt1': 'اكتب وصفًا مقنعًا',
      'aiContextPrompt2': 'جهّز منشورًا',
      'aiContextPrompt3': 'رد على عميل',
      'aiRecentActivity': 'النشاط الأخير',
      'aiSavedInSession': 'محفوظ في هذه الجلسة',
      'aiResultOutputHint': 'ستظهر نتائجك هنا بعد أول استخدام لأدوات Tradex AI.',
      'aiNoHistory': 'لا توجد عمليات محفوظة بعد.',
      'aiGenerateSheetTitleProduct': 'كتابة وصف منتج',
      'aiGenerateSheetTitleInstagram': 'إنشاء بوست انستغرام',
      'aiGenerateSheetTitleHashtags': 'توليد هاشتاقات',
      'aiGenerateSheetTitleCustomerReply': 'كتابة رد للعميل',
      'aiStageLabel': 'المرحلة',
      'aiStageUnknown': 'غير محددة',
      'aiCopiedToClipboard': 'تم النسخ إلى الحافظة ✅',
      'aiNoOperationsAfter': 'لا توجد عمليات بعد. استخدم إحدى أدوات الذكاء الاصطناعي لبدء التوليد.',
      'aiOverviewTitle': 'آخر العمليات',
      'aiOverviewSubtitle': 'عرض السجل',
      'aiViewHistory': 'عرض السجل',
      'subscriptionRequestFormTitle': 'إرسال طلب اشتراك',
      'subscriptionRequestFormSubtitle': 'أدخل بيانات الخطة وارفع صورة إثبات الدفع لمراجعة الإدارة.',
      'selectPaymentProofLabel': 'اختيار إثبات الدفع',
      'paymentProofRequirements': 'صورة JPEG أو PNG أو WebP، بحد أقصى 4 ميجابايت',
      'planIdRequired': 'معرّف الخطة مطلوب',
      'fullNameRequired': 'الاسم الكامل مطلوب',
      'phoneRequired': 'رقم الهاتف مطلوب',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'bankTransfer': 'تحويل بنكي',
      'cash': 'دفع نقدي',
      'activeStatus': 'نشط',
      'expiredStatus': 'منتهي',
      'cancelledStatus': 'ملغي',
      'unknownStatus': 'غير معروف',
      'approvedStatus': 'مقبول',
      'rejectedStatus': 'مرفوض',
      'pendingStatus': 'قيد المراجعة',
      'requestStatusLabel': 'حالة الطلب',
      'productCategoryDefault': 'عام',
    },
    'en': {
      'appName': 'Tradex',
      'welcomeBack': 'Welcome back 👋',
      'welcomeBackMerchant': 'Sign in to manage your store',
      'welcomeBackClient': 'Sign in to shop smarter',
      'login': 'Log in',
      'loginLoading': 'Signing in...',
      'email': 'Email',
      'password': 'Password',
      'rememberMe': 'Remember me',
      'forgotPassword': 'Forgot password?',
      'resetPassword': 'Reset password',
      'sendResetLink': 'Send reset link',
      'noAccount': 'Don’t have an account?',
      'createAccount': 'Create a new account',
      'enterEmailPassword': 'Please enter your email and password',
      'enterEmailPlease': 'Please enter your email.',
      'enterValidEmail': 'Please enter a valid email address.',
      'otpSent': 'If an account is associated with this email, a password reset link has been sent.',
      'verificationCode': 'Verification code',
      'verificationCodeHelp': 'We sent a 4-digit code to your phone',
      'codeRequired': 'Please enter the 4-digit verification code',
      'resendCode': 'Resend code',
      'codeResent': 'The code was resent to',
      'resendFailed': 'Resend failed. Please try again.',
      'invalidCode': 'The verification code is incorrect. Please try again.',
      'networkCheck': 'Check your internet connection and try again.',
      'pleaseChooseYourRegion': 'Please choose your region first.',
      'selectRegionFirst': 'Please choose your region first.',
      'regionSelected': 'Location selected: ',
      'unableToGetLocation': 'Unable to get your current location.',
      'useMyLocation': 'Use my current location',
      'searchRegion': 'Search for your region...',
      'chooseImageSource': 'Choose image source',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'imagePickerError': 'Unable to choose the image',
      'saveChanges': 'Save changes',
      'changesSaved': 'Changes saved',
      'unableSaveChanges': 'Unable to save changes. Please try again.',
      'personalInfo': 'Personal information',
      'fullName': 'Full name',
      'phoneNumber': 'Phone number',
      'chooseStoreCategory': 'Choose store category',
      'confirmCode': 'Confirm code',
      'didNotReceiveCode': 'Didn’t receive the code?',
      'profilePhotoTitle': 'Profile photo',
      'profilePhotoSubtitle': 'Add a clear photo so customers can recognize you.',
      'storeSelectionRequired': 'Please select a store first.',
      'storeProducts': 'Store products',
      'unableLoadStoreData': 'Unable to load store details.',
      'merchantAccessExpiredMessage': 'Your merchant access has expired. Please renew your subscription or contact support.',
      'orderApprovedMessage': 'Your order has been approved.',
      'orderNotFound': 'Order not found.',
      'unableLoadOrderDetails': 'Unable to load order details.',
      'confirmDelivery': 'Confirm delivery',
      'subscriptionRequestTitle': 'Subscription request',
      'discoverLocalStores': 'Discover local stores',
      'bestLocalDeals': 'Best local deals',
      'dealsUpTo40': 'Deals up to 40%',
      'weekendDeals': 'Weekend deals',
      'discoverNow': 'Discover now',
      'startNow': 'Start now',
      'watchGuide': 'Watch guide',
      'aiHeroTitle': 'AI-powered storefront',
      'aiHeroSubtitle': 'Generate product, marketing, and support content faster.',
      'aiAccuracy': 'Accuracy',
      'aiGeneratedAccuracy': 'Generated accuracy',
      'aiGeneratedVolume': 'Generated volume',
      'error': 'Error',
      'enterFullName': 'Enter your full name',
      'completeProfileClient': 'Complete shopper profile',
      'selectYourRegion': 'Select your region',
      'regionDescription': 'Choose the area where you are located to personalize your experience.',
      'retry': 'Retry',
      'continueText': 'Continue',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'done': 'Done',
      'success': 'Success',
      'yes': 'Yes',
      'no': 'No',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'back': 'Back',
      'next': 'Next',
      'defaultUser': 'Tradex user',
      'registerNewAccount': 'Create a new account',
      'registerClientSubtitle': 'Join the Tradex smart marketplace',
      'registerMerchantSubtitle': 'Create your business account now',
      'agreeTermsAndPrivacy': 'I agree to the terms of service and privacy policy',
      'alreadyHaveAccount': 'Already have an account?',
      'createAccountAction': 'Create account',
      'creatingAccount': 'Creating account...',
      'fieldRequired': 'This field is required',
      'completeMerchantProfile': 'Complete merchant profile',
      'merchantProfileStep': 'Final step: complete your details',
      'merchantStoreName': 'Store name',
      'merchantStoreNameHint': 'Example: Modern Tech Store',
      'merchantStoreCategory': 'Store category',
      'merchantChooseCategory': 'Choose category',
      'merchantRegion': 'Region',
      'merchantAddressDetail': 'Detailed address',
      'merchantAddressHint': 'Street, building number...',
      'merchantDescription': 'Store description',
      'merchantDescriptionHint': 'Tell us what makes your store special...',
      'merchantWhatsApp': 'WhatsApp number',
      'merchantWorkHours': 'Work hours',
      'merchantWorkHoursHint': 'Example: 10 AM - 8 PM',
      'merchantStoreNameRequired': 'Please enter the store name',
      'restaurantCategory': 'Restaurants',
      'cafesCategory': 'Cafés',
      'fashionCategory': 'Clothing',
      'workspacesCategory': 'Workspaces',
      'giftsCategory': 'Gifts',
      'shoesCategory': 'Shoes',
      'carsCategory': 'Cars',
      'jewelryCategory': 'Jewelry',
      'cosmeticsCategory': 'Cosmetics',
      'supermarketCategory': 'Supermarket',
      'mallCategory': 'Mall',
      'storeCategoryDefault': 'Store',
      'marketCategory': 'Store',
      'electronicsCategory': 'Electronics',
      'medicalSuppliesCategory': 'Medical supplies',
      'opticsCategory': 'Optics',
      'storeSettingsTitle': 'Store settings',
      'storeNameLabel': 'Store name',
      'storeDescriptionLabel': 'Store description',
      'storeNameHint': 'Store name',
      'storeDescriptionHint': 'Write a short description for your store',
      'savingChanges': 'Saving...',
      'storeSavedSuccessfully': 'Store settings saved ✅',
      'storeNameRequiredError': 'Please enter the store name',
      'userWelcomeTitle': 'Welcome to Tradex',
      'userSelectionSubtitle': 'Choose the account type to continue',
      'shopperCardTitle': 'Shopper',
      'shopperCardDescription': 'Find products, compare prices, and shop with smart ease.',
      'merchantCardTitle': 'Merchant',
      'merchantCardDescription': 'Sell your products, track profits, and grow your business with AI.',
      'termsAgreementText': 'By continuing, you agree to the terms of service',
      'onboardingAiTag': 'Artificial Intelligence',
      'onboardingMainHeading': 'Market with',
      'onboardingDescription': 'Turn your ideas into polished marketing campaigns in seconds. Let our smart assistant handle the content and promotions.',
      'onboardingDataAnalysis': 'Data analysis',
      'onboardingExpectedGrowth': 'Expected growth',
      'skipToFinalStep': 'Skip to the final step',
      'chooseImageSourceTitle': 'Choose image source',
      'galleryLabel': 'Gallery',
      'cameraLabel': 'Camera',
      'photoUploadFailed': 'Unable to choose the image',
      'fullNameExample': 'Ahmad Mohamed',
      'phoneNumberExample': '05XXXXXXXX',
      'cityExample': 'Gaza',
      'deliveryNoteHint': 'Any delivery instructions...',
      'requiredFieldMessage': 'This field is required',
      'chooseCategory': 'Choose category',
      'accountAlreadyExists': 'Already have an account?',
      'emailAlreadyRegistered': 'This email is already registered.',
      'loginNow': 'Log in',
      'chooseStoreCategoryLabel': 'Choose category',
      'settings': 'Settings',
      'editProfile': 'Edit profile',
      'changePassword': 'Change password',
      'notifications': 'Notifications',
      'language': 'Language',
      'languageArabic': 'Arabic',
      'languageEnglish': 'English',
      'favorites': 'Favorites',
      'noFavorites': 'No favorite products',
      'logout': 'Log out',
      'loggingOut': 'Logging out...',
      'deleteAccount': 'Delete Account',
      'deletingAccount': 'Deleting account...',
      'deleteAccountConfirm': 'Delete account permanently?',
      'deleteAccountMessage': 'Your account will be permanently deleted and all associated sessions and personal data will be removed. This action cannot be undone.',
      'passwordCurrent': 'Current password',
      'passwordNew': 'New password',
      'passwordConfirm': 'Confirm new password',
      'passwordDescription': 'Create a new password to keep your account secure.',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'passwordSave': 'Save password',
      'passwordCancel': 'Cancel',
      'passwordChanged': 'Password changed successfully',
      'passwordSuccessDescription': 'Your password was updated and your current session was kept active.',
      'passwordBackToProfile': 'Back to profile',
      'passwordRequired': 'This field is required.',
      'passwordMinLength': 'Password must be at least 6 characters.',
      'passwordMismatch': 'Passwords do not match.',
      'sessionExpired': 'Your session expired. Please sign in again.',
      'forbidden': 'You do not have permission to do this.',
      'serverError': 'A server error occurred. Please try again.',
      'networkError': 'No internet connection. Check your network and try again.',
      'timeoutError': 'The request timed out. Please try again.',
      'unexpectedError': 'Something went wrong. Please try again.',
      'home': 'Home',
      'search': 'Search',
      'categories': 'Categories',
      'account': 'Account',
      'orders': 'Orders',
      'aiTools': 'AI tools',
      'myProducts': 'My products',
      'noScreensAvailable': 'No screens available',
      'markAllRead': 'Mark all as read',
      'noNotifications': 'No new notifications.',
      'filterStatus': 'Filter status',
      'allProducts': 'All products',
      'active': 'Active',
      'inactive': 'Hidden',
      'outOfStock': 'Out of stock',
      'visible': 'Visible',
      'hidden': 'Hidden',
      'stock': 'Stock',
      'deleteProduct': 'Delete product',
      'deleteProductConfirm': 'Are you sure you want to delete "{name}"?\\nThis action cannot be undone.',
      'noProductsYet': 'No products yet',
      'publishFirstProduct': 'Publish your first product and start selling now',
      'addNewProduct': 'Add new product',
      'productDeleted': 'Product deleted',
      'uploadPhoto': 'Upload photo',
      'skip': 'Skip',
      'chooseYourRegion': 'Choose your region',
      'useCurrentLocation': 'Use my current location',
      'aiImagePrompt': 'No photo? Create one that looks like you',
      'aiImagePromptHint': 'How would you like your photo to look?',
      'writeImageDescriptionFirst': 'Write a description for the image first',
      'aiFeatureInProgress': 'AI image generation is being prepared',
      'generateImage': 'Generate',
      'productDescriptionTool': 'Product description',
      'marketingContentTool': 'Marketing content',
      'hashtagsTool': 'Hashtags',
      'customerReplyTool': 'Customer reply',
      'aiPromptPlaceholder': 'How can I help you?',
      'aiGenerateButton': 'Generate with Tradex AI',
      'aiGenerateButtonLoading': 'Generating...',
      'aiWhatToDoPrompt': 'What do you want to accomplish today?',
      'aiChooseToolPrompt': 'Choose a tool or start from a product idea.',
      'aiSmartWorkspaceTitle': 'Your smart tools',
      'aiSmartWorkspaceSubtitle': 'Everything you need for your store',
      'aiContextPrompt1': 'Write a compelling description',
      'aiContextPrompt2': 'Prepare a post',
      'aiContextPrompt3': 'Reply to a customer',
      'aiRecentActivity': 'Recent activity',
      'aiSavedInSession': 'Saved in this session',
      'aiResultOutputHint': 'Your results will appear here after your first Tradex AI use.',
      'aiNoHistory': 'No saved operations yet.',
      'aiGenerateSheetTitleProduct': 'Write product description',
      'aiGenerateSheetTitleInstagram': 'Create Instagram post',
      'aiGenerateSheetTitleHashtags': 'Generate hashtags',
      'aiGenerateSheetTitleCustomerReply': 'Write customer reply',
      'aiStageLabel': 'Stage',
      'aiStageUnknown': 'Unknown',
      'aiCopiedToClipboard': 'Copied to clipboard ✅',
      'aiNoOperationsAfter': 'No operations yet. Use an AI tool to start generating.',
      'newOrders': 'New orders',
      'completedSales': 'Completed sales',
      'lowStock': 'Low stock',
      'addProductAction': 'Add product',
      'ordersAction': 'Orders',
      'profileAction': 'Profile',
      'storeSettingsAction': 'Store settings',
      'noOrdersYet': 'No orders yet',
      'ordersWillAppear': 'Customer orders will appear here as soon as they arrive',
      'updatePassword': 'Update password',
      'statusLabel': 'Status',
      'typeLabel': 'Type',
      'planType': 'Plan type',
      'paymentProofRequired': 'Please choose a payment proof image first.',
      'productOrTopic': 'Product / topic *',
      'customerMessageLabel': 'Customer message *',
      'optionalCategory': 'Category (optional)',
      'optionalDetails': 'Additional info (optional)',
      'exampleWirelessHeadphones': 'Example: Wireless Bluetooth headphones',
      'examplePerfume': 'Example: jasmine night perfume',
      'exampleCosmetics': 'Example: cosmetics',
      'exampleCustomerMessage': 'Paste the customer message here...',
      'minutesAgo': 'min ago',
      'hoursAgo': 'hr ago',
      'daysAgo': 'day ago',
      'resultText': 'Result',
      'copyText': 'Copy text',
      'generateAiText': 'Generate with AI',
      'before': 'before',
      'aiOverviewTitle': 'Recent operations',
      'aiOverviewSubtitle': 'View history',
      'aiViewHistory': 'View history',
      'subscriptionRequestFormTitle': 'Submit subscription request',
      'subscriptionRequestFormSubtitle': 'Enter the plan details and upload a payment proof image for review.',
      'selectPaymentProofLabel': 'Choose payment proof',
      'paymentProofRequirements': 'JPEG, PNG, or WebP image, max 4 MB',
      'planIdRequired': 'Plan ID is required',
      'fullNameRequired': 'Full name is required',
      'phoneRequired': 'Phone number is required',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'bankTransfer': 'Bank transfer',
      'cash': 'Cash payment',
      'activeStatus': 'Active',
      'expiredStatus': 'Expired',
      'cancelledStatus': 'Cancelled',
      'unknownStatus': 'Unknown',
      'approvedStatus': 'Approved',
      'rejectedStatus': 'Rejected',
      'pendingStatus': 'Pending review',
      'requestStatusLabel': 'Request status',
      'productCategoryDefault': 'General',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
