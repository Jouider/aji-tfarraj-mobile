# « Ma paie » — la paie du staff (app)

`features/staff_pay/`. Les règles et le calcul sont côté serveur : voir
`docs/staff-pay.md` du backend.

## Qui la voit

Un membre avec un poste payé (superviseur des chargés publics, chauffeur de
salle, équipe technique) : `GET /api/auth/me` renvoie `staff_pay: true`.
L'écran s'ouvre (`/staff-pay`) depuis :

- la carte « Ma paie » du **profil** ;
- le lien « Voir le détail de ma paie staff » de l'onglet **Gains** du mode
  chargé public (le superviseur et le chauffeur sont aussi chargés publics).

## L'écran

De haut en bas :

1. **Le total** gagné en paie staff, le nombre d'épisodes payés, et ce qui est
   **disponible au retrait** (paie + gains de chargé public : un seul solde).
2. **Le poste actuel** et ce qu'il paie (« 300 DH par épisode d'une grande
   émission, 200 DH pour une petite », etc.).
3. Une note orange si des épisodes sont **en attente** : l'émission n'a pas
   encore de format, le montant s'affichera quand l'équipe l'aura choisi.
4. **Le retrait Wafacash** : le même `WafacashSection` que les chargés publics.
5. **L'historique**, mois par mois : date, émission, format (ou nombre
   d'entrées pour la technique), montant — ou « En attente ».

FR et AR via `StaffPayCopy` (`app/copywriting/staff_pay_copy.dart`).

## Tests

`test/staff_pay_test.dart` : lecture de la réponse, drapeau du profil, textes
FR/AR, rendu à 375 px sans débordement dans les deux langues.
