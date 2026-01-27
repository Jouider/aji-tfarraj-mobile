# Screens & Pages — Aji Tfarraj

Ce document liste tous les écrans de l’application mobile
et toutes les pages du site web, avec leur rôle fonctionnel.

---
Figma wireframes:
https://www.figma.com/make/EMU1OZ2iKOer95M53xjRM8/Mobile-App-Wireframe?t=0t8n7Nx79CCTVTyt-0&preview-route=%2Fhome

## 1. Mobile App — Flutter

### 1.1 Auth / Onboarding
- Splash screen
- Sélection de la langue (FR / AR)
- Écran de connexion / inscription
- Autorisation des notifications

---

### 1.2 Écrans principaux

#### Home / Liste des émissions
- Liste des émissions à venir
- Filtres (ville, catégorie, chaîne)
- États :
  - loading
  - empty (aucune émission)
  - erreur réseau

---

#### Détail émission
- Informations complètes
- Règles de participation
- Nombre de places restantes
- Bouton “Réserver”

---

#### Réservation
- Sélection du nombre de places
- Confirmation de la demande
- Message de succès / erreur

---

### 1.3 Mes réservations

#### Liste des réservations
- Onglets :
  - En attente
  - Approuvées
  - Passées
- Badge de statut visible

---

#### Détail réservation
- Informations émission
- Statut actuel
- Actions possibles :
  - Annuler (si autorisé)
  - Générer ticket (si approuvé)

---

### 1.4 Ticket

#### Écran ticket
- QR code
- Numéro de ticket
- Infos pratiques (lieu, heure)
- Disponible hors ligne

---

### 1.5 Fidélité (Phase 1)
- Solde de points
- Historique des points

---

### 1.6 États globaux
- Chargement
- Erreur API
- Session expirée
- Pas de connexion internet

---

## 2. Website — SPA

### 2.1 Pages publiques
- Landing page
- Comment ça marche
- Liste des émissions à venir
- Page détail émission
- FAQ
- Contact

---

### 2.2 Règles web
- Pas de génération de ticket
- Pas de validation de réservation
- CTA vers application mobile
- SEO et partage réseaux sociaux

---

## 3. Règles UX globales
- Les statuts doivent être compréhensibles
- Les erreurs doivent être explicites
- Les actions critiques doivent être confirmées
