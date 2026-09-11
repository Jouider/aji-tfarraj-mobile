# « Présents » : noter qu'une personne est partie avant la fin

Réservé au staff, aux admins et aux scanners, les mêmes rôles que la navette.
On y accède de deux façons :
- depuis le profil, par la tuile **Présents** ;
- depuis le check-in, par l'icône 👥. Elle ouvre directement l'émission du
  billet qui vient d'être scanné.

## L'écran

- La liste contient tout le monde qui a été pointé à l'entrée : les
  réservations et les walk-ins (« Sans compte »).
- On retrouve quelqu'un en tapant **une partie du nom**, sans tenir compte des
  accents ni de l'ordre des mots, ou un code billet. Quand quelqu'un sort, plus
  personne n'a son billet en main.
- Chaque ligne affiche le code billet, le chargé public, l'heure d'entrée, et
  selon le cas :
  - « Sortie 19:32 · raison » ;
  - « Exclusion précédente ».
- Toucher une ligne ouvre une feuille, avec la photo et le nom en premier pour
  vérifier que c'est la bonne personne. On y choisit la raison parmi :
  - départ volontaire ;
  - malaise / santé ;
  - exclusion pour comportement ;
  - autre, avec une note obligatoire.
- La feuille annonce les conséquences : les points de la soirée sont retirés,
  et le chargé public n'est pas payé pour cette venue.
- Sur une personne déjà sortie, la même feuille montre qui a noté la sortie et
  permet de l'**annuler** (en cas de mauvaise personne).

## À la porte

Au scan suivant d'une personne déjà exclue, l'aperçu affiche « Exclusion
précédente — le 01/08/2026 (émission) ». La décision reste au scanner. Si le
billet appartient à quelqu'un déjà sorti ce soir, l'aperçu l'indique aussi.

## Côté membre

Rien de nouveau, sauf la ligne **« Retrait — parti avant la fin »** dans
l'historique de ses points. La raison reste interne à l'équipe.

Au passage, deux types de lignes de points s'affichaient encore sous leur nom
technique (`redemption`, `charge_public_bonus`). Ils ont maintenant un libellé
en FR et en AR.

Détails côté serveur : `docs/departures.md` du backend.
Tests : `test/departure_test.dart`.
