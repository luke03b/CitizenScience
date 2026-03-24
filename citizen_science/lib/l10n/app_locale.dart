import 'package:flutter_localization/flutter_localization.dart';

/// Localized strings for the Citizen Science application.
/// 
/// Contains all user-facing text in multiple languages (Italian and English).
class AppLocale {
  // Supported locales
  static const String it = 'it';
  static const String en = 'en';

  // Settings Screen
  static const userInfo = 'userInfo';
  static const edit = 'edit';
  static const firstName = 'firstName';
  static const yourFirstName = 'yourFirstName';
  static const enterFirstName = 'enterFirstName';
  static const lastName = 'lastName';
  static const yourLastName = 'yourLastName';
  static const enterLastName = 'enterLastName';
  static const email = 'email';
  static const yourEmail = 'yourEmail';
  static const enterEmail = 'enterEmail';
  static const enterValidEmail = 'enterValidEmail';
  static const cancel = 'cancel';
  static const save = 'save';
  static const appearance = 'appearance';
  static const darkMode = 'darkMode';
  static const toggleDarkMode = 'toggleDarkMode';
  static const language = 'language';
  static const selectLanguage = 'selectLanguage';
  static const italian = 'italian';
  static const english = 'english';
  static const selectAiModel = 'selectAiModel';
  static const configureAiModel = 'configureAiModel';
  static const account = 'account';
  static const changePassword = 'changePassword';
  static const logout = 'logout';
  static const confirmLogout = 'confirmLogout';
  static const confirmLogoutMessage = 'confirmLogoutMessage';
  static const exit = 'exit';
  static const infoUpdatedSuccess = 'infoUpdatedSuccess';
  static const updateError = 'updateError';

  // Login Screen
  static const citizenScience = 'citizenScience';
  static const welcomeLogin = 'welcomeLogin';
  static const password = 'password';
  static const enterPassword = 'enterPassword';
  static const passwordMinLength = 'passwordMinLength';
  static const login = 'login';
  static const noAccount = 'noAccount';
  static const register = 'register';
  static const loginFailed = 'loginFailed';

  // Registration Screen
  static const registration = 'registration';
  static const createAccount = 'createAccount';
  static const passwordConfirmation = 'passwordConfirmation';
  static const confirmPassword = 'confirmPassword';
  static const passwordsDontMatch = 'passwordsDontMatch';
  static const iAmResearcher = 'iAmResearcher';
  static const alreadyHaveAccount = 'alreadyHaveAccount';
  static const registrationFailed = 'registrationFailed';
  static const firstNameMinLength = 'firstNameMinLength';
  static const firstNameOnlyLetters = 'firstNameOnlyLetters';
  static const firstNameMaxLength = 'firstNameMaxLength';
  static const lastNameMinLength = 'lastNameMinLength';
  static const lastNameOnlyLetters = 'lastNameOnlyLetters';
  static const lastNameMaxLength = 'lastNameMaxLength';

  // Change Password Screen
  static const changePasswordTitle = 'changePasswordTitle';
  static const enterOldAndNew = 'enterOldAndNew';
  static const oldPassword = 'oldPassword';
  static const enterOldPassword = 'enterOldPassword';
  static const newPassword = 'newPassword';
  static const enterNewPassword = 'enterNewPassword';
  static const passwordChangedSuccess = 'passwordChangedSuccess';
  static const passwordChangeError = 'passwordChangeError';
  static const newPasswordMustBeDifferent = 'newPasswordMustBeDifferent';

  // Collection Screen
  static const myCollection = 'myCollection';
  static const noSightings = 'noSightings';
  static const noSightingsDesc = 'noSightingsDesc';
  static const sortBy = 'sortBy';
  static const mostRecent = 'mostRecent';
  static const leastRecent = 'leastRecent';
  static const closest = 'closest';
  static const farthest = 'farthest';
  static const alphabeticalAsc = 'alphabeticalAsc';
  static const alphabeticalDesc = 'alphabeticalDesc';

  // Map Screen
  static const map = 'map';
  static const sightings = 'sightings';

  // Sighting Details
  static const location = 'location';
  static const date = 'date';
  static const notes = 'notes';
  static const noNotes = 'noNotes';
  static const editNotes = 'editNotes';
  static const saveNotes = 'saveNotes';
  static const deleteSighting = 'deleteSighting';
  static const confirmDelete = 'confirmDelete';
  static const confirmDeleteMessage = 'confirmDeleteMessage';
  static const deleteAction = 'deleteAction';
  static const sightingDeleted = 'sightingDeleted';
  static const deleteError = 'deleteError';

  // Create Sighting Screen
  static const newSighting = 'newSighting';
  static const takePhoto = 'takePhoto';
  static const uploadPhoto = 'uploadPhoto';
  static const selectPhoto = 'selectPhoto';
  static const flowerName = 'flowerName';
  static const enterFlowerName = 'enterFlowerName';
  static const addNotes = 'addNotes';
  static const optionalNotes = 'optionalNotes';
  static const create = 'create';
  static const photoRequired = 'photoRequired';
  static const creationSuccess = 'creationSuccess';
  static const creationError = 'creationError';
  static const cameraError = 'cameraError';
  static const galleryError = 'galleryError';
  static const selectLocation = 'selectLocation';
  static const useCurrentLocation = 'useCurrentLocation';
  static const confirmSelection = 'confirmSelection';
  static const unknownError = 'unknownError';
  static const addPhoto = 'addPhoto';
  static const addPhotoDescription = 'addPhotoDescription';
  static const chooseFromGallery = 'chooseFromGallery';
  static const fromGallery = 'fromGallery';
  static const retakePhoto = 'retakePhoto';
  static const dateAndTime = 'dateAndTime';
  static const notesOptional = 'notesOptional';
  static const createSighting = 'createSighting';
  static const coordinates = 'coordinates';
  static const confirm = 'confirm';
  static const savedOffline = 'savedOffline';

  // Navigation
  static const mapLabel = 'mapLabel';
  static const collectionLabel = 'collectionLabel';
  static const settingsLabel = 'settingsLabel';

  // Common/General
  static const retry = 'retry';
  static const loading = 'loading';
  static const error = 'error';
  static const success = 'success';
  static const warning = 'warning';
  static const info = 'info';
  static const close = 'close';
  static const back = 'back';
  static const next = 'next';
  static const done = 'done';

  // Sighting Details Extended
  static const sightedBy = 'sightedBy';
  static const aiModel = 'aiModel';
  static const confidence = 'confidence';
  static const noNotesAvailable = 'noNotesAvailable';
  static const sightingNotFound = 'sightingNotFound';
  static const notesUpdatedSuccess = 'notesUpdatedSuccess';
  static const notesUpdateError = 'notesUpdateError';
  static const sightingDetails = 'sightingDetails';
  static const deleteInProgress = 'deleteInProgress';
  static const deleteSightingTooltip = 'deleteSightingTooltip';
  static const deleteConfirmationMessage = 'deleteConfirmationMessage';

  // Collection Screen Extended
  static const pendingSightingsHeader = 'pendingSightingsHeader';
  static const pendingSightingsSubtitle = 'pendingSightingsSubtitle';
  static const syncCompleted = 'syncCompleted';
  static const unableToLoadSightings = 'unableToLoadSightings';
  static const loadingSightings = 'loadingSightings';
  static const synchronize = 'synchronize';
  static const pendingSightingsCount = 'pendingSightingsCount';
  static const yourSightingsWillAppearHere = 'yourSightingsWillAppearHere';

  // Map Screen Extended
  static const networkError = 'networkError';
  static const networkErrorMessage = 'networkErrorMessage';
  static const locationError = 'locationError';
  static const locationErrorMessage = 'locationErrorMessage';
  static const locationServicesDisabled = 'locationServicesDisabled';
  static const locationPermissionDenied = 'locationPermissionDenied';
  static const details = 'details';
  static const centeredOnCurrentLocation = 'centeredOnCurrentLocation';
  static const availableModels = 'availableModels';
  static const confirmSelectionButton = 'confirmSelectionButton';

  // AI Model Selection Screen
  static const aiModelSelection = 'aiModelSelection';
  static const selectModelPrompt = 'selectModelPrompt';
  static const currentModel = 'currentModel';
  static const modelSelectedSuccess = 'modelSelectedSuccess';
  static const modelSelectionError = 'modelSelectionError';
  static const noModelsAvailable = 'noModelsAvailable';
  static const aiModelForThisSighting = 'aiModelForThisSighting';
  static const useDefaultModel = 'useDefaultModel';
  static const modelInfoTitle = 'modelInfoTitle';
  static const noModelDescription = 'noModelDescription';
  static const setAsDefault = 'setAsDefault';
  static const removeDefault = 'removeDefault';
  static const setDefaultSuccess = 'setDefaultSuccess';
  static const clearDefaultSuccess = 'clearDefaultSuccess';

  // Error Messages
  static const errorNetworkConnection = 'errorNetworkConnection';
  static const errorServerUnavailable = 'errorServerUnavailable';
  static const errorInvalidCredentials = 'errorInvalidCredentials';
  static const errorEmailAlreadyExists = 'errorEmailAlreadyExists';
  static const errorInvalidData = 'errorInvalidData';
  static const errorUnauthorized = 'errorUnauthorized';
  static const errorNotFound = 'errorNotFound';
  static const errorTimeout = 'errorTimeout';
  static const errorUnexpected = 'errorUnexpected';
  static const errorInvalidEmail = 'errorInvalidEmail';
  static const errorWeakPassword = 'errorWeakPassword';
  static const errorWrongPassword = 'errorWrongPassword';

  static final List<MapLocale> locales = [
    MapLocale(it, LocaleData.it),
    MapLocale(en, LocaleData.en),
  ];
}

class LocaleData {
  static const Map<String, dynamic> it = {
    // Settings Screen
    AppLocale.userInfo: 'Informazioni Utente',
    AppLocale.edit: 'Modifica',
    AppLocale.firstName: 'Nome',
    AppLocale.yourFirstName: 'Il tuo nome',
    AppLocale.enterFirstName: 'Inserisci il tuo nome',
    AppLocale.lastName: 'Cognome',
    AppLocale.yourLastName: 'Il tuo cognome',
    AppLocale.enterLastName: 'Inserisci il tuo cognome',
    AppLocale.email: 'Email',
    AppLocale.yourEmail: 'La tua email',
    AppLocale.enterEmail: 'Inserisci la tua email',
    AppLocale.enterValidEmail: 'Inserisci un\'email valida',
    AppLocale.cancel: 'Annulla',
    AppLocale.save: 'Salva',
    AppLocale.appearance: 'Aspetto',
    AppLocale.darkMode: 'Modalità Scura',
    AppLocale.toggleDarkMode: 'Attiva/disattiva il tema scuro',
    AppLocale.language: 'Lingua',
    AppLocale.selectLanguage: 'Seleziona la lingua dell\'applicazione',
    AppLocale.italian: 'Italiano',
    AppLocale.english: 'Inglese',
    AppLocale.selectAiModel: 'Seleziona Modello AI',
    AppLocale.configureAiModel: 'Configura il modello di intelligenza artificiale',
    AppLocale.account: 'Account',
    AppLocale.changePassword: 'Cambio Password',
    AppLocale.logout: 'Logout',
    AppLocale.confirmLogout: 'Conferma Logout',
    AppLocale.confirmLogoutMessage: 'Sei sicuro di voler uscire?',
    AppLocale.exit: 'Esci',
    AppLocale.infoUpdatedSuccess: 'Informazioni aggiornate con successo',
    AppLocale.updateError: 'Errore nell\'aggiornamento',

    // Login Screen
    AppLocale.citizenScience: 'Citizen Science',
    AppLocale.welcomeLogin: 'Benvenuto! Accedi per continuare',
    AppLocale.password: 'Password',
    AppLocale.enterPassword: 'Inserisci la tua password',
    AppLocale.passwordMinLength: 'La password deve essere di almeno 6 caratteri',
    AppLocale.login: 'Accedi',
    AppLocale.noAccount: 'Non hai un account? ',
    AppLocale.register: 'Registrati',
    AppLocale.loginFailed: 'Login fallito',

    // Registration Screen
    AppLocale.registration: 'Registrazione',
    AppLocale.createAccount: 'Crea il tuo account',
    AppLocale.passwordConfirmation: 'Conferma Password',
    AppLocale.confirmPassword: 'Conferma Password',
    AppLocale.passwordsDontMatch: 'Le password non corrispondono',
    AppLocale.iAmResearcher: 'Sono un ricercatore',
    AppLocale.alreadyHaveAccount: 'Hai già un account? ',
    AppLocale.registrationFailed: 'Registrazione fallita',
    AppLocale.firstNameMinLength: 'Il nome deve essere di almeno 2 caratteri',
    AppLocale.firstNameOnlyLetters: 'Il nome può contenere solo lettere',
    AppLocale.firstNameMaxLength: 'Il nome non può superare i 50 caratteri',
    AppLocale.lastNameMinLength: 'Il cognome deve essere di almeno 2 caratteri',
    AppLocale.lastNameOnlyLetters: 'Il cognome può contenere solo lettere',
    AppLocale.lastNameMaxLength: 'Il cognome non può superare i 50 caratteri',

    // Change Password Screen
    AppLocale.changePasswordTitle: 'Cambio Password',
    AppLocale.enterOldAndNew: 'Inserisci la tua vecchia password e la nuova password',
    AppLocale.oldPassword: 'Vecchia Password',
    AppLocale.enterOldPassword: 'Inserisci la tua vecchia password',
    AppLocale.newPassword: 'Nuova Password',
    AppLocale.enterNewPassword: 'Inserisci la nuova password',
    AppLocale.passwordChangedSuccess: 'Password cambiata con successo',
    AppLocale.passwordChangeError: 'Errore nel cambio password',
    AppLocale.newPasswordMustBeDifferent: 'La nuova password deve essere diversa dalla vecchia',

    // Collection Screen
    AppLocale.myCollection: 'La Mia Collezione',
    AppLocale.noSightings: 'Nessun avvistamento',
    AppLocale.noSightingsDesc: 'Inizia ad aggiungere avvistamenti dalla mappa',
    AppLocale.sortBy: 'Ordina per',
    AppLocale.mostRecent: 'Più recente',
    AppLocale.leastRecent: 'Meno recente',
    AppLocale.closest: 'Più vicino',
    AppLocale.farthest: 'Più lontano',
    AppLocale.alphabeticalAsc: 'A-Z',
    AppLocale.alphabeticalDesc: 'Z-A',

    // Map Screen
    AppLocale.map: 'Mappa',
    AppLocale.sightings: 'Avvistamenti',

    // Sighting Details
    AppLocale.location: 'Posizione',
    AppLocale.date: 'Data',
    AppLocale.notes: 'Note',
    AppLocale.noNotes: 'Nessuna nota',
    AppLocale.editNotes: 'Modifica Note',
    AppLocale.saveNotes: 'Salva Note',
    AppLocale.deleteSighting: 'Elimina Avvistamento',
    AppLocale.confirmDelete: 'Conferma Eliminazione',
    AppLocale.confirmDeleteMessage: 'Sei sicuro di voler eliminare questo avvistamento?',
    AppLocale.deleteAction: 'Elimina',
    AppLocale.sightingDeleted: 'Avvistamento eliminato con successo',
    AppLocale.deleteError: 'Errore nell\'eliminazione',

    // Create Sighting Screen
    AppLocale.newSighting: 'Nuovo Avvistamento',
    AppLocale.takePhoto: 'Scatta Foto',
    AppLocale.uploadPhoto: 'Carica Foto',
    AppLocale.selectPhoto: 'Seleziona una foto',
    AppLocale.flowerName: 'Nome del Fiore',
    AppLocale.enterFlowerName: 'Inserisci il nome del fiore',
    AppLocale.addNotes: 'Aggiungi Note',
    AppLocale.optionalNotes: 'Note opzionali sull\'avvistamento',
    AppLocale.create: 'Crea',
    AppLocale.photoRequired: 'È richiesta una foto',
    AppLocale.creationSuccess: 'Avvistamento creato con successo',
    AppLocale.creationError: 'Errore nella creazione',
    AppLocale.cameraError: 'Errore nell\'apertura della fotocamera',
    AppLocale.galleryError: 'Errore nell\'apertura della galleria',
    AppLocale.selectLocation: 'Seleziona Posizione',
    AppLocale.useCurrentLocation: 'Usa Posizione Corrente',
    AppLocale.confirmSelection: 'Conferma Selezione',
    AppLocale.unknownError: 'Errore sconosciuto',
    AppLocale.addPhoto: 'Aggiungi una foto',
    AppLocale.addPhotoDescription: 'Scatta una foto o selezionala dalla galleria per creare un nuovo avvistamento',
    AppLocale.chooseFromGallery: 'Scegli dalla galleria',
    AppLocale.fromGallery: 'Dalla galleria',
    AppLocale.retakePhoto: 'Scatta di nuovo',
    AppLocale.dateAndTime: 'Data e ora',
    AppLocale.notesOptional: 'Note (opzionale)',
    AppLocale.createSighting: 'Crea Avvistamento',
    AppLocale.coordinates: 'Coordinate',
    AppLocale.confirm: 'Conferma',
    AppLocale.savedOffline: 'Avvistamento salvato. Sarà caricato quando tornerà la connessione (In attesa di rete)',

    // Navigation
    AppLocale.mapLabel: 'Mappa',
    AppLocale.collectionLabel: 'Collezione',
    AppLocale.settingsLabel: 'Impostazioni',

    // Common/General
    AppLocale.retry: 'Riprova',
    AppLocale.loading: 'Caricamento...',
    AppLocale.error: 'Errore',
    AppLocale.success: 'Successo',
    AppLocale.warning: 'Attenzione',
    AppLocale.info: 'Informazione',
    AppLocale.close: 'Chiudi',
    AppLocale.back: 'Indietro',
    AppLocale.next: 'Avanti',
    AppLocale.done: 'Fatto',

    // Sighting Details Extended
    AppLocale.sightedBy: 'Avvistato da',
    AppLocale.aiModel: 'Modello AI',
    AppLocale.confidence: 'Confidenza',
    AppLocale.noNotesAvailable: 'Nessuna nota disponibile',
    AppLocale.sightingNotFound: 'Avvistamento non trovato',
    AppLocale.notesUpdatedSuccess: 'Note aggiornate con successo',
    AppLocale.notesUpdateError: 'Errore nell\'aggiornamento delle note',
    AppLocale.sightingDetails: 'Dettagli Avvistamento',
    AppLocale.deleteInProgress: 'Eliminazione in corso...',
    AppLocale.deleteSightingTooltip: 'Elimina avvistamento',
    AppLocale.deleteConfirmationMessage: 'Sei sicuro di voler eliminare questo avvistamento? Questa azione non può essere annullata.',

    // Collection Screen Extended
    AppLocale.pendingSightingsHeader: 'Avvistamenti in Attesa',
    AppLocale.pendingSightingsSubtitle: 'Questi avvistamenti non sono ancora stati sincronizzati',
    AppLocale.syncCompleted: 'Sincronizzazione completata',
    AppLocale.unableToLoadSightings: 'Impossibile caricare gli avvistamenti. Riprova più tardi.',
    AppLocale.loadingSightings: 'Caricamento avvistamenti...',
    AppLocale.synchronize: 'Sincronizza',
    AppLocale.pendingSightingsCount: 'avvistamento/i in attesa di rete',
    AppLocale.yourSightingsWillAppearHere: 'I tuoi avvistamenti appariranno qui',

    // Map Screen Extended
    AppLocale.networkError: 'Errore di Connessione',
    AppLocale.networkErrorMessage: 'Nessuna connessione a Internet. Gli avvistamenti saranno salvati localmente.',
    AppLocale.locationError: 'Errore di Posizione',
    AppLocale.locationErrorMessage: 'Impossibile ottenere la posizione. Verrà utilizzata una posizione predefinita.',
    AppLocale.locationServicesDisabled: 'I servizi di localizzazione sono disabilitati',
    AppLocale.locationPermissionDenied: 'Permesso di localizzazione negato',
    AppLocale.details: 'Dettagli',
    AppLocale.centeredOnCurrentLocation: 'Centrato sulla posizione attuale',
    AppLocale.availableModels: 'Modelli Disponibili',
    AppLocale.confirmSelectionButton: 'Conferma Selezione',

    // AI Model Selection Screen
    AppLocale.aiModelSelection: 'Selezione Modello AI',
    AppLocale.selectModelPrompt: 'Seleziona un modello di intelligenza artificiale',
    AppLocale.currentModel: 'Modello Corrente',
    AppLocale.modelSelectedSuccess: 'Modello selezionato con successo',
    AppLocale.modelSelectionError: 'Errore nella selezione del modello',
    AppLocale.noModelsAvailable: 'Nessun modello disponibile',
    AppLocale.aiModelForThisSighting: 'Seleziona Modello AI',
    AppLocale.useDefaultModel: 'Predefinito',
    AppLocale.modelInfoTitle: 'Informazioni Modello',
    AppLocale.noModelDescription: 'Nessuna descrizione disponibile per questo modello.',
    AppLocale.setAsDefault: 'Imposta come predefinito',
    AppLocale.removeDefault: 'Rimuovi predefinito',
    AppLocale.setDefaultSuccess: 'Modello predefinito impostato con successo',
    AppLocale.clearDefaultSuccess: 'Modello predefinito rimosso',

    // Error Messages
    AppLocale.errorNetworkConnection: 'Impossibile connettersi al server. Verifica la tua connessione Internet.',
    AppLocale.errorServerUnavailable: 'Il server non è al momento disponibile. Riprova più tardi.',
    AppLocale.errorInvalidCredentials: 'Email o password non corretti.',
    AppLocale.errorEmailAlreadyExists: 'Questa email è già registrata. Prova ad accedere.',
    AppLocale.errorInvalidData: 'I dati inseriti non sono validi. Controlla e riprova.',
    AppLocale.errorUnauthorized: 'Non sei autorizzato ad eseguire questa operazione.',
    AppLocale.errorNotFound: 'La risorsa richiesta non è stata trovata.',
    AppLocale.errorTimeout: 'Richiesta scaduta. Controlla la tua connessione e riprova.',
    AppLocale.errorUnexpected: 'Si è verificato un errore imprevisto. Riprova più tardi.',
    AppLocale.errorInvalidEmail: 'L\'indirizzo email non è valido.',
    AppLocale.errorWeakPassword: 'La password è troppo debole. Usa almeno 6 caratteri.',
    AppLocale.errorWrongPassword: 'La password inserita non è corretta.',
  };

  static const Map<String, dynamic> en = {
    // Settings Screen
    AppLocale.userInfo: 'User Information',
    AppLocale.edit: 'Edit',
    AppLocale.firstName: 'First Name',
    AppLocale.yourFirstName: 'Your first name',
    AppLocale.enterFirstName: 'Enter your first name',
    AppLocale.lastName: 'Last Name',
    AppLocale.yourLastName: 'Your last name',
    AppLocale.enterLastName: 'Enter your last name',
    AppLocale.email: 'Email',
    AppLocale.yourEmail: 'Your email',
    AppLocale.enterEmail: 'Enter your email',
    AppLocale.enterValidEmail: 'Enter a valid email',
    AppLocale.cancel: 'Cancel',
    AppLocale.save: 'Save',
    AppLocale.appearance: 'Appearance',
    AppLocale.darkMode: 'Dark Mode',
    AppLocale.toggleDarkMode: 'Toggle dark theme',
    AppLocale.language: 'Language',
    AppLocale.selectLanguage: 'Select application language',
    AppLocale.italian: 'Italian',
    AppLocale.english: 'English',
    AppLocale.selectAiModel: 'Select AI Model',
    AppLocale.configureAiModel: 'Configure artificial intelligence model',
    AppLocale.account: 'Account',
    AppLocale.changePassword: 'Change Password',
    AppLocale.logout: 'Logout',
    AppLocale.confirmLogout: 'Confirm Logout',
    AppLocale.confirmLogoutMessage: 'Are you sure you want to log out?',
    AppLocale.exit: 'Exit',
    AppLocale.infoUpdatedSuccess: 'Information updated successfully',
    AppLocale.updateError: 'Update error',

    // Login Screen
    AppLocale.citizenScience: 'Citizen Science',
    AppLocale.welcomeLogin: 'Welcome! Log in to continue',
    AppLocale.password: 'Password',
    AppLocale.enterPassword: 'Enter your password',
    AppLocale.passwordMinLength: 'Password must be at least 6 characters',
    AppLocale.login: 'Login',
    AppLocale.noAccount: 'Don\'t have an account? ',
    AppLocale.register: 'Sign Up',
    AppLocale.loginFailed: 'Login failed',

    // Registration Screen
    AppLocale.registration: 'Registration',
    AppLocale.createAccount: 'Create your account',
    AppLocale.passwordConfirmation: 'Password Confirmation',
    AppLocale.confirmPassword: 'Confirm Password',
    AppLocale.passwordsDontMatch: 'Passwords do not match',
    AppLocale.iAmResearcher: 'I am a researcher',
    AppLocale.alreadyHaveAccount: 'Already have an account? ',
    AppLocale.registrationFailed: 'Registration failed',
    AppLocale.firstNameMinLength: 'First name must be at least 2 characters',
    AppLocale.firstNameOnlyLetters: 'First name can only contain letters',
    AppLocale.firstNameMaxLength: 'First name cannot exceed 50 characters',
    AppLocale.lastNameMinLength: 'Last name must be at least 2 characters',
    AppLocale.lastNameOnlyLetters: 'Last name can only contain letters',
    AppLocale.lastNameMaxLength: 'Last name cannot exceed 50 characters',

    // Change Password Screen
    AppLocale.changePasswordTitle: 'Change Password',
    AppLocale.enterOldAndNew: 'Enter your old password and new password',
    AppLocale.oldPassword: 'Old Password',
    AppLocale.enterOldPassword: 'Enter your old password',
    AppLocale.newPassword: 'New Password',
    AppLocale.enterNewPassword: 'Enter new password',
    AppLocale.passwordChangedSuccess: 'Password changed successfully',
    AppLocale.passwordChangeError: 'Error changing password',
    AppLocale.newPasswordMustBeDifferent: 'New password must be different from old password',

    // Collection Screen
    AppLocale.myCollection: 'My Collection',
    AppLocale.noSightings: 'No sightings',
    AppLocale.noSightingsDesc: 'Start adding sightings from the map',
    AppLocale.sortBy: 'Sort by',
    AppLocale.mostRecent: 'Most recent',
    AppLocale.leastRecent: 'Least recent',
    AppLocale.closest: 'Closest',
    AppLocale.farthest: 'Farthest',
    AppLocale.alphabeticalAsc: 'A-Z',
    AppLocale.alphabeticalDesc: 'Z-A',

    // Map Screen
    AppLocale.map: 'Map',
    AppLocale.sightings: 'Sightings',

    // Sighting Details
    AppLocale.location: 'Location',
    AppLocale.date: 'Date',
    AppLocale.notes: 'Notes',
    AppLocale.noNotes: 'No notes',
    AppLocale.editNotes: 'Edit Notes',
    AppLocale.saveNotes: 'Save Notes',
    AppLocale.deleteSighting: 'Delete Sighting',
    AppLocale.confirmDelete: 'Confirm Deletion',
    AppLocale.confirmDeleteMessage: 'Are you sure you want to delete this sighting?',
    AppLocale.deleteAction: 'Delete',
    AppLocale.sightingDeleted: 'Sighting deleted successfully',
    AppLocale.deleteError: 'Deletion error',

    // Create Sighting Screen
    AppLocale.newSighting: 'New Sighting',
    AppLocale.takePhoto: 'Take Photo',
    AppLocale.uploadPhoto: 'Upload Photo',
    AppLocale.selectPhoto: 'Select a photo',
    AppLocale.flowerName: 'Flower Name',
    AppLocale.enterFlowerName: 'Enter flower name',
    AppLocale.addNotes: 'Add Notes',
    AppLocale.optionalNotes: 'Optional notes about the sighting',
    AppLocale.create: 'Create',
    AppLocale.photoRequired: 'A photo is required',
    AppLocale.creationSuccess: 'Sighting created successfully',
    AppLocale.creationError: 'Creation error',
    AppLocale.cameraError: 'Error opening camera',
    AppLocale.galleryError: 'Error opening gallery',
    AppLocale.selectLocation: 'Select Location',
    AppLocale.useCurrentLocation: 'Use Current Location',
    AppLocale.confirmSelection: 'Confirm Selection',
    AppLocale.unknownError: 'Unknown error',
    AppLocale.addPhoto: 'Add a photo',
    AppLocale.addPhotoDescription: 'Take a photo or select one from the gallery to create a new sighting',
    AppLocale.chooseFromGallery: 'Choose from gallery',
    AppLocale.fromGallery: 'From gallery',
    AppLocale.retakePhoto: 'Retake photo',
    AppLocale.dateAndTime: 'Date and time',
    AppLocale.notesOptional: 'Notes (optional)',
    AppLocale.createSighting: 'Create Sighting',
    AppLocale.coordinates: 'Coordinates',
    AppLocale.confirm: 'Confirm',
    AppLocale.savedOffline: 'Sighting saved. It will be uploaded when connection returns (Waiting for network)',

    // Navigation
    AppLocale.mapLabel: 'Map',
    AppLocale.collectionLabel: 'Collection',
    AppLocale.settingsLabel: 'Settings',

    // Common/General
    AppLocale.retry: 'Retry',
    AppLocale.loading: 'Loading...',
    AppLocale.error: 'Error',
    AppLocale.success: 'Success',
    AppLocale.warning: 'Warning',
    AppLocale.info: 'Information',
    AppLocale.close: 'Close',
    AppLocale.back: 'Back',
    AppLocale.next: 'Next',
    AppLocale.done: 'Done',

    // Sighting Details Extended
    AppLocale.sightedBy: 'Sighted By',
    AppLocale.aiModel: 'AI Model',
    AppLocale.confidence: 'Confidence',
    AppLocale.noNotesAvailable: 'No notes available',
    AppLocale.sightingNotFound: 'Sighting not found',
    AppLocale.notesUpdatedSuccess: 'Notes updated successfully',
    AppLocale.notesUpdateError: 'Error updating notes',
    AppLocale.sightingDetails: 'Sighting Details',
    AppLocale.deleteInProgress: 'Deleting...',
    AppLocale.deleteSightingTooltip: 'Delete sighting',
    AppLocale.deleteConfirmationMessage: 'Are you sure you want to delete this sighting? This action cannot be undone.',

    // Collection Screen Extended
    AppLocale.pendingSightingsHeader: 'Pending Sightings',
    AppLocale.pendingSightingsSubtitle: 'These sightings have not been synced yet',
    AppLocale.syncCompleted: 'Synchronization completed',
    AppLocale.unableToLoadSightings: 'Unable to load sightings. Please try again later.',
    AppLocale.loadingSightings: 'Loading sightings...',
    AppLocale.synchronize: 'Synchronize',
    AppLocale.pendingSightingsCount: 'sighting(s) waiting for network',
    AppLocale.yourSightingsWillAppearHere: 'Your sightings will appear here',

    // Map Screen Extended
    AppLocale.networkError: 'Connection Error',
    AppLocale.networkErrorMessage: 'No internet connection. Sightings will be saved locally.',
    AppLocale.locationError: 'Location Error',
    AppLocale.locationErrorMessage: 'Unable to get location. A default location will be used.',
    AppLocale.locationServicesDisabled: 'Location services are disabled',
    AppLocale.locationPermissionDenied: 'Location permission denied',
    AppLocale.details: 'Details',
    AppLocale.centeredOnCurrentLocation: 'Centered on current location',
    AppLocale.availableModels: 'Available Models',
    AppLocale.confirmSelectionButton: 'Confirm Selection',

    // AI Model Selection Screen
    AppLocale.aiModelSelection: 'AI Model Selection',
    AppLocale.selectModelPrompt: 'Select an artificial intelligence model',
    AppLocale.currentModel: 'Current Model',
    AppLocale.modelSelectedSuccess: 'Model selected successfully',
    AppLocale.modelSelectionError: 'Error selecting model',
    AppLocale.noModelsAvailable: 'No models available',
    AppLocale.aiModelForThisSighting: 'Select AI model',
    AppLocale.useDefaultModel: 'Default',
    AppLocale.modelInfoTitle: 'Model Information',
    AppLocale.noModelDescription: 'No description available for this model.',
    AppLocale.setAsDefault: 'Set as default',
    AppLocale.removeDefault: 'Remove default',
    AppLocale.setDefaultSuccess: 'Default model set successfully',
    AppLocale.clearDefaultSuccess: 'Default model cleared',

    // Error Messages
    AppLocale.errorNetworkConnection: 'Unable to connect to the server. Please check your Internet connection.',
    AppLocale.errorServerUnavailable: 'The server is currently unavailable. Please try again later.',
    AppLocale.errorInvalidCredentials: 'Invalid email or password.',
    AppLocale.errorEmailAlreadyExists: 'This email is already registered. Try logging in.',
    AppLocale.errorInvalidData: 'The data entered is not valid. Please check and try again.',
    AppLocale.errorUnauthorized: 'You are not authorized to perform this operation.',
    AppLocale.errorNotFound: 'The requested resource was not found.',
    AppLocale.errorTimeout: 'Request timed out. Check your connection and try again.',
    AppLocale.errorUnexpected: 'An unexpected error occurred. Please try again later.',
    AppLocale.errorInvalidEmail: 'The email address is not valid.',
    AppLocale.errorWeakPassword: 'The password is too weak. Use at least 6 characters.',
    AppLocale.errorWrongPassword: 'The password entered is incorrect.',
  };
}
