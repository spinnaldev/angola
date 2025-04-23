# Documentation API - Projet Angola

Cette documentation décrit les endpoints de l'API RESTful pour l'application mobile de recherche, d'évaluation et de notation de prestataires de services en Angola.

## Authentification

L'API utilise JWT (JSON Web Tokens) pour l'authentification. Pour accéder aux endpoints protégés, vous devez inclure le token JWT dans l'en-tête de vos requêtes:

```
Authorization: Bearer <votre_token_jwt>
```

### Endpoints d'authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/register/` | Inscription d'un nouvel utilisateur |
| POST | `/api/auth/token/` | Obtention d'un token JWT |
| POST | `/api/auth/token/refresh/` | Rafraîchissement d'un token JWT |

#### Inscription (`/api/auth/register/`)

Permet d'inscrire un nouvel utilisateur dans le système.

**Payload:**
```json
{
  "username": "johndoe",
  "password": "mot_de_passe_securise",
  "password2": "mot_de_passe_securise",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+244 923456789",
  "role": "client",
  "location": "Luanda, Angola"
}
```

**Valeurs possibles pour `role`:**
- `client`: Pour les utilisateurs qui recherchent des services
- `provider`: Pour les prestataires de services

#### Obtention d'un token (`/api/auth/token/`)

**Payload:**
```json
{
  "username": "johndoe",
  "password": "mot_de_passe_securise"
}
```

**Réponse:**
```json
{
  "access": "votre_token_jwt",
  "refresh": "votre_token_refresh"
}
```

#### Rafraîchissement d'un token (`/api/auth/token/refresh/`)

**Payload:**
```json
{
  "refresh": "votre_token_refresh"
}
```

**Réponse:**
```json
{
  "access": "nouveau_token_jwt"
}
```

## Utilisateurs

### Endpoints utilisateurs

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/users/` | Liste des utilisateurs (admin uniquement) |
| GET | `/api/users/{id}/` | Détails d'un utilisateur |
| PUT | `/api/users/{id}/` | Mise à jour d'un utilisateur (propriétaire uniquement) |
| DELETE | `/api/users/{id}/` | Suppression d'un utilisateur (propriétaire uniquement) |
| GET | `/api/users/me/` | Obtention des informations de l'utilisateur connecté |
| PUT | `/api/users/update_me/` | Mise à jour des informations de l'utilisateur connecté |

#### Obtention des informations de l'utilisateur connecté (`/api/users/me/`)

**Réponse:**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+244 923456789",
  "bio": "À propos de moi",
  "profile_picture": "/media/profile_pictures/john.jpg",
  "role": "client",
  "is_verified": false,
  "location": "Luanda, Angola",
  "date_joined": "2023-06-15T10:30:45Z"
}
```

#### Mise à jour des informations de l'utilisateur connecté (`/api/users/update_me/`)

**Payload:**
```json
{
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "+244 923456789",
  "bio": "Ma nouvelle bio",
  "profile_picture": [FICHIER],
  "location": "Benguela, Angola"
}
```

## Catégories et Sous-catégories

### Endpoints catégories

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/categories/` | Liste des catégories |
| GET | `/api/categories/{id}/` | Détails d'une catégorie |
| POST | `/api/categories/` | Création d'une catégorie (admin uniquement) |
| PUT | `/api/categories/{id}/` | Mise à jour d'une catégorie (admin uniquement) |
| DELETE | `/api/categories/{id}/` | Suppression d'une catégorie (admin uniquement) |

#### Liste des catégories (`/api/categories/`)

Paramètres de recherche:
- `search`: Recherche dans le nom et la description

**Réponse:**
```json
[
  {
    "id": 1,
    "name": "Services pour la Maison & Construction",
    "description": "Services liés à la construction, rénovation et maintenance de la maison",
    "icon": "home",
    "created_at": "2023-06-15T10:30:45Z",
    "updated_at": "2023-06-15T10:30:45Z"
  },
  ...
]
```

### Endpoints sous-catégories

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/subcategories/` | Liste des sous-catégories |
| GET | `/api/subcategories/{id}/` | Détails d'une sous-catégorie |
| POST | `/api/subcategories/` | Création d'une sous-catégorie (admin uniquement) |
| PUT | `/api/subcategories/{id}/` | Mise à jour d'une sous-catégorie (admin uniquement) |
| DELETE | `/api/subcategories/{id}/` | Suppression d'une sous-catégorie (admin uniquement) |

#### Liste des sous-catégories (`/api/subcategories/`)

Paramètres de filtrage:
- `category`: ID de la catégorie
- `search`: Recherche dans le nom et la description

**Réponse:**
```json
[
  {
    "id": 1,
    "name": "Construction & Rénovation",
    "description": "Maçons, architectes, entreprises de construction",
    "icon": "building",
    "category": 1,
    "category_name": "Services pour la Maison & Construction"
  },
  ...
]
```

## Prestataires

### Endpoints prestataires

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/providers/` | Liste des prestataires |
| GET | `/api/providers/{id}/` | Détails d'un prestataire |
| PUT | `/api/providers/{id}/` | Mise à jour d'un prestataire (propriétaire uniquement) |
| GET | `/api/providers/me/` | Obtention des informations du prestataire connecté |
| PUT | `/api/providers/update_me/` | Mise à jour des informations du prestataire connecté |
| GET | `/api/providers/by_category/` | Liste des prestataires par catégorie |
| GET | `/api/providers/by_subcategory/` | Liste des prestataires par sous-catégorie |
| GET | `/api/providers/nearby/` | Liste des prestataires à proximité |

#### Liste des prestataires (`/api/providers/`)

Paramètres de filtrage:
- `is_verified`: Filtrer par prestataires vérifiés (`true`/`false`)
- `is_featured`: Filtrer par prestataires mis en avant (`true`/`false`)
- `search`: Recherche dans le nom, la description et l'entreprise

**Réponse:**
```json
[
  {
    "id": 1,
    "username": "johndoe",
    "full_name": "John Doe",
    "company_name": "JD Construction",
    "avg_rating": 4.5,
    "is_verified": true,
    "is_featured": false,
    "services_count": 3,
    "reviews_count": 15,
    "main_category": {
      "category_id": 1,
      "category_name": "Services pour la Maison & Construction"
    },
    "address": "123 Rue Principale, Luanda",
    "latitude": -8.838333,
    "longitude": 13.234444
  },
  ...
]
```

#### Détails d'un prestataire (`/api/providers/{id}/`)

**Réponse:**
```json
{
  "id": 1,
  "user": {
    "id": 2,
    "username": "johndoe",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+244 923456789",
    "bio": "Expert en construction depuis 10 ans",
    "profile_picture": "/media/profile_pictures/john.jpg",
    "role": "provider",
    "is_verified": true,
    "location": "Luanda, Angola",
    "date_joined": "2023-06-15T10:30:45Z"
  },
  "company_name": "JD Construction",
  "is_verified": true,
  "is_featured": false,
  "avg_rating": 4.5,
  "trust_score": 4.2,
  "address": "123 Rue Principale, Luanda",
  "latitude": -8.838333,
  "longitude": 13.234444,
  "services": [
    {
      "id": 1,
      "title": "Rénovation complète de maison",
      "description": "Service de rénovation complète de votre maison",
      "price": 5000.00,
      "price_type": "fixed",
      "is_available": true,
      "subcategory": 1,
      "subcategory_name": "Construction & Rénovation",
      "category_name": "Services pour la Maison & Construction",
      "avg_rating": 4.7
    },
    ...
  ],
  "portfolio": [
    {
      "id": 1,
      "title": "Rénovation Villa Luanda",
      "description": "Projet complet de rénovation d'une villa à Luanda",
      "image": "/media/portfolio/villa_luanda.jpg",
      "created_at": "2023-06-15T10:30:45Z"
    },
    ...
  ],
  "certificates": [
    {
      "id": 1,
      "title": "Certification en Génie Civil",
      "issuing_organization": "Université de Luanda",
      "issue_date": "2018-05-20",
      "expiry_date": null,
      "file": "/media/certificates/genie_civil.pdf",
      "is_verified": true,
      "created_at": "2023-06-15T10:30:45Z"
    },
    ...
  ],
  "reviews": [
    {
      "id": 1,
      "client": 3,
      "client_name": "janedoe",
      "client_picture": "/media/profile_pictures/jane.jpg",
      "provider": 1,
      "service": 1,
      "quality_rating": 5,
      "punctuality_rating": 4,
      "value_rating": 4,
      "overall_rating": 4.33,
      "comment": "Excellent travail, très professionnel",
      "is_verified": true,
      "created_at": "2023-07-20T14:25:30Z",
      "images": [
        {
          "id": 1,
          "image": "/media/review_images/review_img1.jpg"
        }
      ]
    },
    ...
  ],
  "is_favorited": true
}
```

#### Liste des prestataires par catégorie (`/api/providers/by_category/`)

Paramètres de requête:
- `category_id`: ID de la catégorie (obligatoire)

#### Liste des prestataires par sous-catégorie (`/api/providers/by_subcategory/`)

Paramètres de requête:
- `subcategory_id`: ID de la sous-catégorie (obligatoire)

#### Liste des prestataires à proximité (`/api/providers/nearby/`)

Paramètres de requête:
- `latitude`: Latitude de l'utilisateur (obligatoire)
- `longitude`: Longitude de l'utilisateur (obligatoire)
- `radius`: Rayon de recherche en km (facultatif, par défaut: 10)

## Services

### Endpoints services

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/services/` | Liste des services |
| GET | `/api/services/{id}/` | Détails d'un service |
| POST | `/api/services/` | Création d'un service (prestataires uniquement) |
| PUT | `/api/services/{id}/` | Mise à jour d'un service (propriétaire uniquement) |
| DELETE | `/api/services/{id}/` | Suppression d'un service (propriétaire uniquement) |
| GET | `/api/services/my_services/` | Liste des services du prestataire connecté |

#### Liste des services (`/api/services/`)

Paramètres de filtrage:
- `provider_id`: ID du prestataire
- `subcategory`: ID de la sous-catégorie
- `is_available`: Disponibilité du service (`true`/`false`)
- `price_type`: Type de prix (`fixed`, `hourly`, `daily`, `negotiable`)
- `search`: Recherche dans le titre et la description

**Réponse:**
```json
[
  {
    "id": 1,
    "title": "Rénovation complète de maison",
    "description": "Service de rénovation complète de votre maison",
    "price": 5000.00,
    "price_type": "fixed",
    "is_available": true,
    "subcategory": 1,
    "subcategory_name": "Construction & Rénovation",
    "category_name": "Services pour la Maison & Construction",
    "avg_rating": 4.7
  },
  ...
]
```

#### Création d'un service (`/api/services/`)

**Payload:**
```json
{
  "title": "Rénovation complète de maison",
  "description": "Service de rénovation complète de votre maison",
  "price": 5000.00,
  "price_type": "fixed",
  "is_available": true,
  "subcategory": 1
}
```

## Portfolio

### Endpoints portfolio

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/portfolio/` | Liste des éléments de portfolio (filtrés par prestataire) |
| GET | `/api/portfolio/{id}/` | Détails d'un élément de portfolio |
| POST | `/api/portfolio/` | Ajout d'un élément de portfolio (prestataires uniquement) |
| PUT | `/api/portfolio/{id}/` | Mise à jour d'un élément de portfolio (propriétaire uniquement) |
| DELETE | `/api/portfolio/{id}/` | Suppression d'un élément de portfolio (propriétaire uniquement) |
| GET | `/api/portfolio/my_portfolio/` | Liste des éléments de portfolio du prestataire connecté |

#### Liste des éléments de portfolio (`/api/portfolio/`)

Paramètres de requête:
- `provider_id`: ID du prestataire (obligatoire)

#### Ajout d'un élément de portfolio (`/api/portfolio/`)

**Payload:**
```json
{
  "title": "Rénovation Villa Luanda",
  "description": "Projet complet de rénovation d'une villa à Luanda",
  "image": [FICHIER]
}
```

## Certificats

### Endpoints certificats

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/certificates/` | Liste des certificats (filtrés par prestataire) |
| GET | `/api/certificates/{id}/` | Détails d'un certificat |
| POST | `/api/certificates/` | Ajout d'un certificat (prestataires uniquement) |
| PUT | `/api/certificates/{id}/` | Mise à jour d'un certificat (propriétaire uniquement) |
| DELETE | `/api/certificates/{id}/` | Suppression d'un certificat (propriétaire uniquement) |
| GET | `/api/certificates/my_certificates/` | Liste des certificats du prestataire connecté |

#### Liste des certificats (`/api/certificates/`)

Paramètres de requête:
- `provider_id`: ID du prestataire (obligatoire)

#### Ajout d'un certificat (`/api/certificates/`)

**Payload:**
```json
{
  "title": "Certification en Génie Civil",
  "issuing_organization": "Université de Luanda",
  "issue_date": "2018-05-20",
  "expiry_date": null,
  "file": [FICHIER]
}
```

## Avis et évaluations

### Endpoints avis

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/reviews/` | Liste des avis (filtrés par prestataire ou service) |
| GET | `/api/reviews/{id}/` | Détails d'un avis |
| POST | `/api/reviews/` | Ajout d'un avis (clients uniquement) |
| PUT | `/api/reviews/{id}/` | Mise à jour d'un avis (propriétaire uniquement) |
| DELETE | `/api/reviews/{id}/` | Suppression d'un avis (propriétaire uniquement) |
| GET | `/api/reviews/my_reviews/` | Liste des avis laissés par l'utilisateur connecté |
| GET | `/api/reviews/provider_reviews/` | Liste des avis reçus par le prestataire connecté |

#### Liste des avis (`/api/reviews/`)

Paramètres de filtrage:
- `provider`: ID du prestataire
- `service`: ID du service

#### Ajout d'un avis (`/api/reviews/`)

**Payload:**
```json
{
  "provider": 1,
  "service": 1,
  "quality_rating": 5,
  "punctuality_rating": 4,
  "value_rating": 4,
  "comment": "Excellent travail, très professionnel",
  "uploaded_images": [FICHIERS]
}
```

## Favoris

### Endpoints favoris

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/favorites/` | Liste des prestataires favoris de l'utilisateur connecté |
| POST | `/api/favorites/` | Ajout d'un prestataire aux favoris |
| DELETE | `/api/favorites/{id}/` | Suppression d'un prestataire des favoris |
| POST | `/api/favorites/toggle/` | Ajout/suppression d'un prestataire des favoris |

#### Ajout d'un prestataire aux favoris (`/api/favorites/`)

**Payload:**
```json
{
  "provider": 1
}
```

#### Ajout/suppression d'un prestataire des favoris (`/api/favorites/toggle/`)

**Payload:**
```json
{
  "provider_id": 1
}
```

## Messagerie

### Endpoints conversations

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/conversations/` | Liste des conversations de l'utilisateur connecté |
| GET | `/api/conversations/{id}/` | Détails d'une conversation |
| GET | `/api/conversations/{id}/messages/` | Liste des messages d'une conversation |
| POST | `/api/conversations/{id}/send_message/` | Envoi d'un message dans une conversation |
| POST | `/api/conversations/start/` | Démarrage d'une nouvelle conversation |

#### Liste des conversations (`/api/conversations/`)

**Réponse:**
```json
[
  {
    "id": 1,
    "client": 3,
    "provider": 1,
    "client_details": {
      "id": 3,
      "username": "janedoe",
      "email": "jane@example.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "phone_number": "+244 923456780",
      "bio": "",
      "profile_picture": "/media/profile_pictures/jane.jpg",
      "role": "client",
      "is_verified": false,
      "location": "Luanda, Angola",
      "date_joined": "2023-06-15T10:30:45Z"
    },
    "provider_details": {
      "id": 1,
      "user_id": 2,
      "username": "johndoe",
      "full_name": "John Doe",
      "company_name": "JD Construction",
      "profile_picture": "/media/profile_pictures/john.jpg"
    },
    "last_message": {
      "content": "Pouvez-vous me donner un devis pour la rénovation de ma salle de bain?",
      "sender_id": 3,
      "created_at": "2023-07-20T14:25:30Z",
      "is_read": false
    },
    "unread_count": 1,
    "created_at": "2023-07-20T14:25:30Z"
  },
  ...
]
```

#### Liste des messages d'une conversation (`/api/conversations/{id}/messages/`)

**Réponse:**
```json
[
  {
    "id": 1,
    "sender": 3,
    "sender_name": "janedoe",
    "content": "Bonjour, j'aimerais avoir des informations sur vos services de plomberie.",
    "is_read": true,
    "created_at": "2023-07-20T14:25:30Z",
    "attachments": []
  },
  {
    "id": 2,
    "sender": 2,
    "sender_name": "johndoe",
    "content": "Bonjour! Bien sûr, comment puis-je vous aider?",
    "is_read": true,
    "created_at": "2023-07-20T14:30:15Z",
    "attachments": []
  },
  ...
]
```

#### Envoi d'un message dans une conversation (`/api/conversations/{id}/send_message/`)

**Payload:**
```json
{
  "content": "Bonjour, j'aimerais prendre rendez-vous pour demain.",
  "files": [FICHIERS]
}
```

#### Démarrage d'une nouvelle conversation (`/api/conversations/start/`)

**Payload:**
```json
{
  "provider_id": 1,
  "message": "Bonjour, j'aimerais avoir des informations sur vos services."
}
```

## Litiges

### Endpoints litiges

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/disputes/` | Liste des litiges de l'utilisateur connecté |
| GET | `/api/disputes/{id}/` | Détails d'un litige |
| POST | `/api/disputes/` | Création d'un litige |
| POST | `/api/disputes/{id}/add_evidence/` | Ajout d'une preuve à un litige |
| POST | `/api/disputes/{id}/update_status/` | Mise à jour du statut d'un litige (admin uniquement) |

#### Liste des litiges (`/api/disputes/`)

**Réponse:**
```json
[
  {
    "id": 1,
    "client": 3,
    "client_name": "janedoe",
    "provider": 1,
    "provider_name": "johndoe",
    "service": 1,
    "service_title": "Rénovation complète de maison",
    "title": "Travail non terminé",
    "description": "Le prestataire n'a pas terminé les travaux comme convenu.",
    "status": "open",
    "resolution_note": "",
    "created_at": "2023-07-20T14:25:30Z",
    "evidence": [
      {
        "id": 1,
        "user": 3,
        "user_name": "janedoe",
        "description": "Photo du travail inachevé",
        "file": "/media/dispute_evidence/evidence1.jpg",
        "created_at": "2023-07-20T14:30:15Z"
      }
    ]
  },
  ...
]
```

#### Création d'un litige (`/api/disputes/`)

**Payload:**
```json
{
  "provider": 1,
  "service": 1,
  "title": "Travail non terminé",
  "description": "Le prestataire n'a pas terminé les travaux comme convenu."
}
```

#### Ajout d'une preuve à un litige (`/api/disputes/{id}/add_evidence/`)

**Payload:**
```json
{
  "description": "Photo du travail inachevé",
  "file": [FICHIER]
}
```

#### Mise à jour du statut d'un litige (`/api/disputes/{id}/update_status/`)

**Payload:**
```json
{
  "status": "resolved",
  "resolution_note": "Le prestataire a terminé les travaux après médiation."
}
```

## Notifications

### Endpoints notifications

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/notifications/` | Liste des notifications de l'utilisateur connecté |
| GET | `/api/notifications/{id}/` | Détails d'une notification |
| POST | `/api/notifications/{id}/mark_as_read/` | Marquer une notification comme lue |
| POST | `/api/notifications/mark_all_as_read/` | Marquer toutes les notifications comme lues |
| GET | `/api/notifications/unread_count/` | Nombre de notifications non lues |

#### Liste des notifications (`/api/notifications/`)

**Réponse:**
```json
[
  {
    "id": 1,
    "title": "Nouveau message",
    "content": "Vous avez reçu un nouveau message de John Doe.",
    "type": "message",
    "related_object_id": 5,
    "is_read": false,
    "created_at": "2023-07-20T14:25:30Z"
  },
  ...
]
```

#### Nombre de notifications non lues (`/api/notifications/unread_count/`)

**Réponse:**
```json
{
  "count": 3
}
```

## Signalements

### Endpoints signalements

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/reports/` | Liste des signalements de l'utilisateur connecté (ou tous pour les admins) |
| GET | `/api/reports/{id}/` | Détails d'un signalement |
| POST | `/api/reports/` | Création d'un signalement |
| POST | `/api/reports/{id}/update_status/` | Mise à jour du statut d'un signalement (admin uniquement) |

#### Liste des signalements (`/api/reports/`)

**Réponse:**
```json
[
  {
    "id": 1,
    "reporter": 3,
    "reporter_name": "janedoe",
    "reported_user": 2,
    "reported_user_name": "johndoe",
    "reported_provider": 1,
    "reported_provider_name": "johndoe",
    "reported_review": null,
    "reason": "Service non fourni après paiement",
    "status": "pending",
    "type": "provider",
    "created_at": "2023-07-20T14:25:30Z"
  },
  ...
]
```

#### Création d'un signalement (`/api/reports/`)

**Payload:**
```json
{
  "reported_user": 2,
  "reported_provider": 1,
  "reported_review": null,
  "reason": "Service non fourni après paiement",
  "type": "provider"
}
```

**Valeurs possibles pour `type`:**
- `provider`: Signalement d'un prestataire
- `review`: Signalement d'un avis
- `user`: Signalement d'un utilisateur

#### Mise à jour du statut d'un signalement (`/api/reports/{id}/update_status/`)

**Payload:**
```json
{
  "status": "resolved",
  "admin_notes": "Prestataire contacté et problème résolu."
}
```

## Pagination

La pagination est utilisée pour les endpoints qui retournent des listes. Exemple de réponse paginée :

```json
{
  "count": 100,
  "next": "https://api.example.com/api/providers/?page=2",
  "previous": null,
  "results": [
    // liste des objets
  ]
}
```

Paramètres de requête pour la pagination :
- `page`: Numéro de la page (par défaut: 1)
- `page_size`: Nombre d'éléments par page (par défaut: 10, max: 100)

## Filtrage et recherche

De nombreux endpoints supportent le filtrage et la recherche. Les paramètres de filtrage sont spécifiés comme paramètres de requête. Par exemple :

```
/api/providers/?is_verified=true&search=construction
```

Les filtres disponibles sont détaillés dans la description de chaque endpoint.

## Codes d'erreur

L'API retourne des codes d'erreur HTTP standard :

- `200 OK`: Requête réussie
- `201 Created`: Ressource créée avec succès
- `204 No Content`: Requête réussie sans contenu à retourner
- `400 Bad Request`: Requête invalide ou données manquantes
- `401 Unauthorized`: Authentification requise
- `403 Forbidden`: Accès refusé à la ressource
- `404 Not Found`: Ressource non trouvée
- `500 Internal Server Error`: Erreur serveur

Les réponses d'erreur incluent des détails sur l'erreur :

```json
{
  "detail": "Description de l'erreur"
}
```

ou, pour les erreurs de validation :

```json
{
  "field_name": [
    "Message d'erreur pour ce champ"
  ]
}
```