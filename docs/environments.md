# Environments — Aji Tfarraj Backend

Ce document décrit les environnements du backend Laravel (API + Admin/Staff) ainsi que la stratégie de secrets.

## 1) Environnements

### 1.1 Local
**Objectif:** développement sur les machines des devs (Abdellah, Mouad).

- `APP_ENV=local`
- `APP_DEBUG=true`
- Base URL: `http://localhost:8000` (ou autre)
- DB: PostgreSQL en local (Docker recommandé)
- Mail: sandbox (log / mailtrap) — pas d’envoi réel
- Storage: local (`storage/app`)

**Règles**
- Ne jamais commiter `.env`
- Utiliser `.env.example` comme référence

---

### 1.2 Staging
**Objectif:** environnement partagé de test (intégration), proche de la prod mais sans utilisateurs réels.

- `APP_ENV=staging`
- `APP_DEBUG=false`
- API base URL: `https://staging.api.<domaine>`
- DB: PostgreSQL staging (séparée de prod)
- Queue worker + scheduler actifs
- Logs/monitoring actifs
- Notifications: selon choix (souvent activées mais contrôlées)

**Déploiement**
- Déployer depuis la branche `develop`
- Les PRs fusionnées dans `develop` doivent être testables sur staging

**Règles**
- Données staging = données de test uniquement
- Accès admin/staff limité à l’équipe

---

### 1.3 Production
**Objectif:** environnement réel pour les utilisateurs.

- `APP_ENV=production`
- `APP_DEBUG=false`
- API base URL: `https://api.<domaine>`
- DB: PostgreSQL prod (séparée)
- Queue worker + scheduler actifs
- Backups DB réguliers
- TLS/SSL obligatoire
- Politique stricte de sécurité (rate limiting, headers)

**Déploiement**
- Déployer depuis la branche `main` uniquement
- Toute release = PR `develop → main` + validation

---

## 2) Stratégie de secrets

### 2.1 Règles générales
- ✅ `.env` **n’est jamais commité**
- ✅ `.env.example` est commité (sans secrets)
- ✅ Les secrets sont fournis via variables d’environnement sur serveur/hosting
- ✅ Rotation des secrets si fuite soupçonnée

### 2.2 Secrets typiques (à ne jamais commiter)
- `APP_KEY`
- `DB_PASSWORD`
- `MAIL_PASSWORD`
- `JWT_SECRET` (si utilisé)
- `API_KEYS` (SMS provider, push, etc.)

### 2.3 Gestion des secrets par environnement
- Local: `.env` sur la machine du dev
- Staging/Prod: variables d’environnement configurées sur le serveur (ou dashboard hosting)

---

## 3) Base de données PostgreSQL

### 3.1 Local (recommandé via Docker)
- DB: `aji_tfarraj`
- User: `postgres`
- Port: `5432`

### 3.2 Staging
- DB séparée de prod
- Accès restreint
- Backups (au moins quotidien)

### 3.3 Production
- DB séparée de staging
- Backups réguliers + restauration testée
- Permissions minimales

---

## 4) Checklist “prêt pour staging/prod”

### Staging ready
- [ ] `APP_DEBUG=false`
- [ ] migrations ok
- [ ] queue worker actif
- [ ] scheduler actif
- [ ] logs ok
- [ ] admin login ok

### Production ready
- [ ] SSL/TLS ok
- [ ] backups DB configurés
- [ ] rate limiting actif
- [ ] monitoring/logging
- [ ] `APP_DEBUG=false`
- [ ] déploiement depuis `main`
