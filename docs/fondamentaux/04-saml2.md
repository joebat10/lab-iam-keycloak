# SAML 2.0 — le standard fédératif historique

## Pourquoi l'apprendre alors qu'OIDC est plus moderne

Parce qu'énormément de grands comptes, d'ERP, d'outils RH et d'applications
d'entreprise historiques (souvent en environnement Java/.NET) ne parlent que
SAML. Un ingénieur/architecte IAM qui ne sait pas lire ni déboguer une assertion
SAML se retrouve bloqué sur une part importante des projets réels.

## Le principe

SAML (Security Assertion Markup Language) échange des **assertions XML signées**
entre un **Identity Provider (IdP)** et un **Service Provider (SP)**, en
s'appuyant sur le navigateur de l'utilisateur comme intermédiaire (le navigateur
transporte les messages, il ne les comprend pas).

## Les rôles

- **IdP** : authentifie l'utilisateur et produit l'assertion signée
  (Keycloak, configuré comme IdP SAML).
- **SP** : consomme l'assertion, en vérifie la signature, en extrait l'identité
  et les attributs, puis ouvre une session locale.

## Le flux SP-initiated (le plus courant)

1. L'utilisateur tente d'accéder au SP sans session.
2. Le SP redirige le navigateur vers l'IdP avec une **AuthnRequest**.
3. L'utilisateur s'authentifie auprès de l'IdP.
4. L'IdP renvoie une **Response** contenant une **Assertion** signée
   (généralement via un formulaire auto-soumis — le **binding POST**).
5. Le SP vérifie la signature XML, valide les conditions (`NotBefore`,
   `NotOnOrAfter`, `Audience`), puis ouvre la session.

## Anatomie simplifiée d'une assertion

```xml
<saml:Assertion ID="_abc123" IssueInstant="...">
  <saml:Issuer>https://idp.example/realms/demo</saml:Issuer>
  <ds:Signature>...</ds:Signature>  <!-- signature XML-DSig -->
  <saml:Subject>
    <saml:NameID Format="...persistent">alice</saml:NameID>
  </saml:Subject>
  <saml:Conditions NotBefore="..." NotOnOrAfter="...">
    <saml:AudienceRestriction>
      <saml:Audience>https://sp.example</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AttributeStatement>
    <saml:Attribute Name="email">...</saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
```

Points de vigilance qu'un architecte doit systématiquement vérifier :

- La signature couvre bien l'**Assertion entière**, pas seulement la Response
  (attaque classique : injecter une nouvelle assertion à côté d'une signée).
- `NotOnOrAfter` est respecté par le SP (rejeu de token).
- L'`Audience` correspond bien à l'entity ID du SP attendu.

## Bindings HTTP à connaître

- **HTTP-Redirect** : message compressé dans l'URL (souvent pour l'AuthnRequest,
  taille limitée).
- **HTTP-POST** : message dans un formulaire HTML auto-soumis (le plus courant
  pour la Response, car les assertions sont plus volumineuses).

## SAML vs OIDC : différences pratiques

| | SAML 2.0 | OIDC |
|---|---|---|
| Format | XML signé | JWT (JSON) |
| Transport | Navigateur (redirections/POST) | HTTP direct + navigateur |
| Cas d'usage dominant | SSO entreprise, legacy, SP tiers B2B | Applications web/mobile modernes, API |
| Complexité de mise en œuvre | Plus verbeux, XML-DSig capricieux | Plus simple, JSON + JWT |

## Exercice pratique de ce lab (Phase 3)

Configurer un **second realm Keycloak comme Service Provider SAML** du premier
realm (IdP SAML) via l'Identity Brokering — cela permet de voir tout le flux
sans dépendre d'une librairie SAML tierce, et de littéralement observer
l'assertion XML brute échangée entre les deux realms.
