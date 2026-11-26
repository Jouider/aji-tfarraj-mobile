# « Ma caisse » — les dépenses de Hamza (app)

`features/expenses/`. Les règles et les calculs sont côté serveur : voir
`docs/expenses.md` du backend (règles d'Ayoub du 25/11/2026).

## Qui la voit

La personne qui a le rôle « Saisie des dépenses » dans le panneau (Hamza) :
`GET /api/auth/me` renvoie `expenses: true`. La carte « Ma caisse et mes
dépenses » du **profil** ouvre `/expenses`. Ayoub valide dans le panneau, pas
dans l'app.

## L'écran « Ma caisse »

1. **Le solde** de la caisse (vert ; rouge quand Hamza a avancé de sa poche),
   ce qu'il a reçu et dépensé, et la part encore en attente de validation.
2. **Une tuile par type de dépense** : un appui ouvre directement le bon
   formulaire. Le bouton « Nouvelle dépense » ouvre les mêmes tuiles.
3. **À corriger** : ce qu'Ayoub a refusé, avec son motif et « Corriger ».
4. **La liste** par état : En attente / Validées / Refusées.
5. **L'argent reçu** d'Ayoub.

## Le formulaire

Un seul écran (`ExpenseFormScreen`) qui ne montre que les champs de la
catégorie. Les nombres (minibus, sandwichs, personnes) se règlent avec − et +
(un appui sur le chiffre pour le taper). Le **total se calcule en direct** et
reste en bas, avec ce qu'il fait à la caisse (« Sort de ta caisse » / « Ne
touche pas ta caisse » / « Ajouté à sa paie »). Le serveur recalcule le
total : celui de l'app n'est jamais envoyé.

- Le programme se choisit dans une liste avec recherche (45 jours en arrière,
  30 en avant) ; choisir un programme met la date du tournage.
- Transport : après l'enregistrement, l'app propose « Un autre prestataire ? »
  pour le même programme.
- Staff payé du jour : seuls les programmes d'une émission qui ne paie pas
  son staff (Jemaatna Zina) sont proposés ; 200 DH, ajoutés à la paie de la
  personne une fois validés.
- Reçus : appareil photo ou galerie, 6 au plus. Les reçus déjà envoyés se
  chargent par l'API (jeton compris), jamais par une URL publique.
- Une dépense refusée se corrige et se renvoie ; une dépense validée ne se
  modifie plus.

« Ma paie » nomme la ligne `day_staff` (« Staff du jour ») et marque les
épisodes d'une émission sans paie du staff.

FR et AR via `ExpensesCopy` (`app/copywriting/expenses_copy.dart`).

## Notifications

`type: expenses` (dépense validée ou refusée, caisse alimentée) ouvre
`/expenses` ; `type: staff_pay` (staff du jour payé) ouvre « Ma paie ».

## Tests

`test/expenses_test.dart` : lecture des réponses, totaux et champs manquants
du brouillon, textes FR/AR, rendu à 375 px sans débordement dans les deux
langues, total recalculé en direct.
