# Autorisation : RBAC, ABAC, ReBAC

Trois façons de répondre à la même question — *cet utilisateur a-t-il le droit
de faire cette action sur cette ressource ?* — avec des compromis différents en
expressivité, complexité et performance.

## RBAC — Role-Based Access Control

Le modèle le plus répandu, et celui de Keycloak par défaut. On assigne des
**rôles** aux utilisateurs, et des **permissions** aux rôles.

```
Utilisateur --est--> Rôle --a--> Permission --sur--> Ressource
   Alice    --est--> "editor" --a--> "write" --sur--> "documents"
```

Forces : simple à comprendre, à auditer, à administrer à grande échelle
(on gère des groupes de rôles, pas des permissions individuelles).

Limite : RBAC répond mal aux règles **contextuelles ou relationnelles** :
"Alice peut éditer *ce* document parce qu'elle appartient à *l'équipe
propriétaire de ce dossier précis*" — un rôle statique ("editor") ne capture
pas naturellement cette relation dynamique à une ressource particulière.
On finit souvent par créer une explosion de rôles très spécifiques
("editor-dossier-1", "editor-dossier-2"...) pour compenser — un anti-pattern
classique appelé *role explosion*.

## ABAC — Attribute-Based Access Control

La décision se base sur des **attributs** — de l'utilisateur, de la ressource,
de l'environnement — évalués par une règle/politique :

```
autoriser SI utilisateur.departement == ressource.departement
         ET heure_actuelle BETWEEN 8h ET 20h
         ET utilisateur.niveau_habilitation >= ressource.niveau_confidentialite
```

Forces : très expressif, capture des règles métier fines sans exploser le
nombre de rôles.

Limite : peut devenir difficile à auditer ("pourquoi cet accès a-t-il été
autorisé ?" devient une question d'évaluation de règle, pas de lecture d'une
table de rôles) — et les moteurs de règles peuvent devenir des boîtes noires
si mal documentés.

## ReBAC — Relationship-Based Access Control

Popularisé par le papier **Google Zanzibar** (2019), qui décrit le système
d'autorisation interne de Google (Drive, Photos, Calendar...). L'idée : les
permissions découlent de **relations explicites entre objets**, potentiellement
transitives.

```
document:roadmap#owner@alice
folder:projet-x#viewer@team:marketing
document:roadmap#parent@folder:projet-x

# Alice peut éditer roadmap car elle en est owner (relation directe)
# N'importe qui dans team:marketing peut voir roadmap
#   car roadmap a pour parent folder:projet-x,
#   et la définition de "viewer" sur document hérite du "viewer" du parent
#   (relation transitive)
```

Forces : capture naturellement les hiérarchies (dossiers, organisations,
équipes imbriquées) sans exploser le nombre de rôles ; les vérifications
(`Check`) sont rapides même sur des graphes de relations très larges — c'est
tout l'objet du papier Zanzibar : servir des milliards de vérifications de
permission par seconde chez Google.

Limite : modéliser un système ReBAC demande un vrai travail de modélisation
(définir les types d'objets, les relations, les héritages) — plus proche d'un
schéma de base de données relationnelle qu'un simple tableau de rôles.

## Comment ces trois modèles cohabitent dans ce lab

- **Keycloak (phases 1-3)** : RBAC — rôles realm et rôles client, suffisant
  pour la majorité des décisions "grossières" (qui peut accéder à quelle
  application, avec quel rôle applicatif de haut niveau).
- **OpenFGA (phase 4)** : ReBAC — pour les décisions fines et relationnelles
  qu'un simple rôle Keycloak ne peut pas exprimer proprement (permissions sur
  des documents individuels, héritées d'une hiérarchie de dossiers).

C'est un pattern d'architecture réel et de plus en plus courant : **Keycloak
pour l'authentification et les rôles de haut niveau, OpenFGA (ou équivalent)
pour l'autorisation fine au niveau ressource**. Aucun des deux ne remplace
l'autre — ils répondent à des granularités différentes du même problème.

## Question type d'entretien

> "Pourquoi ne pas juste ajouter plus de rôles Keycloak pour gérer ça ?"

Réponse attendue : parce que le nombre de rôles nécessaires croît en général
avec le produit du nombre de ressources et du nombre de niveaux de permission
(*role explosion*), ce qui devient vite impossible à administrer et à auditer
(des dizaines de milliers de rôles pour des dizaines de milliers de documents).
Un modèle ReBAC exprime la règle une seule fois ("un viewer d'un dossier est
viewer de tous ses documents") et la laisse s'appliquer automatiquement à
n'importe quelle nouvelle ressource créée dans ce dossier.
