# User Journeys — Aji Tfarraj

Ce document décrit les parcours utilisateurs principaux de la plateforme Aji Tfarraj,
depuis la découverte des émissions jusqu’au check-in le jour du tournage.

Il sert de référence commune pour :
- le développement mobile (Flutter)
- le backend (Laravel)
- l’admin/staff panel

---

## 1. Parcours principal (Happy Path)

### 1.1 Découverte des émissions (Browse)
- L’utilisateur ouvre l’application mobile
- Il accède à la liste des émissions à venir
- Il peut filtrer par :
  - ville
  - catégorie (série, émission, musique, etc.)
  - chaîne (2M, Al Aoula, …)

**Résultat attendu**
- Liste claire des émissions disponibles
- Indication du nombre de places restantes

---

### 1.2 Demande de réservation (Reserve)
- L’utilisateur ouvre le détail d’une émission
- Il consulte :
  - date et heure
  - lieu / studio
  - règles (âge, dress code, interdictions)
- Il choisit le nombre de places
- Il confirme la demande

**Résultat attendu**
- Une réservation est créée avec le statut `pending_review`
- Les places sont temporairement bloquées (soft-hold)

---

### 1.3 En attente de validation (Pending)
- L’utilisateur voit sa réservation avec le statut :
  `En attente de confirmation`
- Message affiché :
  > “Votre demande est en cours de validation. Notre équipe va vous contacter.”

**Actions possibles**
- Annuler la réservation (si autorisé)
- Attendre l’appel du staff

---

### 1.4 Validation par le staff (Approved)
- Le staff contacte l’utilisateur par téléphone
- Si confirmation :
  - la réservation passe au statut `approved`
  - l’utilisateur reçoit une notification

**Résultat attendu**
- L’utilisateur voit un bouton “Générer mon ticket”

---

### 1.5 Génération du ticket (Ticket)
- L’utilisateur génère son ticket
- Le ticket contient :
  - QR code unique
  - numéro de ticket
  - informations de l’émission
- Le ticket est stocké localement (offline)

**Règle métier**
- Le ticket n’est disponible que si la réservation est `approved`

---

### 1.6 Check-in le jour J (Check-in)
- Le staff scanne le QR code à l’entrée du studio
- Si valide :
  - la réservation passe au statut `checked_in`
  - des points de fidélité sont ajoutés

---

## 2. États de réservation (State Machine)

| Statut | Description |
|------|------------|
| pending_review | Demande envoyée, en attente de contact |
| contacting | Staff en cours de contact |
| approved | Réservation validée |
| rejected | Demande refusée |
| cancelled | Annulée par l’utilisateur ou le staff |
| expired | Non confirmée à temps |
| checked_in | Présence confirmée sur place |

---

## 3. Cas limites (Edge Cases)

### 3.1 Émission complète (Sold Out)
- Plus de places disponibles
- Bouton de réservation désactivé
- Option : rejoindre une liste d’attente (si activée)

### 3.2 Liste d’attente (Waitlist)
- Réservation en attente sans places garanties
- Notification envoyée si une place se libère

### 3.3 Refus (Rejected)
- La réservation est rejetée par le staff
- Le motif peut être affiché
- Aucun ticket n’est générable

### 3.4 Expiration (Expired)
- L’utilisateur n’a pas confirmé à temps
- Les places sont libérées
- Invitation à refaire une demande

### 3.5 Hors connexion (Offline)
- Consultation des tickets possible hors ligne
- Impossible de réserver sans connexion

---

## 4. Règles importantes
- Le web ne gère pas la logique critique (ticket, validation)
- Le mobile est la source principale pour les réservations
- Les statuts doivent être toujours visibles et clairs pour l’utilisateur


Edge cases à gérer (très important)

Ajoute cette checklist 👇

🚫 Sold out

Capacité atteinte

Bouton “Complet”

Option : rejoindre la liste d’attente

⏳ Waitlist

Réservation en waitlist

Notification si une place se libère

❌ Cancel

Annulation par l’utilisateur (avant validation)

Annulation par l’admin/staff

Message clair + statut mis à jour

🚫 Rejected

Réservation rejetée

Affichage du motif (si fourni)

Pas de ticket possible

⏰ Expired

Réservation non confirmée à temps

Statut expired

Message : “Veuillez refaire une demande”

📵 Offline

Ticket accessible sans connexion

Message si tentative de réservation hors ligne