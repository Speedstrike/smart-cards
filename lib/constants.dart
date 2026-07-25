// MIT License
//
// Copyright (c) 2026 Aaryan Karlapalem
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:flutter/cupertino.dart';

class Constants {
  static const String dbURL = 'https://ivinjnnepudqjvemmxaw.supabase.co';
  static const String dbKey = 'sb_publishable_pSSmUJyAMnvuevtFtjSn-Q_BrLWHWRV';

  static const String morningGreeting = 'Good morning';
  static const String afternoonGreeting = 'Good afternoon';
  static const String eveningGreeting = 'Good evening';
  static const String nightGreeting = 'Good night';

  static const String mainSubtitle = 'Your recent flashcards';
  static const String noRecentDecks = 'You don\'t have any flashcards yet.\nTap + to create one.';
  static const String noMatchingDecks = 'No decks match your search or filters.';
  static const String deckSearchPlaceholder = 'Search decks';
  static const String deckFilterLabel = 'Filter';
  static const String deckSortLabel = 'Sort';
  static const String deckAllFilter = 'All';
  static const String deckSmallFilter = 'Small';
  static const String deckMediumFilter = 'Medium';
  static const String deckLargeFilter = 'Large';
  static const String deckNewestSort = 'Newest';
  static const String deckOldestSort = 'Oldest';
  static const String deckAZSort = 'A-Z';
  static const String deckCardsHighSort = 'Cards ↓';
  static const String deckCardsLowSort = 'Cards ↑';
  static const String deckResetFilters = 'Reset filters';

  static const String createDeckTitle = 'Create a new deck';
  static const String createDeckSubtitle = 'How do you want to create your deck?';

  static const String scanTitle = 'Scan notes';
  static const String scanSubtitle = 'Take a picture of your notes, assignment, or textbook page, to generate flashcards';
  static const String uploadTitle = 'Upload files';
  static const String uploadSubtitle = 'Upload a PDF, image, or text file to create flashcards from its content';
  static const String aiTitle = 'AI Generation';
  static const String aiSubtitle = 'Use AI to generate flashcards from a topic or text you provide';

  static const String uploadInstructions = 'Select files to upload to generate flashcards';
  static const String scanInstructions = 'Scan your notes, assignment, or textbook page to create a deck';
  static const String aiInstructions = 'Enter a topic and number of flashcards to generate a deck using AI';

  static const String scanRecognizedTextLabel = 'Recognized text';
  static const String scanRecognizingText = 'Reading text from image...';
  static const String scanRetakeButton = 'Retake photo';
  static const String scanExtractButton = 'Extract text';
  static const String scanOcrPlaceholder = 'Extracted notes will appear here';
  static const String scanOcrUnavailable ='OCR is available on Android and iOS only.';
  static const String scanOcrEmpty = 'No readable text was found. Try a clearer image.';

  static const String aiTopicPlaceholder = 'Flashcard topic';
  static const String flashcardCountPlaceholder = 'Number of flashcards';
  static const String continueButtonText = 'Generate flashcards';

  static const String accountCreateTitle = 'Create Account';
  static const String accountWelcomeTitle = 'Welcome Back';
  static const String accountSettingsTitle = 'Account Settings';
  static const String accountCreateSubtitle = 'Start studying smarter today.';
  static const String accountWelcomeSubtitle = 'Sign in to access your profile.';
  static const String accountDeleteDialogTitle = 'Delete Account';
  static const String accountDeleteDialogContent = 'This permanently deletes your account and all saved decks. This cannot be undone.';
  static const String accountDeleteButtonText = 'Delete';
  static const String accountCancelButtonText = 'Cancel';
  static const String accountPlaceholderEmail = 'Email Address';
  static const String accountPlaceholderPassword = 'Password';
  static const String accountPlaceholderNewEmail = 'New email address';
  static const String accountPlaceholderNewPassword = 'New password';
  static const String accountPlaceholderConfirmPassword = 'Confirm new password';
  static const String accountButtonSignUp = 'Create Account';
  static const String accountButtonSignIn = 'Sign In';
  static const String accountButtonToggleToSignIn = 'Already have an account? Sign In';
  static const String accountButtonToggleToSignUp = 'New here? Create an Account';
  static const String accountForgotPassword = 'Forgot password?';
  static const String accountRowChangeEmail = 'Change Email';
  static const String accountRowChangePassword = 'Change Password';
  static const String accountRowSignOut = 'Sign Out';
  static const String accountRowDeleteAccount = 'Delete Account';
  static const String accountButtonUpdateEmail = 'Update Email';
  static const String accountButtonUpdatePassword = 'Update Password';
  static const String accountButtonBack = 'Back';

  static const String errorEmptyCredentials = 'Please enter your email and password.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorEmptyEmailReset = 'Enter your email address first.';
  static const String errorEmptyNewEmail = 'Enter a new email address.';
  static const String errorEmptyPasswordFields = 'Please fill in both fields.';
  static const String errorPasswordMismatch = 'Passwords do not match.';
  static const String errorPasswordLength = 'Password must be at least 6 characters.';
  static const String errorDeleteAccount = 'Could not delete account. Please try again.';

  static const String successAccountCreated = 'Account created!';
  static const String successConfirmEmail = 'Check your email to confirm your account.';
  static const String successWelcomeBack = 'Welcome back!';
  static const String successPasswordResetSent = 'Password reset email sent.';
  static const String successPasswordUpdated = 'Password updated successfully.';

  static const String saveConfirmationText = 'OK';
  static const String saveErrorMessage = 'Failed to save';
  static const String saveErrorExplanationText = 'Create an account to save your created decks!';

  static const String previousCardButtonText = 'Previous';
  static const String nextCardButtonText = 'Next';

  static const String editDeckTitle = 'Edit deck';
  static const String editDeckSubtitle = 'Update the title or cards in this deck';
  static const String editTitlePlaceholder = 'Deck title';
  static const String editAddCardButtonText = 'Add card';
  static const String editSaveButtonText = 'Save changes';
  static const String editEmptyFieldsError = 'Give your deck a title and at least one complete card.';
  static const String editDeleteDeckDialogTitle = 'Delete Deck';
  static const String editDeleteDeckDialogContent = 'This permanently deletes this deck and all its flashcards. This cannot be undone.';

  static const String shareTite = 'Share / Export';
  static const String shareInstructions = 'Share the deck text or export it as a CSV file.';
  static const String shareExportInstructions = 'Share deck';
  static const String shareCSVInstructions = 'Export CSV';
  static const String shareCancel = 'Cancel';

  static const List<String> allowedFileExtensions = ['pdf', 'png', 'jpg', 'jpeg', 'heic', 'txt', 'dat'];

  static const Color background = Color(0xFF1C1C1E);
  static const Color cardBackground = Color(0xFF2C2C2E);
  static const Color cardSubBackground = Color(0xFF222224);
  static const Color border = Color(0xFF3A3A3C);
  static const Color inputBackground = Color(0xFF333333);
  static const Color deckGradientStart = Color(0xFFFFE500);
  static const Color deckGradientEnd = Color(0xFF00FF00);
  static const Color deckTitleText = Color(0xFF1A2E00);
  static const Color deckSubtitleText = Color(0xFF3A5200);
}