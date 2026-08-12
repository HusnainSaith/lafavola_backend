// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'La Favola';

  @override
  String get language => 'Lingua';

  @override
  String get english => 'Inglese';

  @override
  String get italian => 'Italiano';

  @override
  String get publicMenu => 'Menu pubblico';

  @override
  String get signIn => 'Accedi';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Ordini';

  @override
  String get profile => 'Profilo';

  @override
  String get preferences => 'Preferenze';

  @override
  String get privacy => 'Privacy';

  @override
  String get contentNotFound => 'Contenuto non trovato';

  @override
  String get invalidMenuItem => 'Questa voce del menu non è più disponibile.';

  @override
  String get createYourPizza => 'Crea la tua pizza';

  @override
  String get createPizzaWithLivePricing => 'Crea la tua pizza con prezzo in tempo reale';

  @override
  String get yourOrder => 'Il tuo ordine';

  @override
  String get closeCheckout => 'Chiudi il riepilogo';

  @override
  String get quantity => 'Quantità';

  @override
  String get fulfilment => 'Modalità di consegna';

  @override
  String get delivery => 'Consegna';

  @override
  String get pickup => 'Ritiro';

  @override
  String get deliveryAddress => 'Indirizzo di consegna';

  @override
  String get missingDeliveryAddress => 'Aggiungi un indirizzo salvato nel Profilo prima di richiedere la consegna.';

  @override
  String get promoCode => 'Codice promozionale';

  @override
  String get apply => 'Applica';

  @override
  String get payment => 'Pagamento';

  @override
  String get cashOnDelivery => 'Contanti alla consegna';

  @override
  String get cashOnPickup => 'Contanti al ritiro';

  @override
  String get payOnHandover => 'Paga quando ricevi l’ordine.';

  @override
  String get onlineCard => 'Carta online';

  @override
  String get onlineCardUnavailable => 'Non ancora attiva. Non vengono raccolti dati della carta.';

  @override
  String get placeOrder => 'Invia l’ordine con totale aggiornato';

  @override
  String get orderReceived => 'Ordine ricevuto';

  @override
  String reference(String reference) {
    return 'Riferimento: $reference';
  }

  @override
  String total(String total) {
    return 'Totale: $total';
  }

  @override
  String get orderVisibleToTeam => 'Il team ordini di La Favola può ora vedere questo ordine.';

  @override
  String get backToMenu => 'Torna al menu';

  @override
  String get trackOrder => 'Segui l’ordine';

  @override
  String get livePriceNotice => 'Totale finale, imposte, promozioni e disponibilità vengono ricalcolati in sicurezza prima della conferma.';

  @override
  String get size => 'Formato';

  @override
  String get required => 'Obbligatorio';

  @override
  String chooseUpTo(int count) {
    return 'Scegli fino a $count';
  }

  @override
  String get loading => 'Caricamento…';

  @override
  String get retry => 'Riprova';

  @override
  String get noMenuItems => 'Nessuna voce del menu è disponibile in questo momento.';

  @override
  String get searchMenu => 'Cerca nel menu';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get orderTracking => 'Stato dell’ordine';

  @override
  String get estimatedReady => 'Orario di preparazione stimato';

  @override
  String get estimatedArrival => 'Arrivo stimato';

  @override
  String remainingMinutes(int minutes) {
    return 'Circa $minutes min rimanenti';
  }

  @override
  String get dueNow => 'In arrivo';

  @override
  String lastUpdated(String time) {
    return 'Aggiornato alle $time';
  }

  @override
  String get liveUpdates => 'Aggiornamenti in tempo reale';

  @override
  String get reconnecting => 'Riconnessione…';

  @override
  String get offlineTracking => 'Gli aggiornamenti in tempo reale non sono disponibili. L’app continuerà a riprovare in sicurezza.';

  @override
  String get cancelOrder => 'Annulla ordine';

  @override
  String get cancelReason => 'Motivo dell’annullamento';

  @override
  String get confirmCancellation => 'Conferma annullamento';

  @override
  String get keepOrder => 'Mantieni ordine';

  @override
  String get orderReceipt => 'Ricevuta ordine';

  @override
  String get receiptNotice => 'Questa è una ricevuta dell’ordine, non una fattura fiscale. Il documento fiscale viene emesso dal fornitore configurato quando applicabile.';

  @override
  String get subtotal => 'Subtotale';

  @override
  String get options => 'Opzioni';

  @override
  String get deliveryFee => 'Costo di consegna';

  @override
  String get discount => 'Sconto';

  @override
  String get tax => 'Imposte';

  @override
  String get grandTotal => 'Totale';

  @override
  String get statusPendingPayment => 'In attesa di pagamento';

  @override
  String get statusPlaced => 'Ordine inviato';

  @override
  String get statusAccepted => 'Accettato';

  @override
  String get statusPreparing => 'In preparazione';

  @override
  String get statusBaking => 'In forno';

  @override
  String get statusPacking => 'In confezionamento';

  @override
  String get statusReady => 'Pronto';

  @override
  String get statusDriverAssigned => 'Fattorino assegnato';

  @override
  String get statusOutForDelivery => 'In consegna';

  @override
  String get statusDelivered => 'Consegnato';

  @override
  String get statusClosed => 'Completato';

  @override
  String get statusCancelled => 'Annullato';

  @override
  String get statusRejected => 'Rifiutato';

  @override
  String get bresciaItaly => 'BRESCIA · ITALIA';

  @override
  String get menuHeroTitle => 'Il menu,\nindimenticabile.';

  @override
  String liveCatalogue(String version) {
    return 'Menu live · catalogo $version';
  }

  @override
  String get menuCategories => 'Categorie del menu';

  @override
  String get discoverFavourites => 'Scopri i preferiti di oggi';

  @override
  String get clearSearch => 'Cancella ricerca';

  @override
  String menuResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti',
      one: '1 prodotto',
      zero: 'Nessun prodotto',
    );
    return '$_temp0';
  }

  @override
  String get madeWithCare => 'Preparato con cura';

  @override
  String get detailsUnavailable => 'I dettagli non sono disponibili per questo prodotto.';

  @override
  String get dietaryAllergenInfo => 'Informazioni alimentari e allergeni';

  @override
  String get customizePizza => 'Personalizza la tua pizza';

  @override
  String get addToOrder => 'Aggiungi all’ordine';

  @override
  String get builderIntro => 'Creala come vuoi. Il prezzo si aggiorna in tempo reale.';

  @override
  String get chooseOne => 'Scegli una';

  @override
  String get checkingPrice => 'Verifica del prezzo in corso…';

  @override
  String get livePriceUnavailable => 'Il prezzo live non è disponibile.';

  @override
  String get items => 'Prodotti';

  @override
  String get weCouldNotLoadMenu => 'Impossibile caricare il menu live';

  @override
  String get menuUpdating => 'Il menu è in aggiornamento';

  @override
  String get noLiveCategories => 'Al momento non ci sono categorie disponibili.';

  @override
  String get noSearchResults => 'Nessun prodotto corrisponde alla ricerca.';

  @override
  String get orderHistory => 'I tuoi ordini';

  @override
  String get allOrders => 'Tutti';

  @override
  String get active => 'Attivi';

  @override
  String get completed => 'Completati';

  @override
  String get noOrders => 'I tuoi ordini appariranno qui.';

  @override
  String get timeline => 'Cronologia';

  @override
  String get orderReceivedTimeline => 'L’ordine è stato ricevuto.';

  @override
  String get requestCancellation => 'Richiedi annullamento';

  @override
  String get sendingRequest => 'Invio richiesta…';

  @override
  String get sendRequest => 'Invia richiesta';

  @override
  String get estimatePending => 'Stima in attesa';

  @override
  String get finalisingNow => 'In completamento';

  @override
  String countdown(int minutes, String seconds) {
    return '$minutes:$seconds rimanenti';
  }

  @override
  String lateEstimate(int minutes) {
    return '$minutes min oltre la stima';
  }

  @override
  String get estimatedCollectionReady => 'Ritiro stimato';

  @override
  String get estimatedKitchenReady => 'Preparazione stimata';

  @override
  String get viewReceipt => 'Visualizza ricevuta';

  @override
  String get receiptLoading => 'Caricamento ricevuta…';

  @override
  String get receiptFailed => 'Impossibile caricare la ricevuta.';

  @override
  String issuedAt(String date) {
    return 'Emessa il $date';
  }

  @override
  String get unitPrice => 'Prezzo unitario';

  @override
  String get optionCharges => 'Supplementi';

  @override
  String get statusPickedUp => 'Ritirato';

  @override
  String get statusServed => 'Servito';

  @override
  String get statusDeliveryFailed => 'La consegna richiede attenzione';

  @override
  String get waitingConfirmation => 'In attesa di conferma dal ristorante';

  @override
  String get orderConfirmed => 'Ordine confermato';

  @override
  String get orderBeingPrepared => 'Il tuo ordine è in preparazione';

  @override
  String get pizzaInOven => 'La tua pizza è in forno';

  @override
  String get packingOrder => 'Confezionamento dell’ordine';

  @override
  String get readyForRider => 'Pronto, in attesa del rider';

  @override
  String get readyForPickup => 'Pronto per il ritiro';

  @override
  String get riderOnWay => 'Il rider è in arrivo';

  @override
  String tableLabel(String table) {
    return 'Tavolo $table';
  }

  @override
  String selectionRequired(int count) {
    return 'Seleziona almeno $count';
  }

  @override
  String selectionTooMany(int count) {
    return 'Seleziona al massimo $count';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signInSubtitle => 'Accedi per gestire il tuo account oppure consulta il menu pubblico.';

  @override
  String get signingIn => 'Accesso in corso…';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get otherSignInMethods => 'Altri metodi di accesso';

  @override
  String get continueGoogle => 'Continua con Google';

  @override
  String get continueApple => 'Continua con Apple';

  @override
  String get continueGuest => 'Continua come ospite';

  @override
  String get guestSubtitle => 'Esplora il menu completo di La Favola senza accedere';

  @override
  String get createAccount => 'Crea un account';

  @override
  String get haveVerificationCode => 'Hai già un codice di verifica?';

  @override
  String get publicAccountNotice => 'Il menu è pubblico. Profilo, indirizzi e privacy richiedono un account.';

  @override
  String get sessionUnavailable => 'Sessione non disponibile';

  @override
  String get validEmailError => 'Inserisci un indirizzo email valido.';

  @override
  String get passwordMinError => 'La password deve contenere almeno 8 caratteri.';

  @override
  String get registration => 'Registrazione';

  @override
  String get registrationSubtitle => 'Crea il tuo account per salvare preferiti e ordini.';

  @override
  String get name => 'Nome';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get creatingAccount => 'Creazione in corso…';

  @override
  String get goToSignIn => 'Vai all\'accesso';

  @override
  String get registrationCompleted => 'Registrazione completata';

  @override
  String get registrationCompletedMessage => 'Il tuo account è pronto. Accedi con email e password.';

  @override
  String get fixFields => 'Correggi i campi';

  @override
  String get passwordRequirements => 'Da 8 a 72 caratteri. Incolla e gestori di password sono supportati.';

  @override
  String get termsTitle => 'Informative e condizioni';

  @override
  String get termsMessage => 'La registrazione non attiva comunicazioni promozionali. Le informative applicabili devono essere disponibili prima della distribuzione.';

  @override
  String get verifyEmail => 'Verifica email';

  @override
  String get verifyEmailSubtitle => 'Inserisci il codice monouso ricevuto via email.';

  @override
  String get verificationCode => 'Codice di verifica';

  @override
  String get verifying => 'Verifica in corso…';

  @override
  String get verify => 'Verifica';

  @override
  String get resendEmail => 'Email per nuovo invio';

  @override
  String get resend => 'Invia di nuovo';

  @override
  String get verificationResult => 'Risultato verifica';

  @override
  String get passwordRecovery => 'Recupero password';

  @override
  String get recoveryTitle => 'Recupero e reimpostazione';

  @override
  String get recoverySubtitle => 'Richiedi un link oppure completa la reimpostazione con il codice ricevuto.';

  @override
  String get requestRecovery => 'Richiedi recupero';

  @override
  String get resetCode => 'Codice di reimpostazione';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get updatePassword => 'Aggiorna password';

  @override
  String get operationCompleted => 'Operazione completata';

  @override
  String get requestRecoveryStep => '1. Richiedi recupero';

  @override
  String get requestRecoveryHelp => 'La risposta non conferma se l’account esiste.';

  @override
  String get resetPasswordStep => '2. Imposta nuova password';

  @override
  String get resetPasswordHelp => 'I codici monouso scaduti o già usati non modificano l’account.';

  @override
  String providerSignIn(String provider) {
    return 'Accesso con $provider';
  }

  @override
  String get providerSubtitle => 'Il collegamento si completa soltanto dopo un ritorno verificato dal provider.';

  @override
  String get providerNotConfigured => 'Metodo non configurato';

  @override
  String get providerNotConfiguredMessage => 'Questo metodo di accesso non è disponibile in questa configurazione.';

  @override
  String get startSecureSignIn => 'Avvia accesso protetto';

  @override
  String get startSecureSignInHelp => 'Nessun account viene collegato finché il ritorno non è verificato.';

  @override
  String get preparing => 'Preparazione…';

  @override
  String get continueAction => 'Continua';

  @override
  String get waitingProvider => 'In attesa del provider';

  @override
  String get waitingProviderMessage => 'Completa l’accesso nella finestra protetta. Puoi tornare indietro senza modificare l’account.';

  @override
  String get profileLoading => 'Caricamento profilo cliente';

  @override
  String get profileData => 'Dati del profilo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get displayName => 'Nome visualizzato';

  @override
  String get verifiedEmail => 'Email verificata';

  @override
  String get optionalPhone => 'Telefono (facoltativo)';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get edit => 'Modifica';

  @override
  String get accountSummary => 'Riepilogo account';

  @override
  String versionValue(String version) {
    return 'Versione $version';
  }

  @override
  String get currentLanguage => 'Lingua: Italiano (Italia)';

  @override
  String get emailReadOnlyNotice => 'Il cambio email non è incluso nel salvataggio generico del profilo.';

  @override
  String get profileSubtitle => 'Dati propri e versionati. L’email resta un’identità di sola lettura.';

  @override
  String get profileUpdated => 'Profilo aggiornato';

  @override
  String get addresses => 'Indirizzi';

  @override
  String get savedAddresses => 'Indirizzi salvati';

  @override
  String get addressesLoading => 'Caricamento indirizzi salvati';

  @override
  String get addressesSubtitle => 'Sono mostrati solo i tuoi dati. L’idoneità alla consegna è verificata dal servizio.';

  @override
  String get addAddress => 'Aggiungi indirizzo';

  @override
  String get addressesUpdated => 'Indirizzi aggiornati';

  @override
  String get noSavedAddresses => 'Nessun indirizzo salvato';

  @override
  String get noSavedAddressesMessage => 'Aggiungi un indirizzo per trovarlo rapidamente nei prossimi ordini.';

  @override
  String get addFirstAddress => 'Aggiungi il primo indirizzo';

  @override
  String get defaultLabel => 'Predefinito';

  @override
  String get archive => 'Archivia';

  @override
  String get archiveAddressQuestion => 'Archivia indirizzo?';

  @override
  String get archiveDefaultWarning => 'Scegli un altro indirizzo predefinito prima di archiviarlo.';

  @override
  String get archiveAddressWarning => 'L’indirizzo sarà archiviato, non eliminato definitivamente.';

  @override
  String get editAddress => 'Modifica indirizzo';

  @override
  String get newAddress => 'Nuovo indirizzo';

  @override
  String get checkFields => 'Controlla i campi';

  @override
  String get addressLabel => 'Etichetta';

  @override
  String get recipientName => 'Nome destinatario';

  @override
  String get streetAddress => 'Via e numero';

  @override
  String get city => 'Città';

  @override
  String get province => 'Provincia';

  @override
  String get postalCode => 'CAP';

  @override
  String get optionalNotes => 'Note facoltative';

  @override
  String get setAsDefault => 'Imposta come predefinito';

  @override
  String get saveAddress => 'Salva indirizzo';

  @override
  String get security => 'Sicurezza';

  @override
  String get securityPreferences => 'Sicurezza e preferenze';

  @override
  String get securityLoading => 'Caricamento preferenze e sessioni';

  @override
  String get securitySubtitle => 'Preferenze versionate, avvisi essenziali e controllo sessioni.';

  @override
  String get refreshSession => 'Aggiorna sessione';

  @override
  String get settingsUpdated => 'Impostazioni aggiornate';

  @override
  String get communications => 'Comunicazioni';

  @override
  String get communicationsSubtitle => 'Le comunicazioni facoltative sono disattivate per impostazione predefinita.';

  @override
  String get marketingEmails => 'Email promozionali facoltative';

  @override
  String get marketingEmailsHelp => 'Questa preferenza non modifica le comunicazioni essenziali.';

  @override
  String get securityAlerts => 'Avvisi di sicurezza essenziali';

  @override
  String get securityAlertsHelp => 'Attivi e separati dalle preferenze promozionali.';

  @override
  String get enabled => 'Attivi';

  @override
  String get signInMethods => 'Metodi di accesso';

  @override
  String get signInMethodsHelp => 'Gestisci email/password e i provider configurati.';

  @override
  String get emailPassword => 'Email e password';

  @override
  String get currentMethod => 'Metodo corrente';

  @override
  String get additionalProviders => 'Provider aggiuntivi';

  @override
  String get noProviders => 'Nessun provider configurato';

  @override
  String get configured => 'Configurato';

  @override
  String get activeSessions => 'Sessioni attive';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioni',
      one: '1 sessione',
    );
    return '$_temp0';
  }

  @override
  String get unnamedDevice => 'Dispositivo non nominato';

  @override
  String get current => 'Corrente';

  @override
  String lastUsed(String date) {
    return 'Ultimo uso $date';
  }

  @override
  String get revokeSession => 'Revoca sessione';

  @override
  String get privacySubtitle => 'Esportazione e cancellazione mostrano lo stato autorevole senza promettere tempi.';

  @override
  String get reauthenticationRequired => 'Riautenticazione richiesta';

  @override
  String get reauthenticationHelp => 'Conferma con la password. L’app non conserva password o prova.';

  @override
  String get requestExport => 'Richiedi esportazione';

  @override
  String get requestDeletion => 'Avvia richiesta cancellazione';

  @override
  String get noRequests => 'Nessuna richiesta';

  @override
  String get noRequestsMessage => 'Le richieste inviate appariranno qui con lo stato aggiornato.';

  @override
  String get requestStatus => 'Stato richieste';

  @override
  String get export => 'Esportazione';

  @override
  String get deletion => 'Cancellazione';

  @override
  String get requestInformation => 'Informazioni sulla richiesta';

  @override
  String get requestInformationHelp => 'Obblighi di conservazione e azioni disponibili provengono dalla risposta del servizio.';

  @override
  String get signOut => 'Esci';

  @override
  String get sessionRequired => 'Sessione richiesta';

  @override
  String get signInToContinue => 'Accedi per continuare';

  @override
  String get protectedRouteNotice => 'Le destinazioni protette non conservano dati quando la sessione è assente.';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get errorTitle => 'Impossibile completare l’operazione';

  @override
  String referenceCode(String code) {
    return 'Riferimento: $code';
  }

  @override
  String get tapToContinue => 'Tocca per continuare';

  @override
  String get timing => 'Orario';

  @override
  String get asSoonAsPossible => 'Il prima possibile';

  @override
  String get scheduleOrder => 'Programma';

  @override
  String get chooseDate => 'Scegli data';

  @override
  String get scheduledTime => 'Orario programmato';

  @override
  String get noTimeSlots => 'Nessun orario disponibile per questa data. Scegli un’altra data.';

  @override
  String get closedNow => 'La Favola è chiusa in questo momento. Scegli un orario disponibile.';

  @override
  String leadTime(int minutes) {
    return 'Stima attuale: circa $minutes minuti';
  }

  @override
  String get nameValidation => 'Il nome è obbligatorio, deve contenere al massimo 100 caratteri e non può includere caratteri di controllo.';

  @override
  String get phoneValidation => 'Inserisci un numero di telefono internazionale valido.';

  @override
  String get passwordRangeError => 'La password deve contenere da 8 a 72 caratteri.';

  @override
  String get passwordMismatchError => 'Le password non coincidono.';

  @override
  String get verificationCodeMinError => 'Il codice deve contenere almeno 8 caratteri.';

  @override
  String get emailVerifiedSuccess => 'Email verificata. Ora puoi accedere.';

  @override
  String get resendVerificationAccepted => 'La richiesta di nuovo invio è stata accettata senza rivelare lo stato dell’account.';

  @override
  String get recoveryAccepted => 'Richiesta ricevuta. Il risultato resta neutrale per ogni indirizzo email.';

  @override
  String get resetTokenMinError => 'Il codice di ripristino deve contenere almeno 8 caratteri.';

  @override
  String get resetValidationError => 'Controlla il codice di ripristino e la nuova password (almeno 8 caratteri).';

  @override
  String get passwordResetSuccess => 'Password aggiornata. Le altre sessioni sono state revocate.';

  @override
  String profileSavedVersion(String version) {
    return 'Profilo salvato alla versione $version.';
  }

  @override
  String get addressCreated => 'Indirizzo creato.';

  @override
  String get addressUpdated => 'Indirizzo aggiornato.';

  @override
  String get addressArchived => 'Indirizzo archiviato.';

  @override
  String preferencesSavedVersion(String version) {
    return 'Preferenze salvate alla versione $version.';
  }

  @override
  String get sessionRevoked => 'Sessione revocata.';

  @override
  String get privacyPasswordRequired => 'Inserisci la password per confermare la richiesta.';

  @override
  String get privacyStateRequested => 'Richiesta';

  @override
  String get privacyStateInReview => 'In revisione';

  @override
  String get privacyStateCompleted => 'Completata';

  @override
  String get privacyStateCancelled => 'Annullata';

  @override
  String get privacyStateRetention => 'Conservazione richiesta';

  @override
  String get reauthUnavailable => 'Riautenticazione non disponibile';

  @override
  String get reauthUnavailableMessage => 'Aggiorna il contratto del servizio prima di inviare richieste privacy.';

  @override
  String get signInProtectedRoute => 'Accedi per aprire questa destinazione protetta.';

  @override
  String get signInAgain => 'Accedi di nuovo per continuare.';

  @override
  String get noActionAvailable => 'Nessuna azione disponibile';

  @override
  String get addressLabelRequired => 'Inserisci un’etichetta per l’indirizzo.';

  @override
  String get recipientRequired => 'Inserisci il nome del destinatario.';

  @override
  String get streetRequired => 'Inserisci via e numero.';

  @override
  String get cityRequired => 'Inserisci la città.';

  @override
  String get provinceRequired => 'Inserisci la provincia.';

  @override
  String get postalCodeValidation => 'Il CAP deve contenere cinque cifre.';

  @override
  String get notesLengthValidation => 'Le note non possono superare 500 caratteri.';

  @override
  String get completeRequiredFields => 'Completa i campi indicati.';

  @override
  String get sessionRefreshed => 'Sessione aggiornata.';

  @override
  String get lastMethodProtection => 'Protezione ultimo metodo di accesso';

  @override
  String get lastMethodProtectionMessage => 'L’ultimo metodo di accesso non può essere scollegato.';

  @override
  String get oneTimeCodeHelp => 'Sono supportati incolla e completamento automatico del codice monouso.';
}

/// The translations for Italian, as used in Italy (`it_IT`).
class AppLocalizationsItIt extends AppLocalizationsIt {
  AppLocalizationsItIt(): super('it_IT');

  @override
  String get appTitle => 'La Favola';

  @override
  String get language => 'Lingua';

  @override
  String get english => 'Inglese';

  @override
  String get italian => 'Italiano';

  @override
  String get publicMenu => 'Menu pubblico';

  @override
  String get signIn => 'Accedi';

  @override
  String get menu => 'Menu';

  @override
  String get orders => 'Ordini';

  @override
  String get profile => 'Profilo';

  @override
  String get preferences => 'Preferenze';

  @override
  String get privacy => 'Privacy';

  @override
  String get contentNotFound => 'Contenuto non trovato';

  @override
  String get invalidMenuItem => 'Questa voce del menu non è più disponibile.';

  @override
  String get createYourPizza => 'Crea la tua pizza';

  @override
  String get createPizzaWithLivePricing => 'Crea la tua pizza con prezzo in tempo reale';

  @override
  String get yourOrder => 'Il tuo ordine';

  @override
  String get closeCheckout => 'Chiudi il riepilogo';

  @override
  String get quantity => 'Quantità';

  @override
  String get fulfilment => 'Modalità di consegna';

  @override
  String get delivery => 'Consegna';

  @override
  String get pickup => 'Ritiro';

  @override
  String get deliveryAddress => 'Indirizzo di consegna';

  @override
  String get missingDeliveryAddress => 'Aggiungi un indirizzo salvato nel Profilo prima di richiedere la consegna.';

  @override
  String get promoCode => 'Codice promozionale';

  @override
  String get apply => 'Applica';

  @override
  String get payment => 'Pagamento';

  @override
  String get cashOnDelivery => 'Contanti alla consegna';

  @override
  String get cashOnPickup => 'Contanti al ritiro';

  @override
  String get payOnHandover => 'Paga quando ricevi l’ordine.';

  @override
  String get onlineCard => 'Carta online';

  @override
  String get onlineCardUnavailable => 'Non ancora attiva. Non vengono raccolti dati della carta.';

  @override
  String get placeOrder => 'Invia l’ordine con totale aggiornato';

  @override
  String get orderReceived => 'Ordine ricevuto';

  @override
  String reference(String reference) {
    return 'Riferimento: $reference';
  }

  @override
  String total(String total) {
    return 'Totale: $total';
  }

  @override
  String get orderVisibleToTeam => 'Il team ordini di La Favola può ora vedere questo ordine.';

  @override
  String get backToMenu => 'Torna al menu';

  @override
  String get trackOrder => 'Segui l’ordine';

  @override
  String get livePriceNotice => 'Totale finale, imposte, promozioni e disponibilità vengono ricalcolati in sicurezza prima della conferma.';

  @override
  String get size => 'Formato';

  @override
  String get required => 'Obbligatorio';

  @override
  String chooseUpTo(int count) {
    return 'Scegli fino a $count';
  }

  @override
  String get loading => 'Caricamento…';

  @override
  String get retry => 'Riprova';

  @override
  String get noMenuItems => 'Nessuna voce del menu è disponibile in questo momento.';

  @override
  String get searchMenu => 'Cerca nel menu';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get orderTracking => 'Stato dell’ordine';

  @override
  String get estimatedReady => 'Orario di preparazione stimato';

  @override
  String get estimatedArrival => 'Arrivo stimato';

  @override
  String remainingMinutes(int minutes) {
    return 'Circa $minutes min rimanenti';
  }

  @override
  String get dueNow => 'In arrivo';

  @override
  String lastUpdated(String time) {
    return 'Aggiornato alle $time';
  }

  @override
  String get liveUpdates => 'Aggiornamenti in tempo reale';

  @override
  String get reconnecting => 'Riconnessione…';

  @override
  String get offlineTracking => 'Gli aggiornamenti in tempo reale non sono disponibili. L’app continuerà a riprovare in sicurezza.';

  @override
  String get cancelOrder => 'Annulla ordine';

  @override
  String get cancelReason => 'Motivo dell’annullamento';

  @override
  String get confirmCancellation => 'Conferma annullamento';

  @override
  String get keepOrder => 'Mantieni ordine';

  @override
  String get orderReceipt => 'Ricevuta ordine';

  @override
  String get receiptNotice => 'Questa è una ricevuta dell’ordine, non una fattura fiscale. Il documento fiscale viene emesso dal fornitore configurato quando applicabile.';

  @override
  String get subtotal => 'Subtotale';

  @override
  String get options => 'Opzioni';

  @override
  String get deliveryFee => 'Costo di consegna';

  @override
  String get discount => 'Sconto';

  @override
  String get tax => 'Imposte';

  @override
  String get grandTotal => 'Totale';

  @override
  String get statusPendingPayment => 'In attesa di pagamento';

  @override
  String get statusPlaced => 'Ordine inviato';

  @override
  String get statusAccepted => 'Accettato';

  @override
  String get statusPreparing => 'In preparazione';

  @override
  String get statusBaking => 'In forno';

  @override
  String get statusPacking => 'In confezionamento';

  @override
  String get statusReady => 'Pronto';

  @override
  String get statusDriverAssigned => 'Fattorino assegnato';

  @override
  String get statusOutForDelivery => 'In consegna';

  @override
  String get statusDelivered => 'Consegnato';

  @override
  String get statusClosed => 'Completato';

  @override
  String get statusCancelled => 'Annullato';

  @override
  String get statusRejected => 'Rifiutato';

  @override
  String get bresciaItaly => 'BRESCIA · ITALIA';

  @override
  String get menuHeroTitle => 'Il menu,\nindimenticabile.';

  @override
  String liveCatalogue(String version) {
    return 'Menu live · catalogo $version';
  }

  @override
  String get menuCategories => 'Categorie del menu';

  @override
  String get discoverFavourites => 'Scopri i preferiti di oggi';

  @override
  String get clearSearch => 'Cancella ricerca';

  @override
  String menuResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prodotti',
      one: '1 prodotto',
      zero: 'Nessun prodotto',
    );
    return '$_temp0';
  }

  @override
  String get madeWithCare => 'Preparato con cura';

  @override
  String get detailsUnavailable => 'I dettagli non sono disponibili per questo prodotto.';

  @override
  String get dietaryAllergenInfo => 'Informazioni alimentari e allergeni';

  @override
  String get customizePizza => 'Personalizza la tua pizza';

  @override
  String get addToOrder => 'Aggiungi all’ordine';

  @override
  String get builderIntro => 'Creala come vuoi. Il prezzo si aggiorna in tempo reale.';

  @override
  String get chooseOne => 'Scegli una';

  @override
  String get checkingPrice => 'Verifica del prezzo in corso…';

  @override
  String get livePriceUnavailable => 'Il prezzo live non è disponibile.';

  @override
  String get items => 'Prodotti';

  @override
  String get weCouldNotLoadMenu => 'Impossibile caricare il menu live';

  @override
  String get menuUpdating => 'Il menu è in aggiornamento';

  @override
  String get noLiveCategories => 'Al momento non ci sono categorie disponibili.';

  @override
  String get noSearchResults => 'Nessun prodotto corrisponde alla ricerca.';

  @override
  String get orderHistory => 'I tuoi ordini';

  @override
  String get allOrders => 'Tutti';

  @override
  String get active => 'Attivi';

  @override
  String get completed => 'Completati';

  @override
  String get noOrders => 'I tuoi ordini appariranno qui.';

  @override
  String get timeline => 'Cronologia';

  @override
  String get orderReceivedTimeline => 'L’ordine è stato ricevuto.';

  @override
  String get requestCancellation => 'Richiedi annullamento';

  @override
  String get sendingRequest => 'Invio richiesta…';

  @override
  String get sendRequest => 'Invia richiesta';

  @override
  String get estimatePending => 'Stima in attesa';

  @override
  String get finalisingNow => 'In completamento';

  @override
  String countdown(int minutes, String seconds) {
    return '$minutes:$seconds rimanenti';
  }

  @override
  String lateEstimate(int minutes) {
    return '$minutes min oltre la stima';
  }

  @override
  String get estimatedCollectionReady => 'Ritiro stimato';

  @override
  String get estimatedKitchenReady => 'Preparazione stimata';

  @override
  String get viewReceipt => 'Visualizza ricevuta';

  @override
  String get receiptLoading => 'Caricamento ricevuta…';

  @override
  String get receiptFailed => 'Impossibile caricare la ricevuta.';

  @override
  String issuedAt(String date) {
    return 'Emessa il $date';
  }

  @override
  String get unitPrice => 'Prezzo unitario';

  @override
  String get optionCharges => 'Supplementi';

  @override
  String get statusPickedUp => 'Ritirato';

  @override
  String get statusServed => 'Servito';

  @override
  String get statusDeliveryFailed => 'La consegna richiede attenzione';

  @override
  String get waitingConfirmation => 'In attesa di conferma dal ristorante';

  @override
  String get orderConfirmed => 'Ordine confermato';

  @override
  String get orderBeingPrepared => 'Il tuo ordine è in preparazione';

  @override
  String get pizzaInOven => 'La tua pizza è in forno';

  @override
  String get packingOrder => 'Confezionamento dell’ordine';

  @override
  String get readyForRider => 'Pronto, in attesa del rider';

  @override
  String get readyForPickup => 'Pronto per il ritiro';

  @override
  String get riderOnWay => 'Il rider è in arrivo';

  @override
  String tableLabel(String table) {
    return 'Tavolo $table';
  }

  @override
  String selectionRequired(int count) {
    return 'Seleziona almeno $count';
  }

  @override
  String selectionTooMany(int count) {
    return 'Seleziona al massimo $count';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signInSubtitle => 'Accedi per gestire il tuo account oppure consulta il menu pubblico.';

  @override
  String get signingIn => 'Accesso in corso…';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get otherSignInMethods => 'Altri metodi di accesso';

  @override
  String get continueGoogle => 'Continua con Google';

  @override
  String get continueApple => 'Continua con Apple';

  @override
  String get continueGuest => 'Continua come ospite';

  @override
  String get guestSubtitle => 'Esplora il menu completo di La Favola senza accedere';

  @override
  String get createAccount => 'Crea un account';

  @override
  String get haveVerificationCode => 'Hai già un codice di verifica?';

  @override
  String get publicAccountNotice => 'Il menu è pubblico. Profilo, indirizzi e privacy richiedono un account.';

  @override
  String get sessionUnavailable => 'Sessione non disponibile';

  @override
  String get validEmailError => 'Inserisci un indirizzo email valido.';

  @override
  String get passwordMinError => 'La password deve contenere almeno 8 caratteri.';

  @override
  String get registration => 'Registrazione';

  @override
  String get registrationSubtitle => 'Crea il tuo account per salvare preferiti e ordini.';

  @override
  String get name => 'Nome';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get creatingAccount => 'Creazione in corso…';

  @override
  String get goToSignIn => 'Vai all\'accesso';

  @override
  String get registrationCompleted => 'Registrazione completata';

  @override
  String get registrationCompletedMessage => 'Il tuo account è pronto. Accedi con email e password.';

  @override
  String get fixFields => 'Correggi i campi';

  @override
  String get passwordRequirements => 'Da 8 a 72 caratteri. Incolla e gestori di password sono supportati.';

  @override
  String get termsTitle => 'Informative e condizioni';

  @override
  String get termsMessage => 'La registrazione non attiva comunicazioni promozionali. Le informative applicabili devono essere disponibili prima della distribuzione.';

  @override
  String get verifyEmail => 'Verifica email';

  @override
  String get verifyEmailSubtitle => 'Inserisci il codice monouso ricevuto via email.';

  @override
  String get verificationCode => 'Codice di verifica';

  @override
  String get verifying => 'Verifica in corso…';

  @override
  String get verify => 'Verifica';

  @override
  String get resendEmail => 'Email per nuovo invio';

  @override
  String get resend => 'Invia di nuovo';

  @override
  String get verificationResult => 'Risultato verifica';

  @override
  String get passwordRecovery => 'Recupero password';

  @override
  String get recoveryTitle => 'Recupero e reimpostazione';

  @override
  String get recoverySubtitle => 'Richiedi un link oppure completa la reimpostazione con il codice ricevuto.';

  @override
  String get requestRecovery => 'Richiedi recupero';

  @override
  String get resetCode => 'Codice di reimpostazione';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get updatePassword => 'Aggiorna password';

  @override
  String get operationCompleted => 'Operazione completata';

  @override
  String get requestRecoveryStep => '1. Richiedi recupero';

  @override
  String get requestRecoveryHelp => 'La risposta non conferma se l’account esiste.';

  @override
  String get resetPasswordStep => '2. Imposta nuova password';

  @override
  String get resetPasswordHelp => 'I codici monouso scaduti o già usati non modificano l’account.';

  @override
  String providerSignIn(String provider) {
    return 'Accesso con $provider';
  }

  @override
  String get providerSubtitle => 'Il collegamento si completa soltanto dopo un ritorno verificato dal provider.';

  @override
  String get providerNotConfigured => 'Metodo non configurato';

  @override
  String get providerNotConfiguredMessage => 'Questo metodo di accesso non è disponibile in questa configurazione.';

  @override
  String get startSecureSignIn => 'Avvia accesso protetto';

  @override
  String get startSecureSignInHelp => 'Nessun account viene collegato finché il ritorno non è verificato.';

  @override
  String get preparing => 'Preparazione…';

  @override
  String get continueAction => 'Continua';

  @override
  String get waitingProvider => 'In attesa del provider';

  @override
  String get waitingProviderMessage => 'Completa l’accesso nella finestra protetta. Puoi tornare indietro senza modificare l’account.';

  @override
  String get profileLoading => 'Caricamento profilo cliente';

  @override
  String get profileData => 'Dati del profilo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get displayName => 'Nome visualizzato';

  @override
  String get verifiedEmail => 'Email verificata';

  @override
  String get optionalPhone => 'Telefono (facoltativo)';

  @override
  String get saving => 'Salvataggio…';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get edit => 'Modifica';

  @override
  String get accountSummary => 'Riepilogo account';

  @override
  String versionValue(String version) {
    return 'Versione $version';
  }

  @override
  String get currentLanguage => 'Lingua: Italiano (Italia)';

  @override
  String get emailReadOnlyNotice => 'Il cambio email non è incluso nel salvataggio generico del profilo.';

  @override
  String get profileSubtitle => 'Dati propri e versionati. L’email resta un’identità di sola lettura.';

  @override
  String get profileUpdated => 'Profilo aggiornato';

  @override
  String get addresses => 'Indirizzi';

  @override
  String get savedAddresses => 'Indirizzi salvati';

  @override
  String get addressesLoading => 'Caricamento indirizzi salvati';

  @override
  String get addressesSubtitle => 'Sono mostrati solo i tuoi dati. L’idoneità alla consegna è verificata dal servizio.';

  @override
  String get addAddress => 'Aggiungi indirizzo';

  @override
  String get addressesUpdated => 'Indirizzi aggiornati';

  @override
  String get noSavedAddresses => 'Nessun indirizzo salvato';

  @override
  String get noSavedAddressesMessage => 'Aggiungi un indirizzo per trovarlo rapidamente nei prossimi ordini.';

  @override
  String get addFirstAddress => 'Aggiungi il primo indirizzo';

  @override
  String get defaultLabel => 'Predefinito';

  @override
  String get archive => 'Archivia';

  @override
  String get archiveAddressQuestion => 'Archivia indirizzo?';

  @override
  String get archiveDefaultWarning => 'Scegli un altro indirizzo predefinito prima di archiviarlo.';

  @override
  String get archiveAddressWarning => 'L’indirizzo sarà archiviato, non eliminato definitivamente.';

  @override
  String get editAddress => 'Modifica indirizzo';

  @override
  String get newAddress => 'Nuovo indirizzo';

  @override
  String get checkFields => 'Controlla i campi';

  @override
  String get addressLabel => 'Etichetta';

  @override
  String get recipientName => 'Nome destinatario';

  @override
  String get streetAddress => 'Via e numero';

  @override
  String get city => 'Città';

  @override
  String get province => 'Provincia';

  @override
  String get postalCode => 'CAP';

  @override
  String get optionalNotes => 'Note facoltative';

  @override
  String get setAsDefault => 'Imposta come predefinito';

  @override
  String get saveAddress => 'Salva indirizzo';

  @override
  String get security => 'Sicurezza';

  @override
  String get securityPreferences => 'Sicurezza e preferenze';

  @override
  String get securityLoading => 'Caricamento preferenze e sessioni';

  @override
  String get securitySubtitle => 'Preferenze versionate, avvisi essenziali e controllo sessioni.';

  @override
  String get refreshSession => 'Aggiorna sessione';

  @override
  String get settingsUpdated => 'Impostazioni aggiornate';

  @override
  String get communications => 'Comunicazioni';

  @override
  String get communicationsSubtitle => 'Le comunicazioni facoltative sono disattivate per impostazione predefinita.';

  @override
  String get marketingEmails => 'Email promozionali facoltative';

  @override
  String get marketingEmailsHelp => 'Questa preferenza non modifica le comunicazioni essenziali.';

  @override
  String get securityAlerts => 'Avvisi di sicurezza essenziali';

  @override
  String get securityAlertsHelp => 'Attivi e separati dalle preferenze promozionali.';

  @override
  String get enabled => 'Attivi';

  @override
  String get signInMethods => 'Metodi di accesso';

  @override
  String get signInMethodsHelp => 'Gestisci email/password e i provider configurati.';

  @override
  String get emailPassword => 'Email e password';

  @override
  String get currentMethod => 'Metodo corrente';

  @override
  String get additionalProviders => 'Provider aggiuntivi';

  @override
  String get noProviders => 'Nessun provider configurato';

  @override
  String get configured => 'Configurato';

  @override
  String get activeSessions => 'Sessioni attive';

  @override
  String sessionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessioni',
      one: '1 sessione',
    );
    return '$_temp0';
  }

  @override
  String get unnamedDevice => 'Dispositivo non nominato';

  @override
  String get current => 'Corrente';

  @override
  String lastUsed(String date) {
    return 'Ultimo uso $date';
  }

  @override
  String get revokeSession => 'Revoca sessione';

  @override
  String get privacySubtitle => 'Esportazione e cancellazione mostrano lo stato autorevole senza promettere tempi.';

  @override
  String get reauthenticationRequired => 'Riautenticazione richiesta';

  @override
  String get reauthenticationHelp => 'Conferma con la password. L’app non conserva password o prova.';

  @override
  String get requestExport => 'Richiedi esportazione';

  @override
  String get requestDeletion => 'Avvia richiesta cancellazione';

  @override
  String get noRequests => 'Nessuna richiesta';

  @override
  String get noRequestsMessage => 'Le richieste inviate appariranno qui con lo stato aggiornato.';

  @override
  String get requestStatus => 'Stato richieste';

  @override
  String get export => 'Esportazione';

  @override
  String get deletion => 'Cancellazione';

  @override
  String get requestInformation => 'Informazioni sulla richiesta';

  @override
  String get requestInformationHelp => 'Obblighi di conservazione e azioni disponibili provengono dalla risposta del servizio.';

  @override
  String get signOut => 'Esci';

  @override
  String get sessionRequired => 'Sessione richiesta';

  @override
  String get signInToContinue => 'Accedi per continuare';

  @override
  String get protectedRouteNotice => 'Le destinazioni protette non conservano dati quando la sessione è assente.';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get errorTitle => 'Impossibile completare l’operazione';

  @override
  String referenceCode(String code) {
    return 'Riferimento: $code';
  }

  @override
  String get tapToContinue => 'Tocca per continuare';

  @override
  String get timing => 'Orario';

  @override
  String get asSoonAsPossible => 'Il prima possibile';

  @override
  String get scheduleOrder => 'Programma';

  @override
  String get chooseDate => 'Scegli data';

  @override
  String get scheduledTime => 'Orario programmato';

  @override
  String get noTimeSlots => 'Nessun orario disponibile per questa data. Scegli un’altra data.';

  @override
  String get closedNow => 'La Favola è chiusa in questo momento. Scegli un orario disponibile.';

  @override
  String leadTime(int minutes) {
    return 'Stima attuale: circa $minutes minuti';
  }

  @override
  String get nameValidation => 'Il nome è obbligatorio, deve contenere al massimo 100 caratteri e non può includere caratteri di controllo.';

  @override
  String get phoneValidation => 'Inserisci un numero di telefono internazionale valido.';

  @override
  String get passwordRangeError => 'La password deve contenere da 8 a 72 caratteri.';

  @override
  String get passwordMismatchError => 'Le password non coincidono.';

  @override
  String get verificationCodeMinError => 'Il codice deve contenere almeno 8 caratteri.';

  @override
  String get emailVerifiedSuccess => 'Email verificata. Ora puoi accedere.';

  @override
  String get resendVerificationAccepted => 'La richiesta di nuovo invio è stata accettata senza rivelare lo stato dell’account.';

  @override
  String get recoveryAccepted => 'Richiesta ricevuta. Il risultato resta neutrale per ogni indirizzo email.';

  @override
  String get resetTokenMinError => 'Il codice di ripristino deve contenere almeno 8 caratteri.';

  @override
  String get resetValidationError => 'Controlla il codice di ripristino e la nuova password (almeno 8 caratteri).';

  @override
  String get passwordResetSuccess => 'Password aggiornata. Le altre sessioni sono state revocate.';

  @override
  String profileSavedVersion(String version) {
    return 'Profilo salvato alla versione $version.';
  }

  @override
  String get addressCreated => 'Indirizzo creato.';

  @override
  String get addressUpdated => 'Indirizzo aggiornato.';

  @override
  String get addressArchived => 'Indirizzo archiviato.';

  @override
  String preferencesSavedVersion(String version) {
    return 'Preferenze salvate alla versione $version.';
  }

  @override
  String get sessionRevoked => 'Sessione revocata.';

  @override
  String get privacyPasswordRequired => 'Inserisci la password per confermare la richiesta.';

  @override
  String get privacyStateRequested => 'Richiesta';

  @override
  String get privacyStateInReview => 'In revisione';

  @override
  String get privacyStateCompleted => 'Completata';

  @override
  String get privacyStateCancelled => 'Annullata';

  @override
  String get privacyStateRetention => 'Conservazione richiesta';

  @override
  String get reauthUnavailable => 'Riautenticazione non disponibile';

  @override
  String get reauthUnavailableMessage => 'Aggiorna il contratto del servizio prima di inviare richieste privacy.';

  @override
  String get signInProtectedRoute => 'Accedi per aprire questa destinazione protetta.';

  @override
  String get signInAgain => 'Accedi di nuovo per continuare.';

  @override
  String get noActionAvailable => 'Nessuna azione disponibile';

  @override
  String get addressLabelRequired => 'Inserisci un’etichetta per l’indirizzo.';

  @override
  String get recipientRequired => 'Inserisci il nome del destinatario.';

  @override
  String get streetRequired => 'Inserisci via e numero.';

  @override
  String get cityRequired => 'Inserisci la città.';

  @override
  String get provinceRequired => 'Inserisci la provincia.';

  @override
  String get postalCodeValidation => 'Il CAP deve contenere cinque cifre.';

  @override
  String get notesLengthValidation => 'Le note non possono superare 500 caratteri.';

  @override
  String get completeRequiredFields => 'Completa i campi indicati.';

  @override
  String get sessionRefreshed => 'Sessione aggiornata.';

  @override
  String get lastMethodProtection => 'Protezione ultimo metodo di accesso';

  @override
  String get lastMethodProtectionMessage => 'L’ultimo metodo di accesso non può essere scollegato.';

  @override
  String get oneTimeCodeHelp => 'Sono supportati incolla e completamento automatico del codice monouso.';
}
