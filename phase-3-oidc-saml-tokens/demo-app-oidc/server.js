// demo-app-oidc — client OIDC minimal contre Keycloak.
//
// Sert à OBSERVER un vrai flux Authorization Code + PKCE + refresh, pas à
// être un exemple de production (session en mémoire, pas de HTTPS...).
//
// Variables d'environnement (voir .env.example) :
//   OIDC_ISSUER                     ex: http://localhost:8080/realms/lab-iam
//   OIDC_CLIENT_ID                  ex: demo-spa (client public créé en phase 1)
//   OIDC_REDIRECT_URI                ex: http://localhost:3000/callback
//   OIDC_INTROSPECTION_CLIENT_ID     ex: demo-backend (client confidentiel)
//   OIDC_INTROSPECTION_CLIENT_SECRET  secret du client demo-backend
//   SESSION_SECRET                   secret pour signer le cookie de session
//   PORT                             défaut 3000

import express from 'express';
import session from 'express-session';
import * as client from 'openid-client';

const PORT = process.env.PORT || 3000;
const ISSUER_URL = process.env.OIDC_ISSUER || 'http://localhost:8080/realms/lab-iam';
const CLIENT_ID = process.env.OIDC_CLIENT_ID || 'demo-spa';
const REDIRECT_URI = process.env.OIDC_REDIRECT_URI || `http://localhost:${PORT}/callback`;

const app = express();
app.use(
  session({
    secret: process.env.SESSION_SECRET || 'change-me-session-secret',
    resave: false,
    saveUninitialized: false,
  }),
);

// Configuration openid-client, découverte une seule fois au démarrage
// (client "demo-spa" : public, donc pas de client_secret ici).
let mainConfig;
async function getMainConfig() {
  if (!mainConfig) {
    mainConfig = await client.discovery(new URL(ISSUER_URL), CLIENT_ID);
  }
  return mainConfig;
}

app.get('/', (req, res) => {
  const tokens = req.session.tokens;
  if (!tokens) {
    res.send(`
      <h1>lab-iam-keycloak — démo OIDC</h1>
      <p>Aucune session active.</p>
      <p><a href="/login">Se connecter via Keycloak (Authorization Code + PKCE)</a></p>
    `);
    return;
  }

  let claims = null;
  try {
    claims = tokens.claims ? tokens.claims() : null;
  } catch {
    claims = null;
  }

  res.send(`
    <h1>Connecté</h1>
    <h2>Claims de l'ID Token</h2>
    <pre>${JSON.stringify(claims, null, 2)}</pre>
    <h2>Réponse brute du endpoint token</h2>
    <pre>${JSON.stringify(tokens, null, 2)}</pre>
    <p><a href="/refresh">Rafraîchir le token (refresh_token grant)</a></p>
    <p><a href="/introspect">Introspecter l'access_token (RFC 7662)</a></p>
    <p><a href="/logout">Se déconnecter (révoque le refresh_token)</a></p>
  `);
});

app.get('/login', async (req, res, next) => {
  try {
    const config = await getMainConfig();

    const code_verifier = client.randomPKCECodeVerifier();
    const code_challenge = await client.calculatePKCECodeChallenge(code_verifier);
    const state = client.randomState();

    // Stockés en session le temps de l'aller-retour vers Keycloak.
    req.session.code_verifier = code_verifier;
    req.session.state = state;

    const authUrl = client.buildAuthorizationUrl(config, {
      redirect_uri: REDIRECT_URI,
      scope: 'openid profile email',
      code_challenge,
      code_challenge_method: 'S256',
      state,
    });

    res.redirect(authUrl.href);
  } catch (err) {
    next(err);
  }
});

app.get('/callback', async (req, res, next) => {
  try {
    const config = await getMainConfig();
    const currentUrl = new URL(req.originalUrl, `${req.protocol}://${req.get('host')}`);

    const tokens = await client.authorizationCodeGrant(config, currentUrl, {
      pkceCodeVerifier: req.session.code_verifier,
      expectedState: req.session.state,
    });

    req.session.tokens = tokens;
    res.redirect('/');
  } catch (err) {
    next(err);
  }
});

app.get('/refresh', async (req, res, next) => {
  try {
    const config = await getMainConfig();
    const tokens = req.session.tokens;
    if (!tokens?.refresh_token) {
      res.redirect('/');
      return;
    }

    const newTokens = await client.refreshTokenGrant(config, tokens.refresh_token);
    req.session.tokens = newTokens;

    res.send(`
      <h1>Refresh effectué</h1>
      <p>Nouvel access_token obtenu <strong>sans</strong> redemander le mot de passe.</p>
      <pre>${JSON.stringify(newTokens, null, 2)}</pre>
      <p><a href="/">Retour</a></p>
    `);
  } catch (err) {
    next(err);
  }
});

app.get('/introspect', async (req, res, next) => {
  try {
    const tokens = req.session.tokens;
    if (!tokens) {
      res.redirect('/');
      return;
    }

    const introspectionClientId = process.env.OIDC_INTROSPECTION_CLIENT_ID || 'demo-backend';
    const introspectionClientSecret = process.env.OIDC_INTROSPECTION_CLIENT_SECRET;

    if (!introspectionClientSecret) {
      res.send(`
        <p>Renseigne <code>OIDC_INTROSPECTION_CLIENT_SECRET</code> dans
        <code>.env</code> (secret du client confidentiel <code>demo-backend</code>
        créé en Phase 1) pour tester l'introspection.</p>
        <p><a href="/">Retour</a></p>
      `);
      return;
    }

    // L'introspection nécessite un client authentifié (RFC 7662) --
    // on utilise donc le client confidentiel de la phase 1, pas demo-spa.
    const introspectionConfig = await client.discovery(
      new URL(ISSUER_URL),
      introspectionClientId,
      introspectionClientSecret,
    );

    const result = await client.tokenIntrospection(introspectionConfig, tokens.access_token);

    res.send(`
      <h1>Résultat de l'introspection</h1>
      <pre>${JSON.stringify(result, null, 2)}</pre>
      <p><a href="/">Retour</a></p>
    `);
  } catch (err) {
    next(err);
  }
});

app.get('/logout', async (req, res, next) => {
  try {
    const config = await getMainConfig();
    const tokens = req.session.tokens;

    if (tokens?.refresh_token) {
      // Révocation explicite (RFC 7009) -- ne pas se contenter de détruire
      // la session locale, le refresh_token doit être invalidé côté serveur.
      await client.tokenRevocation(config, tokens.refresh_token);
    }

    req.session.destroy(() => {
      res.send('<p>Déconnecté et refresh_token révoqué côté Keycloak.</p><p><a href="/">Retour</a></p>');
    });
  } catch (err) {
    next(err);
  }
});

app.listen(PORT, () => {
  console.log(`demo-app-oidc en écoute sur http://localhost:${PORT}`);
  console.log(`Issuer configuré : ${ISSUER_URL}`);
});
