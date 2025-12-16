<h1>
    <a href="readme-fr.md">
        <img src="https://img.icons8.com/material-rounded/48/ffffff/chevron-left.png" width="30" alt="Retour"/>
    </a>
    <a href="technical-specification-fr.md"><img src="https://img.icons8.com/color/48/000000/france-circular.png" width="30" alt="Français"/></a>
    <a href="technical-specification.md"><img src="https://img.icons8.com/color/48/000000/great-britain-circular.png" width="30" alt="English"/></a> 
    NexaCore - Cahier des Charges Technique <br>
</h1>

## Sommaire
- [Sommaire](#sommaire)
- [Architecture Générale](#architecture-générale)
  - [Architecture Logiciel](#architecture-logiciel)
  - [Architecture système](#architecture-système)
- [Contraintes Technologiques](#contraintes-technologiques)
  - [Technilogies](#technilogies)
  - [Performances](#performances)
  - [Sécurités](#sécurités)
---

## Architecture Générale
**Application**

Contient les services (User, Ticket, Comment, Notification, Log) et MediatR pour le pattern CQRS.
Orchestre les cas d"usage et coordonne le domaine.

**Domaine**

Regroupe les entités métier, règles de gestion et interfaces de repository.
Totalement indépendant de la technologie.
C"est le cœur fonctionnel du projet.

**Infrastructure**

Implémente les repositories, DbContext EF Core et l"accès SQL.
Expose la persistance et les opérations techniques définies par le domaine.

**Sécurité**

ASP.NET Identity + JWT.
Protège les API, valide l"accès et applique les règles d"authentification/autorisation.

**Persistance**

Base SQL Server utilisée via l"infrastructure.

### Architecture Logiciel
L'architecture logicielle de NexaCore est divisée en plusieurs couches : Présentation, Application, Domaine, Infrastructure, et Sécurité.

  [![Architecture-logiciel.svg](/Documents/Graph/fr/architecture-logiciel.svg)](/Documents/Graph/fr/architecture-logiciel.svg)

### Architecture système
L'architecture système montre les interactions entre les différentes couches et composants.
  [![Architecture-systeme.svg](/Documents/Graph/fr/architecture-system.svg)](/Documents/Graph/fr/architecture-system.svg)

## Contraintes Technologiques
### Technilogies
- **.NET + Blazor WebAssembly** : interface moderne, compilation WebAssembly, forte interactivité.

- **ASP.NET Core** : API REST, filtres, middlewares, validation, pipeline HTTP performant.

- **Entity Framework Core + SQL Server** : ORM robuste, migrations, requêtes efficaces.

- **MediatR (CQRS)** : séparation des commandes et requêtes, logique propre et testable.

- **JWT + Identity** : authentification stateless, gestion complète des utilisateurs.

### Performances
- Minimisation des allers-retours client–serveur (caching, state management).

- Requêtes optimisées avec EF Core (projections, includes ciblés, pagination).

- Architecture en couches limitant les dépendances inutiles.

- Charge maîtrisée grâce au découpage Command/Query et à la logique métier isolée.
- 
### Sécurités
- Authentification par **JWT** et gestion des sessions stateless.

- Autorisation fine via Identity + rôles.

- Validation systématique des entrées (filtres, DTO).

- Journalisation des actions sensibles (audit log).

- Cloisonnement clair entre couches pour réduire la surface d'attaque.