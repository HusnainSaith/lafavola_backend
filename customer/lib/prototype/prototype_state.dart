enum PrototypeScreen { homeMenu, pizzaBuilder }

enum MenuPrototypeState {
  ready,
  loading,
  empty,
  noResults,
  itemUnavailable,
  stale,
  offline,
  favoriteAuthRequired,
}

enum BuilderPrototypeState {
  ready,
  requiredError,
  minMax,
  unavailable,
  refreshPending,
  refreshError,
  versionPriceChange,
  success,
}

extension MenuPrototypeStateLabel on MenuPrototypeState {
  String get label => switch (this) {
    MenuPrototypeState.ready => 'Menu pronto — prototipo',
    MenuPrototypeState.loading => 'Caricamento',
    MenuPrototypeState.empty => 'Catalogo vuoto',
    MenuPrototypeState.noResults => 'Nessun risultato',
    MenuPrototypeState.itemUnavailable => 'Voce non disponibile',
    MenuPrototypeState.stale => 'Dati non aggiornati',
    MenuPrototypeState.offline => 'Connessione assente',
    MenuPrototypeState.favoriteAuthRequired =>
      'Preferito richiede autenticazione',
  };
}

extension BuilderPrototypeStateLabel on BuilderPrototypeState {
  String get label => switch (this) {
    BuilderPrototypeState.ready => 'Configurazione iniziale',
    BuilderPrototypeState.requiredError => 'Scelta richiesta mancante',
    BuilderPrototypeState.minMax => 'Limite minimo / massimo',
    BuilderPrototypeState.unavailable => 'Opzione non disponibile',
    BuilderPrototypeState.refreshPending => 'Aggiornamento in corso',
    BuilderPrototypeState.refreshError => 'Aggiornamento non riuscito',
    BuilderPrototypeState.versionPriceChange => 'Versione / prezzo cambiato',
    BuilderPrototypeState.success => 'Risultato visivo persistente',
  };
}
