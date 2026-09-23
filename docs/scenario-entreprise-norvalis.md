# Scénario d'entreprise — Norvalis

À partir de la Phase 5, les phases restantes de ce lab sont habillées comme des
missions pour une entreprise fictive, plutôt que des exercices isolés — pour se
rapprocher d'une vraie formation professionnelle et raisonner en contraintes
d'entreprise, pas juste en configuration technique.

## Le contexte

**Norvalis** — PME de logistique industrielle, 750 salariés, 4 sites en France
(siège + sites secondaires, dont Poitiers).

Trois réalités déclenchent les phases à venir :

1. **Audit de sécurité NIS2 dans 6 mois.** Le DSI doit démontrer qu'il maîtrise sa
   chaîne d'authentification, pas seulement qu'elle fonctionne au quotidien.
2. **Rachat récent de Fluxo**, une startup dont tous les salariés utilisent déjà
   Microsoft 365 / Entra ID. Il faut les faire travailler avec les outils Norvalis
   sans dupliquer leurs comptes.
3. **Un système d'identité hétérogène, jamais unifié.** Le siège a été migré sur
   LLDAP il y a deux ans, mais le site de **Poitiers a gardé son Active Directory
   historique**, jamais rebasculé — personne n'a eu le temps ni le mandat de finir
   la migration. Deux annuaires différents à faire cohabiter sur le même Keycloak,
   une situation qu'on retrouve dans énormément de vraies entreprises après une
   fusion ou une migration partielle.

**Déclencheur immédiat (Phase 5)** : un ancien alternant avait encore un compte
actif 8 mois après son départ, découvert par hasard lors d'un contrôle interne. Le
DSI exige que ça ne se reproduise plus.

## Mission par phase

| Phase | Mission chez Norvalis |
|---|---|
| 4 (déjà fait) | Le modèle documentaire ReBAC correspond à un vrai besoin : dossiers partagés entre équipes, droits hérités. |
| 2 ter — Active Directory (en cours) | Fédérer l'AD hérité du site de Poitiers sur le même Keycloak que le LLDAP du siège — deux annuaires, une seule porte d'entrée. |
| 5 — midPoint | Mettre en place une vraie gouvernance des identités : plus jamais un compte fantôme après un départ. |
| 4 bis — Durcissement | Préparer la configuration Keycloak à résister à l'audit NIS2. |
| 4 ter — Exploitation prod | Rendre l'infrastructure digne de confiance : HTTPS, sauvegardes testées, logs exploitables. |
| 6 — Zitadel | Donner un avis argumenté au DSI, qui hésite à migrer tout Norvalis vers Zitadel. |
| 7 — Entra ID | Intégrer les salariés de Fluxo sans dupliquer leurs comptes Entra ID. |
| 8 — Grafana | Fournir au RSSI un tableau de bord de santé du système d'authentification. |

## Incidents et support N1/N2

Une fois l'AD de Poitiers fédéré à Keycloak (Phase 2 ter), les phases suivantes
intègrent des **simulations d'incidents** en plus des missions de construction :
un ticket de support réaliste ("le site de Poitiers signale que ses utilisateurs
n'arrivent plus à se connecter"), sans indice sur la cause — à diagnostiquer à
l'aveugle avec les outils déjà appris (console Keycloak, logs, curl), exactement
comme un vrai appel de référent d'établissement. Pratique directement
transférable à un poste d'Administrateur SSO/WebSSO en environnement de
support N1/N2.

## Format à partir de maintenant

Chaque phase se termine par un **quiz de 5 questions** pour vérifier ce qui a été
réellement retenu, pas juste coché comme "fait".
